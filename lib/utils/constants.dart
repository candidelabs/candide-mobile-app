import 'package:candide_mobile_app/config/env.dart';
import 'package:ens_dart/ens_dart.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';

class Constants {
  static String addressZeroHex = "0x0000000000000000000000000000000000000000";
  static String addressOneHex = "0x0000000000000000000000000000000000000001";
  static final EthereumAddress addressZero = EthereumAddress.fromHex("0x0000000000000000000000000000000000000000");
  static final EthereumAddress addressOne = EthereumAddress.fromHex("0x0000000000000000000000000000000000000001");
  static Web3Client client = Web3Client(Env.nodeRpcEndpoint, Client());
  static const nullCode = "0x";
  static final nullCodeBytes = hexToBytes("0x");
  static Ens ens = Ens(address: EthereumAddress.fromHex("0x4B1488B7a6B320d2D721406204aBc3eeAa9AD329"), client: client);
}