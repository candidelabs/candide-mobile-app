import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/screens/onboard/components/chain_selector.dart';
import 'package:flutter/material.dart';
import 'package:info_popup/info_popup.dart';
import 'package:lottie/lottie.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class CreateAccountChainScreen extends StatefulWidget {
  final String confirmButtonLabel;
  final VoidCallback? onBack;
  final Function(String, int) onNext;
  const CreateAccountChainScreen({Key? key, required this.onNext, this.onBack, this.confirmButtonLabel="Next"}) : super(key: key);

  @override
  State<CreateAccountChainScreen> createState() => _CreateAccountChainScreenState();
}

class _CreateAccountChainScreenState extends State<CreateAccountChainScreen> {
  String name = "";
  int chainId = Networks.instances[0].chainId.toInt();

  bool isValidName(String name){
    /*RegExp regexp = RegExp(r"^[a-zA-Z0-9\-]+$");
    if (!regexp.hasMatch(name)) return false;
    if (name.startsWith("-") || name.endsWith("-")) return false;*/
    if (name.trim().isEmpty) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints){
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth, minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  widget.onBack != null ? Container(
                    margin: const EdgeInsets.only(left: 15, top: 10),
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  ) : const SizedBox.shrink(),
                  Lottie.asset('assets/animations/wallet-info.json', width: 200, reverse: true),
                  const SizedBox(height: 25,),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 15),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: "Choose the ",
                        style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 18),
                        children: const [
                          TextSpan(
                            text: "chain",
                            style: TextStyle(color: Colors.deepOrange),
                          ),
                          TextSpan(
                            text: " on which your account will be created in. and choose a ",
                          ),
                          TextSpan(
                            text: "name",
                            style: TextStyle(color: Colors.deepOrange),
                          ),
                          TextSpan(
                            text: " for your account.",
                          ),
                        ]
                      )
                    ),
                  ),
                  const SizedBox(height: 25,),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    child: ChainSelector(
                      selectedChainId: chainId,
                      onSelect: (_chainId){
                        setState(() {
                          chainId = _chainId;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 25,),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 25),
                    child: TextFormField(
                      decoration: InputDecoration(
                        label: const Text("Account name"),
                        hintText: "e.g. john-${Networks.getByChainId(chainId)!.name.toLowerCase().replaceAll(" ", "-")}",
                        suffixIcon: InfoPopupWidget(
                          arrowTheme: InfoPopupArrowTheme(
                            color: Colors.black.withOpacity(0.8),
                          ),
                          customContent: Container(
                            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(8)
                            ),
                            child: const Text("This name is stored locally and will never be shared with us or any third parties."),
                          ),
                          child: const Icon(
                            Icons.info,
                          ),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (String? input){
                        input ??= "";
                        if ((input).trim().isEmpty) return "Account name required.";
                        if (!isValidName(input)) return "Invalid account name";
                        return null;
                      },
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      onChanged: (value) => setState(() => name = value),
                    ),
                  ),
                  const SizedBox(height: 12,),
                  _AccountChainAlert(network: Networks.getByChainId(chainId)!,),
                  const SizedBox(height: 12,),
                  ElevatedButton(
                    onPressed: !isValidName(name) ? null : (){
                      widget.onNext.call(name, chainId);
                    },
                    style: ButtonStyle(
                      shape: MaterialStateProperty.all(RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)
                      )),
                    ),
                    child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Text(widget.confirmButtonLabel, style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),)
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AccountChainAlert extends StatelessWidget {
  final Network network;
  const _AccountChainAlert({Key? key, required this.network}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      margin: const EdgeInsets.symmetric(horizontal: 25),
      decoration: BoxDecoration(
        color: network.color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const  SizedBox(width: 5,),
          Icon(PhosphorIcons.info, color: network.color,),
          const SizedBox(width: 5,),
          Flexible(
            child: RichText(
              textAlign: TextAlign.start,
              text: TextSpan(
                  text: "The account will",
                  style: TextStyle(fontSize: 12, fontFamily: AppThemes.fonts.gilroy, color: network.color),
                  children: [
                    TextSpan(
                      text: " only ",
                      style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold)
                    ),
                    const TextSpan(
                      text: "be available on ",
                    ),
                    TextSpan(
                        text: network.name,
                        style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold)
                    ),
                    const TextSpan(
                      text: " chain.",
                    ),
                  ]
              ),
            ),
          ),
          const SizedBox(width: 5,),
        ],
      ),
    );
  }
}
