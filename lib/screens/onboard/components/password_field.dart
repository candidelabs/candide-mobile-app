import 'package:fancy_password_field/fancy_password_field.dart';
import 'package:flutter/material.dart';

class PasswordField extends StatefulWidget {
  final FancyPasswordController passwordController;
  final FocusNode nextFocusNode;
  final double horizontalMargin;
  final bool showRules;
  const PasswordField({
    Key? key,
    required this.passwordController,
    required this.nextFocusNode,
    this.horizontalMargin = 35,
    required this.showRules,
    required this.onChange,
  }) : super(key: key);

  final Function(String) onChange;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _isObscured = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: widget.horizontalMargin),
        child: FancyPasswordField(
          passwordController: widget.passwordController,
          textInputAction: TextInputAction.next,
          hasValidationRules: true,
          obscureText: _isObscured,
          hasShowHidePassword: false,
          decoration: InputDecoration(
            label: const Text("Password"),
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
          onChanged: (value) => widget.onChange.call(value),
          onFieldSubmitted: (_) => widget.nextFocusNode.requestFocus(),
          strengthIndicatorBuilder: (strength) {
            return const SizedBox.shrink();
          },
          validationRules: {
            DigitValidationRule(),
            UppercaseValidationRule(),
            LowercaseValidationRule(),
            SpecialCharacterValidationRule(),
            MinCharactersValidationRule(6),
          },
          validationRuleBuilder: (rules, value) {
            if (!widget.showRules) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.only(top: 10),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (var rule in rules)
                      Builder(
                        builder: (context) {
                          final ruleValidated = rule.validate(value);
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(
                                ruleValidated ? Icons.check : Icons.close,
                                color: ruleValidated ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                rule.name,
                                style: TextStyle(
                                  color: ruleValidated ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          );
                        }
                      ),
                  ],
                ),
              )
            );
          },
        ),
      ),
    );
  }
}