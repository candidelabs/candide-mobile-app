import 'dart:convert';

import 'package:candide_mobile_app/config/env.dart';
import 'package:candide_mobile_app/models/recovery_request.dart';
import 'package:dio/dio.dart';

class SecurityGateway {
  static int latestErrorCode = 200; // todo store error codes here

  static Future<RecoveryRequest?> create(String accountAddress, String newOwner, String network) async {
    try{
      var response = await Dio().post("${Env.securityUri}/v1/guardian/create",
        data: jsonEncode({
          "accountAddress": accountAddress,
          "newOwner": newOwner,
          "network": network
        }),
      );
      //
      RecoveryRequest recoveryRequest = RecoveryRequest(
        id: response.data["id"].toString(),
        emoji: response.data["emoji"],
        accountAddress: response.data["accountAddress"],
        newOwner: response.data["newOwner"],
        network: response.data["network"],
        signatures: response.data["signatures"],
        status: response.data["status"],
        createdAt: DateTime.parse(response.data["createdAt"]),
      );
      //
      return recoveryRequest;
    } on DioError catch(e){
      latestErrorCode = e.response?.statusCode ?? 400;
      print("Error occured ${e.type.toString()}");
      return null;
    }
  }

  static Future<bool> finalize(String id) async {
    try{
      var response = await Dio().post("${Env.securityUri}/v1/guardian/finalize",
        data: jsonEncode({
          "id": id,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201){
        return true;
      }
      //
      return false;
    } on DioError catch(e){
      latestErrorCode = e.response?.statusCode ?? 400;
      print("Error occured ${e.type.toString()}");
      return false;
    }
  }

  static Future<RecoveryRequest?> fetchById(String id) async {
    try{
      var response = await Dio().get("${Env.securityUri}/v1/guardian/fetchById", queryParameters: {"id": id});
      //
      RecoveryRequest recoveryRequest = RecoveryRequest(
        id: response.data["id"].toString(),
        emoji: response.data["emoji"],
        accountAddress: response.data["accountAddress"],
        newOwner: response.data["newOwner"],
        network: response.data["network"],
        signatures: response.data["signatures"],
        status: response.data["status"],
        createdAt: DateTime.parse(response.data["createdAt"]),
      );
      //
      return recoveryRequest;
    } on DioError catch(e){
      latestErrorCode = e.response?.statusCode ?? 400;
      print("Error occured ${e.type.toString()}");
      return null;
    }
  }
}