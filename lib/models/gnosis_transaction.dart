import 'dart:typed_data';

import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:eth_sig_util/util/utils.dart';
import 'package:wallet_dart/wallet/encode_function_data.dart';
import 'package:web3dart/web3dart.dart';

enum GnosisTransactionType{
  execTransaction,
  execTransactionFromModule,
}

class GnosisTransaction {
  String id;
  EthereumAddress to;
  BigInt value;
  Uint8List data;
  late BigInt operation;
  late BigInt safeTxGas;
  late BigInt nonce;
  GnosisTransactionType type;
  List<Uint8List> signatures = [];

  GnosisTransaction({
    required this.id,
    required this.to,
    required this.value,
    required this.data,
    required this.type,
    BigInt? operation,
    BigInt? safeTxGas,
    BigInt? nonce,
  }){
    this.nonce = nonce ?? BigInt.from(0);
    this.operation = operation ?? BigInt.zero;
    this.safeTxGas = safeTxGas ?? BigInt.from(38306);
  }

  Uint8List getHash(
    EthereumAddress address,
    {
      required BigInt baseGas,
      required BigInt gasPrice,
      required EthereumAddress gasToken,
      required EthereumAddress refundReceiver,
    }
  ){
    return EncodeFunctionData.getTransactionHash(
      to,
      value,
      data,
      operation,
      safeTxGas,
      baseGas,
      gasPrice,
      gasToken,
      refundReceiver,
      nonce,
      address: address
    );
  }

  void signWithPrivateKey(Uint8List privateKey, EthereumAddress address, {
    required BigInt baseGas,
    required BigInt gasPrice,
    required EthereumAddress gasToken,
    required EthereumAddress refundReceiver,
  }){
    var signature = EthSigUtil.signMessage(
      privateKeyInBytes: privateKey,
      message: getHash(
        address,
        baseGas: baseGas,
        gasPrice: gasPrice,
        gasToken: gasToken,
        refundReceiver: refundReceiver,
      ),
    );
    for (Uint8List _signatureBytes in signatures){
      var _signature = bytesToHex(_signatureBytes, include0x: true);
      if (_signature == signature) return;
    }
    signatures.add(hexToBytes(signature));
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
    if (type == GnosisTransactionType.execTransaction){
      return _toExecTransactionCallData(
        baseGas: baseGas,
        gasPrice: gasPrice,
        gasToken: gasToken,
        refundReceiver: refundReceiver,
      );
    }else{
      return _toExecTransactionFromModuleCallData();
    }
  }

  String _toExecTransactionCallData({
    required BigInt baseGas,
    required BigInt gasPrice,
    required EthereumAddress gasToken,
    required EthereumAddress refundReceiver,
  }){
    return EncodeFunctionData.execTransaction(
      to,
      value,
      data,
      operation,
      safeTxGas,
      baseGas,
      gasPrice,
      gasToken,
      refundReceiver,
      signatures[0],
    );
  }

  String _toExecTransactionFromModuleCallData(){
    return EncodeFunctionData.execTransactionFromModule(
      to,
      value,
      data,
      operation,
    );
  }
}