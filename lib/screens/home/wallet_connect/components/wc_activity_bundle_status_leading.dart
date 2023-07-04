import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/wallet_connect/wc_peer_meta.dart';
import 'package:candide_mobile_app/screens/home/wallet_connect/components/wc_peer_icon.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WCBundleStatusLeading extends StatelessWidget {
  final WCPeerMeta peerMeta;
  const WCBundleStatusLeading({Key? key, required this.peerMeta}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: Get.theme.colorScheme.primary.withOpacity(0.25),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: WCPeerIcon(icons: peerMeta.icons,)
            ),
          ),
          const SizedBox(width: 5,),
          RichText(
            text: TextSpan(
              text: peerMeta.name,
              style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 13, color: Get.theme.colorScheme.primary),
              children: [
                TextSpan(
                  text: " is showing you this page",
                  style: TextStyle(fontFamily: AppThemes.fonts.gilroy, fontSize: 12, color: Colors.white),
                )
              ]
            ),
          )
        ],
      ),
    );
  }
}
