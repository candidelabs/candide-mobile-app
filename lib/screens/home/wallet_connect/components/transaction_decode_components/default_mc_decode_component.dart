import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:candide_mobile_app/screens/home/wallet_connect/components/transaction_decode_components/default_decode_component.dart';
import 'package:candide_mobile_app/screens/home/wallet_connect/components/transaction_decode_components/known_params_component.dart';
import 'package:candide_mobile_app/screens/home/wallet_connect/components/transaction_decode_components/wc_approve_component.dart';
import 'package:candide_mobile_app/services/transaction_decoder.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';

class DefaultMultiCallDecodeComponent extends StatefulWidget {
  final JsonRpcRequest request;
  const DefaultMultiCallDecodeComponent({Key? key, required this.request}) : super(key: key);

  @override
  State<DefaultMultiCallDecodeComponent> createState() => _DefaultMultiCallDecodeComponentState();
}

class _DefaultMultiCallDecodeComponentState extends State<DefaultMultiCallDecodeComponent> {
  List<Widget> decodedDataLeadings = [];

  void decodeRequestData() async {
    List<Widget> leadings = [];
    for (var call in widget.request.params![0]["calls"]){
      HexTransactionDetails? transactionDetails = await TransactionDecoder.decodeHexData(call["data"]);
      bool showKnownParamsComponent = false;
      if (transactionDetails != null){
        check: {
          if (TransactionDecoder.uiOrganizedFunctions.contains(transactionDetails.selector)){
            if (transactionDetails.selector == "095ea7b3"){ // approve
              TokenInfo? token = TokenInfoStorage.getTokenByAddress(call["to"].toString().toLowerCase());
              if (token == null){
                showKnownParamsComponent = true;
                break check;
              }
              leadings.add(WCApproveComponent(
                transactionDetails: transactionDetails,
                token: token,
                margin: EdgeInsets.zero,
                elevation: 0,
              ));
            }
          }else{
            showKnownParamsComponent = true;
          }
        }
        if (showKnownParamsComponent){
          leadings.add(KnownParamsComponent(
            transactionDetails: transactionDetails,
            margin: EdgeInsets.zero,
            elevation: 0,
          ));
        }
      }else{
        leadings.add(DefaultDecodedLeading(
          data: call["data"],
          margin: EdgeInsets.zero,
          elevation: 0,
        ));
      }
    }
    setState(() {
      decodedDataLeadings.clear();
      decodedDataLeadings = leadings;
    });
  }

  @override
  void initState() {
    for (var call in widget.request.params![0]["calls"]){
      decodedDataLeadings.add(DefaultDecodedLeading(
        data: call["data"],
        margin: EdgeInsets.zero,
      ));
    }
    decodeRequestData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: Card(
        child: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(5),
          child: Column(
            children: [
              for (int i=0; i < widget.request.params![0]["calls"].length; i++)
                Builder(
                  builder: (context) {
                    var call = widget.request.params![0]["calls"][i];
                    if (decodedDataLeadings.length-1 < i) return const SizedBox.shrink();
                    return ExpandablePanel(
                      header: Row(
                        children: [
                          RichText(
                            text: TextSpan(
                              text: "Call ",
                              style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 17),
                              children: [
                                TextSpan(
                                  text: (i+1).toString(),
                                  style: TextStyle(color: Get.theme.colorScheme.primary)
                                )
                              ]
                            ),
                          ),
                          const Spacer(),
                          Text(Utils.truncate(call["to"]), style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 12, color: Colors.grey),),
                        ],
                      ),
                      collapsed: const SizedBox.shrink(),
                      //expanded: const SizedBox.shrink(),
                      expanded: decodedDataLeadings[i],
                      theme: const ExpandableThemeData(
                        hasIcon: true,
                        iconColor: Colors.white,
                        iconSize: 25,
                        tapBodyToCollapse: true,
                        tapHeaderToExpand: true,
                        headerAlignment: ExpandablePanelHeaderAlignment.center,
                      ),
                    );
                  }
                ),
            ],
          ),
        ),
      ),
    );
  }
}
