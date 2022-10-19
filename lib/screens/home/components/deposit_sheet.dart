import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class DepositSheet extends StatefulWidget {
  final String address;
  const DepositSheet({Key? key, required this.address}) : super(key: key);

  @override
  State<DepositSheet> createState() => _DepositSheetState();
}

class _DepositSheetState extends State<DepositSheet> {
  bool _addressCopied = false;


  copyAddress() async {
    Clipboard.setData(ClipboardData(text: widget.address));
    setState(() => _addressCopied = true);
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    setState(() => _addressCopied = false);
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Get.theme.colorScheme.primary,
      ),
      child: Stack(
        children: [
          Positioned(
            width: Get.width,
            bottom: 0,
            child: Opacity(
              opacity: 0.25,
              child: Image.asset("assets/images/optimism_fund_background.png",),
            )
          ),
          Column(
            children: [
              const SizedBox(height: 35,),
              const Text("Fund your", style: TextStyle(fontSize: 20, color: Colors.black),),
              const SizedBox(height: 5,),
              Text("GÖERLI", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 30, color: Colors.red, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),),
              //SvgPicture.asset("assets/images/optimism_title.svg"),
              const SizedBox(height: 5,),
              const Text("Account", style: TextStyle(fontSize: 20, color: Colors.black),),
              const SizedBox(height: 15,),
              QrImage(
                data: widget.address,
                size: 250,
                errorCorrectionLevel: QrErrorCorrectLevel.Q,
                embeddedImage: const AssetImage("assets/images/logo.jpeg"),
              ),
              const SizedBox(height: 15,),
              Text(Utils.truncate(widget.address, trailingDigits: 10), style: const TextStyle(fontSize: 20, color: Colors.black),),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 65,
                    child: ElevatedButton(
                      onPressed: (){
                        Share.share(widget.address);
                      },
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.transparent),
                        elevation: MaterialStateProperty.all(0),
                        shape: MaterialStateProperty.all(BeveledRectangleBorder(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(10),
                            ),
                            side: BorderSide(color: Get.theme.colorScheme.onPrimary, width: 0.7)
                        )),
                      ),
                      child: const Icon(PhosphorIcons.shareLight, color: Colors.black, size: 20,),
                    ),
                  ),
                  const SizedBox(width: 5,),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    width: _addressCopied ? 115 : 65,
                    child: ElevatedButton(
                      onPressed: !_addressCopied ? copyAddress : null,
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.transparent),
                        elevation: MaterialStateProperty.all(0),
                        shape: MaterialStateProperty.all(RoundedRectangleBorder(
                            borderRadius: const BorderRadius.all(Radius.circular(0)),
                            side: BorderSide(color: Get.theme.colorScheme.onPrimary, width: 1.5)
                        )),
                      ),
                      child: !_addressCopied ? const Icon(PhosphorIcons.copyLight, color: Colors.black, size: 20,)
                      : Row(
                        children: const [
                          Icon(Icons.check, color: Colors.green,),
                          SizedBox(width: 2,),
                          Text("Copied!", style: TextStyle(color: Colors.green),),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50,),
            ],
          ),
        ],
      ),
    );
  }
}
