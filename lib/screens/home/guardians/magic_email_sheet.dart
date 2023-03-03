import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/screens/components/continous_input_border.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class MagicEmailSheet extends StatefulWidget {
  final Function(String, String?) onProceed;
  const MagicEmailSheet({Key? key, required this.onProceed}) : super(key: key);

  @override
  State<MagicEmailSheet> createState() => _MagicEmailSheetState();
}

class _MagicEmailSheetState extends State<MagicEmailSheet> {
  final FocusNode emailFocus = FocusNode();
  final FocusNode nicknameFocus = FocusNode();
  String email = "";
  String? nickname = "";
  bool valid = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 250),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        children: [
          const SizedBox(height: 15,),
          Text("Enter your email", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 20),),
          const SizedBox(height: 35,),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 15),
            child: TextFormField(
              focusNode: emailFocus,
              style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 22),
              textAlign: TextAlign.center,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                label: Text("Email Address"),
                border: ContinousInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(35)),
                ),
              ),
              onChanged: (val) => email = val,
              validator: (val){
                valid = false;
                if (val == null || val.isEmpty) return 'required';
                if (!val.isEmail) return 'Invalid email';
                valid = true;
                return null;
              },
              autovalidateMode: AutovalidateMode.always,
              onFieldSubmitted: (_) => nicknameFocus.requestFocus(),
            ),
          ),
          const SizedBox(height: 10,),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 15),
            child: TextFormField(
              focusNode: nicknameFocus,
              style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),
              decoration: const InputDecoration(
                label: Text("Nickname (Optional)"),
                border: ContinousInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(35)),
                ),
              ),
              onChanged: (val) => nickname = val,
            ),
          ),
          const SizedBox(height: 25,),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 25),
            child: RichText(
              text: TextSpan(
                text: "By proceeding, you agree to Magic Labs ",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                children: [
                  TextSpan(
                    text: "terms of service ",
                    style: const TextStyle(color: Colors.blue),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => Utils.launchUri("https://magic.link/legal/terms-of-service", mode: LaunchMode.externalApplication),
                  ),
                  const TextSpan(
                    text: "and ",
                  ),
                  TextSpan(
                    text: "privacy policy",
                    style: const TextStyle(color: Colors.blue),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => Utils.launchUri("https://magic.link/legal/privacy-policy", mode: LaunchMode.externalApplication),
                  ),
                ]
              ),
            ),
          ),
          const SizedBox(height: 35,),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 25),
            width: Get.width,
            child: ElevatedButton(
              onPressed: (){
                if (!valid) return;
                emailFocus.unfocus();
                nicknameFocus.unfocus();
                if (nickname?.removeAllWhitespace.isEmpty ?? true){
                  nickname = null;
                }
                widget.onProceed.call(email, nickname);
              },
              child: Text("Proceed to Magic Link Auth", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),),
            ),
          ),
          const SizedBox(height: 50,),
        ],
      ),
    );
  }
}
