class GasEstimate {
  BigInt callGasLimit;
  BigInt preVerificationGas;
  BigInt verificationGasLimit;
  BigInt maxPriorityFeePerGas;
  BigInt maxFeePerGas;
  late BigInt l1GasUsed; //specific for L2s
  late BigInt l1BaseFee; //specific for L2s

  GasEstimate(
      {required this.callGasLimit,
      required this.preVerificationGas,
      required this.verificationGasLimit,
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
      preVerificationGas: preVerificationGas,
      verificationGasLimit: verificationGasLimit,
      maxPriorityFeePerGas: maxPriorityFeePerGas,
      maxFeePerGas: maxFeePerGas,
      l1GasUsed: l1GasUsed,
      l1BaseFee: l1BaseFee,
    );
  }
}
