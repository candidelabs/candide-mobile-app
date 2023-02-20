import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class BalanceCard extends StatelessWidget {
  final VoidCallback onPressVisibilityIcon;
  final VoidCallback? onPressDeposit;
  final VoidCallback? onPressSend;
  final VoidCallback? onPressSwap;
  final AccountBalance balance;
  final bool balanceVisible;
  const BalanceCard({
    Key? key,
    required this.onPressVisibilityIcon,
    required this.balance,
    this.onPressDeposit,
    this.onPressSend,
    this.onPressSwap,
    required this.balanceVisible
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 7),
      child: Card(
        color: Colors.transparent,
        shape: const BeveledRectangleBorder(
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(10)
            )
        ),
        elevation: 0,
        child: Column(
          children: [
            const SizedBox(height: 10,),
            InkWell(
              onTap: onPressVisibilityIcon,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Text(
                  balanceVisible ? "\$${balance.currentBalance.toPrecision(2)}" : "••••••••••••",
                  style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 50),
                ),
              ),
            ),
            const SizedBox(height: 10,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ActionButton(
                  onPress: onPressDeposit,
                  action: "Receive",
                  iconData: PhosphorIcons.arrowDownBold,
                ),
                const SizedBox(width: 25,),
                _ActionButton(
                  onPress: onPressSend,
                  action: "Send",
                  iconData: PhosphorIcons.paperPlaneTiltBold,
                ),
                SizedBox(width: onPressSwap != null ? 25 : 0,),
                onPressSwap != null ? _ActionButton(
                  onPress: onPressSwap,
                  action: "Swap",
                  iconData: PhosphorIcons.arrowsDownUpBold,
                ) : const SizedBox.shrink(),
              ],
            ),
            const SizedBox(height: 5,),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String action;
  final IconData iconData;
  final VoidCallback? onPress;
  const _ActionButton({Key? key, required this.action, required this.iconData, this.onPress}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color color = onPress == null ? Get.theme.colorScheme.primary.withOpacity(0.25) : Get.theme.colorScheme.primary;
    return Column(
      children: [
        Card(
          color: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25)
          ),
          elevation: 10,
          child: InkWell(
            onTap: onPress,
            highlightColor: color.withOpacity(0.20),
            borderRadius: BorderRadius.circular(25),
            child: SizedBox(
              width: 55,
              height: 50,
              child: Icon(iconData, size: 25, color: Get.theme.colorScheme.onPrimary)
            ),
          )
        ),
        Text(action, style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: color, fontSize: 13)),
      ],
    );
  }
}
