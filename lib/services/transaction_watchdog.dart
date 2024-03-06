import 'dart:async';
import 'dart:math';

import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:candide_mobile_app/models/user_operation_receipt.dart';
import 'package:candide_mobile_app/screens/home/activity/components/transaction_activity_details_card.dart';
import 'package:candide_mobile_app/utils/constants.dart';
import 'package:candide_mobile_app/utils/events.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:eth_sig_util/util/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:pausable_timer/pausable_timer.dart';
import 'package:wallet_dart/utils/abi_utils.dart';
import 'package:web3dart/web3dart.dart';

class TransactionWatchdog {
  static PausableTimer? _timer;
  static Map<String, TransactionActivity> transactions = {};
  //
  static final Map<String, Stream<FilterEvent>?> _userOperationLogStream = {};
  static final Map<String, UserOperationReceipt> _receiptsRepo = {};

  static Future<Map?> getBundleStatus(String bundleHash, Network network) async {
    try {
      UserOperationReceipt? receipt = await _fetchUserOperationReceiptFromSources(bundleHash, network, 0);
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
      if (!receipt.success) return null;
      if (receipt.txReceipt == null) return null;
      return {
        "calls": [
          {
            "status": "CONFIRMED",
            "receipt": {
              "logs": receipt.txReceipt!.logs.map((e) => {
                "address": e.address?.hexEip55,
                "topics": e.topics,
                "data": e.data,
              }).toList(),
              "success": receipt.success,
              "blockHash": bytesToHex(receipt.txReceipt!.blockHash, include0x: true),
              "blockNumber": receipt.txReceipt!.blockNumber.blockNum,
              "gasUsed": receipt.txReceipt!.gasUsed != null ? '0x${receipt.txReceipt!.gasUsed!.toRadixString(16)}' : null,
              "transactionHash": bytesToHex(receipt.txReceipt!.transactionHash, include0x: true),
            }
          },
        ]
      };
    } catch (e) {
      return null;
    }
  }

  static Future<UserOperationReceipt> _filterEventToUserOperationReceipt(FilterEvent event, Network network) async {
    var data = decodeAbi(["uint256", "bool", "uint256", "uint256"], hexToBytes(event.data!));
    TransactionReceipt? txReceipt = await network.client.getTransactionReceipt(event.transactionHash!);
    UserOperationReceipt userOpReceipt = UserOperationReceipt(
        entryPoint: network.entrypoint,
        userOpHash: hexToBytes(event.topics![1]!),
        sender: EthereumAddress(hexToBytes(event.topics![2]!).sublist(12)),
        nonce: data[0],
        paymaster: EthereumAddress(hexToBytes(event.topics![3]!).sublist(12)),
        actualGasCost: data[2],
        actualGasUsed: data[3],
        success: data[1],
        logs: [event],
        txReceipt: txReceipt
    );
    return userOpReceipt;
  }

  static Future<UserOperationReceipt?> getUserOperationReceipt(String userOperationHash, Network network, {required bool useBundler}) async {
    if (useBundler){
      return await network.bundler.getUserOperationReceipt(userOperationHash);
    }
    List<FilterEvent> events = await network.client.getLogs(FilterOptions(
      fromBlock: const BlockNum.genesis(),
      toBlock: const BlockNum.current(),
      address: network.entrypoint,
      topics: [
        ["0x49628fd1471006c1482da88028e9ce4dbb080b815c9b0344d39e5a8e6ec1419f"],
        [bytesToHex(hexToBytes(userOperationHash), forcePadLength: 64, include0x: true)],
        [],
        []
      ]
    ));
    if (events.isEmpty) return null;
    FilterEvent event = events[0];
    return await _filterEventToUserOperationReceipt(event, network);
  }


