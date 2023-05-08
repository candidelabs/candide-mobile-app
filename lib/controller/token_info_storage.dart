import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

class TokenInfoStorage {
  static late int _loadedChainId;
  static List<TokenInfo> tokens = [];

  static Map<int, List<TokenInfo>> defaultTokens = {
    5: [
      TokenInfo(
        name: "Ethereum",
        symbol: "ETH",
        address: "0x0000000000000000000000000000000000000000",
        decimals: 18,
        logoUri: "https://raw.githubusercontent.com/candidelabs/candide-mobile-app/main/assets/images/ethereum.svg",
      ),
      TokenInfo(
        name: "Uniswap",
        symbol: "UNI",
        address: "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984",
        decimals: 18,
        logoUri: "https://cryptologos.cc/logos/uniswap-uni-logo.png?v=023",
      ),
      TokenInfo(
        name: "Candide Test Token",
        symbol: "CTT",
        address: "0x7DdEFA2f027691116D0a7aa6418246622d70B12A",
        logoUri: "https://raw.githubusercontent.com/candidelabs/candide-mobile-app/main/assets/images/fee-coin2.svg",
        decimals: 18,
      ),
      TokenInfo(
        name: "Wrapped Ethereum",
        symbol: "WETH",
        address: "0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6",
        decimals: 18,
        visible: false,
      ),
      TokenInfo(
        name: "Tether",
        symbol: "USDT",
        address: "0x509Ee0d083DdF8AC028f2a56731412edD63223B9",
        decimals: 6,
        logoUri: "https://cryptologos.cc/logos/tether-usdt-logo.svg?v=023",
        visible: false,
      ),
    ],
    420: [
      TokenInfo(
        name: "Ethereum",
        symbol: "ETH",
        address: "0x0000000000000000000000000000000000000000",
        decimals: 18,
        logoUri: "https://raw.githubusercontent.com/candidelabs/candide-mobile-app/main/assets/images/ethereum.svg",
      ),
      TokenInfo(
        name: "Candide Test Token",
        symbol: "CTT",
        address: "0x7DdEFA2f027691116D0a7aa6418246622d70B12A",
        logoUri: "https://raw.githubusercontent.com/candidelabs/candide-mobile-app/main/assets/images/fee-coin2.svg",
        decimals: 18,
      ),
      TokenInfo(
        name: "Wrapped Ethereum",
        symbol: "WETH",
        address: "0x4200000000000000000000000000000000000006",
        decimals: 18,
        visible: false,
      ),
      TokenInfo(
        name: "Optimism",
        symbol: "OP",
        address: "0x4200000000000000000000000000000000000042",
        decimals: 18,
        logoUri: "https://raw.githubusercontent.com/candidelabs/candide-mobile-app/main/assets/images/optimism.svg",
        visible: false,
      ),
    ],
    10: [
      TokenInfo(
        name: "Ethereum",
        symbol: "ETH",
        address: "0x0000000000000000000000000000000000000000",
        decimals: 18,
        logoUri: "https://raw.githubusercontent.com/candidelabs/candide-mobile-app/main/assets/images/ethereum.svg",
      ),
      TokenInfo(
        name: "Wrapped Ethereum",
        symbol: "WETH",
        address: "0x4200000000000000000000000000000000000006",
        decimals: 18,
        visible: false,
      ),
      TokenInfo(
        name: "Optimism",
        symbol: "OP",
        address: "0x4200000000000000000000000000000000000042",
        decimals: 18,
        logoUri: "https://raw.githubusercontent.com/candidelabs/candide-mobile-app/main/assets/images/optimism.svg",
        visible: false,
      ),
      TokenInfo(
        name: "USD Coin",
        symbol: "USDC",
        address: "0x7F5c764cBc14f9669B88837ca1490cCa17c31607",
        decimals: 6,
        logoUri: "https://raw.githubusercontent.com/ethereum-optimism/ethereum-optimism.github.io/master/data/USDC/logo.png",
        visible: true,
      ),
    ],
    11155111: [
      TokenInfo(
        name: "Ethereum",
        symbol: "ETH",
        address: "0x0000000000000000000000000000000000000000",
        decimals: 18,
        logoUri: "https://raw.githubusercontent.com/candidelabs/candide-mobile-app/main/assets/images/ethereum.svg",
        visible: true,
      ),
    ]
  };

  // Save to Box called "tokens_storage" at "tokens_info({chainId})"
  static Future<void> persistAllTokens(List<TokenInfo> _tokens, int chainId) async {
    List<Map<String, dynamic>> tokensList = [];
    for (final TokenInfo token in _tokens){
      tokensList.add(token.toJson());
    }
    await Hive.box("tokens_storage").put("tokens_info($chainId)", tokensList);
  }

