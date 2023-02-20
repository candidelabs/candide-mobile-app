import 'package:candide_mobile_app/config/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class OnboardDisclaimerScreen extends StatefulWidget {
  final VoidCallback onContinue;
  const OnboardDisclaimerScreen({Key? key, required this.onContinue}) : super(key: key);

  @override
  State<OnboardDisclaimerScreen> createState() => _OnboardDisclaimerScreenState();
}

class _OnboardDisclaimerScreenState extends State<OnboardDisclaimerScreen> {
  bool _acceptFirstCondition = false;
  bool _acceptSecondCondition = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 40,
        leading: Container(
          margin: const EdgeInsets.only(left: 10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[800],
          ),
          child: IconButton(
            onPressed: (){
              Get.back();
            },
            padding: const EdgeInsets.all(0),
            splashRadius: 15,
            style: const ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(PhosphorIcons.caretLeftBold, size: 17,),
          ),
        ),
      ),
      body: Container(
        margin: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Disclaimer", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 35),),
            const SizedBox(height: 10,),
            const Text("CANDIDE Wallet is in alpha release and may experience technical issues or introduce breaking changes from time to time.\n\nBy using CANDIDE wallet, you accept the following:"),
            const SizedBox(height: 10,),
            Directionality(
              textDirection: TextDirection.rtl,
              child: CheckboxListTile(
                onChanged: (val) => setState(() => _acceptFirstCondition = (val ?? false)),
                value: _acceptFirstCondition,
                activeColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                  side: BorderSide(color: Get.theme.colorScheme.primary.withOpacity(0.5), width: 0.4)
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                title: const Text(
                  "I understand that CANDIDE may introduce changes that make my existing account unsafe/unusable and force me to create/migrate to new ones",
                  textDirection: TextDirection.ltr,
                ),
              ),
            ),
            const SizedBox(height: 10,),
            Directionality(
              textDirection: TextDirection.rtl,
              child: CheckboxListTile(
                onChanged: (val) => setState(() => _acceptSecondCondition = (val ?? false)),
                value: _acceptSecondCondition,
                activeColor: Colors.blue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                    side: BorderSide(color: Get.theme.colorScheme.primary.withOpacity(0.5), width: 0.4)
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                title: const Text(
                  "I understand that CANDIDE may experience technical issues and my transactions may fail for various reasons.",
                  textDirection: TextDirection.ltr,
                ),
              ),
            ),
            const SizedBox(height: 10,),
            SizedBox(
              width: 120,
              child: ElevatedButton(
                onPressed: _acceptFirstCondition && _acceptSecondCondition ? (){
                  widget.onContinue.call();
                } : null,
                style: ButtonStyle(
                  shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)
                  )),
                ),
                child: Text("Continue", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
