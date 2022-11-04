import 'package:candide_mobile_app/config/env.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/address_persistent_data.dart';
import 'package:candide_mobile_app/screens/components/confirm_dialog.dart';
import 'package:candide_mobile_app/screens/onboard/landing_screen.dart';
import 'package:candide_mobile_app/services/explorer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _debugFieldController = TextEditingController();

  void refreshDebugFieldText(bool forceDataReload) async {
    if (forceDataReload){
      _debugFieldController.text = "";
      await Explorer.fetchAddressOverview(address: AddressData.wallet.walletAddress.hex,);
    }
    String debugText = "";
    debugText += "Manager deployed: ${AddressData.walletStatus.managerDeployed}\n";
    debugText += "Proxy deployed: ${AddressData.walletStatus.proxyDeployed}\n";
    debugText += "Social recovery module deployed: ${AddressData.walletStatus.socialModuleDeployed}\n";
    debugText += "Nonce: ${AddressData.walletStatus.nonce}\n";
    _debugFieldController.text = debugText;
  }

  @override
  void initState() {
    refreshDebugFieldText(false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                margin: const EdgeInsets.only(left: 15, top: 25),
                child: Text("Settings", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 25),)
            ),
            const SizedBox(height: 15,),
            _MenuItem(
              onPress: (){},
              //leading: const Icon(PhosphorIcons.info),
              label: RichText(
                text: TextSpan(
                  text: "About ",
                  style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 17),
                  children: [
                    TextSpan(
                      text: "CANDIDE",
                        style: TextStyle(color: Get.theme.colorScheme.primary, fontSize: 15)
                    )
                  ]
                ),
              ),
              trailing: const Icon(PhosphorIcons.arrowRightBold),
            ),
            const Divider(indent: 10, endIndent: 10,),
            Container(
              width: double.maxFinite,
              height: 45,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              child: ElevatedButton(
                onPressed: () async {
                  bool delete = await confirm(
                    context,
                    title: const Text("Are you sure ?"),
                    content: const Text("Are you sure you want to delete your wallet locally from this device ?\nPlease review your security settings and options before proceeding to be able to gain access later to this wallet"),
                  );
                  if (delete){
                    await Hive.box("wallet").delete("main");
                    await Hive.box("state").clear();
                    Get.off(const LandingScreen());
                  }
                },
                style: ButtonStyle(
                  elevation: MaterialStateProperty.all(0),
                  backgroundColor: MaterialStateProperty.all(Colors.transparent),
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(5)),
                    side: BorderSide(color: Colors.redAccent[700]!, width: 1)
                  ))
                ),
                child: Text("Remove Wallet", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 15, color: Colors.redAccent[700]),),
              ),
            ),
            kDebugMode || Env.testnet ? Column(
              children: [
                const SizedBox(height: 10,),
                const Divider(indent: 10, endIndent: 10, thickness: 2,),
                const SizedBox(height: 5,),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      const Text("Debug info:"),
                      const Spacer(),
                      IconButton(
                        onPressed: (){
                          refreshDebugFieldText(true);
                        },
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5,),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  child: TextField(
                    controller: _debugFieldController,
                    maxLines: 5,
                    minLines: 5,
                    enabled: false,
                    decoration: const InputDecoration(
                      disabledBorder: OutlineInputBorder(borderSide: BorderSide(width: 3, color: Colors.grey)),
                    ),
                  ),
                )
              ],
            ) : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final Widget label;
  final Widget? description;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback onPress;
  const _MenuItem({Key? key, required this.label, this.description, this.leading, this.trailing, required this.onPress}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      child: Card(
        child: InkWell(
          onTap: onPress,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
            child: Row(
              children: [
                leading != null ? Container(
                  margin: const EdgeInsets.only(right: 7.5),
                  child: leading
                ) : const SizedBox.shrink(),
                Column(
                  children: [
                    label,
                  ],
                ),
                const Spacer(),
                trailing != null ? Container(
                    margin: const EdgeInsets.only(right: 5),
                    child: trailing
                ) : const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

