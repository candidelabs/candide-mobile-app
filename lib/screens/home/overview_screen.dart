import 'dart:async';

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
import 'package:candide_mobile_app/utils/events.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';


class OverviewScreen extends StatefulWidget {
  const OverviewScreen({Key? key}) : super(key: key);

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  final RefreshController _refreshController = RefreshController(initialRefresh: true);
  late final StreamSubscription transactionStatusSubscription;
  final ownerPublicAddress = AddressData.wallet.walletAddress.hexEip55;
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
    transactionStatusSubscription = eventBus.on<OnTransactionStatusChange>().listen((event) {
      if (!mounted) return;
      if (event.activity.action == "transfer" || event.activity.action == "swap"){ // todo(walletconnect/dapps) add contract interaction in the future
        _refreshController.requestRefresh();
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    transactionStatusSubscription.cancel();
    super.dispose();
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
              Icon(PhosphorIcons.user, size: 25, color: Get.theme.colorScheme.primary),
              const SizedBox(width: 10,),
              Text(
                Utils.truncate(ownerPublicAddress, trailingDigits: 3), 
                style: TextStyle(fontSize: 18, fontFamily: AppThemes.fonts.gilroy),
              ),
              const SizedBox(width: 10,),
              IconButton(
                splashRadius: 12,
                style: const ButtonStyle(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => Utils.copyText(ownerPublicAddress, message: "Address copied to clipboard!"),
                icon: Icon(PhosphorIcons.copyLight, color: Get.theme.colorScheme.primary , size: 20),
              ),
              const Spacer(),
              NetworkBar(network: Networks.get(SettingsData.network)!),
              const SizedBox(width: 10,),
            ],
          ),
          BalanceCard(
            balanceVisible: balancesVisible,
            onPressVisibilityIcon: () async {
              setState(() {
                balancesVisible = !balancesVisible;
              });
            },
            onPressDeposit: _refreshController.isLoading ? null : (){
              showBarModalBottomSheet(
                context: context,
                builder: (context) => SingleChildScrollView(
                  controller: ModalScrollController.of(context),
                  child: DepositSheet(address: ownerPublicAddress),
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
