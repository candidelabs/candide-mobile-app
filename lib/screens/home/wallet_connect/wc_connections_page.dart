import 'dart:async';

import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/wallet_connect/wallet_connect_controller.dart';
import 'package:candide_mobile_app/controller/wallet_connect/wallet_connect_v2_controller.dart';
import 'package:candide_mobile_app/controller/wallet_connect/wc_peer_meta.dart';
import 'package:candide_mobile_app/screens/home/wallet_connect/components/wc_peer_icon.dart';
import 'package:candide_mobile_app/utils/events.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:wallet_dart/wallet/account.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

class WCConnectionsPage extends StatefulWidget {
  final Account account;
  final VoidCallback onBack;
  const WCConnectionsPage({Key? key, required this.account, required this.onBack}) : super(key: key);

  @override
  State<WCConnectionsPage> createState() => _WCConnectionsPageState();
}

class _WCConnectionsPageState extends State<WCConnectionsPage> {
  late WalletConnectV2Controller v2Controller;
  List<SessionData> v2Sessions = [];
  late StreamSubscription disconnectListener;

  Future<void> loadV2Sessions() async {
    setState(() => v2Sessions.clear());
    v2Controller = await WalletConnectV2Controller.instance();
    setState(() {
      v2Sessions.addAll(v2Controller.getAccountSessions(widget.account));
    });
  }

  @override
  void initState() {
    disconnectListener = eventBus.on<OnWalletConnectDisconnect>().listen((event) async {
      if (!mounted) return;
      await loadV2Sessions();
      setState(() {});
    });
    loadV2Sessions();
    super.initState();
  }

  @override
  void dispose() {
    disconnectListener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isEmpty = true;
    if (WalletConnectController.instances.isNotEmpty) isEmpty = false;
    if (v2Sessions.isNotEmpty) isEmpty = false;
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
      body: isEmpty ? Center(
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
                  peerMeta: WCPeerMeta.fromPeerMeta(controller.connector.session.peerMeta),
                  onPressDisconnect: () async {
                    controller.disconnect();
                  },
                ),
              for (final SessionData session in v2Sessions)
                _SessionCard(
                  peerMeta: WCPeerMeta.fromPairingMetadata(session.peer.metadata),
                  onPressDisconnect: () async {
                    v2Controller.wcClient.disconnectSession(
                      topic: session.topic,
                      reason: Errors.getSdkError(Errors.USER_DISCONNECTED)
                    );
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
  final WCPeerMeta peerMeta;
  final VoidCallback onPressDisconnect;
  const _SessionCard({Key? key, required this.peerMeta, required this.onPressDisconnect}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                    child: WCPeerIcon(icons: peerMeta.icons),
                  ),
                ),
                const SizedBox(width: 10,),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Utils.truncate(peerMeta.name, leadingDigits: 35, trailingDigits: 0),
                        style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 13),
                      ),
                      Text(
                        Utils.truncate(peerMeta.url, leadingDigits: 50, trailingDigits: 0),
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
