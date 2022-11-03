import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NetworkBar extends StatelessWidget {
  final Network network;
  const NetworkBar({Key? key, required this.network}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: Get.theme.colorScheme.primary,
        borderRadius: const BorderRadius.all(Radius.circular(25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 5,),
          /*SizedBox(
            height: 25,
            width: 25,
            child: network.logo,
          ),*/
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.all(Radius.circular(50))
            ),
          ),
          const SizedBox(width: 5,),
          Text(network.name, style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Colors.black),),
          const SizedBox(width: 10,),
        ],
      ),
    );
  }
}