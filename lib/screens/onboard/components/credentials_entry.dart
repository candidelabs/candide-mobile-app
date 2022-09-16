import 'package:biometric_storage/biometric_storage.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/screens/onboard/components/password_field.dart';
import 'package:fancy_password_field/fancy_password_field.dart';
import 'package:flutter/material.dart';

class CredentialsEntry extends StatefulWidget {
  final double horizontalMargin;
  final String confirmButtonText;
  final bool disable;
  final Function(String, bool) onConfirm;
  const CredentialsEntry({Key? key, required this.confirmButtonText, required this.onConfirm, this.horizontalMargin=35, this.disable=false}) : super(key: key);

  @override
  State<CredentialsEntry> createState() => _CredentialsEntryState();
}

class _CredentialsEntryState extends State<CredentialsEntry> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  final FancyPasswordController _passwordController = FancyPasswordController();
  final FocusNode _confirmPasswordNode = FocusNode();
  //
  bool _isObscured = true;
  bool _showPasswordRules = false;
  String password = "";
  String confirmPassword = "";
  bool biometricsEnabled = false;
  bool _showBiometricsAuth = false;
  //
  initialize() async {
    final response = await BiometricStorage().canAuthenticate();
    if (response == CanAuthenticateResponse.success){
      setState(() => _showBiometricsAuth = true);
    }
  }

  @override
  void initState() {
    initialize();
    super.initState();
  }
  //
  void onConfirmPress() async {
    if (password.isEmpty || !_passwordController.areAllRulesValidated){
      setState(() => _showPasswordRules = true);
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)){
      return;
    }
    widget.onConfirm.call(password, biometricsEnabled);
    return;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          PasswordField(
            onChange: (value) => password = value,
            horizontalMargin: widget.horizontalMargin,
            passwordController: _passwordController,
            nextFocusNode: _confirmPasswordNode,
            showRules: _showPasswordRules,
          ),
          const SizedBox(height: 25,),
          Container(
            margin: EdgeInsets.symmetric(horizontal: widget.horizontalMargin),
            child: TextFormField(
              focusNode: _confirmPasswordNode,
              obscureText: _isObscured,
              decoration: InputDecoration(
                  label: const Text("Confirm Password"),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: (){
                      setState(() {
                        _isObscured = !_isObscured;
                      });
                    },
                    icon: Icon(_isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  )
              ),
              validator: (input){
                if (input != password) return "Passwords don't match";
                return null;
              },
              onChanged: (value) => confirmPassword = value,
            ),
          ),
          _showBiometricsAuth ? Container(
            margin: const EdgeInsets.only(top: 10),
            child: SwitchListTile(
              value: biometricsEnabled,
              activeColor: Colors.blue,
              title: const Text("Use biometrics for authentication", textAlign: TextAlign.center, style: TextStyle(fontSize: 14),),
              onChanged: (val) => setState(() => biometricsEnabled = val),
            ),
          ) : const SizedBox.shrink(),
          ElevatedButton(
            onPressed: widget.disable ? null : onConfirmPress,
            style: ButtonStyle(
              shape: MaterialStateProperty.all(RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)
              )),
            ),
            child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Text(widget.confirmButtonText, style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),)
            ),
          ),
        ],
      ),
    );
  }
}
