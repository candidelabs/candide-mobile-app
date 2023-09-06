class GasEstimate {
  BigInt callGasLimit;
  BigInt preVerificationGas;
  BigInt verificationGasLimit;
  BigInt maxPriorityFeePerGas;
  BigInt maxFeePerGas;

  GasEstimate(
      {required this.callGasLimit, // set by bundler
      required this.preVerificationGas, // calculated/adjusted for chain
      required this.verificationGasLimit, // set by bundler
      required this.maxPriorityFeePerGas,
      required this.maxFeePerGas});

  GasEstimate copy() {
    return GasEstimate(
      callGasLimit: callGasLimit,
      preVerificationGas: preVerificationGas,
      verificationGasLimit: verificationGasLimit,
      maxPriorityFeePerGas: maxPriorityFeePerGas,
      maxFeePerGas: maxFeePerGas,
    );
  }
}
