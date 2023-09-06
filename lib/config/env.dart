import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static late String explorerUri;
  static late String securityUri;
  //
  static late String optimismBundlerEndpoint;
  static late String goerliBundlerEndpoint;
  static late String optimismGoerliBundlerEndpoint;
  static late String sepoliaBundlerEndpoint;
  //
  static late String optimismPaymasterEndpoint;
  static late String goerliPaymasterEndpoint;
  static late String optimismGoerliPaymasterEndpoint;
  static late String sepoliaPaymasterEndpoint;
  //
  static late String mainnetRpcEndpoint;
  static late String optimismRpcEndpoint;
  static late String goerliRpcEndpoint;
  static late String optimismGoerliRpcEndpoint;
  static late String sepoliaRpcEndpoint;
  //
  static late String optimismWebsocketsRpcEndpoint;
  static late String goerliWebsocketsRpcEndpoint;
  static late String optimismGoerliWebsocketsRpcEndpoint;
  static late String sepoliaWebsocketsRpcEndpoint;
  //
  static late String walletConnectProjectId;
  static late String magicApiKey;

  static String getNodeUrlByChainId(int chainId){
    switch (chainId){
      case 5: return goerliRpcEndpoint;
      case 10: return optimismRpcEndpoint;
      case 420: return optimismGoerliRpcEndpoint;
      case 11155111: return sepoliaRpcEndpoint;
      //
      default: return optimismRpcEndpoint;
    }
  }

  static String getWebsocketsNodeUrlByChainId(int chainId){
    switch (chainId){
      case 5: return goerliWebsocketsRpcEndpoint;
      case 10: return optimismWebsocketsRpcEndpoint;
      case 420: return optimismGoerliWebsocketsRpcEndpoint;
      case 11155111: return sepoliaWebsocketsRpcEndpoint;
    //
      default: return optimismWebsocketsRpcEndpoint;
    }
  }

  static String getBundlerUrlByChainId(int chainId){
    switch (chainId){
      case 5: return goerliBundlerEndpoint;
      case 10: return optimismBundlerEndpoint;
      case 420: return optimismGoerliBundlerEndpoint;
      case 11155111: return sepoliaBundlerEndpoint;
      //
      default: return goerliBundlerEndpoint;
    }
  }

  static String getPaymasterUrlByChainId(int chainId){
    switch (chainId){
      case 5: return goerliPaymasterEndpoint;
      case 10: return optimismPaymasterEndpoint;
      case 420: return optimismGoerliPaymasterEndpoint;
      case 11155111: return sepoliaPaymasterEndpoint;
    //
      default: return goerliPaymasterEndpoint;
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
    optimismGoerliRpcEndpoint = dotenv.get('OPTIMISM_GOERLI_NODE_HTTP_RPC_ENDPOINT', fallback: '-');
    optimismGoerliWebsocketsRpcEndpoint = dotenv.get('OPTIMISM_GOERLI_NODE_WSS_RPC_ENDPOINT', fallback: '-');
    optimismGoerliBundlerEndpoint = dotenv.get('OPTIMISM_GOERLI_BUNDLER_NODE', fallback: '-');
    optimismGoerliPaymasterEndpoint = dotenv.get('OPTIMISM_GOERLI_PAYMASTER', fallback: '-');
    //
    sepoliaRpcEndpoint = dotenv.get('SEPOLIA_NODE_HTTP_RPC_ENDPOINT', fallback: '-');
    sepoliaWebsocketsRpcEndpoint = dotenv.get('SEPOLIA_NODE_WSS_RPC_ENDPOINT', fallback: '-');
    sepoliaBundlerEndpoint = dotenv.get('SEPOLIA_BUNDLER_NODE', fallback: '-');
    sepoliaPaymasterEndpoint = dotenv.get('SEPOLIA_PAYMASTER', fallback: '-');
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