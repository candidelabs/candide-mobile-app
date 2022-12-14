import 'package:animations/animations.dart';
import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/controller/settings_persistent_data.dart';
import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:candide_mobile_app/controller/wallet_connect_controller.dart';
import 'package:candide_mobile_app/screens/home/activity/activity_screen.dart';
import 'package:candide_mobile_app/screens/home/guardians/guardians_page.dart';
import 'package:candide_mobile_app/screens/home/overview_screen.dart';
import 'package:candide_mobile_app/screens/home/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var pagesList = [
    const OverviewScreen(),
    const ActivityScreen(),
    const GuardiansPage(),
    const SettingsScreen(),
  ];
  bool reverse = false;
  int currentIndex = 0;

  @override
  void initState() {
    WalletConnectController.restoreAllSessions(Networks.get(SettingsData.network)!.chainId.toInt());
    WalletConnectController.startConnectivityAssuranceTimer();
    //
    TokenInfoStorage.loadAllTokens(Networks.get(SettingsData.network)!.chainId.toInt());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageTransitionSwitcher(
          transitionBuilder: (
              Widget child,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
              ) {
            return SharedAxisTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              transitionType: SharedAxisTransitionType.horizontal,
              child: child,
            );
          },
          duration: const Duration(milliseconds: 400),
          reverse: reverse,
          child: pagesList[currentIndex],
        ),
      ),
      bottomNavigationBar: Card(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        margin: EdgeInsets.zero,
        child: SalomonBottomBar(
          currentIndex: currentIndex,
          onTap: (i){
            setState(() {
              reverse = i < currentIndex;
              currentIndex = i;
            });
          },
          items: [
            SalomonBottomBarItem(
              icon: const Icon(PhosphorIcons.walletLight, size: 25,),
              title: const Text("Assets"),
              selectedColor: Get.theme.colorScheme.primary,
            ),
            SalomonBottomBarItem(
              icon: const Icon(PhosphorIcons.listBulletsFill, size: 25,),
              title: const Text("Activity"),
              selectedColor: const Color(0xff9fd8df),
            ),
            SalomonBottomBarItem(
              icon: const Icon(PhosphorIcons.shieldLight, size: 25,),
              title: const Text("Security"),
              selectedColor: const Color(0xffdf695e),
            ),
            SalomonBottomBarItem(
              icon: const Icon(PhosphorIcons.gearLight, size: 25,),
              title: const Text("Settings"),
              selectedColor: const Color(0xffebb577),
            ),
          ],
        ),
      ),
    );
  }
}
