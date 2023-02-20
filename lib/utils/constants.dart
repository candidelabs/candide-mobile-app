import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class Constants {
  static String addressZeroHex = "0x0000000000000000000000000000000000000000";
  static String addressOneHex = "0x0000000000000000000000000000000000000001";
  static final EthereumAddress addressZero = EthereumAddress.fromHex("0x0000000000000000000000000000000000000000");
  static final EthereumAddress addressOne = EthereumAddress.fromHex("0x0000000000000000000000000000000000000001");
  static const nullCode = "0x";
  static final nullCodeBytes = hexToBytes("0x");
}