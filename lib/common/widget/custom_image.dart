import 'package:cached_network_image/cached_network_image.dart';
import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shimmer/shimmer.dart';
import 'package:krimson/utilities/app_res.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/style_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class CustomImage extends StatelessWidget {
  final Size size;
  final double strokeWidth;
  final String? image;
  final double radius;
  final double? cornerSmoothing;
  final VoidCallback? onTap;
  final bool isShowPlaceHolder;
  final Color? strokeColor;
  final BoxFit? fit;
  final bool isImageLoaderVisible;
  final String? fullName;
  final bool isStokeOutSide;
  final String? placeHolderImage;
  /// When set (e.g. gift GIFs), uses [CachedNetworkImage] even on web
  /// so images persist in disk cache instead of reloading every open.
  final BaseCacheManager? cacheManager;

  const CustomImage({
    super.key,
    required this.size,
    this.strokeWidth = 0,
    this.image,
    this.radius = 180,
    this.onTap,
    this.cornerSmoothing,
    this.isShowPlaceHolder = false,
    this.strokeColor,
    this.fit,
    this.isImageLoaderVisible = true,
    this.fullName,
    this.isStokeOutSide = true,
    this.placeHolderImage,
    this.cacheManager,
  });

  @override
  Widget build(BuildContext context) {
    // En grids Quilted/Staggered el Size suele ser infinity:
    // hay que resolver con LayoutBuilder para llenar la celda sin romper el layout.
    final needsResolve = !size.width.isFinite || !size.height.isFinite;
    if (needsResolve) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final resolved = Size(
            size.width.isFinite
                ? size.width
                : (constraints.maxWidth.isFinite ? constraints.maxWidth : 0),
            size.height.isFinite
                ? size.height
                : (constraints.maxHeight.isFinite ? constraints.maxHeight : 0),
          );
          return CustomImage(
            size: resolved,
            strokeWidth: strokeWidth,
            image: image,
            radius: radius,
            cornerSmoothing: this.cornerSmoothing,
            onTap: onTap,
            isShowPlaceHolder: isShowPlaceHolder,
            strokeColor: strokeColor,
            fit: fit ?? BoxFit.cover,
            isImageLoaderVisible: isImageLoaderVisible,
            fullName: fullName,
            isStokeOutSide: isStokeOutSide,
            placeHolderImage: placeHolderImage,
            cacheManager: cacheManager,
          );
        },
      );
    }

    final imageUrl = image ?? '';
    final cornerSmoothing = this.cornerSmoothing ?? 0;
    final content = imageUrl.isEmpty
        ? ImageErrorWidget(
            size: size,
            radius: radius,
            cornerSmoothing: cornerSmoothing,
            isShowPlaceHolder: isShowPlaceHolder,
            fullName: fullName,
            placeHolderImage: placeHolderImage,
          )
        : _NetworkImage(
            imageUrl: imageUrl,
            size: size,
            radius: radius,
            fit: fit ?? BoxFit.cover,
            isImageLoaderVisible: isImageLoaderVisible,
            cornerSmoothing: cornerSmoothing,
            isShowPlaceHolder: isShowPlaceHolder,
            fullName: fullName,
            placeHolderImage: placeHolderImage,
            cacheManager: cacheManager,
          );

    // On web, ClipSmoothRect rasterizes children and breaks HTML <img>
    // (CORS). Prefer ClipRRect so WebHtmlElementStrategy can display media.
    final clipped = kIsWeb
        ? ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: content,
          )
        : ClipSmoothRect(
            radius: SmoothBorderRadius(
                cornerRadius: radius, cornerSmoothing: cornerSmoothing),
            child: content,
          );

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: fit == BoxFit.fitWidth ? null : size.height,
        width: size.width,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(
                    imageUrl.isEmpty || !isStokeOutSide ? 0 : strokeWidth),
                child: clipped,
              ),
            ),
            if (strokeWidth > 0)
              Positioned.fill(
                child: Container(
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(
                    shape: SmoothRectangleBorder(
                      borderRadius: SmoothBorderRadius(cornerRadius: radius),
                      side: BorderSide(
                          color: strokeColor ??
                              whitePure(context).withValues(alpha: .3),
                          width: strokeWidth),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// On web, prefer HTML &lt;img&gt; to avoid CORS failures with XHR/CachedNetworkImage.
class _NetworkImage extends StatelessWidget {
  final String imageUrl;
  final Size size;
  final double radius;
  final BoxFit fit;
  final bool isImageLoaderVisible;
  final double cornerSmoothing;
  final bool isShowPlaceHolder;
  final String? fullName;
  final String? placeHolderImage;
  final BaseCacheManager? cacheManager;

  const _NetworkImage({
    required this.imageUrl,
    required this.size,
    required this.radius,
    required this.fit,
    required this.isImageLoaderVisible,
    required this.cornerSmoothing,
    required this.isShowPlaceHolder,
    this.fullName,
    this.placeHolderImage,
    this.cacheManager,
  });

  Widget _error(BuildContext context) => ImageErrorWidget(
        size: size,
        radius: radius,
        cornerSmoothing: cornerSmoothing,
        isShowPlaceHolder: isShowPlaceHolder,
        fullName: fullName,
        placeHolderImage: placeHolderImage,
      );

  Widget _placeholder(BuildContext context) {
    if (!isImageLoaderVisible) return const SizedBox.expand();
    return Shimmer.fromColors(
      baseColor: bgGrey(context),
      highlightColor: bgMediumGrey(context),
      child: Container(
        height: size.height.isFinite ? size.height : double.infinity,
        width: size.width.isFinite ? size.width : double.infinity,
        color: bgGrey(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = size.width.isFinite ? size.width : null;
    final h = size.height.isFinite ? size.height : null;
    final useDiskCache = cacheManager != null || !kIsWeb;

    // Gift (and similar) media: CachedNetworkImage + disk cache on all
    // platforms. Other web images keep HTML <img> to avoid CORS failures.
    if (useDiskCache) {
      return SizedBox.expand(
        child: CachedNetworkImage(
          fit: fit,
          imageUrl: imageUrl,
          cacheKey: imageUrl,
          cacheManager: cacheManager,
          width: w,
          height: h,
          fadeInDuration: const Duration(milliseconds: 120),
          fadeOutDuration: const Duration(milliseconds: 80),
          placeholder: (context, url) => _placeholder(context),
          errorWidget: (context, error, stackTrace) {
            if (kIsWeb && cacheManager != null) {
              // CORS fallback for web when XHR cache download fails.
              return Image.network(
                imageUrl,
                fit: fit,
                width: w,
                height: h,
                gaplessPlayback: true,
                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                errorBuilder: (context, error, stackTrace) => _error(context),
              );
            }
            return _error(context);
          },
        ),
      );
    }

    return SizedBox.expand(
      child: Image.network(
        imageUrl,
        fit: fit,
        width: w,
        height: h,
        gaplessPlayback: true,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        errorBuilder: (context, error, stackTrace) => _error(context),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return SizedBox.expand(child: child);
          }
          return _placeholder(context);
        },
      ),
    );
  }
}

class ImageErrorWidget extends StatelessWidget {
  final double radius;
  final double cornerSmoothing;
  final bool isShowPlaceHolder;
  final Size size;
  final String? fullName;
  final double? placeHolderColorOpacity;
  final String? placeHolderImage;

  const ImageErrorWidget(
      {super.key,
      required this.radius,
      required this.cornerSmoothing,
      this.isShowPlaceHolder = false,
      required this.size,
      this.fullName,
      this.placeHolderColorOpacity,
      this.placeHolderImage});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Container(
        decoration: ShapeDecoration(
          shape: SmoothRectangleBorder(
              borderRadius: SmoothBorderRadius(
                  cornerRadius: radius, cornerSmoothing: cornerSmoothing)),
          gradient: isShowPlaceHolder
              ? StyleRes.disabledGreyGradient(
                  opacity: placeHolderColorOpacity ?? 1)
              : StyleRes.themeGradient,
        ),
        alignment: Alignment.center,
        child: isShowPlaceHolder
            ? LayoutBuilder(builder: (context, constraints) {
                final side = (constraints.biggest.shortestSide / 2)
                    .clamp(18.0, 72.0)
                    .toDouble();
                return Image.asset(placeHolderImage ?? AssetRes.icNoImage,
                    height: side,
                    width: side,
                    color: textDarkGrey(context));
              })
            : Text(
                (fullName?[0] ?? AppRes.appName[0]).toUpperCase(),
                style: TextStyleCustom.unboundedMedium500(
                    fontSize: size.height.isFinite && size.height > 0
                        ? (size.height / 2.4).clamp(16.0, 36.0)
                        : 20,
                    color: whitePure(context)),
              ),
      ),
    );
  }
}
