import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static late bool testnet;
  static late String explorerUri;
  static late String bundlerUri;
  static late String securityUri;
  static late String magicApiKey;
  static late String nodeRpcEndpoint;

  static initialize() async {
    await dotenv.load(fileName: ".env");
    testnet = dotenv.get('NETWORK_ENV', fallback: 'testnet') == "testnet";
    explorerUri = dotenv.get('EXPLORER_URL', fallback: 'http://192.168.1.3:3000');
    bundlerUri = dotenv.get('BUNDLER_URL', fallback: 'http://192.168.1.3:3002');
    securityUri = dotenv.get('SECURITY_URL', fallback: 'http://192.168.1.3:3004');
    magicApiKey = dotenv.get('MAGIC_API_KEY', fallback: '-');
    nodeRpcEndpoint = dotenv.get('NODE_RPC_ENDPOINT', fallback: '-');
  }
}