import 'package:biometric_storage/biometric_storage.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:candide_mobile_app/controller/signers_controller.dart';
import 'package:candide_mobile_app/screens/home/settings/components/candide_about_dialog.dart';
import 'package:candide_mobile_app/screens/home/settings/components/candide_community_widget.dart';
import 'package:candide_mobile_app/screens/home/settings/components/setting_menu_item.dart';
import 'package:candide_mobile_app/screens/onboard/create_account/pin_entry_screen.dart';
import 'package:candide_mobile_app/utils/events.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:wallet_dart/wallet/account_helpers.dart';
import 'package:wallet_dart/wallet/encrypted_signer.dart';
import 'package:web3dart/web3dart.dart';

import 'developer_settings/developer_settings_page.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late BiometricStorageFile biometricStorage;
  bool _showBiometricsToggle = false;
  late String tweetUrl;

  Future<Tuple<String, Credentials>?> authenticateUser() async {
    Tuple<String, Credentials>? result;
    await Get.to(PinEntryScreen(
      showLogo: true,
      promptText: "Enter PIN code",
      confirmMode: false,
      onPinEnter: (String pin, _) async {
        var cancelLoad = Utils.showLoading();
        Credentials? signer = await AccountHelpers.decryptSigner(
          SignersController.instance.getSignersFromAccount(PersistentData.selectedAccount).first!,
          pin,
        );
        cancelLoad();
        if (signer == null){
          eventBus.fire(OnPinErrorChange(error: "Incorrect PIN"));
          return null;
        }
        result = Tuple(a: pin, b: signer);
        Get.back();
      },
      onBack: (){
        Get.back();
      },
    ));
    return result;
  }

  void changePassword() async {
    Tuple? validationData = await authenticateUser();
    String? password = validationData?.a;
    if (!mounted) return;
    if (password == null) return;
    String? newPin;
    bool useBiometrics = false;
    await Get.to(PinEntryScreen(
      showLogo: false,
      promptText: "Choose a PIN to unlock your wallet",
      confirmText: "Confirm your chosen PIN",
      confirmMode: true,
      showBiometricsToggle: true,
      onPinEnter: (String _newPin, bool _useBiometrics) async {
        newPin = _newPin;
        useBiometrics = _useBiometrics;
        Get.back();
      },
      onBack: (){
        Get.back();
      },
    ));
    if (newPin == null) return;
    var cancelLoad = Utils.showLoading();
    EncryptedSigner encryptedSigner = SignersController.instance.getSignersFromAccount(PersistentData.selectedAccount).first!;
    EncryptedSigner copy = EncryptedSigner.fromJson(encryptedSigner.toJson());
    bool success = await AccountHelpers.reEncryptSigner(copy, newPin!, credentials: SignersController.instance.getPrivateKeyFromSignerId(PersistentData.selectedAccount.signersIds.first));
    cancelLoad();
    if (!success) return;
    if (useBiometrics){
      try{
        await biometricStorage.write(newPin!);
      } on AuthException catch(_) {
        Utils.showError(title: "Error", message: "User cancelled auth, password not changed!");
        return null;
      }
    }
    encryptedSigner.encryptedPrivateKey = copy.encryptedPrivateKey;
    PersistentData.saveSigners();
  }

  void toggleFingerprint() async {
    var biometricsEnabled = Hive.box("settings").get("biometrics_enabled");
    if (!biometricsEnabled){
      final response = await BiometricStorage().canAuthenticate();
      if (response != CanAuthenticateResponse.success){
        Utils.showError(title: "Error", message: "No biometrics detected.");
        return;
      }
    }
    String? password = (await authenticateUser())?.a;
    if (password == null) return;
    if (biometricsEnabled){
      await biometricStorage.delete();
      await Hive.box("settings").put("biometrics_enabled", false);
    }else{
      await biometricStorage.write(password);
      await Hive.box("settings").put("biometrics_enabled", true);
    }
    setState(() {});
  }

  @override
  void initState() {
    BiometricStorage().canAuthenticate().then((response) async {
      if (response == CanAuthenticateResponse.success){
        biometricStorage = await BiometricStorage().getStorage('auth_data');
        setState(() => _showBiometricsToggle = true);
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),),
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
            onPressed: () => Get.back(),
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
          const SizedBox(height: 15,),
          SettingMenuItem(
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
          _showBiometricsToggle ? SettingMenuItem(
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
          ) : const SizedBox.shrink(),
          SettingMenuItem(
            onPress: (){
              Get.to(const DeveloperSettingsPage(), transition: Transition.rightToLeft);
            },
            leading: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.deepPurple,
                    Colors.deepPurpleAccent,
                  ],
                ),
              ),
              child: const CircleAvatar(
                backgroundColor: Colors.transparent,
                child: Icon(PhosphorIcons.code, color: Colors.white,),
              ),
            ),
            label: Text("Developer Settings", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 17)),
            trailing: const Icon(PhosphorIcons.arrowRightBold),
          ),
          SettingMenuItem(
            onPress: () async {
              PackageInfo packageInfo = await PackageInfo.fromPlatform();
              String version = packageInfo.version;
              Get.dialog(CandideAboutDialog(
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
          const Spacer(),
          const Center(
            child: CandideCommunityWidget()
          ),
          const SizedBox(height: 10,),
        ],
      ),
    );
  }
}





