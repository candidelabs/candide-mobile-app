import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/screens/home/components/unique_address_onboarding.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wallet_dart/wallet/account.dart';

class DepositSheet extends StatefulWidget {
  final Account account;
  const DepositSheet({Key? key, required this.account}) : super(key: key);

  @override
  State<DepositSheet> createState() => _DepositSheetState();
}

class _DepositSheetState extends State<DepositSheet> {
  bool _addressCopied = false;
  late Network network;


  void checkUniqueAddressOnboarding() async {
    await Future.delayed(const Duration(milliseconds: 250)); // cooldown for the widget to not interrupt the widget while being built
    bool? onboardSeenStatus = Hive.box("state").get("unique_address_onboard_tutorial_seen(${network.chainId})");
    if (onboardSeenStatus == null || onboardSeenStatus == false){
      Get.to(const UniqueAddressOnBoarding());
      await Hive.box("state").put("unique_address_onboard_tutorial_seen(${network.chainId})", true);
    }
  }

  copyAddress() async {
    Utils.copyText(widget.account.address.hexEip55);
    setState(() => _addressCopied = true);
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    setState(() => _addressCopied = false);
  }

  @override
  void initState() {
    network = Networks.getByChainId(widget.account.chainId)!;
    checkUniqueAddressOnboarding();
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Get.theme.colorScheme.primary,
      ),
      child: Column(
        children: [
          const SizedBox(height: 35,),
          const Text("Fund your", style: TextStyle(fontSize: 20, color: Colors.black),),
          const SizedBox(height: 5,),
          Text(Networks.selected().name, style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 30, color: Networks.selected().color, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),),
          const SizedBox(height: 5,),
          const Text("Account", style: TextStyle(fontSize: 20, color: Colors.black),),
          const SizedBox(height: 15,),
          QrImage(
            data: widget.account.address.hexEip55,
            size: 250,
            errorCorrectionLevel: QrErrorCorrectLevel.Q,
            embeddedImage: const AssetImage("assets/images/logo.jpeg"),
          ),
          const SizedBox(height: 15,),
          Text(Utils.truncate(widget.account.address.hexEip55, trailingDigits: 6), style: const TextStyle(fontSize: 20, color: Colors.black),),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 65,
                child: ElevatedButton(
                  onPressed: () {
                    // _onShare method:
                    final box = context.findRenderObject() as RenderBox?;
                    Share.share(
                      widget.account.address.hexEip55,
                      sharePositionOrigin:
                          box!.localToGlobal(Offset.zero) & box.size,
                    );
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.transparent),
                    elevation: MaterialStateProperty.all(0),
                    shape: MaterialStateProperty.all(RoundedRectangleBorder(
                      side: BorderSide(color: Get.theme.colorScheme.onPrimary, width: 1.5)
                    )),
                  ),
                  child: const Icon(PhosphorIcons.shareLight, color: Colors.black, size: 20,),
                ),
              ),
              const SizedBox(width: 5,),
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                width: _addressCopied ? 115 : 65,
                child: ElevatedButton(
                  onPressed: !_addressCopied ? copyAddress : null,
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.transparent),
                    elevation: MaterialStateProperty.all(0),
                    shape: MaterialStateProperty.all(RoundedRectangleBorder(
                      side: BorderSide(color: Get.theme.colorScheme.onPrimary, width: 1.5)
                    )),
                  ),
                  child: !_addressCopied ? const Icon(PhosphorIcons.copyLight, color: Colors.black, size: 20,)
                  : Row(
                    children: const [
                      Icon(Icons.check, color: Colors.green,),
                      SizedBox(width: 2,),
                      Text("Copied!", style: TextStyle(color: Colors.green),),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10,),
          DepositAlertFundsLoss(network: network,),
          const SizedBox(height: 35,),
        ],
      ),
    );
  }
}

class DepositAlertFundsLoss extends StatelessWidget {
  final Network network;
  const DepositAlertFundsLoss({Key? key, required this.network}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: network.color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(5),
      ),
      child: SizedBox(
        width: Get.width * 0.9,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const  SizedBox(width: 10,),
            Icon(PhosphorIcons.info, color: network.color,),
            const SizedBox(width: 5,),
            Flexible(
              child: RichText(
                textAlign: TextAlign.start,
                text: TextSpan(
                  text: "This address is unique to ",
                  style: TextStyle(fontSize: 13, fontFamily: AppThemes.fonts.gilroy, color: network.color),
                  children: [
                    TextSpan(
                        text: network.name,
                        style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold)
                    ),
                    const TextSpan(
                      text: ".\n",
                    ),
                    const TextSpan(
                      text: "Only deposit from ",
                    ),
                    TextSpan(
                        text: network.name,
                        style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold)
                    ),
                    const TextSpan(
                      text: ", otherwise funds ",
                    ),
                    TextSpan(
                        text: "will be lost.",
                        style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold)
                    ),
                  ]
                ),
              ),
            ),
            const SizedBox(width: 10,),
          ],
        ),
      ),
    );
  }
}
