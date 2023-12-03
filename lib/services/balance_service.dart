import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/top_tokens.dart';
import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:candide_mobile_app/utils/constants.dart';
import 'package:candide_mobile_app/utils/currency.dart';
import 'package:dio/dio.dart';
import 'package:wallet_dart/wallet/account.dart';
import 'package:web3dart/web3dart.dart';

class BalanceService {

  static Future<Map> fetchBalances({
    required Account account,
    required List<TokenInfo> additionalCurrencies
  }) async {
    List<EthereumAddress> tokens = TopTokens.getChainTokens(account.chainId);
    Set<String> additionalCurrenciesSet = {};
    for (TokenInfo token in TokenInfoStorage.tokens){
      if (additionalCurrencies.contains(token)){
        EthereumAddress tokenAddress = EthereumAddress.fromHex(token.address);
        additionalCurrenciesSet.add(token.address.toLowerCase());
        if (tokens.contains(tokenAddress)) continue;
        tokens.add(tokenAddress);
      }
    }
    //
    Network network = Networks.getByChainId(account.chainId)!;
    var candideBalancesContract = DeployedContract(ContractAbi.fromJson('[{"inputs":[{"internalType":"address","name":"user","type":"address"},{"internalType":"address[]","name":"tokens","type":"address[]"}],"name":"tokenBalances","outputs":[{"internalType":"uint256[]","name":"balances","type":"uint256[]"}],"stateMutability":"view","type":"function"}]', "CandideBalances"), network.candideBalances);
    //
    String tokenAddresses = "";
    List<EthereumAddress> _equivalentTokens;
    if (network.testnetData == null){
      tokenAddresses = tokens.map((e) => e.hexEip55).toList().join(",");
    }else{
      _equivalentTokens = TopTokens.getTestChainEquivalentTokens(account.chainId, network.testnetData!.testnetForChainId);
      tokenAddresses = _equivalentTokens.map((e) => e.hexEip55).toList().join(",");
    }
    //
    List<dynamic> _balancesResult = [];
    double ethUsdPrice = 0;
    List<Response> responses = [];
    List<Future<dynamic>> futures = [];
    //
    var _tokenAddresses = tokenAddresses.split(",");
    List<String> _tempTokenAddresses = [];
    for (int i=0; i<_tokenAddresses.length; i++){
      _tempTokenAddresses.add(_tokenAddresses[i]);
      if (_tempTokenAddresses.length == 10 || i == _tokenAddresses.length-1){
        var _addresses = _tempTokenAddresses.join(",");
        futures.add(Dio().get(
          "https://api.coingecko.com/api/v3/simple/token_price/${network.coinGeckoAssetPlatform}?contract_addresses=$_addresses&vs_currencies=eth"
        ).then((value) => responses.add(value)).catchError((_){
          print("Fetching quotes failed!");
        }));
        _tempTokenAddresses.clear();
      }
    }
    await Future.wait([
      network.client.call(
        contract: candideBalancesContract,
        function: candideBalancesContract.function("tokenBalances"),
        params: [account.address, tokens],
      ).then((value) => _balancesResult = value),
      getETHUSDPrice().then((value) => ethUsdPrice = value),
      ...futures,
    ]);
    //
    List<BigInt> balances = (_balancesResult[0] as List<dynamic>).cast<BigInt>();
    Map quotes = {};
    //
    for (var response in responses){
      quotes.addAll(response.data);
    }
    //
    Map result = {};
    double totalQuote = 0;
    result["currencies"] = [];
    for (EthereumAddress tokenAddress in tokens){
      String quoteTokenAddress = tokenAddress.hex.toLowerCase();
      if (network.testnetData != null){
        String? _tempTokenAddress = TopTokens.getEquivalentToken(tokenAddress.hex, network.chainId.toInt(), network.testnetData!.testnetForChainId);
        if (_tempTokenAddress != null){
          quoteTokenAddress = _tempTokenAddress.toLowerCase();
        }
      }
      //
      var tokenIndex = tokens.indexOf(tokenAddress);
      if (balances[tokenIndex] == BigInt.zero){
        if (!additionalCurrenciesSet.contains(tokenAddress.hex.toLowerCase())){
          continue;
        }
      }
      //
      double quoteInEth = 0;
      double quoteInUSD = 0;
      if (balances[tokenIndex] > BigInt.zero && quotes[quoteTokenAddress] != null){
        int? tokenDecimals = TopTokens.getTokenDecimals(network.chainId.toInt(), tokenAddress.hex);
        tokenDecimals ??= TokenInfoStorage.getTokenByAddress(tokenAddress.hex)?.decimals;
        if (tokenDecimals != null){
          quoteInEth = double.parse(CurrencyUtils.formatUnits(balances[tokenIndex], tokenDecimals)) * quotes[quoteTokenAddress]["eth"];
          quoteInUSD = quoteInEth * ethUsdPrice;
          totalQuote += quoteInUSD;
        }
      }
      if (tokenAddress.hex == Constants.addressZeroHex){
        quoteInEth = double.parse(CurrencyUtils.formatUnits(balances[tokenIndex], TokenInfoStorage.getTokenByAddress(Constants.addressZeroHex)!.decimals));
        quoteInUSD = quoteInEth * ethUsdPrice;
        totalQuote += quoteInUSD;
      }
      result["currencies"].add({'currency': tokenAddress.hexEip55, 'quoteCurrency': 'USD', 'balance': balances[tokenIndex], 'currentBalanceInQuoteCurrency': quoteInUSD});
    }
    result["accountBalance"] = {'quoteCurrency': 'USD', 'currentBalance': totalQuote};
    return result;
  }

  static Future<double> getETHUSDPrice() async {
    try {
      var response = await Dio().get("https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD");
      return response.data["USD"].toDouble();
    } catch (e) {
      // todo handle network errors (note: return of 0 is used in debug_verify_endpoints_dialog.dart)
      return 0;
    }
  }
}