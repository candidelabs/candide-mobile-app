import 'package:blockies/blockies.dart';
import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wallet_dart/wallet/account.dart';

class TestTokenAccountSelection extends StatefulWidget {
  final Function(Account) onSelect;
  const TestTokenAccountSelection({Key? key, required this.onSelect}) : super(key: key);

  @override
  State<TestTokenAccountSelection> createState() => _TestTokenWalletSelectionState();
}

class _TestTokenWalletSelectionState extends State<TestTokenAccountSelection> {
  List<int> walletChainIds = [];

  @override
  void initState() {
    Set<int> _tempChainIds = {};
    for (Account account in PersistentData.accounts){
      Network? network = Networks.getByChainId(account.chainId);
      if (network == null || network.testnetData == null) continue;
      _tempChainIds.add(account.chainId);
    }
    walletChainIds.addAll(_tempChainIds);
    walletChainIds.sort();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Choose an account"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                          account: account,
                        ),
                    ],
                  );
                }
            ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final Account account;
  final VoidCallback onSelect;
  const _AccountCard({Key? key, required this.account, required this.onSelect}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (account.recoveryId != null) return const SizedBox.shrink();
    return Card(
      elevation: 15,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(9),
      ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.only(top: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                SizedBox(
                  width: 35,
                  height: 35,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(35),
                    child: Blockies(
                      seed: account.address.hexEip55 + account.chainId.toString(),
                      color: Get.theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10,),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 17)
                    ),
                    const SizedBox(height: 2,),
                    Text(Utils.truncate(account.address.hexEip55), style: const TextStyle(fontSize: 12, color: Colors.grey),),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
