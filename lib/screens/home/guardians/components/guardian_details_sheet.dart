import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:candide_mobile_app/screens/components/continous_input_border.dart';
import 'package:candide_mobile_app/screens/components/summary_table.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart' as intl;

class GuardianDetailsSheet extends StatefulWidget {
  final AccountGuardian guardian;
  final VoidCallback onPressDelete;
  final Widget logo;
  const GuardianDetailsSheet({Key? key, required this.guardian, required this.logo, required this.onPressDelete}) : super(key: key);

  @override
  State<GuardianDetailsSheet> createState() => _GuardianDetailsCardState();
}

class _GuardianDetailsCardState extends State<GuardianDetailsSheet> {
  late final StreamSubscription transactionStatusSubscription;
  final TextEditingController nicknameController = TextEditingController();
  final FocusNode nicknameFocus = FocusNode();

  saveNickname(String newNickname) async {
    widget.guardian.nickname = newNickname;
    await PersistentData.storeGuardians(PersistentData.selectedAccount);
    BotToast.showText(
      text: "New nickname saved!",
      textStyle: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Colors.black),
      contentColor: Get.theme.colorScheme.primary,
      align: Alignment.topCenter,
    );
  }


  @override
  void initState(){
    if (widget.guardian.nickname == null || widget.guardian.nickname!.isEmpty){
      nicknameController.text = "";
    }else{
      nicknameController.text = widget.guardian.nickname!;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String title = widget.guardian.type.replaceAll("-", " ").capitalize!;
    if (widget.guardian.type == "magic-link"){
      title = "Email Recovery";
    }
    if (widget.guardian.type == "hardware-wallet"){
      title = "Hardware Wallet";
    }
    String dateAdded;
    if (widget.guardian.creationDate == null) {
      dateAdded = "Unknown";
    } else {
      dateAdded = intl.DateFormat.yMMMMd().format(widget.guardian.creationDate!);
    }

    return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            controller: Get.find<ScrollController>(tag: "guardian_details_modal"),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth, minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    const SizedBox(height: 15,),
                    Text("Recovery Contact Details", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 20),),
                    const SizedBox(height: 50,),
                    Transform.scale(
                        scale: 2.5,
                        child: widget.logo
                    ),
                    const SizedBox(height: 50,),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 15),
                      child: TextFormField(
                        controller: nicknameController,
                        focusNode: nicknameFocus,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 25),
                        decoration: const InputDecoration(
                          label: Text("Nickname", style: TextStyle(fontSize: 25),),
                          border: ContinousInputBorder(
                            borderSide: BorderSide(color: Colors.transparent),
                            borderRadius: BorderRadius.all(Radius.circular(35)),
                          ),
                        ),
                        onFieldSubmitted: (value) => saveNickname(value),
                      ),
                    ),
                    const SizedBox(height: 20,),
                    widget.guardian.type == "magic-link"
                        ? Text(widget.guardian.email!, style: const TextStyle(fontSize: 15, color: Colors.grey))
                        : const SizedBox.shrink(),
                    const SizedBox(height: 15,),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: Get.width * 0.03),
                      child: SummaryTable(
                        entries: [
                          SummaryTableEntry(
                            title: "Address",
                            value: Utils.truncate(widget.guardian.address, trailingDigits: 4),
                            trailing: IconButton(
                              splashRadius: 12,
                              style: const ButtonStyle(
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: (){
                                Utils.copyText(widget.guardian.address, message: "Address copied to clipboard!");
                              },
                              icon: Icon(PhosphorIcons.copyLight, color: Get.theme.colorScheme.primary , size: 20),
                            ),
                          ),
                          SummaryTableEntry(
                            title: "Connection",
                            value: title,
                          ),
                          SummaryTableEntry(
                            title: "Date Added",
                            value: dateAdded,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20,),
                    ElevatedButton(
                      onPressed: (){
                        Get.back();
                        widget.onPressDelete();
                      },
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.orange[600]),
                      ),
                      child: Text("Remove", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 17),),
                    ),
                    const Spacer(),
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