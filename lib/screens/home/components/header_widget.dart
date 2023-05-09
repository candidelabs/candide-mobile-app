import 'package:blockies/blockies.dart';
import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/screens/home/components/network_bar.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:wallet_dart/wallet/account.dart';

class HeaderWidget extends StatefulWidget {
  final Account account;
  final bool showWalletConnectIcon;
  final VoidCallback onCopyAddress;
  final VoidCallback onPressWalletConnect;
  final VoidCallback onPressWalletSelector;
  const HeaderWidget({Key? key, required this.account, this.showWalletConnectIcon=true, required this.onCopyAddress, required this.onPressWalletConnect, required this.onPressWalletSelector}) : super(key: key);

  @override
  State<HeaderWidget> createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends State<HeaderWidget> {
  late Network network;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    network = Networks.getByChainId(widget.account.chainId)!;
    return Material(
      child: Column(
        children: [
          const SizedBox(height: 10,),
          Row(
            children: [
              const SizedBox(width: 15,),
              NetworkBar(network: network),
              const Spacer(),
              widget.showWalletConnectIcon ? Stack(
                children: [
                  IconButton(
                    onPressed: widget.onPressWalletConnect,
                    splashRadius: 15,
                    icon: Container(
                      width: 25,
                      height: 25,
                      decoration: BoxDecoration(
                        color: Get.theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(PhosphorIcons.scan, size: 20, color: Get.theme.colorScheme.onPrimary,)
                    ),
                  ),
                  Positioned(
                    top: 5,
                    right: 7,
                    child: Container(
                      padding: const EdgeInsets.all(1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B99FC),
                        borderRadius: BorderRadius.circular(50)
                      ),
                      width: 15,
                      height: 15,
                      child: SvgPicture.asset("assets/images/walletconnect.svg", color: Colors.white),
                    ),
                  )
                ],
              ) : const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 0,),
          SizedBox(
            width: 70,
            height: 70,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(70),
              child: Blockies(
                seed: widget.account.address.hexEip55 + widget.account.chainId.toString(),
                color: Get.theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 5,),
          InkWell(
            onTap: widget.onPressWalletSelector,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 2,),
                RichText(
                  text: TextSpan(
                    text: Utils.truncate(widget.account.name, leadingDigits: 12, trailingDigits: 12),
                    style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 25),
                    /*children: const [ // todo re-visit when ens services are up
                      TextSpan(
                        text: ".candide.id",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ]*/
                  )
                ),
                const SizedBox(width: 5,),
                const Icon(PhosphorIcons.caretDownLight, color: Colors.grey, size: 15,),
                const SizedBox(width: 2,),
              ],
            ),
          ),
          const SizedBox(height: 10,),
          InkWell(
            onTap: widget.onCopyAddress,
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: network.color.withOpacity(0.6),
                borderRadius: BorderRadius.circular(15)
              ),
              child: Text(Utils.truncate(widget.account.address.hex, leadingDigits: 4, trailingDigits: 4), textAlign: TextAlign.center, style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 12, color: AppThemes.getContrastColor(network.color))),
            ),
          )
        ],
      ),
    );
  }
}
