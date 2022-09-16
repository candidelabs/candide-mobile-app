import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static late String explorerUri;
  static late String bundlerUri;
  static late String securityUri;
  static late String magicApiKey;

  static initialize() async {
    await dotenv.load(fileName: ".env");
    explorerUri = dotenv.get('EXPLORER_URL', fallback: 'http://192.168.1.3:3000');
    bundlerUri = dotenv.get('BUNDLER_URL', fallback: 'http://192.168.1.3:3002');
    securityUri = dotenv.get('SECURITY_URL', fallback: 'http://192.168.1.3:3004');
    magicApiKey = dotenv.get('MAGIC_API_KEY', fallback: '-');
  }
}