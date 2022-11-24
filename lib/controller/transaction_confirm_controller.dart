import 'dart:typed_data';

import 'package:biometric_storage/biometric_storage.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/controller/address_persistent_data.dart';
import 'package:candide_mobile_app/controller/settings_persistent_data.dart';
import 'package:candide_mobile_app/models/batch.dart';
import 'package:candide_mobile_app/models/relay_response.dart';
import 'package:candide_mobile_app/screens/home/components/prompt_password.dart';
import 'package:candide_mobile_app/services/bundler.dart';
import 'package:candide_mobile_app/services/explorer.dart';
import 'package:candide_mobile_app/utils/constants.dart';
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

  static onPressConfirm(Batch batch, TransactionActivity transactionActivity) async {
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
        confirmTransactions(password, batch, transactionActivity);
      }
    }else{
      Get.dialog(PromptPasswordDialog(
        onConfirm: (String password){
          confirmTransactions(password, batch, transactionActivity);
        },
      ));
    }
  }

  static confirmTransactions(String masterPassword, Batch batch, TransactionActivity transactionActivity) async {
    var cancelLoad = Utils.showLoading();
    Credentials? signer = await WalletHelpers.decryptSigner(
      AddressData.wallet,
      masterPassword,
      AddressData.wallet.salt,
    );
    if (signer == null){
      cancelLoad();
      BotToast.showText(
        text: "Incorrect password",
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
        contentColor: Colors.red,
        align: Alignment.topCenter,
      );
      Get.dialog(PromptPasswordDialog(
        onConfirm: (String password){
          confirmTransactions(password, batch);
        },
      ));
      return;
    }
    //
    Uint8List privateKey = (signer as EthPrivateKey).privateKey;
    await Explorer.fetchAddressOverview(address: AddressData.wallet.walletAddress.hexEip55);
    batch.configureNonces(AddressData.walletStatus.nonce);
    batch.signTransactions(privateKey, AddressData.wallet);
    List<UserOperation> unsignedUserOperations = [await batch.toSingleUserOperation(
      AddressData.wallet,
      AddressData.walletStatus.nonce,
      proxyDeployed: AddressData.walletStatus.proxyDeployed,
      managerDeployed: AddressData.walletStatus.managerDeployed,
    )];
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
    if (response?.status.toLowerCase() == "pending"){
      BotToast.showText(
        text: "Transaction still pending, refresh later...",
        textStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        duration: const Duration(seconds: 5),
        contentColor: Get.theme.colorScheme.primary,
        align: Alignment.topCenter,
      );
    }else if (response?.status.toLowerCase() == "failed") {
      BotToast.showText(
        text: "Transaction failed, contact us for help",
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
        duration: const Duration(seconds: 5),
        contentColor: Colors.red,
        align: Alignment.topCenter,
      );
    }else if (response?.status.toLowerCase() == "failed-to-submit"){
      BotToast.showText(
        text: "Transaction failed to submit, contact us for help",
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
        duration: const Duration(seconds: 5),
        contentColor: Colors.red,
        align: Alignment.topCenter,
      );
    }else if (response?.status.toLowerCase() == "success"){
      BotToast.showText(
        text: "Transaction completed!",
        textStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        duration: const Duration(seconds: 5),
        contentColor: Colors.green,
        align: Alignment.topCenter,
      );
    }
    transactionActivity.hash = response?.hash;
    transactionActivity.status = response?.status ?? "fail";
    transactionActivity.fee = TransactionFeeActivityData(
      paymasterAddress: batch.includesPaymaster ? Constants.addressZeroHex : Batch.paymasterAddress.hexEip55,
      currency: batch.getFeeCurrency(),
      fee: batch.getFee(),
    );
    transactionActivity.date = DateTime.now();
    AddressData.storeNewTransactionActivity(transactionActivity, Networks.get(SettingsData.network)!.chainId.toInt());
    cancelLoad();
    Get.back(result: true);
  }
}