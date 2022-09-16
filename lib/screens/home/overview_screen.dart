import 'package:biometric_storage/biometric_storage.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/hooks/guardian_hook.dart';
import 'package:candide_mobile_app/screens/home/swap/swap_sheet.dart';
import 'package:candide_mobile_app/controller/explorer.dart';
import 'package:candide_mobile_app/controller/address_persistent_data.dart';
import 'package:candide_mobile_app/controller/settings_persistent_data.dart';
import 'package:candide_mobile_app/screens/home/components/balance_card.dart';
import 'package:candide_mobile_app/screens/home/components/currency_balance_card.dart';
import 'package:candide_mobile_app/screens/home/components/deposit_sheet.dart';
import 'package:candide_mobile_app/screens/home/components/network_bar.dart';
import 'package:candide_mobile_app/screens/home/send/send_sheet.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:magic_sdk/magic_sdk.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:wallet_dart/constants/constants.dart';
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
        quoteCurrency: SettingsData.quoteCurrency,
        timePeriod: SettingsData.timePeriod,
        currencyList: ["UNI", "ETH"], // todo check here
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
              print(AddressData.wallet.toJson());
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
