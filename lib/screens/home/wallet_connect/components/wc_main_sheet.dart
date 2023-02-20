import 'package:candide_mobile_app/screens/home/wallet_connect/components/wc_scan_sheet.dart';
import 'package:candide_mobile_app/screens/home/wallet_connect/wc_connections_page.dart';
import 'package:flutter/material.dart';

class WCMainSheet extends StatefulWidget {
  final Function(String) onScanResult;
  const WCMainSheet({Key? key, required this.onScanResult}) : super(key: key);

  @override
  State<WCMainSheet> createState() => _WCMainSheetState();
}

class _WCMainSheetState extends State<WCMainSheet> {
  final PageController pageController = PageController(initialPage: 0);

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: pageController,
      children: [
        WCScanSheet(onScanResult: widget.onScanResult),
        WCConnectionsPage(onBack: () => pageController.animateToPage(0, duration: const Duration(milliseconds: 500), curve: Curves.easeOut),),
      ],
    );
  }
}
