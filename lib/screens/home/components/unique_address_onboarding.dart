import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/config/network.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:onboarding/onboarding.dart';



class UniqueAddressOnBoarding extends StatefulWidget {
  const UniqueAddressOnBoarding({Key? key}) : super(key: key);

  @override
  State<UniqueAddressOnBoarding> createState() =>
      _UniqueAddressOnBoardingState();
}

class _UniqueAddressOnBoardingState extends State<UniqueAddressOnBoarding> {
  late int index;
  final onboardingPagesList = [
    PageModel(
      widget: _OnBoardStep(
        leading: Lottie.asset('assets/animations/warning-shield.json', width: 200, reverse: true),
        title: "Heads up!",
        description: "Your public address is unique to ${Networks.selected().name}. Unlike other wallets, smart contract accounts are completly independent on each chain with different public addresses and security setup",
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
      child: Text("I Understand", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Get.theme.colorScheme.onPrimary),),
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