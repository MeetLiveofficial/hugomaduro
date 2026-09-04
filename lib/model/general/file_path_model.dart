class FilePathModel {
  FilePathModel({
    this.status,
    this.message,
    this.data,
  });

  FilePathModel.fromJson(dynamic json) {
    final raw = json['status'];
    if (raw is bool) {
      status = raw;
    } else if (raw is num) {
      status = raw != 0;
    } else if (raw is String) {
      final v = raw.toLowerCase().trim();
      status = v == 'true' || v == '1' || v == 'yes';
    } else {
      status = false;
    }
    message = json['message']?.toString();
    data = json['data']?.toString();
  }

  bool? status;
  String? message;
  String? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = status;
    map['message'] = message;
    map['data'] = data;
    return map;
  }
}
