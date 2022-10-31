import 'dart:typed_data';

import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/controller/address_persistent_data.dart';
import 'package:candide_mobile_app/controller/settings_persistent_data.dart';
import 'package:candide_mobile_app/models/fee_currency.dart';
import 'package:candide_mobile_app/models/gas.dart';
import 'package:candide_mobile_app/models/gnosis_transaction.dart';
import 'package:candide_mobile_app/services/bundler.dart';
import 'package:candide_mobile_app/utils/constants.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:wallet_dart/wallet/encode_function_data.dart';
import 'package:wallet_dart/wallet/user_operation.dart';
import 'package:wallet_dart/wallet/wallet_helpers.dart';
import 'package:wallet_dart/wallet/wallet_instance.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class Batch {
  static final EthereumAddress _paymasterAddress = EthereumAddress.fromHex("0x83DAc8e36D8FDeCF69CD78f9f86f25664EEE72f4");
  BigInt baseGas = BigInt.zero;
  FeeCurrency? _feeCurrency;
  EthereumAddress refundReceiver = Constants.addressZero;
  List<FeeCurrency> _feeCurrencies = [];
  List<GnosisTransaction> transactions = [];

  bool get includesPaymaster => _feeCurrency?.currency.symbol != Networks.get(SettingsData.network)!.nativeCurrency;
  FeeCurrency? get feeCurrency => _feeCurrency;
  List<FeeCurrency> get feeCurrencies => _feeCurrencies;

  GnosisTransaction? getById(String id){
    return transactions.firstWhereOrNull((e) => e.id == id);
  }

  Future<void> changeFeeCurrency(FeeCurrency? feeCurrency) async {
    _feeCurrency = feeCurrency;
    if (transactions[0].id == "paymaster-allowance"){
      transactions.removeAt(0);
    }
    if (feeCurrency == null) return;
    if (includesPaymaster){
      GnosisTransaction approveTransaction = GnosisTransaction(
        id: "paymaster-allowance",
        to: EthereumAddress.fromHex(feeCurrency.currency.address),
        value: BigInt.zero,
        data: hexToBytes(EncodeFunctionData.erc20Approve(
          _paymasterAddress,
          feeCurrency.fee,
        )),
        type: GnosisTransactionType.execTransactionFromModule,
      );
      transactions.insert(0, approveTransaction);
    }
  }

  Future<void> changeFeeCurrencies(List<FeeCurrency> feeCurrencies) async {
    _feeCurrencies = feeCurrencies;
    await _adjustFeeCurrencyCosts();
  }

  Future<void> _adjustFeeCurrencyCosts() async{
    configureNonces(AddressData.walletStatus.nonce);
    List<UserOperation> userOps = await toUserOperations(AddressData.wallet, proxyDeployed: AddressData.walletStatus.proxyDeployed, skipPaymasterData: true);
    BigInt fee = FeeCurrencyUtils.calculateFee(userOps);
    BigInt etherFee = FeeCurrencyUtils.calculateEtherFee(userOps);
    for (FeeCurrency feeCurrency in _feeCurrencies){
      if (feeCurrency.currency.symbol == Networks.get(SettingsData.network)!.nativeCurrency){
        feeCurrency.fee = etherFee;
      }else{
        feeCurrency.fee = fee;
      }
    }
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
    if (includesPaymaster){
      nonce++;
    }
    for (GnosisTransaction transaction in transactions){
      transaction.nonce = BigInt.from(nonce);
      if (transaction.type == GnosisTransactionType.execTransaction){
        nonce++;
      }
    }
  }

  void signTransactions(Uint8List privateKey, WalletInstance instance){
    for (GnosisTransaction transaction in transactions){
      if (transaction.type != GnosisTransactionType.execTransaction) continue;
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

  Future<void> _addPaymasterToUserOps(List<UserOperation> userOps) async {
    for (UserOperation op in userOps){
      op.paymaster = _paymasterAddress;
    }
    List<String>? paymasterData = await Bundler.getPaymasterSignature(userOps, feeCurrency!.currency.address);
    if (paymasterData == null){ // todo network: handle fetching errors
      for (UserOperation op in userOps){
        op.paymaster = EthereumAddress(Uint8List(EthereumAddress.addressByteLength));
        op.paymasterData = "0x";
      }
    }else{
      int index = 0;
      for (UserOperation op in userOps){
        op.paymasterData = paymasterData[index];
        index++;
      }
    }
  }

  Future<List<UserOperation>> toUserOperations(WalletInstance instance, {bool proxyDeployed=true, bool managerDeployed=true, bool skipPaymasterData=false}) async {
    List<UserOperation> userOps = [];
    //
    String initCode = "0x";
    String managerSalt = "0x";
    if (!proxyDeployed){
      initCode = bytesToHex(WalletHelpers.getInitCode(EthereumAddress.fromHex(instance.initOwner), instance.moduleManager), include0x: true);
    }
    if (!managerDeployed){
      managerSalt = bytesToHex(keccak256(Uint8List.fromList("${instance.salt}_moduleManager".codeUnits)), include0x: true);
      print(managerSalt);
    }
    //
    int nonce = transactions[0].nonce.toInt() - transactions.length;
    if (includesPaymaster){
      nonce--;
    }
    //
    for (GnosisTransaction transaction in transactions){
      UserOperation userOp = UserOperation.get(
        sender: instance.walletAddress,
        initCode: initCode,
        callData: transaction.toCallData(baseGas: baseGas, gasPrice: feeCurrency?.fee ?? BigInt.zero, gasToken: EthereumAddress.fromHex(feeCurrency?.currency.address ?? Constants.addressZero.hex), refundReceiver: refundReceiver),
        nonce: nonce,
        moduleManagerSalt: managerSalt,
      );
      //
      userOps.add(userOp);
      nonce++;
      if (initCode != "0x"){
        nonce = 0;
      }
      initCode = "0x";
      managerSalt = "0x";
    }
    //List<GasEstimate>? gasEstimates = await Bundler.getOperationsGasFees(userOps);
    List<GasEstimate>? gasEstimates = await BatchUtils.getGasEstimates(userOps, Networks.get(SettingsData.network)!.chainId.toInt());
    int index = 0;
    for (UserOperation op in userOps) {
      op.callGas = gasEstimates[index].callGas;
      op.preVerificationGas = gasEstimates[index].preVerificationGas;
      op.verificationGas = gasEstimates[index].verificationGas;
      op.maxFeePerGas = gasEstimates[index].maxFeePerGas;
      op.maxPriorityFeePerGas = gasEstimates[index].maxPriorityFeePerGas;
      index++;
    }
    if (includesPaymaster && !skipPaymasterData){
      await _addPaymasterToUserOps(userOps);
    }
    //
    return userOps;
  }
}

class BatchUtils {

  static Future<List<int>?> getNetworkGasFees(int chainId) async {
    try{
      var response = await Dio().get("https://gas-api.metaswap.codefi.network/networks/$chainId/suggestedGasFees");
      //
      int suggestedMaxFeePerGas = (double.parse(response.data["medium"]["suggestedMaxFeePerGas"]) * 1000).ceil();
      int suggestedMaxPriorityFeePerGas = (double.parse(response.data["medium"]["suggestedMaxPriorityFeePerGas"]) * 1000).ceil();
      suggestedMaxFeePerGas = EtherAmount.fromUnitAndValue(EtherUnit.mwei, suggestedMaxFeePerGas).getInWei.toInt();
      suggestedMaxPriorityFeePerGas = EtherAmount.fromUnitAndValue(EtherUnit.mwei, suggestedMaxPriorityFeePerGas).getInWei.toInt();
      //
      return [suggestedMaxFeePerGas, suggestedMaxPriorityFeePerGas];
    } on DioError catch(e){
      print("Error occured ${e.type.toString()}");
      return null;
    }
  }

  static Future<List<GasEstimate>> getGasEstimates(List<UserOperation> userOps, int chainId) async {
    List<GasEstimate> results = [];
    List<int> networkFees = await getNetworkGasFees(chainId) ?? [0, 0];
    for (UserOperation op in userOps){
      int preVerificationGas = op.pack().length * 5 + 18000;
      GasEstimate gasEstimate = GasEstimate(callGas: 2150000, preVerificationGas: preVerificationGas, verificationGas: 645000, maxFeePerGas: networkFees[0], maxPriorityFeePerGas: networkFees[1]);
      results.add(gasEstimate);
    }
    return results;
  }

}