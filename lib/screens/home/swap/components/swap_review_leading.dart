import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/utils/currency.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

class SwapReviewLeadingWidget extends StatelessWidget {
  final String baseCurrency;
  final BigInt baseValue;
  final String quoteCurrency;
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
          icon: const Icon(Icons.arrow_downward_rounded, color: Color(0xFFF44336), size: 18,),
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
          icon: const Icon(Icons.arrow_upward_rounded, color: Color(0xFF4CAF50), size: 18,),
        ),
        const Spacer(flex: 2,),
      ],
    );
  }
}

class _CurrencySwapIcon extends StatelessWidget {
  final String currency;
  final String value;
  final Icon icon;
  const _CurrencySwapIcon({Key? key, required this.currency, required this.value, required this.icon}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              width: 95,
              height: 95,
              decoration: BoxDecoration(
                color: Get.theme.cardColor,
                shape: BoxShape.circle,
              ),
              child: CurrencyMetadata.metadata[currency]!.logo,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(5),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Get.theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: icon,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 25,),
        RichText(
          text: TextSpan(
              text: "$value ",
              style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 18),
              children: [
                TextSpan(
                    text: currency,
                    style: const TextStyle(fontSize: 13, color: Colors.grey)
                )
              ]
          ),
        ),
      ],
    );
  }
}
