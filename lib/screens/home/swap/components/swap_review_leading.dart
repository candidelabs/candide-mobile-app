import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:candide_mobile_app/screens/home/components/token_logo.dart';
import 'package:candide_mobile_app/utils/currency.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

class SwapReviewLeadingWidget extends StatelessWidget {
  final TokenInfo baseCurrency;
  final BigInt baseValue;
  final TokenInfo quoteCurrency;
  final BigInt quoteValue;
  const SwapReviewLeadingWidget({Key? key, required this.baseCurrency, required this.baseValue, required this.quoteCurrency, required this.quoteValue}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(flex: 2,),
        _CurrencySwapIcon(
          currency: baseCurrency,
          value: CurrencyUtils.formatCurrency(baseValue, baseCurrency, includeSymbol: false, formatSmallDecimals: true),
        ),
        const Spacer(),
        Container(
          margin: const EdgeInsets.only(bottom: 35),
          child: Card(
              shape: ContinuousRectangleBorder(
                borderRadius: BorderRadius.circular(25.0),
              ),
              child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: const Icon(FontAwesomeIcons.arrowRight)
              )
          ),
        ),
        const Spacer(),
        _CurrencySwapIcon(
          currency: quoteCurrency,
          value: CurrencyUtils.formatCurrency(quoteValue, quoteCurrency, includeSymbol: false, formatSmallDecimals: true),
        ),
        const Spacer(flex: 2,),
      ],
    );
  }
}

class _CurrencySwapIcon extends StatelessWidget {
  final TokenInfo currency;
  final String value;
  const _CurrencySwapIcon({Key? key, required this.currency, required this.value}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Get.theme.cardColor,
            shape: BoxShape.circle,
          ),
          child: TokenLogo(
            token: currency,
            size: 95
          ),
        ),
        const SizedBox(height: 25,),
        RichText(
          text: TextSpan(
              text: "$value ",
              style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 18),
              children: [
                TextSpan(
                    text: currency.symbol,
                    style: const TextStyle(fontSize: 13, color: Colors.grey)
                )
              ]
          ),
        ),
      ],
    );
  }
}
