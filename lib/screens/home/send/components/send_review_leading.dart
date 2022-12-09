import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/utils/currency.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';

class SendReviewLeadingWidget extends StatelessWidget {
  final String currency;
  final BigInt value;
  final WalletConnect? connector;
  const SendReviewLeadingWidget({Key? key, required this.currency, required this.value, this.connector}) : super(key: key);

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
                    child: Icon(PhosphorIcons.paperPlaneTiltFill, color: Get.theme.colorScheme.onPrimary, size: 18,)
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
        connector != null ? Container(
          margin: const EdgeInsets.only(right: 15, left: 15, top: 20),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
                text: connector!.session.peerMeta!.name,
                style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 22, color: Get.theme.colorScheme.primary),
                children: const [
                  TextSpan(
                    text: " wants your permission to execute this transaction",
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  )
                ]
            ),
          ),
        ) : const SizedBox.shrink(),
      ],
    );
  }
}
