import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static late String explorerUri;
  static late String securityUri;
  //
  static late String optimismBundlerEndpoint;
  static late String sepoliaBundlerEndpoint;
  //
  static late String optimismPaymasterEndpoint;
  static late String sepoliaPaymasterEndpoint;
  //
  static late String mainnetRpcEndpoint;
  static late String optimismRpcEndpoint;
  static late String sepoliaRpcEndpoint;
  //
  static late String optimismWebsocketsRpcEndpoint;
  static late String sepoliaWebsocketsRpcEndpoint;
  //
  static late String walletConnectProjectId;
  static late String magicApiKey;

  static String getWebsocketsNodeUrlByChainId(int chainId){
    switch (chainId){
      case 10: return optimismWebsocketsRpcEndpoint;
      case 11155111: return sepoliaWebsocketsRpcEndpoint;
      //
      default: return optimismWebsocketsRpcEndpoint;
    }
  }

  static initialize() async {
    await dotenv.load(fileName: ".env");
    explorerUri = dotenv.get('EXPLORER_URL', fallback: 'http://192.168.1.3:3000');
    securityUri = dotenv.get('SECURITY_URL', fallback: 'http://192.168.1.3:3004');
    //
    optimismRpcEndpoint = dotenv.get('OPTIMISM_NODE_HTTP_RPC_ENDPOINT', fallback: '-');
    optimismWebsocketsRpcEndpoint = dotenv.get('OPTIMISM_NODE_WSS_RPC_ENDPOINT', fallback: '-');
    optimismBundlerEndpoint = dotenv.get('OPTIMISM_BUNDLER_NODE', fallback: '-');
    optimismPaymasterEndpoint = dotenv.get('OPTIMISM_PAYMASTER', fallback: '-');
    //
    sepoliaRpcEndpoint = dotenv.get('SEPOLIA_NODE_HTTP_RPC_ENDPOINT', fallback: '-');
    sepoliaWebsocketsRpcEndpoint = dotenv.get('SEPOLIA_NODE_WSS_RPC_ENDPOINT', fallback: '-');
    sepoliaBundlerEndpoint = dotenv.get('SEPOLIA_BUNDLER_NODE', fallback: '-');
    sepoliaPaymasterEndpoint = dotenv.get('SEPOLIA_PAYMASTER', fallback: '-');
    //
    mainnetRpcEndpoint = dotenv.get('MAINNET_NODE_HTTP_RPC_ENDPOINT', fallback: '-');
    //
    magicApiKey = dotenv.get('MAGIC_API_KEY', fallback: '-');
    walletConnectProjectId = dotenv.get('WALLET_CONNECT_PROJECT_ID', fallback: '-');
  }
}