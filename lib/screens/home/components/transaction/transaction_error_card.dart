import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TransactionErrorCard extends StatelessWidget {
  final String errorMessage;
  const TransactionErrorCard({Key? key, required this.errorMessage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: Get.width * 0.05, right: Get.width * 0.05, top: 10, bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      width: double.maxFinite,
      height: 40,
      decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(
            color: Colors.red,
          )
      ),
      child: Center(
          child: Text(errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red),)
      ),
    );
  }
}
