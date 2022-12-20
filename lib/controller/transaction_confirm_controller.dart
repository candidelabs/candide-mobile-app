import 'dart:typed_data';

import 'package:biometric_storage/biometric_storage.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/address_persistent_data.dart';
import 'package:candide_mobile_app/controller/settings_persistent_data.dart';
import 'package:candide_mobile_app/models/batch.dart';
import 'package:candide_mobile_app/models/relay_response.dart';
import 'package:candide_mobile_app/screens/home/activity/components/transaction_activity_details_card.dart';
import 'package:candide_mobile_app/screens/home/components/prompt_password.dart';
import 'package:candide_mobile_app/services/bundler.dart';
import 'package:candide_mobile_app/services/explorer.dart';
import 'package:candide_mobile_app/utils/constants.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
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
      BotToast.showText(
        text: "User cancelled authentication",
        textStyle: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),
      );
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
          textStyle: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),
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
        textStyle: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),
        contentColor: Colors.red,
        align: Alignment.topCenter,
      );
      Get.dialog(PromptPasswordDialog(
        onConfirm: (String password){
          confirmTransactions(password, batch, transactionActivity);
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
      textStyle: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Colors.black),
      contentColor: Get.theme.colorScheme.primary,
      align: Alignment.topCenter,
    );
    //
    RelayResponse? response = await Bundler.relayUserOperations(signedUserOperations, SettingsData.network);
    if (response?.status.toLowerCase() == "pending"){
      Utils.showBottomStatus(
        "Transaction still pending",
        "Waiting for confirmation",
        loading: true,
        success: false,
      );
    }else if (response?.status.toLowerCase() == "failed") {
      Utils.showBottomStatus(
        "Transaction failed",
        "Contact us for help",
        loading: false,
        success: false,
        duration: const Duration(seconds: 6),
      );
    }else if (response?.status.toLowerCase() == "failed-to-submit"){
      Utils.showBottomStatus(
        "Transaction failed to submit",
        "Contact us for help",
        loading: false,
        success: false,
        duration: const Duration(seconds: 6),
      );
    }else if (response?.status.toLowerCase() == "success"){
      Utils.showBottomStatus(
        "Transaction completed!",
        "Tap to view transaction details",
        loading: false,
        success: true,
        duration: const Duration(seconds: 6),
        onClick: () async {
          await showBarModalBottomSheet(
            context: Get.context!,
            builder: (context) {
              Get.put<ScrollController>(ModalScrollController.of(context)!, tag: "transaction_details_modal");
              return TransactionActivityDetailsCard(
                transaction: transactionActivity,
              );
            },
          );
        }
      );
    }
    transactionActivity.hash = response?.hash;
    transactionActivity.status = response?.status ?? "fail";
    transactionActivity.fee = TransactionFeeActivityData(
      paymasterAddress: batch.includesPaymaster ? Constants.addressZeroHex : Batch.paymasterAddress.hexEip55,
      currencyAddress: batch.getFeeToken(),
      fee: batch.getFee(),
    );
    transactionActivity.date = DateTime.now();
    AddressData.storeNewTransactionActivity(transactionActivity, Networks.get(SettingsData.network)!.chainId.toInt());
    cancelLoad();
    Get.back(result: true);
  }
}