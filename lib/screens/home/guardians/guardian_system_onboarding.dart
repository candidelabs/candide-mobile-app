import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/screens/components/onboarding_feature_card.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:onboarding/onboarding.dart';
import 'package:url_launcher/url_launcher.dart';


class GuardianSystemOnBoarding extends StatefulWidget {
  const GuardianSystemOnBoarding({Key? key}) : super(key: key);

  @override
  State<GuardianSystemOnBoarding> createState() =>
      _GuardianSystemOnBoardingState();
}

class _GuardianSystemOnBoardingState extends State<GuardianSystemOnBoarding> {
  late int index;
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
          title: "Add Recovery Contacts",
          description: "These are people and devices that you trust to recover your account in case you get locked out",
          trailing: Container(
            margin: const EdgeInsets.symmetric(horizontal: 15),
            child: const OnboardingFeatureCard(
              title: "You will need the approval of the majority to recover your account", 
              icon: Icon(PhosphorIcons.infoLight, size: 25, color: Colors.blue),
            ), 
          ),
        )
    ),
    PageModel(
        widget: _OnBoardStep(
          leading: Image.asset("assets/images/magic_link_vertical_logo.png", width: 120, color: const Color(0xff6851FF)),
          title: "Add Email Recovery",
          description: "Use your email as one of your recovery methods with Magic Link.",
          trailing: Container(
            margin: const EdgeInsets.symmetric(horizontal: 25),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: TextButton.icon(
                onPressed: () => Utils.launchUri("https://magic.link/auth", mode: LaunchMode.externalApplication),
                style: ButtonStyle(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  padding: MaterialStateProperty.all(EdgeInsets.zero),
                ),
                icon: Container(
                  margin: const EdgeInsets.only(bottom: 3.5),
                  child: const Icon(PhosphorIcons.arrowSquareOutLight, size: 15, color: Colors.lightBlue)
                ),
                label: Text(
                  "Learn more about Magic, the company",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: AppThemes.fonts.gilroy, fontSize: 14, color: Colors.lightBlue)
                ),
              ),
            ),
          ),
        )
    ),
    PageModel(
        widget: _OnBoardStep(
          leading: Image.asset('assets/images/shield_icon.png', width: 150),
          title: "Secure your account",
          description: "We recommend adding at least 3 recovery contacts from different backgrounds.",
          trailing: Column(
          children: const [
            OnboardingFeatureCard(title: "A family member or a friend", icon: Icon(PhosphorIcons.checkCircleLight, size: 25, color: Colors.green),), 
            OnboardingFeatureCard(title: "A hardware wallet you own", icon: Icon(PhosphorIcons.checkCircleLight, size: 25, color: Colors.green),),
            OnboardingFeatureCard(title: "Your Email", icon: Icon(PhosphorIcons.checkCircleLight, size: 25, color: Colors.green),),
            ]
        ),
      )
    ),
  ];

  @override
  void initState() {
    index = 0;
    super.initState();
  }

  Widget _nextButton({void Function(int)? setIndex}) {
    return ElevatedButton(
      onPressed: (){
        setIndex?.call(++index);
      },
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(Colors.grey[700]),
        shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)))
      ),
      child: const Text("Next", style: TextStyle(color: Colors.white),),
    );
  }

  Widget _doneButton() {
    return ElevatedButton(
      onPressed: (){
        Navigator.pop(context);
      },
      style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(Get.theme.colorScheme.primary),
          shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)))
      ),
      child: Text("Got it", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Get.theme.colorScheme.onPrimary),),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Onboarding(
        pages: onboardingPagesList,
        onPageChange: (int pageIndex) {
          index = pageIndex;
        },
        startPageIndex: 0,
        footerBuilder: (context, dragDistance, pagesLength, setIndex) {
          return Padding(
            padding: const EdgeInsets.all(45.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomIndicator(
                  netDragPercent: dragDistance,
                  pagesLength: pagesLength,
                  indicator: Indicator(
                    indicatorDesign: IndicatorDesign.line(
                      lineDesign: LineDesign(
                        lineType: DesignType.line_uniform,
                      ),
                    ),
                  ),
                ),
                index == pagesLength - 1 ? _doneButton() : _nextButton(setIndex: setIndex)
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
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
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