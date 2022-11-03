import 'dart:convert';
import 'dart:typed_data';

import 'package:biometric_storage/biometric_storage.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:candide_mobile_app/models/batch.dart';
import 'package:candide_mobile_app/models/fee_currency.dart';
import 'package:candide_mobile_app/models/gnosis_transaction.dart';
import 'package:candide_mobile_app/models/guardian_operation.dart';
import 'package:candide_mobile_app/controller/address_persistent_data.dart';
import 'package:candide_mobile_app/models/recovery_request.dart';
import 'package:candide_mobile_app/screens/onboard/recovery/recovery_request_page.dart';
import 'package:candide_mobile_app/services/bundler.dart';
import 'package:candide_mobile_app/controller/guardian_controller.dart';
import 'package:candide_mobile_app/controller/settings_persistent_data.dart';
import 'package:candide_mobile_app/models/relay_response.dart';
import 'package:candide_mobile_app/screens/home/components/prompt_password.dart';
import 'package:candide_mobile_app/screens/home/guardians/guardian_operation_review.dart';
import 'package:candide_mobile_app/services/security.dart';
import 'package:candide_mobile_app/utils/constants.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:magic_sdk/magic_sdk.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:wallet_dart/contracts/factories/EIP4337Manager.g.dart';
import 'package:wallet_dart/contracts/wallet.dart';
import 'package:wallet_dart/wallet/user_operation.dart';
import 'package:wallet_dart/wallet/wallet_helpers.dart';
import 'package:wallet_dart/wallet/wallet_instance.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class GuardianOperationsHelper {

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

  static Future<bool> grantGuardian(String address, {Map? magicLinkData}) async {
    CancelFunc? cancelLoad = Utils.showLoading();
    Batch grantBatch = Batch();
    bool setupSocialModule = true;
    int friendsCount = 0;
    int threshold = 1;
    if (AddressData.walletStatus.socialModuleDeployed){
      EthereumAddress recoveryManager = await CWallet.recoveryInterface(AddressData.wallet.socialRecovery).manager();
      if (recoveryManager.hex == AddressData.wallet.walletAddress.hex){
        setupSocialModule = false;
        friendsCount = (await CWallet.recoveryInterface(AddressData.wallet.socialRecovery).getFriends()).length;
        threshold = (((friendsCount + 1) / 2 ) + 1).floor();
      }
    }
    List<GnosisTransaction> transactions = GuardianController.buildGrantTransactions(
        socialModuleDeployed: AddressData.walletStatus.socialModuleDeployed,
        setup: setupSocialModule,
        instance: AddressData.wallet,
        guardianAddress: address,
        threshold: threshold,
    );
    grantBatch.transactions.addAll(transactions);
    //
    List<FeeCurrency>? feeCurrencies = await Bundler.fetchPaymasterFees();
    if (feeCurrencies == null){
      // todo handle network errors
      return false;
    }else{
      await grantBatch.changeFeeCurrencies(feeCurrencies);
    }
    //
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
    int friendsCount = (await CWallet.recoveryInterface(AddressData.wallet.socialRecovery).getFriends()).length;
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
    //
    List<FeeCurrency>? feeCurrencies = await Bundler.fetchPaymasterFees();
    if (feeCurrencies == null){
      // todo handle network errors
      return false;
    }else{
      await revokeBatch.changeFeeCurrencies(feeCurrencies);
    }
    //
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

class GuardianRecoveryHelper{

  static Future<EthereumAddress?> getSocialRecoveryModule(String walletAddress, [GetModulesPaginated? modulesPaginated]) async{
    if (modulesPaginated == null){
      try{
        modulesPaginated = await CWallet.customInterface(EthereumAddress.fromHex(walletAddress)).getModulesPaginated(Constants.addressOne, BigInt.from(25));
      }catch (e){
        return null;
      }
    }
    for (EthereumAddress module in modulesPaginated.array){
      try{
        int guardiansCount = (await CWallet.recoveryInterface(module).getFriends()).length;
        if (guardiansCount == 0) return null;
        return module;
      }catch (e){
        continue;
      }
    }
    return null;
  }

  static Future<EthereumAddress?> getModuleManagerAddress(String walletAddress, [GetModulesPaginated? modulesPaginated]) async{
    if (modulesPaginated == null){
      try{
        modulesPaginated = await CWallet.customInterface(EthereumAddress.fromHex(walletAddress)).getModulesPaginated(Constants.addressOne, BigInt.from(25));
      }catch (e){
        return null;
      }
    }
    String abi = '''[{"inputs":[],"name":"eip4337manager","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"}]''';
    for (EthereumAddress module in modulesPaginated.array){
      try{
        final contract = DeployedContract(ContractAbi.fromJson(abi, 'EIP4337Fallback'), module);
        var moduleManagerAddress = await Constants.client.call(contract: contract, function: contract.function("eip4337manager"), params: []);
        return moduleManagerAddress[0];
      }catch (e){
        continue;
      }
    }
    return null;
  }

  static setupRecoveryWallet(String address, String password, bool biometricsEnabled, String method) async {
    var cancelLoad = Utils.showLoading();
    //
    GetModulesPaginated modulesPaginated;
    try{
      modulesPaginated = await CWallet.customInterface(EthereumAddress.fromHex(address)).getModulesPaginated(Constants.addressOne, BigInt.from(25));
    }catch (e){
      cancelLoad();
      Utils.showError(title: "Error", message: "This wallet is not a candide smart contract wallet!");
      return;
    }
    //
    EthereumAddress? socialModuleAddress = await getSocialRecoveryModule(address, modulesPaginated);
    EthereumAddress? moduleManagerAddress = await getModuleManagerAddress(address, modulesPaginated);
    if (socialModuleAddress == null || moduleManagerAddress == null){
      cancelLoad();
      Utils.showError(title: "Error", message: "This wallet does not have any guardians, unfortunately this means this wallet cannot be recovered, contact us to learn more");
      return;
    }
    //
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
    var salt = base64Encode(Utils.randomBytes(16, secure: true));
    WalletInstance wallet = await WalletHelpers.createRecovery(address, moduleManagerAddress.hexEip55, socialModuleAddress.hexEip55, password, salt);
    await Hive.box("wallet").put("recovered", jsonEncode(wallet.toJson()));
    cancelLoad();
    Get.back();
    //
    if (method == "social-recovery"){
      EthereumAddress oldOwner = (await CWallet.customInterface(EthereumAddress.fromHex(address)).getOwners())[0];
      var dataHash = CWallet.customInterface(EthereumAddress.fromHex(address)).self.function("swapOwner").encodeCall([Constants.addressOne, oldOwner, EthereumAddress.fromHex(wallet.initOwner)]);
      dataHash = keccak256(dataHash);
      startRecoveryRequest(wallet, bytesToHex(dataHash, include0x: true), oldOwner.hexEip55);
    }
    //
  }

  static void startRecoveryRequest(WalletInstance wallet, String dataHash, String oldOwner) async {
    var cancelLoad = Utils.showLoading();
    RecoveryRequest? request = await SecurityGateway.create(wallet.walletAddress.hexEip55, wallet.socialRecovery.hexEip55, dataHash, oldOwner, wallet.initOwner, SettingsData.network);
    if (request == null){
      cancelLoad();
      if (SecurityGateway.latestErrorCode == 429){
        Utils.showError(title: "Error", message: "A recovery request was created for this wallet in the past hour, please wait some time and try again");
      }else{
        Utils.showError(title: "Error", message: "Error occurred while trying to create a recovery request, please try again later or contact us");
      }
      return;
    }
    cancelLoad();
    AddressData.storeRecoveryRequest(request.id);
    Get.off(RecoveryRequestPage(request: request));
  }
}