import 'dart:async';

import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:candide_mobile_app/screens/home/activity/components/transaction_activity_details_card.dart';
import 'package:candide_mobile_app/services/bundler.dart';
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
      if (!receipt["status"]!) return null;
      return {
        "calls": [
          {
            "status": "CONFIRMED",
            "receipt": {
              "logs": receipt["receipt"]["logs"].map((e) => {
                "address": e.address?.hexEip55,
                "topics": e.topics,
                "data": e.data,
              }).toList(),
              "success": receipt["status"],
              "blockHash": bytesToHex(receipt["receipt"]["blockHash"], include0x: true),
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

  static Future<String> getUserOperationStatus(String hash) async {
    try {
      var receipt = await Bundler.getUserOperationReceipt(hash, Networks.selected().chainId.toInt());
      if (receipt == null) return "pending";
      String transactionHash = receipt["receipt"]["transactionHash"];
      return (receipt["success"] ?? false) ? "success:$transactionHash" : "failed:$transactionHash";
    } catch (e) {
      return "failed";
    }
  }

  static addTransactionActivity(TransactionActivity transactionActivity){
    if (transactionActivity.hash == null) return;
    if (transactions.containsKey(transactionActivity.hash)) return;
    transactions[transactionActivity.hash!] = transactionActivity;
    _timer ??= PausableTimer(const Duration(seconds: 1, milliseconds: 250), _checkAllTransactions);
    if (!(_timer!.isActive)){
      _timer!..reset()..start();
    }
  }

  static _checkAllTransactions() async {
    List<Future> futures = [];
    List<TransactionActivity> removedActivities = [];
    for (MapEntry<String, TransactionActivity> entry in transactions.entries){
      futures.add(getUserOperationStatus(entry.key).then((status) async {
        if (status == "pending") return;
        String txHash = status.split(":")[1];
        status = status.split(":")[0];
        entry.value.status = status;
        entry.value.txHash = txHash;
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