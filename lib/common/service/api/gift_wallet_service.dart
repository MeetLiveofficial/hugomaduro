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
    final json = await ApiService.instance.call(
      url: WebService.giftWallet.sendGift,
      fromJson: (j) => j,
      param: {Params.userId: userId, Params.giftId: giftId},
    );
    return StatusModel.fromJson(json);
  }

  /// Envía regalo y devuelve el precio real confirmado por el backend.
  Future<({bool ok, String? message, int coinPrice, String? image})>
      sendGiftDetailed({int? userId, int? giftId}) async {
    final json = await ApiService.instance.call(
      url: WebService.giftWallet.sendGift,
      fromJson: (j) => j,
      param: {Params.userId: userId, Params.giftId: giftId},
    );
    final ok = json['status'] == true;
    final data = json['data'];
    var coinPrice = 0;
    String? image;
    if (data is Map) {
      final raw = data['coin_price'] ?? data['coinPrice'];
      if (raw is num) {
        coinPrice = raw.toInt();
      } else {
        coinPrice = int.tryParse('$raw') ?? 0;
      }
      image = data['image']?.toString();
    }
    return (
      ok: ok,
      message: json['message']?.toString(),
      coinPrice: coinPrice,
      image: image,
    );
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

  Future<Map<String, dynamic>> submitWithdrawalRequest(
      {required String coins,
      required String gateway,
      required String account}) async {
    return ApiService.instance.call(
        url: WebService.giftWallet.submitWithdrawalRequest,
        fromJson: (j) => Map<String, dynamic>.from(j),
        param: {
          Params.coins: coins,
          Params.gateway: gateway,
          Params.account: account
        });
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

  /// Crea factura NOWPayments.
  /// Devuelve `{ok: true, data: {...}}` o `{ok: false, message: '...'}`.
  Future<Map<String, dynamic>> createCryptoPayment(
      {required int coinPackageId}) async {
    final json = await ApiService.instance.call(
      url: WebService.giftWallet.createCryptoPayment,
      fromJson: (j) => j,
      param: {Params.coinPackageId: coinPackageId},
    );
    if (json['status'] == true && json['data'] is Map) {
      return {
        'ok': true,
        'data': Map<String, dynamic>.from(json['data'] as Map),
      };
    }
    return {
      'ok': false,
      'message': (json['message'] ?? 'No se pudo iniciar el pago crypto')
          .toString(),
    };
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

  /// Sincroniza pagos crypto pendientes con NOWPayments (recupera si falló el IPN).
  Future<int> syncPendingCryptoPayments() async {
    final json = await ApiService.instance.call(
      url: WebService.giftWallet.syncPendingCryptoPayments,
      fromJson: (j) => j,
      param: {},
    );
    if (json['status'] != true) return 0;
    final data = json['data'];
    if (data is Map && data['credited_count'] != null) {
      return int.tryParse('${data['credited_count']}') ?? 0;
    }
    return 0;
  }

  /// Crea checkout Wompi (tarjeta / PSE / Nequi).
  Future<Map<String, dynamic>> createWompiPayment(
      {required int coinPackageId}) async {
    final json = await ApiService.instance.call(
      url: WebService.giftWallet.createWompiPayment,
      fromJson: (j) => j,
      param: {Params.coinPackageId: coinPackageId},
    );
    if (json['status'] == true && json['data'] is Map) {
      return {
        'ok': true,
        'data': Map<String, dynamic>.from(json['data'] as Map),
      };
    }
    return {
      'ok': false,
      'message': (json['message'] ?? 'No se pudo iniciar el pago con tarjeta')
          .toString(),
    };
  }

  Future<Map<String, dynamic>?> checkWompiPayment(
      {required String orderId}) async {
    final json = await ApiService.instance.call(
      url: WebService.giftWallet.checkWompiPayment,
      fromJson: (j) => j,
      param: {Params.orderId: orderId},
    );
    if (json['status'] != true) return null;
    final data = json['data'];
    if (data is! Map) return null;
    return Map<String, dynamic>.from(data);
  }

  Future<int> syncPendingWompiPayments() async {
    final json = await ApiService.instance.call(
      url: WebService.giftWallet.syncPendingWompiPayments,
      fromJson: (j) => j,
      param: {},
    );
    if (json['status'] != true) return 0;
    final data = json['data'];
    if (data is Map && data['credited_count'] != null) {
      return int.tryParse('${data['credited_count']}') ?? 0;
    }
    return 0;
  }
}
