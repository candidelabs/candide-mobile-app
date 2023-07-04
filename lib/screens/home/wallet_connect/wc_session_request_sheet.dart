import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/wallet_connect/wc_peer_meta.dart';
import 'package:candide_mobile_app/screens/home/wallet_connect/components/wc_peer_icon.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class WCSessionRequestSheet extends StatefulWidget {
  final WCPeerMeta peerMeta;
  final bool isConforming;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  const WCSessionRequestSheet({Key? key, required this.peerMeta, required this.isConforming, required this.onApprove, required this.onReject}) : super(key: key);

  @override
  State<WCSessionRequestSheet> createState() => _WCSessionRequestSheetState();
}

class _WCSessionRequestSheetState extends State<WCSessionRequestSheet> {
  @override
  Widget build(BuildContext context) {
    //
    String peerName = widget.peerMeta.name;
    String peerUrl = widget.peerMeta.url;
    //
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 25,),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: WCPeerIcon(icons: widget.peerMeta.icons),
              ),
            ),
            const SizedBox(width: 20,),
            const Icon(PhosphorIcons.arrowRightBold),
            const SizedBox(width: 20,),
            CircleAvatar(
              radius: 30,
              backgroundColor: Get.theme.colorScheme.primary,
              child: SizedBox(
                width: 50,
                height: 50,
                child: SvgPicture.asset("assets/images/logo_cropped.svg", color: Get.theme.colorScheme.onPrimary,),
              ),
            ),
          ],
        ),
        const SizedBox(height: 25,),
        SizedBox(
          width: Get.width * 0.75,
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              text: peerName,
              style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 18),
              children: [
                TextSpan(
                  text: " wants to connect",
                  style: TextStyle(fontFamily: AppThemes.fonts.gilroy, fontSize: 16),
                ),
              ]
            )
          ),
        ),
        const SizedBox(height: 5,),
        InkWell(
          onTap: () => Utils.launchUri(peerUrl, mode: LaunchMode.externalApplication),
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.35),
              borderRadius: BorderRadius.circular(15)
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(peerUrl, textAlign: TextAlign.center, style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 12)),
                const SizedBox(width: 5,),
                const Icon(PhosphorIcons.arrowSquareOut, size: 14,),
              ],
            ),
          ),
        ),
        const SizedBox(height: 25,),
        SizedBox(
          width: Get.width * 0.9,
          child: Text("App Permissions:", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 14, color: Colors.grey)),
        ),
        const SizedBox(height: 10,),
        Container(
          margin: EdgeInsets.only(left: Get.width * 0.12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: const [
                  Icon(PhosphorIcons.walletLight, color: Colors.green,),
                  SizedBox(width: 10,),
                  Text("View your balance and activity", style: TextStyle(color: Colors.white)),
                ],
              ),
              const SizedBox(height: 5,),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: const [
                  Icon(PhosphorIcons.currencyEthLight, color: Colors.green,),
                  SizedBox(width: 10,),
                  Text("Request approval for transactions", style: TextStyle(color: Colors.white)),
                ],
              ),
              const SizedBox(height: 5,),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: const [
                  Icon(PhosphorIcons.x, color: Colors.red,),
                  SizedBox(width: 10,),
                  Text("Transfer your assets without consent", style: TextStyle(color: Colors.white)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 25,),
        !widget.isConforming ? Container(
          margin: const EdgeInsets.only(left: 20, right: 20),
          padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 7.5),
          decoration: BoxDecoration(
            color: Colors.red[900]!.withOpacity(0.35),
            borderRadius: BorderRadius.circular(6)
          ),
          child: Text(
            "Incompatible connection\nPlease change chain on the dApp to be able connect.",
            style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),
          ),
        ) : const SizedBox.shrink(),
        widget.isConforming ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => widget.onReject.call(),
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
              onPressed: () => widget.onApprove.call(),
              style: ButtonStyle(
                  minimumSize: MaterialStateProperty.all(Size(Get.width * 0.30, 40)),
                  elevation: MaterialStateProperty.all(0),
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                      side: BorderSide(color: widget.isConforming ? Get.theme.colorScheme.primary : Colors.grey.withOpacity(0.5))
                  ))
              ),
              child: Text("Connect", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),),
            ),
          ],
        ) : const SizedBox.shrink(),
        const SizedBox(height: 25,),
      ],
    );
  }
}
