import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/utils/currency.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SendReviewLeadingWidget extends StatelessWidget {
  final String currency;
  final BigInt value;
  const SendReviewLeadingWidget({Key? key, required this.currency, required this.value}) : super(key: key);

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
                    child: Icon(Icons.arrow_upward_rounded, color: Get.theme.colorScheme.onPrimary, size: 18,)
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 25,),
        Text(
          CurrencyUtils.formatCurrency(value, currency, formatSmallDecimals: true),
          style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 28),
        ),
      ],
    );
  }
}
