// ignore_for_file: no_leading_underscores_for_local_identifiers
import 'dart:typed_data';

import 'package:animations/animations.dart';
import 'package:biometric_storage/biometric_storage.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/swap.dart';
import 'package:candide_mobile_app/controller/address_persistent_data.dart';
import 'package:candide_mobile_app/models/batch.dart';
import 'package:candide_mobile_app/models/fee_currency.dart';
import 'package:candide_mobile_app/models/gnosis_transaction.dart';
import 'package:candide_mobile_app/services/bundler.dart';
import 'package:candide_mobile_app/controller/swap_controller.dart';
import 'package:candide_mobile_app/controller/settings_persistent_data.dart';
import 'package:candide_mobile_app/models/relay_response.dart';
import 'package:candide_mobile_app/screens/home/components/prompt_password.dart';
import 'package:candide_mobile_app/screens/home/swap/swap_main_sheet.dart';
import 'package:candide_mobile_app/screens/home/swap/swap_review_sheet.dart';
import 'package:candide_mobile_app/utils/currency.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wallet_dart/wallet/user_operation.dart';
import 'package:wallet_dart/wallet/wallet_helpers.dart';
import 'package:web3dart/web3dart.dart';

class SwapSheet extends StatefulWidget {
  const SwapSheet({Key? key}) : super(key: key);

  @override
  State<SwapSheet> createState() => _SwapSheetState();
}

class _SwapSheetState extends State<SwapSheet> {
  List<Widget> pagesList = [
    Container(),
  ];
  bool reverse = false;
  int currentIndex = 0;
  //
  String baseCurrency = "";
  double baseAmount = 0;
  String quoteCurrency = "";
  OptimalQuote? quote;
  List<UserOperation> userOperations = [];
  List<UserOperation>? unsignedUserOperations = [];
  //
  Batch? swapBatch;
  //
  initPages(){
    pagesList = [
      SwapMainSheet(
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

  onPressReview(String bc, double bcAmount, String qc, OptimalQuote _quote) async {
    baseCurrency = bc;
    baseAmount = bcAmount;
    quoteCurrency = qc;
    quote = _quote;
    //
    BigInt baseValue = CurrencyUtils.parseCurrency(baseAmount.toString(), baseCurrency);
    //
    swapBatch = Batch();
    //
    List<GnosisTransaction> transactions = SwapController.buildTransactions(
        baseCurrency: baseCurrency,
        baseCurrencyValue: baseValue,
        optimalQuote: quote!
    );
    swapBatch!.transactions.addAll(transactions);
    //
    List<FeeCurrency>? feeCurrencies = await Bundler.fetchPaymasterFees();
    if (feeCurrencies == null){
      // todo handle network errors
      return;
    }else{
      //sendBatch!.feeCurrencies = feeCurrencies;
      swapBatch!.feeCurrencies = [
        FeeCurrency(currency: CurrencyMetadata.metadata["ETH"]!, fee: EtherAmount.fromUnitAndValue(EtherUnit.gwei, 500000).getInWei),
        FeeCurrency(currency: CurrencyMetadata.metadata["UNI"]!, fee: BigInt.from(6000000000000000)),
        FeeCurrency(currency: CurrencyMetadata.metadata["CTT"]!, fee: BigInt.from(5000000000000000)),
      ];
    }
    //
    pagesList[1] = SwapReviewSheet(
      baseCurrency: baseCurrency,
      baseValue: baseValue,
      quoteCurrency: quoteCurrency,
      quote: quote!,
      batch: swapBatch!,
      onPressBack: (){
        gotoPage(0);
      },
      onConfirm: onPressSwap,
    );
    //
    gotoPage(1);
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

  onPressSwap() async {
    //
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
    swapBatch!.configureNonces(AddressData.walletStatus.nonce);
    swapBatch!.signTransactions(privateKey, AddressData.wallet);
    unsignedUserOperations = await swapBatch!.toUserOperations(AddressData.wallet);
    //
    var signedUserOperations = await Bundler.signUserOperations(
      signer,
      SettingsData.network,
      unsignedUserOperations!,
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