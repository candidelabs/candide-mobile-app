import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/controller/settings_persistent_data.dart';
import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:candide_mobile_app/services/token_info_fetcher.dart';
import 'package:candide_mobile_app/services/transaction_watchdog.dart';
import 'package:candide_mobile_app/utils/constants.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:wallet_dart/contracts/social_module.dart';
import 'package:wallet_dart/wallet/wallet_instance.dart';
import 'package:web3dart/web3dart.dart';

class AddressData {
  // Load from Box called "state" at "selected_wallet"
  static late WalletInstance selectedWallet;

  // Load from Box called "wallets" at "wallets"
  static late List<WalletInstance> wallets;

  // Load from Box called "activity" at "transactions(walletAddress-chainId)"
  static late int _loadedChainId;
  static List<TransactionActivity> transactionsActivity = [];

  // Load from Box called "state" at "guardians_metadata(walletAddress-chainId)"
  static List<WalletGuardian> guardians = [];

  // Load from Box called "state" at "recovery_request_id"
  static String? recoveryRequestId;

  // Load from Box called "state" at "address_data(walletAddress-chainId)"
  static late WalletStatus walletStatus;
  static late WalletBalance walletBalance;
  static late List<ContactAddress> contacts = [];
  static List<CurrencyBalance> currencies = [];

  static loadExplorerJson(Map? json) async {
    json ??= Hive.box("state").get("address_data");
    if (json == null){
      walletStatus = WalletStatus(
        proxyDeployed: false,
        nonce: 0,
      );
      walletBalance = WalletBalance(
        quoteCurrency: "USDT",
        currentBalance: BigInt.zero,
      );
      currencies = [];
      contacts = [];
      return;
    }
    //
    if (json["walletBalance"] != null){
      walletBalance = WalletBalance.fromJson(json["walletBalance"]);
    }
    //
    if (json["currencies"] != null){
      List<CurrencyBalance> _currencies = [];
      for (var currency in json["currencies"]){
        CurrencyBalance currencyBalance = CurrencyBalance.fromJson(currency);
        if (TokenInfoStorage.getTokenByAddress(currencyBalance.currencyAddress.toLowerCase()) == null){
          TokenInfo? token = await TokenInfoFetcher.fetchTokenInfo(currencyBalance.currencyAddress, Networks.getByName(SettingsData.network)!.chainId.toInt());
          if (token != null){
            await TokenInfoStorage.addToken(token);
            _currencies.add(currencyBalance);
          }
        }else{
          _currencies.add(currencyBalance);
        }
      }
      currencies.clear();
      currencies = _currencies;
    }
    //
  }

  static updateTransactionActivityStorage(TransactionActivity activity, int chainId) async {
    List transactionsAsJson = Hive.box("activity").get("transactions($chainId)") ?? [];
    List<Map> newTransactionsJson = [];
    for (Map transactionJson in transactionsAsJson){
      var temp = TransactionActivity.fromJson(transactionJson);
      if (temp.hash == activity.hash){
        newTransactionsJson.add(activity.toJson());
      }else{
        newTransactionsJson.add(temp.toJson());
      }
    }
    await Hive.box("activity").put("transactions($chainId)", newTransactionsJson);
  }

  static storeNewTransactionActivity(TransactionActivity activity, int chainId){
    List transactionsAsJson = Hive.box("activity").get("transactions($chainId)") ?? [];
    transactionsAsJson.add(activity.toJson());
    Hive.box("activity").put("transactions($chainId)", transactionsAsJson);
    if (_loadedChainId == chainId){
      transactionsActivity.add(activity);
    }
    if (activity.status == "pending"){
      TransactionWatchdog.addTransactionActivity(activity);
    }
  }

  static loadTransactionsActivity(int chainId){
    _loadedChainId = chainId;
    transactionsActivity.clear();
    List transactionsAsJson = Hive.box("activity").get("transactions($chainId)") ?? []; // List<Json>
    for (Map transactionJson in transactionsAsJson){
      var activity = TransactionActivity.fromJson(transactionJson);
      transactionsActivity.add(activity);
      if (activity.status == "pending"){
        TransactionWatchdog.addTransactionActivity(activity);
      }
    }
  }

