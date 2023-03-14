import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:candide_mobile_app/controller/settings_persistent_data.dart';
import 'package:candide_mobile_app/controller/signers_controller.dart';
import 'package:candide_mobile_app/screens/home/home_screen.dart';
import 'package:candide_mobile_app/screens/onboard/components/wallet_onboarding.dart';
import 'package:candide_mobile_app/screens/onboard/create_account/pin_entry_screen.dart';
import 'package:candide_mobile_app/utils/events.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:wallet_dart/wallet/account_helpers.dart';
import 'package:web3dart/web3dart.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  navigateToHome(){
    PersistentData.loadExplorerJson(PersistentData.selectedAccount, null);
    SettingsData.loadFromJson(null);
    Get.off(const HomeScreen());
  }

  authenticate() async {
    Get.to(PinEntryScreen(
      showLogo: true,
      promptText: "Enter PIN code",
      confirmMode: false,
      onPinEnter: (String pin, _) async {
        var cancelLoad = Utils.showLoading();
        Credentials? credentials = await AccountHelpers.decryptSigner(
          SignersController.instance.getSignerFromId("main")!,
          pin,
        );
        if (credentials == null){
          cancelLoad();
          eventBus.fire(OnPinErrorChange(error: "Incorrect PIN"));
          return null;
        }
        SignersController.instance.storePrivateKey("main", credentials as EthPrivateKey);
        cancelLoad();
        Get.back(result: true);
        navigateToHome();
      },
    ));
  }

  initialize() async {
    await Future.wait([
      Hive.openBox("signers"),
      Hive.openBox("wallet"),
      Hive.openBox("settings"),
      Hive.openBox("state"),
      Hive.openBox("activity"),
      Hive.openBox("wallet_connect"),
      Hive.openBox("tokens_storage"),
    ]);
    Networks.initialize();
    Networks.configureVisibility();
    PersistentData.loadSigners();
    PersistentData.loadAccounts();
    SettingsData.loadFromJson(null);
    //
    if (PersistentData.accounts.isEmpty){
      Get.off(const WalletOnboarding());
    }else{
      eventBus.fire(OnAccountChange());
      authenticate();
    }
  }

  @override
  void initState() {
    initialize();
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              "assets/images/logov3.svg",
              width: Get.width * 0.8,
              color: Get.theme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
