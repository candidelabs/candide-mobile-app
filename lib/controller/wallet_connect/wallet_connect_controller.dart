import 'dart:async';
import 'dart:convert';

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
import 'package:candide_mobile_app/screens/home/wallet_connect/wc_session_request_sheet.dart';
import 'package:candide_mobile_app/screens/home/wallet_connect/wc_signature_request_sheet.dart';
import 'package:candide_mobile_app/services/transaction_watchdog.dart';
import 'package:candide_mobile_app/utils/currency.dart';
import 'package:candide_mobile_app/utils/events.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:pausable_timer/pausable_timer.dart';
import 'package:short_uuids/short_uuids.dart';
import 'package:wallet_dart/wallet/account.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/crypto.dart';

class WalletConnectController {
  late String sessionId;
  late WalletConnect connector;
  int _reconnectAttempts = 0;

  static Account? _lastRestoredSessionsAccount;
  static late PausableTimer _connectivityTimer;
  static List<WalletConnectController> instances = [];

  // todo: remove when dapps support receiving UserOperation hashes
  static final Map<String, List<dynamic>> _statusListenerHashes = {}; // key: UO hash, value: [connector, payload id]
  static void initUserOpListener(){
    eventBus.on<OnTransactionStatusChange>().listen((event) {
      if (event.activity.hash == null) return;
      if (_statusListenerHashes[event.activity.hash] != null){
        if (event.activity.txHash == null) return;
        WalletConnect connector = _statusListenerHashes[event.activity.hash]![0];
        connector.approveRequest(id: _statusListenerHashes[event.activity.hash]![1], result: event.activity.txHash!);
      }
    });
  }

  // Save to Box called "wallet_connect" at "sessions({wallet_connect_version})({account_address}-{chainId})"
  static Future<void> persistAllSessions(Account account) async {
    List<String> sessionsIds = [];
    for (final WalletConnectController controller in instances){
      sessionsIds.add(controller.sessionId);
    }
    await Hive.box("wallet_connect").put("sessions(1)(${account.address.hex}-${account.chainId})", sessionsIds);
  }

  static void restoreAllSessions(Account account) async {
    _lastRestoredSessionsAccount ??= account;
    if (_lastRestoredSessionsAccount!.chainId != account.chainId || _lastRestoredSessionsAccount!.address != account.address){
      for (final WalletConnectController controller in instances){
        await controller.connector.close(forceClose: true);
      }
      instances.clear();
    }
    _lastRestoredSessionsAccount = account;
    List sessions = Hive.box("wallet_connect").get("sessions(1)(${account.address.hex}-${account.chainId})") ?? []; // List<String>
    for (String sessionId in sessions){
      await restoreSession(sessionId);
      await Future.delayed(const Duration(milliseconds: 250));
    }
  }

  static disconnectAllSessions() async {
    for (final WalletConnectController controller in instances){
      await controller.connector.killSession();
      controller.connector.close(forceClose: true);
    }
    instances.clear();
  }

  static startConnectivityAssuranceTimer(){
    _connectivityTimer = PausableTimer(const Duration(seconds: 40), _ensureConnectivity);
    _connectivityTimer.start();
  }

  static _ensureConnectivity() async {
    for (final WalletConnectController controller in instances){
      if (!controller.connector.bridgeConnected || controller._reconnectAttempts >= 3){
        controller.connector.reconnect();
        controller._reconnectAttempts = 0;
      }else{
        controller._reconnectAttempts++;
      }
    }
    _connectivityTimer..reset()..start();
  }

  static restoreSession(String sessionId) async {
    SessionStorage storage = _WalletConnectSecureStorage(storageKey: sessionId);
    WalletConnectSession? session = await storage.getSession();
    if (session == null) return;
    for (final WalletConnectController controller in instances){
      if (controller.sessionId == sessionId) return;
    }
    var controller = WalletConnectController();
    controller.connectSession(storage, session, sessionId);
  }

  WalletConnect connectSession(SessionStorage storage, WalletConnectSession session, String _sessionId){
    sessionId = _sessionId;
    connector = WalletConnect(
      sessionStorage: storage,
      session: session,
    );
    _initializeListeners();
    if (!connector.bridgeConnected){
      connector.reconnect();
    }
    if (!connector.connected){
      connector.connect(chainId: Networks.selected().chainId.toInt());
    }
    instances.add(this);
    return connector;
  }

  WalletConnect connect(String uri, String _sessionId){
    sessionId = _sessionId;
    connector = WalletConnect(
      uri: uri,
      clientMeta: const PeerMeta(
        name: "CANDIDE Wallet",
        url: "https://candidewallet.com/",
        icons: ["https://raw.githubusercontent.com/candidelabs/candide-mobile-app/main/assets/images/logo.jpeg"],
      ),
      sessionStorage: _WalletConnectSecureStorage(storageKey: sessionId)
    );
    _initializeListeners();
    instances.add(this);
    return connector;
  }

