import 'package:candide_mobile_app/config/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class WalletDeploymentLeadingWidget extends StatelessWidget {
  const WalletDeploymentLeadingWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Get.theme.cardColor,
                shape: BoxShape.circle,
              ),
              child: Icon(PhosphorIcons.wallet, color: Get.theme.colorScheme.primary, size: 50,),
            ),
          ],
        ),
        const SizedBox(height: 25,),
        Text("Wallet deployment", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 20),),
      ],
    );
  }
}
