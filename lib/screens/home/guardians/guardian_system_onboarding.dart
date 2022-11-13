import 'package:candide_mobile_app/config/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
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
        description: "Your Wallet is fully self-custodial. Which means: no one have access to your funds, including us.",
      )
    ),
    PageModel(
        widget: _OnBoardStep(
          leading: SvgPicture.asset('assets/images/friends_cropped.svg', width: 150, height: 150,),
          title: "Choose your CANDIDE guardians",
          description: "Guardians are people and devices that you trust to recover your account in case you lose your phone.",
        )
    ),
    PageModel(
        widget: _OnBoardStep(
          leading: Lottie.asset('assets/animations/security6.json', width: 275),
          title: "Secure your account",
          description: "We recommend adding at least 3 Guardians from different backgrounds.",
          trailing: Container(
            margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
            child: const Text(
              "* You can add anyone you trust with an Ethereum wallet, a hardware wallet, or even an Institution",
              style: TextStyle(fontSize: 15, color: Colors.grey),
            )
          ),
        )
    ),
    PageModel(
        widget: _OnBoardStep(
          leading: Image.asset("assets/images/magic_link_vertical_logo.png", width: 150, color: Color(0xff6851FF)),
          title: "Add email recovery",
          description: "Candide offers you the possibility of using your email as one of your Guardians with Magic Labs.",
          trailing: Container(
            margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: TextButton.icon(
                onPressed: () async {
                  String url = "https://magic.link/auth";
                  var urllaunchable = await canLaunchUrl(Uri.parse(url));
                  if (urllaunchable) {
                    await launchUrl(Uri.parse(url));
                  } else {
                    throw "Could not launch URL";
                  }
                },
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
                  "Learn more about Magic Link, the company",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: AppThemes.fonts.gilroy, fontSize: 14, color: Colors.lightBlue)
                ),
              ),
            ),
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