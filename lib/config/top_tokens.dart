import 'package:get/get.dart';
import 'package:web3dart/web3dart.dart';

class TopTokens {
  static Map<int, List<List>> topTokens = {
    1: [
      ["0x0000000000000000000000000000000000000000", "ETH", 18],
      ["0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2", "WETH", 18],
      ["0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984", "UNI", 18],
      ["0xdAC17F958D2ee523a2206206994597C13D831ec7", "USDT", 6],
    ],
    5: [
      ["0x0000000000000000000000000000000000000000", "ETH", 18],
      ["0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6", "WETH", 18],
      ["0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984", "UNI", 18],
      ["0xFaaFfdCBF13f879EA5D5594C4aEBcE0F5dE733ca", "CTT", 18],
      ["0x509Ee0d083DdF8AC028f2a56731412edD63223B9", "USDT", 6],
    ],
    10: [
      ["0x0000000000000000000000000000000000000000", "ETH", 18],
      ["0x4200000000000000000000000000000000000006", "WETH", 18],
      ["0x4200000000000000000000000000000000000042", "OP", 18],
      ["0x94b008aa00579c1307b0ef2c499ad98a8ce58e58", "USDT", 6],
      ["0x7F5c764cBc14f9669B88837ca1490cCa17c31607", "USDC", 6],
      ["0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1", "DAI", 18],
      ["0x68f180fcCe6836688e9084f035309E29Bf0A2095", "WBTC", 8],
      ["0x350a791Bfc2C21F9Ed5d10980Dad2e2638ffa7f6", "LINK", 18],
      ["0xFdb794692724153d1488CcdBE0C56c252596735F", "LDO", 18],
      ["0x2E3D870790dC77A83DD1d18184Acc7439A53f475", "FRAX", 18],
      ["0xC22885e06cd8507c5c74a948C59af853AEd1Ea5C", "USDD", 18],
      ["0x8700dAec35aF8Ff88c16BdF0418774CB3D7599B4", "SNX", 18],
      ["0x67CCEA5bb16181E7b4109c9c2143c24a1c2205Be", "FXS", 18],
      ["0xFB21B70922B9f6e3C6274BcD6CB1aa8A0fe20B80", "UST", 6],
      ["0xa00E3A3511aAC35cA78530c85007AFCd31753819", "KNC", 18],
      ["0x8c6f28f2F1A3C87F0f938b96d27520d9751ec8d9", "sUSD", 18],
      ["0x4E720DD3Ac5CFe1e1fbDE4935f386Bb1C66F4642", "BIFI", 18],
      ["0xE405de8F52ba7559f9df3C368500B6E6ae6Cee49", "sETH", 18],
      ["0xB0B195aEFA3650A6908f15CdaC7D92F8a5791B0B", "BOB", 18],
      ["0x217D47011b23BB961eB6D93cA9945B7501a5BB11", "THALES", 18],
      ["0x73cb180bf0521828d8849bc8CF2B920918e23032", "USD+", 6],
      ["0x298B9B95708152ff6968aafd889c6586e9169f1D", "sBTC", 18],
      ["0xB548f63D4405466B36C0c0aC3318a22fDcec711a", "RGT", 18],
      ["0xc5102fE9359FD9a28f877a67E36B0F050d81a3CC", "HOP", 18],
      ["0xEe9801669C6138E84bD50dEB500827b776777d28", "O3", 18],
      ["0x1da650C3B2DaA8AA9Ff6F661d4156Ce24d08A062", "DCN", 0],
      ["0xc5Db22719A06418028A40A9B5E9A7c02959D0d08", "sLINK", 18],
      ["0x0c5b4c92c948691EEBf185C17eeB9c230DC019E9", "PICKLE", 18],
      ["0xb12c13e66AdE1F72f71834f2FC5082Db8C091358", "ROOBEE", 18],
      ["0xEcF46257ed31c329F204Eb43E254C609dee143B3", "GRG", 18],
      ["0x00a35FD824c717879BF370E70AC6868b95870Dfb", "IB", 18],
    ],
    420: [
      ["0x0000000000000000000000000000000000000000", "ETH", 18],
      ["0x4200000000000000000000000000000000000006", "WETH", 18],
      ["0x4200000000000000000000000000000000000042", "OP", 18],
      ["0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1", "DAI", 18],
      ["0xeeDeF0B71B98Fb3563184706C3e94Dd2d8abd927", "USDC", 6],
    ],
    11155111: [
      ["0x0000000000000000000000000000000000000000", "ETH", 18],
    ],
  };

  static List<EthereumAddress> getChainTokens(int chainId){
    if (!topTokens.containsKey(chainId)) return [];
    return topTokens[chainId]!.map((e) => EthereumAddress.fromHex(e[0])).toList();
  }

  // returns the equivalent tokens addresses of test chains on main chain
  static List<EthereumAddress> getTestChainEquivalentTokens(int testChainId, int equivalentChainId){
    if (!topTokens.containsKey(testChainId)) return [];
    if (!topTokens.containsKey(equivalentChainId)) return [];
    List<EthereumAddress> equivalentTokens = [];
    for (List testToken in topTokens[testChainId]!){
      String? equivalentTokenAddress = topTokens[equivalentChainId]!.firstWhereOrNull((element) => element[1] == testToken[1])?[0];
      if (equivalentTokenAddress == null) continue;
      equivalentTokens.add(EthereumAddress.fromHex(equivalentTokenAddress));
    }
    return equivalentTokens;
  }


  static String? getEquivalentToken(String tokenAddress, int tokenChainId, int equivalentChainId){
    if (!topTokens.containsKey(tokenChainId)) return null;
    if (!topTokens.containsKey(equivalentChainId)) return null;
    String? tokenSymbol = topTokens[tokenChainId]!.firstWhereOrNull((element) => element[0].toString().toLowerCase() == tokenAddress.toLowerCase())?[1];
    if (tokenSymbol == null) return null;
    String? equivalentTokenAddress = topTokens[equivalentChainId]!.firstWhereOrNull((element) => element[1] == tokenSymbol)?[0];
    return equivalentTokenAddress;
  }

  static int? getTokenDecimals(int chainId, String tokenAddress){
    return topTokens[chainId]!.firstWhereOrNull((element) => element[0].toString().toLowerCase() == tokenAddress.toLowerCase())?[2];
  }
}