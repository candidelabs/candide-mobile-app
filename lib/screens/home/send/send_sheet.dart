// ignore_for_file: no_leading_underscores_for_local_identifiers
import 'package:animations/animations.dart';
import 'package:candide_mobile_app/controller/address_persistent_data.dart';
import 'package:candide_mobile_app/controller/settings_persistent_data.dart';
import 'package:candide_mobile_app/models/batch.dart';
import 'package:candide_mobile_app/models/fee_currency.dart';
import 'package:candide_mobile_app/models/gnosis_transaction.dart';
import 'package:candide_mobile_app/screens/home/components/transaction_review_sheet.dart';
import 'package:candide_mobile_app/screens/home/send/components/send_review_leading.dart';
import 'package:candide_mobile_app/services/bundler.dart';
import 'package:candide_mobile_app/controller/send_controller.dart';
import 'package:candide_mobile_app/screens/home/send/send_amount_sheet.dart';
import 'package:candide_mobile_app/screens/home/send/send_to_sheet.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:wallet_dart/wallet/user_operation.dart';

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

  onPressReview(String _currency, BigInt value) async {
    currency = _currency;
    var cancelLoad = Utils.showLoading();
    //
    sendBatch = Batch();
    //
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
      await sendBatch!.changeFeeCurrencies(feeCurrencies);
    }
    //
    cancelLoad();
    pagesList[2] = TransactionReviewSheet(
      modalId: "send_modal",
      leading: SendReviewLeadingWidget(
        currency: currency,
        value: value,
      ),
      tableEntriesData: {
        "From": AddressData.wallet.walletAddress.hexEip55,
        "To": toAddress,
        "Network": SettingsData.network
      },
      currency: currency,
      value: value,
      batch: sendBatch!,
      onBack: (){
        gotoPage(1);
      },
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
