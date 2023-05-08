import 'dart:typed_data';

import 'package:web3dart/credentials.dart';

class PaymasterData {
  EthereumAddress paymaster;
  Uint8List eventTopic;

  PaymasterData({required this.paymaster, required this.eventTopic});
}