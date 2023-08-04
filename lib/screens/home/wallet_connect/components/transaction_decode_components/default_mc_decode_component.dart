import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:candide_mobile_app/screens/home/wallet_connect/components/transaction_decode_components/default_decode_component.dart';
import 'package:candide_mobile_app/screens/home/wallet_connect/components/transaction_decode_components/known_params_component.dart';
import 'package:candide_mobile_app/screens/home/wallet_connect/components/transaction_decode_components/wc_approve_component.dart';
import 'package:candide_mobile_app/services/transaction_decoder.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';

class DefaultMultiCallDecodeComponent extends StatefulWidget {
  final List<dynamic> params;
  const DefaultMultiCallDecodeComponent({Key? key, required this.params}) : super(key: key);

  @override
  State<DefaultMultiCallDecodeComponent> createState() => _DefaultMultiCallDecodeComponentState();
}

class _DefaultMultiCallDecodeComponentState extends State<DefaultMultiCallDecodeComponent> {
  List<dynamic> decodedDataLeadings = [];

  void decodeRequestData() async {
    List<dynamic> leadings = [];
    for (var call in widget.params[0]["calls"]){
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
              leadings.add([transactionDetails.functionName, WCApproveComponent(
                transactionDetails: transactionDetails,
                token: token,
                margin: EdgeInsets.zero,
                elevation: 0,
              )]);
            }
          }else{
            showKnownParamsComponent = true;
          }
        }
        if (showKnownParamsComponent){
          leadings.add([transactionDetails.functionName, KnownParamsComponent(
            transactionDetails: transactionDetails,
            margin: EdgeInsets.zero,
            elevation: 0,
          )]);
        }
      }else{
        leadings.add(["Unknown call", DefaultDecodedLeading(
          data: call["data"],
          margin: EdgeInsets.zero,
          elevation: 0,
        )]);
      }
    }
    setState(() {
      decodedDataLeadings.clear();
      decodedDataLeadings = leadings;
    });
  }

  @override
  void initState() {
    for (var call in widget.params[0]["calls"]){
      decodedDataLeadings.add(["...", DefaultDecodedLeading(
        data: call["data"],
        margin: EdgeInsets.zero,
      )]);
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
              for (int i=0; i < widget.params[0]["calls"].length; i++)
                Builder(
                  builder: (context) {
                    var call = widget.params[0]["calls"][i];
                    if (decodedDataLeadings.length-1 < i) return const SizedBox.shrink();
                    return ExpandablePanel(
                      header: Row(
                        children: [
                          RichText(
                            text: TextSpan(
                              text: "#${i+1} ",
                              style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 8, color: Colors.grey),
                              children: [
                                TextSpan(
                                  text: Utils.truncate(decodedDataLeadings[i][0].toString(), leadingDigits: 20, trailingDigits: 0),
                                  style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 17, color: Colors.white),
                                )
                              ]
                            ),
                          ),
                          const Spacer(),
                          Text(Utils.truncate(call["to"], leadingDigits: 4, trailingDigits: 3), style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 10, color: Colors.grey),),
                        ],
                      ),
                      collapsed: const SizedBox.shrink(),
                      //expanded: const SizedBox.shrink(),
                      expanded: decodedDataLeadings[i][1],
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