  static void loadAllTokens(int chainId) {
    List data = Hive.box("tokens_storage").get("tokens_info($chainId)") ?? []; // List<Map<String,dynamic>>
    _loadedChainId = chainId;
    tokens.clear();
    Set<String> addedTokens = {};
    if (defaultTokens.containsKey(chainId)){
      for (TokenInfo token in defaultTokens[chainId]!){
        tokens.add(token);
        addedTokens.add(token.address.toLowerCase());
      }
    }
    for (Map tokenInfoJson in data){
      TokenInfo tokenInfo = TokenInfo.fromJson(tokenInfoJson);
      if (addedTokens.contains(tokenInfo.address.toLowerCase())){
        TokenInfo addedToken = getTokenByAddress(tokenInfo.address)!;
        addedToken.visible = tokenInfo.visible;
        continue;
      }
      tokens.add(tokenInfo);
    }
  }

  static Future<void> addToken(TokenInfo token, int chainId) async {
    if (_loadedChainId == chainId){
      if (tokens.firstWhereOrNull((element) => element.address.toLowerCase() == token.address.toLowerCase()) != null) return;
      tokens.add(token);
      await persistAllTokens(tokens, _loadedChainId);
    }else{
      List data = Hive.box("tokens_storage").get("tokens_info($chainId)") ?? []; // List<Map<String,dynamic>>
      List<TokenInfo> _tempTokens = [];
      for (Map tokenInfoJson in data){
        TokenInfo tokenInfo = TokenInfo.fromJson(tokenInfoJson);
        _tempTokens.add(tokenInfo);
      }
      if (_tempTokens.firstWhereOrNull((element) => element.address.toLowerCase() == token.address.toLowerCase()) != null) return;
      _tempTokens.add(token);
      await persistAllTokens(_tempTokens, chainId);
    }
  }

  static TokenInfo? getTokenByAddress(String address, {int? chainId}){
    if (address.length < 5) return getTokenBySymbol(address, chainId: chainId);
    if (chainId == null || _loadedChainId == chainId){
      return tokens.firstWhereOrNull((element) => element.address.toLowerCase() == address.toLowerCase());
    }
    List data = Hive.box("tokens_storage").get("tokens_info($chainId)") ?? []; // List<Map<String,dynamic>>
    for (Map tokenInfoJson in data){
      if (tokenInfoJson["address"].toString().toLowerCase() == address.toLowerCase()){
        return TokenInfo.fromJson(tokenInfoJson);
      }
    }
    return null;
  }

  static TokenInfo? getTokenBySymbol(String symbol, {int? chainId}){
    if (chainId == null || _loadedChainId == chainId){
      return tokens.firstWhereOrNull((element) => element.symbol.toLowerCase() == symbol.toLowerCase());
    }
    List data = Hive.box("tokens_storage").get("tokens_info($chainId)") ?? []; // List<Map<String,dynamic>>
    for (Map tokenInfoJson in data){
      if (tokenInfoJson["symbol"].toString().toLowerCase() == symbol.toLowerCase()){
        return TokenInfo.fromJson(tokenInfoJson);
      }
    }
    return null;
  }

  static TokenInfo? getTokenByName(String name, {int? chainId}){
    if (chainId == null || _loadedChainId == chainId){
      return tokens.firstWhereOrNull((element) => element.name.toLowerCase() == name.toLowerCase());
    }
    List data = Hive.box("tokens_storage").get("tokens_info($chainId)") ?? []; // List<Map<String,dynamic>>
    for (Map tokenInfoJson in data){
      if (tokenInfoJson["name"].toString().toLowerCase() == name.toLowerCase()){
        return TokenInfo.fromJson(tokenInfoJson);
      }
    }
    return null;
  }

}

class TokenInfo {
  String name;
  String symbol;
  String address;
  int decimals;
  String? logoUri;
  bool visible;

  TokenInfo({
    required this.name,
    required this.symbol,
    required this.address,
    required this.decimals,
    this.logoUri,
    this.visible = true,
  });

  TokenInfo.fromJson(Map json)
      : name = json['name'],
        symbol = json['symbol'],
        address = json['address'],
        decimals = json['decimals'],
        logoUri = json['logoUri'],
        visible = json['visible'];

  Map<String, dynamic> toJson() => {
    'name': name,
    'symbol': symbol,
    'address': address,
    'decimals': decimals,
    'logoUri': logoUri,
    'visible': visible,
  };
}