import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:candide_mobile_app/screens/home/components/address_field.dart';
import 'package:candide_mobile_app/screens/home/components/address_qr_scanner.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SendToSheet extends StatefulWidget {
  final Function(String) onNext;
  const SendToSheet({Key? key, required this.onNext}) : super(key: key);

  @override
  State<SendToSheet> createState() => _SendToSheetState();
}

class _SendToSheetState extends State<SendToSheet> {
  String address = "";
  Map? _ensResponse = null;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          controller: Get.find<ScrollController>(tag: "send_modal"),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth, minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  const SizedBox(height: 15,),
                  Text("Send", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 20),),
                  const SizedBox(height: 35,),
                  Container(
                    margin: const EdgeInsets.only(left: 15),
                    alignment: Alignment.centerLeft,
                    child: Text("To", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 20),)
                  ),
                  AddressField(
                    onAddressChanged: (val){
                      setState(() => address = val);
                    },
                    onENSChange: (Map? ens) {
                      setState(() => _ensResponse = ens);
                    },
                    hint: "Public address (0x)",
                    scanENS: false,
                    qrAlertWidget: const QRAlertFundsLoss(),
                  ),
                  const SizedBox(height: 25,),
                  Container(
                      margin: const EdgeInsets.only(left: 15),
                      alignment: Alignment.centerLeft,
                      child: Text("Recent", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Colors.grey, fontSize: 20),)
                  ),
                  PersistentData.contacts.isEmpty ? Container(
                    margin: const EdgeInsets.only(top: 25),
                    child: const Text("No recent contacts", style: TextStyle(color: Colors.grey),)
                  ) : Container(),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: Utils.isValidAddress(address) || _ensResponse != null ? (){
                      if (_ensResponse != null){
                        widget.onNext.call(_ensResponse!["address"]);
                        return;
                      }
                      widget.onNext.call(address);
                    } : null,
                    style: ButtonStyle(
                      minimumSize: MaterialStateProperty.all(Size(Get.width * 0.8, 35)),
                      shape: MaterialStateProperty.all(const BeveledRectangleBorder(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(7),
                        ),
                      )),
                    ),
                    child: Text("Next", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 18),),
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

