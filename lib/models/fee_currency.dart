import 'package:candide_mobile_app/config/network.dart';

class FeeCurrency {
  CurrencyMetadata currency;
  BigInt fee;

  FeeCurrency({required this.currency, required this.fee});
}