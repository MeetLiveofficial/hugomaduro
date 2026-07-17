import 'package:krimson/common/service/api/api_service.dart';
import 'package:krimson/common/service/utils/params.dart';
import 'package:krimson/common/service/utils/web_service.dart';
import 'package:krimson/model/general/status_model.dart';
import 'package:krimson/model/gift_wallet/coin_recharge_model.dart';
import 'package:krimson/model/gift_wallet/withdraw_model.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/utilities/app_res.dart';

class GiftWalletService {
  GiftWalletService._();

  static final GiftWalletService instance = GiftWalletService._();

  Future<StatusModel> sendGift({int? userId, int? giftId}) async {
    StatusModel response = await ApiService.instance.call(
        url: WebService.giftWallet.sendGift,
        fromJson: StatusModel.fromJson,
        param: {Params.userId: userId, Params.giftId: giftId});
    return response;
  }

  Future<List<Withdraw>> fetchMyWithdrawalRequest({int? lastItemId}) async {
    WithdrawModel response = await ApiService.instance.call(
        url: WebService.giftWallet.fetchMyWithdrawalRequest,
        fromJson: WithdrawModel.fromJson,
        param: {
          Params.limit: AppRes.paginationLimit,
          Params.lastItemId: lastItemId,
        });

    return response.data ?? [];
  }

  Future<List<CoinRecharge>> fetchMyRecharges({int? lastItemId}) async {
    final json = await ApiService.instance.call(
      url: WebService.giftWallet.fetchMyRecharges,
      fromJson: (j) => j,
      param: {
        Params.limit: AppRes.paginationLimit,
        Params.lastItemId: lastItemId,
      },
    );
    if (json['status'] != true) return [];
    final data = json['data'];
    if (data is! List) return [];
    return data
        .map((e) => CoinRecharge.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<StatusModel> submitWithdrawalRequest(
      {required String coins,
      required String gateway,
      required String account}) async {
    StatusModel response = await ApiService.instance.call(
        url: WebService.giftWallet.submitWithdrawalRequest,
        fromJson: StatusModel.fromJson,
        param: {
          Params.coins: coins,
          Params.gateway: gateway,
          Params.account: account
        });

    return response;
  }

  Future<User?> buyCoins({required int id, String? purchasedAt}) async {
    UserModel response = await ApiService.instance.call(
        url: WebService.giftWallet.buyCoins,
        fromJson: UserModel.fromJson,
        param: {
          Params.coinPackageId: id,
          Params.purchasedAt: purchasedAt,
        });
    if (response.status == true) {
      return response.data;
    }
    return null;
  }

  /// Crea factura NOWPayments. Devuelve mapa con invoice_url, order_id, etc.
  Future<Map<String, dynamic>?> createCryptoPayment(
      {required int coinPackageId}) async {
    final json = await ApiService.instance.call(
      url: WebService.giftWallet.createCryptoPayment,
      fromJson: (j) => j,
      param: {Params.coinPackageId: coinPackageId},
    );
    if (json['status'] != true) return null;
    final data = json['data'];
    if (data is! Map) return null;
    return Map<String, dynamic>.from(data);
  }

  /// Consulta estado del pago crypto. Si finished, puede incluir user.
  Future<Map<String, dynamic>?> checkCryptoPayment(
      {required String orderId}) async {
    final json = await ApiService.instance.call(
      url: WebService.giftWallet.checkCryptoPayment,
      fromJson: (j) => j,
      param: {Params.orderId: orderId},
    );
    if (json['status'] != true) return null;
    final data = json['data'];
    if (data is! Map) return null;
    return Map<String, dynamic>.from(data);
  }
}
