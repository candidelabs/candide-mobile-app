import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/address_persistent_data.dart';
import 'package:candide_mobile_app/utils/currency.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class BalanceCard extends StatelessWidget {
  final VoidCallback onPressVisibilityIcon;
  final VoidCallback onPressWalletConnect;
  final VoidCallback? onPressDeposit;
  final VoidCallback? onPressSend;
  final VoidCallback? onPressSwap;
  final WalletBalance balance;
  final bool balanceVisible;
  const BalanceCard({Key? key, required this.onPressVisibilityIcon, required this.onPressWalletConnect, required this.balance, this.onPressDeposit, this.onPressSend, this.onPressSwap, required this.balanceVisible}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 7),
      child: Card(
        shape: const BeveledRectangleBorder(
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(10)
            )
        ),
        child: Column(
          children: [
            const SizedBox(height: 5,),
            Row(
              children: [
                const SizedBox(width: 10,),
                Text("Overview", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 20),),
                const SizedBox(width: 10,),
                IconButton(
                  onPressed: onPressVisibilityIcon,
                  iconSize: 18,
                  icon: const Icon(PhosphorIcons.eye, size: 25,),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onPressWalletConnect,
                  iconSize: 18,
                  icon: const Icon(PhosphorIcons.scan, size: 25,),
                ),
              ],
            ),
            Container(
                margin: const EdgeInsets.only(left: 10),
                alignment: Alignment.centerLeft,
                child: Text(
                  balanceVisible ? CurrencyUtils.formatCurrency(balance.currentBalance, balance.quoteCurrency) : "••••••••••••",
                  style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 25),
                )
            ),
            const SizedBox(height: 5,),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(width: 10,),
                Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                    onPressed: onPressDeposit,
                    style: ButtonStyle(
                        shape: MaterialStateProperty.all(const BeveledRectangleBorder(
                            borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(10)
                            )
                        ))
                    ),
                    icon: const Icon(PhosphorIcons.arrowDownLight, size: 19,),
                    label: Text("Receive", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 13),),
                  ),
                ),
                const SizedBox(width: 5,),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onPressSend,
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.transparent),
                      elevation: MaterialStateProperty.all(0),
                      shape: MaterialStateProperty.all(RoundedRectangleBorder(
                          borderRadius: const BorderRadius.all(Radius.circular(0)),
                          side: BorderSide(color: Get.theme.colorScheme.primary, width: 1.5)
                      )),
                    ),
                    icon: Icon(PhosphorIcons.arrowUpLight, size: 19, color: Get.theme.colorScheme.primary),
                    label: Text("Send", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Get.theme.colorScheme.primary, fontSize: 13),),
                  ),
                ),
                const SizedBox(width: 5,),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onPressSwap,
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.transparent),
                      elevation: MaterialStateProperty.all(0),
                      shape: MaterialStateProperty.all(RoundedRectangleBorder(
                          borderRadius: const BorderRadius.all(Radius.circular(0)),
                          side: BorderSide(color: Get.theme.colorScheme.primary, width: 1.5)
                      )),
                    ),
                    icon: Transform.rotate(
                      angle: (math.pi / 4),
                      child: Icon(PhosphorIcons.arrowsDownUp, size: 19, color: Get.theme.colorScheme.primary)
                    ),
                    label: Text("Swap", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Get.theme.colorScheme.primary, fontSize: 13),),
                  ),
                ),
                const SizedBox(width: 10,),
              ],
            ),
            const SizedBox(height: 5,),
          ],
        ),
      ),
    );
  }
}