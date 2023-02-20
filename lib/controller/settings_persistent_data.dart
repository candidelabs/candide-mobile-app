import 'package:hive/hive.dart';

class SettingsData {
  static late String quoteCurrency;

  static loadFromJson(Map? json){
    json ??= Hive.box("settings").get("general");
    if (json == null){ // DEFAULT VALUES
      quoteCurrency = "USD";
      return;
    }
    quoteCurrency = json["quoteCurrency"];
  }
}