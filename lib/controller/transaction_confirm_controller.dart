import 'dart:typed_data';

import 'package:biometric_storage/biometric_storage.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:candide_mobile_app/controller/address_persistent_data.dart';
import 'package:candide_mobile_app/controller/settings_persistent_data.dart';
import 'package:candide_mobile_app/models/batch.dart';
import 'package:candide_mobile_app/models/relay_response.dart';
import 'package:candide_mobile_app/screens/home/components/prompt_password.dart';
import 'package:candide_mobile_app/services/bundler.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wallet_dart/wallet/user_operation.dart';
import 'package:wallet_dart/wallet/wallet_helpers.dart';
import 'package:web3dart/web3dart.dart';

class TransactionConfirmController {
  static Future<String?> _getPasswordThroughBiometrics() async {
    try{
      final store = await BiometricStorage().getStorage('auth_data');
      String? password = await store.read();
      return password;
    } on AuthException catch(_) {
      BotToast.showText(text: "User cancelled authentication");
      return null;
    }
  }

  static onPressConfirm(Batch batch) async {
    var biometricsEnabled = Hive.box("settings").get("biometrics_enabled");
    if (biometricsEnabled){
      String? password = await _getPasswordThroughBiometrics();
      if (password == null){
        BotToast.showText(
          text: "User cancelled authentication",
          contentColor: Colors.red,
          align: Alignment.topCenter,
        );
        return;
      }else{
        confirmTransactions(password, batch);
      }
    }else{
      Get.dialog(PromptPasswordDialog(
        onConfirm: (String password){
          confirmTransactions(password, batch);
        },
      ));
    }
  }

  static confirmTransactions(String masterPassword, Batch batch) async {
    var cancelLoad = Utils.showLoading();
    Credentials? signer = await WalletHelpers.decryptSigner(
      AddressData.wallet,
      masterPassword,
      AddressData.wallet.salt,
    );
    if (signer == null){
      Utils.showError(title: "Error", message: "Incorrect password");
      return;
    }
    //
    Uint8List privateKey = (signer as EthPrivateKey).privateKey;
    batch.configureNonces(AddressData.walletStatus.nonce);
    batch.signTransactions(privateKey, AddressData.wallet);
    List<UserOperation> unsignedUserOperations = await batch.toUserOperations(
      AddressData.wallet,
      proxyDeployed: AddressData.walletStatus.proxyDeployed,
      managerDeployed: AddressData.walletStatus.managerDeployed,
    );
    //
    var signedUserOperations = await Bundler.signUserOperations(
      signer,
      SettingsData.network,
      unsignedUserOperations,
    );
    //
    BotToast.showText(
      text: "Transaction sent, this might take a minute...",
      textStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
      contentColor: Get.theme.colorScheme.primary,
      align: Alignment.topCenter,
    );
    //
    RelayResponse? response = await Bundler.relayUserOperations(signedUserOperations, SettingsData.network);
    if (response?.status == "PENDING"){
      BotToast.showText(
        text: "Transaction still pending, refresh later...",
        textStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        contentColor: Get.theme.colorScheme.primary,
        align: Alignment.topCenter,
      );
    }else if (response?.status == "FAIL"){
      BotToast.showText(
        text: "Transaction failed, contact us for help",
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
        contentColor: Colors.red,
        align: Alignment.topCenter,
      );
    }else if (response?.status == "SUCCESS"){
      BotToast.showText(
        text: "Transaction completed!",
        textStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        contentColor: Colors.green,
        align: Alignment.topCenter,
      );
    }
    cancelLoad();
    Get.back(result: true);
  }
}