class GasEstimate {
  int callGas;
  int preVerificationGas;
  int verificationGas;
  int maxPriorityFeePerGas;
  int maxFeePerGas;

  GasEstimate(
      {required this.callGas,
      required this.preVerificationGas,
      required this.verificationGas,
      required this.maxPriorityFeePerGas,
      required this.maxFeePerGas});
}