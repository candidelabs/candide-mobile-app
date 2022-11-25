import 'dart:async';

import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/address_persistent_data.dart';
import 'package:candide_mobile_app/controller/settings_persistent_data.dart';
import 'package:candide_mobile_app/models/guardian_operation.dart';
import 'package:candide_mobile_app/screens/components/summary_table.dart';
import 'package:candide_mobile_app/screens/home/guardians/components/guardian_review_leading.dart';
import 'package:candide_mobile_app/screens/home/send/components/send_review_leading.dart';
import 'package:candide_mobile_app/screens/home/swap/components/swap_review_leading.dart';
import 'package:candide_mobile_app/services/transaction_watchdog.dart';
import 'package:candide_mobile_app/utils/currency.dart';
import 'package:candide_mobile_app/utils/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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
            widget.transaction.data["currency"]!,
            includeSymbol: true,
            formatSmallDecimals: true,
          ),
          style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),
        ),
        const Icon(PhosphorIcons.caretRightBold, size: 15,),
        Text(
          CurrencyUtils.formatCurrency(
            BigInt.parse(widget.transaction.data["swapReceive"]!),
            widget.transaction.data["swapCurrency"]!,
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
            return _TransactionDetailsCard(
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
                CurrencyUtils.formatCurrency(BigInt.parse(widget.transaction.data["amount"]!), widget.transaction.data["currency"]!, includeSymbol: true, formatSmallDecimals: true),
                style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),
              ) : widget.transaction.action == "swap" ? swapValueWidget() : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}


class _TransactionDetailsCard extends StatefulWidget {
  final TransactionActivity transaction;
  const _TransactionDetailsCard({Key? key, required this.transaction}) : super(key: key);

  @override
  State<_TransactionDetailsCard> createState() => _TransactionDetailsCardState();
}

class _TransactionDetailsCardState extends State<_TransactionDetailsCard> {
  late final StreamSubscription transactionStatusSubscription;

  Color getStatusColor(String status){
    switch (status) {
      case "success": return Colors.green;
      case "pending": return Colors.orange;
      case "failed": return Colors.red;
      case "failed-to-submit": return Colors.red;
      default: return Colors.green;
    }
  }

  Widget getLeadingWidget(){
    if (widget.transaction.action == "transfer"){
      return SendReviewLeadingWidget(
        currency: widget.transaction.data["currency"]!,
        value: BigInt.parse(widget.transaction.data["amount"]!),
      );
    }else if (widget.transaction.action == "swap"){
      return SwapReviewLeadingWidget(
        baseCurrency: widget.transaction.data["currency"]!,
        baseValue: BigInt.parse(widget.transaction.data["amount"]!),
        quoteCurrency: widget.transaction.data["swapCurrency"]!,
        quoteValue: BigInt.parse(widget.transaction.data["swapReceive"]!),
      );
    }else if (widget.transaction.action.startsWith("guardian-")){
      return GuardianReviewLeadingWidget(
        operation: widget.transaction.action.contains("grant") ? GuardianOperation.grant : GuardianOperation.revoke,
      );
    }
    return const SizedBox.shrink();
  }

  Map getTableEntries(){
    Map entries = {};
      entries["Date"] = intl.DateFormat("dd/MM/yyyy hh:mm a").format(widget.transaction.date);
    if (widget.transaction.action == "transfer"){
      entries.addAll({
        "To": widget.transaction.data["to"]!,
      });
    }else if (widget.transaction.action == "swap"){
    }else if (widget.transaction.action.startsWith("guardian-")){
      entries.addAll({
        "Operation": widget.transaction.action.contains("grant") ? "Granting guardian" : "Removing guardian",
        "Guardian address": widget.transaction.data["guardian"]!,
      });
    }
    entries["Status"] = widget.transaction.status.replaceAll("-", " ").capitalizeFirst;
    entries["Transaction fee"] = "< ${CurrencyUtils.formatCurrency(widget.transaction.fee.fee, widget.transaction.fee.currency, includeSymbol: true, formatSmallDecimals: true)}";
    if (widget.transaction.status == "failed-to-submit"){
      entries["Transaction fee"] = CurrencyUtils.formatCurrency(BigInt.zero, widget.transaction.fee.currency, includeSymbol: true, formatSmallDecimals: true);
    }
    entries["Network"] = SettingsData.network;
    return entries;
  }


  @override
  void initState() {
    transactionStatusSubscription = eventBus.on<OnTransactionStatusChange>().listen((event) {
      if (!mounted) return;
      if (widget.transaction.hash == null) return;
      if (event.activity.hash != widget.transaction.hash) return;
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    transactionStatusSubscription.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          controller: Get.find<ScrollController>(tag: "transaction_details_modal"),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth, minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  const SizedBox(height: 15,),
                  Text("Transaction Details", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 20),),
                  const SizedBox(height: 25,),
                  getLeadingWidget(),
                  const SizedBox(height: 15,),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: Get.width * 0.03),
                    child: SummaryTable(
                      entries: [
                        for (MapEntry entry in getTableEntries().entries)
                          SummaryTableEntry(
                            title: entry.key,
                            titleStyle: entry.key == "Network" ? TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Networks.get(SettingsData.network)!.color) : null,
                            value: entry.value,
                            valueStyle: entry.key == "Network" || entry.key == "Status" ? TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: entry.key == "Status" ? getStatusColor(widget.transaction.status) : Networks.get(SettingsData.network)!.color) : null,
                          )
                      ],
                    ),
                  ),
                  const Spacer(),
                  widget.transaction.hash != null && (widget.transaction.hash?.removeAllWhitespace.isNotEmpty ?? false) ? Directionality(
                    textDirection: TextDirection.rtl,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        var url = "https://goerli.etherscan.io/tx/${widget.transaction.hash}";
                        var launchable = await canLaunchUrl(Uri.parse(url));
                        if (launchable) {
                          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                        } else {
                          throw "Could not launch URL";
                        }
                      },
                      style: ButtonStyle(
                        minimumSize: MaterialStateProperty.all(Size(Get.width * 0.9, 40)),
                        shape: MaterialStateProperty.all(const BeveledRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(7),
                          ),
                        )),
                      ),
                      icon: const Icon(PhosphorIcons.arrowSquareOutBold),
                      label: Text("View transaction details", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 18),),
                    ),
                  ) : const SizedBox.shrink(),
                  const SizedBox(height: 25,),
                ],
              ),
            ),
          ),
        );
      }
    );
  }
}