  static Future<void> startListeningToUserOperations(Network network, EthereumAddress account) async {
    if (network.client.socketConnector == null) return;
    var key = "${network.chainId.toString()};${account.hexNo0x}";
    if (_userOperationLogStream[key] != null) return;
    var fromBlock = await network.client.getBlockNumber();
    _userOperationLogStream[key] = network.client.events(
      FilterOptions(
        address: network.entrypoint,
        fromBlock: BlockNum.exact(fromBlock-2),
        toBlock: const BlockNum.current(),
        topics: [
          ["0x49628fd1471006c1482da88028e9ce4dbb080b815c9b0344d39e5a8e6ec1419f"],
          [],
          [bytesToHex(account.addressBytes, forcePadLength: 64, include0x: true)],
          []
        ]
      ),
    );
    _userOperationLogStream[key]!.listen((event) async {
      await Future.delayed(const Duration(seconds: 2)); // give websocket node and http node time to be in sync
      var userOpReceipt = await _filterEventToUserOperationReceipt(event, network);
      var hashKey = bytesToHex(userOpReceipt.userOpHash, include0x: false).toLowerCase();
      _receiptsRepo[hashKey] = userOpReceipt;
    });
    return;
  }

  static String getUserOperationStatus(Map<String, dynamic>? receipt) {
    if (receipt == null) return "pending";
    return (receipt["success"] ?? false) ? "success" : "failed";
  }

  static BigInt? getPaymasterFeeFromReceipt(UserOperationReceipt receipt, String sponsoredEventTopic){
    if (receipt.txReceipt == null) return null;
    for (FilterEvent log in receipt.txReceipt!.logs){
      if (log.topics == null) continue;
      if (log.topics![0].toString().toLowerCase() == sponsoredEventTopic.toLowerCase()){
        String value = log.data.toString().toLowerCase().replaceAll("0x", "");
        return BigInt.parse(value, radix: 16);
      }
    }
    return null;
  }

  static final Map<String, int> _transactionsChainIdMap = {};
  static addTransactionActivity(TransactionActivity transactionActivity, Network network){
    if (transactionActivity.hash == null) return;
    if (transactions.containsKey(transactionActivity.hash)) return;
    _transactionsChainIdMap[transactionActivity.hash!] = network.chainId.toInt();
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

  static final Map<String, String> _fetchSourceMap = {};
  static Future<UserOperationReceipt?> _fetchUserOperationReceiptFromSources(String userOpHash, Network network, int activityCheckCount) async {
    var hashKey = userOpHash.replaceAll("0x", "").toLowerCase();
    if (_receiptsRepo.containsKey(hashKey)) return _receiptsRepo[hashKey];
    if (!_fetchSourceMap.containsKey(hashKey)){
      _fetchSourceMap[hashKey] = "bundler:0";
    }
    var _value = _fetchSourceMap[hashKey]!.split(":");
    String source = _value[0];
    int checks = int.parse(_value[1]);
    UserOperationReceipt? userOpReceipt;
    if (source == "bundler"){
      checks++;
      if (checks == 2) _fetchSourceMap[hashKey] = "node:0";
      userOpReceipt = await getUserOperationReceipt(userOpHash, network, useBundler: true);
    }else{
      checks++;
      if (checks == 2) _fetchSourceMap[hashKey] = "bundler:0";
      userOpReceipt = await getUserOperationReceipt(userOpHash, network, useBundler: false);
    }
    if (checks < 2) _fetchSourceMap[hashKey] = "$source:$checks";
    return userOpReceipt;
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
      Network network = Networks.getByChainId(_transactionsChainIdMap[entry.key]!)!;
      futures.add(_fetchUserOperationReceiptFromSources(entry.key, network, entry.value.checkCount).then((receipt) async {
        var status = receipt == null ? "pending" : (receipt.success ? "success" : "failed");
        if (receipt == null) return;
        if (status == "pending") return;
        String? txHash = receipt.txReceipt != null ? bytesToHex(receipt.txReceipt!.transactionHash, include0x: true) : null;
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
          if (receipt.actualGasCost != null){
            entry.value.fee.actualFee = receipt.actualGasCost;
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