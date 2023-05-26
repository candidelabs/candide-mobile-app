import 'package:web3dart/credentials.dart';

class PaymasterData {
  EthereumAddress paymaster;
  String eventTopic;

  PaymasterData({required this.paymaster, required this.eventTopic});
}