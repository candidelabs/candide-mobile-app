import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/screens/home/swap/swap_sheet.dart';
import 'package:candide_mobile_app/services/explorer.dart';
import 'package:candide_mobile_app/controller/address_persistent_data.dart';
import 'package:candide_mobile_app/controller/settings_persistent_data.dart';
import 'package:candide_mobile_app/screens/home/components/balance_card.dart';
import 'package:candide_mobile_app/screens/home/components/currency_balance_card.dart';
import 'package:candide_mobile_app/screens/home/components/deposit_sheet.dart';
import 'package:candide_mobile_app/screens/home/components/network_bar.dart';
import 'package:candide_mobile_app/screens/home/send/send_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';


class OverviewScreen extends StatefulWidget {
  const OverviewScreen({Key? key}) : super(key: key);

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  final RefreshController _refreshController = RefreshController(initialRefresh: true);
  bool balancesVisible = true;

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
            balanceVisible: balancesVisible,
            onPressVisibilityIcon: () {
              /*print(jsonEncode(AddressData.wallet.toJson()));
              //var x = await Constants.ens.withAddress(EthereumAddress.fromHex("0xdbd510f9EBB7A81209FcCD12A56f6c6354AA8caB")).getName();
              print(AddressData.walletStatus.proxyDeployed);
              print(AddressData.walletStatus.managerDeployed);
              print(AddressData.walletStatus.socialModuleDeployed);
              print(bytesToHex((WalletHelpers.decryptSigner(AddressData.wallet, "002500Gg!", AddressData.wallet.salt) as EthPrivateKey).privateKey, include0x: true));
              return;*/
              setState(() {
                balancesVisible = !balancesVisible;
              });
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
            CurrencyBalanceCard(currencyBalance: currencyBalance, balanceVisible: balancesVisible,),
        ],
      ),
    );
  }
}
