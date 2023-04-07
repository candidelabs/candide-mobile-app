class GasEstimate {
  BigInt callGasLimit;
  BigInt preVerificationGas;
  BigInt verificationGasLimit;
  BigInt maxPriorityFeePerGas;
  BigInt maxFeePerGas;

  GasEstimate(
      {required this.callGasLimit,
      required this.preVerificationGas,
      required this.verificationGasLimit,
      required this.maxPriorityFeePerGas,
      required this.maxFeePerGas});
}