import 'package:flutter/material.dart';
import 'package:krimson/common/manager/haptic_manager.dart';
import 'package:krimson/screen/face_filters/models/face_filter_effect.dart';
import 'package:krimson/utilities/theme_res.dart';

/// Carrusel de filtros con nombre visible y color único por look.
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

  void _scrollToSelected() {
    if (!_scrollController.hasClients) return;
    const itemExtent = 78.0;
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
      height: 96,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final effect = items[index];
          final selected = effect.id == widget.selectedId;
          final size = selected ? 56.0 : 50.0;
          return GestureDetector(
            onTap: () {
              HapticManager.shared.light();
              widget.onSelected(effect.id);
            },
            child: SizedBox(
              width: 68,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          effect.accent,
                          effect.accent.withValues(alpha: 0.55),
                          Colors.black.withValues(alpha: 0.45),
                        ],
                      ),
                      border: Border.all(
                        color: selected
                            ? whitePure(context)
                            : whitePure(context).withValues(alpha: 0.4),
                        width: selected ? 2.5 : 1.2,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: effect.accent.withValues(alpha: 0.55),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (effect.hasPhotoThumb)
                          ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              effect.accent.withValues(alpha: 0.45),
                              BlendMode.softLight,
                            ),
                            child: effect.iconUrl != null &&
                                    effect.iconUrl!.isNotEmpty
                                ? Image.network(
                                    effect.iconUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox.shrink(),
                                  )
                                : Image.asset(
                                    effect.assetIcon!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox.shrink(),
                                  ),
                          ),
                        Center(
                          child: Icon(
                            effect.icon,
                            color: whitePure(context),
                            size: selected ? 24 : 20,
                            shadows: const [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    effect.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontSize: 10,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
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
