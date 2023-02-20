import 'package:blockies/blockies.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:candide_mobile_app/utils/events.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wallet_dart/wallet/account.dart';

class AccountNameEditDialog extends StatefulWidget {
  final Account account;
  const AccountNameEditDialog({Key? key, required this.account}) : super(key: key);

  @override
  State<AccountNameEditDialog> createState() => _AccountNameEditDialogState();
}

class _AccountNameEditDialogState extends State<AccountNameEditDialog> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  String _newAccountName = "";

  @override
  void initState() {
    _newAccountName = widget.account.name;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(70),
              child: Blockies(
                seed: widget.account.address.hexEip55 + widget.account.chainId.toString(),
                color: Get.theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 10,),
          Text(Utils.truncate(widget.account.address.hex, leadingDigits: 4, trailingDigits: 4), textAlign: TextAlign.center, style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 12)),
          Form(
            key: formKey,
            child: TextFormField(
              initialValue: _newAccountName,
              autofocus: true,
              style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 35, decoration: TextDecoration.underline),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintStyle: TextStyle(fontSize: 15, decoration: TextDecoration.none, color: Colors.grey.withOpacity(0.25)),
                hintText: "Account name (e.g. 'main')",
                border: InputBorder.none,
              ),
              onChanged: (String value) => _newAccountName = value,
              onFieldSubmitted: (String value) => _newAccountName = value,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (String? value){
                if (value == null) return "required";
                if (value.trim().isEmpty) return "required";
                return null;
              },
            ),
          )
        ],
      ),
      actions: [
        TextButton(
          onPressed: (){
            if (widget.account.name.trim().isEmpty){
              formKey.currentState?.validate();
              return;
            }
            Get.back();
          },
          child: Text("Cancel", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold)),
        ),
        TextButton(
          onPressed: () async {
            if (_newAccountName.trim().isEmpty) {
              formKey.currentState?.validate();
              return;
            }
            widget.account.name = _newAccountName;
            await PersistentData.saveAccounts();
            eventBus.fire(OnAccountDataEdit());
            Get.back();
          },
          child: Text("Save", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold)),
        ),
      ],
    );
  }
}
