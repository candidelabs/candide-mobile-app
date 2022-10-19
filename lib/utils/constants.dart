import 'package:ens_dart/ens_dart.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';

class Constants {
  static String addressZeroHex = "0x0000000000000000000000000000000000000000";
  static String addressOneHex = "0x0000000000000000000000000000000000000001";
  static final EthereumAddress addressZero = EthereumAddress.fromHex("0x0000000000000000000000000000000000000000");
  static final EthereumAddress addressOne = EthereumAddress.fromHex("0x0000000000000000000000000000000000000001");
  //static Web3Client client = Web3Client("https://mainnet.infura.io/v3/db07a0ccb47b4318888ab6d61f7bfb13", Client());
  static Web3Client client = Web3Client("https://goerli.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161", Client());
  static const nullCode = "0x";
  static final nullCodeBytes = hexToBytes("0x");
  static Ens ens = Ens(address: EthereumAddress.fromHex("0x4B1488B7a6B320d2D721406204aBc3eeAa9AD329"), client: client);
}