import 'dart:convert';
import 'dart:typed_data';


import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/screens/home/swap/swap_sheet.dart';
import 'package:candide_mobile_app/services/bundler.dart';
import 'package:candide_mobile_app/services/explorer.dart';
import 'package:candide_mobile_app/controller/address_persistent_data.dart';
import 'package:candide_mobile_app/controller/settings_persistent_data.dart';
import 'package:candide_mobile_app/screens/home/components/balance_card.dart';
import 'package:candide_mobile_app/screens/home/components/currency_balance_card.dart';
import 'package:candide_mobile_app/screens/home/components/deposit_sheet.dart';
import 'package:candide_mobile_app/screens/home/components/network_bar.dart';
import 'package:candide_mobile_app/screens/home/send/send_sheet.dart';
import 'package:candide_mobile_app/utils/constants.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:wallet_dart/contracts/entrypoint.dart';
import 'package:wallet_dart/contracts/factories/EIP4337Manager.g.dart';
import 'package:wallet_dart/contracts/wallet.dart';
import 'package:wallet_dart/utils/encode.dart';
import 'package:wallet_dart/wallet/UserOperation.dart';
import 'package:wallet_dart/wallet/encode_function_data.dart';
import 'package:wallet_dart/wallet/wallet_helpers.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';


class OverviewScreen extends StatefulWidget {
  const OverviewScreen({Key? key}) : super(key: key);

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  final RefreshController _refreshController = RefreshController(initialRefresh: true);

  fetchOverview() async {
    await Explorer.fetchAddressOverview(
        network: SettingsData.network,
        address: AddressData.wallet.walletAddress.hex,
        quoteCurrency: "USDT",//SettingsData.quoteCurrency,
        currencyList: ["ETH", "UNI", "CTT"], // todo check here
    );
    if (!mounted) return;
    _refreshController.refreshCompleted();
    setState(() {});
  }
  
  @override
  void initState() {
    AddressData.loadExplorerJson(null);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SmartRefresher(
      physics: const BouncingScrollPhysics(),
      controller: _refreshController,
      header: MaterialClassicHeader(
        color: Get.theme.colorScheme.onPrimary,
      ),
      onRefresh: fetchOverview,
      enablePullDown: true,
      child: Column(
        children: [
          const SizedBox(height: 20,),
          Row(
            children: [
              const SizedBox(width: 10,),
              Text("Assets", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 25),),
              const Spacer(),
              NetworkBar(network: Networks.get(SettingsData.network)!),
              const SizedBox(width: 10,),
            ],
          ),
          const SizedBox(height: 20,),
          BalanceCard(
            onToggleVisibility: (val) async {
              print(jsonEncode(AddressData.wallet.toJson()));
              print(AddressData.walletStatus.proxyDeployed);
              print(AddressData.walletStatus.managerDeployed);
              print(AddressData.walletStatus.socialModuleDeployed);
              //printWrapped(bytesToHex(WalletHelpers.getInitCode(AddressData.wallet.walletAddress, AddressData.wallet.moduleManager), include0x: true));
              /*Uint8List managerSalt = keccak256(Uint8List.fromList("${AddressData.wallet.salt}_moduleManager".codeUnits));
              print(bytesToHex(managerSalt));
              BigInt saltInt = BigInt.parse(bytesToHex(managerSalt), radix: 16);
              print(saltInt.toString());
              print(saltInt.toRadixString(16));*/
              //var walletInterface = CWallet.customInterface(AddressData.wallet.walletAddress, client: Constants.client);
              //print((await walletInterface.getModulesPaginated(EthereumAddress.fromHex("0x0000000000000000000000000000000000000001"), BigInt.from(10))).array.map((e) => e.hexEip55));
              //var recoveryInterface = CWallet.recoveryInterface(AddressData.wallet.walletAddress, client: Constants.client);
              //print(await recoveryInterface.isFriend(EthereumAddress.fromHex("0xdbd510f9EBB7A81209FcCD12A56f6c6354AA8caB")));
              //print(bytesToHex(WalletHelpers.getInitCode(EthereumAddress.fromHex(AddressData.wallet.initOwner), AddressData.wallet.moduleManager)));
              //print(AddressData.currencies.map((e) => print("${e.currency} >> ${e.balance} >> ${e.currentBalanceInQuote}")));
              /*UserOperation op = UserOperation.get(
                sender: AddressData.wallet.walletAddress,
                initCode: "0x",
                callData: "0xaa",
                paymaster: AddressData.wallet.walletAddress,
                paymasterData: bytesToHex(keccak256(Uint8List.fromList("lol".codeUnits)), include0x: true),
                signature: "0x"
              );
              print(op.toList(hexRepresentation: true));
              print(jsonEncode(op.toJson()));*/
              /*var x = encodeAbi(["bytes"], [hexToBytes("0x00")]);
              print(bytesToHex(x));*/
              /*var requestIdRemote = await Bundler.getRequestId(op, SettingsData.network);
              var requestIdLocal = await op.requestId(CEntrypoint.address, BigInt.from(5));
              print(bytesToHex(requestIdRemote!, include0x: true));
              print(bytesToHex(requestIdLocal, include0x: true));*/
            },
            onPressDeposit: _refreshController.isLoading ? null : (){
              showBarModalBottomSheet(
                context: context,
                builder: (context) => SingleChildScrollView(
                  controller: ModalScrollController.of(context),
                  child: DepositSheet(address: AddressData.wallet.walletAddress.hexEip55),
                ),
              );
            },
            onPressSend: () async {
              var refresh = await showBarModalBottomSheet(
                context: context,
                builder: (context) {
                  Get.put<ScrollController>(ModalScrollController.of(context)!, tag: "send_modal");
                  return const SendSheet();
                },
              );
              if (refresh ?? false){
                _refreshController.requestRefresh();
              }
            },
            onPressSwap: () async {
              var refresh = await showBarModalBottomSheet(
                context: context,
                builder: (context) {
                  Get.put<ScrollController>(ModalScrollController.of(context)!, tag: "swap_modal");
                  return const SwapSheet();
                },
              );
              if (refresh ?? false){
                _refreshController.requestRefresh();
              }
            },
            balance: AddressData.walletBalance,
          ),
          const SizedBox(height: 10,),
          Container(
            alignment: Alignment.centerLeft,
            margin: const EdgeInsets.only(left: 10),
            child: Text("Currencies", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 25),)
          ),
          const SizedBox(height: 5,),
          for (CurrencyBalance currencyBalance in AddressData.currencies)
            CurrencyBalanceCard(currencyBalance: currencyBalance,),
        ],
      ),
    );
  }
}
