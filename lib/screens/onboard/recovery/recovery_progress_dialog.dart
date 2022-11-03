import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wallet_dart/contracts/factories/EIP4337Manager.g.dart';
import 'package:wallet_dart/contracts/wallet.dart';
import 'package:web3dart/web3dart.dart';

class RecoveryProgressDialog extends StatefulWidget {
  final String walletAddress;
  final String expectedOwner;
  const RecoveryProgressDialog({Key? key, required this.walletAddress, required this.expectedOwner}) : super(key: key);

  @override
  State<RecoveryProgressDialog> createState() => _RecoveryProgressDialogState();
}

class _RecoveryProgressDialogState extends State<RecoveryProgressDialog> {
  late EIP4337Manager walletInterface;

  void periodicCheck(int checks) async {
    if (checks >= 25){
      Navigator.pop(context, false);
      return;
    }
    var owner = (await walletInterface.getOwners())[0];
    if (owner.hex.toLowerCase() == widget.expectedOwner.toLowerCase()){
      if (!mounted) return;
      Navigator.pop(context, true);
      return;
    }
    if (!mounted) return;
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    periodicCheck(checks+1);
  }

  @override
  void initState() {
    walletInterface = CWallet.customInterface(EthereumAddress.fromHex(widget.walletAddress));
    periodicCheck(0);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Recovery in progress"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          CircularProgressIndicator(),
          SizedBox(height: 25,),
          Text("Do not close!", style: TextStyle(color: Colors.amber),),
        ],
      ),
    );
  }
}
