import 'package:bot_toast/bot_toast.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:candide_mobile_app/controller/signers_controller.dart';
import 'package:candide_mobile_app/models/batch.dart';
import 'package:candide_mobile_app/models/relay_response.dart';
import 'package:candide_mobile_app/screens/home/activity/components/transaction_activity_details_card.dart';
import 'package:candide_mobile_app/screens/onboard/create_account/pin_entry_screen.dart';
import 'package:candide_mobile_app/services/bundler.dart';
import 'package:candide_mobile_app/services/explorer.dart';
import 'package:candide_mobile_app/utils/constants.dart';
import 'package:candide_mobile_app/utils/events.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:wallet_dart/wallet/account_helpers.dart';
import 'package:wallet_dart/wallet/user_operation.dart';
import 'package:web3dart/web3dart.dart';

class TransactionConfirmController {

  static onPressConfirm(Batch batch, TransactionActivity transactionActivity) async {
    EthPrivateKey? privateKey = SignersController.instance.getPrivateKeysFromAccount(PersistentData.selectedAccount).first;
    if (privateKey != null){
      bool? result = await confirmTransactions(privateKey, null, batch, transactionActivity);
      if (result != null){
        return;
      }
    }
    Get.to(PinEntryScreen(
      showLogo: true,
      promptText: "Enter PIN code",
      confirmMode: false,
      onPinEnter: (String password, _) async {
        bool? result = await confirmTransactions(null, password, batch, transactionActivity);
        if (result == null){
          eventBus.fire(OnPinErrorChange(error: "Incorrect PIN"));
          return;
        }
        Get.back(result: true);
      },
      onBack: (){
        Get.back();
      },
    ));
  }

  static Future<bool?> confirmTransactions(EthPrivateKey? credentials, String? pin, Batch batch, TransactionActivity transactionActivity) async {
    var cancelLoad = Utils.showLoading();
    if (credentials == null){
      credentials = (await AccountHelpers.decryptSigner(
        SignersController.instance.getSignersFromAccount(PersistentData.selectedAccount).first!,
        pin!,
      )) as EthPrivateKey?;
      if (credentials == null){
        cancelLoad();
        return null;
      }
    }
    //
    await Explorer.fetchAddressOverview(account: PersistentData.selectedAccount, skipBalances: true);
    UserOperation unsignedUserOperation = await batch.toUserOperation(
      PersistentData.selectedAccount,
      BigInt.from(PersistentData.accountStatus.nonce),
      proxyDeployed: PersistentData.accountStatus.proxyDeployed,
    );
    //
    var signedUserOperation = await Bundler.signUserOperations(
      credentials,
      PersistentData.selectedAccount.entrypoint!,
      PersistentData.selectedAccount.chainId,
      unsignedUserOperation,
    );
    //
    BotToast.showText(
      text: "Transaction sent, this might take a minute...",
      textStyle: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Colors.black),
      contentColor: Get.theme.colorScheme.primary,
      align: Alignment.topCenter,
    );
    //
    RelayResponse? response = await Bundler.relayUserOperation(signedUserOperation, PersistentData.selectedAccount.chainId);
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
              backgroundColor: Get.theme.canvasColor,
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
    transactionActivity.status = response?.status ?? "failed-to-submit";
    transactionActivity.fee = TransactionFeeActivityData(
      paymasterAddress: batch.includesPaymaster ? Constants.addressZeroHex : batch.feeCurrency!.paymaster.hexEip55,
      currencyAddress: batch.getFeeToken(),
      fee: batch.getFee(),
    );
    transactionActivity.date = DateTime.now();
    PersistentData.storeNewTransactionActivity(PersistentData.selectedAccount, transactionActivity);
    cancelLoad();
    Get.back(result: true);
    if (transactionActivity.status == "fail" || transactionActivity.status == "failed-to-submit"){
      return false;
    }
    return true;
  }
}