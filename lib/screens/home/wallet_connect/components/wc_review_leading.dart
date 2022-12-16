import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:candide_mobile_app/screens/home/wallet_connect/components/transaction_decode_components/default_decode_component.dart';
import 'package:candide_mobile_app/screens/home/wallet_connect/components/transaction_decode_components/default_mc_decode_component.dart';
import 'package:candide_mobile_app/screens/home/wallet_connect/components/transaction_decode_components/known_params_component.dart';
import 'package:candide_mobile_app/screens/home/wallet_connect/components/transaction_decode_components/wc_approve_component.dart';
import 'package:candide_mobile_app/services/transaction_decoder.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';

class WCReviewLeading extends StatefulWidget {
  final WalletConnect connector;
  final JsonRpcRequest request;
  final bool isMultiCall;
  const WCReviewLeading({Key? key, required this.connector, required this.request, required this.isMultiCall}) : super(key: key);

  @override
  State<WCReviewLeading> createState() => _WCReviewLeadingState();
}

class _WCReviewLeadingState extends State<WCReviewLeading> {
  late Widget decodedDataLeading;

  void decodeRequestData() async {
    HexTransactionDetails? transactionDetails = await TransactionDecoder.decodeHexData(widget.request.params![0]["data"]);
    if (transactionDetails == null) return;
    bool showKnownParamsComponent = false;
    check: {
      if (TransactionDecoder.uiOrganizedFunctions.contains(transactionDetails.selector)){
        if (transactionDetails.selector == "095ea7b3"){ // approve
          TokenInfo? token = TokenInfoStorage.getTokenByAddress(widget.request.params![0]["to"].toString().toLowerCase());
          if (token == null){
            showKnownParamsComponent = true;
            break check;
          }
          decodedDataLeading = WCApproveComponent(
            transactionDetails: transactionDetails,
            token: token,
          );
        }
      }else{
        showKnownParamsComponent = true;
      }
    }
    if (showKnownParamsComponent){
      decodedDataLeading = KnownParamsComponent(
        transactionDetails: transactionDetails,
      );
    }
    setState(() {});
  }

  @override
  void initState() {
    if (!widget.isMultiCall){
      decodedDataLeading = DefaultDecodedLeading(data: widget.request.params![0]["data"]!);
      decodeRequestData();
    }else{
      decodedDataLeading = DefaultMultiCallDecodeComponent(request: widget.request,);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 75,
          height: 75,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(75),
            child: Image.network(
              widget.connector.session.peerMeta!.icons![0]
            ),
          ),
        ),
        const SizedBox(height: 25,),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 15),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              text: widget.connector.session.peerMeta!.name,
              style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 22, color: Get.theme.colorScheme.primary),
              children: const [
                TextSpan(
                  text: " wants your permission to execute this transaction",
                  style: TextStyle(fontSize: 20, color: Colors.white),
                )
              ]
            ),
          ),
        ),
        const SizedBox(height: 15,),
        decodedDataLeading,
      ],
    );
  }
}
