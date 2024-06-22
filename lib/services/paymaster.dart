import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:candide_mobile_app/controller/wallet_connect/wc_peer_meta.dart';
import 'package:candide_mobile_app/models/paymaster/fee_token.dart';
import 'package:candide_mobile_app/models/paymaster/paymaster_data.dart';
import 'package:candide_mobile_app/models/paymaster/paymaster_response.dart';
import 'package:candide_mobile_app/models/paymaster/sponsor_data.dart';
import 'package:candide_mobile_app/models/paymaster/sponsor_result.dart';
import 'package:candide_mobile_app/utils/constants.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:http/http.dart';
import 'package:wallet_dart/wallet/user_operation.dart';
import 'package:web3dart/json_rpc.dart';
import 'package:web3dart/web3dart.dart';

class Paymaster {

  JsonRPC? jsonRpc;

  Paymaster(String endpoint, Client client){
    if (endpoint.trim() == "-" || endpoint.trim().isEmpty) return;
    jsonRpc = JsonRPC(endpoint, client);
  }

  Future<PaymasterResponse> supportedERC20Tokens(TokenInfo nativeToken) async {
    List<FeeToken> result = [];
    result.add(FeeToken(
        token: nativeToken,
        fee: BigInt.zero,
        paymasterFee: BigInt.zero,
        exchangeRate: BigInt.parse("1000000000000000000")
    ));
    PaymasterResponse paymasterResponse = PaymasterResponse(
        tokens: result,
        paymasterData: PaymasterMetadata(
          address: Constants.addressZero,
          sponsoredEventTopic: "0x",
          dummyPaymasterAndData: "0x"
        ),
        sponsorData: SponsorData(
          sponsored: false,
          sponsorMeta: null,
        )
    );
    if (jsonRpc == null) return paymasterResponse;
    try{
      var response = await jsonRpc!.call(
          "pm_supportedERC20Tokens",
          []
      );
      //
      for (Map tokenData in response.result["tokens"]){
        TokenInfo? _token = TokenInfoStorage.getTokenByAddress(tokenData["address"]);
        if (_token == null) continue;
        result.add(
          FeeToken(
            token: _token,
            fee: BigInt.zero,
            paymasterFee: Utils.decodeBigInt(tokenData["fee"], defaultsToZero: true)!,
            exchangeRate: Utils.decodeBigInt(tokenData["exchangeRate"], defaultsToZero: true)!,
          )
        );
      }
      paymasterResponse.tokens = result;
      paymasterResponse.paymasterData.address = EthereumAddress.fromHex(response.result["paymasterMetadata"]["address"]);
      paymasterResponse.paymasterData.dummyPaymasterAndData = response.result["paymasterMetadata"]["dummyPaymasterAndData"];
      paymasterResponse.paymasterData.sponsoredEventTopic = response.result["paymasterMetadata"]["sponsoredEventTopic"];
      return paymasterResponse;
    } on RPCError catch(e){
      print("Error occurred (p_set, ${e.errorCode}, ${e.message})");
      return paymasterResponse;
    } on Exception catch(e){
      print("Error occurred p_set, $e");
      return paymasterResponse;
    }
  }

  Future<SponsorData?> checkSponsorshipEligibility(UserOperation userOperation, EthereumAddress entrypoint) async {
    if (jsonRpc == null) return null;
    try{
      var response = await jsonRpc!.call(
          "pm_checkSponsorshipEligibility",
          [
            userOperation.toJson(),
            entrypoint.hex
          ]
      );
      //
      SponsorData sponsorData = SponsorData(
        sponsored: response.result["sponsored"],
      );
      if (sponsorData.sponsored){
        sponsorData.sponsorMeta = WCPeerMeta.fromJson(response.result["sponsorMeta"]);
      }
      return sponsorData;
    } on RPCError catch(e){
      print("Error occurred (p_cse, ${e.errorCode}, ${e.message})");
      return null;
    } on Exception catch(e){
      print("Error occurred p_cse, $e");
      return null;
    }
  }

  Future<SponsorResult?> sponsorUserOperation(UserOperation userOperation, EthereumAddress entrypoint, FeeToken? feeToken) async{
    if (jsonRpc == null) return null;
    Map context = {};
    if (feeToken != null){
      context["token"] = feeToken.token.address;
    }
    try{
      var response = await jsonRpc!.call(
        "pm_sponsorUserOperation",
        [
          userOperation.toJson(),
          entrypoint.hex,
          context,
        ]
      );
      //
      SponsorResult sponsorResult = SponsorResult(
        paymasterAndData: response.result["paymasterAndData"],
        callGasLimit: Utils.decodeBigInt(response.result["callGasLimit"]),
        verificationGasLimit: Utils.decodeBigInt(response.result["verificationGasLimit"]),
        preVerificationGas: Utils.decodeBigInt(response.result["preVerificationGas"]),
        maxFeePerGas: Utils.decodeBigInt(response.result["maxFeePerGas"]),
        maxPriorityFeePerGas: Utils.decodeBigInt(response.result["maxPriorityFeePerGas"]),
      );
      return sponsorResult;
    } on RPCError catch(e){
      print("Error occurred (p_suo, ${e.errorCode}, ${e.message})");
      return null;
    } on Exception catch(e){
      print("Error occurred p_suo, $e");
      return null;
    }
  }

}