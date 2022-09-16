import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/controller/address_persistent_data.dart';
import 'package:candide_mobile_app/controller/bundler.dart';
import 'package:candide_mobile_app/controller/explorer.dart';
import 'package:candide_mobile_app/controller/settings_persistent_data.dart';
import 'package:candide_mobile_app/models/gas.dart';
import 'package:candide_mobile_app/models/relay_response.dart';
import 'package:wallet_dart/contracts/wallet.dart';
import 'package:wallet_dart/wallet/UserOperation.dart';
import 'package:wallet_dart/wallet/encode_function_data.dart';
import 'package:wallet_dart/wallet/wallet_helpers.dart';
import 'package:wallet_dart/wallet/wallet_instance.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class GuardianHook {

  static Future<Map> buildRecoverOps({
    required EthereumAddress walletAddress,
    required String network,
    required String defaultCurrency,
    required String newOwner,
  }) async {
    int nonce = (await CWallet.customInterface(walletAddress).nonce()).toInt();
    //
    GasEstimate? gasEstimate;
    Map? paymasterStatus;
    await Future.wait([
      Bundler.fetchPaymasterStatus(walletAddress.hex, network).then((value) => paymasterStatus = value),
      Explorer.fetchGasEstimate(network).then((value) => gasEstimate = value),
    ]);
    //
    GasOverrides gasOverrides = GasOverrides.perform(gasEstimate!);
    //
    BigInt feeValue = BigInt.parse(paymasterStatus?["fees"][defaultCurrency] ?? '0');
    BigInt allowance = BigInt.parse(paymasterStatus?["allowances"][defaultCurrency] ?? '0');
    bool shouldApprovePaymaster = allowance < feeValue;
    //
    var approvePaymasterOp = shouldApprovePaymaster ? UserOperation.get(
        sender: walletAddress,
        nonce: nonce,
        verificationGas: gasOverrides.verificationGas,
        preVerificationGas: gasOverrides.preVerificationGas,
        maxPriorityFeePerGas: gasOverrides.maxPriorityFeePerGas,
        maxFeePerGas: gasOverrides.maxFeePerGas,
        callData: EncodeFunctionData.erc20Approve(
          EthereumAddress.fromHex(CurrencyMetadata.metadata[defaultCurrency]!.address),
          EthereumAddress.fromHex(paymasterStatus?["address"]),
          feeValue
        )
    ) : null;
    //
    var grantOp = UserOperation.get(
      sender: walletAddress,
      nonce: nonce + (shouldApprovePaymaster ? 1 : 0),
      verificationGas: gasOverrides.verificationGas,
      preVerificationGas: gasOverrides.preVerificationGas,
      maxPriorityFeePerGas: gasOverrides.maxPriorityFeePerGas,
      maxFeePerGas: gasOverrides.maxFeePerGas,
      callData: EncodeFunctionData.transferOwner(EthereumAddress.fromHex(newOwner))
    );
    //
    List<UserOperation> userOperations = [];
    if (approvePaymasterOp != null){
      userOperations.add(approvePaymasterOp);
    }
    userOperations.add(grantOp);
    return {
      "userOperations": userOperations,
      "fee": {"currency": defaultCurrency, "value": feeValue}
    };
  }

  static Future<Map> buildGrantOps({
    required WalletInstance instance,
    required String network,
    required bool isDeployed,
    required int nonce,
    required String defaultCurrency,
    //
    required String guardianAddress,
  }) async {
    GasEstimate? gasEstimate;
    Map? paymasterStatus;
    await Future.wait([
      Bundler.fetchPaymasterStatus(instance.walletAddress.hex, network).then((value) => paymasterStatus = value),
      Explorer.fetchGasEstimate(network).then((value) => gasEstimate = value),
    ]);
    //
    GasOverrides gasOverrides = GasOverrides.perform(gasEstimate!);
    //
    BigInt feeValue = BigInt.parse(paymasterStatus?["fees"][defaultCurrency] ?? '0');
    BigInt allowance = BigInt.parse(paymasterStatus?["allowances"][defaultCurrency] ?? '0');
    bool shouldApprovePaymaster = allowance < feeValue;
    //
    var approvePaymasterOp = shouldApprovePaymaster ? UserOperation.get(
        sender: instance.walletAddress,
        nonce: nonce,
        verificationGas: gasOverrides.verificationGas,
        preVerificationGas: gasOverrides.preVerificationGas,
        maxPriorityFeePerGas: gasOverrides.maxPriorityFeePerGas,
        maxFeePerGas: gasOverrides.maxFeePerGas,
        initCode: isDeployed ? UserOperation.nullCode : bytesToHex(WalletHelpers.getInitCode(EthereumAddress.fromHex(instance.initOwner), []), include0x: true),
        callData: EncodeFunctionData.erc20Approve(
            EthereumAddress.fromHex(CurrencyMetadata.metadata[defaultCurrency]!.address),
            EthereumAddress.fromHex(paymasterStatus?["address"]),
            feeValue
        )
    ) : null;
    //
    var grantOp = UserOperation.get(
      sender: instance.walletAddress,
      nonce: nonce + (shouldApprovePaymaster ? 1 : 0),
      verificationGas: gasOverrides.verificationGas,
      preVerificationGas: gasOverrides.preVerificationGas,
      maxPriorityFeePerGas: gasOverrides.maxPriorityFeePerGas,
      maxFeePerGas: gasOverrides.maxFeePerGas,
      callData: EncodeFunctionData.grantGuardian(EthereumAddress.fromHex(guardianAddress))
    );
    //
    List<UserOperation> userOperations = [];
    if (approvePaymasterOp != null){
      userOperations.add(approvePaymasterOp);
    }
    userOperations.add(grantOp);
    return {
      "userOperations": userOperations,
      "fee": {"currency": defaultCurrency, "value": feeValue}
    };
  }

  static Future<Map> buildRevokeOps({
    required WalletInstance instance,
    required String network,
    required bool isDeployed,
    required int nonce,
    required String defaultCurrency,
    //
    required String guardianAddress,
  }) async {
    GasEstimate? gasEstimate;
    Map? paymasterStatus;
    await Future.wait([
      Bundler.fetchPaymasterStatus(instance.walletAddress.hex, network).then((value) => paymasterStatus = value),
      Explorer.fetchGasEstimate(network).then((value) => gasEstimate = value),
    ]);
    //
    GasOverrides gasOverrides = GasOverrides.perform(gasEstimate!);
    //
    BigInt feeValue = BigInt.parse(paymasterStatus?["fees"][defaultCurrency] ?? '0');
    BigInt allowance = BigInt.parse(paymasterStatus?["allowances"][defaultCurrency] ?? '0');
    bool shouldApprovePaymaster = allowance < feeValue;
    //
    var approvePaymasterOp = shouldApprovePaymaster ? UserOperation.get(
        sender: instance.walletAddress,
        nonce: nonce,
        verificationGas: gasOverrides.verificationGas,
        preVerificationGas: gasOverrides.preVerificationGas,
        maxPriorityFeePerGas: gasOverrides.maxPriorityFeePerGas,
        maxFeePerGas: gasOverrides.maxFeePerGas,
        initCode: isDeployed ? UserOperation.nullCode : bytesToHex(WalletHelpers.getInitCode(EthereumAddress.fromHex(instance.initOwner), []), include0x: true),
        callData: EncodeFunctionData.erc20Approve(
            EthereumAddress.fromHex(CurrencyMetadata.metadata[defaultCurrency]!.address),
            EthereumAddress.fromHex(paymasterStatus?["address"]),
            feeValue
        )
    ) : null;
    //
    var revokeOp = UserOperation.get(
        sender: instance.walletAddress,
        nonce: nonce + (shouldApprovePaymaster ? 1 : 0),
        verificationGas: gasOverrides.verificationGas,
        preVerificationGas: gasOverrides.preVerificationGas,
        maxPriorityFeePerGas: gasOverrides.maxPriorityFeePerGas,
        maxFeePerGas: gasOverrides.maxFeePerGas,
        callData: EncodeFunctionData.revokeGuardian(EthereumAddress.fromHex(guardianAddress))
    );
    //
    List<UserOperation> userOperations = [];
    if (approvePaymasterOp != null){
      userOperations.add(approvePaymasterOp);
    }
    userOperations.add(revokeOp);
    return {
      "userOperations": userOperations,
      "fee": {"currency": defaultCurrency, "value": feeValue}
    };
  }


  static tryAddingGuardian(String address) async {
    print("H0");
    Map data = await buildGrantOps(
      instance: AddressData.wallet,
      network: SettingsData.network,
      isDeployed: AddressData.walletStatus.isDeployed,
      nonce: AddressData.walletStatus.nonce,
      defaultCurrency: SettingsData.quoteCurrency,
      guardianAddress: address,
    );
    List<UserOperation> userOperations = data["userOperations"];
    print("H1");
    List<UserOperation>? unsignedUserOperations = await Bundler.requestPaymasterSignature(
      userOperations,
      SettingsData.network,
    );
    print("H2");
    var signedUserOperations = await Bundler.signUserOperations(
      AddressData.wallet,
      "0025Gg!",
      SettingsData.network,
      unsignedUserOperations!,
    );
    print("H3");
    RelayResponse? response = await Bundler.relayUserOperations(signedUserOperations!, SettingsData.network);
    print("H4");
    print(response?.status);
  }

  static tryRevokingGuardian(String address) async {
    print("H0");
    Map data = await buildRevokeOps(
      instance: AddressData.wallet,
      network: SettingsData.network,
      isDeployed: AddressData.walletStatus.isDeployed,
      nonce: AddressData.walletStatus.nonce,
      defaultCurrency: SettingsData.quoteCurrency,
      guardianAddress: address,
    );
    List<UserOperation> userOperations = data["userOperations"];
    print("H1");
    List<UserOperation>? unsignedUserOperations = await Bundler.requestPaymasterSignature(
      userOperations,
      SettingsData.network,
    );
    print("H2");
    var signedUserOperations = await Bundler.signUserOperations(
      AddressData.wallet,
      "0025Gg!",
      SettingsData.network,
      unsignedUserOperations!,
    );
    print("H3");
    RelayResponse? response = await Bundler.relayUserOperations(signedUserOperations!, SettingsData.network);
    if (response == null){
    }
    print("H4");
    print(response?.status);
  }
}