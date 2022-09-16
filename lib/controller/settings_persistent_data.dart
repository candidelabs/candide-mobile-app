import 'package:hive/hive.dart';

class SettingsData {
  static late String network;
  static late String quoteCurrency;
  static late String timePeriod;

  static loadFromJson(Map? json){
    json ??= Hive.box("settings").get("general");
    if (json == null){ // DEFAULT VALUES
      network = "Goerli";
      quoteCurrency = "UNI";
      timePeriod = "Month";
      return;
    }
    network = json["network"];
    quoteCurrency = json["quoteCurrency"];
    timePeriod = json["timePeriod"];
  }
}