import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/screens/onboard/landing_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:onboarding/onboarding.dart';


class WalletOnboarding extends StatefulWidget {
  const WalletOnboarding({Key? key}) : super(key: key);

  @override
  State<WalletOnboarding> createState() =>
      _WalletOnboardingState();
}

class _WalletOnboardingState extends State<WalletOnboarding> {
  late int index;
  int opacity = 0;
  final onboardingPagesList = [
    PageModel(
      widget: _OnBoardStep(
        leading: SvgPicture.asset('assets/images/logo_cropped.svg', width: 150, height: 150, color: Get.theme.colorScheme.primary,),
        title: "Own It. Really do",
        description: "Your Wallet is self-custodial. Only you have access to your funds",
      )
    ),
    PageModel(
      widget: _OnBoardStep(
        leading: SvgPicture.asset('assets/images/friends_cropped.svg', width: 150, height: 130,),
        title: "Choose your CANDIDE guardians",
        description: "Guardians are people and devices that you trust to recover your account in case you lose your phone.",
        trailing: Container(
          margin: const EdgeInsets.symmetric(horizontal: 15),
          child: const Text(
            "* You will need the approval of more than half of them to recover your account",
            style: TextStyle(fontSize: 15, color: Colors.grey),
          )
        ),
      )
    ),
    PageModel(widget: const SizedBox.shrink()),
  ];

  @override
  void initState() {
    index = 0;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Onboarding(
        pages: onboardingPagesList,
        onPageChange: (int pageIndex) async {
          index = pageIndex;
          if (index == (onboardingPagesList.length - 1) ){
            await Future.delayed(const Duration(milliseconds: 200));
            Get.off(const LandingScreen());
          }
        },
        startPageIndex: 0,
        footerBuilder: (context, dragDistance, pagesLength, setIndex) {
          return Container(
            margin: const EdgeInsets.only(bottom: 50, right: 85),
            color: Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomIndicator(
                  netDragPercent: dragDistance,
                  pagesLength: pagesLength,
                  indicator: Indicator(
                    indicatorDesign: IndicatorDesign.line(
                      lineDesign: LineDesign(
                        lineType: DesignType.line_nonuniform,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}


class _OnBoardStep extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String description;
  final Widget? trailing;
  const _OnBoardStep({Key? key, this.leading, required this.title, required this.description, this.trailing}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.maxFinite,
      width: double.maxFinite,
      color: Colors.transparent,
      child: Column(
        children: [
          const SizedBox(height: 75,),
          leading ?? const SizedBox.shrink(),
          Container(
            margin: const EdgeInsets.all(25),
            child: Text(
              title,
              style: TextStyle(fontFamily: AppThemes.fonts.gilroy, color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            margin: const EdgeInsets.all(25),
            child: Text(
              description,
              style: TextStyle(
                  fontFamily: AppThemes.fonts.gilroy,
                  color: Colors.white,
                  fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ),
          trailing ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}