import 'dart:async';
import 'dart:math';

import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:candide_mobile_app/screens/home/activity/components/transaction_activity_details_card.dart';
import 'package:candide_mobile_app/services/bundler.dart';
import 'package:candide_mobile_app/utils/constants.dart';
import 'package:candide_mobile_app/utils/events.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:eth_sig_util/util/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:pausable_timer/pausable_timer.dart';

class TransactionWatchdog {
  static PausableTimer? _timer;
  static Map<String, TransactionActivity> transactions = {};

  static Future<Map?> getBundleStatus(String bundleHash) async {
    try {
      var receipt = await Bundler.getUserOperationReceipt(bundleHash, Networks.selected().chainId.toInt());
      if (receipt == null){
        if (transactions.containsKey(bundleHash)){
          return {
            "calls": [
              {"status": "PENDING"}
            ]
          };
        }
        return null;
      }
      if (!receipt["success"]!) return null;
      return {
        "calls": [
          {
            "status": "CONFIRMED",
            "receipt": {
              "logs": receipt["receipt"]["logs"].map((e) => {
                "address": e["address"],
                "topics": e["topics"],
                "data": e["data"],
              }).toList(),
              "success": receipt["success"],
              "blockHash": receipt["receipt"]["blockHash"],
              "blockNumber": receipt["receipt"]["blockNumber"],
              "gasUsed": receipt["receipt"]["gasUsed"],
              "transactionHash": receipt["receipt"]["transactionHash"],
            }
          },
        ]
      };
    } catch (e) {
      return null;
    }
  }

  static String getUserOperationStatus(Map<String, dynamic>? receipt) {
    if (receipt == null) return "pending";
    return (receipt["success"] ?? false) ? "success" : "failed";
  }

  static BigInt? getPaymasterFeeFromReceipt(Map<String, dynamic> receipt, String sponsoredEventTopic){
    for (Map<String, dynamic> log in receipt["receipt"]["logs"]){
      if (log["topics"][0].toString().toLowerCase() == sponsoredEventTopic.toLowerCase()){
        String value = log["data"].toString().toLowerCase().replaceAll("0x", "");
        return BigInt.parse(value, radix: 16);
      }
    }
    return null;
  }

  static addTransactionActivity(TransactionActivity transactionActivity){
    if (transactionActivity.hash == null) return;
    if (transactions.containsKey(transactionActivity.hash)) return;
    transactions[transactionActivity.hash!] = transactionActivity;
    _timer ??= PausableTimer(const Duration(seconds: 1, milliseconds: 500), _checkAllTransactions);
    if (!(_timer!.isActive)){
      _timer!..reset()..start();
    }
  }

  static bool _performCheck(int input) {
    double interval = 0.5;
    if (input < 10){
      interval = 3;
    }else if (input < 45){
      interval = 0.3;
    }
    if (input == 119 || (input % (interval * pow(10, (log(input) / ln10).floor()))) == 0) {
      return true;
    }
    return false;
  }

  static _checkAllTransactions() async {
    List<Future> futures = [];
    List<TransactionActivity> removedActivities = [];
    for (MapEntry<String, TransactionActivity> entry in transactions.entries){
      if (entry.value.checkCount == 120){
        entry.value.status = "transaction-lost"; // when a transaction is sent to the bundler but cannot find a receipt for it
        removedActivities.add(entry.value);
        await PersistentData.updateTransactionActivityStorage(PersistentData.selectedAccount, entry.value);
        continue;
      }
      entry.value.checkCount++;
      if (!_performCheck(entry.value.checkCount.toInt())) continue;
      futures.add(Bundler.getUserOperationReceipt(entry.key, Networks.selected().chainId.toInt()).then((receipt) async {
        if (receipt == null) return;
        var status = getUserOperationStatus(receipt);
        if (status == "pending") return;
        String txHash = receipt["receipt"]["transactionHash"];
        entry.value.status = status;
        entry.value.txHash = txHash;
        if (entry.value.fee.paymasterAddress != Constants.addressZeroHex){
          if (status == "failed"){
            entry.value.fee.actualFee = BigInt.zero;
          }else{
            if (entry.value.fee.sponsoredEventTopic != null && entry.value.fee.sponsoredEventTopic != "0x"){
              BigInt? actualFee = getPaymasterFeeFromReceipt(receipt, entry.value.fee.sponsoredEventTopic!);
              entry.value.fee.actualFee = actualFee;
            }
          }
        }else{
          if (receipt["actualGasCost"] != null){
            entry.value.fee.actualFee = BigInt.from(receipt["actualGasCost"]);
          }
        }
        removedActivities.add(entry.value);
        await PersistentData.updateTransactionActivityStorage(PersistentData.selectedAccount, entry.value);
      }));
    }
    await Future.wait(futures);
    for (TransactionActivity activity in removedActivities){
      transactions.remove(activity.hash);
      eventBus.fire(OnTransactionStatusChange(activity: activity));
      if (activity.status.toLowerCase() == "success"){
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
                  transaction: activity,
                );
              },
            );
          }
        );
      }else if (activity.status.toLowerCase() == "transaction-lost"){
        Utils.showBottomStatus(
          "Transaction failed",
          "Transaction was lost, please check it yourself on the block explorer.\nContact us for help",
          loading: false,
          success: false,
          duration: const Duration(seconds: 8),
        );
      }else{
        Utils.showBottomStatus(
          "Transaction failed",
          "Contact us for help",
          loading: false,
          success: false,
          duration: const Duration(seconds: 6),
        );
      }
    }
    if (transactions.isNotEmpty){
      _timer?..reset()..start();
    }
  }
}