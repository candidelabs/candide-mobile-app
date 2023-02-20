import 'dart:async';

import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/wallet_connect_controller.dart';
import 'package:candide_mobile_app/utils/events.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class WCConnectionsPage extends StatefulWidget {
  final VoidCallback onBack;
  const WCConnectionsPage({Key? key, required this.onBack}) : super(key: key);

  @override
  State<WCConnectionsPage> createState() => _WCConnectionsPageState();
}

class _WCConnectionsPageState extends State<WCConnectionsPage> {
  late StreamSubscription disconnectListener;

  @override
  void initState() {
    disconnectListener = eventBus.on<OnWalletConnectDisconnect>().listen((event) {
      if (!mounted) return;
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    disconnectListener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Connected dApps", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 40,
        leading: Container(
          margin: const EdgeInsets.only(left: 10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[800],
          ),
          child: IconButton(
            onPressed: widget.onBack,
            padding: const EdgeInsets.all(0),
            splashRadius: 15,
            style: const ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(PhosphorIcons.caretLeftBold, size: 17,),
          ),
        ),
      ),
      body: WalletConnectController.instances.isEmpty ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            Icon(PhosphorIcons.link, color: Colors.grey,),
            SizedBox(height: 10,),
            Text("Authorized dApps will appear here", style: TextStyle(color: Colors.grey),),
          ],
        ),
      ) : SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15,),
              Text("Active connections", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),),
              for (final WalletConnectController controller in WalletConnectController.instances)
                _SessionCard(
                  sessionController: controller,
                  onPressDisconnect: () async {
                    controller.disconnect();
                  },
                ),
              const SizedBox(height: 15,),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final WalletConnectController sessionController;
  final VoidCallback onPressDisconnect;
  const _SessionCard({Key? key, required this.sessionController, required this.onPressDisconnect}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget peerIcon;
    if (sessionController.connector.session.peerMeta == null
          || sessionController.connector.session.peerMeta!.icons == null
          || sessionController.connector.session.peerMeta!.icons!.isEmpty){
      peerIcon = SvgPicture.asset("assets/images/walletconnect.svg");
    }else{
      if (sessionController.connector.session.peerMeta!.icons![0].endsWith(".svg")){
        peerIcon = SvgPicture.network(sessionController.connector.session.peerMeta!.icons![0]);
      }else{
        peerIcon = Image.network(sessionController.connector.session.peerMeta!.icons![0]);
      }
    }
    return Card(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: peerIcon,
                  ),
                ),
                const SizedBox(width: 10,),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Utils.truncate(sessionController.connector.session.peerMeta?.name ?? "Unknown", leadingDigits: 35, trailingDigits: 0),
                        style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 13),
                      ),
                      Text(
                        Utils.truncate(sessionController.connector.session.peerMeta?.url ?? "", leadingDigits: 50, trailingDigits: 0),
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Container(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onPressDisconnect,
                style: const ButtonStyle(
                  padding: MaterialStatePropertyAll(EdgeInsets.zero),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(PhosphorIcons.linkBreakBold, color: Colors.red, size: 18,),
                label: Text("Disconnect", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Colors.red, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

