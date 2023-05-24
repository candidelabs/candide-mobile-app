import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:candide_mobile_app/models/batch.dart';
import 'package:candide_mobile_app/models/gnosis_transaction.dart';
import 'package:candide_mobile_app/screens/home/components/transaction/transaction_review_sheet.dart';
import 'package:candide_mobile_app/screens/home/wallet_connect/components/wallet_deployment_leading.dart';
import 'package:candide_mobile_app/utils/constants.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:web3dart/crypto.dart';

class WCSignatureRejectDialog extends StatelessWidget {
  final WalletConnect connector;
  const WCSignatureRejectDialog({Key? key, required this.connector}) : super(key: key);

  void createEmptyTransaction() async {
    var cancelLoad = Utils.showLoading();
    Batch emptyBatch = Batch(account: PersistentData.selectedAccount, network: Networks.selected());
    await emptyBatch.fetchPaymasterResponse();
    emptyBatch.transactions.add(GnosisTransaction(
      id: "empty-deploy",
      to: Constants.addressZero,
      data: hexToBytes("0x"),
      value: BigInt.zero,
      type: GnosisTransactionType.execTransactionFromEntrypoint,
      suggestedGasLimit: BigInt.from(21000),
    ));
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
      title: RichText(
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
                Text("Your account needs to be activated", textAlign: TextAlign.left, style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 20),),
                const SizedBox(height: 10,),
                Text("In order to sign this message you need to first activate your account on ${Networks.selected().name}\n\nActivating your account can be done manually or automatically on your first transaction.", textAlign: TextAlign.start, style: TextStyle(fontFamily: AppThemes.fonts.gilroy, fontSize: 15, color: Colors.white)),
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
              child:  Text("Manually Activate Account", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Get.theme.colorScheme.primary, fontSize: 15)),
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
