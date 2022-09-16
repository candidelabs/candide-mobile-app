import 'package:biometric_storage/biometric_storage.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:candide_mobile_app/models/guardian_operation.dart';
import 'package:candide_mobile_app/controller/address_persistent_data.dart';
import 'package:candide_mobile_app/controller/bundler.dart';
import 'package:candide_mobile_app/controller/hooks/guardian_hook.dart';
import 'package:candide_mobile_app/controller/settings_persistent_data.dart';
import 'package:candide_mobile_app/models/relay_response.dart';
import 'package:candide_mobile_app/screens/home/components/prompt_password.dart';
import 'package:candide_mobile_app/screens/home/guardians/guardian_operation_review.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:magic_sdk/magic_sdk.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:wallet_dart/wallet/UserOperation.dart';
import 'package:web3dart/web3dart.dart';

class GuardiansHelper {

  static Future<String?> getPasswordThroughBiometrics() async {
    try{
      final store = await BiometricStorage().getStorage('auth_data');
      String? password = await store.read();
      return password;
    } on AuthException catch(_) {
      BotToast.showText(text: "User cancelled authentication");
      return null;
    }
  }

  static void onConfirmTransaction(List<UserOperation> userOperations) async {
    List<UserOperation>? unsignedUserOperations = await Bundler.requestPaymasterSignature(
      userOperations,
      SettingsData.network,
    );
    if (unsignedUserOperations == null) return;
    var biometricsEnabled = Hive.box("settings").get("biometrics_enabled");
    if (biometricsEnabled){
      String? password = await getPasswordThroughBiometrics();
      if (password == null){
        BotToast.showText(
          text: "User cancelled authentication",
          contentColor: Colors.red,
          align: Alignment.topCenter,
        );
        return;
      }else{
        confirmTransactions(userOperations, unsignedUserOperations, password);
      }
    }else{
      Get.dialog(PromptPasswordDialog(
        onConfirm: (String password){
          confirmTransactions(userOperations, unsignedUserOperations, password);
        },
      ));
    }
  }

