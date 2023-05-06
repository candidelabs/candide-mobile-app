import 'dart:async';

import 'package:blockies/blockies.dart';
import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:candide_mobile_app/screens/home/settings/settings_screen.dart';
import 'package:candide_mobile_app/screens/home/wallet_selection/wallet_name_edit_dialog.dart';
import 'package:candide_mobile_app/utils/events.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:wallet_dart/wallet/account.dart';

class AccountSelectionSheet extends StatefulWidget {
  final Account currentSelectedAccount;
  final Function(Account) onSelect;
  final Function(Account) onPressRemove;
  final Function(Account) onSetupRecovery;
  final VoidCallback onPressCreate;
  final VoidCallback onPressRecover;
  const AccountSelectionSheet({
    Key? key,
    required this.currentSelectedAccount,
    required this.onSelect,
    required this.onPressRemove,
    required this.onPressCreate,
    required this.onSetupRecovery,
    required this.onPressRecover
  }) : super(key: key);

  @override
  State<AccountSelectionSheet> createState() => _AccountSelectionSheetState();
}

class _AccountSelectionSheetState extends State<AccountSelectionSheet> {
  late final StreamSubscription accountDataEditSubscription;
  bool editState = false;
  List<int> walletChainIds = [];

  @override
  void initState() {
    Set<int> _tempChainIds = {};
    for (Account account in PersistentData.accounts){
      if (PersistentData.hiddenNetworks.contains(account.chainId)) continue;
      if (Networks.getByChainId(account.chainId) == null) continue;
      _tempChainIds.add(account.chainId);
    }
    walletChainIds.addAll(_tempChainIds);
    walletChainIds.sort();
    accountDataEditSubscription = eventBus.on<OnAccountDataEdit>().listen((event) {
      if (!mounted) return;
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    accountDataEditSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 15,),
          Stack(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(width: 15,),
                  InkWell(
                    onTap: () async {
                      Get.back(); // close account selection sheet
                      await Future.delayed(const Duration(milliseconds: 300)); // for the user to see the account selection sheet close
                      Get.to(const SettingsScreen());
                    },
                    child: const Icon(PhosphorIcons.gearLight)
                  ),
                  const Spacer(),
                  Card(
                    child: InkWell(
                      onTap: (){
                        setState(() => editState = !editState);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        child: Row(
                          children: [
                            Text(editState ? "Done" : "Edit", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 14),),
                            const SizedBox(width: 10,),
                            Icon(editState ? PhosphorIcons.check : PhosphorIcons.pencilLineLight, size: 15,)
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5,),
                ],
              ),
              Center(child: Text("Accounts", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 20),)),
            ],
          ),
          const SizedBox(height: 10,),
          for (int chainId in walletChainIds)
            Builder(
              builder: (context) {
                Network network = Networks.getByChainId(chainId)!;
                return Column(
                  children: [
                    const SizedBox(height: 5,),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: Get.width,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: network.color.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(8)
                      ),
                      child: Text(network.name),
                    ),
                    const SizedBox(height: 5,),
                    for (Account account in PersistentData.accounts.where((element) => element.chainId == chainId))
                      _AccountCard(
                        onSelect: () => widget.onSelect(account),
                        onRemove: () => widget.onPressRemove(account),
                        onSetupRecovery: () => widget.onSetupRecovery(account),
                        account: account,
                        isSelected: account == PersistentData.selectedAccount,
                        editState: editState,
                      ),
                  ],
                );
              }
            ),
          const SizedBox(height: 5,),
          const Divider(indent: 30, endIndent: 30,),
          const SizedBox(height: 5,),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: TextButton.icon(
              onPressed: widget.onPressCreate,
              style: ButtonStyle(
                alignment: Alignment.centerLeft,
                minimumSize: MaterialStatePropertyAll(Size(Get.width, 0))
              ),
              label: Text("Create new account", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 17),),
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Get.theme.cardColor,
                ),
                child: const Icon(Icons.add_circle_outlined, size: 20,),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: TextButton.icon(
              onPressed: widget.onPressRecover,
              style: ButtonStyle(
                  alignment: Alignment.centerLeft,
                  minimumSize: MaterialStatePropertyAll(Size(Get.width, 0))
              ),
              label: Text("Recover existing CANDIDE account", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 17),),
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Get.theme.cardColor,
                ),
                child: const Icon(PhosphorIcons.shieldBold, size: 20,),
              ),
            ),
          ),
          const SizedBox(height: 25,),
        ],
      ),
    );
  }
}