  Future<void> disconnect() async {
    await connector.killSession();
  }

  void _initializeListeners(){
    connector.on('connect', _handleConnect);
    connector.on('disconnect', _handleDisconnect);
    connector.on('session_request', _handleSessionRequest);
    connector.on('session_update', _handleSessionUpdate);
    //
    connector.on('eth_sign', _ethSign);
    connector.on('eth_signTypedData', _ethSignTypedData);
    connector.on('eth_signTypedData_v1', _ethSignTypedData);
    connector.on('eth_signTypedData_v2', _ethSignTypedData);
    connector.on('eth_signTypedData_v3', _ethSignTypedData);
    connector.on('eth_signTypedData_v4', _ethSignTypedData);
    connector.on('personal_sign', _ethPersonalSign);
    //
    connector.on('eth_sendTransaction', _ethSendTransaction);
    //
    connector.on('wallet_sendFunctionCallBundle', walletSendFunctionCallBundle);
    connector.on('wallet_getBundleStatus', walletGetBundleStatus);
    connector.on('wallet_showBundleStatus', walletShowBundleStatus);
  }

  void _handleConnect(Object? session) async {
    if (session is SessionStatus){
      await connector.sessionStorage?.store(connector.session);
      persistAllSessions(PersistentData.selectedAccount);
    }
  }

  void _handleDisconnect(Object? session){
    connector.close();
    instances.remove(this);
    persistAllSessions(PersistentData.selectedAccount);
    eventBus.fire(OnWalletConnectDisconnect());
  }

  void _handleSessionRequest(WCSessionRequest? payload){
    //print(payload);
    if (payload == null) return;
    if (payload.peerMeta == null) return;
    connector.session.clientMeta = payload.peerMeta;
    showBarModalBottomSheet(
      context: Get.context!,
      backgroundColor: Get.theme.canvasColor,
      builder: (context) => SingleChildScrollView(
        controller: ModalScrollController.of(context),
        child: WCSessionRequestSheet(
          onApprove: (){
            connector.approveSession(accounts: [PersistentData.selectedAccount.address.hexEip55], chainId: Networks.selected().chainId.toInt());
            Get.back();
            Utils.showBottomStatus(
              "Connected to ${connector.session.peerMeta!.name}",
              "Please check the application",
              loading: false,
              success: true,
            );
          },
          onReject: (){
            connector.rejectSession();
            Get.back();
          },
          isConforming: true,
          peerMeta: WCPeerMeta.fromPeerMeta(connector.session.peerMeta),
        ),
      ),
    );
  }

  void _handleSessionUpdate(Object? payload){
    //print(payload.runtimeType);
    //print(payload);
    if (payload == null) return;
  }

  void _ethSendTransaction(JsonRpcRequest? payload) async {
    if (payload == null) return;
    WCPeerMeta peerMeta = WCPeerMeta.fromPeerMeta(connector.session.peerMeta);
    var cancelLoad = Utils.showLoading();
    Batch wcBatch = await Batch.create(account: PersistentData.selectedAccount, refreshAccountData: true);
    String hexValue = "0x00";
    String gasLimit = "0x00";
    String data = "0x";
    if ((payload.params![0] as Map).containsKey("value")){
      hexValue = payload.params![0]["value"];
    }
    if ((payload.params![0] as Map).containsKey("gas")){
      gasLimit = payload.params![0]["gas"];
    }
    if ((payload.params![0] as Map).containsKey("data")){
      data = payload.params![0]["data"];
    }
    hexValue = hexValue.replaceAll("0x", "");
    gasLimit = gasLimit.replaceAll("0x", "");
    BigInt value = BigInt.parse(hexValue, radix: 16);
    BigInt gasValue = BigInt.parse(gasLimit, radix: 16);
    EthereumAddress toAddress = EthereumAddress.fromHex(payload.params![0]["to"]);
    var toCode = await Networks.selected().client.getCode(toAddress);
    bool isTransfer = toCode.isEmpty || toAddress.hex == PersistentData.selectedAccount.address.hex;
    //
    GnosisTransaction transaction = GnosisTransaction(
      id: "wc-$sessionId-${const ShortUuid().generate()}",
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
      "To": payload.params![0]["to"],
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
            params: payload.params!,
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
      connector.rejectRequest(id: payload.id, errorMessage: "Rejected by user");
    }else{
      if (transactionActivity.txHash != null){
        connector.approveRequest(id: payload.id, result: transactionActivity.txHash!);
      }else{
        _statusListenerHashes[transactionActivity.hash!] = [connector, payload.id];
      }
    }
  }

