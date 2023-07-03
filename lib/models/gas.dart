class GasEstimate {
  BigInt callGasLimit;
  BigInt basePreVerificationGas;
  BigInt preVerificationGas;
  BigInt verificationGasLimit;
  BigInt maxPriorityFeePerGas;
  BigInt maxFeePerGas;
  late BigInt l1Fee; //specific for L2s
  late BigInt l1FeeWithPaymaster; //specific for L2s

  GasEstimate(
      {required this.callGasLimit, // set by bundler
      required this.basePreVerificationGas, // set by bundler
      required this.preVerificationGas, // calculated/adjusted for chain
      required this.verificationGasLimit, // set by bundler
      required this.maxPriorityFeePerGas,
      required this.maxFeePerGas,
      BigInt? l1Fee,
      BigInt? l1FeeWithPaymaster}) {
    this.l1Fee = l1Fee ?? BigInt.zero;
    this.l1FeeWithPaymaster = l1FeeWithPaymaster ?? BigInt.zero;
  }

  GasEstimate copy() {
    return GasEstimate(
      callGasLimit: callGasLimit,
      basePreVerificationGas: basePreVerificationGas,
      preVerificationGas: preVerificationGas,
      verificationGasLimit: verificationGasLimit,
      maxPriorityFeePerGas: maxPriorityFeePerGas,
      maxFeePerGas: maxFeePerGas,
      l1Fee: l1Fee,
      l1FeeWithPaymaster: l1FeeWithPaymaster,
    );
  }
}
