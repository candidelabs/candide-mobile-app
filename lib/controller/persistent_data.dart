import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:candide_mobile_app/services/token_info_fetcher.dart';
import 'package:candide_mobile_app/services/transaction_watchdog.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:wallet_dart/contracts/social_module.dart';
import 'package:wallet_dart/wallet/account.dart';
import 'package:wallet_dart/wallet/encrypted_signer.dart';
import 'package:web3dart/web3dart.dart';

class PersistentData {
  // Load from Box called "wallet" at "selected_account"
  static const String ACCOUNT_VERSION = "0.0.1";
  static late Account selectedAccount;

  // Load from Box called "signers" at ("id" = signer)
  static const String ENCRYPTED_SIGNERS_VERSION = "0.0.0";
  static Map<String, EncryptedSigner> walletSigners = {};

  // Load from Box called "wallet" at "accounts"
  static List<Account> accounts = [];

  // Load from Box called "activity" at "transactions(accountAddress-chainId)"
  static late int _loadedChainId;
  static List<TransactionActivity> transactionsActivity = [];

  // Load from Box called "state" at "guardians_metadata(accountAddress-chainId)"
  static List<AccountGuardian> guardians = [];

  // Load from Box called "state" at "hidden_networks"
  static List<int> hiddenNetworks = [];

  // Load from Box called "state" at "address_data(accountAddress-chainId)"
  static late AccountStatus accountStatus;
  static late AccountBalance accountBalance;
  static List<ContactAddress> contacts = [];
  static List<CurrencyBalance> currencies = [];

  // Temporary session values
  static final Map<int, List<dynamic>> _recoverableStatus = {}; // Map<Account HashCode, [bool recoverable, int expireAt]> temporarily store recoverable status of accounts instead of always fetching it

