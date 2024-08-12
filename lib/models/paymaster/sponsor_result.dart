import 'package:candide_mobile_app/controller/wallet_connect/wc_peer_meta.dart';

class SponsorResult {
  String paymasterAndData;
  BigInt? callGasLimit;
  BigInt? verificationGasLimit;
  BigInt? preVerificationGas;
  BigInt? maxFeePerGas;
  BigInt? maxPriorityFeePerGas;
  WCPeerMeta? sponsorMetadata;

  SponsorResult({
    required this.paymasterAndData,
    this.callGasLimit,
    this.verificationGasLimit,
    this.preVerificationGas,
    this.maxFeePerGas,
    this.maxPriorityFeePerGas,
    this.sponsorMetadata,
  });
}