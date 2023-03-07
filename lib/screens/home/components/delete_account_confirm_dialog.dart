import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/screens/components/continous_input_border.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wallet_dart/wallet/account.dart';

class DeleteAccountConfirmDialog extends StatefulWidget {
  final Account account;
  const DeleteAccountConfirmDialog({Key? key, required this.account}) : super(key: key);

  @override
  State<DeleteAccountConfirmDialog> createState() => _DeleteAccountConfirmDialogState();
}

class _DeleteAccountConfirmDialogState extends State<DeleteAccountConfirmDialog> {
  String confirmationInput = "";
  bool confirmEnabled = false;

  @override
  Widget build(BuildContext context) {
    confirmEnabled = confirmationInput.toLowerCase() == "i understand";
    return AlertDialog(
      title: const Text("Are you sure ?"),
      insetPadding: const EdgeInsets.symmetric(horizontal: 25),
      titlePadding: const EdgeInsets.only(left: 18, right: 18, top: 20),
      contentPadding: const EdgeInsets.only(left: 18, right: 18, top: 10, bottom: 24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const Text("You are about to delete your account from this device. \n\nYou will need your Guardians and this wallet's public address to regain access to your wallet again"),
          Text("\nAccount name: ${widget.account.name}", style: const TextStyle(fontWeight: FontWeight.bold),),
          Text("Account network: ${Networks.getByChainId(widget.account.chainId)!.name}", style: const TextStyle(fontWeight: FontWeight.bold),),
          const SizedBox(height: 10,),
          RichText(
            text: TextSpan(
              text: "To delete this account, please write\n'",
              style: const TextStyle(fontSize: 15),
              children: [
                TextSpan(
                  text: "I understand",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[900])
                ),
                const TextSpan(
                  text: "' below."
                )
              ]
            ),
          ),
          const SizedBox(height: 10,),
          TextFormField(
            style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              label: Text("Write here", textAlign: TextAlign.center,),
              border: ContinousInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(35)),
              ),
            ),
            onChanged: (val) => setState(() => confirmationInput = val),
          ),
          const SizedBox(height: 10,),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () async {
                  Get.back();
                },
                style: ButtonStyle(
                  minimumSize: MaterialStateProperty.all(Size(Get.width * 0.30, 40)),
                  backgroundColor: MaterialStateProperty.all(Colors.transparent),
                  elevation: MaterialStateProperty.all(0),
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                      side: BorderSide(color: Get.theme.colorScheme.primary)
                  ))
                ),
                child: Text("Cancel", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Get.theme.colorScheme.primary),),
              ),
              const SizedBox(width: 15,),
              ElevatedButton(
                onPressed: confirmEnabled ? (){
                  Get.back(result: true);
                } : null,
                style: ButtonStyle(
                    minimumSize: MaterialStateProperty.all(Size(Get.width * 0.30, 40)),
                    elevation: MaterialStateProperty.all(0),
                    shape: MaterialStateProperty.all(RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                        side: BorderSide(color: confirmEnabled ? Get.theme.colorScheme.primary : Colors.grey.withOpacity(0.25))
                    ))
                ),
                child: Text("Confirm", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
