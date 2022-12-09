import 'dart:convert';

import 'package:biometric_storage/biometric_storage.dart';
import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/controller/address_persistent_data.dart';
import 'package:candide_mobile_app/services/security.dart';
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
    await Future.wait([
      Hive.openBox("wallet"),
      Hive.openBox("settings"),
      Hive.openBox("state"),
      Hive.openBox("activity"),
      Hive.openBox("wallet_connect"),
    ]);
    Networks.initialize();
    SettingsData.loadFromJson(null);
    AddressData.loadRecoveryRequest();
    AddressData.loadTransactionsActivity(Networks.get(SettingsData.network)!.chainId.toInt());
    if (AddressData.recoveryRequestId != null){ // todo re-enable
      RecoveryRequest? request = await SecurityGateway.fetchById(AddressData.recoveryRequestId!);
      if (request != null){
        Get.off(RecoveryRequestPage(request: request));
        return;
      }
    }
    var wallet = Hive.box("wallet").get("main");
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
