import 'dart:async';

import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/signers_controller.dart';
import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:candide_mobile_app/controller/wallet_connect_controller.dart';
import 'package:candide_mobile_app/models/recovery_request.dart';
import 'package:candide_mobile_app/screens/home/components/delete_account_confirm_dialog.dart';
import 'package:candide_mobile_app/screens/home/components/header_widget.dart';
import 'package:candide_mobile_app/screens/home/components/recover_warning_card.dart';
import 'package:candide_mobile_app/screens/home/components/token_management_sheet.dart';
import 'package:candide_mobile_app/screens/home/swap/swap_sheet.dart';
import 'package:candide_mobile_app/screens/home/wallet_connect/components/wc_main_sheet.dart';
import 'package:candide_mobile_app/screens/home/wallet_selection/wallet_name_edit_dialog.dart';
import 'package:candide_mobile_app/screens/home/wallet_selection/wallet_selection_sheet.dart';
import 'package:candide_mobile_app/screens/onboard/create_account/create_account_main_screen.dart';
import 'package:candide_mobile_app/screens/onboard/landing_screen.dart';
import 'package:candide_mobile_app/screens/onboard/recovery/recover_account_sheet.dart';
import 'package:candide_mobile_app/screens/onboard/recovery/recovery_request_page.dart';
import 'package:candide_mobile_app/services/explorer.dart';
import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:candide_mobile_app/screens/home/components/balance_card.dart';
import 'package:candide_mobile_app/screens/home/components/currency_balance_card.dart';
import 'package:candide_mobile_app/screens/home/components/deposit_sheet.dart';
import 'package:candide_mobile_app/screens/home/send/send_sheet.dart';
import 'package:candide_mobile_app/services/security.dart';
import 'package:candide_mobile_app/utils/events.dart';
import 'package:candide_mobile_app/utils/guardian_helpers.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:short_uuids/short_uuids.dart';
import 'package:wallet_dart/wallet/account.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({Key? key}) : super(key: key);

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  final RefreshController _refreshController = RefreshController(initialRefresh: true);
  late final StreamSubscription transactionStatusSubscription;
  late final StreamSubscription accountDataEditSubscription;
  //
  bool balancesVisible = true;
  bool isRecovery = false;
  RecoveryRequest? recoveryRequest;
  Account account = PersistentData.selectedAccount;
  bool? accountRecoverable = true;

  fetchOverview() async {
    await Explorer.fetchAddressOverview(
      account: account,
      additionalCurrencies: TokenInfoStorage.tokens,
    );
    if (!mounted) return;
    _refreshController.refreshCompleted();
    setState(() {});
  }

  void checkRecovery() async {
    bool _previousState = isRecovery;
    setState((){
      isRecovery = account.recoveryId != null;
    });
    if (isRecovery && _previousState){
      setState(() {
        recoveryRequest = null;
      });
    }
    if (!isRecovery){
      if (account.name.trim().isEmpty){
        showDialog(
            context: context,
            useRootNavigator: false,
            barrierDismissible: false,
            builder: (_) => AccountNameEditDialog(account: account)
        );
      }
      return;
    }
    recoveryRequest = await SecurityGateway.fetchById(account.recoveryId!);
    setState(() {});
  }

  Future<bool> requestWalletRemoval(Account account) async {
    bool? delete = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (_) => DeleteAccountConfirmDialog(account: account,)
    ) ?? false;
    if (!delete) return false;
    int deletedWalletIndex = PersistentData.accounts.indexOf(account);
    await WalletConnectController.disconnectAllSessions();
    PersistentData.transactionsActivity.clear();
    PersistentData.guardians.clear();
    await PersistentData.deleteAccount(account);
    await Hive.box("state").delete("address_data(${account.address.hex}-${account.chainId})");
    await Hive.box("state").delete("guardians_metadata(${account.address.hex}-${account.chainId})");
    await Hive.box("activity").delete("transactions(${account.address.hex}-${account.chainId})");
    await Hive.box("wallet_connect").delete("sessions(1)(${account.address.hex}-${account.chainId})");
    if (PersistentData.accounts.isEmpty){
      SignersController.instance.clearPrivateKeys();
      await Hive.box("wallet").clear();
      await Hive.box("signers").clear();
      Get.off(const LandingScreen());
      return false;
    }else{
      Account nextAccount;
      if (PersistentData.accounts.length > deletedWalletIndex + 1){
        nextAccount = PersistentData.accounts[deletedWalletIndex+1];
      }else{
        nextAccount = PersistentData.accounts[deletedWalletIndex-1];
      }
      PersistentData.selectAccount(
        address: nextAccount.address,
        chainId: nextAccount.chainId,
      );
    }
    return true;
  }

  void showDepositModal(){
    showBarModalBottomSheet(
      context: context,
      backgroundColor: Get.theme.canvasColor,
      builder: (context) => SingleChildScrollView(
        controller: ModalScrollController.of(context),
        child: DepositSheet(account: account),
      ),
    );
  }

  void checkRecoverability() async {
    setState(() => accountRecoverable = null);
    if (account.recoveryId != null) return;
    bool _recoverable = await PersistentData.isAccountRecoverable(account);
    if (!mounted) return;
    setState(() => accountRecoverable = _recoverable);
  }
  
  @override
  void initState() {
    checkRecovery();
    checkRecoverability();
    PersistentData.loadExplorerJson(account, null);
    transactionStatusSubscription = eventBus.on<OnTransactionStatusChange>().listen((event) {
      if (!mounted) return;
      if (event.activity.action == "transfer" || event.activity.action == "swap" || event.activity.action == "wc-transaction"){
        _refreshController.requestRefresh();
      }
    });
    accountDataEditSubscription = eventBus.on<OnAccountDataEdit>().listen((event) {
      if (!mounted) return;
      if (event.recovered){
        isRecovery = false;
        recoveryRequest = null;
        _refreshController.requestRefresh();
        if (account.name.trim().isEmpty){
          showDialog(
              context: context,
              useRootNavigator: false,
              barrierDismissible: false,
              builder: (_) => AccountNameEditDialog(account: account)
          );
        }
      }
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    transactionStatusSubscription.cancel();
    accountDataEditSubscription.cancel();
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
      child: SingleChildScrollView(
        child: Column(
          children: [
            HeaderWidget(
              account: account,
              showWalletConnectIcon: account.recoveryId == null,
              onCopyAddress: (){
                if (account.recoveryId == null){
                  showDepositModal();
                }else{
                  Utils.copyText(account.address.hexEip55, message: "Address copied!");
                }
              },
              onPressWalletSelector: () async {
                bool? refresh = await showBarModalBottomSheet(
                  context: context,
                  backgroundColor: Get.theme.canvasColor,
                  builder: (context) {
                    return AccountSelectionSheet(
                      currentSelectedAccount: account,
                      onSelect: (Account account){
                        PersistentData.selectAccount(address: account.address, chainId: account.chainId);
                        Get.back(result: true);
                      },
                      onPressRemove: (Account account) async {
                        bool removed = await requestWalletRemoval(account);
                        if (removed){
                          Get.back(result: true);
                          return;
                        }
                      },
                      onSetupRecovery: (Account account) async {
                        PersistentData.selectAccount(address: account.address, chainId: account.chainId);
                        Get.back(result: true);
                        await Future.delayed(const Duration(milliseconds: 500)); // for the user to observe that the wallet indeed changed in case he's recovering an account that is not selected
                        eventBus.fire(OnHomeRequestChangePageIndex(index: 2));
                      },
                      onPressCreate: (){
                        Get.to(
                          CreateAccountMainScreen(baseAccount: PersistentData.selectedAccount,)
                        );
                      },
                      onPressRecover: () async {
                        var result = await showBarModalBottomSheet(
                          context: context,
                          backgroundColor: Get.theme.canvasColor,
                          builder: (context) {
                            Get.put<ScrollController>(ModalScrollController.of(context)!, tag: "recovery_account_modal");
                            return const RecoverAccountSheet(
                                method: "social-recovery",
                                onNext: GuardianRecoveryHelper.setupRecoveryAccount
                            );
                          },
                        );
                        if (result == true){
                          Get.back(result: true);
                        }
                      },
                    );
                  },
                );
                refresh ??= false;
                if (refresh){
                  account = PersistentData.selectedAccount;
                  checkRecovery();
                  checkRecoverability();
                  _refreshController.requestRefresh();
                  eventBus.fire(OnAccountChange());
                  setState(() {});
                }
              },
              onPressWalletConnect: () async {
                await showBarModalBottomSheet(
                  context: context,
                  backgroundColor: Get.theme.canvasColor,
                  builder: (context) {
                    return WCMainSheet(
                      onScanResult: (String uri){
                        var wcController = WalletConnectController();
                        wcController.connect(
                          uri,
                          const ShortUuid().generate(),
                        );
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 5,),
            !isRecovery ? BalanceCard(
              balanceVisible: balancesVisible,
              onPressVisibilityIcon: () async {
                setState(() {
                  balancesVisible = !balancesVisible;
                });
              },
              onPressDeposit: (){
                showDepositModal();
              },
              onPressSend: () async {
                var refresh = await showBarModalBottomSheet(
                  context: context,
                  backgroundColor: Get.theme.canvasColor,
                  builder: (context) {
                    Get.put<ScrollController>(ModalScrollController.of(context)!, tag: "send_modal");
                    return const SendSheet();
                  },
                );
                if (refresh ?? false){
                  _refreshController.requestRefresh();
                }
              },
              onPressSwap: Networks.selected().isFeatureEnabled("swap.basic") ? () async {
                var refresh = await showBarModalBottomSheet(
                  context: context,
                  backgroundColor: Get.theme.canvasColor,
                  builder: (context) {
                    Get.put<ScrollController>(ModalScrollController.of(context)!, tag: "swap_modal");
                    return const SwapSheet();
                  },
                );
                if (refresh ?? false){
                  _refreshController.requestRefresh();
                }
              } : null,
              balance: PersistentData.accountBalance,
            ) : const SizedBox.shrink(),
            const SizedBox(height: 10,),
            !isRecovery && accountRecoverable == false ? RecoverWarningCard(
              onPressed: (){
                eventBus.fire(OnHomeRequestChangePageIndex(index: 2));
              },
            ) : const SizedBox.shrink(),
            !isRecovery ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  margin: const EdgeInsets.only(right: 15),
                  child: TextButton.icon(
                    onPressed: () async {
                      await showBarModalBottomSheet(
                        context: context,
                        backgroundColor: Get.theme.canvasColor,
                        builder: (context) {
                          Get.put<ScrollController>(ModalScrollController.of(context)!, tag: "token_management_modal");
                          return const TokenManagementSheet();
                        },
                      );
                      setState(() {});
                    },
                    style: const ButtonStyle(
                      padding: MaterialStatePropertyAll(EdgeInsets.zero),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: Icon(PhosphorIcons.slidersHorizontal, size: 14, color: Get.theme.colorScheme.primary.withOpacity(0.75),),
                    label: Text("Manage tokens", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 12, color: Get.theme.colorScheme.primary.withOpacity(0.75)),),
                  ),
                ),
              ],
            ) : const SizedBox.shrink(),
            !isRecovery ? Column(
              children: [
                for (TokenInfo token in TokenInfoStorage.tokens.where((element) => element.visible))
                  CurrencyBalanceCard(token: token, balanceVisible: balancesVisible,),
                const SizedBox(height: 10,)
              ],
            ) : const SizedBox.shrink(),
            //const SizedBox(height: 10,),
            isRecovery ?
            (recoveryRequest != null ? RecoveryRequestPage(
              account: account,
              request: recoveryRequest!
            ) : const CircularProgressIndicator())
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
