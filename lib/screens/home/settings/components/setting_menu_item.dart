import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingMenuItem extends StatelessWidget {
  final Widget label;
  final Widget? description;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback onPress;
  const SettingMenuItem({Key? key, required this.label, this.description, this.leading, this.trailing, required this.onPress}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      child: Card(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)
        ),
        child: InkWell(
          onTap: onPress,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
            child: Row(
              children: [
                leading != null ? Container(
                    margin: const EdgeInsets.only(right: 7.5),
                    child: leading
                ) : const SizedBox.shrink(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    label,
                    description != null ? Container(
                        margin: const EdgeInsets.only(top: 5),
                        width: Get.width * 0.55,
                        child: description!
                    ) : const SizedBox.shrink(),
                  ],
                ),
                const Spacer(),
                trailing != null ? Container(
                    margin: const EdgeInsets.only(right: 5),
                    child: trailing
                ) : const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}