  static confirmTransactions(List<UserOperation> userOperations, List<UserOperation> unsignedUserOperations, String masterPassword) async {
    if (!Bundler.verifyUserOperationsWithPaymaster(userOperations, unsignedUserOperations)) {
      Get.back();
      Utils.showError(title: "Error", message: "Transaction corrupted, contact us for help");
      return;
    }
    var signedUserOperations = await Bundler.signUserOperations(
      AddressData.wallet,
      masterPassword,
      SettingsData.network,
      unsignedUserOperations,
    );

    if (signedUserOperations == null){
      Utils.showError(title: "Error", message: "Incorrect password");
      return;
    }

    BotToast.showText(
      text: "Transaction sent, this might take a minute...",
      textStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
      contentColor: Get.theme.colorScheme.primary,
      align: Alignment.topCenter,
    );
    var cancelLoad = Utils.showLoading();
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

  static void confirmGuardianRecoveryTransaction(List<UserOperation> userOperations) async {
    List<UserOperation>? unsignedUserOperations = await Bundler.requestPaymasterSignature(
      userOperations,
      SettingsData.network,
    );
    if (unsignedUserOperations == null) return;
    if (!Bundler.verifyUserOperationsWithPaymaster(userOperations, unsignedUserOperations)) {
      Get.back();
      Utils.showError(title: "Error", message: "Transaction corrupted, contact us for help");
      return;
    }
    var signedUserOperations = await Bundler.signUserOperationsAsMagicLink(
      SettingsData.network,
      unsignedUserOperations,
    );

    if (signedUserOperations == null){
      Utils.showError(title: "Error", message: "Incorrect password");
      return;
    }

    BotToast.showText(
      text: "Transaction sent, this might take a minute...",
      textStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
      contentColor: Get.theme.colorScheme.primary,
      align: Alignment.topCenter,
    );
    var cancelLoad = Utils.showLoading();
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


  static Future<bool> revokeGuardian(String address) async {
    CancelFunc? cancelLoad = Utils.showLoading();
    Map data = await GuardianHook.buildRevokeOps(
      instance: AddressData.wallet,
      network: SettingsData.network,
      isDeployed: AddressData.walletStatus.isDeployed,
      nonce: AddressData.walletStatus.nonce,
      defaultCurrency: SettingsData.quoteCurrency,
      guardianAddress: address,
    );
    cancelLoad();
    cancelLoad = null;
    bool? refresh = await showBarModalBottomSheet(
      context: Get.context!,
      builder: (context) {
        Get.put<ScrollController>(ModalScrollController.of(context)!, tag: "guardian_review_modal");
        return GuardianOperationReview(
          operation: GuardianOperation.revoke,
          guardian: address,
          fee: data["fee"],
          onConfirm: (){
            cancelLoad = Utils.showLoading();
            onConfirmTransaction(data["userOperations"]);
          },
        );
      },
    );
    cancelLoad?.call();
    return (refresh ?? false);
  }

  static Future<bool> grantGuardian(String address, {Map? magicLinkData}) async {
    CancelFunc? cancelLoad = Utils.showLoading();
    Map data = await GuardianHook.buildGrantOps(
      instance: AddressData.wallet,
      network: SettingsData.network,
      isDeployed: AddressData.walletStatus.isDeployed,
      nonce: AddressData.walletStatus.nonce,
      defaultCurrency: SettingsData.quoteCurrency,
      guardianAddress: address,
    );
    cancelLoad();
    cancelLoad = null;
    bool? refresh = await showBarModalBottomSheet(
      context: Get.context!,
      builder: (context) {
        Get.put<ScrollController>(ModalScrollController.of(context)!, tag: "guardian_review_modal");
        return GuardianOperationReview(
          operation: GuardianOperation.grant,
          guardian: address,
          fee: data["fee"],
          onConfirm: (){
            cancelLoad = Utils.showLoading();
            onConfirmTransaction(data["userOperations"]);
          },
        );
      },
    );
    if (refresh ?? false){
      if (magicLinkData != null){
        AddressData.guardians.add(WalletGuardian(
          type: "magic-link",
          address: address,
          email: magicLinkData["email"],
          creationDate: DateTime.now(),
        ));
      }else{
        AddressData.guardians.add(WalletGuardian(
          type: "family-and-friends",
          address: address,
          email: null,
          creationDate: DateTime.now(),
        ));
      }
      await AddressData.storeGuardians();
    }
    cancelLoad?.call();
    return (refresh ?? false);
  }

  static Future<bool> recoverUsingGuardian(String address, String newOwner) async {
    CancelFunc? cancelLoad = Utils.showLoading();
    Map data = await GuardianHook.buildRecoverOps(
      walletAddress: EthereumAddress.fromHex(address),
      network: SettingsData.network,
      defaultCurrency: SettingsData.quoteCurrency,
      newOwner: newOwner,
    );
    cancelLoad();
    cancelLoad = null;
    bool? refresh = await showBarModalBottomSheet(
      context: Get.context!,
      builder: (context) {
        Get.put<ScrollController>(ModalScrollController.of(context)!, tag: "guardian_review_modal");
        return GuardianOperationReview(
          operation: GuardianOperation.recover,
          guardian: address,
          fee: data["fee"],
          onConfirm: (){
            cancelLoad = Utils.showLoading();
            confirmGuardianRecoveryTransaction(data["userOperations"]);
          },
        );
      },
    );
    cancelLoad?.call();
    return (refresh ?? false);
  }

  static Future<bool> setupMagicLinkRecovery(String email, String walletAddress, String newOwner) async {
    CancelFunc? cancelLoad = Utils.showLoading();
    bool? refresh = false;
    try {
      var magic = Magic.instance;
      var isLoggedIn = await magic.user.isLoggedIn();
      if (isLoggedIn){
        await magic.user.logout();
      }
      await magic.auth.loginWithMagicLink(email: email, showUI: true); // todo show ui
      var metadata = await magic.user.getMetadata();
      cancelLoad.call();
      cancelLoad = null;
      if (metadata.publicAddress == null) return false;
      refresh = await recoverUsingGuardian(walletAddress, newOwner);
    } on Exception catch (e) {
      cancelLoad?.call();
      print(e);
      return false;
    }
    cancelLoad?.call();
    Get.back();
    return refresh;
  }

  static Future<bool> setupMagicLinkGuardian(String email) async {
    CancelFunc? cancelLoad = Utils.showLoading();
    bool? refresh = false;
    try {
      var magic = Magic.instance;
      var isLoggedIn = await magic.user.isLoggedIn();
      if (isLoggedIn){
        await magic.user.logout();
      }
      await magic.auth.loginWithMagicLink(email: email);
      var metadata = await magic.user.getMetadata();
      cancelLoad.call();
      cancelLoad = null;
      if (metadata.publicAddress == null) return false;
      refresh = await grantGuardian(metadata.publicAddress!, magicLinkData: {"email":email});
    } on Exception catch (e) {
      cancelLoad?.call();
      print(e);
      return false;
    }
    cancelLoad?.call();
    Get.back();
    return refresh;
  }

}