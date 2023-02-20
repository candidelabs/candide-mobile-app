// ignore_for_file: no_leading_underscores_for_local_identifiers
import 'package:animations/animations.dart';
import 'package:candide_mobile_app/config/swap.dart';
import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:candide_mobile_app/models/batch.dart';
import 'package:candide_mobile_app/models/fee_currency.dart';
import 'package:candide_mobile_app/models/gnosis_transaction.dart';
import 'package:candide_mobile_app/screens/home/components/transaction_review_sheet.dart';
import 'package:candide_mobile_app/screens/home/swap/components/swap_review_leading.dart';
import 'package:candide_mobile_app/services/bundler.dart';
import 'package:candide_mobile_app/controller/swap_controller.dart';
import 'package:candide_mobile_app/screens/home/swap/swap_main_sheet.dart';
import 'package:candide_mobile_app/utils/currency.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:wallet_dart/wallet/user_operation.dart';

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
  TokenInfo baseCurrency = TokenInfoStorage.getTokenBySymbol("ETH")!;
  TokenInfo quoteCurrency = TokenInfoStorage.getTokenBySymbol("UNI")!;
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

  onPressReview(TokenInfo bc, BigInt baseValue, TokenInfo qc, OptimalQuote _quote) async {
    baseCurrency = bc;
    quoteCurrency = qc;
    quote = _quote;
    var cancelLoad = Utils.showLoading();
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
    List<FeeToken>? feeCurrencies = await Bundler.fetchPaymasterFees(PersistentData.selectedAccount.chainId);
    if (feeCurrencies == null){
      // todo handle network errors
      return;
    }else{
      await swapBatch!.changeFeeCurrencies(feeCurrencies);
    }
    //
    cancelLoad();
    TransactionActivity transactionActivity = TransactionActivity(
      date: DateTime.now(),
      action: "swap",
      title: "Swap",
      status: "pending",
      data: {"currency": baseCurrency.address, "amount": baseValue.toString(), "swapCurrency": quoteCurrency.address, "swapReceive": quote!.amount.toString()},
    );

    pagesList[1] = TransactionReviewSheet(
      modalId: "swap_modal",
      leading: SwapReviewLeadingWidget(
        baseCurrency: baseCurrency,
        baseValue: baseValue,
        quoteCurrency: quoteCurrency,
        quoteValue: quote!.amount,
      ),
      tableEntriesData: {
        "Rate": CurrencyUtils.formatRate(baseCurrency, quoteCurrency, quote!.rate),
      },
      currency: baseCurrency,
      value: baseValue,
      batch: swapBatch!,
      transactionActivity: transactionActivity,
      onBack: (){
        gotoPage(0);
      },
    );
    //
    gotoPage(1);
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