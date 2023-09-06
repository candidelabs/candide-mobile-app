import 'dart:math';
import 'dart:ui';

import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/models/paymaster/sponsor_data.dart';
import 'package:candide_mobile_app/screens/home/wallet_connect/components/wc_peer_icon.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class SponsorshipSheet extends StatefulWidget {
  final SponsorData sponsorData;
  const SponsorshipSheet({Key? key, required this.sponsorData}) : super(key: key);

  @override
  State<SponsorshipSheet> createState() => _SponsorshipSheetState();
}

class _SponsorshipSheetState extends State<SponsorshipSheet> {
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
                Card(
                  shape: ContinuousRectangleBorder(
                    borderRadius: BorderRadius.circular(150)
                  ),
                  child: Container(
                    width: double.maxFinite,
                    padding: const EdgeInsets.symmetric(vertical: 25),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: WCPeerIcon(icons: widget.sponsorData.sponsorMeta!.icons),
                          ),
                        ),
                        const SizedBox(height: 25,),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            text: "This transaction is sponsored by\n",
                            style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Colors.white, fontSize: 17),
                            children: [
                              TextSpan(
                                text: widget.sponsorData.sponsorMeta!.name,
                                style: const TextStyle(color: Colors.deepPurpleAccent, fontSize: 20),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => Utils.launchUri(widget.sponsorData.sponsorMeta!.url, mode: LaunchMode.externalApplication),
                              ),
                              TextSpan(
                                text: "\n${widget.sponsorData.sponsorMeta!.description}",
                                style: TextStyle(color: Colors.deepPurpleAccent.withOpacity(0.75), fontSize: 12),
                              ),
                            ]
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 35,),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Get.theme.cardColor),
                    shape: MaterialStateProperty.all(const ContinuousRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(150)),
                    )),
                    minimumSize: const MaterialStatePropertyAll(Size(double.maxFinite, 50)),
                    overlayColor: MaterialStateProperty.all(Get.theme.colorScheme.primary.withOpacity(0.1)),
                  ),
                  child: Text('Continue', style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Colors.white, fontSize: 16),),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
