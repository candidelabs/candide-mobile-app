import 'dart:math';
import 'dart:ui';

import 'package:candide_mobile_app/config/theme.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GasBackSheet extends StatefulWidget {
  const GasBackSheet({Key? key}) : super(key: key);

  @override
  State<GasBackSheet> createState() => _GasBackSheetState();
}

class _GasBackSheetState extends State<GasBackSheet> {
  final ConfettiController confettiController = ConfettiController(duration: const Duration(seconds: 1));

  Path drawStar(Size size) {
    double degToRad(double deg) => deg * (pi / 180.0);
    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(halfWidth + externalRadius * cos(step),
          halfWidth + externalRadius * sin(step));
      path.lineTo(halfWidth + internalRadius * cos(step + halfDegreesPerStep),
          halfWidth + internalRadius * sin(step + halfDegreesPerStep));
    }
    path.close();
    return path;
  }

  @override
  void initState() {
    confettiController.play();
    super.initState();
  }

  @override
  void dispose() {
    confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
      child: AlertDialog(
        contentPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        content: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: ConfettiWidget(
                confettiController: confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple
                ], // manually specify the colors to be used
                createParticlePath: drawStar, // define a custom shape/path.
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50,),
                Image.asset("assets/images/zerofee_pass.png" , height: 300),
                const SizedBox(height: 25,),
                const Text(
                  "Your sense of exploration unlocked a valuable ZeroFee Pass, granting you a feeless transaction. Enjoy the freedom to transact without worrying about gas fees!",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 35,),
                Container(
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color.fromRGBO(181, 150, 77, 1),
                          Color.fromRGBO(232, 223, 200, 1),
                        ],
                        stops: [0.4, 1]
                      ),
                    borderRadius: BorderRadius.circular(15)
                  ),
                  child: ElevatedButton(
                    onPressed: (){
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 7.5),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      minimumSize: const Size(200, 0),
                    ),
                    child: Text('Continue', style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Colors.black, fontSize: 16),),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
