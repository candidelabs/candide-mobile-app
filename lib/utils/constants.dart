import 'package:ens_dart/ens_dart.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';

class Constants {
  static String addressZero = "0x0000000000000000000000000000000000000000";
  static Web3Client client = Web3Client("https://mainnet.infura.io/v3/db07a0ccb47b4318888ab6d61f7bfb13", Client());
  static Ens ens = Ens(client: client);
}