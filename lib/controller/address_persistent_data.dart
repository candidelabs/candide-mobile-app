import 'dart:convert';

import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:wallet_dart/contracts/wallet.dart';
import 'package:wallet_dart/wallet/wallet_instance.dart';

class AddressData {
  // Load from Box called "wallet" at "main"
  static late WalletInstance wallet;
  // Load from Box called "state" at "guardians_metadata"
  static late List<WalletGuardian> guardians = [];
  // Load from Box called "state" at "recovery_request_id"
  static String? recoveryRequestId;
  // Load from Box called "state" at "address_data"
  static late WalletStatus walletStatus;
  static late WalletBalance walletBalance;
  static late List<ContactAddress> contacts = [];
  static List<CurrencyBalance> currencies = [];

  static loadExplorerJson(Map? json) async {
    json ??= Hive.box("state").get("address_data");
    if (json == null){
      walletStatus = WalletStatus(isDeployed: false, nonce: 0);
      walletBalance = WalletBalance(
        quoteCurrency: "UNI",
        currentBalance: BigInt.zero,
        previousBalance: BigInt.zero
      );
      currencies = [];
      contacts = [];
      return;
    }
    if (json["walletStatus"] != null){
      walletStatus = WalletStatus.fromJson(json["walletStatus"]);
    }
    //
    if (json["walletBalance"] != null){
      walletBalance = WalletBalance.fromJson(json["walletBalance"]);
    }

    //
    if (json["contacts"] != null){
      List<ContactAddress> _contacts = [];
      for (var contact in json["contacts"]){
        _contacts.add(ContactAddress.fromJson(contact));
      }
      contacts.clear();
      contacts = _contacts;
    }
    //
    if (json["currencies"] != null){
      List<CurrencyBalance> _currencies = [];
      for (var currency in json["currencies"]){
        _currencies.add(CurrencyBalance.fromJson(currency));
      }
      currencies.clear();
      currencies = _currencies;
    }
    //
  }

  static loadGuardians() async {
    if (wallet == null) return;
    var json = Hive.box("state").get("guardians_metadata");
    Map<String, List<dynamic>> metadata = {};
    //
    if (json != null){
      for (var guardianMetadata in json){
        metadata[guardianMetadata["address"].toString().toLowerCase()] = [guardianMetadata["type"], guardianMetadata["email"], guardianMetadata['creationDate'] != null ? DateFormat("dd/MM/yyy").parse(guardianMetadata['creationDate']) : null];
      }
    }
    //
    guardians.clear();
    var walletInterface = CWallet.customInterface(wallet.walletAddress);
    int guardiansCount = (await walletInterface.getGuardiansCount()).toInt();
    if (guardiansCount > 0){
      var _indexesList = List<int>.generate(guardiansCount, (i) => i);
      await Future.wait(
        _indexesList.map(
          (e) => walletInterface.getGuardian(BigInt.from(e))
          .then((value){
            var guardianMetadata = metadata.containsKey(value.hex.toLowerCase()) ? metadata[value.hex.toLowerCase()] : null;
            guardians.add(WalletGuardian(
              address: value.hex,
              type: guardianMetadata?[0] ?? "unknown",
              creationDate: guardianMetadata?[2],
              email: guardianMetadata?[1],
            ));
          })
        ),
      );
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

  static loadWallet(){
    var wallet = Hive.box("wallet").get("main");
    if (wallet != null){
      AddressData.wallet = WalletInstance.fromJson(jsonDecode(wallet));
    }
  }

  static updateExplorerJson(Map json) async {
    loadExplorerJson(json);
    //
    await Hive.box("state").put("address_data", json);
  }

  static loadLocally({bool walletOnly = false}){
    loadWallet();
    if (walletOnly) return;
    loadGuardians();
  }

  static BigInt getCurrencyBalance(String currencySymbol){
    CurrencyBalance? balance = currencies.firstWhereOrNull((element) => element.currency == currencySymbol);
    if (balance == null) return BigInt.zero;
    return balance.balance;
  }

}

class WalletStatus {
  bool isDeployed;
  int nonce;

  WalletStatus({required this.isDeployed, required this.nonce});

  WalletStatus.fromJson(Map json)
      : isDeployed = json['isDeployed'],
        nonce = json['nonce'];
}

class WalletBalance {
  String quoteCurrency;
  BigInt currentBalance;
  BigInt previousBalance;

  WalletBalance({required this.quoteCurrency,
    required this.currentBalance,
    required this.previousBalance});

  WalletBalance.fromJson(Map json)
      : quoteCurrency = json['quoteCurrency'],
        currentBalance = BigInt.parse(json['currentBalance']),
        previousBalance = BigInt.parse(json['previousBalance']);
}


class CurrencyBalance {
  String currency;
  String quoteCurrency;
  BigInt balance;
  BigInt currentBalanceInQuote;

  CurrencyBalance({required this.currency,
    required this.quoteCurrency,
    required this.balance,
    required this.currentBalanceInQuote});

  CurrencyBalance.fromJson(Map json)
      : currency = json['currency'],
        quoteCurrency = json['quoteCurrency'],
        balance = BigInt.parse(json['balance']),
        currentBalanceInQuote = BigInt.parse(json['currentBalanceInQuoteCurrency']);

  Map<String, dynamic> toJson() => {
    'currency': currency,
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
  String address;
  String type;
  String? email;
  DateTime? creationDate;

  WalletGuardian({required this.address,
    required this.type,
    this.email,
    this.creationDate});

  WalletGuardian.fromJson(Map json)
      : address = json['address'],
        type = json['type'],
        email = json['email'],
        creationDate = json['creationDate'] != null ? DateFormat("dd/MM/yyy").parse(json['creationDate']) : null;

  Map<String, dynamic> toJson() => {
    'address': address,
    'type': type,
    'email': email,
    'creationDate': creationDate != null ? DateFormat("dd/MM/yyy").format(creationDate!) : null,
  };
}