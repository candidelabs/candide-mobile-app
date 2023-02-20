import 'dart:math';
import 'dart:typed_data';

import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:candide_mobile_app/controller/signers_controller.dart';
import 'package:candide_mobile_app/models/fee_currency.dart';
import 'package:candide_mobile_app/models/gas.dart';
import 'package:candide_mobile_app/models/gnosis_transaction.dart';
import 'package:candide_mobile_app/services/bundler.dart';
import 'package:candide_mobile_app/utils/constants.dart';
import 'package:dio/dio.dart';
import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:get/get.dart';
import 'package:wallet_dart/wallet/account.dart';
import 'package:wallet_dart/wallet/account_helpers.dart';
import 'package:wallet_dart/wallet/encode_function_data.dart';
import 'package:wallet_dart/wallet/user_operation.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web3dart/src/utils/length_tracking_byte_sink.dart';

class Batch {
  static final EthereumAddress paymasterAddress = EthereumAddress.fromHex("0xA275Da33fE068CD62510B8e3Af7818EdE891cdff");
  static final EthereumAddress _multiSendCallAddress = EthereumAddress.fromHex("0x40A2aCCbd92BCA938b02010E17A5b8929b49130D");
  BigInt baseGas = BigInt.zero;
  FeeToken? _feeToken;
  EthereumAddress refundReceiver = Constants.addressZero;
  List<FeeToken> _feeTokens = [];
  List<GnosisTransaction> transactions = [];

  bool get includesPaymaster => _feeToken?.token.symbol != Networks.selected().nativeCurrency && _feeToken?.token.address != Constants.addressZeroHex;
  FeeToken? get feeCurrency => _feeToken;
  List<FeeToken> get feeCurrencies => _feeTokens;

  GnosisTransaction? getById(String id){
    return transactions.firstWhereOrNull((e) => e.id == id);
  }

  Future<void> changeFeeCurrency(FeeToken? feeCurrency) async {
    _feeToken = feeCurrency;
    if (transactions.isNotEmpty && transactions[0].id == "paymaster-allowance"){
      transactions.removeAt(0);
    }
    if (feeCurrency == null) return;
    if (includesPaymaster){
      GnosisTransaction approveTransaction = GnosisTransaction(
        id: "paymaster-allowance",
        to: EthereumAddress.fromHex(feeCurrency.token.address),
        value: BigInt.zero,
        data: hexToBytes(EncodeFunctionData.erc20Approve(
          paymasterAddress,
          feeCurrency.fee,
        )),
        type: GnosisTransactionType.execTransactionFromEntrypoint,
      );
      transactions.insert(0, approveTransaction);
    }
  }

  Future<void> changeFeeCurrencies(List<FeeToken> feeCurrencies) async {
    _feeTokens = feeCurrencies;
    await _adjustFeeCurrencyCosts();
  }

  Future<void> _adjustFeeCurrencyCosts() async{
    configureNonces(PersistentData.accountStatus.nonce);
    UserOperation userOperation = await toUserOperation(PersistentData.selectedAccount, PersistentData.accountStatus.nonce, proxyDeployed: PersistentData.accountStatus.proxyDeployed, skipPaymasterData: true);
    for (FeeToken feeCurrency in _feeTokens){
      bool isEther = feeCurrency.token.symbol == Networks.selected().nativeCurrency && feeCurrency.token.address == Constants.addressZeroHex;
      feeCurrency.fee = FeeCurrencyUtils.calculateFee(userOperation, feeCurrency.conversion, isEther);
    }
  }


  String getFeeToken(){
    return feeCurrency?.token.symbol ?? "ETH";
  }

  BigInt getFee(){
    return feeCurrency?.fee ?? BigInt.zero;
  }

  void configureNonces(int startNonce){
    int nonce = startNonce;
    nonce = nonce + transactions.length;
    if (includesPaymaster){
      nonce++;
    }
    for (GnosisTransaction transaction in transactions){
      transaction.nonce = BigInt.from(nonce);
      if (transaction.type == GnosisTransactionType.execTransaction){
        nonce++;
      }
    }
  }

  void signTransactions(Uint8List privateKey, Account account){
    for (GnosisTransaction transaction in transactions){
      if (transaction.type != GnosisTransactionType.execTransaction) continue;
      transaction.signWithPrivateKey(
        privateKey,
        account.address,
        baseGas: baseGas,
        gasPrice: feeCurrency?.fee ?? BigInt.zero,
        gasToken: EthereumAddress.fromHex(feeCurrency?.token.address ?? Constants.addressZero.hex),
        refundReceiver: refundReceiver
      );
    }
  }

