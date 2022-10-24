import 'package:wallet_dart/wallet/user_operation.dart';

class GasEstimate{
  String maxPriorityFeePerGas;
  String maxFeePerGas;

  GasEstimate({required this.maxPriorityFeePerGas, required this.maxFeePerGas});
}

class GasOverrides {
  int preVerificationGas;
  int verificationGas;
  int maxPriorityFeePerGas;
  int maxFeePerGas;

  GasOverrides(
      {required this.preVerificationGas,
      required this.verificationGas,
      required this.maxPriorityFeePerGas,
      required this.maxFeePerGas});

  static GasOverrides perform(GasEstimate gasEstimate) {
    var maxPriorityFeePerGas = BigInt.parse(
      gasEstimate.maxPriorityFeePerGas,
    ).toInt();
    var maxFeePerGas = BigInt.parse(
      gasEstimate.maxFeePerGas,
    ).toInt();
    return GasOverrides(
      preVerificationGas: 0,
      verificationGas: UserOperation.defaultGas * 3,
      maxPriorityFeePerGas: maxPriorityFeePerGas,
      maxFeePerGas: maxFeePerGas,
    );
  }
}