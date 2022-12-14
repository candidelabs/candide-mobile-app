import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/screens/components/continous_input_border.dart';
import 'package:candide_mobile_app/screens/home/components/address_field.dart';
import 'package:candide_mobile_app/screens/home/components/address_qr_scanner.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GuardianAddressSheet extends StatefulWidget {
  final Function(String, String?) onProceed;
  const GuardianAddressSheet({Key? key, required this.onProceed}) : super(key: key);

  @override
  State<GuardianAddressSheet> createState() => _GuardianAddressSheetState();
}

class _GuardianAddressSheetState extends State<GuardianAddressSheet> {
  String address = "";
  String? nickname = "";
  Map? ensResponse;
  bool valid = false;


  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 250),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        children: [
          const SizedBox(height: 15,),
          Text("Add guardian", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 20),),
          const SizedBox(height: 35,),
          AddressField(
            onAddressChanged: (val){
              setState(() => address = val);
            },
            onENSChange: (Map? ens) {
              setState(() => ensResponse = ens);
            },
            hint: "Guardian public address (0x), or ENS",
            filled: false,
            qrAlertWidget: const QRAlertGuardianAddressFail(),
          ),
          const SizedBox(height: 10,),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 15),
            child: TextFormField(
              style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),
              decoration: const InputDecoration(
                label: Text("Guardian nickname"),
                border: ContinousInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(35)),
                ),
              ),
              onChanged: (val) => nickname = val,
            ),
          ),
          const SizedBox(height: 25,),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 25),
            child: RichText(
              text: const TextSpan(
                  text: "* Your Guardian address is stored publicly on the blockchain. A good practice is to ask your guardian to give you a new address so they remain anonymous.",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 10,),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 25),
            width: Get.width,
            child: ElevatedButton(
              onPressed: Utils.isValidAddress(address) || ensResponse != null ? (){
                if (nickname?.removeAllWhitespace.isEmpty ?? true){
                  nickname = null;
                }
                if (ensResponse != null){
                  widget.onProceed.call(ensResponse!["address"], nickname);
                  return;
                }
                widget.onProceed.call(address, nickname);
              } : null,
              child: Text("Continue", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),),
            ),
          ),
          const SizedBox(height: 25,),
        ],
      ),
    );
  }
}
