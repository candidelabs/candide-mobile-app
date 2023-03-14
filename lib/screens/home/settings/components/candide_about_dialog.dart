import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/screens/home/settings/components/custom_license_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CandideAboutDialog extends StatelessWidget {
  final String applicationName;
  final String applicationVersion;
  const CandideAboutDialog({Key? key, required this.applicationName, required this.applicationVersion}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      content: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(applicationName, style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 25, color: Get.theme.colorScheme.primary),),
            Text(applicationVersion, style: const TextStyle(color: Colors.grey, fontSize: 12),),
            const SizedBox(height: 30,),
            const Text("CANDIDE Wallet is an open source Ethereum wallet built as a public good. "),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            Get.to(CustomLicensePage(
              applicationName: applicationName,
              applicationVersion: applicationVersion,
            ));
          },
          child: Text("VIEW OPEN LICENSES", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text("CLOSE", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),),
        ),
      ],
    );
  }
}