import 'dart:convert';

import 'package:biometric_storage/biometric_storage.dart';
import 'package:candide_mobile_app/config/env.dart';
import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/controller/address_persistent_data.dart';
import 'package:candide_mobile_app/controller/security.dart';
import 'package:candide_mobile_app/controller/settings_persistent_data.dart';
import 'package:candide_mobile_app/models/recovery_request.dart';
import 'package:candide_mobile_app/screens/home/home_screen.dart';
import 'package:candide_mobile_app/screens/onboard/landing_screen.dart';
import 'package:candide_mobile_app/screens/onboard/recovery/recovery_request_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:wallet_dart/wallet/wallet_instance.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  navigateToHome(){
    AddressData.loadExplorerJson(null);
    SettingsData.loadFromJson(null);
    Get.off(const HomeScreen());
  }

  askForBiometrics() async {
    try{
      var biometricsEnabled = Hive.box("settings").get("biometrics_enabled");
      if (biometricsEnabled == null || !biometricsEnabled){
        navigateToHome();
      }
      final store = await BiometricStorage().getStorage('auth_data');
      String? password = await store.read();
      if (password != null){
        navigateToHome();
      }
    } on AuthException catch(_) {
      askForBiometrics();
      return;
    }

  }

  initialize() async {
    await Hive.openBox("wallet");
    await Hive.openBox("settings");
    await Hive.openBox("state");
    Networks.initialize();
    SettingsData.loadFromJson(null);
    AddressData.loadRecoveryRequest();
    if (AddressData.recoveryRequestId != null){ // todo re-enable
      RecoveryRequest? request = await SecurityGateway.fetchById(AddressData.recoveryRequestId!);
      if (request != null){
        Get.off(RecoveryRequestPage(request: request));
        return;
      }
    }
    var wallet = Hive.box("wallet").get("main");
    //
    //wallet = null; // todo remove
    /*if (wallet == null){ // todo remove
      wallet = '{"walletAddress":"0x011341fb589cd6566124e61c0b770a8a48f17397","initImplementation":"0x4f7459eff03cd8c19b5a442d7c9b675a05f66fbf","initOwner":"0xc26976587aed81a811c7d5e1084e8fd0da178ad7","initGuardians":[],"salt":"sDbtw1e/Wyk2TnzQcFo5Tg==","encryptedSigner":"b0+pMyCcW7fm9GCqtBUJwDH2NxuXgLZ2yHK9oULUQKuaV1yT0kVkxlOi29oFmAlnIc8okqbKNhuPa2UgSi9CNwxhDiWTT+ospds4FfY+7as="}';
      await (await BiometricStorage().getStorage("auth_data")).write("StrongPass1@");
      await Hive.box("settings").put("biometrics_enabled", true);
    }*/
    //
    if (wallet == null){
      Get.off(const LandingScreen(), transition: Transition.rightToLeftWithFade);
    }else{
      AddressData.wallet = WalletInstance.fromJson(jsonDecode(wallet));
      askForBiometrics();
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
