class SponsorResult {
  String paymasterAndData;
  BigInt? callGasLimit;
  BigInt? verificationGasLimit;
  BigInt? preVerificationGas;
  BigInt? maxFeePerGas;
  BigInt? maxPriorityFeePerGas;

  SponsorResult({
    required this.paymasterAndData,
    this.callGasLimit,
    this.verificationGasLimit,
    this.preVerificationGas,
    this.maxFeePerGas,
    this.maxPriorityFeePerGas
  });
}