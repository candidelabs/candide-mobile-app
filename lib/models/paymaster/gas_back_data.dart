import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/models/paymaster/source/paymaster_contract.g.dart';
import 'package:candide_mobile_app/utils/constants.dart';
import 'package:wallet_dart/wallet/account.dart';
import 'package:web3dart/credentials.dart';

class GasBackData {
  EthereumAddress paymaster;
  String paymasterAndData;
  bool gasBackApplied;

  GasBackData({required this.paymaster, required this.paymasterAndData, required this.gasBackApplied});

  static Future<GasBackData> getGasBackData(Account account, EthereumAddress _paymaster, Network network, BigInt maxETHCost) async {
    if (_paymaster == Constants.addressZero) return GasBackData(paymaster: _paymaster, paymasterAndData: "0x", gasBackApplied: false);
    PaymasterContract paymasterContract = PaymasterContract(address: _paymaster, client: network.client);
    BigInt accountGasBack = await paymasterContract.gasBackBalances(account.address);
    bool gasBackApplied = accountGasBack >= maxETHCost;
    String paymasterAndData = "0x";
    if (gasBackApplied){
      paymasterAndData += _paymaster.hexNo0x;
      paymasterAndData += Constants.addressZero.hexNo0x; // no token
      paymasterAndData += BigInt.from(2).toRadixString(16).padLeft(2,  '0'); // paymaster mode = 2 (GAS_BACK)
      paymasterAndData += BigInt.from(0).toRadixString(16).padLeft(12, '0'); // validUntil = 0 (48 bits = 6 bytes = 12 hex chars)
      paymasterAndData += BigInt.from(0).toRadixString(16).padLeft(64, '0'); // fee = 0 (256 bits = 32 bytes = 64 hex chars)
      paymasterAndData += BigInt.from(0).toRadixString(16).padLeft(64, '0'); // exchangeRate = 0
    }
    return GasBackData(
      paymaster: _paymaster,
      paymasterAndData: paymasterAndData,
      gasBackApplied: gasBackApplied,
    );
  }

}