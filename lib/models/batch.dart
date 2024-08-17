import 'dart:typed_data';

import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:candide_mobile_app/controller/signers_controller.dart';
import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:candide_mobile_app/models/gas.dart';
import 'package:candide_mobile_app/models/gas_estimators/gas_estimator.dart';
import 'package:candide_mobile_app/models/gnosis_transaction.dart';
import 'package:candide_mobile_app/models/paymaster/fee_token.dart';
import 'package:candide_mobile_app/models/paymaster/gas_back_data.dart';
import 'package:candide_mobile_app/models/paymaster/paymaster_response.dart';
import 'package:candide_mobile_app/models/paymaster/sponsor_data.dart';
import 'package:candide_mobile_app/models/paymaster/sponsor_result.dart';
import 'package:candide_mobile_app/services/explorer.dart';
import 'package:candide_mobile_app/utils/extensions/bigint_extensions.dart';
import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:wallet_dart/contracts/account.dart';
import 'package:wallet_dart/wallet/account.dart';
import 'package:wallet_dart/wallet/account_helpers.dart';
import 'package:wallet_dart/wallet/encode_function_data.dart';
import 'package:wallet_dart/wallet/user_operation.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class Batch {
  Account account;
  late Network network;
  //
  late FeeToken? _selectedFeeToken;
  GasEstimate? gasEstimate;
  GasEstimate? gasEstimateWithPaymaster;
  SponsorResult? sponsorResult;
  late PaymasterResponse paymasterResponse;
  GasBackData? gasBack;
  //
  late BigInt? _suggestedCallGasLimit;
  late UserOperation userOperation;
  //
  List<GnosisTransaction> transactions = [];
  //

  Batch({required this.account}){
    network = Networks.getByChainId(account.chainId)!;
  }

  static Future<Batch> create({required Account account, bool refreshAccountData=false}) async {
    var batch = Batch(account: account);
    if (refreshAccountData){
      await Explorer.fetchAddressOverview(
        account: account,
        additionalCurrencies: TokenInfoStorage.tokens,
      );
    }
    return batch;
  }

  GnosisTransaction _getMultiSendTransaction(){
    if (transactions.length == 1){
      transactions.first.paymaster = null;
      transactions.first.approveToken = null;
      transactions.first.approveAmount = null;
      return transactions.first;
    }
    BigInt suggestedGasLimit = BigInt.zero;
    LengthTrackingByteSink sink = LengthTrackingByteSink();
    for (GnosisTransaction transaction in transactions){
      suggestedGasLimit = suggestedGasLimit + transaction.suggestedGasLimit;
      Uint8List data = AbiUtil.solidityPack(
        ["uint8", "address", "uint256", "uint256", "bytes"],
        [BigInt.zero, transaction.to.addressBytes, transaction.value, transaction.data.length, transaction.data],
      );
      sink.add(data);
    }
    Uint8List multiSendCallData = hexToBytes(EncodeFunctionData.multiSend(sink.asBytes()));
    GnosisTransaction transaction = GnosisTransaction(
      id: "multi-send",
      to: network.multiSendCall,
      value: BigInt.zero,
      data: multiSendCallData,
      operation: BigInt.one,
      type: GnosisTransactionType.execTransactionFromEntrypoint,
      suggestedGasLimit: suggestedGasLimit,
    );
    return transaction;
  }

  FeeToken? get selectedFeeToken => _selectedFeeToken;
  bool get isGasBackApplied => gasBack?.gasBackApplied ?? false;
  bool get isReverted => !paymasterResponse.sponsorData.sponsored && gasEstimate == null;

  Future<bool> prepare({bool checkSponsorshipEligibility = false}) async {
    bool userOpPreparationSuccess = await _prepareUserOperation();
    bool paymasterResponseSuccess = await _fetchPaymasterResponse();
    bool userOpSponsored = false;
    bool gasEstimationSuccess = true;
    if (checkSponsorshipEligibility || true){
      userOpSponsored = await _trySponsorUserOp();
    }
    if (!userOpSponsored){
      gasEstimationSuccess = await _estimateGas();
      await _adjustPaymasterResponseAfterEstimation();
    }
    return userOpPreparationSuccess && paymasterResponseSuccess && gasEstimationSuccess;
  }

  Future<bool> _prepareUserOperation() async {
    if (PersistentData.selectedAccount != account) return false;
    //
    (BigInt, BigInt)? networkFees;
    bool proxyDeployed = false;
    BigInt nonce = BigInt.zero;
    await Future.wait([
      network.client.getCode(account.address).then((value) => proxyDeployed = value.isNotEmpty),
      IAccount.interface(address: account.address, client: network.client).getNonce().then((value) => nonce = value).catchError((e, st){
        return BigInt.zero;
      }),
      GasEstimator.instance().getNetworkGasFees(network).then((value) => networkFees = value)
    ]);
    //
    var initCode = "0x";
    if (!proxyDeployed){
      initCode = bytesToHex(account.factory!.addressBytes + AccountHelpers.getInitCode(
        account.singleton!,
        account.entrypoint!,
        account.fallback!,
        SignersController.instance.getSignersAddressesFromAccount(account),
        BigInt.parse(account.salt.replaceAll("0x", ""), radix: 16),
      ), include0x: true);
    }
    //
    GnosisTransaction multiSendTransaction = _getMultiSendTransaction();
    _suggestedCallGasLimit = multiSendTransaction.suggestedGasLimit;
    var callData = multiSendTransaction.toCallData();
    userOperation = UserOperation.get(
      sender: account.address,
      nonce: nonce,
      initCode: initCode,
      callData: callData,
    );
    //
    if (networkFees != null) {
      var (maxFeePerGas, maxPriorityFeePerGas) = networkFees!;
      if (network.chainId.toInt() == 10 || network.chainId.toInt() == 420){
        maxFeePerGas = maxFeePerGas.scale(1.10);
        maxPriorityFeePerGas = maxFeePerGas.scale(1.10);
      }
      userOperation.maxFeePerGas = maxFeePerGas;
      userOperation.maxPriorityFeePerGas = maxPriorityFeePerGas;
    }else{
      return false;
    }
    //
    return true;
  }

  Future<bool> _fetchPaymasterResponse() async {
    PaymasterResponse _paymasterResponse = await network.paymaster.supportedERC20Tokens(TokenInfoStorage.getNativeTokenForNetwork(network));
    paymasterResponse = _paymasterResponse;
    //
    _selectedFeeToken = paymasterResponse.tokens.first;
    return true;
  }

  Future<bool> _trySponsorUserOp() async {
    UserOperation dummyOp = UserOperation.fromJson(userOperation.toJson());
    var dummySignature = List<int>.filled(64, 1, growable: true);
    dummySignature.add(28);
    dummyOp.signature = bytesToHex(Uint8List.fromList(dummySignature), include0x: true);
    var _sponsorResult = await network.paymaster.sponsorUserOperation(dummyOp, network.entrypoint, null);
    if (_sponsorResult == null) return false;
    sponsorResult = _sponsorResult;
    paymasterResponse.sponsorData = SponsorData(
      sponsored: true,
      sponsorMeta: _sponsorResult.sponsorMetadata
    );
    if (paymasterResponse.tokens.length > 1){
      paymasterResponse.tokens.removeRange(1, paymasterResponse.tokens.length); // remove all tokens except native token which is always at index 0
    }
    _selectedFeeToken = paymasterResponse.tokens.first;
    return true;
  }

  Future<void> _adjustPaymasterResponseAfterEstimation() async {
    if (gasEstimateWithPaymaster == null){
      paymasterResponse.tokens.removeRange(1, paymasterResponse.tokens.length);
      setSelectedFeeToken(_selectedFeeToken);
    }
    if (gasEstimate == null) return;
    for (int i = 0; i < paymasterResponse.tokens.length; i++){
      var feeToken = paymasterResponse.tokens[i];
      BigInt maxCost = feeToken.calculateFee(i == 0 ? gasEstimate! : gasEstimateWithPaymaster!, network, i > 0);
      maxCost = maxCost.scale(1.05); // todo check
      feeToken.fee = maxCost;
    }
    setSelectedFeeToken(_selectedFeeToken);
    //
    if (gasEstimateWithPaymaster != null){
      // BigInt maxETHCost = paymasterResponse.tokens.last.calculateETHFee(gasEstimateWithPaymaster!, network, true);
      // gasBack = await GasBackData.getGasBackData(account, paymasterResponse.paymasterData.address, network, maxETHCost);
    }
    //
  }

  void setSelectedFeeToken(FeeToken? feeToken){
    if (gasEstimate == null) return;
    _selectedFeeToken = feeToken;
    _selectedFeeToken ??= paymasterResponse.tokens[0];
    //
    bool nativeToken = true;
    GasEstimate _gasEstimate;
    if (_selectedFeeToken!.token.address.toLowerCase() == TokenInfoStorage.getNativeTokenForNetwork(network).address.toLowerCase()){
      _gasEstimate = gasEstimate!;
    }else{
      nativeToken = false;
      _gasEstimate = gasEstimateWithPaymaster!;
    }
    //
    userOperation.callGasLimit = _gasEstimate.callGasLimit;
    userOperation.verificationGasLimit = _gasEstimate.verificationGasLimit;
    userOperation.preVerificationGas = _gasEstimate.preVerificationGas;
    //
    GnosisTransaction multiSendTransaction = _getMultiSendTransaction();
    if (!nativeToken){
      multiSendTransaction.paymaster = paymasterResponse.paymasterData.address;
      multiSendTransaction.approveToken = EthereumAddress.fromHex(_selectedFeeToken!.token.address);
      multiSendTransaction.approveAmount = _selectedFeeToken!.fee;
    }
    var callData = multiSendTransaction.toCallData();
    userOperation.callData = callData;
  }

  BigInt getFee(){
    if (isGasBackApplied || paymasterResponse.sponsorData.sponsored){
      return BigInt.zero;
    }
    return _selectedFeeToken?.fee ?? BigInt.zero;
  }

  Future<bool> _estimateGas() async {
    GasEstimate? _gasEstimate;
    GasEstimate? _gasEstimateWithPaymaster;
    List<Future<dynamic>> futures = [];
    futures.add(
      GasEstimator.instance().getGasEstimates(
        userOperation,
        network.bundler,
        null
      )
    );
    if (network.paymaster.jsonRpc != null){
      futures.add(
        GasEstimator.instance().getGasEstimates(
            userOperation,
            network.bundler,
            paymasterResponse
        )
      );
    }
    var returns = await Future.wait(futures);
    _gasEstimate = returns[0];
    if (network.paymaster.jsonRpc != null) {
      _gasEstimateWithPaymaster = returns[1];
    }
    if (_gasEstimate == null) return false;
    double callGasLimitScalar = 2;
    double verificationGasLimitScalar = 2;
    double preVerificationGasScalar = 1.15;
    //
    _gasEstimate.callGasLimit = _gasEstimate.callGasLimit.scale(callGasLimitScalar);
    _gasEstimate.verificationGasLimit = _gasEstimate.verificationGasLimit.scale(verificationGasLimitScalar);
    _gasEstimate.preVerificationGas = _gasEstimate.preVerificationGas.scale(preVerificationGasScalar);
    if (userOperation.initCode != "0x"){
      _gasEstimate.verificationGasLimit += BigInt.from(350000); // higher than normal for deployment
      _gasEstimate.callGasLimit += _suggestedCallGasLimit ?? userOperation.callGasLimit; // todo remove when first simulateHandleOp is implemented
    }
    //
    if (_gasEstimateWithPaymaster != null){
      _gasEstimateWithPaymaster.callGasLimit = (_gasEstimateWithPaymaster.callGasLimit + BigInt.from(30000)).scale(callGasLimitScalar); // we add 30k gas for the token approval
      _gasEstimateWithPaymaster.verificationGasLimit = _gasEstimateWithPaymaster.verificationGasLimit.scale(verificationGasLimitScalar);
      _gasEstimateWithPaymaster.preVerificationGas = _gasEstimateWithPaymaster.preVerificationGas.scale(preVerificationGasScalar);
    }
    //
    gasEstimate = _gasEstimate;
    gasEstimateWithPaymaster = _gasEstimateWithPaymaster;
    return true;
  }

  Future<bool> finalize() async {
    if (!paymasterResponse.sponsorData.sponsored){
      if (isGasBackApplied){
        userOperation.paymasterAndData = gasBack!.paymasterAndData;
        return true;
      }
      if (selectedFeeToken?.token.address.toLowerCase() == network.nativeCurrencyAddress.hex.toLowerCase()) return true;
    }
    if (sponsorResult == null){ // todo network: handle fetching errors
      userOperation.paymasterAndData = "0x";
      return false;
    }else{
      userOperation.paymasterAndData = sponsorResult!.paymasterAndData;
      if (paymasterResponse.sponsorData.sponsored){
        userOperation.callGasLimit = sponsorResult?.callGasLimit ?? userOperation.callGasLimit;
        userOperation.verificationGasLimit = sponsorResult?.verificationGasLimit ?? userOperation.verificationGasLimit;
        userOperation.preVerificationGas = sponsorResult?.preVerificationGas ?? userOperation.preVerificationGas;
        userOperation.maxFeePerGas = sponsorResult?.maxFeePerGas ?? userOperation.maxFeePerGas;
        userOperation.maxPriorityFeePerGas = sponsorResult?.maxPriorityFeePerGas ?? userOperation.maxPriorityFeePerGas;
      }
    }
    return true;
  }

}