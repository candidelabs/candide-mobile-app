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
          Builder(
            builder: (context) {
              bool selected = selectedChainId == network.chainId.toInt();
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                child: ElevatedButton(
                  onPressed: (){
                    onSelect(network.chainId.toInt());
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStatePropertyAll(network.color.withOpacity(0.4)),
                    elevation: const MaterialStatePropertyAll(0),
                    shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                      side: BorderSide(color: selected ? network.color : Colors.transparent),
                      borderRadius: BorderRadius.circular(8),
                    )),
                    overlayColor: MaterialStatePropertyAll(Get.theme.colorScheme.primary.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(network.name, style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: AppThemes.getContrastColor(network.color).withOpacity(selected ? 1 : 0.85)),),
                      SizedBox(width: selected ? 5 : 0),
                      selected ? Icon(Icons.check, size: 15, color: AppThemes.getContrastColor(network.color)) : const SizedBox.shrink(),
                    ],
                  ),
                ),
              );
            }
          )
      ],
    );
  }
}