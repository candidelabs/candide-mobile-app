import 'dart:convert';

import 'package:candide_mobile_app/config/env.dart';
import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:candide_mobile_app/controller/wallet_connect/wc_peer_meta.dart';
import 'package:candide_mobile_app/models/batch.dart';
import 'package:candide_mobile_app/models/gnosis_transaction.dart';
import 'package:candide_mobile_app/screens/home/activity/components/transaction_activity_details_card.dart';
import 'package:candide_mobile_app/screens/home/components/transaction/transaction_review_sheet.dart';
import 'package:candide_mobile_app/screens/home/send/components/send_review_leading.dart';
import 'package:candide_mobile_app/screens/home/wallet_connect/components/wc_activity_bundle_status_leading.dart';
import 'package:candide_mobile_app/screens/home/wallet_connect/components/wc_review_leading.dart';
import 'package:candide_mobile_app/screens/home/wallet_connect/components/wc_signature_reject_dialog.dart';
import 'package:candide_mobile_app/screens/home/wallet_connect/components/wc_switch_account_sheet.dart';
import 'package:candide_mobile_app/screens/home/wallet_connect/wc_session_request_sheet.dart';
import 'package:candide_mobile_app/screens/home/wallet_connect/wc_signature_request_sheet.dart';
import 'package:candide_mobile_app/services/transaction_watchdog.dart';
import 'package:candide_mobile_app/utils/currency.dart';
import 'package:candide_mobile_app/utils/events.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:short_uuids/short_uuids.dart';
import 'package:wallet_dart/wallet/account.dart';
import 'package:walletconnect_flutter_v2/apis/sign_api/utils/sign_api_validator_utils.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class WalletConnectV2Controller {
  bool wcClientInitialized = false;
  late Web3Wallet wcClient;
  Map<String, dynamic> _namespaceMethods = {};
  Map<String, SessionData> tempSessions = {};
  static WalletConnectV2Controller? _instance;


  static Future<WalletConnectV2Controller> instance() async {
    if (_instance == null){
      _instance = WalletConnectV2Controller();
      await _instance!._initializeClient();
      return _instance!;
    }
    return _instance!;
  }

  static Future<bool> initialize() async {
    if (_instance == null){
      _instance = WalletConnectV2Controller();
      await _instance!._initializeClient();
      return true;
    }
    await _instance!._initializeClient();
    return true;
  }

  Future<String> waitForTxHash(String uoHash) async {
    await for (final event in eventBus.on<OnTransactionStatusChange>()) {
      if (event.activity.hash == null) continue;
      if (event.activity.txHash == null) continue;
      if (event.activity.hash!.toLowerCase() == uoHash.toLowerCase()) {
        return event.activity.txHash!;
      }
    }
    return Errors.getSdkError(Errors.USER_REJECTED).message;
  }

  void _fillMethods(){
    var chains = Networks.instances.map((e) => e.chainId.toInt()).toList();
    _namespaceMethods = {
      'eth_sign': {"chains": chains, "implementation": _ethSign},
      'eth_signTypedData': {"chains": chains, "implementation": _ethSignTypedData},
      'eth_signTypedData_v1': {"chains": chains, "implementation": _ethSignTypedData},
      'eth_signTypedData_v2': {"chains": chains, "implementation": _ethSignTypedData},
      'eth_signTypedData_v3': {"chains": chains, "implementation": _ethSignTypedData},
      'eth_signTypedData_v4': {"chains": chains, "implementation": _ethSignTypedData},
      'personal_sign': {"chains": chains, "implementation": _ethPersonalSign},
      'eth_sendTransaction': {"chains": chains, "implementation": _ethSendTransaction},
      'wallet_sendFunctionCallBundle': {"chains": chains, "implementation": _walletSendFunctionCallBundle},
      'wallet_getBundleStatus': {"chains": chains, "implementation": _walletGetBundleStatus},
      'wallet_showBundleStatus': {"chains": chains, "implementation": _walletShowBundleStatus},
    };
  }


  Future<void> _initializeClient() async {
    if (wcClientInitialized) return;
    var wcProjectId = Env.walletConnectProjectId;
    if (wcProjectId.trim().isEmpty || wcProjectId.trim() == "-") return;
    wcClient = await Web3Wallet.createInstance(
      relayUrl: 'wss://relay.walletconnect.com',
      projectId: wcProjectId,
      metadata: const PairingMetadata(
        name: 'CANDIDE Wallet',
        description: 'Smart contract wallet, supports social recovery, gas sponsorships, multi-calls, and more...',
        url: 'https://candidewallet.com/',
        icons: ['https://raw.githubusercontent.com/candidelabs/candide-mobile-app/main/assets/images/logo.jpeg'],
      ),
    );
    _fillMethods();
    wcClient.onSessionProposal.subscribe(_handleSessionRequest);
    wcClient.onSessionDelete.subscribe((SessionDelete? sessionDelete) {
      tempSessions.remove(sessionDelete?.topic);
      eventBus.fire(OnWalletConnectDisconnect());
    });
    for (MapEntry entry in _namespaceMethods.entries){
      for (int chain in entry.value["chains"]){
        wcClient.registerRequestHandler(
          chainId: "eip155:$chain",
          method: entry.key,
          handler: (String topic, dynamic parameters) async {
            return await _requestHandlerMiddleware(entry.key, topic, parameters, entry.value["implementation"]);
          },
        );
      }
    }
    wcClientInitialized = true;
  }

  void _handleSessionRequest(SessionProposalEvent? payload){
    if (payload == null) return;
    final walletNamespaces = {
      'eip155': Namespace(
        accounts: ['eip155:${Networks.selected().chainId.toInt()}:${PersistentData.selectedAccount.address.hex}'],
        methods: _namespaceMethods.keys.toList(),
        events: ["chainChanged", "accountsChanged"],
      ),
    };
    bool isConforming = true;
    try {
      SignApiValidatorUtils.isConformingNamespaces(
        context: "pre_approve()",
        namespaces: walletNamespaces,
        requiredNamespaces: payload.params.requiredNamespaces,
      );
    } catch (e) {
      isConforming = false;
    }
    showBarModalBottomSheet(
      context: Get.context!,
      backgroundColor: Get.theme.canvasColor,
      builder: (context) => SingleChildScrollView(
        controller: ModalScrollController.of(context),
        child: WCSessionRequestSheet(
          onApprove: () async {
            ApproveResponse response = await wcClient.approveSession(
              id: payload.id,
              namespaces: walletNamespaces,
            );
            tempSessions[response.topic] = response.session;
            Get.back();
            Utils.showBottomStatus(
              "Connected to ${payload.params.proposer.metadata.name}",
              "Please check the application",
              loading: false,
              success: true,
            );
          },
          onReject: (){
            wcClient.rejectSession(
              id: payload.id,
              reason: Errors.getSdkError(Errors.USER_REJECTED),
            );
            Get.back();
          },
          isConforming: isConforming,
          peerMeta: WCPeerMeta.fromPairingMetadata(payload.params.proposer.metadata),
        ),
      ),
    );
  }


  void connect(String scannedUriString) async {
    if (!wcClientInitialized){
      await _initializeClient();
    }
    if (!wcClientInitialized) return;
    Uri uri = Uri.parse(scannedUriString);
    await wcClient.pair(uri: uri);
  }

  Future<String> _requestHandlerMiddleware(String method, String topic, dynamic parameters, dynamic Function(String, dynamic, dynamic) handler) async {
    if (Get.context == null) return Errors.getSdkError(Errors.USER_REJECTED).message;
    if (Get.currentRoute == "/PinEntryScreen") return Errors.getSdkError(Errors.USER_REJECTED).message;
    EthereumAddress targetAddress;
    if (method == "eth_sign" || method.startsWith("eth_signTypedData")){
      targetAddress = EthereumAddress.fromHex(parameters[0]);
    }else if (method == "personal_sign"){
      targetAddress = EthereumAddress.fromHex(parameters[1]);
    }else if (method == "eth_sendTransaction" || method == "wallet_sendFunctionCallBundle"){
      targetAddress = EthereumAddress.fromHex(parameters[0]["from"]);
    }else {
      SessionData? sessionData = wcClient.getActiveSessions()[topic];
      if (sessionData == null) return Errors.getSdkError(Errors.USER_REJECTED).message;
      RegExp regex = RegExp(r'.*:(.*$)');
      String address = regex.firstMatch(sessionData.namespaces["eip155"]!.accounts[0])!.group(1)!;
      targetAddress = EthereumAddress.fromHex(address);
    }
    if (targetAddress != PersistentData.selectedAccount.address){
      Account? targetAccount = PersistentData.getAccount(address: targetAddress);
      if (targetAccount == null) return Errors.getSdkError(Errors.USER_REJECTED).message;
      WCPeerMeta peerMeta = getPeerMetaFromTopic(topic);
      bool? result = await showBarModalBottomSheet(
        context: Get.context!,
        backgroundColor: Get.theme.canvasColor,
        builder: (context) {
          Get.put<ScrollController>(ModalScrollController.of(context)!, tag: "wc_switch_account_modal");
          return WCSwitchAccountSheet(
            peerMeta: peerMeta,
            targetAccount: targetAccount,
            onReject: (){
              Get.back(result: false);
            },
            onAccept: (){
              PersistentData.selectAccount(address: targetAccount.address, chainId: targetAccount.chainId);
              Get.back(result: true);
              eventBus.fire(OnAccountChange());
            },
          );
        },
      );
      result = result ?? false;
      if (!result) {
        return Errors.getSdkError(Errors.USER_REJECTED).message;
      }else{
        if (TransactionReviewSheet.active > 0){
          while (TransactionReviewSheet.active > 0){
            Get.back();
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    dynamic extraData;
    if (method.startsWith("eth_signTypedData")){
      extraData = "typed-v4";
      if (method != "eth_signTypedData"){
        RegExp regexp = RegExp(r"^eth_signTypedData_v([1,3,4])");
        extraData = "typed-v${regexp.allMatches(method).last.group(1) ?? "4"}";
      }
    }
    return await handler.call(topic, parameters, extraData);
  }

  Future<String> _ethSignTypedData(String topic, dynamic parameters, dynamic type) async {
    String result = await _showSignatureRequest(topic, type, parameters[1] ?? "");
    return result;
  }

  Future<String> _ethSign(String topic, dynamic parameters, dynamic extraData) async {
    String result = await _showSignatureRequest(topic, "sign", parameters[1] ?? "");
    return result;
  }

  Future<String> _ethPersonalSign(String topic, dynamic parameters, dynamic extraData) async {
    String result = await _showSignatureRequest(topic, "personal", parameters[0] ?? "");
    return result;
  }

  Future<String> _showSignatureRequest(String topic, String type, String payload) async {
    WCPeerMeta peerMeta = getPeerMetaFromTopic(topic);
    if (!PersistentData.accountStatus.proxyDeployed){
      await showDialog(
        context: Get.context!,
        builder: (_) => WCSignatureRejectDialog(peerMeta: peerMeta,),
        useRootNavigator: false,
      );
      return Errors.getSdkError(Errors.USER_REJECTED_SIGN).message;
    }
    var result = await showBarModalBottomSheet(
      context: Get.context!,
      backgroundColor: Get.theme.canvasColor,
      builder: (context) {
        Get.put<ScrollController>(ModalScrollController.of(context)!, tag: "wc_signature_modal");
        return SignatureRequestSheet(
          peerMeta: peerMeta,
          signatureType: type,
          payload: payload,
          onReject: () => Get.back(result: Errors.getSdkError(Errors.USER_REJECTED_SIGN).message),
          onSign: (signature) => Get.back(result: signature),
        );
      },
    );
    return result ?? Errors.getSdkError(Errors.USER_REJECTED_SIGN).message;
  }


  Future<String> _ethSendTransaction(String topic, dynamic parameters, dynamic extraData) async {
    WCPeerMeta peerMeta = getPeerMetaFromTopic(topic);
    var cancelLoad = Utils.showLoading();
    Batch wcBatch = await Batch.create(account: PersistentData.selectedAccount, refreshAccountData: true);
    String hexValue = "0x00";
    String gasLimit = "0x00";
    String data = "0x";
    if ((parameters[0] as Map).containsKey("value")){
      hexValue = parameters[0]["value"];
    }
    if ((parameters[0] as Map).containsKey("gas")){
      gasLimit = parameters[0]["gas"];
    }
    if ((parameters[0] as Map).containsKey("data")){
      data = parameters[0]["data"];
    }
    hexValue = hexValue.replaceAll("0x", "");
    gasLimit = gasLimit.replaceAll("0x", "");
    BigInt value = BigInt.parse(hexValue, radix: 16);
    BigInt gasValue = BigInt.parse(gasLimit, radix: 16);
    EthereumAddress toAddress = EthereumAddress.fromHex(parameters[0]["to"]);
    var toCode = await Networks.selected().client.getCode(toAddress);
    bool isTransfer = toCode.isEmpty || toAddress.hex == PersistentData.selectedAccount.address.hex;
    //
    GnosisTransaction transaction = GnosisTransaction(
      id: "wc-$topic-${const ShortUuid().generate()}",
      to: toAddress,
      value: value,
      data: hexToBytes(data),
      type: GnosisTransactionType.execTransactionFromEntrypoint,
      suggestedGasLimit: gasValue,
    );
    wcBatch.transactions.add(transaction);
    //
    await wcBatch.fetchPaymasterResponse();
    //
    cancelLoad();
    TransactionActivity transactionActivity = TransactionActivity(
      date: DateTime.now(),
      action: isTransfer ? "transfer" : "wc-transaction",
      title: isTransfer ? "Sent ETH" : "Contract Interaction",
      status: "pending",
      data: {"currency": "ETH", "amount": value.toString(), "to": toAddress.hexEip55},
    );
    //
    Map<String, String> tableEntriesData = {
      "To": parameters[0]["to"],
    };
    if (value > BigInt.zero){
      tableEntriesData["Value"] = CurrencyUtils.formatCurrency(value, TokenInfoStorage.getTokenBySymbol("ETH")!, includeSymbol: true, formatSmallDecimals: true);
    }
    tableEntriesData["Network"] = Networks.selected().chainId.toString();
    //
    var executed = await showBarModalBottomSheet(
      context: Get.context!,
      backgroundColor: Get.theme.canvasColor,
      builder: (context) {
        Get.put<ScrollController>(ModalScrollController.of(context)!, tag: "wc_transaction_review_modal");
        return TransactionReviewSheet(
          modalId: "wc_transaction_review_modal",
          leading: isTransfer ? SendReviewLeadingWidget(
            token: TokenInfoStorage.getTokenBySymbol("ETH")!,
            value: value,
            peerMeta: peerMeta,
          ) : WCReviewLeading(
            peerMeta: peerMeta,
            params: parameters,
            isMultiCall: false,
          ),
          tableEntriesData: tableEntriesData,
          batch: wcBatch,
          transactionActivity: transactionActivity,
          showRejectButton: true,
        );
      },
    );
    if (executed == null || !executed){
      return Errors.getSdkError(Errors.USER_REJECTED_SIGN).message;
    }else{
      if (transactionActivity.txHash != null){
        return transactionActivity.txHash!;
      }else{
        return await waitForTxHash(transactionActivity.hash!);
      }
    }
  }

  Future<String> _walletSendFunctionCallBundle(String topic, dynamic parameters, dynamic extraData) async {
    WCPeerMeta peerMeta = getPeerMetaFromTopic(topic);
    var cancelLoad = Utils.showLoading();
    Batch wcBatch = await Batch.create(account: PersistentData.selectedAccount, refreshAccountData: true);
    BigInt totalValue = BigInt.zero;
    for (Map call in parameters[0]["calls"]){
      String hexValue = "0x00";
      String gasLimit = "0x00";
      String data = "0x";
      if (call.containsKey("value")){
        hexValue = call["value"];
      }
      if (call.containsKey("gas")){
        gasLimit = call["gas"];
      }
      if (call.containsKey("data")){
        data = call["data"];
      }
      hexValue = hexValue.replaceAll("0x", "");
      gasLimit = gasLimit.replaceAll("0x", "");
      BigInt value = BigInt.parse(hexValue, radix: 16);
      BigInt gasValue = BigInt.parse(gasLimit, radix: 16);
      totalValue += value;
      EthereumAddress toAddress = EthereumAddress.fromHex(call["to"]);
      //
      GnosisTransaction transaction = GnosisTransaction(
        id: "wc-$topic-${const ShortUuid().generate()}",
        to: toAddress,
        value: value,
        data: hexToBytes(data),
        type: GnosisTransactionType.execTransactionFromEntrypoint,
        suggestedGasLimit: gasValue,
      );
      wcBatch.transactions.add(transaction);
    }
    //
    await wcBatch.fetchPaymasterResponse();
    //
    cancelLoad();
    TransactionActivity transactionActivity = TransactionActivity(
      date: DateTime.now(),
      action: "wc-transaction",
      title: "Contract Interaction",
      status: "pending",
      data: {"currency": "ETH", "amount": totalValue.toString(), "to": "multi-call"},
    );
    //
    Map<String, String> tableEntriesData = {};
    if (totalValue > BigInt.zero){
      tableEntriesData["Value"] = CurrencyUtils.formatCurrency(totalValue, TokenInfoStorage.getTokenBySymbol("ETH")!, includeSymbol: true, formatSmallDecimals: true);
    }
    tableEntriesData["Network"] = Networks.selected().chainId.toString();
    //
    var executed = await showBarModalBottomSheet(
      context: Get.context!,
      backgroundColor: Get.theme.canvasColor,
      builder: (context) {
        Get.put<ScrollController>(ModalScrollController.of(context)!, tag: "wc_transaction_review_modal");
        return TransactionReviewSheet(
          modalId: "wc_transaction_review_modal",
          leading: WCReviewLeading(
            peerMeta: peerMeta,
            params: parameters,
            isMultiCall: true,
          ),
          tableEntriesData: tableEntriesData,
          batch: wcBatch,
          transactionActivity: transactionActivity,
          showRejectButton: true,
        );
      },
    );
    if (executed == null || !executed){
      return Errors.getSdkError(Errors.USER_REJECTED_SIGN).message;
    }else{
      if (transactionActivity.txHash != null){
        return transactionActivity.hash!;
      }else{
        await waitForTxHash(transactionActivity.hash!);
        return transactionActivity.hash!;
      }
    }
  }

  Future<String> _walletGetBundleStatus(String topic, dynamic parameters, dynamic extraData) async {
    Map? result = await TransactionWatchdog.getBundleStatus(parameters[0]);
    if (result == null){
      return Errors.getSdkError(Errors.USER_REJECTED_SIGN).message;
    }
    return jsonEncode(result);
  }

  Future<String> _walletShowBundleStatus(String topic, dynamic parameters, dynamic extraData) async {
    WCPeerMeta peerMeta = getPeerMetaFromTopic(topic);
    TransactionActivity? activity = PersistentData.transactionsActivity.firstWhereOrNull((element) => element.hash == parameters[0]);
    if (activity == null){
      return Errors.getSdkError(Errors.USER_REJECTED_SIGN).message;
    }
    showBarModalBottomSheet(
      context: Get.context!,
      backgroundColor: Get.theme.canvasColor,
      builder: (context) {
        Get.put<ScrollController>(ModalScrollController.of(context)!, tag: "transaction_details_modal");
        return TransactionActivityDetailsCard(
          leading: WCBundleStatusLeading(
            peerMeta: peerMeta,
          ),
          transaction: activity,
        );
      },
    );
    return "";
  }

  WCPeerMeta getPeerMetaFromTopic(String topic){
    var sessions = wcClient.getActiveSessions();
    if (sessions.containsKey(topic)){
      return WCPeerMeta.fromPairingMetadata(sessions[topic]!.peer.metadata);
    }
    return WCPeerMeta.fromPairingMetadata(null);
  }

  List<SessionData> getAccountSessions(Account account){
    if (!wcClientInitialized) return [];
    List<SessionData> sessions = [];
    Set<String> addedTopics = {};
    for (MapEntry<String, SessionData> entry in wcClient.getActiveSessions().entries){
      if (entry.value.namespaces["eip155"]!.accounts.where((element) => element.toLowerCase().contains(account.address.hex.toLowerCase())).isEmpty) continue;
      addedTopics.add(entry.value.topic);
      sessions.add(entry.value);
    }
    for (MapEntry<String, SessionData> entry in tempSessions.entries){
      if (addedTopics.contains(entry.value.topic)) continue;
      if (entry.value.namespaces["eip155"]!.accounts.where((element) => element.toLowerCase().contains(account.address.hex.toLowerCase())).isEmpty) continue;
      sessions.add(entry.value);
    }
    return sessions;
  }

}