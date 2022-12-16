import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DefaultDecodedLeading extends StatelessWidget {
  final String data;
  final EdgeInsets margin;
  final double? elevation;

  const DefaultDecodedLeading({
    Key? key,
    required this.data,
    this.margin = const EdgeInsets.symmetric(horizontal: 10),
    this.elevation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: Card(
        elevation: elevation ?? Get.theme.cardTheme.elevation,
        child: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  text: "Data",
                  style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 20),
                  children: const [
                    TextSpan(
                      text: " in hex",
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    )
                  ]
                ),
              ),
              const SizedBox(height: 5),
              Text(Utils.truncate(data, leadingDigits: 30, trailingDigits: 30), style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          )
        ),
      ),
    );
  }
}
