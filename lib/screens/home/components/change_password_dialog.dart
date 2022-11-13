import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/screens/onboard/components/credentials_entry.dart';
import 'package:flutter/material.dart';

class ChangePasswordDialog extends StatefulWidget {
  final Function(String) onConfirm;
  const ChangePasswordDialog({Key? key, required this.onConfirm}) : super(key: key);

  @override
  State<ChangePasswordDialog> createState() => _PromptPasswordDialogState();
}

class _PromptPasswordDialogState extends State<ChangePasswordDialog> {

  @override
  Widget build(BuildContext context) {
    return AlertDialog(

      title: const Text("Enter a new password"),
      shape: const BeveledRectangleBorder(
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(15)
          )
      ),
      content: CredentialsEntry(
        horizontalMargin: 0,
        showBiometricsOption: false,
        disable: false,
        onConfirm: (String password, _){
          widget.onConfirm(password);
        },
        confirmButtonText: 'Confirm',
      ),
    );
  }
}