  static loadGuardians(EthereumAddress walletAddress) async {
    var json = Hive.box("state").get("guardians_metadata");
    Map<String, List<dynamic>> metadata = {};
    //
    if (json != null){
      for (var guardianMetadata in json){
        metadata[guardianMetadata["address"].toString().toLowerCase()] = [guardianMetadata["type"], guardianMetadata["nickname"], guardianMetadata["email"], guardianMetadata['creationDate'] != null ? DateFormat("dd/MM/yyy").parse(guardianMetadata['creationDate']) : null];
      }
    }
    //
    Set<String> pendingRevocations = {};
    for (TransactionActivity activity in transactionsActivity){
      if (activity.status.toLowerCase() != "pending") continue;
      if (activity.action == "guardian-revoke"){
        pendingRevocations.add(activity.data["guardian"]!.toLowerCase());
      }
    }
    //
    guardians.clear();
    var interface = ISocialModule.interface(client: Constants.client);
    List<EthereumAddress> _guardians = (await interface.getGuardians(walletAddress));
    int guardiansCount = _guardians.length;
    if (guardiansCount > 0){
      int index = 0;
      for (EthereumAddress guardianAddress in _guardians){
        var guardianMetadata = metadata.containsKey(guardianAddress.hex.toLowerCase()) ? metadata[guardianAddress.hex.toLowerCase()] : null;
        var guardian = WalletGuardian(
          index: index,
          address: guardianAddress.hex,
          type: guardianMetadata?[0] ?? "unknown",
          nickname: guardianMetadata?[1],
          email: guardianMetadata?[2],
          creationDate: guardianMetadata?[3],
        );
        if (pendingRevocations.contains(guardianAddress.hex.toLowerCase())){
          guardian.isBeingRemoved = true;
        }
        guardians.add(guardian);
        index++;
      }
    }
  }

  static storeGuardians() async {
    List guardiansJson = [];
    for (WalletGuardian guardian in guardians){
      guardiansJson.add(guardian.toJson());
    }
    await Hive.box("state").put("guardians_metadata", guardiansJson);
  }

  static loadRecoveryRequest(){
    recoveryRequestId = Hive.box("state").get("recovery_request_id");
  }

  static storeRecoveryRequest(String? id) async {
    if (id == null) return;
    await Hive.box("state").put("recovery_request_id", id);
  }

  static void loadWallets(){
    wallets.clear();
    List walletsAsJson = Hive.box("wallets").get("wallets") ?? []; // List<Json>
    for (Map<String, dynamic> walletJson in walletsAsJson){
      var wallet = WalletInstance.fromJson(walletJson);
      wallets.add(wallet);
    }
    selectWallet();
  }

  static Future<void> insertWallet(WalletInstance wallet) async {
    wallets.add(wallet);
    await Hive.box("wallets").put("wallets", wallets.map((e) => e.toJson()).toList());
  }

  static void selectWallet({EthereumAddress? address, int? chainId}){
    if (address == null || chainId == null){
      String? selectedData = Hive.box("state").get("selected_wallet", defaultValue: null);
      if (selectedData == null) return;
      address = EthereumAddress.fromHex(selectedData.split(";")[0]);
      chainId = int.parse(selectedData.split(";")[1]);
    }
    for (WalletInstance wallet in wallets){
      if (wallet.walletAddress == address && chainId == chainId){
        selectedWallet = wallet;
        return;
      }
    }
  }

  static Future<void> updateExplorerJson(WalletInstance wallet, Map json) async {
    loadExplorerJson(json);
    //
    await Hive.box("state").put("address_data(${wallet.walletAddress.hex}-${wallet.chainId})", json);
  }

  static BigInt getCurrencyBalance(String currencyAddress){
    CurrencyBalance? balance = currencies.firstWhereOrNull((element) => element.currencyAddress.toLowerCase() == currencyAddress.toLowerCase());
    if (balance == null) return BigInt.zero;
    return balance.balance;
  }

}

class WalletStatus {
  bool proxyDeployed;
  int nonce;

