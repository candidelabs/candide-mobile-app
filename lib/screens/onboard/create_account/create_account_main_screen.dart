import 'package:animations/animations.dart';
import 'package:biometric_storage/biometric_storage.dart';
import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:candide_mobile_app/controller/settings_persistent_data.dart';
import 'package:candide_mobile_app/controller/signers_controller.dart';
import 'package:candide_mobile_app/screens/home/home_screen.dart';
import 'package:candide_mobile_app/screens/onboard/create_account/create_account_chain_screen.dart';
import 'package:candide_mobile_app/screens/onboard/create_account/pin_entry_screen.dart';
import 'package:candide_mobile_app/utils/events.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:eth_sig_util/util/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wallet_dart/wallet/account.dart';
import 'package:wallet_dart/wallet/account_helpers.dart';
import 'package:wallet_dart/wallet/encrypted_signer.dart';
import 'package:web3dart/credentials.dart';

class CreateAccountMainScreen extends StatefulWidget {
  final Account? baseAccount; // account to inherit some properties from, like encrypted signer, initial owner, etc..
  const CreateAccountMainScreen({Key? key, this.baseAccount}) : super(key: key);

  @override
  State<CreateAccountMainScreen> createState() => _CreateAccountMainScreenState();
}

class _CreateAccountMainScreenState extends State<CreateAccountMainScreen> {
  var pagesList = [];
  bool reverse = false;
  int currentIndex = 0;
  //
  String name = "Account 1";
  int chainId = 10;

  void onRegisterConfirm(String? password, bool biometricsEnabled) async {
    if (password == null && widget.baseAccount == null) return;
    if (password != null && biometricsEnabled){
      try {
        final store = await BiometricStorage().getStorage('auth_data');
        await store.write(password);
        await Hive.box("settings").put("biometrics_enabled", true);
      } on AuthException catch(_) {
        eventBus.fire(OnPinErrorChange(error: "User cancelled biometrics auth, please try again"));
        return;
      }
    }else if (password != null && !biometricsEnabled){
      await Hive.box("settings").put("biometrics_enabled", false);
    }
    var cancelLoad = Utils.showLoading();
    Network network = Networks.getByChainId(chainId)!;
    if (PersistentData.walletSigners.isEmpty){
      var signerSalt = bytesToHex(Utils.randomBytes(16, secure: true));
      EncryptedSigner mainSigner = await AccountHelpers.createEncryptedSigner(salt: signerSalt, password: password!);
      await PersistentData.addSigner("main", mainSigner);
    }
    EncryptedSigner mainSigner = SignersController.instance.getSignerFromId("main")!;
    String salt = bytesToHex(Utils.randomBytes(16, secure: true), include0x: false);
    Account account = await AccountHelpers.createAccount(
      chainId: network.chainId.toInt(),
      name: name,
      signers: [mainSigner.publicAddress],
      signersIds: ["main"],
      salt: salt,
      singleton: network.safeSingleton,
      factory: network.proxyFactory,
      fallbackHandler: network.fallbackHandler,
      entrypoint: network.entrypoint,
    );
    if (SignersController.instance.privateKeys.isEmpty && password != null){
      Credentials? credentials = await AccountHelpers.decryptSigner(mainSigner, password);
      SignersController.instance.storePrivateKey("main", credentials! as EthPrivateKey);
    }
    await PersistentData.insertAccount(account);
    PersistentData.selectAccount(address: account.address, chainId: account.chainId);
    eventBus.fire(OnAccountChange());
    cancelLoad();
    navigateToHome();
  }

  navigateToHome(){
    PersistentData.loadExplorerJson(PersistentData.selectedAccount, null);
    SettingsData.loadFromJson(null);
    Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=> const HomeScreen()));
  }

  void onBackPress(){
    if (currentIndex == 0){
      Get.back();
      return;
    }
    setState(() {
      reverse = true;
      currentIndex--;
    });
  }

  @override
  void initState() {
    pagesList = [
      CreateAccountChainScreen(
        onNext: (String _name, int _chain){
          name = _name;
          chainId = _chain;
          if (widget.baseAccount != null){
            bool biometricEnabled = Hive.box("settings").get("biometrics_enabled", defaultValue: false);
            onRegisterConfirm(null, biometricEnabled);
            return;
          }
          setState(() {
            reverse = false;
            currentIndex = 1;
          });
        },
        onBack: onBackPress,
        confirmButtonLabel: widget.baseAccount == null ? "Next" : "Create account",
      ),
      PinEntryScreen(
        showLogo: false,
        promptText: "Choose a PIN to unlock your wallet",
        confirmText: "Confirm your chosen PIN",
        confirmMode: true,
        showBiometricsToggle: true,
        onPinEnter: onRegisterConfirm,
        onBack: onBackPress,
      ),
    ];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageTransitionSwitcher(
          transitionBuilder: (
              Widget child,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
              ) {
            return SharedAxisTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              transitionType: SharedAxisTransitionType.horizontal,
              child: child,
            );
          },
          duration: const Duration(milliseconds: 400),
          reverse: reverse,
          child: pagesList[currentIndex],
        ),
      ),
    );
  }
}
