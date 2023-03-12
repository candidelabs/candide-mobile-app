import 'dart:typed_data';

import 'package:candide_mobile_app/utils/constants.dart';
import 'package:wallet_dart/wallet/encode_function_data.dart';
import 'package:web3dart/web3dart.dart';

enum GnosisTransactionType{
  execTransactionFromEntrypoint,
}

class GnosisTransaction {
  String id;
  EthereumAddress to;
  BigInt value;
  Uint8List data;
  late BigInt suggestedGasLimit;
  late BigInt operation;
  //
  EthereumAddress? paymaster;
  EthereumAddress? approveToken;
  BigInt? approveAmount;
  //
  GnosisTransactionType type;

  GnosisTransaction({
    required this.id,
    required this.to,
    required this.value,
    required this.data,
    required this.type,
    this.paymaster,
    this.approveToken,
    this.approveAmount,
    BigInt? suggestedGasLimit,
    BigInt? operation,
  }){
    this.operation = operation ?? BigInt.zero;
    this.suggestedGasLimit = suggestedGasLimit ?? BigInt.zero;
  }

  void signWithCredentials(Credentials credentials, EthereumAddress address){
    throw UnimplementedError("Signing using `web3dart Credentials` object not yet implemented");
  }

  String toCallData({
    required BigInt baseGas,
    required BigInt gasPrice,
    required EthereumAddress gasToken,
    required EthereumAddress refundReceiver,
  }){
    if (type == GnosisTransactionType.execTransactionFromEntrypoint){
      return _toExecTransactionFromModuleCallData();
    }
    return _toExecTransactionFromModuleCallData();
  }

  String _toExecTransactionFromModuleCallData(){
    return EncodeFunctionData.execTransactionFromEntrypoint(
      to,
      value,
      data,
      operation,
      paymaster ?? Constants.addressZero,
      approveToken ?? Constants.addressZero,
      approveAmount ?? BigInt.zero,
    );
  }
}