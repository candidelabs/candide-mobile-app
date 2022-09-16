// ignore_for_file: no_leading_underscores_for_local_identifiers
import 'package:animations/animations.dart';
import 'package:biometric_storage/biometric_storage.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:candide_mobile_app/controller/address_persistent_data.dart';
import 'package:candide_mobile_app/controller/bundler.dart';
import 'package:candide_mobile_app/controller/hooks/send_hook.dart';
import 'package:candide_mobile_app/controller/settings_persistent_data.dart';
import 'package:candide_mobile_app/models/relay_response.dart';
import 'package:candide_mobile_app/screens/home/components/prompt_password.dart';
import 'package:candide_mobile_app/screens/home/send/send_amount_sheet.dart';
import 'package:candide_mobile_app/screens/home/send/send_review_sheet.dart';
import 'package:candide_mobile_app/screens/home/send/send_to_sheet.dart';
import 'package:candide_mobile_app/utils/currency.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wallet_dart/wallet/UserOperation.dart';

class SendSheet extends StatefulWidget {
  const SendSheet({Key? key}) : super(key: key);

  @override
  State<SendSheet> createState() => _SendSheetState();
}

class _SendSheetState extends State<SendSheet> {
  List<Widget> pagesList = [
    Container(),
  ];
  bool reverse = false;
  int currentIndex = 0;
  //
  String toAddress = "";
  String currency = "";
  List<UserOperation> userOperations = [];
  List<UserOperation>? unsignedUserOperations = [];
  Map fee = {};
  double amount = 0;
  //
  initPages(){
    pagesList = [
      SendToSheet(
        onNext: (String address){
          toAddress = address;
          gotoPage(1);
        },
      ),
      SendAmountSheet(
        onPressBack: (){
          gotoPage(0);
        },
        onPressReview: onPressReview,
      ),
      Container(),
    ];
    setState(() {});
  }

  @override
  void initState() {
    initPages();
    super.initState();
  }
  //

  onPressReview(String _currency, double _amount) async {
    currency = _currency;
    amount = _amount;
    var cancelLoad = Utils.showLoading();
    //
    BigInt value = CurrencyUtils.parseCurrency(amount.toString(), currency);
    Map data = await SendHook.buildOps(
      instance: AddressData.wallet,
      network: SettingsData.network,
      isDeployed: AddressData.walletStatus.isDeployed,
      nonce: AddressData.walletStatus.nonce,
      defaultCurrency: SettingsData.quoteCurrency,
      sendCurrency: _currency,
      toAddress: toAddress,
      value: value,
    );
    userOperations = data["userOperations"];
    fee = data["fee"];
    cancelLoad();
    //
    pagesList[2] = SendReviewSheet(
      from: AddressData.wallet.walletAddress.hex,
      to: toAddress,
      currency: currency,
      value: value,
      fee: fee,
      onPressBack: (){
        gotoPage(1);
      },
      onConfirm: onPressConfirm,
    );
    //
    gotoPage(2);
  }

  gotoPage(int page){
    setState(() {
      if (page > currentIndex){
        reverse = false;
      }else{
        reverse = true;
      }
      currentIndex = page;
    });
  }

  Future<String?> getPasswordThroughBiometrics() async {
    try{
      final store = await BiometricStorage().getStorage('auth_data');
      String? password = await store.read();
      return password;
    } on AuthException catch(_) {
      BotToast.showText(text: "User cancelled authentication");
      return null;
    }
  }

  onPressConfirm() async {
    unsignedUserOperations = await Bundler.requestPaymasterSignature(
      userOperations,
      SettingsData.network,
    );
    //
    //unsignedUserOperations = List.from(userOperations); // todo delete
    //
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
        confirmTransactions(password);
      }
    }else{
      Get.dialog(PromptPasswordDialog(
        onConfirm: (String password){
          confirmTransactions(password);
        },
      ));
    }
  }

  confirmTransactions(String masterPassword) async {
    if (!Bundler.verifyUserOperationsWithPaymaster(userOperations, unsignedUserOperations!)) {
      Get.back();
      Utils.showError(title: "Error", message: "Transaction corrupted, contact us for help");
      return;
    }
    var signedUserOperations = await Bundler.signUserOperations(
      AddressData.wallet,
      masterPassword,
      SettingsData.network,
      unsignedUserOperations!,
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

  @override
  Widget build(BuildContext context) {
    return PageTransitionSwitcher(
      transitionBuilder: (
          Widget child,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          ) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.horizontal,
          child: child,
        );
      },
      duration: const Duration(milliseconds: 400),
      reverse: reverse,
      child: pagesList[currentIndex],
    );
  }
}
