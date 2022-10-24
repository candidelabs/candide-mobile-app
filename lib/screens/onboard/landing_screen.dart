import 'package:animations/animations.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/screens/onboard/recovery/recovery_wallet_sheet.dart';
import 'package:candide_mobile_app/screens/onboard/create_wallet_screen.dart';
import 'package:candide_mobile_app/utils/guardian_helpers.dart';
import 'package:candide_mobile_app/utils/routing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({Key? key}) : super(key: key);

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              height: 250,
              decoration: BoxDecoration(
                color: Get.theme.colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    bottom: 25,
                    child: SvgPicture.asset(
                      "assets/images/logo.svg",
                      width: 250,
                      height: 250,
                      color: Get.theme.colorScheme.onPrimary,
                    ),
                  ),
                  Positioned(
                    bottom: 25,
                    child: Text("CANDIDE", style: TextStyle(fontFamily: AppThemes.fonts.procrastinating, fontSize: 25, color: Get.theme.colorScheme.onPrimary),)
                  )
                ],
              ),
            ),
            const SizedBox(height: 25,),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  text: "If you already had a Candide Wallet before, you can ",
                  style: TextStyle(fontSize: 15, color: Colors.grey),
                  children: [
                    TextSpan(
                      text: "recover",
                      style: TextStyle(color: Colors.teal)
                    ),
                    TextSpan(
                      text: " your account, otherwise ",
                    ),
                    TextSpan(
                      text: "create",
                        style: TextStyle(color: Colors.teal)
                    ),
                    TextSpan(
                      text: " a new one with minimal effort",
                    ),
                  ]
                )
              ),
            ),
            const Spacer(flex: 2,),
            Container(
              margin: EdgeInsets.symmetric(horizontal: Get.width * 0.125),
              child: ElevatedButton(
                onPressed: (){
                  Navigator.push(context, SharedAxisRoute(builder: (_) => const CreateWalletScreen(), transitionType: SharedAxisTransitionType.horizontal));
                },
                style: ButtonStyle(
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)
                  )),
                  minimumSize: MaterialStateProperty.all(const Size.fromHeight(50)),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Text("Create a new wallet", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 17),)
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              margin: EdgeInsets.symmetric(horizontal: Get.width * 0.125),
              child: TextButton(
                onPressed: () async {
                  await showBarModalBottomSheet(
                    context: context,
                    builder: (context) {
                      Get.put<ScrollController>(ModalScrollController.of(context)!, tag: "recovery_wallet_modal");
                      return const RecoveryWalletSheet(
                          method: "social-recovery",
                          onNext: GuardianRecoveryHelper.setupRecoveryWallet
                      );
                    },
                  );
                },
                style: ButtonStyle(
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  )),
                  minimumSize: MaterialStateProperty.all(const Size.fromHeight(50)),
                  backgroundColor: MaterialStateProperty.all<Color>(Get.theme.cardColor),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Text("I already have a wallet", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 17, color: Get.theme.colorScheme.primary)),
                )
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

