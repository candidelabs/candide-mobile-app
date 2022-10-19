import 'package:animations/animations.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/services/security.dart';
import 'package:candide_mobile_app/models/recovery_request.dart';
import 'package:candide_mobile_app/screens/onboard/create_wallet_screen.dart';
import 'package:candide_mobile_app/screens/onboard/recovery/recover_sheet.dart';
import 'package:candide_mobile_app/screens/onboard/recovery/recovery_request_page.dart';
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
        child: SingleChildScrollView(
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
              const SizedBox(height: 35,),
              Text("Crypto can be really confusing\nand hard to understand.", textAlign: TextAlign.center, style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 18),),
              const SizedBox(height: 25),
              Text("Candide makes your entry to crypto\na very pleasant and easy experience.", textAlign: TextAlign.center, style: TextStyle(fontFamily: AppThemes.fonts.gilroy, fontSize: 15),),
              const SizedBox(height: 25,),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    text: "If you're an already crypto user, you can ",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    children: [
                      TextSpan(
                        text: "import",
                        style: TextStyle(color: Colors.teal)
                      ),
                      TextSpan(
                        text: " your wallet, otherwise ",
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
              const SizedBox(height: 25,),
              ElevatedButton(
                onPressed: (){
                  Navigator.push(context, SharedAxisRoute(builder: (_) => const CreateWalletScreen(), transitionType: SharedAxisTransitionType.horizontal));
                },
                style: ButtonStyle(
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)
                  )),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Text("Create your crypto account", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),)
                ),
              ),
              TextButton(
                onPressed: (){
                  //Get.bottomSheet(RecoverSheet());
                  showBarModalBottomSheet(
                    context: context,
                    builder: (context) => SingleChildScrollView(
                      controller: ModalScrollController.of(context),
                      child: const RecoverSheet(),
                    ),
                  );
                },
                child: Text("lost your wallet ? recover it", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold)),
              ),
              /*ElevatedButton(
                onPressed: () async {
                  RecoveryRequest? request = await SecurityGateway.fetchById("631901fa8e4ac8d9bb9e7a9b");
                  Get.to(RecoveryRequestPage(request: request!));
                },
                child: Text("Test"),
              )*/
            ],
          ),
        ),
      ),
    );
  }
}

