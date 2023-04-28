import 'dart:typed_data';

import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:candide_mobile_app/controller/signers_controller.dart';
import 'package:candide_mobile_app/models/fee_currency.dart';
import 'package:candide_mobile_app/models/gas.dart';
import 'package:candide_mobile_app/models/gnosis_transaction.dart';
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
import 'package:web3dart/web3dart.dart';
import 'package:web3dart/src/utils/length_tracking_byte_sink.dart';

class Batch {
  BigInt baseGas = BigInt.zero;
  FeeToken? _feeToken;
  EthereumAddress refundReceiver = Constants.addressZero;
  List<FeeToken> _feeTokens = [];
  List<GnosisTransaction> transactions = [];

  bool get includesPaymaster => _feeToken != null && _feeToken?.token.symbol != Networks.selected().nativeCurrency && _feeToken?.token.address != Constants.addressZeroHex;
  FeeToken? get feeCurrency => _feeToken;
  List<FeeToken> get feeCurrencies => _feeTokens;

  GnosisTransaction? getById(String id){
    return transactions.firstWhereOrNull((e) => e.id == id);
  }

  void changeFeeCurrency(FeeToken? feeCurrency) => _feeToken = feeCurrency;

  Future<void> changeFeeCurrencies(List<FeeToken> feeCurrencies) async {
    _feeTokens = feeCurrencies;
    await _adjustFeeCurrencyCosts();
  }


  Future<void> _adjustFeeCurrencyCosts() async{
    List<Future<UserOperation>> _userOpsTemp = [];
    Map<FeeToken, UserOperation> _userOps = {};
    for (FeeToken feeCurrency in _feeTokens){
      bool isEther = feeCurrency.token.symbol == Networks.selected().nativeCurrency && feeCurrency.token.address == Constants.addressZeroHex;
      _userOpsTemp.add(
        toUserOperation(
          PersistentData.selectedAccount,
          BigInt.from(PersistentData.accountStatus.nonce),
          proxyDeployed: PersistentData.accountStatus.proxyDeployed,
          skipPaymasterData: true,
          overrideFee: isEther ? null : feeCurrency,
        ).then((op){
          _userOps[feeCurrency] = op;
          BigInt maxCost = FeeCurrencyUtils.calculateFee(_userOps[feeCurrency]!, feeCurrency.exchangeRate, isEther);
          if (!isEther){
            maxCost = maxCost.scale(1.05); // todo check
          }
          feeCurrency.fee = maxCost;
          return op;
        })
      );
    }
    await Future.wait(_userOpsTemp);
  }

  String getFeeToken(){
    return feeCurrency?.token.symbol ?? "ETH";
  }

  BigInt getFee(){
    return feeCurrency?.fee ?? BigInt.zero;
  }

  Future<void> _addPaymasterToUserOp(UserOperation userOp, int chainId) async {
    String? paymasterData = await Paymaster.getPaymasterData(userOp, feeCurrency!.token.address, chainId);
    if (paymasterData == null){ // todo network: handle fetching errors
      userOp.paymasterAndData = "0x";
    }else{
      List<int> paymasterAndData = feeCurrency!.paymaster.addressBytes + hexToBytes(paymasterData);
      userOp.paymasterAndData = bytesToHex(paymasterAndData, include0x: true);
    }
  }

  void _addPaymasterToTransaction(GnosisTransaction transaction, [FeeToken? feeToken]){
    feeToken ??= feeCurrency;
    if (feeToken == null) return;
    transaction.paymaster = feeToken.paymaster;
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
      to: Networks.selected().multiSendCall,
      value: BigInt.zero,
      data: multiSendCallData,
      operation: BigInt.one,
      type: GnosisTransactionType.execTransactionFromEntrypoint,
      suggestedGasLimit: suggestedGasLimit,
    );
    return transaction;
  }

  Future<UserOperation> toUserOperation(Account account, BigInt nonce, {bool proxyDeployed=true, bool skipPaymasterData=false, FeeToken? overrideFee}) async {
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
      if (includesPaymaster || overrideFee != null){
        _addPaymasterToTransaction(multiSendTransaction, overrideFee);
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
    Network network = Networks.getByChainId(account.chainId)!;
    GasEstimate? gasEstimates = await network.gasEstimator.getGasEstimates(userOp, paymasterAddress: includesPaymaster ? feeCurrency!.paymaster : overrideFee?.paymaster); // todo enable, // todo handle null gas estimates (calldata error, or network error)
    //
    userOp.callGasLimit = gasEstimates!.callGasLimit.scale(1.25);
    userOp.preVerificationGas = gasEstimates.preVerificationGas;
    userOp.verificationGasLimit = gasEstimates.verificationGasLimit.scale(1.5);
    userOp.maxFeePerGas = gasEstimates.maxFeePerGas;
    userOp.maxPriorityFeePerGas = gasEstimates.maxPriorityFeePerGas;
    if (userOp.initCode != "0x"){
      userOp.verificationGasLimit += BigInt.from(350000); // higher than normal for deployment
      userOp.callGasLimit += multiSendTransaction?.suggestedGasLimit ?? userOp.callGasLimit; // todo remove when first simulateHandleOp is implemented
    }
    // userOp.callGasLimit += multiSendTransaction?.suggestedGasLimit.toInt() ?? 0; // todo check
    if (includesPaymaster || overrideFee != null){
      userOp.verificationGasLimit += BigInt.from(35000);
    }
    if (includesPaymaster && !skipPaymasterData){
      await _addPaymasterToUserOp(userOp, account.chainId);
    }
    //
    return userOp;
  }

}