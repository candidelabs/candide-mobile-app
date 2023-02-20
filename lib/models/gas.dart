class GasEstimate {
  int callGasLimit;
  int preVerificationGas;
  int verificationGasLimit;
  int maxPriorityFeePerGas;
  int maxFeePerGas;

  GasEstimate(
      {required this.callGasLimit,
      required this.preVerificationGas,
      required this.verificationGasLimit,
      required this.maxPriorityFeePerGas,
      required this.maxFeePerGas});
}