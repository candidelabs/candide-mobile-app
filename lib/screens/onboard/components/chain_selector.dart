import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChainSelector extends StatelessWidget {
  final int selectedChainId;
  final Function(int) onSelect;
  const ChainSelector({Key? key, required this.selectedChainId, required this.onSelect}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        for (Network network in Networks.instances.where((element) => element.visible))
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            child: ElevatedButton(
              onPressed: (){
                onSelect(network.chainId.toInt());
              },
              style: ButtonStyle(
                backgroundColor: MaterialStatePropertyAll(network.color.withOpacity(0.15)),
                elevation: const MaterialStatePropertyAll(0),
                shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                  side: BorderSide(color: selectedChainId == network.chainId.toInt() ? network.color : Colors.transparent),
                  borderRadius: BorderRadius.circular(8),
                )),
                overlayColor: MaterialStatePropertyAll(Get.theme.colorScheme.primary.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(network.name, style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: network.color),),
                  SizedBox(width: selectedChainId == network.chainId.toInt() ? 5 : 0),
                  selectedChainId == network.chainId.toInt() ? Icon(Icons.check, size: 15, color: network.color,) : const SizedBox.shrink(),
                ],
              ),
            ),
          )
      ],
    );
  }
}