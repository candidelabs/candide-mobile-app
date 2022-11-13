import 'package:candide_mobile_app/config/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  late Material materialButton;
  late int index;
  final onboardingPagesList = [
    PageModel(
      widget: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          border: Border.all(
            width: 0.0,
            color: background,
          ),
        ),
        child: SingleChildScrollView(
          controller: ScrollController(),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 45.0,
                  vertical: 10.0,
                ),
                child: SvgPicture.asset('assets/images/logo.svg',
                    width: 300, color: pageImageColor),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 45.0),
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Own It. Really do',
                    style: TextStyle(
                      fontFamily: AppThemes.fonts.gilroy,
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 45.0, vertical: 69.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Your Wallet is fully self-custodial. Which means: no one have access to your funds, including us.',
                    style: TextStyle(
                        fontFamily: AppThemes.fonts.gilroy,
                        color: Colors.white,
                        fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    PageModel(
      widget: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          border: Border.all(
            width: 0.0,
            color: background,
          ),
        ),
        child: SingleChildScrollView(
          controller: ScrollController(),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 45.0,
                  vertical: 40.0,
                ),
                child:
                    SvgPicture.asset('assets/images/friends.svg', width: 185),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 45.0),
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Choose your CANDIDE Guardians',
                    style: TextStyle(
                      fontFamily: AppThemes.fonts.gilroy,
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 50.0, vertical: 25.0),
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Guardians are people and devices that you trust to recover your account in case you lose your phone.',
                    style: TextStyle(
                      fontFamily: AppThemes.fonts.gilroy,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 50.0, vertical: 7.0),
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    "You will need the approval of more than half of them to recover your wallet.",
                    style: TextStyle(
                      fontFamily: AppThemes.fonts.gilroy,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    PageModel(
      widget: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          border: Border.all(
            width: 0.0,
            color: background,
          ),
        ),
        child: SingleChildScrollView(
          controller: ScrollController(),
          child: Column(
            children: [
              Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 45.0,
                    vertical: 5.0,
                  ),
                  child: Lottie.asset('assets/animations/security6.json',
                      width: 275)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 45.0),
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Secure your Account',
                    style: TextStyle(
                      fontFamily: AppThemes.fonts.gilroy,
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 45.0, vertical: 30.0),
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    "We recommend adding at least 3 Guardians from different backgrounds.",
                    style: TextStyle(
                      fontFamily: AppThemes.fonts.gilroy,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 40.0, vertical: 20.0),
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    "You can add anyone you trust with an Ethereum wallet, a hardware wallet, or even an Institution",
                    style: TextStyle(
                      fontFamily: AppThemes.fonts.gilroy,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    PageModel(
      widget: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          border: Border.all(
            width: 0.0,
            color: background,
          ),
        ),
        child: SingleChildScrollView(
          controller: ScrollController(),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 45.0,
                  vertical: 40.0,
                ),
                child: Image.asset("assets/images/magic_link_vertical_logo.png",
                    width: 150, color: pageImageColor),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 45.0),
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Add Email Recovery',
                    style: TextStyle(
                      fontFamily: AppThemes.fonts.gilroy,
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 45.0, vertical: 55.0),
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    "Candide offers you the posibility of using your email as one of your Guardians with Magic Labs.",
                    style: TextStyle(
                      fontFamily: AppThemes.fonts.gilroy,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 45.0, vertical: 25.0),
                child: Align(
                    alignment: Alignment.center,
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: TextButton.icon(
                        onPressed: () async {
                            String url =
                                "https://magic.link/auth";
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
                            child: const Icon(PhosphorIcons.arrowSquareOutLight,
                                size: 10, color: Colors.lightBlue)),
                        label: Text("Learn more about Magic Link, the company",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontFamily: AppThemes.fonts.gilroy,
                                fontSize: 18,
                                color: Colors.lightBlue)),
                      ),
                    )),
              ),
            ],
          ),
        ),
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    materialButton = _nextButton();
    index = 0;
  }

  Material _nextButton({void Function(int)? setIndex}) {
    return Material(
      borderRadius: defaultSkipButtonBorderRadius,
      color: defaultSkipButtonColor,
      child: InkWell(
        borderRadius: defaultSkipButtonBorderRadius,
        onTap: () {
          if (setIndex != null) {
            index = index+1;
            setIndex(index);
          }
        },
        child: const Padding(
          padding: defaultSkipButtonPadding,
          child: Text(
            'Next',
            style: defaultSkipButtonTextStyle,
          ),
        ),
      ),
    );
  }

  Material get _doneButton {
    return Material(
      borderRadius: defaultProceedButtonBorderRadius,
      color: defaultProceedButtonColor,
      child: InkWell(
        borderRadius: defaultProceedButtonBorderRadius,
        onTap: () {
          Navigator.pop(context);
        },
        child: const Padding(
          padding: defaultProceedButtonPadding,
          child: Text(
            'Got it',
            style: defaultProceedButtonTextStyle,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Guardian System Onboarding',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        body: Onboarding(
          pages: onboardingPagesList,
          onPageChange: (int pageIndex) {
            index = pageIndex;
          },
          startPageIndex: 0,
          footerBuilder: (context, dragDistance, pagesLength, setIndex) {
            return DecoratedBox(
              decoration: BoxDecoration(
                color: background,
                border: Border.all(
                  width: 0.0,
                  color: background,
                ),
              ),
              child: ColoredBox(
                color: background,
                child: Padding(
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
                      index == pagesLength - 1
                          ? _doneButton
                          : _nextButton(setIndex: setIndex)
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
