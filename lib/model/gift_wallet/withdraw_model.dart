class WithdrawModel {
  WithdrawModel({
    this.status,
    this.message,
    this.data,
  });

  WithdrawModel.fromJson(dynamic json) {
    status = json['status'];
    message = json['message'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(Withdraw.fromJson(v));
      });
    }
  }

  bool? status;
  String? message;
  List<Withdraw>? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = status;
    map['message'] = message;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class Withdraw {
  Withdraw({
    this.id,
    this.userId,
    this.requestNumber,
    this.gateway,
    this.account,
    this.amount,
    this.commissionPercent,
    this.commissionAmount,
    this.netAmount,
    this.coins,
    this.coinValue,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  Withdraw.fromJson(dynamic json) {
    id = json['id'];
    userId = json['user_id'];
    requestNumber = json['request_number'];
    gateway = json['gateway'];
    account = json['account'];
    amount = json['amount']?.toString();
    commissionPercent = _asNum(json['commission_percent']);
    commissionAmount = _asNum(json['commission_amount']);
    netAmount = _asNum(json['net_amount']);
    coins = json['coins'];
    coinValue = json['coin_value'];
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  static num? _asNum(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    return num.tryParse('$v');
  }

  num? id;
  num? userId;
  String? requestNumber;
  String? gateway;
  String? account;
  String? amount;
  num? commissionPercent;
  num? commissionAmount;
  num? netAmount;
  num? coins;
  num? coinValue;
  num? status;
  String? createdAt;
  String? updatedAt;

  double get grossUsd => double.tryParse(amount ?? '0') ?? 0;
  double get netUsd => (netAmount ?? grossUsd).toDouble();
  double get feeUsd => (commissionAmount ?? 0).toDouble();

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['user_id'] = userId;
    map['request_number'] = requestNumber;
    map['gateway'] = gateway;
    map['account'] = account;
    map['amount'] = amount;
    map['commission_percent'] = commissionPercent;
    map['commission_amount'] = commissionAmount;
    map['net_amount'] = netAmount;
    map['coins'] = coins;
    map['coin_value'] = coinValue;
    map['status'] = status;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    return map;
  }
}
