import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/model/post_story/post_model.dart';
import 'package:krimson/screen/chat_screen/widget/chat_center_message_view.dart';
import 'package:krimson/utilities/theme_res.dart';

/// Preview de imagen/video thumbnail compatible con Web y móvil.
class SafePickedImage extends StatelessWidget {
  final String path;
  final XFile? xFile;
  final BoxFit fit;
  final double? width;
  final double? height;

  const SafePickedImage({
    super.key,
    required this.path,
    this.xFile,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (path.startsWith('http://') ||
        path.startsWith('https://') ||
        path.startsWith('blob:') ||
        path.startsWith('data:')) {
      return Image.network(
        path,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => _error(context),
      );
    }

    if (kIsWeb) {
      final source = xFile ?? XFile(path);
      return FutureBuilder(
        future: source.readAsBytes(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
                child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2)));
          }
          return Image.memory(
            snap.data!,
            fit: fit,
            width: width,
            height: height,
            errorBuilder: (_, __, ___) => _error(context),
          );
        },
      );
    }

    return Image.file(
      File(path),
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, __, ___) => _error(context),
    );
  }

  Widget _error(BuildContext context) => Icon(
        Icons.broken_image_outlined,
        size: 48,
        color: textLightGrey(context),
      );
}

class ChatBubble extends StatelessWidget {
  final bool isMe;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const ChatBubble({
    super.key,
    required this.isMe,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: Get.width * 0.72),
      padding: padding,
      decoration: ShapeDecoration(
        color: isMe
            ? themeAccentSolid(context).withValues(alpha: 0.12)
            : bgGrey(context),
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(cornerRadius: 14, cornerSmoothing: 1),
        ),
        shadows: messageBubbleShadow,
      ),
      child: child,
    );
  }
}

class ChatNetworkMedia extends StatelessWidget {
  final String? path;
  final double width;
  final double height;
  final BoxFit fit;

  const ChatNetworkMedia({
    super.key,
    required this.path,
    this.width = 220,
    this.height = 220,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final url = (path ?? '').addBaseURL();
    if (url.isEmpty) {
      return SizedBox(
        width: width,
        height: height,
        child: Icon(Icons.image_not_supported_outlined,
            color: textLightGrey(context)),
      );
    }

    if (kIsWeb) {
      return Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => SizedBox(
          width: width,
          height: height,
          child: Icon(Icons.broken_image_outlined, color: textLightGrey(context)),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      errorWidget: (_, __, ___) => SizedBox(
        width: width,
        height: height,
        child: Icon(Icons.broken_image_outlined, color: textLightGrey(context)),
      ),
    );
  }
}

String? decodePostThumb(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    final post = Post.fromJson(jsonDecode(raw));
    return post.thumbnail ??
        (post.images?.isNotEmpty == true ? post.images!.first.image : null) ??
        post.video;
  } catch (_) {
    return null;
  }
}

String decodePostTitle(String? raw) {
  if (raw == null || raw.isEmpty) return 'Post';
  try {
    final post = Post.fromJson(jsonDecode(raw));
    final desc = (post.description ?? '').trim();
    return desc.isEmpty ? 'Shared a post' : desc;
  } catch (_) {
    return 'Post';
  }
}
