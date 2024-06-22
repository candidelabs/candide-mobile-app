import 'package:candide_mobile_app/config/network.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

class TokenInfoStorage {
  static late int _loadedChainId;
  static List<TokenInfo> tokens = [];

  static Map<int, List<TokenInfo>> defaultTokens = {
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
      TokenInfo(
        name: "Candide Test Token",
        symbol: "CTT",
        address: "0xFa5854FBf9964330d761961F46565AB7326e5a3b",
        logoUri: "https://raw.githubusercontent.com/candidelabs/candide-mobile-app/main/assets/images/fee-coin2.svg",
        decimals: 18,
      ),
      TokenInfo(
        name: "Wrapped Ethereum",
        symbol: "WETH",
        address: "0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14",
        decimals: 18,
        visible: false,
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

  static TokenInfo getNativeTokenForNetwork(Network network){
    return TokenInfoStorage.getTokenByAddress(network.nativeCurrencyAddress.hex, chainId: network.chainId.toInt())!;
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