  Future<void> _addPaymasterToUserOp(UserOperation userOp, int chainId) async {
    String? paymasterData = await Bundler.getPaymasterData(userOp, feeCurrency!.token.address, chainId);
    if (paymasterData == null){ // todo network: handle fetching errors
      userOp.paymasterAndData = "0x";
    }else{
      List<int> paymasterAndData = paymasterAddress.addressBytes + hexToBytes(paymasterData);
      userOp.paymasterAndData = bytesToHex(paymasterAndData, include0x: true);
    }
  }

  GnosisTransaction? _getMultiSendTransaction(){
    if (transactions.isEmpty) return null;
    if (transactions.length == 1){
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
      to: _multiSendCallAddress,
      value: BigInt.zero,
      data: multiSendCallData,
      operation: BigInt.one,
      type: GnosisTransactionType.execTransactionFromEntrypoint,
      suggestedGasLimit: suggestedGasLimit,
    );
    return transaction;
  }

  Future<UserOperation> toUserOperation(Account account, int nonce, {bool proxyDeployed=true, bool skipPaymasterData=false}) async {
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
      callData = multiSendTransaction.toCallData(baseGas: baseGas, gasPrice: feeCurrency?.fee ?? BigInt.zero, gasToken: EthereumAddress.fromHex(feeCurrency?.token.address ?? Constants.addressZero.hex), refundReceiver: refundReceiver);
    }
    UserOperation userOp = UserOperation.get(
      sender: account.address,
      initCode: initCode,
      nonce: nonce,
      callData: callData,
    );
    //
    List<GasEstimate>? gasEstimates = await BatchUtils.getGasEstimates([userOp], Networks.selected().chainId.toInt());
    userOp.callGasLimit = gasEstimates[0].callGasLimit;
    userOp.preVerificationGas = gasEstimates[0].preVerificationGas;
    userOp.verificationGasLimit = gasEstimates[0].verificationGasLimit;
    userOp.maxFeePerGas = gasEstimates[0].maxFeePerGas;
    userOp.maxPriorityFeePerGas = gasEstimates[0].maxPriorityFeePerGas;
    if (userOp.initCode != "0x"){
      userOp.preVerificationGas = 50000;
      userOp.verificationGasLimit = 350000;
    }
    userOp.callGasLimit += multiSendTransaction?.suggestedGasLimit.toInt() ?? 0;
    if (includesPaymaster && !skipPaymasterData){
      await _addPaymasterToUserOp(userOp, account.chainId);
    }
    //
    return userOp;
  }

}

class BatchUtils {

  static Future<List<int>?> getNetworkGasFees(int chainId) async {
    if (chainId == 420){ // todo: dynamic values for optimism goerli
      return [1100000, 1000000];
    }
    try{
      var response = await Dio().get("https://gas-api.metaswap.codefi.network/networks/$chainId/suggestedGasFees");
      //
      int suggestedMaxFeePerGas = (double.parse(response.data["medium"]["suggestedMaxFeePerGas"]) * 1000).ceil();
      int suggestedMaxPriorityFeePerGas = (double.parse(response.data["medium"]["suggestedMaxPriorityFeePerGas"]) * 1000).ceil();
      suggestedMaxFeePerGas = EtherAmount.fromUnitAndValue(EtherUnit.mwei, suggestedMaxFeePerGas).getInWei.toInt();
      suggestedMaxPriorityFeePerGas = EtherAmount.fromUnitAndValue(EtherUnit.mwei, suggestedMaxPriorityFeePerGas).getInWei.toInt();
      //
      suggestedMaxFeePerGas = min(suggestedMaxFeePerGas, EtherAmount.fromUnitAndValue(EtherUnit.gwei, 35).getInWei.toInt());
      //
      return [suggestedMaxFeePerGas, suggestedMaxPriorityFeePerGas];
    } on DioError catch(e){
      print("Error occurred ${e.type.toString()}");
      return null;
    }
  }

  static Future<List<GasEstimate>> getGasEstimates(List<UserOperation> userOps, int chainId) async {
    List<GasEstimate> results = [];
    List<int> networkFees = await getNetworkGasFees(chainId) ?? [0, 0];
    for (UserOperation op in userOps){
      int preVerificationGas = op.pack().length * 5 + 18000;
      GasEstimate gasEstimate = GasEstimate(callGasLimit: 300000, verificationGasLimit: 250000, preVerificationGas: preVerificationGas, maxFeePerGas: networkFees[0], maxPriorityFeePerGas: networkFees[1]);
      results.add(gasEstimate);
    }
    return results;
  }

}