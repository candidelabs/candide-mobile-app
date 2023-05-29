import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/screens/home/settings/components/setting_menu_item.dart';
import 'package:candide_mobile_app/screens/home/settings/developer_settings/components/debug_verify_endpoints_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DeveloperDebugPage extends StatefulWidget {
  const DeveloperDebugPage({Key? key}) : super(key: key);

  @override
  State<DeveloperDebugPage> createState() => _DeveloperDebugPageState();
}

class _DeveloperDebugPageState extends State<DeveloperDebugPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Developer Debug", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),),
        centerTitle: true,
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
            onPressed: () => Navigator.maybePop(context),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingMenuItem(
            onPress: (){
              Get.dialog(VerifyEndpointsDialog(network: Networks.selected()));
            },
            label: Text("Verify endpoints", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 17)),
            trailing: const Icon(PhosphorIcons.arrowRightBold),
          ),
        ],
      ),
    );
  }
}
