import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/screens/components/continous_input_border.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MagicEmailSheet extends StatefulWidget {
  final Function(String) onProceed;
  const MagicEmailSheet({Key? key, required this.onProceed}) : super(key: key);

  @override
  State<MagicEmailSheet> createState() => _MagicEmailSheetState();
}

class _MagicEmailSheetState extends State<MagicEmailSheet> {
  String email = "";
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
            margin: const EdgeInsets.symmetric(horizontal: 25),
            child: TextFormField(
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
            ),
          ),
          const SizedBox(height: 25,),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 25),
            //child: const Text("By proceeding you agree to Candide's terms and conditions and to Magic Link's terms and conditions")
            child: RichText(
              text: TextSpan(
                text: "By proceeding you agree to Candide's ",
                style: const TextStyle(fontStyle: FontStyle.italic),
                children: [
                  TextSpan(
                    text: "terms and conditions ",
                    style: const TextStyle(color: Colors.blue),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {}, // todo add terms of service
                  ),
                  const TextSpan(
                    text: "and to Magic Link's ",
                  ),
                  TextSpan(
                    text: "terms and conditions",
                    style: const TextStyle(color: Colors.blue),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {}, // todo add terms of service
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
                widget.onProceed.call(email);
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