  WalletStatus({
    required this.proxyDeployed,
    required this.nonce
  });

  WalletStatus.fromJson(Map json)
      : proxyDeployed = json['proxyDeployed'],
        nonce = json['nonce'];
}

class WalletBalance {
  String quoteCurrency;
  BigInt currentBalance;

  WalletBalance({required this.quoteCurrency,
    required this.currentBalance});

  WalletBalance.fromJson(Map json)
      : quoteCurrency = json['quoteCurrency'],
        currentBalance = BigInt.parse(json['currentBalance']);
}


class CurrencyBalance {
  String currencyAddress;
  String quoteCurrency;
  BigInt balance;
  BigInt currentBalanceInQuote;

  CurrencyBalance({required this.currencyAddress,
    required this.quoteCurrency,
    required this.balance,
    required this.currentBalanceInQuote});

  CurrencyBalance.fromJson(Map json)
      : currencyAddress = json['currency'],
        quoteCurrency = json['quoteCurrency'],
        balance = BigInt.parse(json['balance']),
        currentBalanceInQuote = BigInt.parse(json['currentBalanceInQuoteCurrency']);

  Map<String, dynamic> toJson() => {
    'currency': currencyAddress,
    'quoteCurrency': quoteCurrency,
    'balance': balance.toString(),
    'currentBalanceInQuote': currentBalanceInQuote.toString(),
  };

}

class ContactAddress{
  String address;
  String? ens;

  ContactAddress.fromJson(Map json)
      : address = json['currency'],
        ens = json['quoteCurrency'];

  Map<String, dynamic> toJson() => {
    'address': address,
    'ens': ens,
  };
}

class WalletGuardian {
  int index;
  String address;
  String type;
  String? nickname;
  String? email;
  DateTime? creationDate;
  bool isBeingRemoved; // flag to determine if a guardian has a current removal operation

  WalletGuardian({required this.index,
    required this.address,
    required this.type,
    this.nickname,
    this.email,
    this.creationDate,
    this.isBeingRemoved = false});

  WalletGuardian.fromJson(Map json)
      : index = json['index'],
        address = json['address'],
        type = json['type'],
        nickname = json['nickname'],
        email = json['email'],
        creationDate = json['creationDate'] != null ? DateFormat("dd/MM/yyy").parse(json['creationDate']) : null,
        isBeingRemoved = false;

  Map<String, dynamic> toJson() => {
    'index': index,
    'address': address,
    'type': type,
    'nickname': nickname,
    'email': email,
    'creationDate': creationDate != null ? DateFormat("dd/MM/yyy").format(creationDate!) : null,
  };
}

class TransactionActivity {
  DateTime date;
  String action;
  String title;
  String status;
  String? hash;
  Map<String, String> data;
  late TransactionFeeActivityData fee;

  TransactionActivity({required this.date,
    required this.action,
    required this.title,
    required this.status,
    this.hash,
    required this.data});

  TransactionActivity.fromJson(Map json)
      : date = DateTime.fromMillisecondsSinceEpoch(int.parse(json['date'])),
        action = json['action'],
        title = json['title'],
        status = json['status'],
        hash = json['hash'],
        data = Map<String, String>.from(json['data']),
        fee = TransactionFeeActivityData.fromJson(json['fee']);

  Map<String, dynamic> toJson() => {
    'date': date.millisecondsSinceEpoch.toString(),
    'action': action,
    'title': title,
    'status': status,
    'hash': hash,
    'data': data,
    'fee': fee.toJson(),
  };
}

class TransactionFeeActivityData {
  String paymasterAddress;
  /// Currency Address
  String currencyAddress;
  BigInt fee;

  TransactionFeeActivityData({required this.paymasterAddress,
    required this.currencyAddress,
    required this.fee});

  TransactionFeeActivityData.fromJson(Map json)
      : paymasterAddress = json['paymasterAddress'],
        currencyAddress = json['currency'],
        fee = BigInt.parse(json['fee']);

  Map<String, dynamic> toJson() => {
    'paymasterAddress': paymasterAddress,
    'currency': currencyAddress,
    'fee': fee.toString(),
  };
}