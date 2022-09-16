import 'package:web3dart/web3dart.dart';

class OptimalQuote {
  BigInt amount;
  BigInt rate;
  Map transaction;

  OptimalQuote({
    required this.amount,
    required this.rate,
    required this.transaction
  });
}