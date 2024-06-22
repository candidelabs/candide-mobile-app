import 'dart:typed_data';

import 'package:candide_mobile_app/utils/utils.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class UserOperationReceipt {
  Uint8List userOpHash;
  EthereumAddress entryPoint;
  EthereumAddress sender;
  BigInt nonce;
  EthereumAddress paymaster;
  BigInt? actualGasCost;
  BigInt? actualGasUsed;
  bool success;
  List<FilterEvent> logs = [];
  TransactionReceipt? txReceipt;

  UserOperationReceipt({
    required this.userOpHash,
    required this.entryPoint,
    required this.sender,
    required this.nonce,
    required this.paymaster,
    this.actualGasCost,
    this.actualGasUsed,
    required this.success,
    required this.logs,
    this.txReceipt
  });

  UserOperationReceipt.fromMap(Map<String, dynamic> map)
      : userOpHash = hexToBytes(map['userOpHash'] as String),
        entryPoint = EthereumAddress.fromHex((map['entryPoint'] ?? "") as String),
        sender = EthereumAddress.fromHex(map['sender'] as String),
        nonce = Utils.decodeBigInt(map['nonce'] as String, defaultsToZero: true)!,
        paymaster = EthereumAddress.fromHex(map['entryPoint'] as String),
        actualGasUsed = Utils.decodeBigInt(map['actualGasUsed']),
        actualGasCost = Utils.decodeBigInt(map['actualGasCost']),
        success = map['success'] as bool,
        logs = map['logs'] != null ?
          (map['logs'] as List<dynamic>).map((dynamic log) => FilterEvent.fromMap(log as Map<String, dynamic>)).toList()
            : [],
        txReceipt = map['receipt'] != null ? TransactionReceipt.fromMap(map['receipt']) : null;
}
