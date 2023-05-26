import 'dart:typed_data';

import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:candide_mobile_app/controller/signers_controller.dart';
import 'package:candide_mobile_app/models/gas.dart';
import 'package:candide_mobile_app/models/gnosis_transaction.dart';
import 'package:candide_mobile_app/models/paymaster/fee_token.dart';
import 'package:candide_mobile_app/models/paymaster/gas_back_data.dart';
import 'package:candide_mobile_app/models/paymaster/paymaster_response.dart';
import 'package:candide_mobile_app/services/paymaster.dart';
import 'package:candide_mobile_app/utils/constants.dart';
import 'package:candide_mobile_app/utils/extensions/bigint_extensions.dart';
import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:get/get.dart';
import 'package:wallet_dart/wallet/account.dart';
import 'package:wallet_dart/wallet/account_helpers.dart';
import 'package:wallet_dart/wallet/encode_function_data.dart';
import 'package:wallet_dart/wallet/user_operation.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/src/utils/length_tracking_byte_sink.dart';
import 'package:web3dart/web3dart.dart';

class Batch {
  Account account;
  Network network;
  //
  GasEstimate? gasEstimate;
  GasBackData? gasBack;
  FeeToken? _selectedFeeToken;
  late PaymasterResponse _paymasterResponse;
  List<GnosisTransaction> transactions = [];
  //
  Batch({required this.account, required this.network});
  //
  PaymasterResponse get paymasterResponse => _paymasterResponse;
  FeeToken? get selectedFeeToken => _selectedFeeToken;
  bool get includesPaymaster {
    if (gasBack?.gasBackApplied ?? false) return true;
    return _selectedFeeToken != null && _selectedFeeToken?.token.symbol != network.nativeCurrency && _selectedFeeToken?.token.address != Constants.addressZeroHex;
  }

  bool _includesPaymaster(FeeToken? feeToken) => feeToken != null && feeToken.token.symbol != network.nativeCurrency && feeToken.token.address != Constants.addressZeroHex;

  GnosisTransaction? getById(String id){
    return transactions.firstWhereOrNull((e) => e.id == id);
  }

  void setSelectedFeeToken(FeeToken? feeToken) => _selectedFeeToken = feeToken;

  Future<bool> fetchPaymasterResponse() async {
    PaymasterResponse? paymasterResponse = await Paymaster.fetchPaymasterFees(network.chainId.toInt());
    if (paymasterResponse == null){
      // todo handle network errors
      return false;
    }else{
      await setPaymasterResponse(paymasterResponse);
    }
    return true;
  }

  Future<void> setPaymasterResponse(PaymasterResponse paymasterResponse) async {
    _paymasterResponse = paymasterResponse;
    await _adjustFeeCurrencyCosts();
  }


  Future<void> _adjustFeeCurrencyCosts() async{
    for (FeeToken feeToken in _paymasterResponse.tokens.reversed){
      bool isEther = feeToken.token.symbol == network.nativeCurrency && feeToken.token.address == Constants.addressZeroHex;
      UserOperation op = await toUserOperation(
        BigInt.from(PersistentData.accountStatus.nonce),
        proxyDeployed: PersistentData.accountStatus.proxyDeployed,
        skipPaymasterData: true,
        feeToken: feeToken,
      );
      BigInt maxCost = feeToken.calculateFee(op, network);
      if (!isEther){
        maxCost = maxCost.scale(1.05); // todo check
      }
      feeToken.fee = maxCost;
    }
  }

  String getFeeToken(){
    return selectedFeeToken?.token.symbol ?? "ETH";
  }

  BigInt getFee(){
    if (gasBack?.gasBackApplied ?? false){
      return BigInt.zero;
    }
    return selectedFeeToken?.fee ?? BigInt.zero;
  }

  Future<void> _addPaymasterToUserOp(UserOperation userOp, int chainId) async {
    if (gasBack?.gasBackApplied ?? false){
      userOp.paymasterAndData = gasBack!.paymasterAndData;
      return;
    }
    String? paymasterData = await Paymaster.getPaymasterData(userOp, selectedFeeToken!.token.address, chainId);
    if (paymasterData == null){ // todo network: handle fetching errors
      userOp.paymasterAndData = "0x";
    }else{
      List<int> paymasterAndData = _paymasterResponse.paymasterData.paymaster.addressBytes + hexToBytes(paymasterData);
      userOp.paymasterAndData = bytesToHex(paymasterAndData, include0x: true);
    }
  }

  void _addPaymasterToTransaction(GnosisTransaction transaction, FeeToken feeToken){
    transaction.paymaster = _paymasterResponse.paymasterData.paymaster;
    transaction.approveToken = EthereumAddress.fromHex(feeToken.token.address);
    transaction.approveAmount = feeToken.fee;
  }

  GnosisTransaction? _getMultiSendTransaction(){
    if (transactions.isEmpty) return null;
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

  Future<UserOperation> toUserOperation(BigInt nonce, {bool proxyDeployed=true, bool skipPaymasterData=false, FeeToken? feeToken}) async {
    feeToken ??= _selectedFeeToken;
    //
    String initCode = "0x";
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
    GnosisTransaction? multiSendTransaction = _getMultiSendTransaction();
    String callData = "0x";
    if (multiSendTransaction != null){
      if (_includesPaymaster(feeToken)){
        _addPaymasterToTransaction(multiSendTransaction, feeToken!);
      }
      callData = multiSendTransaction.toCallData();
    }
    UserOperation userOp = UserOperation.get(
      sender: account.address,
      initCode: initCode,
      nonce: nonce,
      callData: callData,
    );
    //
    GasEstimate? _gasEstimate = await network.gasEstimator.getGasEstimates(userOp, prevEstimate: gasEstimate, includesPaymaster: _includesPaymaster(feeToken)); // todo enable, // todo handle null gas estimates (calldata error, or network error)
    gasEstimate ??= _gasEstimate;
    //
    userOp.callGasLimit = _gasEstimate!.callGasLimit.scale(1.25);
    userOp.preVerificationGas = _gasEstimate.preVerificationGas;
    userOp.verificationGasLimit = _gasEstimate.verificationGasLimit.scale(2);
    userOp.maxFeePerGas = _gasEstimate.maxFeePerGas;
    userOp.maxPriorityFeePerGas = _gasEstimate.maxPriorityFeePerGas;
    if (gasBack == null){
      FeeToken _tempGasToken = feeToken ?? paymasterResponse.tokens.first;
      BigInt maxETHCost = _tempGasToken.calculateETHFee(userOp, network);
      gasBack = await GasBackData.getGasBackData(account, paymasterResponse.paymasterData.paymaster, network, maxETHCost);
    }
    if (userOp.initCode != "0x"){
      userOp.verificationGasLimit += BigInt.from(350000); // higher than normal for deployment
      userOp.callGasLimit += multiSendTransaction?.suggestedGasLimit ?? userOp.callGasLimit; // todo remove when first simulateHandleOp is implemented
    }
    if (_includesPaymaster(feeToken)){
      userOp.verificationGasLimit += BigInt.from(35000);
    }
    if ((_includesPaymaster(feeToken) || gasBack!.gasBackApplied) && !skipPaymasterData){
      await _addPaymasterToUserOp(userOp, account.chainId);
    }
    //
    return userOp;
  }

}