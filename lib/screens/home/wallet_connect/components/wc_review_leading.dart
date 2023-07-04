import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:candide_mobile_app/controller/wallet_connect/wc_peer_meta.dart';
import 'package:candide_mobile_app/screens/home/wallet_connect/components/transaction_decode_components/default_decode_component.dart';
import 'package:candide_mobile_app/screens/home/wallet_connect/components/transaction_decode_components/default_mc_decode_component.dart';
import 'package:candide_mobile_app/screens/home/wallet_connect/components/transaction_decode_components/known_params_component.dart';
import 'package:candide_mobile_app/screens/home/wallet_connect/components/transaction_decode_components/wc_approve_component.dart';
import 'package:candide_mobile_app/screens/home/wallet_connect/components/wc_peer_icon.dart';
import 'package:candide_mobile_app/services/transaction_decoder.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WCReviewLeading extends StatefulWidget {
  final WCPeerMeta peerMeta;
  final List<dynamic> params;
  final bool isMultiCall;
  const WCReviewLeading({Key? key, required this.peerMeta, required this.params, required this.isMultiCall}) : super(key: key);

  @override
  State<WCReviewLeading> createState() => _WCReviewLeadingState();
}

class _WCReviewLeadingState extends State<WCReviewLeading> {
  late Widget decodedDataLeading;

  void decodeRequestData() async {
    HexTransactionDetails? transactionDetails = await TransactionDecoder.decodeHexData(widget.params[0]["data"]);
    if (transactionDetails == null) return;
    bool showKnownParamsComponent = false;
    check: {
      if (TransactionDecoder.uiOrganizedFunctions.contains(transactionDetails.selector)){
        if (transactionDetails.selector == "095ea7b3"){ // approve
          TokenInfo? token = TokenInfoStorage.getTokenByAddress(widget.params[0]["to"].toString().toLowerCase());
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
      decodedDataLeading = DefaultDecodedLeading(data: widget.params[0]["data"]!);
      decodeRequestData();
    }else{
      decodedDataLeading = DefaultMultiCallDecodeComponent(params: widget.params,);
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
            child: WCPeerIcon(icons: widget.peerMeta.icons,)
          ),
        ),
        const SizedBox(height: 25,),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 15),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              text: widget.peerMeta.name,
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
