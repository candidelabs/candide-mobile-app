import 'dart:async';

import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/address_persistent_data.dart';
import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:candide_mobile_app/screens/home/activity/components/transaction_activity_details_card.dart';
import 'package:candide_mobile_app/services/transaction_watchdog.dart';
import 'package:candide_mobile_app/utils/currency.dart';
import 'package:candide_mobile_app/utils/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({Key? key}) : super(key: key);

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final ScrollController scrollController = ScrollController();
  late final StreamSubscription transactionStatusSubscription;
  List<TransactionActivity> transactions = [];

  void sortTransactions() {
    transactions.sort(
      (TransactionActivity a, TransactionActivity b) {
        return b.date.compareTo(a.date);
      }
    );
  }

  Widget transactionsListWidget(){
    Map<String, List<TransactionActivity>> activityDateMap = {};
    sortTransactions();
    intl.DateFormat dateKeyFormat = intl.DateFormat("yyyy:MM:dd");
    intl.DateFormat dateTitleFormat = intl.DateFormat.yMMMMd();
    for (TransactionActivity transaction in transactions){
      String key = dateKeyFormat.format(transaction.date);
      if (!activityDateMap.containsKey(key)){
        activityDateMap[key] = [];
      }
      activityDateMap[key]!.add(transaction);
    }
    return Column(
      children: [
        for (MapEntry<String, List<TransactionActivity>> dateEntry in activityDateMap.entries)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(left: 12, top: 20),
                child: Text(
                  dateTitleFormat.format(dateKeyFormat.parse(dateEntry.key)),
                  style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 18, color: Colors.grey),
                )
              ),
              for (TransactionActivity transaction in dateEntry.value)
                _TransactionCard(
                  transaction: transaction,
                )
            ],
          )
      ],
    );
  }

  @override
  void initState() {
    transactions = AddressData.transactionsActivity;
    for (TransactionActivity activity in transactions){
      if (activity.status == "pending"){
        TransactionWatchdog.addTransactionActivity(activity);
      }
    }
    transactionStatusSubscription = eventBus.on<OnTransactionStatusChange>().listen((event) {
      if (!mounted) return;
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(left: 12, top: 25),
              child: Text("Recent Activity", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 25),)
            ),
            transactions.isEmpty ? const _NoRecentActivityWidget() : transactionsListWidget(),
          ],
        ),
      )
    );
  }
}

class _NoRecentActivityWidget extends StatelessWidget {
  const _NoRecentActivityWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: Get.height * 0.25,),
            SvgPicture.asset("assets/images/activity_list.svg", width: 60,),
            const SizedBox(height: 10,),
            Text("Nothing here yet!", textAlign: TextAlign.center, style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 18),),
            const SizedBox(height: 5,),
            Text("After you've made a transaction\nyou can track it here", textAlign: TextAlign.center, style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 13, color: Colors.grey),),
          ],
        ),
      ),
    );
  }
}

class _TransactionCard extends StatefulWidget {
  final TransactionActivity transaction;
  const _TransactionCard({Key? key, required this.transaction}) : super(key: key);

  @override
  State<_TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<_TransactionCard> {

  Widget swapValueWidget(){
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          CurrencyUtils.formatCurrency(
            BigInt.parse(widget.transaction.data["amount"]!),
            TokenInfoStorage.getTokenByAddress(widget.transaction.data["currency"]!)!,
            includeSymbol: true,
            formatSmallDecimals: true,
          ),
          style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),
        ),
        const Icon(PhosphorIcons.caretRightBold, size: 15,),
        Text(
          CurrencyUtils.formatCurrency(
            BigInt.parse(widget.transaction.data["swapReceive"]!),
            TokenInfoStorage.getTokenByAddress(widget.transaction.data["swapCurrency"]!)!,
            includeSymbol: true,
            formatSmallDecimals: true,
          ),
          style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),
        ),
      ],
    );
  }

  Color getStatusColor(String status){
    switch (status) {
      case "success": return Colors.green;
      case "pending": return Colors.orange;
      case "failed": return Colors.red;
      case "failed-to-submit": return Colors.red;
      default: return Colors.green;
    }
  }

  IconData getActionIcon(String action){
    switch (action) {
      case "transfer": return PhosphorIcons.paperPlaneTiltFill;
      case "swap": return PhosphorIcons.swapFill;
      case "guardian-grant": return PhosphorIcons.shieldBold;
      case "guardian-revoke": return PhosphorIcons.shieldBold;
      default: return PhosphorIcons.handPointingFill;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        await showBarModalBottomSheet(
          context: context,
          builder: (context) {
            Get.put<ScrollController>(ModalScrollController.of(context)!, tag: "transaction_details_modal");
            return TransactionActivityDetailsCard(
              transaction: widget.transaction,
            );
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Row(
          children: [
            Icon(getActionIcon(widget.transaction.action)),
            const SizedBox(width: 10,),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.transaction.title, style: TextStyle(fontFamily: AppThemes.fonts.gilroy),),
                const SizedBox(height: 2.5,),
                Row(
                  children: [
                    widget.transaction.status == "pending" ? Container(
                      margin: const EdgeInsets.only(right: 7.5),
                      width: 10,
                      height: 10,
                      child: const CircularProgressIndicator(strokeWidth: 3)
                    ) : const SizedBox.shrink(),
                    Text(widget.transaction.status.replaceAll("-", " ").capitalizeFirst!, style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: getStatusColor(widget.transaction.status)),),
                  ],
                ),
              ],
            ),
            const Spacer(),
            widget.transaction.action == "transfer" ? Text(
                CurrencyUtils.formatCurrency(
                  BigInt.parse(widget.transaction.data["amount"]!),
                  TokenInfoStorage.getTokenByAddress(widget.transaction.data["currency"]!)!,
                  includeSymbol: true,
                  formatSmallDecimals: true
                ),
                style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),
              ) : widget.transaction.action == "swap" ? swapValueWidget() : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}


