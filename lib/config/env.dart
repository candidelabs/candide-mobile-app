import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static late String explorerUri;
  static late String securityUri;
  //
  static late String optimismBundlerEndpoint;
  static late String goerliBundlerEndpoint;
  //
  static late String optimismPaymasterEndpoint;
  static late String goerliPaymasterEndpoint;
  //
  static late String mainnetRpcEndpoint;
  static late String optimismRpcEndpoint;
  static late String goerliRpcEndpoint;
  //
  static late String optimismWebsocketsRpcEndpoint;
  static late String goerliWebsocketsRpcEndpoint;
  //
  static late String walletConnectProjectId;
  static late String magicApiKey;

  static String getWebsocketsNodeUrlByChainId(int chainId){
    switch (chainId){
      case 5: return goerliWebsocketsRpcEndpoint;
      case 10: return optimismWebsocketsRpcEndpoint;
      //
      default: return optimismWebsocketsRpcEndpoint;
    }
  }

  static initialize() async {
    await dotenv.load(fileName: ".env");
    explorerUri = dotenv.get('EXPLORER_URL', fallback: 'http://192.168.1.3:3000');
    securityUri = dotenv.get('SECURITY_URL', fallback: 'http://192.168.1.3:3004');
    //
    goerliRpcEndpoint = dotenv.get('GOERLI_NODE_HTTP_RPC_ENDPOINT', fallback: '-');
    goerliWebsocketsRpcEndpoint = dotenv.get('GOERLI_NODE_WSS_RPC_ENDPOINT', fallback: '-');
    goerliBundlerEndpoint = dotenv.get('GOERLI_BUNDLER_NODE', fallback: '-');
    goerliPaymasterEndpoint = dotenv.get('GOERLI_PAYMASTER', fallback: '-');
    //
    optimismRpcEndpoint = dotenv.get('OPTIMISM_NODE_HTTP_RPC_ENDPOINT', fallback: '-');
    optimismWebsocketsRpcEndpoint = dotenv.get('OPTIMISM_NODE_WSS_RPC_ENDPOINT', fallback: '-');
    optimismBundlerEndpoint = dotenv.get('OPTIMISM_BUNDLER_NODE', fallback: '-');
    optimismPaymasterEndpoint = dotenv.get('OPTIMISM_PAYMASTER', fallback: '-');
    //
    mainnetRpcEndpoint = dotenv.get('MAINNET_NODE_HTTP_RPC_ENDPOINT', fallback: '-');
    //
    magicApiKey = dotenv.get('MAGIC_API_KEY', fallback: '-');
    walletConnectProjectId = dotenv.get('WALLET_CONNECT_PROJECT_ID', fallback: '-');
  }
}