  static loadExplorerJson(Account account, Map? json) async {
    json ??= Hive.box("state").get("address_data(${account.address.hex}-${account.chainId})");
    if (json == null){
      accountStatus = AccountStatus(
        proxyDeployed: false,
        nonce: 0,
      );
      accountBalance = AccountBalance(
        quoteCurrency: "USD",
        currentBalance: 0,
      );
      currencies = [];
      contacts = [];
      return;
    }
    //
    if (json["accountBalance"] != null){
      accountBalance = AccountBalance.fromJson(json["accountBalance"]);
    }
    //
    if (json["currencies"] != null){
      List<CurrencyBalance> _currencies = [];
      for (var currency in json["currencies"]){
        CurrencyBalance currencyBalance = CurrencyBalance.fromJson(currency);
        if (TokenInfoStorage.getTokenByAddress(currencyBalance.currencyAddress.toLowerCase()) == null){
          TokenInfo? token = await TokenInfoFetcher.fetchTokenInfo(currencyBalance.currencyAddress);
          if (token != null){
            await TokenInfoStorage.addToken(token, account.chainId);
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

  static updateTransactionActivityStorage(Account account, TransactionActivity activity) async {
    List transactionsAsJson = Hive.box("activity").get("transactions(${account.address.hex}-${account.chainId})") ?? [];
    List<Map> newTransactionsJson = [];
    for (Map transactionJson in transactionsAsJson){
      var temp = TransactionActivity.fromJson(transactionJson);
      if (temp.hash == activity.hash){
        newTransactionsJson.add(activity.toJson());
      }else{
        newTransactionsJson.add(temp.toJson());
      }
    }
    await Hive.box("activity").put("transactions(${account.address.hex}-${account.chainId})", newTransactionsJson);
  }

  static storeNewTransactionActivity(Account account, TransactionActivity activity){
    List transactionsAsJson = Hive.box("activity").get("transactions(${account.address.hex}-${account.chainId})") ?? [];
    transactionsAsJson.add(activity.toJson());
    Hive.box("activity").put("transactions(${account.address.hex}-${account.chainId})", transactionsAsJson);
    if (_loadedChainId == account.chainId){
      transactionsActivity.add(activity);
    }
    if (activity.status == "pending"){
      TransactionWatchdog.addTransactionActivity(activity);
    }
  }

  static loadTransactionsActivity(Account account){
    _loadedChainId = account.chainId;
    transactionsActivity.clear();
    List transactionsAsJson = Hive.box("activity").get("transactions(${account.address.hex}-${account.chainId})") ?? []; // List<Json>
    for (Map transactionJson in transactionsAsJson){
      var activity = TransactionActivity.fromJson(transactionJson);
      transactionsActivity.add(activity);
      if (activity.status == "pending"){
        TransactionWatchdog.addTransactionActivity(activity);
      }
    }
  }

  static loadGuardians(Account account) async {
    EthereumAddress socialRecoveryModuleAddress = Networks.getByChainId(account.chainId)!.socialRecoveryModule;
    if (account.socialRecoveryModule != null){
      socialRecoveryModuleAddress = account.socialRecoveryModule!;
    }
    var json = Hive.box("state").get("guardians_metadata(${account.address.hex}-${account.chainId})");
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
    var interface = ISocialModule.interface(address: socialRecoveryModuleAddress, client: Networks.selected().client);
    List<EthereumAddress> _guardians = (await interface.getGuardians(account.address));
    int guardiansCount = _guardians.length;
    if (guardiansCount > 0){
      int index = 0;
      for (EthereumAddress guardianAddress in _guardians){
        var guardianMetadata = metadata.containsKey(guardianAddress.hex.toLowerCase()) ? metadata[guardianAddress.hex.toLowerCase()] : null;
        var guardian = AccountGuardian(
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

  static storeGuardians(Account account) async {
    // reset recoverable status for this account so it's re-fetched next time
    _recoverableStatus.remove(account.hashCode);
    //
    List guardiansJson = [];
    for (AccountGuardian guardian in guardians){
      guardiansJson.add(guardian.toJson());
    }
    await Hive.box("state").put("guardians_metadata(${account.address.hex}-${account.chainId})", guardiansJson);
  }

  static Future<bool> isAccountRecoverable(Account account) async {
    if (account.socialRecoveryModule == null) return false;
    if (_recoverableStatus.containsKey(account.hashCode)){
      var status = _recoverableStatus[account.hashCode];
      if ((status![1] as int) > DateTime.now().millisecondsSinceEpoch){
        return status[0] as bool;
      }
    }
    Network network = Networks.getByChainId(account.chainId)!;
    var interface = ISocialModule.interface(address: account.socialRecoveryModule!, client: network.client);
    BigInt count = (await interface.guardiansCount(account.address));
    bool recoverable = count.toInt() > 0;
    _recoverableStatus[account.hashCode] = [recoverable, DateTime.now().millisecondsSinceEpoch + const Duration(minutes: 5).inMilliseconds];
    return recoverable;
  }

  static void loadSigners(){
    walletSigners.clear();
    for (String id in Hive.box("signers").keys){
      walletSigners[id] = EncryptedSigner.fromJson(Hive.box("signers").get(id));
    }
  }

  static Future<void> addSigner(String id, EncryptedSigner signer) async {
    walletSigners[id] = signer;
    await saveSigners();
  }

  static Future<void> saveSigners() async {
    var _signersMap = walletSigners.map((key, value) => MapEntry(key, value.toJson()));
    await Hive.box("signers").putAll(_signersMap);
  }

  static Future<void> loadAccounts() async {
    List<String> deprecatedVersions = ["0.0.0"];
    bool _deprecatedFlag = false;
    accounts.clear();
    List accountsAsJson = Hive.box("wallet").get("accounts") ?? []; // List<Json>
    for (var accountJson in accountsAsJson){
      var account = Account.fromJson(accountJson);
      if (deprecatedVersions.contains(account.version)){
        _deprecatedFlag = true;
        continue;
      }
      accounts.add(account);
    }
    if (_deprecatedFlag){
      await saveAccounts();
    }
    selectAccount();
  }


  static Future<void> saveAccounts() async {
    await Hive.box("wallet").put("accounts", accounts.map((e) => e.toJson()).toList());
  }

  static Future<void> insertAccount(Account account) async {
    accounts.add(account);
    await Hive.box("wallet").put("accounts", accounts.map((e) => e.toJson()).toList());
  }

  static Future<void> deleteAccount(Account account) async {
    accounts.remove(account);
    await Hive.box("wallet").put("accounts", accounts.map((e) => e.toJson()).toList());
  }

  static void selectAccount({EthereumAddress? address, int? chainId}) async {
    if (address == null || chainId == null){
      String? selectedData = Hive.box("wallet").get("selected_account", defaultValue: null);
      if (selectedData == null){
        if (accounts.isNotEmpty){
          selectedAccount = accounts.first;
          TokenInfoStorage.loadAllTokens(selectedAccount.chainId);
          loadExplorerJson(selectedAccount, null);
        }
        return;
      }
      address = EthereumAddress.fromHex(selectedData.split(";")[0]);
      chainId = int.parse(selectedData.split(";")[1]);
    }
    Hive.box("wallet").put("selected_account", "${address.hex};$chainId");
    for (Account account in accounts){
      if (account.address == address && account.chainId == chainId){
        selectedAccount = account;
        TokenInfoStorage.loadAllTokens(selectedAccount.chainId);
        loadExplorerJson(selectedAccount, null);
        return;
      }
    }
    // if got here then there was no selected account
    if (accounts.isNotEmpty){
      selectedAccount = accounts.first;
      TokenInfoStorage.loadAllTokens(selectedAccount.chainId);
      loadExplorerJson(selectedAccount, null);
    }
  }

  static Account? getAccount({required EthereumAddress address, required int chainId}){
    for (Account account in accounts){
      if (account.address == address && account.chainId == chainId){
        return account;
      }
    }
    return null;
  }

  static Future<void> updateExplorerJson(Account account, Map json) async {
    loadExplorerJson(account, json);
    //
    await Hive.box("state").put("address_data(${account.address.hex}-${account.chainId})", json);
  }

  static List<int> loadHiddenNetworks() {
    hiddenNetworks = Hive.box("state").get("hidden_networks", defaultValue: List.from(Networks.DEFAULT_HIDDEN_NETWORKS)).cast<int>();
    return hiddenNetworks;
  }

  static Future<void> storeHiddenNetworks() async {
    await Hive.box("state").put("hidden_networks", hiddenNetworks);
  }

  static BigInt getCurrencyBalance(String currencyAddress){
    CurrencyBalance? balance = currencies.firstWhereOrNull((element) => element.currencyAddress.toLowerCase() == currencyAddress.toLowerCase());
    if (balance == null) return BigInt.zero;
    return balance.balance;
  }

}

class AccountStatus {
  bool proxyDeployed;
  int nonce;

  AccountStatus({
    required this.proxyDeployed,
    required this.nonce
  });

  AccountStatus.fromJson(Map json)
      : proxyDeployed = json['proxyDeployed'],
        nonce = json['nonce'];
}

class AccountBalance {
  String quoteCurrency;
  double currentBalance;

  AccountBalance({required this.quoteCurrency,
    required this.currentBalance});

  AccountBalance.fromJson(Map json)
      : quoteCurrency = json['quoteCurrency'],
        currentBalance = json['currentBalance'];
}


class CurrencyBalance {
  String currencyAddress;
  String quoteCurrency;
  BigInt balance;
  double currentBalanceInQuote;

  CurrencyBalance({required this.currencyAddress,
    required this.quoteCurrency,
    required this.balance,
    required this.currentBalanceInQuote});

  CurrencyBalance.fromJson(Map json)
      : currencyAddress = json['currency'],
        quoteCurrency = json['quoteCurrency'],
        balance = json['balance'],
        currentBalanceInQuote = json['currentBalanceInQuoteCurrency'];

  Map<String, dynamic> toJson() => {
    'currency': currencyAddress,
    'quoteCurrency': quoteCurrency,
    'balance': balance,
    'currentBalanceInQuote': currentBalanceInQuote,
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

class AccountGuardian {
  int index;
  String address;
  String type;
  String? nickname;
  String? email;
  DateTime? creationDate;
  bool isBeingRemoved; // flag to determine if a guardian has a current removal operation

  AccountGuardian({required this.index,
    required this.address,
    required this.type,
    this.nickname,
    this.email,
    this.creationDate,
    this.isBeingRemoved = false});

  AccountGuardian.fromJson(Map json)
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
  String version;
  DateTime date;
  String action;
  String title;
  String status;
  String? paymasterEventTopic; // used to extract gas cost from paymaster emitted event
  String? hash;
  String? txHash;
  Map<String, String> data;
  late TransactionFeeActivityData fee;

  static const String _version = "0.0.1";

  TransactionActivity({
    this.version = _version,
    required this.date,
    required this.action,
    required this.title,
    required this.status,
    this.paymasterEventTopic,
    this.hash,
    this.txHash,
    required this.data});

  TransactionActivity.fromJson(Map json)
      : version = json['version'] ?? "0.0.0",
        date = DateTime.fromMillisecondsSinceEpoch(int.parse(json['date'])),
        action = json['action'],
        title = json['title'],
        status = json['status'],
        paymasterEventTopic = json['paymasterEventTopic'],
        hash = json['hash'],
        txHash = json['txHash'],
        data = Map<String, String>.from(json['data']),
        fee = TransactionFeeActivityData.fromJson(json['fee']);

  Map<String, dynamic> toJson() => {
    'version': version,
    'date': date.millisecondsSinceEpoch.toString(),
    'action': action,
    'title': title,
    'status': status,
    'paymasterEventTopic': paymasterEventTopic,
    'hash': hash,
    'txHash': txHash,
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