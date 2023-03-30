import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static late String explorerUri;
  static late String securityUri;
  static late String goerliBundlerEndpoint;
  static late String optimismGoerliBundlerEndpoint;
  static late String sepoliaBundlerEndpoint;
  static late String mainnetRpcEndpoint;
  static late String goerliRpcEndpoint;
  static late String optimismGoerliRpcEndpoint;
  static late String optimismRpcEndpoint;
  static late String sepoliaRpcEndpoint;
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

  static String getBundlerUrlByChainId(int chainId){
    switch (chainId){
      case 5: return goerliBundlerEndpoint;
      //case 10: return optimismGoerliBundlerEndpoint;
      case 420: return optimismGoerliBundlerEndpoint;
      case 11155111: return sepoliaBundlerEndpoint;
      //
      default: return optimismRpcEndpoint;
    }
  }

  static initialize() async {
    await dotenv.load(fileName: ".env");
    explorerUri = dotenv.get('EXPLORER_URL', fallback: 'http://192.168.1.3:3000');
    securityUri = dotenv.get('SECURITY_URL', fallback: 'http://192.168.1.3:3004');
    magicApiKey = dotenv.get('MAGIC_API_KEY', fallback: '-');
    goerliBundlerEndpoint = dotenv.get('GOERLI_BUNDLER_NODE', fallback: '-');
    optimismGoerliBundlerEndpoint = dotenv.get('OPTIMISM_GOERLI_BUNDLER_NODE', fallback: '-');
    sepoliaBundlerEndpoint = dotenv.get('SEPOLIA_BUNDLER_NODE', fallback: '-');
    mainnetRpcEndpoint = dotenv.get('MAINNET_NODE_RPC_ENDPOINT', fallback: '-');
    goerliRpcEndpoint = dotenv.get('GOERLI_NODE_RPC_ENDPOINT', fallback: '-');
    optimismGoerliRpcEndpoint = dotenv.get('OPTIMISM_GOERLI_NODE_RPC_ENDPOINT', fallback: '-');
    optimismRpcEndpoint = dotenv.get('OPTIMISM_NODE_RPC_ENDPOINT', fallback: '-');
    sepoliaRpcEndpoint = dotenv.get('SEPOLIA_NODE_RPC_ENDPOINT', fallback: '-');
  }
}