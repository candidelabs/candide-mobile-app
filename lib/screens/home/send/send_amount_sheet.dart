import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:candide_mobile_app/screens/home/components/transaction/currency_selection_sheet.dart';
import 'package:candide_mobile_app/utils/constants.dart';
import 'package:candide_mobile_app/utils/currency.dart';
import 'package:candide_mobile_app/utils/extensions/decimal_extensions.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class SendAmountSheet extends StatefulWidget {
  final VoidCallback onPressBack;
  final Function(TokenInfo, BigInt) onPressReview;
  const SendAmountSheet({Key? key, required this.onPressBack, required this.onPressReview}) : super(key: key);

  @override
  State<SendAmountSheet> createState() => _SendAmountSheetState();
}

class _SendAmountSheetState extends State<SendAmountSheet> {
  final FocusNode _amountFocus = FocusNode();
  final TextEditingController _amountController = TextEditingController();
  TokenInfo selectedToken = TokenInfoStorage.getTokenBySymbol(Networks.selected().nativeCurrency)!;
  String errorMessage = "Sending amount must be greater than zero";
  final _errors = {
    "balance": "Insufficient Balance",
    "zero": "Sending amount must be greater than zero",
  };
  BigInt actualAmount = BigInt.zero;
  Decimal amount = Decimal.zero;
  //
  @override
  void initState() {
    _amountController.text = "${amount.toTrimmedStringAsFixed(selectedToken.decimals)} ${selectedToken.symbol}";
    _amountFocus.addListener((){
      if (_amountFocus.hasFocus){
        _amountController.text = amount.toTrimmedStringAsFixed(selectedToken.decimals);
      }else{
        if (_amountController.value.text.contains("<")) return;
        amount = Decimal.parse(_amountController.value.text.isEmpty ? "0" : _amountController.value.text);
        _amountController.text = "${amount.toTrimmedStringAsFixed(selectedToken.decimals)} ${selectedToken.symbol}";
      }
    });
    super.initState();
  }
  //

  showCurrencySelectionModal(){
    showBarModalBottomSheet(
      context: context,
      backgroundColor: Get.theme.canvasColor,
      builder: (context) => SingleChildScrollView(
        controller: ModalScrollController.of(context),
        child: CurrenciesSelectionSheet(
          currencies: TokenInfoStorage.tokens.where((element) => element.address == Constants.addressZeroHex || PersistentData.getCurrencyBalance(element.address.toLowerCase()) > BigInt.zero).toList(),
          initialSelection: selectedToken,
          onSelected: (token){
            setState(() {
              if (selectedToken != token){
                amount = Decimal.zero;
              }
              selectedToken = token;
              _amountController.text = "${amount.toTrimmedStringAsFixed(selectedToken.decimals)} ${selectedToken.symbol}";
              _validateAmountInput(amount.toTrimmedStringAsFixed(selectedToken.decimals));
            });
          },
        ),
      ),
    );
  }

  void _validateAmountInput(String input, {bool setActualAmount=true}){
    if (input.isEmpty || input == "."){
      input = "0";
    }
    amount = Decimal.parse(input);
    if (setActualAmount){
      actualAmount = CurrencyUtils.parseCurrency(amount.toTrimmedStringAsFixed(selectedToken.decimals), selectedToken);
    }
    if (actualAmount == BigInt.zero){
      if (errorMessage != _errors["zero"]) {
        setState(() {
          errorMessage = _errors["zero"]!;
        });
      }
    }else if (actualAmount > PersistentData.getCurrencyBalance(selectedToken.address.toLowerCase())){
      if (errorMessage != _errors["balance"]){
        setState(() {
          errorMessage = _errors["balance"]!;
        });
      }
    }else if (errorMessage.isNotEmpty){
      setState(() {
        errorMessage = "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return KeyboardActions(
          config: Utils.getiOSNumericKeyboardConfig(context, _amountFocus),
          child: SingleChildScrollView(
            controller: Get.find<ScrollController>(tag: "send_modal"),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth, minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const SizedBox(height: 10,),
                    Row(
                      children: [
                        const SizedBox(width: 5,),
                        IconButton(
                          onPressed: (){
                            widget.onPressBack();
                          },
                          icon: const Icon(Icons.arrow_back),
                        ),
                        const Spacer(flex: 2,),
                        Text("Amount", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 20),),
                        const Spacer(flex: 3,),
                      ],
                    ),
                    const SizedBox(height: 25,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Spacer(flex: 2,),
                        const SizedBox(width: 10,),
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: ElevatedButton.icon(
                            onPressed: (){
                              showCurrencySelectionModal();
                            },
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(Colors.transparent),
                              elevation: MaterialStateProperty.all(0),
                              shape: MaterialStateProperty.all(ContinuousRectangleBorder(
                                borderRadius: const BorderRadius.all(Radius.circular(25)),
                                side: BorderSide(color: Get.theme.colorScheme.primary)
                              )),
                            ),
                            icon: Icon(Icons.arrow_drop_down, color: Get.theme.colorScheme.primary,),
                            label: Text(selectedToken.symbol, style: TextStyle(color: Get.theme.colorScheme.primary),),
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: (){
                            _amountFocus.unfocus();
                            actualAmount = PersistentData.getCurrencyBalance(selectedToken.address.toLowerCase());
                            amount = Decimal.parse(CurrencyUtils.formatCurrency(actualAmount, selectedToken, includeSymbol: false));
                            String _amountString = amount.toTrimmedStringAsFixed(selectedToken.decimals);
                            _amountController.text = "$_amountString ${selectedToken.symbol}";
                            _validateAmountInput(_amountString, setActualAmount: false);
                          },
                          child: Text("USE MAX", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),),
                        ),
                        const SizedBox(width: 10,)
                      ],
                    ),
                    const SizedBox(height: 35,),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 25),
                      child: TextFormField(
                        controller: _amountController,
                        focusNode: _amountFocus,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\.?\d*(?<!\.)\.?\d*'))],
                        style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 25),
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                        onChanged: (val){
                          _validateAmountInput(val);
                        },
                      ),
                    ),
                    const SizedBox(height: 35,),
                    RichText(
                      text: TextSpan(
                        text: "Balance: ${CurrencyUtils.formatCurrency(PersistentData.getCurrencyBalance(selectedToken.address.toLowerCase()), selectedToken, includeSymbol: false, formatSmallDecimals: true)} ",
                        style: TextStyle(
                          fontFamily: AppThemes.fonts.gilroyBold,
                          fontSize: 16
                        ),
                        children: [
                          TextSpan(
                            text: selectedToken.symbol,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          )
                        ]
                      ),
                    ),
                    const Spacer(),
                    errorMessage.isNotEmpty ? Container(
                      margin: EdgeInsets.symmetric(horizontal: Get.width * 0.1),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      width: double.maxFinite,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(
                          color: Colors.red,
                        )
                      ),
                      child: Center(
                        child: Text(errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red),)
                      ),
                    ) : const SizedBox.shrink(),
                    SizedBox(height: errorMessage.isNotEmpty ? 5 : 0,),
                    ElevatedButton(
                      onPressed: errorMessage.isEmpty ? (){
                        widget.onPressReview.call(selectedToken, actualAmount);
                      } : null,
                      style: ButtonStyle(
                        minimumSize: MaterialStateProperty.all(Size(Get.width * 0.8, 35)),
                        shape: MaterialStateProperty.all(const BeveledRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(7),
                          ),
                        )),
                      ),
                      child: Text("Send", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 18),),
                    ),
                    const SizedBox(height: 25,),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    );
  }
}

