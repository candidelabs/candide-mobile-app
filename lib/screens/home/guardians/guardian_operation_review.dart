import 'package:candide_mobile_app/models/batch.dart';
import 'package:candide_mobile_app/models/guardian_operation.dart';
import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/address_persistent_data.dart';
import 'package:candide_mobile_app/controller/settings_persistent_data.dart';
import 'package:candide_mobile_app/screens/components/summary_table.dart';
import 'package:candide_mobile_app/utils/currency.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class GuardianOperationReview extends StatefulWidget {
  final GuardianOperation operation;
  final String guardian;
  final Batch batch;
  final VoidCallback onConfirm;
  const GuardianOperationReview({Key? key, required this.operation, required this.batch, required this.guardian, required this.onConfirm}) : super(key: key);

  @override
  State<GuardianOperationReview> createState() => _GuardianOperationReviewState();
}

class _GuardianOperationReviewState extends State<GuardianOperationReview> {
  String errorMessage = "";
  final _errors = {
    "fee": "Insufficient balance to cover network fee",
  };

  @override
  void initState() {
    String feeCurrency = widget.batch.getFeeCurrency();
    BigInt fee = widget.batch.getFee();
    if (widget.operation != GuardianOperation.recover && AddressData.getCurrencyBalance(feeCurrency) < fee){
      errorMessage = _errors["fee"]!;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints){
        return SingleChildScrollView(
          controller: Get.find<ScrollController>(tag: "guardian_review_modal"),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth, minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  const SizedBox(height: 15,),
                  Text("Review", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 20),),
                  const SizedBox(height: 35,),
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(15),
                        width: 95,
                        height: 95,
                        decoration: BoxDecoration(
                          color: Get.theme.cardColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(PhosphorIcons.userLight, size: 30,),
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
                            child: Icon(widget.operation == GuardianOperation.grant ? Icons.add : (widget.operation == GuardianOperation.revoke ? Icons.remove : Icons.refresh), color: Get.theme.colorScheme.onPrimary, size: 18,)
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25,),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: Get.width * 0.03),
                    child: SummaryTable(
                      entries: [
                        SummaryTableEntry(
                          title: "Operation",
                          value: widget.operation == GuardianOperation.grant ? "Granting guardian" : (widget.operation == GuardianOperation.revoke ? "Removing Guardian" : "Recover wallet"),
                        ),
                        SummaryTableEntry(
                          title: widget.operation == GuardianOperation.recover ? "Wallet address" : "Guardian address",
                          value: widget.guardian,
                        ),
                        SummaryTableEntry(
                          title: "Estimated fee",
                          value: CurrencyUtils.formatCurrency(widget.batch.getFee(), widget.batch.getFeeCurrency()),
                        ),
                        SummaryTableEntry(
                          title: "Network",
                          titleStyle: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Networks.get(SettingsData.network)!.color),
                          valueStyle: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Networks.get(SettingsData.network)!.color),
                          value: SettingsData.network,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  errorMessage.isNotEmpty ? Container(
                    margin: EdgeInsets.symmetric(horizontal: Get.width * 0.05),
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
                  ) : const SizedBox.shrink(),
                  SizedBox(height: errorMessage.isNotEmpty ? 5 : 0,),
                  ElevatedButton(
                    onPressed: errorMessage.isEmpty ? (){
                      widget.onConfirm.call();
                    } : null,
                    style: ButtonStyle(
                      minimumSize: MaterialStateProperty.all(Size(Get.width * 0.9, 40)),
                      shape: MaterialStateProperty.all(const BeveledRectangleBorder(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(7),
                        ),
                      )),
                    ),
                    child: Text("Confirm", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 18),),
                  ),
                  const SizedBox(height: 25,),
                ],
              ),
            ),
          ),
        );
      }
    );
  }
}
