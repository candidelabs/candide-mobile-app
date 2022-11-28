import 'package:candide_mobile_app/models/guardian_operation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class GuardianReviewLeadingWidget extends StatelessWidget {
  final GuardianOperation operation;
  const GuardianReviewLeadingWidget({Key? key, required this.operation}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          width: 95,
          height: 95,
          decoration: BoxDecoration(
            color: Get.theme.cardColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(PhosphorIcons.shield, size: 30,),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(5),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Get.theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
                child: Icon(operation == GuardianOperation.grant ? PhosphorIcons.userPlus : (operation == GuardianOperation.revoke ? PhosphorIcons.userMinus : Icons.refresh), color: Get.theme.colorScheme.onPrimary, size: 18,)
            ),
          ),
        ),
      ],
    );
  }
}
