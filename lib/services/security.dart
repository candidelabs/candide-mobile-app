import 'dart:convert';

import 'package:candide_mobile_app/config/env.dart';
import 'package:candide_mobile_app/models/recovery_request.dart';
import 'package:dio/dio.dart';

class SecurityGateway {
  static int latestErrorCode = 200; // todo store error codes here

  static Future<RecoveryRequest?> create(String walletAddress, String socialRecoveryAddress, String dataHash, String oldOwner, String newOwner, String network) async {
    try{
      var response = await Dio().post("${Env.securityUri}/v1/guardian/create",
        data: jsonEncode({
          "walletAddress": walletAddress,
          "socialRecoveryAddress": socialRecoveryAddress,
          "dataHash": dataHash,
          "oldOwner": oldOwner,
          "newOwner": newOwner,
          "network": network
        }),
      );
      //
      RecoveryRequest recoveryRequest = RecoveryRequest(
        id: response.data["id"].toString(),
        emoji: response.data["emoji"],
        walletAddress: response.data["walletAddress"],
        socialRecoveryAddress: response.data["socialRecoveryAddress"],
        oldOwner: response.data["oldOwner"],
        newOwner: response.data["newOwner"],
        network: response.data["network"],
        signaturesAcquired: 0,
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

  static Future<RecoveryRequest?> fetchById(String id) async {
    try{
      var response = await Dio().get("${Env.securityUri}/v1/guardian/fetchById", queryParameters: {"id": id});
      //
      RecoveryRequest recoveryRequest = RecoveryRequest(
        id: response.data["id"].toString(),
        emoji: response.data["emoji"],
        walletAddress: response.data["walletAddress"],
        socialRecoveryAddress: response.data["socialRecoveryAddress"],
        oldOwner: response.data["oldOwner"],
        newOwner: response.data["newOwner"],
        network: response.data["network"],
        signaturesAcquired: response.data["signaturesAcquired"],
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