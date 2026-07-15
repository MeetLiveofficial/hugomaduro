import 'package:krimson/common/service/api/api_service.dart';
import 'package:krimson/common/service/utils/web_service.dart';
import 'package:krimson/model/user_model/user_model.dart';

class PrivilegeService {
  PrivilegeService._();
  static final PrivilegeService instance = PrivilegeService._();

  Future<Map<String, dynamic>> hub() async {
    final json = await ApiService.instance.call<Map<String, dynamic>>(
      url: WebService.privilege.hub,
      fromJson: (j) => j,
    );
    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'hub failed');
    }
    return Map<String, dynamic>.from(json['data'] as Map? ?? {});
  }

  Future<List<DressingItemModel>> dressingCatalog() async {
    final json = await ApiService.instance.call<Map<String, dynamic>>(
      url: WebService.privilege.dressingCatalog,
      fromJson: (j) => j,
    );
    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'dressing catalog failed');
    }
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return ((data['items'] as List?) ?? [])
        .map((e) => DressingItemModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<User?> equipDressing(int itemId) async {
    final json = await ApiService.instance.call<Map<String, dynamic>>(
      url: WebService.privilege.equipDressing,
      param: {'item_id': itemId},
      fromJson: (j) => j,
    );
    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'equip failed');
    }
    final data = json['data'];
    if (data is Map) {
      return User.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  Future<List<HonorUserModel>> honorWall({int limit = 30}) async {
    final json = await ApiService.instance.call<Map<String, dynamic>>(
      url: WebService.privilege.honorWall,
      param: {'limit': limit},
      fromJson: (j) => j,
    );
    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'honor wall failed');
    }
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return ((data['users'] as List?) ?? [])
        .map((e) => HonorUserModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

class DressingItemModel {
  DressingItemModel({
    this.id,
    this.title,
    this.type,
    this.image,
    this.colorHex,
    this.unlockLevel = 1,
    this.coinPrice = 0,
    this.unlocked = false,
    this.owned = false,
    this.equipped = false,
  });

  factory DressingItemModel.fromJson(Map<String, dynamic> json) {
    return DressingItemModel(
      id: json['id'] is num ? (json['id'] as num).toInt() : int.tryParse('${json['id']}'),
      title: json['title']?.toString(),
      type: json['type']?.toString(),
      image: json['image']?.toString(),
      colorHex: json['color_hex']?.toString(),
      unlockLevel: json['unlock_level'] is num
          ? (json['unlock_level'] as num).toInt()
          : int.tryParse('${json['unlock_level'] ?? 1}') ?? 1,
      coinPrice: json['coin_price'] is num
          ? (json['coin_price'] as num).toInt()
          : int.tryParse('${json['coin_price'] ?? 0}') ?? 0,
      unlocked: json['unlocked'] == true || json['unlocked'] == 1,
      owned: json['owned'] == true || json['owned'] == 1,
      equipped: json['equipped'] == true || json['equipped'] == 1,
    );
  }

  final int? id;
  final String? title;
  final String? type;
  final String? image;
  final String? colorHex;
  final int unlockLevel;
  final int coinPrice;
  final bool unlocked;
  final bool owned;
  final bool equipped;
}

class HonorUserModel {
  HonorUserModel({
    this.id,
    this.username,
    this.fullname,
    this.profilePhoto,
    this.isVerify = 0,
    this.isSvip = 0,
    this.levelNumber = 1,
    this.coinCollectedLifetime = 0,
  });

  factory HonorUserModel.fromJson(Map<String, dynamic> json) {
    return HonorUserModel(
      id: json['id'] is num ? (json['id'] as num).toInt() : int.tryParse('${json['id']}'),
      username: json['username']?.toString(),
      fullname: json['fullname']?.toString(),
      profilePhoto: json['profile_photo']?.toString(),
      isVerify: json['is_verify'] is num
          ? (json['is_verify'] as num).toInt()
          : int.tryParse('${json['is_verify'] ?? 0}') ?? 0,
      isSvip: json['is_svip'] is num
          ? (json['is_svip'] as num).toInt()
          : int.tryParse('${json['is_svip'] ?? 0}') ?? 0,
      levelNumber: json['level_number'] is num
          ? (json['level_number'] as num).toInt()
          : int.tryParse('${json['level_number'] ?? 1}') ?? 1,
      coinCollectedLifetime: json['coin_collected_lifetime'] is num
          ? (json['coin_collected_lifetime'] as num).toInt()
          : int.tryParse('${json['coin_collected_lifetime'] ?? 0}') ?? 0,
    );
  }

  final int? id;
  final String? username;
  final String? fullname;
  final String? profilePhoto;
  final int isVerify;
  final int isSvip;
  final int levelNumber;
  final int coinCollectedLifetime;
}
