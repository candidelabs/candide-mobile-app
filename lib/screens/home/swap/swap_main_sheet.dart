import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/swap.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:candide_mobile_app/services/explorer.dart';
import 'package:candide_mobile_app/screens/components/continous_input_border.dart';
import 'package:candide_mobile_app/screens/components/summary_table.dart';
import 'package:candide_mobile_app/screens/home/components/currency_selection_sheet.dart';
import 'package:candide_mobile_app/utils/currency.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class SwapMainSheet extends StatefulWidget {
  final Function(TokenInfo, BigInt, TokenInfo, OptimalQuote) onPressReview;
  const SwapMainSheet({Key? key, required this.onPressReview}) : super(key: key);

  @override
  State<SwapMainSheet> createState() => _SwapMainSheetState();
}

class _SwapMainSheetState extends State<SwapMainSheet> {
  final TextEditingController _baseController = TextEditingController(text: "0.0");
  final FocusNode _baseFocusNode = FocusNode();
  //
  String errorMessage = "Swapping amount must be greater than zero";
  final _errors = {
    "balance": "Insufficient Balance",
    "zero": "Swapping amount must be greater than zero",
    "liquidity": "Not enough liquidity",
  };
  //
  TokenInfo baseCurrency = TokenInfoStorage.getTokenBySymbol("ETH")!;
  BigInt actualAmount = BigInt.zero;
  double amount = 0.0;
  //
  TokenInfo quoteCurrency = TokenInfoStorage.getTokenBySymbol("UNI")!;
  OptimalQuote? quote;
  BigInt _lastFetchedActualAmount = BigInt.zero;
  bool _retrievingSwapData = false;
  bool showTable = false;
  //
  bool listenToFocus = true;
  //
  getSwapData() async {
    if (_retrievingSwapData) return;
    var cancelLoad = Utils.showLoading();
    _retrievingSwapData = true;
    // Fix a bug where handleFocus is called endlessly after swapCurrencies
    listenToFocus = false;
    //
    quote = await Explorer.fetchSwapQuote(Networks.selected().name, baseCurrency, quoteCurrency, actualAmount, PersistentData.selectedAccount.address.hex);
    _retrievingSwapData = false;
    _lastFetchedActualAmount = actualAmount;
    Future.delayed(const Duration(milliseconds: 350), (){
      listenToFocus = true;
    });
    cancelLoad();
    if (quote == null) {
      errorMessage = _errors['liquidity']!;
      setState(() {});
      return;
    }
    setState(() => showTable = true);
  }

  swapCurrencies() async {
    setState(() {
      var tempBaseCurrency = baseCurrency;
      baseCurrency = quoteCurrency;
      quoteCurrency = tempBaseCurrency;
      if (quote != null){
        amount = double.parse(CurrencyUtils.formatCurrency(quote!.amount, baseCurrency, includeSymbol: false));
        _baseController.text = "$amount";
      }
    });
    if (amount > 0){
      getSwapData();
    }
  }

  handleFocus(bool hasFocus){
    if (!listenToFocus) return;
    //
    if (!hasFocus){
      if (!_baseController.value.text.contains("<")){
        _validateAmountInput(_baseController.value.text);
      }
      if (actualAmount != _lastFetchedActualAmount && actualAmount > BigInt.zero){
        getSwapData();
      }
      if (!_baseController.value.text.contains("<")){
        _baseController.text = "$amount";
      }
    }
  }

