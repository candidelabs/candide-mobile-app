// ignore_for_file: no_leading_underscores_for_local_identifiers
import 'dart:typed_data';

import 'package:animations/animations.dart';
import 'package:biometric_storage/biometric_storage.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/controller/address_persistent_data.dart';
import 'package:candide_mobile_app/models/batch.dart';
import 'package:candide_mobile_app/models/fee_currency.dart';
import 'package:candide_mobile_app/models/gnosis_transaction.dart';
import 'package:candide_mobile_app/services/bundler.dart';
import 'package:candide_mobile_app/controller/send_controller.dart';
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
import 'package:wallet_dart/wallet/wallet_helpers.dart';
import 'package:web3dart/web3dart.dart';

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
  Batch? sendBatch;
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
    sendBatch = Batch();
    //
    BigInt value = CurrencyUtils.parseCurrency(amount.toString(), currency);
    GnosisTransaction transaction = SendController.buildTransaction(
      sendCurrency: _currency,
      to: toAddress,
      value: value,
    );
    //
    sendBatch!.transactions.add(transaction);
    //
    List<FeeCurrency>? feeCurrencies = await Bundler.fetchPaymasterFees();
    if (feeCurrencies == null){
      // todo handle network errors
      return;
    }else{
      //sendBatch!.feeCurrencies = feeCurrencies;
      sendBatch!.feeCurrencies = [
        FeeCurrency(currency: CurrencyMetadata.metadata["ETH"]!, fee: EtherAmount.fromUnitAndValue(EtherUnit.gwei, 500000).getInWei),
        FeeCurrency(currency: CurrencyMetadata.metadata["UNI"]!, fee: BigInt.from(6000000000000000)),
        FeeCurrency(currency: CurrencyMetadata.metadata["CTT"]!, fee: BigInt.from(5000000000000000)),
      ];
    }
    //
    cancelLoad();
    pagesList[2] = SendReviewSheet(
      from: AddressData.wallet.walletAddress.hex,
      to: toAddress,
      currency: currency,
      value: value,
      batch: sendBatch!,
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
    sendBatch!.configureNonces(AddressData.walletStatus.nonce);
    sendBatch!.signTransactions(privateKey, AddressData.wallet);
    unsignedUserOperations = await sendBatch!.toUserOperations(
      AddressData.wallet,
      proxyDeployed: AddressData.walletStatus.proxyDeployed,
      managerDeployed: AddressData.walletStatus.managerDeployed,
    );
    //
    var signedUserOperations = await Bundler.signUserOperations(
      signer,
      SettingsData.network,
      unsignedUserOperations!,
    );
    //
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
