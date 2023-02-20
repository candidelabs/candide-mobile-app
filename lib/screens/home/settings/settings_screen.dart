import 'package:biometric_storage/biometric_storage.dart';
import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:candide_mobile_app/controller/signers_controller.dart';
import 'package:candide_mobile_app/screens/home/settings/custom_license_page.dart';
import 'package:candide_mobile_app/screens/home/settings/test_token_account_selection.dart';
import 'package:candide_mobile_app/screens/onboard/create_account/pin_entry_screen.dart';
import 'package:candide_mobile_app/utils/events.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wallet_dart/wallet/account.dart';
import 'package:wallet_dart/wallet/account_helpers.dart';
import 'package:wallet_dart/wallet/encrypted_signer.dart';
import 'package:web3dart/web3dart.dart';

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
    bool success = await AccountHelpers.reEncryptSigner(copy, newPin!);
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

  tweetToClaimTestTokens(Account account) async {
    Network network = Networks.getByChainId(account.chainId)!;
    var tweetUrl = "https://twitter.com/intent/tweet?text=I%27m%20claiming%20testnet%20tokens%20for%20%40candidewallet%2C%20a%20smart%20contract%20wallet%20based%20on%20ERC4337!%20%0a%0aMy%20Address%3A%20${account.address.hexEip55}%20%0aNetwork%3A%20${network.normalizedName}";
    Utils.launchUri(tweetUrl, mode: LaunchMode.externalApplication);
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
          _showBiometricsToggle ? _MenuItem(
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
              //tweetToClaimTestTokens();
              showDialog(
                context: context,
                builder: (_) => TestTokenAccountSelection(
                  onSelect: (Account account){
                    tweetToClaimTestTokens(account);
                  },
                )
              );
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
          const Spacer(),
          const Center(
            child: _CandideCommunityWidget()
          ),
          const SizedBox(height: 10,),
        ],
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

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12)
      ),
      color: Get.theme.cardColor,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Color(0xff7289da),
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                backgroundColor: Colors.transparent,
                child: IconButton(
                  onPressed: () => Utils.launchUri("https://discord.gg/QQ6R9Ac5ah"),
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
                  onPressed: () => Utils.launchUri("https://twitter.com/candidewallet"),
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
                  onPressed: () => Utils.launchUri("https://github.com/candidelabs"),
                  icon: const Icon(FontAwesomeIcons.github, color: Colors.white, size: 22,),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

