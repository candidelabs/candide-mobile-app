import 'package:candide_mobile_app/config/theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class RecoverExternalSheet extends StatefulWidget {
  const RecoverExternalSheet({Key? key}) : super(key: key);

  @override
  State<RecoverExternalSheet> createState() => _RecoverExternalSheetState();
}

class _RecoverExternalSheetState extends State<RecoverExternalSheet> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 35,),
        Text("Reach out to your guardians and\nask them to scan this QR code", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),),
        SizedBox(
          height: 160,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              QrImage(
                data: "https://security.candide.com",
                size: 120,
                foregroundColor: Colors.white,
              ),
              VerticalDivider(
                thickness: 1.6,
                color: Colors.grey.withOpacity(0.75),
                indent: 25,
                endIndent: 25,
              ),
              const SizedBox(width: 10,),
              RichText(text: TextSpan(
                  text: "or ask them to navigate to",
                  style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 12, color: Colors.white60),
                  children: [
                    TextSpan(
                      text: "\nsecurity.candidewallet.com",
                      style: TextStyle(color: Colors.blue[400]!.withOpacity(0.85)),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => launchUrl(Uri.parse('https://security.candidewallet.com')),
                    )
                  ]
              ))
            ],
          ),
        ),
        const SizedBox(height: 10,),
        Text("They will be asked to approve\nyour wallet recovery, if they\napprove, that’s it, you’re in", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Colors.white),),
        const SizedBox(height: 35,),
      ],
    );
  }
}
