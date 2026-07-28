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
  });

  final FaceFilterId selectedId;
  final ValueChanged<FaceFilterId> onSelected;

  @override
  State<FaceFilterCarousel> createState() => _FaceFilterCarouselState();
}

class _FaceFilterCarouselState extends State<FaceFilterCarousel> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void didUpdateWidget(covariant FaceFilterCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedId != widget.selectedId) _scrollToSelected();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int get _selectedIndex {
    final i = FaceFilterEffect.catalog
        .indexWhere((e) => e.id == widget.selectedId);
    return i < 0 ? 0 : i;
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
    return SizedBox(
      height: 86,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: FaceFilterEffect.catalog.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final effect = FaceFilterEffect.catalog[index];
          final selected = effect.id == widget.selectedId;
          return GestureDetector(
            onTap: () {
              HapticManager.shared.light();
              widget.onSelected(effect.id);
            },
            child: AnimatedScale(
              scale: selected ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 160),
              child: Container(
                width: selected ? 64 : 58,
                height: selected ? 64 : 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
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
                ),
                child: Icon(effect.icon, color: whitePure(context), size: 24),
              ),
            ),
          );
        },
      ),
    );
  }
}
