import 'package:dio/dio.dart';
import 'package:wallet_dart/utils/abi_utils.dart';
import 'package:web3dart/crypto.dart';

class TransactionDecoder {
  /// List of contract functions that has special client UI to better illustrate the functionality of the transaction
  static const Set<String> uiOrganizedFunctions = {
    "095ea7b3", // Approve
  };

  static Future<String?> _fetchData(String hexData) async {
    if (hexData.isEmpty || hexData == "0x") return null;
    hexData = hexData.replaceAll("0x", "");
    String functionSelector = hexData.substring(0, 8);
    try {
      var response = await Dio().get("https://raw.githubusercontent.com/ethereum-lists/4bytes/master/signatures/$functionSelector");
      if (response.statusCode == 404) return null;
      return response.data;
    } on DioError {
      return null;
    }
  }

  static Future<HexTransactionDetails?> decodeHexData(String hexData) async {
    String? data = await _fetchData(hexData);
    if (data == null) return null;
    data = data.split(";")[0];
    RegExp regExp = RegExp(r"^(.+)\((.+)?\)");
    var regExpMatches = regExp.allMatches(data);
    String? functionName = regExpMatches.first.group(1);
    if (functionName == null) return null;
    List<String> parameterTypes = regExpMatches.first.group(2)?.split(",") ?? [];
    List<dynamic> parameterValues = decodeAbi(parameterTypes, hexToBytes(hexData).sublist(4));
    //
    hexData = hexData.replaceAll("0x", "");
    String functionSelector = hexData.substring(0, 8);
    return HexTransactionDetails(
      selector: functionSelector,
      functionName: functionName,
      parameterTypes: parameterTypes,
      parameterValues: parameterValues
    );
  }
}

class HexTransactionDetails {
  String selector;
  String functionName;
  List<String> parameterTypes;
  List<dynamic> parameterValues;

  HexTransactionDetails({
    required this.selector,
    required this.functionName,
    required this.parameterTypes,
    required this.parameterValues
  });
}
