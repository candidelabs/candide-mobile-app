// ignore_for_file: no_leading_underscores_for_local_identifiers
import 'package:animations/animations.dart';
import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:candide_mobile_app/controller/send_controller.dart';
import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:candide_mobile_app/models/batch.dart';
import 'package:candide_mobile_app/models/gnosis_transaction.dart';
import 'package:candide_mobile_app/screens/home/components/transaction/transaction_review_sheet.dart';
import 'package:candide_mobile_app/screens/home/send/components/send_review_leading.dart';
import 'package:candide_mobile_app/screens/home/send/send_amount_sheet.dart';
import 'package:candide_mobile_app/screens/home/send/send_to_sheet.dart';
import 'package:candide_mobile_app/utils/constants.dart';
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
  late TokenInfo currency;
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

  onPressReview(TokenInfo _currency, BigInt value) async {
    currency = _currency;
    var cancelLoad = Utils.showLoading();
    //
    sendBatch = await Batch.create(account: PersistentData.selectedAccount);
    //
    GnosisTransaction transaction = SendController.buildTransaction(
      sendToken: _currency,
      to: toAddress,
      value: value,
    );
    //
    sendBatch!.transactions.add(transaction);
    //
    await sendBatch!.fetchPaymasterResponse();
    //
    cancelLoad();
    TransactionActivity transactionActivity = TransactionActivity(
      date: DateTime.now(),
      action: "transfer",
      title: "Sent ${currency.symbol}",
      status: "pending",
      data: {"currency": currency.address, "amount": value.toString(), "to": toAddress},
    );

    pagesList[2] = TransactionReviewSheet(
      modalId: "send_modal",
      leading: SendReviewLeadingWidget(
        token: currency,
        value: value,
      ),
      tableEntriesData: {
        "From": PersistentData.selectedAccount.address.hexEip55,
        "To": toAddress,
        "Network": Networks.selected().chainId.toString(),
      },
      currency: currency,
      value: value,
      batch: sendBatch!,
      transactionActivity: transactionActivity,
      onBack: (){
        gotoPage(1);
      },
      confirmCheckboxes: [
        currency.address == Constants.addressZeroHex
            ? ["I am not sending to an exchange", "Most exchanges do not detect \$${currency.symbol} transfers coming from smart contract accounts"]
            : null,
        ["The person I'm sending to has a wallet that supports ${Networks.selected().name} network"],
      ],
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
