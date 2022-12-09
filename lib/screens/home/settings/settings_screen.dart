import 'dart:convert';

import 'package:biometric_storage/biometric_storage.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/address_persistent_data.dart';
import 'package:candide_mobile_app/controller/wallet_connect_controller.dart';
import 'package:candide_mobile_app/screens/components/confirm_dialog.dart';
import 'package:candide_mobile_app/screens/home/components/change_password_dialog.dart';
import 'package:candide_mobile_app/screens/home/components/prompt_password.dart';
import 'package:candide_mobile_app/screens/home/settings/custom_license_page.dart';
import 'package:candide_mobile_app/screens/home/wallet_connect/wc_connections_page.dart';
import 'package:candide_mobile_app/screens/onboard/landing_screen.dart';
import 'package:candide_mobile_app/services/explorer.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wallet_dart/wallet/wallet_helpers.dart';
import 'package:wallet_dart/wallet/wallet_instance.dart';
import 'package:web3dart/web3dart.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  BiometricStorageFile? biometricStorage;
  late String tweetUrl;

  Future<String?> getPasswordThroughBiometrics() async {
    try{
      biometricStorage = await BiometricStorage().getStorage('auth_data');
      String? password = await biometricStorage!.read();
      return password;
    } on AuthException catch(_) {
      return null;
    }
  }

  Future<String?> getUserPassword() async {
    var biometricsEnabled = Hive.box("settings").get("biometrics_enabled");
    if (biometricsEnabled){
      String? password = await getPasswordThroughBiometrics();
      if (password == null){
        return null;
      }else{
        return password;
      }
    }else{
      String? password;
      await Get.dialog(PromptPasswordDialog(
        onConfirm: (String _password){
          password = _password;
        },
      ));
      return password;
    }
  }

  Future<Tuple<String, Credentials>?> validateUser() async {
    String? password = await getUserPassword();
    if (password == null) return null;
    var cancelLoad = Utils.showLoading();
    Credentials? signer = await WalletHelpers.decryptSigner(
      AddressData.wallet,
      password,
      AddressData.wallet.salt,
    );
    cancelLoad();
    if (signer == null){
      Utils.showError(title: "Error", message: "Incorrect password");
      return null;
    }
    return Tuple(a: password, b: signer);
  }

  void changePassword() async {
    Tuple? validationData = await validateUser();
    String? password = validationData?.a;
    if (password == null) return;
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (_) => ChangePasswordDialog(
        onConfirm: (String newPassword) async {
          Navigator.pop(context);
          var cancelLoad = Utils.showLoading();
          WalletInstance? newInstance = await WalletHelpers.reEncryptSigner(AddressData.wallet, newPassword, AddressData.wallet.salt, password: password, credentials: (validationData!.b as EthPrivateKey));
          cancelLoad();
          if (newInstance == null) return;
          var biometricsEnabled = Hive.box("settings").get("biometrics_enabled");
          if (biometricsEnabled){
            try{
              await biometricStorage!.write(newPassword);
            } on AuthException catch(_) {
              Utils.showError(title: "Error", message: "User cancelled auth, password not changed!");
              return null;
            }
          }
          AddressData.wallet = newInstance;
          await Hive.box("wallet").put("main", jsonEncode(newInstance.toJson()));
        }
      ),
    );
  }

  void toggleFingerprint() async {
    String? password = (await validateUser())?.a;
    if (password == null) return;
    var biometricsEnabled = Hive.box("settings").get("biometrics_enabled");
    if (biometricsEnabled){
      await biometricStorage!.delete();
      await Hive.box("settings").put("biometrics_enabled", false);
    }else{
      biometricStorage = await BiometricStorage().getStorage('auth_data');
      await biometricStorage!.write(password);
      await Hive.box("settings").put("biometrics_enabled", true);
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
  }

  tweetToClaimTestTokens() async {
    var tweetUrl = "https://twitter.com/intent/tweet?text=I%27m+claiming+testnet+tokens+for+%40candidewallet%2C+a+smart+contract+wallet+based+on+ERC4337!%0A%0AMy+Address%3A+${AddressData.wallet.walletAddress.hexEip55}";
    if(await canLaunchUrl(Uri.parse(tweetUrl))) {
      await launchUrl(Uri.parse(tweetUrl), mode: LaunchMode.externalApplication);
    } else {
      throw "Could not launch $tweetUrl";
    }
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
              onPress: (){
                changePassword();
              },
              leading: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.red[900]!,
                      Colors.redAccent[700]!,
                    ],
                  ),
                ),
                child: const CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: Icon(PhosphorIcons.passwordLight, color: Colors.white,),
                ),
              ),
              label: Text("Change Password", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 17)),
              trailing: const Icon(PhosphorIcons.arrowRightBold),
            ),
            _MenuItem(
              onPress: (){
                toggleFingerprint();
              },
              leading: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue,
                      Colors.blueGrey,
                    ],
                  ),
                ),
                child: const CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: Icon(PhosphorIcons.fingerprint, color: Colors.white,),
                ),
              ),
              label: Text("Enable Fingerprint", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 17)),
              description: const Text("Enable fingerprint to authorize transactions and access your wallet",),
              trailing: Switch(
                onChanged: (val){
                  toggleFingerprint();
                },
                value: Hive.box("settings").get("biometrics_enabled"),
                activeColor: Colors.blue,
              ),
            ),
            _MenuItem(
              leading: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.indigo,
                      Colors.indigoAccent,
                    ],
                  ),
                ),
                child: const CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: Icon(PhosphorIcons.link, color: Colors.white,),
                ),
              ),
              label: RichText(
                text: TextSpan(
                  text: "Connected dApps",
                  style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 17),
                ),
              ),
              trailing: const Icon(PhosphorIcons.arrowRightBold),
              onPress: () {
                Get.to(const WCConnectionsPage());
              },
              description: const Text("Manage dApp connections",),
            ),
            _MenuItem(
              leading: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.yellow,
                      Colors.green,
                    ],
                  ),
                ),
                child: const CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: Icon(PhosphorIcons.coins, color: Colors.white,),
                ),
              ),
              label: RichText(
                text: TextSpan(
                  text: "Request Test Tokens",
                  style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 17),
                ),
              ),
              trailing: const Icon(PhosphorIcons.twitterLogo),
              onPress: () {
                tweetToClaimTestTokens();
              },
              description: const Text("Use the social faucet to get test tokens",),
            ),
            _MenuItem(
              onPress: () async {
                PackageInfo packageInfo = await PackageInfo.fromPlatform();
                String version = packageInfo.version;
                Get.dialog(_AboutDialog(
                  applicationName: "CANDIDE",
                  applicationVersion: version,
                ));
              },
              leading: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Get.theme.colorScheme.primary,
                      Colors.teal,
                    ],
                  ),
                ),
                child: const CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: Icon(PhosphorIcons.infoLight, color: Colors.white,),
                ),
              ),
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
            const SizedBox(height: 5,),
            const _CandideCommunityWidget(),
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
                    content: const Text("You are about to delete your wallet locally from this device. \n\nYou will need your Guardians and your public address / ENS to regain access to your account again"),
                  );
                  if (delete){
                    await WalletConnectController.disconnectAllSessions();
                    await Hive.box("wallet").delete("main");
                    await Hive.box("state").clear();
                    await Hive.box("activity").clear();
                    await Hive.box("wallet_connect").clear();
                    AddressData.transactionsActivity.clear();
                    AddressData.guardians.clear();
                    Get.off(const LandingScreen());
                  }
                },
                style: ButtonStyle(
                  elevation: MaterialStateProperty.all(0),
                  backgroundColor: MaterialStateProperty.all(Colors.transparent),
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    side: BorderSide(color: Colors.redAccent[700]!, width: 1)
                  ))
                ),
                child: Text("Remove Wallet", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 15, color: Colors.redAccent[700]),),
              ),
            ),
            kDebugMode ? _DebugWidget() : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

