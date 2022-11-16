import 'dart:async';

import 'package:blockies/blockies.dart';
import 'package:candide_mobile_app/screens/components/continous_input_border.dart';
import 'package:candide_mobile_app/screens/home/components/address_qr_scanner.dart';
import 'package:candide_mobile_app/utils/constants.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:ens_dart/ens_dart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AddressField extends StatefulWidget {
  final String hint;
  final bool filled;
  final Function(String) onAddressChanged;
  final Function(Map?) onENSChange;
  final Widget qrAlertWidget;
  const AddressField({Key? key, required this.onAddressChanged, required this.onENSChange, required this.hint, this.filled=true, required this.qrAlertWidget}) : super(key: key);

  @override
  State<AddressField> createState() => _AddressFieldState();
}

class _AddressFieldState extends State<AddressField> {
  final TextEditingController _addressController = TextEditingController();
  //
  bool _correctAddress = false;
  String address = "";
  //
  RegExp ensRegex = RegExp(r"^.*\.[A-Za-z]{2,}");
  String? ensError = "";
  bool ensTimerActive = false;
  Timer? ensTimer;
  Map? _ensResponse;
  //
  // Starts/restarts ENS Timer, or stops the timer if regex doesn't match
  void restartENSListener() async {
    if (!ensRegex.hasMatch(address)){
      if (!ensTimerActive) return;
      setState(() {
        ensTimer?.cancel();
        ensError = "";
        ensTimerActive = false;
      });
      return;
    }
    ensTimer?.cancel();
    setState((){
      ensError = "";
      ensTimerActive = true;
      ensTimer = Timer(const Duration(milliseconds: 500), retrieveENS);
    });
  }

  void retrieveENS() async {
    if (_ensResponse != null){
      if (_ensResponse!["lastEns"] == address) return;
    }
    if (!ensRegex.hasMatch(address)) return;
    //
    final _ensAddress = await Constants.ens.withName(address.toLowerCase()).getAddress();
    //
    if (_ensAddress.hex == Constants.addressZeroHex){
      setState(() {
        ensError = "ENS domain not found";
        _correctAddress = false;
        _ensResponse = null;
        ensTimerActive = false;
      });
    }else{
      setState(() {
        ensError = "";
        _ensResponse = {};
        _ensResponse!["address"] = _ensAddress.hex;
        _ensResponse!["lastEns"] = address;
        widget.onENSChange(_ensResponse!);
        _correctAddress = true;
        ensTimerActive = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            alignment: Alignment.centerLeft,
            child: TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                hintText: widget.hint,
                filled: widget.filled,
                fillColor: Get.theme.cardColor,
                border: const ContinousInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(35),)
                ),
                suffixIcon: _ensResponse == null ? (!ensTimerActive ? IconButton(
                  onPressed: (){
                    showBarModalBottomSheet(
                      context: context,
                      builder: (context) {
                        return AddressQRScanner(
                          onScanAddress: (_address){
                            address = _address;
                            _addressController.text = address;
                            setState(() {
                              _correctAddress = true;
                            });
                            widget.onAddressChanged(address);
                          },
                          alertWidget: widget.qrAlertWidget,
                        );
                      },
                    );
                  },
                  icon: const Icon(PhosphorIcons.scanBold),
                ) : Transform.scale(
                  scale: 0.3,
                  child: const CircularProgressIndicator(strokeWidth: 13,)
                )) : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // added line
                  mainAxisSize: MainAxisSize.min, // added line
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.green,),
                    IconButton(
                      onPressed: (){
                        setState((){
                          address = "";
                          _addressController.text = address;
                          _ensResponse = null;
                          widget.onENSChange(null);
                        });
                      },
                      icon: const Icon(Icons.close),
                    )
                  ],
                ),
                prefixIcon: _ensResponse != null ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 7),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Blockies(
                      seed: _ensResponse!["address"],
                      color: Get.theme.colorScheme.primary,
                      size: 10,
                    ),
                  ),
                ) : null,
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return 'required';
                if (!Utils.isValidAddress(val) && !ensRegex.hasMatch(address)){
                  return 'Invalid address';
                }
                if (ensError?.isNotEmpty ?? false) return ensError;
                return null;
              },
              onChanged: (val){
                if (val != address){
                  if (_ensResponse != null){
                    setState(() => _ensResponse = null);
                    widget.onENSChange(null);
                  }
                }
                address = val;
                restartENSListener();
                if (!Utils.isValidAddress(address)){
                  if (_correctAddress){
                    widget.onAddressChanged(address);
                    setState(() => _correctAddress = false);
                  }
                }else{
                  if (!_correctAddress){
                    widget.onAddressChanged(address);
                    setState(() => _correctAddress = true);
                  }
                }
              },
              autovalidateMode: AutovalidateMode.onUserInteraction,
            )
        ),
        SizedBox(height: _ensResponse != null ? 5 : 0,),
        _ensResponse != null ? Container(
          margin: const EdgeInsets.only(left: 15),
          alignment: Alignment.centerLeft,
          child: RichText(
            text: TextSpan(
                text: address.toLowerCase(),
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade400),
                children: [
                  const TextSpan(
                      text: " resolves to:\n",
                      style: TextStyle(color: Colors.white)
                  ),
                  TextSpan(
                      text: _ensResponse!["address"],
                      style: const TextStyle(color: Colors.grey, fontSize: 12)
                  )
                ]
            ),
          ),
        ) : const SizedBox.shrink(),
      ],
    );
  }
}
