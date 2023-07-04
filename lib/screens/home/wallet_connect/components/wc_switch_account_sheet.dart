import 'package:blockies/blockies.dart';
import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:candide_mobile_app/controller/wallet_connect/wc_peer_meta.dart';
import 'package:candide_mobile_app/screens/components/painters/outlined_circle_painter.dart';
import 'package:candide_mobile_app/screens/home/wallet_connect/components/wc_peer_icon.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:wallet_dart/wallet/account.dart';

class WCSwitchAccountSheet extends StatelessWidget {
  final WCPeerMeta peerMeta;
  final Account targetAccount;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  const WCSwitchAccountSheet({Key? key, required this.peerMeta, required this.targetAccount, required this.onAccept, required this.onReject}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 25,),
        SizedBox(
          width: 60,
          height: 60,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(60),
            child: WCPeerIcon(icons: peerMeta.icons),
          ),
        ),
        const SizedBox(height: 25,),
        SizedBox(
          width: Get.width * 0.75,
          child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                  text: peerMeta.name,
                  style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 18),
                  children: [
                    TextSpan(
                      text: " wants to interact with another account",
                      style: TextStyle(fontFamily: AppThemes.fonts.gilroy, fontSize: 16),
                    ),
                  ]
              )
          ),
        ),
        const SizedBox(height: 25,),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _AccountAvatar(
              account: PersistentData.selectedAccount,
            ),
            const SizedBox(width: 20,),
            const Icon(PhosphorIcons.arrowRightBold),
            const SizedBox(width: 20,),
            _AccountAvatar(
              account: targetAccount,
            ),
          ],
        ),
        const SizedBox(height: 25,),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => onReject(),
              style: ButtonStyle(
                  minimumSize: MaterialStateProperty.all(Size(Get.width * 0.30, 40)),
                  backgroundColor: MaterialStateProperty.all(Colors.transparent),
                  elevation: MaterialStateProperty.all(0),
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                    side: BorderSide(color: Get.theme.colorScheme.primary)
                  ))
              ),
              child: Text("Reject", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Get.theme.colorScheme.primary),),
            ),
            const SizedBox(width: 15,),
            ElevatedButton(
              onPressed: () => onAccept(),
              style: ButtonStyle(
                  minimumSize: MaterialStateProperty.all(Size(Get.width * 0.30, 40)),
                  elevation: MaterialStateProperty.all(0),
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                    side: BorderSide(color: Get.theme.colorScheme.primary)
                  ))
              ),
              child: Text("Switch accounts", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),),
            ),
          ],
        ),
        const SizedBox(height: 25,),
      ],
    );
  }
}

class _AccountAvatar extends StatelessWidget {
  final Account account;
  const _AccountAvatar({Key? key, required this.account}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Network network = Networks.getByChainId(account.chainId)!;
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            const SizedBox(width: 80, height: 80,),
            SizedBox(
              width: 70,
              height: 70,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(70),
                child: Blockies(
                  seed: account.address.hexEip55 + account.chainId.toString(),
                  color: Get.theme.colorScheme.primary,
                ),
              ),
            ),
            Container(
              alignment: Alignment.center,
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(70),
              ),
              child: Text(
                Utils.truncate(account.address.hex, leadingDigits: 3, trailingDigits: 3),
                style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 12),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: CustomPaint(
                painter: OutlinedCirclePainter(color: network.color),
                child: CircleAvatar(
                  maxRadius: 12,
                  backgroundColor: network.color,
                  child: network.logo ?? SvgPicture.asset("assets/images/ethereum.svg", width: 20, color: Colors.white,),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5,),
        Text(
          Utils.truncate(account.name, leadingDigits: 12, trailingDigits: 12),
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 16)
        )
      ],
    );
  }
}

