import 'dart:async';

import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:candide_mobile_app/models/guardian_operation.dart';
import 'package:candide_mobile_app/screens/components/summary_table.dart';
import 'package:candide_mobile_app/screens/home/components/transaction/free_card_indicator.dart';
import 'package:candide_mobile_app/screens/home/guardians/components/guardian_review_leading.dart';
import 'package:candide_mobile_app/screens/home/send/components/send_review_leading.dart';
import 'package:candide_mobile_app/screens/home/swap/components/swap_review_leading.dart';
import 'package:candide_mobile_app/utils/currency.dart';
import 'package:candide_mobile_app/utils/events.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class TransactionActivityDetailsCard extends StatefulWidget {
  final TransactionActivity transaction;
  final Widget? leading;
  const TransactionActivityDetailsCard({Key? key, required this.transaction, this.leading}) : super(key: key);

  @override
  State<TransactionActivityDetailsCard> createState() => _TransactionActivityDetailsCardState();
}

class _TransactionActivityDetailsCardState extends State<TransactionActivityDetailsCard> {
  late final StreamSubscription transactionStatusSubscription;

  Color getStatusColor(String status){
    switch (status) {
      case "success": return Colors.green;
      case "pending": return Colors.orange;
      case "failed": return Colors.red;
      case "failed-to-submit": return Colors.red;
      case "transaction-lost": return Colors.red;
      default: return Colors.green;
    }
  }

  Widget getLeadingWidget(){
    if (widget.transaction.action == "transfer"){
      return SendReviewLeadingWidget(
        token: TokenInfoStorage.getTokenByAddress(widget.transaction.data["currency"]!)!,
        value: BigInt.parse(widget.transaction.data["amount"]!),
      );
    }else if (widget.transaction.action == "swap"){
      return SwapReviewLeadingWidget(
        baseCurrency: TokenInfoStorage.getTokenByAddress(widget.transaction.data["currency"]!)!,
        baseValue: BigInt.parse(widget.transaction.data["amount"]!),
        quoteCurrency: TokenInfoStorage.getTokenByAddress(widget.transaction.data["swapCurrency"]!)!,
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
        "Operation": widget.transaction.action.contains("grant") ? "Add recovery contact" : "Remove recovery contact",
        "Recovery Contact address": widget.transaction.data["guardian"]!,
      });
    }
    entries["Status"] = widget.transaction.status.replaceAll("-", " ").capitalizeFirst;
    entries["Estimated fee"] = "< ${CurrencyUtils.formatCurrency(
        widget.transaction.fee.fee,
        TokenInfoStorage.getTokenByAddress(widget.transaction.fee.currencyAddress)!,
        includeSymbol: true,
        formatSmallDecimals: true).replaceAll("<", "")}";
    if (widget.transaction.status == "failed-to-submit"){
      entries["Transaction fee"] = CurrencyUtils.formatCurrency(BigInt.zero, TokenInfoStorage.getTokenByAddress(widget.transaction.fee.currencyAddress)!, includeSymbol: true, formatSmallDecimals: true);
      entries.remove("Estimated fee");
    }
    if (widget.transaction.fee.actualFee != null){
      entries["Transaction fee"] = CurrencyUtils.formatCurrency(
          widget.transaction.fee.actualFee!,
          TokenInfoStorage.getTokenByAddress(widget.transaction.fee.currencyAddress)!,
          includeSymbol: true,
          formatSmallDecimals: true);
      entries.remove("Estimated fee");
    }
    entries["Network"] = Networks.selected().chainId.toString();
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
    var tableEntries = getTableEntries();
    bool userOperationFullSponsored = widget.transaction.status == "success" && (widget.transaction.fee.fee == BigInt.zero || widget.transaction.fee.actualFee == BigInt.zero);
    if (userOperationFullSponsored){
      tableEntries["Transaction fee"] = "";
      tableEntries.remove("Estimated fee");
    }
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
                    widget.leading != null ? Container(
                      margin: const EdgeInsets.only(top: 10),
                      child: widget.leading,
                    ) : const SizedBox.shrink(),
                    const SizedBox(height: 25,),
                    getLeadingWidget(),
                    const SizedBox(height: 15,),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: Get.width * 0.03),
                      child: SummaryTable(
                        entries: [
                          for (MapEntry entry in tableEntries.entries)
                            SummaryTableEntry(
                              title: entry.key,
                              titleStyle: null,
                              trailing: entry.key == "Transaction fee" && userOperationFullSponsored ? const FreeCardIndicator() : null,
                              value: entry.key == "Network" ? Networks.getByChainId(int.parse(entry.value))!.name : entry.value,
                              valueStyle: entry.key == "Network" || entry.key == "Status" ? TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: entry.key == "Status" ? getStatusColor(widget.transaction.status) : Networks.getByChainId(PersistentData.selectedAccount.chainId)!.color) : null,
                            )
                        ],
                      ),
                    ),
                    const Spacer(),
                    widget.transaction.txHash != null && (widget.transaction.txHash?.removeAllWhitespace.isNotEmpty ?? false) ? Directionality(
                      textDirection: TextDirection.rtl,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          String url = "";
                          if (widget.transaction.hash != null && widget.transaction.hash!.isNotEmpty && Networks.selected().explorers.containsKey("jiffyscan")){
                            url = Networks.selected().explorers["jiffyscan"]!.replaceAll("{data}", "userOpHash/${widget.transaction.hash}");
                          }else{
                            url = Networks.selected().explorers["etherscan"]!.replaceAll("{data}", "tx/${widget.transaction.txHash}");
                          }
                          Utils.launchUri(url, mode: LaunchMode.externalApplication);
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