class _AccountCard extends StatefulWidget {
  final Account account;
  final bool isSelected;
  final bool editState;
  final VoidCallback onSelect;
  final VoidCallback onRemove;
  final VoidCallback onSetupRecovery;
  const _AccountCard({Key? key, required this.account, required this.isSelected, required this.editState, required this.onSelect, required this.onRemove, required this.onSetupRecovery}) : super(key: key);

  @override
  State<_AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends State<_AccountCard> {
  bool? _recoverable;
  List<PopupMenuEntry<int>> popupMenuItems = [];

  void checkRecoverability() async {
    _recoverable = await PersistentData.isAccountRecoverable(widget.account);
    if (!mounted) return;
    setState(() {});
  }

  @override
  void initState() {
    checkRecoverability();
    popupMenuItems = [
      const PopupMenuItem(
        value: 1,
        child: Text("Edit Account"),
      )
    ];
    if (widget.account.recoveryId == null){
      popupMenuItems.add(
        const PopupMenuItem(
          value: 2,
          child: Text("Remove Account"),
        )
      );
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
        ),
        child: InkWell(
          onTap: widget.onSelect,
          borderRadius: BorderRadius.circular(9),
          child: Container(
            padding: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              border: widget.isSelected ? Border.all(
                color: Get.theme.colorScheme.primary.withOpacity(0.7),
              ) : null,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 35,
                        height: 35,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(35),
                          child: Blockies(
                            seed: widget.account.address.hexEip55 + widget.account.chainId.toString(),
                            color: Get.theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10,),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          widget.account.recoveryId == null ? Text(
                            widget.account.name,
                            style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 17)
                          ) : Text(
                            "Recovery in progress...",
                            style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Colors.grey, fontSize: 13),
                          ),
                          const SizedBox(height: 2,),
                          Text(Utils.truncate(widget.account.address.hexEip55), style: const TextStyle(fontSize: 12, color: Colors.grey),),
                        ],
                      ),
                      const Spacer(),
                      widget.editState ? PopupMenuButton(
                        itemBuilder: (context) => popupMenuItems,
                        onSelected: (int action) async {
                          if (action == 1){
                            showDialog(
                              context: context,
                              useRootNavigator: false,
                              builder: (_) => AccountNameEditDialog(account: widget.account)
                            );
                          }else if(action == 2){
                            widget.onRemove.call();
                          }
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 3),
                          child: Icon(PhosphorIcons.dotsThreeCircle),
                        ),
                      ) : const SizedBox.shrink(),
                      widget.isSelected && !widget.editState ? const Icon(PhosphorIcons.checkCircleFill, color: Colors.green,) : const SizedBox.shrink(),
                    ],
                  ),
                ),
                const SizedBox(height: 10,),
                !(_recoverable ?? true) ? Container(
                  padding: const EdgeInsets.only(top: 2.5, bottom: 2.5, left: 4),
                  width: double.maxFinite,
                  decoration: BoxDecoration(
                    color: Get.theme.colorScheme.primary.withOpacity(0.15),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(9),
                      bottomRight: Radius.circular(9),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        "Account not recoverable. ",
                        style: TextStyle(fontSize: 11.5),
                      ),
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: TextButton.icon(
                          onPressed: widget.onSetupRecovery,
                          style: const ButtonStyle(
                            padding: MaterialStatePropertyAll(EdgeInsets.zero),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(PhosphorIcons.caretRight, size: 9,),
                          label: const Text(
                            "Setup recovery contacts",
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      )
                    ],
                  ),
                ) : const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
