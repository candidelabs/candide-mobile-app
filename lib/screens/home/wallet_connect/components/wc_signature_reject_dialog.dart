import 'package:candide_mobile_app/config/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';

class WCSignatureRejectDialog extends StatelessWidget {
  final WalletConnect connector;
  const WCSignatureRejectDialog({Key? key, required this.connector}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Method not supported", textAlign: TextAlign.center, style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Lottie.asset(
            "assets/animations/sad.json",
            width: Get.width * 0.4,
            repeat: true,
          ),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
                text: connector.session.peerMeta!.name,
                style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 22, color: Get.theme.colorScheme.primary),
                children: const [
                  TextSpan(
                    text: " wants your signature",
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  )
                ]
            ),
          ),
          const SizedBox(height: 10,),
          Text("Unfortunately, signing is not yet supported in this current Beta version", textAlign: TextAlign.start, style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 15, color: Colors.grey)),
          const SizedBox(height: 5,),
          Text("But rest assured, we're working on it", textAlign: TextAlign.start, style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 15, color: Colors.white)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: (){
            Get.back();
          },
          child: Text("Alright", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold)),
        )
      ],
    );
  }
}
