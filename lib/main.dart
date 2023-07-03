import 'dart:convert';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:candide_mobile_app/config/env.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/screens/home/components/magic_relayer_widget.dart';
import 'package:candide_mobile_app/screens/splashscreen.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Please read assets/ca/README.md
Future<void> _addLERootCertificate() async {
  if (Platform.isAndroid){
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    // if android version is prior to 7.1.1
    if (androidInfo.version.sdkInt <= 25){
      try {
        var isrgX1 = await rootBundle.loadString('assets/ca/isrgrootx1.pem');
        SecurityContext.defaultContext.setTrustedCertificatesBytes(ascii.encode(isrgX1));
      } catch (e) {/* ignore errors */}
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _addLERootCertificate();
  //
  await Env.initialize();
  await Hive.initFlutter();
  runApp(const CandideApp());
}


class CandideApp extends StatelessWidget {
  const CandideApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Stack(
        children: [
          GetMaterialApp(
            title: 'Candide',
            builder: BotToastInit(),
            navigatorObservers: [BotToastNavigatorObserver()],
            debugShowCheckedModeBanner: false,
            theme: AppThemes.darkTheme,
            home: const SplashScreen(),
          ),
          const MagicRelayerWidget(),
        ],
      ),
    );
  }
}