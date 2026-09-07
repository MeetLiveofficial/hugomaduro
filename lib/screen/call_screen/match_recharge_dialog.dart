import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/model/call/call_request_model.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/coin_wallet_screen/recharge_promo_dialog.dart';

/// Tras colgar un Match por saldo: anuncio de recarga. La room ya está cerrada.
class MatchRechargeDialog {
  MatchRechargeDialog._();

  static Future<void> showOutOfCoins({
    User? peer,
    CallParty? party,
  }) {
    final name = (peer?.fullname ?? peer?.username ?? party?.fullname ?? party?.username ?? '')
        .trim();
    final photo = (peer?.profilePhoto ?? party?.profilePhoto ?? '').trim();
    return RechargePromo.show(
      peerName: name.isEmpty ? null : name,
      peerPhotoUrl: photo.isEmpty ? null : photo.addBaseURL(),
    );
  }
}
