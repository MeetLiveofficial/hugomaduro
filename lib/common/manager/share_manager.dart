import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:krimson/common/manager/content_protection.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/service/api/post_service.dart';
import 'package:krimson/model/post_story/post_model.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/share_sheet_widget/share_sheet_widget.dart';
import 'package:krimson/utilities/const_res.dart';

enum ShareKeys {
  reel('reel'),
  post('post'),
  user("user");

  const ShareKeys(this.value);

  final String value;
}

class ShareManager {
  static var shared = ShareManager();
  var isListenerConfigured = false;

  void listen(Function(String key, int value) completion) {
    if (isListenerConfigured) return;
    isListenerConfigured = true;
    AppLinks().uriLinkStream.listen((uri) {
      Loggers.info('Share Link Opened: $uri ${uri.pathSegments} ${uri.path}');
      if (uri.pathSegments.isNotEmpty) {
        var encoded = uri.pathSegments.last;
        Loggers.success(encoded);
        var decoded = safeBase64Decode(encoded);

        var values = decoded.split('_');
        completion(values.first, int.parse(values.last));
      }
    });
  }

  void getValuesFromURL(
      {required String url,
      required Function(String key, int value) completion}) {
    var uri = Uri.parse(url);
    if (uri.pathSegments.isNotEmpty) {
      var encoded = uri.pathSegments.last;
      Loggers.success(encoded);
      var decoded = safeBase64Decode(encoded);

      var values = decoded.split('_');
      completion(values.first, int.parse(values.last));
    }
  }

  void shareTheContent({required ShareKeys key, required int value}) {
    if (!ContentProtection.ensureShareAllowed()) return;
    final encoded = safeBase64Encode('${key.value}_$value');
    final url = '${baseURL}s/$encoded';
    final context = Get.context!;

    final box = context.findRenderObject() as RenderBox?;
    final origin = box!.localToGlobal(Offset.zero) & box.size;

    SharePlus.instance
        .share(ShareParams(uri: Uri.parse(url), sharePositionOrigin: origin));
  }

  String getLink({required ShareKeys key, required int value}) {
    final encoded = safeBase64Encode('${key.value}_$value');
    return '${baseURL}s/$encoded';
  }

  String safeBase64Encode(String input) {
    String encoded = base64.encode(utf8.encode(input));
    return encoded.replaceAll('=', '');
  }

  String safeBase64Decode(String input) {
    input = input.trim();
    input = input.replaceAll(RegExp(r'=+$'), '');
    while (input.length % 4 != 0) {
      input += '=';
    }
    return utf8.decode(base64.decode(input));
  }

  void showCustomShareSheet({
    User? user,
    Post? post,
    required ShareKeys keys,
    VoidCallback? onShareSuccess,
  }) {
    if (!ContentProtection.ensureShareAllowed()) return;

    int? id = keys == ShareKeys.user ? user?.id : post?.id;
    String link = getLink(key: keys, value: id ?? -1);
    Get.bottomSheet(
      ShareSheetWidget(
        onMoreTap: () {
          Get.back();
          if (keys == ShareKeys.post || keys == ShareKeys.reel) {
            shareTheContent(key: keys, value: post?.id ?? -1);
            _increaseShareCount(post?.id, onShareSuccess);
          } else if (keys == ShareKeys.user) {
            shareTheContent(key: keys, value: user?.id ?? -1);
          }
        },
        post: post,
        link: link,
        isDownloadShow: keys == ShareKeys.reel && ContentProtection.canDownload,
        keys: keys,
        onCallBack: onShareSuccess,
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _increaseShareCount(int? postId, VoidCallback? onSuccess) async {
    if (postId == null) return;
    final response =
        await PostService.instance.increaseShareCount(postId: postId);
    if (response.status == true) {
      onSuccess?.call();
    }
  }
}
