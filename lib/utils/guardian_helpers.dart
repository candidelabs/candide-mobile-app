import 'package:biometric_storage/biometric_storage.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/controller/signers_controller.dart';
import 'package:candide_mobile_app/models/batch.dart';
import 'package:candide_mobile_app/models/fee_currency.dart';
import 'package:candide_mobile_app/models/gnosis_transaction.dart';
import 'package:candide_mobile_app/models/guardian_operation.dart';
import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:candide_mobile_app/models/recovery_request.dart';
import 'package:candide_mobile_app/screens/home/components/transaction_review_sheet.dart';
import 'package:candide_mobile_app/screens/home/guardians/components/guardian_review_leading.dart';
import 'package:candide_mobile_app/screens/home/home_screen.dart';
import 'package:candide_mobile_app/services/bundler.dart';
import 'package:candide_mobile_app/controller/guardian_controller.dart';
import 'package:candide_mobile_app/controller/settings_persistent_data.dart';
import 'package:candide_mobile_app/services/security.dart';
import 'package:candide_mobile_app/utils/constants.dart';
import 'package:candide_mobile_app/utils/events.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:magic_sdk/magic_sdk.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:wallet_dart/contracts/account.dart';
import 'package:wallet_dart/contracts/factories/CandideWallet.g.dart';
import 'package:wallet_dart/contracts/social_module.dart';
import 'package:wallet_dart/wallet/account.dart';
import 'package:wallet_dart/wallet/account_helpers.dart';
import 'package:wallet_dart/wallet/encrypted_signer.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class GuardianOperationsHelper {

  static Batch? grantBatch;

  static Future<bool> isSocialRecoveryModuleEnabled(EthereumAddress accountAddress) async {
    try {
      return await IAccount.interface(address: accountAddress, client: Networks.selected().client).isModuleEnabled(Networks.selected().socialRecoveryModule);
    } catch (e) {
      return false;
    }
  }

  static Future<bool> grantGuardian(Account account, EthereumAddress guardian, String? nickname, String type, {Map? magicLinkData}) async {
    CancelFunc? cancelLoad = Utils.showLoading();
    Batch grantBatch = Batch();
    int friendsCount = 0;
    int threshold = 1;
    bool moduleEnabled = await isSocialRecoveryModuleEnabled(account.address);
    if (moduleEnabled){
      friendsCount = (await ISocialModule.interface(address: Networks.selected().socialRecoveryModule, client: Networks.selected().client).guardiansCount(account.address)).toInt();
      threshold = (((friendsCount + 1) / 2 ) + 1).floor();
    }
    List<GnosisTransaction> transactions = GuardianController.buildGrantTransactions(
        socialModuleEnabled: moduleEnabled,
        account: PersistentData.selectedAccount,
        guardians: [guardian],
        threshold: threshold,
    );
    grantBatch.transactions.addAll(transactions);
    //
    List<FeeToken>? feeCurrencies = await Bundler.fetchPaymasterFees(PersistentData.selectedAccount.chainId);
    if (feeCurrencies == null){
      // todo handle network errors
      return false;
    }else{
      await grantBatch.changeFeeCurrencies(feeCurrencies);
    }
    //
    cancelLoad();
    cancelLoad = null;
    TransactionActivity transactionActivity = TransactionActivity(
      date: DateTime.now(),
      action: "guardian-grant",
      title: "Added recovery contact",
      status: "pending",
      data: {"guardian": guardian.hexEip55},
    );

    bool? refresh = await showBarModalBottomSheet(
      context: Get.context!,
      backgroundColor: Get.theme.canvasColor,
      builder: (context) {
        Get.put<ScrollController>(ModalScrollController.of(context)!, tag: "guardian_review_modal");
        return TransactionReviewSheet(
          modalId: "guardian_review_modal",
          leading: const GuardianReviewLeadingWidget(
            operation: GuardianOperation.grant,
          ),
          tableEntriesData: {
            "Operation": "Add Recovery Contact",
            "Address": guardian.hexEip55,
            "Network": Networks.selected().chainId.toString(),
          },
          batch: grantBatch,
          transactionActivity: transactionActivity,
          confirmCheckboxes: magicLinkData == null ? [
            ["The recovery contact has a wallet that supports ${Networks.selected().name} network"],
          ] : [],
        );
      },
    );
    if (refresh ?? false){
      if (magicLinkData != null){
        PersistentData.guardians.add(AccountGuardian(
          index: friendsCount,
          type: "magic-link",
          address: guardian.hexEip55,
          nickname: nickname,
          email: magicLinkData["email"],
          creationDate: DateTime.now(),
        ));
      }else{
        PersistentData.guardians.add(AccountGuardian(
          index: friendsCount,
          type: type,
          address: guardian.hexEip55,
          nickname: nickname,
          email: null,
          creationDate: DateTime.now(),
        ));
      }
      await PersistentData.storeGuardians(PersistentData.selectedAccount);
    }
    cancelLoad?.call();
    return (refresh ?? false);
  }


  static Future<bool> revokeGuardian(EthereumAddress accountAddress, EthereumAddress guardian) async {
    CancelFunc? cancelLoad = Utils.showLoading();
    Batch revokeBatch = Batch();
    List<EthereumAddress> _prevGuardians = await ISocialModule.interface(address: Networks.selected().socialRecoveryModule, client: Networks.selected().client).getGuardians(accountAddress);
    int friendsCount = _prevGuardians.length;
    EthereumAddress previousGuardian = Constants.addressOne;
    int guardianIndex = _prevGuardians.indexOf(guardian);
    if (guardianIndex > 0){
      previousGuardian = _prevGuardians[guardianIndex-1];
    }
    int threshold = (((friendsCount - 1) / 2 ) + 1).floor();
    if ((friendsCount-1) == 0){
      threshold = 0;
    }
    List<GnosisTransaction> transactions = GuardianController.buildRevokeTransactions(
      account: PersistentData.selectedAccount,
      previousGuardian: previousGuardian,
      guardian: guardian,
      threshold: threshold,
    );
    revokeBatch.transactions.addAll(transactions);
    //
    List<FeeToken>? feeCurrencies = await Bundler.fetchPaymasterFees(PersistentData.selectedAccount.chainId);
    if (feeCurrencies == null){
      // todo handle network errors
      return false;
    }else{
      await revokeBatch.changeFeeCurrencies(feeCurrencies);
    }
    //
    cancelLoad();
    cancelLoad = null;
    TransactionActivity transactionActivity = TransactionActivity(
      date: DateTime.now(),
      action: "guardian-revoke",
      title: "Removed recovery contact",
      status: "pending",
      data: {"guardian": guardian.hexEip55},
    );

    bool? refresh = await showBarModalBottomSheet(
      context: Get.context!,
      backgroundColor: Get.theme.canvasColor,
      builder: (context) {
        Get.put<ScrollController>(ModalScrollController.of(context)!, tag: "guardian_review_modal");
        return TransactionReviewSheet(
          modalId: "guardian_review_modal",
          leading: const GuardianReviewLeadingWidget(
            operation: GuardianOperation.revoke,
          ),
          tableEntriesData: {
            "Operation": "Removing Recovery Contact",
            "Address": guardian.hexEip55,
            "Network": Networks.selected().chainId.toString(),
          },
          batch: revokeBatch,
          transactionActivity: transactionActivity,
        );
      },
    );
    cancelLoad?.call();
    return (refresh ?? false);
  }

  static Future<bool> setupMagicLinkGuardian(String email, String? nickname) async {
    CancelFunc? cancelLoad = Utils.showLoading();
    bool? refresh = false;
    try {
      Magic magic = Magic.instance;
      var isLoggedIn = await magic.user.isLoggedIn();
      if (isLoggedIn){
        await magic.user.logout();
      }
      cancelLoad.call();
      await magic.auth.loginWithMagicLink(email: email);
      cancelLoad = Utils.showLoading();
      var metadata = await magic.user.getMetadata();
      cancelLoad.call();
      cancelLoad = null;
      if (metadata.publicAddress == null) return false;
      refresh = await grantGuardian(PersistentData.selectedAccount, EthereumAddress.fromHex(metadata.publicAddress!), nickname, "magic-link", magicLinkData: {"email":email});
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

  static Future<EthereumAddress?> getSocialRecoveryModule(String accountAddress, int chainId, [GetModulesPaginated? modulesPaginated]) async{
    if (modulesPaginated == null){
      try{
        modulesPaginated = await IAccount.interface(address: EthereumAddress.fromHex(accountAddress), client: Networks.selected().client).getModulesPaginated(Constants.addressOne, BigInt.from(25));
      }catch (e){
        return null;
      }
    }
    String abi = '''[{"inputs":[{"internalType":"address","name":"_wallet","type":"address"}],"name":"getGuardians","outputs":[{"internalType":"address[]","name":"_guardians","type":"address[]"}],"stateMutability":"view","type":"function"}]''';
    for (EthereumAddress module in modulesPaginated.array){
      try{
        final contract = DeployedContract(ContractAbi.fromJson(abi, 'SocialRecoveryModule'), module);
        await Networks.getByChainId(chainId)!.client.call(contract: contract, function: contract.function("getGuardians"), params: [EthereumAddress.fromHex(accountAddress)]);
        return module;
      }catch (e){
        continue;
      }
    }
    return null;
  }

  static setupRecoveryAccount(String address, int chainId, String? password, bool? biometricsEnabled, String method) async {
    var cancelLoad = Utils.showLoading();
    //
    Network network = Networks.getByChainId(chainId)!;
    GetModulesPaginated modulesPaginated;
    try{
      modulesPaginated = await IAccount.interface(address: EthereumAddress.fromHex(address), client: network.client).getModulesPaginated(Constants.addressOne, BigInt.from(25));
    }catch (e){
      cancelLoad();
      Utils.showError(title: "Error", message: "This address is not a candide smart contract account!");
      return;
    }
    //
    EthereumAddress? socialModuleAddress = await getSocialRecoveryModule(address, chainId, modulesPaginated);
    if (socialModuleAddress == null){
      cancelLoad();
      Utils.showError(title: "Error", message: "This account does not have any guardians, unfortunately this means this account cannot be recovered, contact us to learn more");
      return;
    }
    BigInt threshold = await ISocialModule.interface(address: socialModuleAddress, client: network.client).threshold(EthereumAddress.fromHex(address));
    if (threshold == BigInt.zero){
      cancelLoad();
      Utils.showError(title: "Error", message: "This account does not have any guardians, unfortunately this means this account cannot be recovered, contact us to learn more");
      return;
    }
    //
    if (biometricsEnabled != null && biometricsEnabled){
      try {
        final store = await BiometricStorage().getStorage('auth_data');
        await store.write(password!);
        await Hive.box("settings").put("biometrics_enabled", true);
      } on AuthException catch(_) {
        eventBus.fire(OnPinErrorChange(error: "User cancelled biometrics auth, please try again"));
        cancelLoad();
        return;
      }
    }else if (biometricsEnabled != null && !biometricsEnabled){
      await Hive.box("settings").put("biometrics_enabled", false);
    }
    //
    EncryptedSigner? mainSigner;
    if (PersistentData.walletSigners.isEmpty){
      var signerSalt = bytesToHex(Utils.randomBytes(16, secure: true));
      mainSigner = await AccountHelpers.createEncryptedSigner(salt: signerSalt, password: password!);
    }else{
      mainSigner = SignersController.instance.getSignerFromId("main")!;
    }
    Account account = await AccountHelpers.createRecovery(
      chainId: network.chainId.toInt(),
      name: "",
      address: EthereumAddress.fromHex(address),
      signersIds: ["main"],
      salt: bytesToHex(Utils.randomBytes(16, secure: true), include0x: false),
    );
    //
    RecoveryRequest? request = await startRecoveryRequest(account, mainSigner);
    if (request == null) {
      cancelLoad();
      Get.back();
      return;
    }
    //
    account.recoveryId = request.id;
    if (mainSigner != null){
      await PersistentData.addSigner("main", mainSigner);
    }
    await PersistentData.insertAccount(account);
    PersistentData.selectAccount(address: account.address, chainId: account.chainId);
    cancelLoad();
    Get.back(result: true);
    if (password != null){
      _navigateToHome();
    }
    //
  }

  static void _navigateToHome(){
    PersistentData.loadExplorerJson(PersistentData.selectedAccount, null);
    SettingsData.loadFromJson(null);
    Navigator.of(Get.context!).popUntil((route) => route.isFirst);
    Navigator.pushReplacement(Get.context!, MaterialPageRoute(builder: (_)=> const HomeScreen()));
  }

  // we're passing accountSigner here because PersistentData.signers may be empty
  // accountSigner will later be inserted to the signers if recovery request wass successfully created
  static Future<RecoveryRequest?> startRecoveryRequest(Account account, EncryptedSigner accountSigner) async {
    var cancelLoad = Utils.showLoading();
    RecoveryRequest? request = await SecurityGateway.create(account.address.hexEip55, accountSigner.publicAddress.hex, Networks.getByChainId(account.chainId)!.normalizedName);
    if (request == null){
      cancelLoad();
      if (SecurityGateway.latestErrorCode == 429){
        Utils.showError(title: "Error", message: "A recovery request was created for this account in the past hour, please wait some time and try again");
      }else{
        Utils.showError(title: "Error", message: "Error occurred while trying to create a recovery request, please try again later or contact us");
      }
      return null;
    }
    cancelLoad();
    return request;
  }
}