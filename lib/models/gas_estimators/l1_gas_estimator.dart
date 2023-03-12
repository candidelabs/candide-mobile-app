import 'package:candide_mobile_app/models/gas.dart';
import 'package:candide_mobile_app/models/gas_estimators/gas_estimator.dart';
import 'package:candide_mobile_app/services/bundler.dart';
import 'package:dio/dio.dart';
import 'package:wallet_dart/wallet/user_operation.dart';
import 'package:web3dart/web3dart.dart';

class L1GasEstimator extends GasEstimator {

  L1GasEstimator({required super.chainId});

  @override
  Future<List<int>?> getNetworkGasFees() async {
    try{
      var response = await Dio().get("https://gas-api.metaswap.codefi.network/networks/$chainId/suggestedGasFees");
      //
      int suggestedMaxFeePerGas = (double.parse(response.data["medium"]["suggestedMaxFeePerGas"]) * 1000).ceil();
      int suggestedMaxPriorityFeePerGas = (double.parse(response.data["medium"]["suggestedMaxPriorityFeePerGas"]) * 1000).ceil();
      suggestedMaxFeePerGas = EtherAmount.fromUnitAndValue(EtherUnit.mwei, suggestedMaxFeePerGas).getInWei.toInt();
      suggestedMaxPriorityFeePerGas = EtherAmount.fromUnitAndValue(EtherUnit.mwei, suggestedMaxPriorityFeePerGas).getInWei.toInt();
      //
      return [suggestedMaxFeePerGas, suggestedMaxPriorityFeePerGas];
    } on DioError catch(e){
      print("Error occurred ${e.type.toString()}");
      return null;
    }
  }

  @override
  Future<GasEstimate?> getGasEstimates(UserOperation userOp, {required bool includesPaymaster}) async {
    List<int> networkFees = await getNetworkGasFees() ?? [0, 0];
    GasEstimate? gasEstimate = await Bundler.getUserOperationGasEstimates(userOp, chainId);
    if (gasEstimate == null) return null;
    gasEstimate.maxFeePerGas = networkFees[0];
    gasEstimate.maxPriorityFeePerGas = networkFees[1];
    return gasEstimate;
  }
}