class _AboutDialog extends StatelessWidget {
  final String applicationName;
  final String applicationVersion;
  const _AboutDialog({Key? key, required this.applicationName, required this.applicationVersion}) : super(key: key);

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


class _DebugWidget extends StatelessWidget {
  _DebugWidget({Key? key}) : super(key: key);
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
  Widget build(BuildContext context) {
    refreshDebugFieldText(false);
    return Column(
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
        ),
        const SizedBox(height: 15,),
      ],
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
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)
        ),
        child: InkWell(
          onTap: onPress,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
            child: Row(
              children: [
                leading != null ? Container(
                  margin: const EdgeInsets.only(right: 7.5),
                  child: leading
                ) : const SizedBox.shrink(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    label,
                    description != null ? Container(
                      margin: const EdgeInsets.only(top: 5),
                      width: Get.width * 0.55,
                      child: description!
                    ) : const SizedBox.shrink(),
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

class _CandideCommunityWidget extends StatelessWidget {
  const _CandideCommunityWidget({Key? key}) : super(key: key);

  launchUri(Uri uri) async {
    if(await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw "Could not launch ${uri.host}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)
        ),
        color: Get.theme.colorScheme.primary,
        child: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.symmetric(vertical: 10),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Join CANDIDE Community", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Get.theme.colorScheme.onPrimary),),
              const SizedBox(height: 5,),
              Text("Come share your feedback and contribute in creating the most fun and accessible open source wallet 🐪", style: TextStyle(color: Get.theme.colorScheme.onPrimary.withOpacity(0.9)),),
              const SizedBox(height: 5,),
              Text("You can find us on:", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Get.theme.colorScheme.onPrimary.withOpacity(0.9)),),
              const SizedBox(height: 5,),
              Row(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xff7289da),
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      backgroundColor: Colors.transparent,
                      child: IconButton(
                        onPressed: () => launchUri(Uri.parse("https://discord.gg/QQ6R9Ac5ah")),
                        icon: const Icon(Icons.discord, color: Colors.white,),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10,),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xff1DA1F2),
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      backgroundColor: Colors.transparent,
                      child: IconButton(
                        onPressed: () => launchUri(Uri.parse("https://twitter.com/candidewallet")),
                        icon: const Icon(FontAwesomeIcons.twitter, color: Colors.white, size: 22,),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10,),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xff333333),
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      backgroundColor: Colors.transparent,
                      child: IconButton(
                        onPressed: () => launchUri(Uri.parse("https://github.com/candidelabs")),
                        icon: const Icon(FontAwesomeIcons.github, color: Colors.white, size: 22,),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

