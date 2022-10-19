import 'dart:typed_data';

import 'package:biometric_storage/biometric_storage.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:candide_mobile_app/models/batch.dart';
import 'package:candide_mobile_app/models/gnosis_transaction.dart';
import 'package:candide_mobile_app/models/guardian_operation.dart';
import 'package:candide_mobile_app/controller/address_persistent_data.dart';
import 'package:candide_mobile_app/services/bundler.dart';
import 'package:candide_mobile_app/controller/guardian_controller.dart';
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
import 'package:wallet_dart/contracts/wallet.dart';
import 'package:wallet_dart/wallet/UserOperation.dart';
import 'package:wallet_dart/wallet/wallet_helpers.dart';
import 'package:web3dart/web3dart.dart';

class GuardiansHelper {

  static Batch? grantBatch;

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

  static void onConfirmTransaction(Batch batch) async {
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
    Credentials? signer = WalletHelpers.decryptSigner(
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
    List<UserOperation> unsignedUserOperations = await batch.toUserOperations(AddressData.wallet);
    //
    var signedUserOperations = await Bundler.signUserOperations(
      signer,
      SettingsData.network,
      unsignedUserOperations,
    );

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


  /*static Future<bool> revokeGuardian(String address) async {
    CancelFunc? cancelLoad = Utils.showLoading();
    Map data = await GuardianController.buildRevokeOps(
      instance: AddressData.wallet,
      network: SettingsData.network,
      isDeployed: AddressData.walletStatus.proxyDeployed,
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
  }*/

  static Future<bool> grantGuardian(String address, {Map? magicLinkData}) async {
    CancelFunc? cancelLoad = Utils.showLoading();
    Batch grantBatch = Batch();
    bool setupSocialModule = true;
    int friendsCount = 0;
    int threshold = 1;
    if (AddressData.walletStatus.socialModuleDeployed){
      print("G!");
      EthereumAddress recoveryManager = await CWallet.recoveryInterface(AddressData.wallet.socialRecovery).manager();
      print("G! : ${recoveryManager.hex}");
      print("G! : ${AddressData.wallet.walletAddress.hex}");
      if (recoveryManager.hex == AddressData.wallet.walletAddress.hex){
        print("G!!");
        setupSocialModule = false;
        friendsCount = (await CWallet.recoveryInterface(AddressData.wallet.socialRecovery).friendsCount()).toInt();
        threshold = (((friendsCount + 1) / 2 ) + 1).floor();
      }
    }
    print("Setup: $setupSocialModule");
    print("friendsCount: $friendsCount");
    print("threshold: $threshold");
    List<GnosisTransaction> transactions = GuardianController.buildGrantTransactions(
        socialModuleDeployed: AddressData.walletStatus.socialModuleDeployed,
        setup: setupSocialModule,
        instance: AddressData.wallet,
        guardianAddress: address,
        threshold: threshold,
    );
    grantBatch.transactions.addAll(transactions);
    cancelLoad();
    cancelLoad = null;
    bool? refresh = await showBarModalBottomSheet(
      context: Get.context!,
      builder: (context) {
        Get.put<ScrollController>(ModalScrollController.of(context)!, tag: "guardian_review_modal");
        return GuardianOperationReview(
          operation: GuardianOperation.grant,
          guardian: address,
          batch: grantBatch,
          onConfirm: (){
            cancelLoad = Utils.showLoading();
            onConfirmTransaction(grantBatch);
          },
        );
      },
    );
    if (refresh ?? false){
      if (magicLinkData != null){
        AddressData.guardians.add(WalletGuardian(
          index: friendsCount,
          type: "magic-link",
          address: address,
          email: magicLinkData["email"],
          creationDate: DateTime.now(),
        ));
      }else{
        AddressData.guardians.add(WalletGuardian(
          index: friendsCount,
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


  static Future<bool> revokeGuardian(String address, int guardianIndex) async {
    CancelFunc? cancelLoad = Utils.showLoading();
    Batch revokeBatch = Batch();
    int friendsCount = (await CWallet.recoveryInterface(AddressData.wallet.socialRecovery).friendsCount()).toInt();
    int threshold = (((friendsCount - 1) / 2 ) + 1).floor();
    if ((friendsCount-1) == 0){
      threshold = 0;
    }
    List<GnosisTransaction> transactions = GuardianController.buildRevokeTransactions(
      instance: AddressData.wallet,
      guardianIndex: guardianIndex,
      threshold: threshold,
    );
    revokeBatch.transactions.addAll(transactions);
    cancelLoad();
    cancelLoad = null;
    bool? refresh = await showBarModalBottomSheet(
      context: Get.context!,
      builder: (context) {
        Get.put<ScrollController>(ModalScrollController.of(context)!, tag: "guardian_review_modal");
        return GuardianOperationReview(
          operation: GuardianOperation.revoke,
          guardian: address,
          batch: revokeBatch,
          onConfirm: (){
            cancelLoad = Utils.showLoading();
            onConfirmTransaction(revokeBatch);
          },
        );
      },
    );
    if (refresh ?? false){
      AddressData.guardians.removeWhere((element) => element.address.toLowerCase() == address.toLowerCase());
      await AddressData.storeGuardians();
    }
    cancelLoad?.call();
    return (refresh ?? false);
  }

  /*static Future<bool> recoverUsingGuardian(String address, String newOwner) async {
    CancelFunc? cancelLoad = Utils.showLoading();
    Map data = await GuardianController.buildRecoverOps(
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
  }*/

  /*static Future<bool> setupMagicLinkRecovery(String email, String walletAddress, String newOwner) async {
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
  }*/

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