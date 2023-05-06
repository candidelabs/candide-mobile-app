// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:candide_mobile_app/utils/extensions/decimal_extensions.dart';
import 'package:decimal/decimal.dart';

class CurrencyUtils {
  static const int DECIMAL_PLACES = 6;

  static double convertToQuote(String baseAddress, String quote, BigInt value){
    if (quote != PersistentData.accountBalance.quoteCurrency){
      throw ArgumentError("Quote currency not supported"); // todo add simple routing
    }
    for (CurrencyBalance balance in PersistentData.currencies){
      if (balance.currencyAddress.toLowerCase() == baseAddress.toLowerCase()){
        if (balance.balance == BigInt.zero) return 0;
        int? decimals = TokenInfoStorage.getTokenByAddress(balance.currencyAddress)?.decimals;
        if (decimals == null) return 0;
        double valueE = double.parse(CurrencyUtils.formatUnits(value, decimals));
        double balanceE = double.parse(CurrencyUtils.formatUnits(balance.balance, decimals));
        return (valueE * balance.currentBalanceInQuote) / balanceE;
      }
    }
    return 0;
  }

  static String formatCurrency(BigInt value, TokenInfo token, {bool includeSymbol=true, bool formatSmallDecimals=false}){
    String result = displayGenericToken(value, token);
    if (formatSmallDecimals){
      var doubleString = result.split(" ")[0];
      if ((doubleString == "0.0" || doubleString == "0") && value > BigInt.zero){
        result = "<0.000001 ${token.symbol}";
      }
    }
    if (token.symbol == "USDT" && includeSymbol){
      return "\$"+result.split(" ")[0];
    }
    if (!includeSymbol){
      return result.split(" ")[0];
    }
    return result;
  }

  static String displayGenericToken(BigInt value, TokenInfo token){
    var multiplier = Decimal.fromInt(10).pow(token.decimals).toDecimal();
    return commify(((Decimal.parse(
        formatUnits(value, token.decimals)
    ) * multiplier).floor() / multiplier).toDecimal().toTrimmedStringAsFixed(DECIMAL_PLACES)) + " " + token.symbol;
  }

  static BigInt parseCurrency(String value, TokenInfo token){
    return parseUnits(value, token.decimals);
  }

  static String formatUnits(BigInt value, int decimals){
    var multiplier = "1";
    for(int i=0; i<decimals; i++){
      multiplier += "0";
    }
    //
    bool negative = value < BigInt.zero;
    if (negative){
      value = value.abs();
    }
    var fraction = value.remainder(BigInt.parse(multiplier)).toString();
    while(fraction.length < multiplier.length - 1){
      fraction = "0$fraction";
    }
    //
    RegExp trailingZeros = RegExp(r'^([0-9]*[1-9]|0)(0*)');
    if (trailingZeros.hasMatch(fraction)){
      fraction = trailingZeros.allMatches(fraction).first.group(1)!;
    }
    //
    var whole = (value ~/ BigInt.parse(multiplier));
    String result = "";
    if (multiplier.length == 1){
      result = whole.toString();
    }else {
      result = "$whole.$fraction";
    }
    if (negative) {
      result = "-$result";
    }
    return result;
  }

  static String formatRate(TokenInfo baseToken, TokenInfo quoteToken, BigInt rate){
    return "${formatCurrency(
      parseUnits('1', baseToken.decimals),
      baseToken,
    )} ≈ ${formatCurrency(rate, quoteToken)}";
  }

  static BigInt parseUnits(String value, int decimals){
    var multiplier = "1";
    for(int i=0; i<decimals; i++){
      multiplier += "0";
    }
    //
    bool negative = (value.substring(0, 1) == "-");
    if (negative) {
      value = value.substring(1);
    }
    //
    var comps = value.split(".");
    if (comps.length > 2) {
      throw ArgumentError("too many decimal points in $value");
    }

    String whole = comps[0];
    String fraction = comps.length > 1 ? comps[1] : "0";
    if (whole.isEmpty) whole = "0";
    //
    while (fraction.isNotEmpty && fraction[fraction.length - 1] == "0") {
      fraction = fraction.substring(0, fraction.length - 1);
    }
    //
    if (fraction.length > multiplier.length - 1) {
      throw AssertionError("fractional component exceeds decimals");
    }
    // If decimals is 0, we have an empty string for fraction
    if (fraction.isEmpty) fraction = "0";
    // Fully pad the string with zeros to get to wei
    while (fraction.length < multiplier.length - 1) {
      fraction += "0";
    }
    var wholeValue = BigInt.parse(whole);
    var fractionValue = BigInt.parse(fraction);
    var wei = (wholeValue * BigInt.parse(multiplier)) + fractionValue;
    if (negative) {
      wei = wei * BigInt.from(-1);
    }
    return wei;
  }

  static String commify(String value){
    var comps = value.split(".");
    var regex = RegExp(r"^-?[0-9]*$");

    if (comps.length > 2 || !regex.hasMatch(comps[0]) || (comps.length >= 2 && !RegExp(r"^-?[0-9]*$").hasMatch(comps[1])) || value == "." || value == "-.") {
      throw ArgumentError();
    }

    // Make sure we have at least one whole digit (0 if none)
    var whole = comps[0];

    var negative = "";
    if (whole.substring(0, 1) == "-") {
      negative = "-";
      whole = whole.substring(1);
    }

    // Make sure we have at least 1 whole digit with no leading zeros
    while (whole.isNotEmpty && whole.substring(0, 1) == "0") {
      whole = whole.substring(1);
    }
    if (whole == "") { whole = "0"; }

    var suffix = "";
    if (comps.length == 2) { suffix = "." + (comps.length >= 2 ? comps[1] : "0"); }
    while (suffix.length > 2 && suffix[suffix.length - 1] == "0") {
      suffix = suffix.substring(0, suffix.length - 1);
    }

    var formatted = [];
    while (whole.isNotEmpty) {
      if (whole.length <= 3) {
        formatted.insert(0, whole);
        break;
      } else {
        var index = whole.length - 3;
        formatted.insert(0, whole.substring(index));
        whole = whole.substring(0, index);
      }
    }

    return negative + formatted.join(",") + suffix;
  }
}