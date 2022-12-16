import 'dart:async';

import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/controller/address_persistent_data.dart';
import 'package:candide_mobile_app/controller/settings_persistent_data.dart';
import 'package:candide_mobile_app/utils/constants.dart';
import 'package:candide_mobile_app/utils/events.dart';
import 'package:eth_sig_util/util/utils.dart';
import 'package:pausable_timer/pausable_timer.dart';

class TransactionWatchdog {
  static PausableTimer? _timer;
  static Map<String, TransactionActivity> transactions = {};

  static Future<Map?> getBundleStatus(String bundleHash) async {
    try {
      var receipt = await Constants.client.getTransactionReceipt(bundleHash);
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
      if (!receipt.status!) return null;
      return {
        "calls": [
          {
            "status": "CONFIRMED",
            "receipt": {
              "logs": receipt.logs.map((e) => {
                "address": e.address?.hexEip55,
                "topics": e.topics,
                "data": e.data,
              }).toList(),
              "success": receipt.status,
              "blockHash": bytesToHex(receipt.blockHash, include0x: true),
              "blockNumber": "0x${receipt.blockNumber.blockNum.toRadixString(16)}",
              "gasUsed": "0x${receipt.gasUsed?.toRadixString(16) ?? "0"}",
              "transactionHash": bytesToHex(receipt.transactionHash, include0x: true),
            }
          },
        ]
      };
    } catch (e) {
      return null;
    }
  }

  static Future<String> getTransactionStatus(String hash) async {
    try {
      var receipt = await Constants.client.getTransactionReceipt(hash);
      if (receipt == null) return "pending";
      return (receipt.status ?? false) ? "success" : "failed";
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
      futures.add(getTransactionStatus(entry.key).then((status) async {
        if (status == "pending") return;
        entry.value.status = status;
        removedActivities.add(entry.value);
        await AddressData.updateTransactionActivityStorage(entry.value, Networks.get(SettingsData.network)!.chainId.toInt());
      }));
    }
    await Future.wait(futures);
    for (TransactionActivity activity in removedActivities){
      transactions.remove(activity.hash);
      eventBus.fire(OnTransactionStatusChange(activity: activity));
    }
    if (transactions.isNotEmpty){
      _timer?..reset()..start();
    }
  }
}