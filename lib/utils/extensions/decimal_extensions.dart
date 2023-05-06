import 'package:decimal/decimal.dart';

extension DecimalExtensions on Decimal {
  String toTrimmedStringAsFixed(int decimals){
    return truncate(scale: decimals).toStringAsFixed(decimals).replaceAll(RegExp(r"([.]*0+)(?!.*\d)"), "");
  }
}