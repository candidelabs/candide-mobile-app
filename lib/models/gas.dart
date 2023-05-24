class GasEstimate {
  BigInt callGasLimit;
  BigInt basePreVerificationGas;
  BigInt preVerificationGas;
  BigInt verificationGasLimit;
  BigInt maxPriorityFeePerGas;
  BigInt maxFeePerGas;
  late BigInt extraPreVerificationGas; //specific for L2s
  late BigInt l1GasUsed; //specific for L2s
  late BigInt l1BaseFee; //specific for L2s

  GasEstimate(
      {required this.callGasLimit, // set by bundler
      required this.basePreVerificationGas, // set by bundler
      required this.preVerificationGas, // calculated/adjusted for chain
      required this.verificationGasLimit, // set by bundler
      required this.maxPriorityFeePerGas,
      required this.maxFeePerGas,
      BigInt? l1GasUsed,
      BigInt? l1BaseFee}) {
    this.l1GasUsed = l1GasUsed ?? BigInt.zero;
    this.l1BaseFee = l1BaseFee ?? BigInt.zero;
  }

  GasEstimate copy() {
    return GasEstimate(
      callGasLimit: callGasLimit,
      basePreVerificationGas: basePreVerificationGas,
      preVerificationGas: preVerificationGas,
      verificationGasLimit: verificationGasLimit,
      maxPriorityFeePerGas: maxPriorityFeePerGas,
      maxFeePerGas: maxFeePerGas,
      l1GasUsed: l1GasUsed,
      l1BaseFee: l1BaseFee,
    );
  }
}
