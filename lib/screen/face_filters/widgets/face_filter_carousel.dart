import 'package:flutter/material.dart';
import 'package:krimson/common/manager/haptic_manager.dart';
import 'package:krimson/screen/face_filters/models/face_filter_effect.dart';
import 'package:krimson/utilities/theme_res.dart';

/// TikTok-style horizontal strip of circular effect thumbnails.
class FaceFilterCarousel extends StatefulWidget {
  const FaceFilterCarousel({
    super.key,
    required this.selectedId,
    required this.onSelected,
    this.effects,
  });

  final FaceFilterId selectedId;
  final ValueChanged<FaceFilterId> onSelected;
  /// Si es null, usa [FaceFilterEffect.catalog] (offline / builtin).
  final List<FaceFilterEffect>? effects;

  @override
  State<FaceFilterCarousel> createState() => _FaceFilterCarouselState();
}

class _FaceFilterCarouselState extends State<FaceFilterCarousel> {
  late final ScrollController _scrollController;

  List<FaceFilterEffect> get _effects =>
      widget.effects ?? FaceFilterEffect.catalog;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void didUpdateWidget(covariant FaceFilterCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedId != widget.selectedId ||
        oldWidget.effects != widget.effects) {
      _scrollToSelected();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int get _selectedIndex {
    final i = _effects.indexWhere((e) => e.id == widget.selectedId);
    return i < 0 ? 0 : i;
  }

  DecorationImage? _thumbImage(FaceFilterEffect effect) {
    final url = effect.iconUrl;
    if (url != null && url.isNotEmpty) {
      return DecorationImage(
        image: NetworkImage(url),
        fit: BoxFit.cover,
      );
    }
    final asset = effect.assetIcon;
    if (asset != null && asset.isNotEmpty) {
      return DecorationImage(
        image: AssetImage(asset),
        fit: BoxFit.cover,
      );
    }
    return null;
  }

  void _scrollToSelected() {
    if (!_scrollController.hasClients) return;
    const itemExtent = 76.0;
    final target = (_selectedIndex * itemExtent) -
        (MediaQuery.sizeOf(context).width / 2) +
        (itemExtent / 2) +
        16;
    _scrollController.animateTo(
      target.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _effects;
    return SizedBox(
      height: 86,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final effect = items[index];
          final selected = effect.id == widget.selectedId;
          return GestureDetector(
            onTap: () {
              HapticManager.shared.light();
              widget.onSelected(effect.id);
            },
            child: AnimatedScale(
              scale: selected ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 160),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: selected ? 64 : 58,
                    height: selected ? 64 : 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: effect.hasPhotoThumb
                          ? Colors.black26
                          : null,
                      gradient: effect.hasPhotoThumb
                          ? null
                          : LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                effect.accent,
                                effect.accent.withValues(alpha: 0.55),
                                Colors.black.withValues(alpha: 0.35),
                              ],
                            ),
                      border: Border.all(
                        color: selected
                            ? whitePure(context)
                            : whitePure(context).withValues(alpha: 0.45),
                        width: selected ? 3 : 1.5,
                      ),
                      image: _thumbImage(effect),
                    ),
                    child: effect.hasPhotoThumb
                        ? null
                        : Icon(effect.icon,
                            color: whitePure(context), size: 24),
                  ),
                  if (effect.isPremium)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFD740),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lock,
                            size: 10, color: Colors.black87),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
