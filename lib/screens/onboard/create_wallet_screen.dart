import 'dart:convert';

import 'package:biometric_storage/biometric_storage.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/address_persistent_data.dart';
import 'package:candide_mobile_app/controller/settings_persistent_data.dart';
import 'package:candide_mobile_app/screens/home/home_screen.dart';
import 'package:candide_mobile_app/screens/onboard/components/credentials_entry.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:wallet_dart/wallet/wallet_helpers.dart';
import 'package:wallet_dart/wallet/wallet_instance.dart';
import 'package:web3dart/web3dart.dart';

class CreateWalletScreen extends StatefulWidget {
  const CreateWalletScreen({Key? key}) : super(key: key);

  @override
  State<CreateWalletScreen> createState() => _CreateWalletScreenState();
}

class _CreateWalletScreenState extends State<CreateWalletScreen> {

  //
  void onRegisterConfirm(String password, bool biometricsEnabled) async {
    if (biometricsEnabled){
      try {
        final store = await BiometricStorage().getStorage('auth_data');
        await store.write(password);
        await Hive.box("settings").put("biometrics_enabled", true);
      } on AuthException catch(_) {
        BotToast.showText(
            text: "User cancelled biometrics auth, please try again",
            contentColor: Colors.red.shade900,
            align: Alignment.topCenter,
            borderRadius: BorderRadius.circular(20)
        );
        return;
      }
    }else{
      await Hive.box("settings").put("biometrics_enabled", false);
    }
    var cancelLoad = Utils.showLoading();
    var salt = base64Encode(Utils.randomBytes(16, secure: true));
    WalletInstance wallet = await WalletHelpers.createRandom(password, salt);
    AddressData.wallet = wallet;
    await Hive.box("wallet").put("main", jsonEncode(wallet.toJson()));
    cancelLoad();
    navigateToHome();
  }

  navigateToHome(){
    AddressData.loadExplorerJson(null);
    SettingsData.loadFromJson(null);
    Get.off(const HomeScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(left: 15, top: 10),
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: (){
                    Get.back();
                  },
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  Lottie.asset('assets/animations/security6.json', width: 275),
                  Center(
                    child: Text("DEFEND YOURSELF", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 25, color: Colors.white),)
                  )
                ],
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    text: "Choose a ",
                    style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 18),
                    children: const [
                      TextSpan(
                        text: "strong",
                        style: TextStyle(color: Colors.deepOrange),
                      ),
                      TextSpan(
                        text: " password to protect your wallet. We'll never have access to it.",
                      )
                    ]
                  )
                ),
              ),
              const SizedBox(height: 25,),
              CredentialsEntry(
                confirmButtonText: "Start your journey",
                onConfirm: onRegisterConfirm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
