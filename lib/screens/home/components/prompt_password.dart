import 'package:candide_mobile_app/config/theme.dart';
import 'package:flutter/material.dart';

class PromptPasswordDialog extends StatefulWidget {
  final Function(String) onConfirm;
  const PromptPasswordDialog({Key? key, required this.onConfirm}) : super(key: key);

  @override
  State<PromptPasswordDialog> createState() => _PromptPasswordDialogState();
}

class _PromptPasswordDialogState extends State<PromptPasswordDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  String password = "";

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Enter your password"),
      shape: const BeveledRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(15)
        )
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          obscureText: true,
          decoration: const InputDecoration(
            label: Text("Password"),
            border: OutlineInputBorder(
            ),
          ),
          validator: (val){
            if (val == null || val.isEmpty) return 'required';
            return null;
          },
          onChanged: (val) => password = val,
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        ElevatedButton(
          onPressed: (){
            if (!(_formKey.currentState?.validate() ?? false)) return;
            Navigator.pop(context);
            widget.onConfirm(password);
          },
          child: Text("Confirm", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),),
        ),
      ],
    );
  }
}
