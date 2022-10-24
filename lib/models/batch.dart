import 'dart:typed_data';

import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/controller/settings_persistent_data.dart';
import 'package:candide_mobile_app/models/fee_currency.dart';
import 'package:candide_mobile_app/models/gas.dart';
import 'package:candide_mobile_app/models/gnosis_transaction.dart';
import 'package:candide_mobile_app/services/bundler.dart';
import 'package:candide_mobile_app/services/explorer.dart';
import 'package:candide_mobile_app/utils/constants.dart';
import 'package:get/get.dart';
import 'package:wallet_dart/wallet/user_operation.dart';
import 'package:wallet_dart/wallet/wallet_helpers.dart';
import 'package:wallet_dart/wallet/wallet_instance.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class Batch {
  BigInt baseGas = BigInt.zero;
  FeeCurrency? feeCurrency;
  EthereumAddress refundReceiver = Constants.addressZero;
  List<FeeCurrency> feeCurrencies = [];
  List<GnosisTransaction> transactions = [];

  GnosisTransaction? getById(String id){
    return transactions.firstWhereOrNull((e) => e.id == id);
  }

  String getFeeCurrency(){
    return CurrencyMetadata.findByAddress(feeCurrency?.currency.address ?? "0x")?.symbol ?? "ETH";
  }

  BigInt getFee(){
    return feeCurrency?.fee ?? BigInt.zero;
  }

  void configureNonces(int startNonce){
    int nonce = startNonce;
    nonce = nonce + transactions.length;
    for (GnosisTransaction transaction in transactions){
      transaction.nonce = BigInt.from(nonce);
      if (transaction.type == GnosisTransactionType.execTransaction){
        print("${transaction.id} gnosis nonce: ${transaction.nonce}");
        nonce++;
      }
    }
  }

  void signTransactions(Uint8List privateKey, WalletInstance instance){
    for (GnosisTransaction transaction in transactions){
      transaction.signWithPrivateKey(
        privateKey,
        instance.walletAddress,
        baseGas: baseGas,
        gasPrice: feeCurrency?.fee ?? BigInt.zero,
        gasToken: EthereumAddress.fromHex(feeCurrency?.currency.address ?? Constants.addressZero.hex),
        refundReceiver: refundReceiver
      );
    }
  }

  Future<List<UserOperation>> toUserOperations(WalletInstance instance, {bool proxyDeployed=true, bool managerDeployed=true}) async {
    List<UserOperation> userOps = [];
    //
    GasEstimate? gasEstimate = await Explorer.fetchGasEstimate(SettingsData.network); // todo network: handle fetching errors
    GasOverrides gasOverrides = GasOverrides.perform(gasEstimate!);
    //
    String initCode = "0x";
    String managerSalt = "0x";
    if (!proxyDeployed){
      initCode = bytesToHex(WalletHelpers.getInitCode(EthereumAddress.fromHex(instance.initOwner), instance.moduleManager), include0x: true);
    }
    if (!managerDeployed){
      managerSalt = bytesToHex(keccak256(Uint8List.fromList("${instance.salt}_moduleManager".codeUnits)), include0x: true);
    }
    //
    int nonce = transactions[0].nonce.toInt() - transactions.length;
    //
    for (GnosisTransaction transaction in transactions){
      print("${transaction.id} userOp nonce: $nonce");
      UserOperation userOp = UserOperation.get(
        sender: instance.walletAddress,
        initCode: initCode,
        callData: transaction.toCallData(baseGas: baseGas, gasPrice: feeCurrency?.fee ?? BigInt.zero, gasToken: EthereumAddress.fromHex(feeCurrency?.currency.address ?? Constants.addressZero.hex), refundReceiver: refundReceiver),
        nonce: nonce,
        callGas: 2150000,
        verificationGas: 645000,
        preVerificationGas: 21000,
        maxPriorityFeePerGas: gasOverrides.maxPriorityFeePerGas,
        maxFeePerGas: gasOverrides.maxFeePerGas,
        /*verificationGas: gasOverrides.verificationGas,
        preVerificationGas: gasOverrides.preVerificationGas,
        maxPriorityFeePerGas: gasOverrides.maxPriorityFeePerGas,
        maxFeePerGas: gasOverrides.maxFeePerGas,*/
        paymaster: EthereumAddress.fromHex("0xf54bA050c486B56EBF9786039D41D8130f560028"),
        managerSalt: managerSalt,
      );
      //
      String? paymasterData = await Bundler.getPaymasterSignature(userOp);
      if (paymasterData == null){ // todo network: handle fetching errors
        userOp.paymaster = EthereumAddress(Uint8List(EthereumAddress.addressByteLength));
        userOp.paymasterData = "0x";
      }else{
        userOp.paymasterData = paymasterData;
      }
      //
      userOps.add(userOp);
      nonce++;
      initCode = "0x";
      managerSalt = "0x";
    }
    //
    return userOps;
  }
}