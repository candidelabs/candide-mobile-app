import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:candide_mobile_app/models/batch.dart';
import 'package:candide_mobile_app/models/fee_currency.dart';
import 'package:candide_mobile_app/screens/home/components/transaction_review_sheet.dart';
import 'package:candide_mobile_app/screens/home/wallet_connect/components/wallet_deployment_leading.dart';
import 'package:candide_mobile_app/services/bundler.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';

class WCSignatureRejectDialog extends StatelessWidget {
  final WalletConnect connector;
  const WCSignatureRejectDialog({Key? key, required this.connector}) : super(key: key);

  void createEmptyTransaction() async {
    var cancelLoad = Utils.showLoading();
    Batch emptyBatch = Batch();
    List<FeeToken>? feeCurrencies = await Bundler.fetchPaymasterFees(PersistentData.selectedAccount.chainId);
    if (feeCurrencies == null){
      // todo handle network errors
      return;
    }else{
      await emptyBatch.changeFeeCurrencies(feeCurrencies);
    }
    //
    TransactionActivity transactionActivity = TransactionActivity(
      date: DateTime.now(),
      action: "account-deployed",
      title: "Wallet deployed",
      status: "pending",
      data: {},
    );
    //
    cancelLoad();
    await showBarModalBottomSheet(
      context: Get.context!,
      backgroundColor: Get.theme.canvasColor,
      builder: (context) {
        Get.put<ScrollController>(ModalScrollController.of(context)!, tag: "empty_deployment");
        return TransactionReviewSheet(
          modalId: "empty_deployment",
          leading: const WalletDeploymentLeadingWidget(),
          tableEntriesData: {
            "Action": "Deployment",
            "Network": Networks.selected().chainId.toString(),
          },
          batch: emptyBatch,
          transactionActivity: transactionActivity,
          showRejectButton: true,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      title: Text("Wallet not deployed", textAlign: TextAlign.center, style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 24.0,
              top: 20.0,
              right: 24.0,
              bottom: 24.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(
                  "assets/animations/sad.json",
                  width: Get.width * 0.4,
                  repeat: true,
                ),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                      text: connector.session.peerMeta!.name,
                      style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 22, color: Get.theme.colorScheme.primary),
                      children: const [
                        TextSpan(
                          text: " wants your signature",
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        )
                      ]
                  ),
                ),
                const SizedBox(height: 10,),
                Text("Signing feature is not accessible until your wallet has been deployed.\nPlease note that deployment occurs automatically upon completion of your initial transaction with this wallet.", textAlign: TextAlign.start, style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 15, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 25,),
          InkWell(
            onTap: (){
              Get.back();
              createEmptyTransaction();
            },
            child: Container(
              alignment: Alignment.center,
              width: double.maxFinite,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border.symmetric(horizontal: BorderSide(color: Colors.grey.withOpacity(0.5), width: 0.5)),
              ),
              child:  Text("Manually deploy wallet", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Get.theme.colorScheme.primary, fontSize: 15)),
            ),
          ),
          InkWell(
            onTap: (){
              Get.back();
            },
            child: Container(
              alignment: Alignment.center,
              width: double.maxFinite,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text("Cancel", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Colors.grey, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
