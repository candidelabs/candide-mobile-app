import 'dart:convert';
import 'dart:typed_data';

import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:candide_mobile_app/controller/signers_controller.dart';
import 'package:candide_mobile_app/screens/onboard/create_account/pin_entry_screen.dart';
import 'package:candide_mobile_app/utils/events.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wallet_dart/utils/abi_utils.dart';
import 'package:wallet_dart/wallet/account_helpers.dart';
import 'package:wallet_dart/wallet/encode_function_data.dart';
import 'package:wallet_dart/wallet/message.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/crypto.dart';

class SignatureRequestSheet extends StatefulWidget {
  final WalletConnect connector;
  final int requestId;
  final String signatureType;
  final String payload;
  const SignatureRequestSheet({Key? key, required this.signatureType, required this.payload, required this.connector, required this.requestId}) : super(key: key);

  @override
  State<SignatureRequestSheet> createState() => _SignatureRequestSheetState();
}

class _SignatureRequestSheetState extends State<SignatureRequestSheet> {

  String getPrettyJSONString(jsonObject){
    var encoder = const JsonEncoder.withIndent("     ");
    return encoder.convert(jsonObject);
  }

  Future<Credentials?> authenticateUser() async {
    Credentials? privateKey;
    privateKey = SignersController.instance.getPrivateKeysFromAccount(PersistentData.selectedAccount).first;
    if (privateKey != null){
      return privateKey;
    }
    await Get.to(PinEntryScreen(
      showLogo: true,
      promptText: "Enter PIN code",
      confirmMode: false,
      onPinEnter: (String pin, _) async {
        var cancelLoad = Utils.showLoading();
        Credentials? signer = await AccountHelpers.decryptSigner(
          SignersController.instance.getSignersFromAccount(PersistentData.selectedAccount).first!,
          pin,
        );
        cancelLoad();
        if (signer == null){
          eventBus.fire(OnPinErrorChange(error: "Incorrect PIN"));
          return null;
        }
        privateKey = signer;
        Get.back();
      },
      onBack: (){
        Get.back();
      },
    ));
    return privateKey;
  }

  @override
  Widget build(BuildContext context) {
    String signatureContent = widget.payload;
    if (widget.signatureType == "personal"){
      signatureContent = String.fromCharCodes(hexToBytes(widget.payload).toList());
    } else if (widget.signatureType.startsWith("typed")){
      signatureContent = getPrettyJSONString(jsonDecode(widget.payload)["message"]);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          controller: Get.find<ScrollController>(tag: "wc_signature_modal"),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth, minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const SizedBox(height: 25,),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 25),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: widget.connector.session.peerMeta?.name ?? "Unknown",
                        style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 18),
                        children: [
                          TextSpan(
                            text: " is requesting your signature",
                            style: TextStyle(fontFamily: AppThemes.fonts.gilroy, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 50,),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 15),
                    child: Text(signatureContent, style: const TextStyle(fontSize: 15, color: Colors.white),)
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          await widget.connector.rejectRequest(id: widget.requestId);
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
                        child: Text("Reject", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Get.theme.colorScheme.primary),),
                      ),
                      const SizedBox(width: 15,),
                      ElevatedButton(
                        onPressed: () async {
                          Credentials? credentials = await authenticateUser();
                          if (credentials == null) return;
                          //
                          String signature = "0x";
                          if (widget.signatureType == "personal" || widget.signatureType == "sign"){
                            signature = await _WCSignatureHelpers.personalSign(credentials, hexToBytes(widget.payload));
                          }else if(widget.signatureType.startsWith("typed")){
                            if (widget.signatureType == "typed-v1") {
                              signature = await _WCSignatureHelpers.typedSign(credentials, widget.payload, TypedDataVersion.V1);
                            }else if (widget.signatureType == "typed-v3"){
                              signature = await _WCSignatureHelpers.typedSign(credentials, widget.payload, TypedDataVersion.V3);
                            }else {
                              signature = await _WCSignatureHelpers.typedSign(credentials, widget.payload, TypedDataVersion.V4);
                            }
                          }
                          //
                          widget.connector.approveRequest(id: widget.requestId, result: signature);
                          Get.back();
                        },
                        style: ButtonStyle(
                            minimumSize: MaterialStateProperty.all(Size(Get.width * 0.30, 40)),
                            elevation: MaterialStateProperty.all(0),
                            shape: MaterialStateProperty.all(RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                                side: BorderSide(color: Get.theme.colorScheme.primary)
                            ))
                        ),
                        child: Text("Approve", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25,),
                ],
              ),
            ),
          ),
        );
      }
    );
  }
}

class _WCSignatureHelpers {
  static const _messagePrefix = '\u0019Ethereum Signed Message:\n';

  static Uint8List _getPersonalMessage(Uint8List message) {
    final prefix = _messagePrefix + message.length.toString();
    final prefixBytes = ascii.encode(prefix);
    return keccak256(Uint8List.fromList(prefixBytes + message));
  }

  static Uint8List getMessageHashForSafe(Uint8List payload){
    Uint8List SAFE_MSG_TYPEHASH = hexToBytes("0x60b3cbf8b4a223d68d641b3b6ddf9a298e7f33710cf3d3a9d1146b5a6150fbca");
    var domainSeparator = EncodeFunctionData.domainSeparator(PersistentData.selectedAccount.address);
    var encodedMessage = encodeAbi(["bytes32", "bytes32"], [SAFE_MSG_TYPEHASH, keccak256(payload)]);
    var messageHash = keccak256(Message.solidityPack(
        ["bytes1", "bytes1", "bytes32", "bytes32",],
        [Uint8List.fromList([0x19]), Uint8List.fromList([0x01]), domainSeparator, keccak256(encodedMessage)]
    ));
    return messageHash;
  }

  static Future<String> personalSign(Credentials credentials, Uint8List payload) async {
    payload = _getPersonalMessage(payload);
    var messageHash = getMessageHashForSafe(payload);
    //
    var signature = EthSigUtil.signMessage(
      privateKeyInBytes: (credentials as EthPrivateKey).privateKey,
      message: messageHash,
    );
    return signature;
  }

  static Future<String> typedSign(Credentials credentials, String payload, TypedDataVersion version) async {
    Uint8List hash = TypedDataUtil.hashMessage(jsonData: payload, version: version);
    var messageHash = getMessageHashForSafe(hash);
    //
    var signature = EthSigUtil.signMessage(
      privateKeyInBytes: (credentials as EthPrivateKey).privateKey,
      message: messageHash,
    );
    return signature;
  }

}