  void walletSendFunctionCallBundle(JsonRpcRequest? payload) async {
    if (payload == null) return;
    if (payload.params == null) return;
    WCPeerMeta peerMeta = WCPeerMeta.fromPeerMeta(connector.session.peerMeta);
    //print(payload.toJson());
    var cancelLoad = Utils.showLoading();
    Batch wcBatch = await Batch.create(account: PersistentData.selectedAccount, refreshAccountData: true);
    BigInt totalValue = BigInt.zero;
    for (Map call in payload.params![0]["calls"]){
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
        id: "wc-$sessionId-${const ShortUuid().generate()}",
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
            params: payload.params!,
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
      connector.rejectRequest(id: payload.id, errorMessage: "Rejected by user");
    }else{
      if (transactionActivity.txHash != null){
        connector.approveRequest(id: payload.id, result: transactionActivity.txHash!);
      }else{
        _statusListenerHashes[transactionActivity.hash!] = [connector, payload.id];
      }
    }
  }

  void walletGetBundleStatus(JsonRpcRequest? payload) async {
    if (payload == null) return;
    if (payload.params == null) return;
    Map? result = await TransactionWatchdog.getBundleStatus(payload.params![0]);
    if (result == null){
      connector.rejectRequest(id: payload.id);
      return;
    }
    connector.approveRequest(id: payload.id, result: jsonEncode(result));
  }

  void walletShowBundleStatus(JsonRpcRequest? payload) async {
    if (payload == null) return;
    if (payload.params == null) return;
    TransactionActivity? activity = PersistentData.transactionsActivity.firstWhereOrNull((element) => element.hash == payload.params![0]);
    if (activity == null){
      connector.rejectRequest(id: payload.id);
      return;
    }
    connector.approveRequest(id: payload.id, result: "");
    await showBarModalBottomSheet(
      context: Get.context!,
      backgroundColor: Get.theme.canvasColor,
      builder: (context) {
        Get.put<ScrollController>(ModalScrollController.of(context)!, tag: "transaction_details_modal");
        return TransactionActivityDetailsCard(
          leading: WCBundleStatusLeading(
            peerMeta: WCPeerMeta.fromPeerMeta(connector.session.peerMeta),
          ),
          transaction: activity,
        );
      },
    );
  }

  void _ethSignTypedData(JsonRpcRequest? payload){
    if (payload == null) return;
    String type = "typed-v4";
    if (payload.method != "eth_signTypedData"){
      RegExp regexp = RegExp(r"^eth_signTypedData_v([1,3,4])");
      type = "typed-v${regexp.allMatches(payload.method).last.group(1) ?? "4"}";
    }
    _showSignatureRequest(payload.id, type, payload.params?[1] ?? "");
  }

  void _ethSign(JsonRpcRequest? payload){
    if (payload == null) return;
    //print(payload.toJson());
    _showSignatureRequest(payload.id, "sign", payload.params?[1] ?? "");
  }

  void _ethPersonalSign(JsonRpcRequest? payload) {
    if (payload == null) return;
    //print(payload.toJson());
    _showSignatureRequest(payload.id, "personal", payload.params?[0] ?? "");
  }

  void _showSignatureRequest(int requestId, String type, String payload) async {
    WCPeerMeta peerMeta = WCPeerMeta.fromPeerMeta(connector.session.peerMeta);
    if (!PersistentData.accountStatus.proxyDeployed){
      await showDialog(
        context: Get.context!,
        builder: (_) => WCSignatureRejectDialog(peerMeta: peerMeta,),
        useRootNavigator: false,
      );
      connector.rejectRequest(id: requestId);
      return;
    }
    showBarModalBottomSheet(
      context: Get.context!,
      backgroundColor: Get.theme.canvasColor,
      builder: (context) {
        Get.put<ScrollController>(ModalScrollController.of(context)!, tag: "wc_signature_modal");
        return SignatureRequestSheet(
          peerMeta: peerMeta,
          signatureType: type,
          payload: payload,
          onReject: () async {
            await connector.rejectRequest(id: requestId);
            Get.back();
          },
          onSign: (signature) async {
            await connector.approveRequest(id: requestId, result: signature);
            Get.back();
          },
        );
      },
    );
  }


}

class _WalletConnectSecureStorage implements SessionStorage {
  final String storageKey;
  final FlutterSecureStorage _storage;

  _WalletConnectSecureStorage({
    this.storageKey = 'wc_default_session',
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<WalletConnectSession?> getSession() async {
    final json = await _storage.read(key: storageKey);
    if (json == null) {
      return null;
    }

    try {
      final data = jsonDecode(json);
      return WalletConnectSession.fromJson(data);
    } on FormatException {
      return null;
    }
  }

  @override
  Future store(WalletConnectSession session) async {
    await _storage.write(key: storageKey, value: jsonEncode(session.toJson()));
  }

  @override
  Future removeSession() async {
    await _storage.delete(key: storageKey);
  }
}