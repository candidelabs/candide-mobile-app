import 'package:candide_mobile_app/models/paymaster/fee_token.dart';
import 'package:candide_mobile_app/models/paymaster/paymaster_data.dart';
import 'package:candide_mobile_app/models/paymaster/sponsor_data.dart';

class PaymasterResponse {
    List<FeeToken> tokens;
    SponsorData sponsorData;
    PaymasterMetadata paymasterData;

    PaymasterResponse({required this.tokens, required this.sponsorData, required this.paymasterData});
}