  void _validateAmountInput(String input, {bool setActualAmount=true}){
    if (showTable){
      setState(() => showTable = false);
    }
    if (input.isEmpty || input == "."){
      input = "0";
    }
    amount = double.parse(input);
    if (setActualAmount){
      actualAmount = CurrencyUtils.parseCurrency(amount.toString(), baseCurrency);
    }
    if (actualAmount == BigInt.zero){
      if (errorMessage != _errors["zero"]) {
        setState(() {
          errorMessage = _errors["zero"]!;
        });
      }
    }else if (actualAmount > PersistentData.getCurrencyBalance(baseCurrency.address.toLowerCase())){
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
  //

  @override
  Widget build(BuildContext context) {
    bool isKeyboardShowing = MediaQuery.of(context).viewInsets.vertical > 0;
    if (!isKeyboardShowing){
      handleFocus(false);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return KeyboardActions(
          config: Utils.getiOSNumericKeyboardConfig(context, _baseFocusNode),
          child: SingleChildScrollView(
            controller: Get.find<ScrollController>(tag: "swap_modal"),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth, minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const SizedBox(height: 25,),
                    Text("Swap", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 20),),
                    const SizedBox(height: 15,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: (){
                            _baseFocusNode.unfocus();
                            actualAmount = PersistentData.getCurrencyBalance(baseCurrency.address.toLowerCase());
                            amount = double.parse(CurrencyUtils.formatCurrency(actualAmount, baseCurrency, includeSymbol: false));
                            _baseController.text = "$amount";
                            _validateAmountInput(amount.toString(), setActualAmount: false);
                            if (amount.toString() == "0.0" && actualAmount > BigInt.zero){
                              _baseController.text = "<0.000001";
                            }
                          },
                          style: ButtonStyle(
                            padding: MaterialStateProperty.all(EdgeInsets.zero),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap
                          ),
                          child: Text("USE MAX", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),),
                        ),
                        const SizedBox(width: 25,),
                      ],
                    ),
                    Row(
                      children: [
                        const SizedBox(width: 25,),
                        Expanded(
                          child: _CurrencySelector(
                            currency: baseCurrency,
                            onChange: (currency){
                              if (currency == baseCurrency) return;
                              if (currency == quoteCurrency){
                                swapCurrencies();
                                return;
                              }
                              setState(() => baseCurrency = currency);
                            },
                          ),
                        ),
                        const SizedBox(width: 12.5,),
                        Expanded(
                          child: Focus(
                            onFocusChange: (hasFocus){
                              handleFocus(hasFocus);
                            },
                            child: TextFormField(
                              controller: _baseController,
                              focusNode: _baseFocusNode,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\.?\d*(?<!\.)\.?\d*'))],
                              style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 25),
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 10),
                                border: ContinousInputBorder(
                                  borderRadius: const BorderRadius.all(Radius.circular(25)),
                                  borderSide: BorderSide(color: Get.theme.colorScheme.primary)
                                )
                              ),
                              onChanged: (val){
                                _validateAmountInput(val);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 25,),
                      ],
                    ),
                    const SizedBox(height: 10,),
                    Container(
                      margin: const EdgeInsets.only(right: 27),
                      alignment: Alignment.centerRight,
                      child: RichText(
                        text: TextSpan(
                          text: "Balance: ",
                          style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Colors.grey),
                          children: [
                            TextSpan(
                              text: "${CurrencyUtils.formatCurrency(PersistentData.getCurrencyBalance(baseCurrency.address.toLowerCase()), baseCurrency, includeSymbol: false, formatSmallDecimals: true)} ${baseCurrency.symbol}",
                              style: const TextStyle(color: Colors.white),
                            )
                          ]
                        ),
                      ),
                    ),
                    const SizedBox(height: 10,),
                    Card(
                      shape: ContinuousRectangleBorder(
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                      child: IconButton(
                        onPressed: (){
                          swapCurrencies();
                        },
                        icon: const Icon(FontAwesomeIcons.arrowDown),
                      ),
                    ),
                    const SizedBox(height: 20,),
                    Row(
                      children: [
                        const SizedBox(width: 25,),
                        Expanded(
                          child: _CurrencySelector(
                            currency: quoteCurrency,
                            onChange: (currency){
                              if (currency == quoteCurrency) return;
                              if (currency == baseCurrency){
                                swapCurrencies();
                                return;
                              }
                              setState(() => quoteCurrency = currency);
                            },
                          ),
                        ),
                        const SizedBox(width: 12.5,),
                        Expanded(
                          child: Container(
                            alignment: Alignment.center,
                            child: Text(CurrencyUtils.formatCurrency(quote?.amount ?? BigInt.zero, quoteCurrency, includeSymbol: false, formatSmallDecimals: true), style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 25)),
                          ),
                        ),
                        const SizedBox(width: 25,),
                      ],
                    ),
                    SizedBox(height: showTable ? 20 : 0,),
                    showTable ? Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      child: SummaryTable(entries: [
                        SummaryTableEntry(title: "Rate", value: CurrencyUtils.formatRate(baseCurrency, quoteCurrency, quote?.rate ?? BigInt.zero)),
                      ]),
                    ) : const SizedBox.shrink(),
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
                        widget.onPressReview.call(baseCurrency, actualAmount, quoteCurrency, quote!);
                      } : null,
                      style: ButtonStyle(
                        minimumSize: MaterialStateProperty.all(Size(Get.width * 0.8, 40)),
                        shape: MaterialStateProperty.all(const BeveledRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(7),
                          ),
                        )),
                      ),
                      child: Text("Review", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 18),),
                    ),
                    const SizedBox(height: 25,),
                  ],
                ),
              )
            ),
          ),
        );
      }
    );
  }
}



class _CurrencySelector extends StatelessWidget {
  final TokenInfo currency;
  final Function(TokenInfo) onChange;
  const _CurrencySelector({Key? key, required this.currency, required this.onChange}) : super(key: key);

  showCurrencySelectionModal(){
    showBarModalBottomSheet(
      context: Get.context!,
      backgroundColor: Get.theme.canvasColor,
      builder: (context) => SingleChildScrollView(
        controller: ModalScrollController.of(context),
        child: CurrenciesSelectionSheet(
          currencies: const ["ETH", "UNI"].map((e) => TokenInfoStorage.getTokenBySymbol(e)!).toList(),
          initialSelection: currency,
          forceVisibility: true,
          onSelected: (selectedCurrency){
            if (selectedCurrency != currency){
              onChange.call(selectedCurrency);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ElevatedButton.icon(
        onPressed: (){
          showCurrencySelectionModal();
        },
        style: ButtonStyle(
          minimumSize: MaterialStateProperty.all(const Size(0, 48)),
          backgroundColor: MaterialStateProperty.all(Get.theme.cardColor),
          elevation: MaterialStateProperty.all(5),
          shape: MaterialStateProperty.all(ContinuousRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(25)),
            side: BorderSide(color: Get.theme.colorScheme.primary)
          )),
        ),
        icon: Icon(Icons.arrow_drop_down, color: Get.theme.colorScheme.primary,),
        label: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(currency.symbol, style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 20, color: Get.theme.colorScheme.primary),),
            const SizedBox(width: 10,),
            /*SizedBox(
              width: 25,
              height: 25,
              child: CurrencyMetadata.metadata[currency]!.logo,
            ),*/
          ],
        ),
      ),
    );
  }
}

