import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:version/version.dart';

class BoxController {
  Map<String, Version> boxVersions = {};
  late HiveAesCipher hiveAesCipher;

  static BoxController? _instance;

  BoxController();

  Future<void> _initialize() async {
    const secureStorage = FlutterSecureStorage();
    final encryptionKeyString = await secureStorage.read(key: 'hive_key');
    if (encryptionKeyString == null) {
      final key = Hive.generateSecureKey();
      await secureStorage.write(
        key: 'hive_key',
        value: base64UrlEncode(key),
      );
    }
    final hiveKey = await secureStorage.read(key: 'hive_key');
    final encryptionKeyUint8List = base64Url.decode(hiveKey!);
    hiveAesCipher = HiveAesCipher(encryptionKeyUint8List);
  }

  static Future<BoxController> instance() async {
    if (_instance == null){
      _instance = BoxController();
      await _instance!._initialize();
      await _instance!._loadBoxesVersions();
      return _instance!;
    }
    return _instance!;
  }

  Future<void> _loadBoxesVersions() async {
    await Hive.openBox("boxes_configs");
    List<String> boxesNames = ["signers", "wallet", "settings", "state", "activity", "wallet_connect", "tokens_storage"];
    for (String boxName in boxesNames){
      String boxVersionRaw = Hive.box("boxes_configs").get("${boxName}_version", defaultValue: "0.0.0");
      boxVersions[boxName] = Version.parse(boxVersionRaw);
    }
  }

  Future<void> _saveBoxVersion(String boxName, String version) async {
    await Hive.box("boxes_configs").put("${boxName}_version", version);
    boxVersions[boxName] = Version.parse(version);
  }

  Future<void> openBox(String boxName) async {
    if (boxName == "signers"){
      await _loadSignersBox();
    }else if(boxName == "wallet"){
      await _loadWalletBox();
    }else if(boxName == "settings"){
      await _loadSettingsBox();
    }else if(boxName == "state"){
      await _loadStateBox();
    }else if(boxName == "activity"){
      await _loadActivityBox();
    }else if(boxName == "wallet_connect"){
      await _loadWalletConnectBox();
    }else if(boxName == "tokens_storage"){
      await _loadTokenStorageBox();
    }

  }

  Future<void> _loadSignersBox() async {
    String boxName = "signers";
    Version latestBoxVersion = Version.parse("0.0.1");
    bool boxExists = await Hive.boxExists(boxName);
    bool abort = false;
    if (boxExists && boxVersions[boxName]! < latestBoxVersion){
      if (boxVersions[boxName]! < Version.parse("0.0.1")){
        await _BoxVersionMigrationHelper.migrateCipher(boxName, hiveAesCipher);
        abort = true;
      }
    }
    await _saveBoxVersion(boxName, latestBoxVersion.toString());
    if (abort){
      return;
    }
    await Hive.openBox(boxName, encryptionCipher: hiveAesCipher);
  }

  Future<void> _loadWalletBox() async {
    String boxName = "wallet";
    Version latestBoxVersion = Version.parse("0.0.1");
    bool boxExists = await Hive.boxExists(boxName);
    bool abort = false;
    if (boxExists && boxVersions[boxName]! < latestBoxVersion){
      if (boxVersions[boxName]! < Version.parse("0.0.1")){
        await _BoxVersionMigrationHelper.migrateCipher(boxName, hiveAesCipher);
        abort = true;
      }
    }
    await _saveBoxVersion(boxName, latestBoxVersion.toString());
    if (abort){
      return;
    }
    await Hive.openBox(boxName, encryptionCipher: hiveAesCipher);
  }

  Future<void> _loadSettingsBox() async {
    String boxName = "settings";
    Version latestBoxVersion = Version.parse("0.0.0");
    bool boxExists = await Hive.boxExists(boxName);
    bool abort = false;
    if (boxExists && boxVersions[boxName]! < latestBoxVersion){}
    await _saveBoxVersion(boxName, latestBoxVersion.toString());
    if (abort){
      return;
    }
    await Hive.openBox(boxName);
  }

  Future<void> _loadStateBox() async {
    String boxName = "state";
    Version latestBoxVersion = Version.parse("0.0.0");
    bool boxExists = await Hive.boxExists(boxName);
    bool abort = false;
    if (boxExists && boxVersions[boxName]! < latestBoxVersion){}
    await _saveBoxVersion(boxName, latestBoxVersion.toString());
    if (abort){
      return;
    }
    await Hive.openBox(boxName);
  }

  Future<void> _loadActivityBox() async {
    String boxName = "activity";
    Version latestBoxVersion = Version.parse("0.0.0");
    bool boxExists = await Hive.boxExists(boxName);
    bool abort = false;
    if (boxExists && boxVersions[boxName]! < latestBoxVersion){}
    await _saveBoxVersion(boxName, latestBoxVersion.toString());
    if (abort){
      return;
    }
    await Hive.openBox(boxName);
  }

  Future<void> _loadWalletConnectBox() async {
    String boxName = "wallet_connect";
    Version latestBoxVersion = Version.parse("0.0.1");
    bool boxExists = await Hive.boxExists(boxName);
    bool abort = false;
    if (boxExists && boxVersions[boxName]! < latestBoxVersion){
      if (boxVersions[boxName]! < Version.parse("0.0.1")){
        await _BoxVersionMigrationHelper.migrateCipher(boxName, hiveAesCipher);
        abort = true;
      }
    }
    await _saveBoxVersion(boxName, latestBoxVersion.toString());
    if (abort){
      return;
    }
    await Hive.openBox(boxName, encryptionCipher: hiveAesCipher);
  }

  Future<void> _loadTokenStorageBox() async {
    String boxName = "tokens_storage";
    Version latestBoxVersion = Version.parse("0.0.0");
    bool boxExists = await Hive.boxExists(boxName);
    bool abort = false;
    if (boxExists && boxVersions[boxName]! < latestBoxVersion){}
    await _saveBoxVersion(boxName, latestBoxVersion.toString());
    if (abort){
      return;
    }
    await Hive.openBox(boxName);
  }

}

class _BoxVersionMigrationHelper {

  static Future<void> migrateCipher(String boxName, HiveAesCipher hiveAesCipher) async {
    await Hive.openBox(boxName);
    var data = Hive.box(boxName).toMap();
    //
    await Hive.box(boxName).clear();
    await Hive.box(boxName).deleteFromDisk();
    //
    await Hive.openBox(boxName, encryptionCipher: hiveAesCipher);
    await Hive.box(boxName).putAll(data);
  }

}