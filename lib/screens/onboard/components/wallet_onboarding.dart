import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/screens/components/onboarding_feature_card.dart';
import 'package:candide_mobile_app/screens/onboard/landing_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:onboarding/onboarding.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
        title: "Welcome to CANDIDE",
        description: "Unleash Ethereum's true potential with Account Abstraction and the scale of Optimism",
      )
    ),
    PageModel(
      widget: _OnBoardStep(
        leading: Image.asset('assets/images/eth-diamond-rainbow-logo.png', height: 150,),
        title: "A wallet you deserve",
        description: "It's Open Source. It's build for the Ethereum Public Good",
        trailing: Column(
          children: const [
            OnboardingFeatureCard(title: "Contact Based Recovery", icon: Icon(PhosphorIcons.checkCircleFill, size: 25, color: Colors.green)), 
            OnboardingFeatureCard(title: "Pay Gas in supported Tokens", icon: Icon(PhosphorIcons.checkCircleFill, size: 25, color: Colors.green)),
            OnboardingFeatureCard(title: "Future Censorship Resistant", icon: Icon(PhosphorIcons.checkCircleFill, size: 25, color: Colors.green)),
            ]
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