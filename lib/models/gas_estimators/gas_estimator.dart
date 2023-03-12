import 'package:candide_mobile_app/models/gas.dart';
import 'package:wallet_dart/wallet/user_operation.dart';

abstract class GasEstimator {
  int chainId;

  GasEstimator({required this.chainId});

  Future<List<int>?> getNetworkGasFees();
  Future<GasEstimate?> getGasEstimates(UserOperation userOp, {required bool includesPaymaster});
}