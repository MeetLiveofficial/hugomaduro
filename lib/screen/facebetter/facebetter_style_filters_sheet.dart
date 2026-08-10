import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/screen/deepar/deepar.dart';
import 'package:krimson/screen/face_filters/models/face_filter_effect.dart';
import 'package:krimson/screen/face_filters/widgets/face_filter_carousel.dart';

/// Panel inferior estilo FaceBetter (demo.facebetter.net).
/// Categorías: Beauty / Reshape / Makeup / Filter / Sticker / …
class FaceBetterStyleFiltersPanel extends StatefulWidget {
  const FaceBetterStyleFiltersPanel({
    super.key,
    required this.beautyOn,
    required this.onApply,
    required this.styleEffects,
    this.selectedFilterId,
    this.onStyleSelected,
    this.useDeepArFilters = false,
    this.deepArSelectedId,
    this.onDeepArStyleSelected,
    this.whiten,
    this.smooth,
    this.rosy,
    this.sharpen,
    this.slimFace,
    this.bigEye,
  });

  final RxBool beautyOn;
  final Future<void> Function() onApply;
  final Rx<FaceFilterId>? selectedFilterId;
  final List<FaceFilterEffect> styleEffects;
  final ValueChanged<FaceFilterId>? onStyleSelected;
  final bool useDeepArFilters;
  final RxnInt? deepArSelectedId;
  final ValueChanged<DeepARFilters?>? onDeepArStyleSelected;
  final RxDouble? whiten;
  final RxDouble? smooth;
  final RxDouble? rosy;
  final RxDouble? sharpen;
  final RxDouble? slimFace;
  final RxDouble? bigEye;

  @override
  State<FaceBetterStyleFiltersPanel> createState() =>
      _FaceBetterStyleFiltersPanelState();
}

enum _FbCategory {
  beauty,
  reshape,
  makeup,
  filter,
  sticker,
  body,
  virtualBg,
  quality,
}

enum _BeautyTool { off, whiten, smooth, rosy, sharpen }

enum _ReshapeTool { slimFace, bigEye }

enum _MakeupTool { blush, lipstick }

class _FaceBetterStyleFiltersPanelState
    extends State<FaceBetterStyleFiltersPanel> {
  _FbCategory _category = _FbCategory.beauty;
  _BeautyTool _beautyTool = _BeautyTool.smooth;
  _ReshapeTool _reshapeTool = _ReshapeTool.slimFace;
  _MakeupTool _makeupTool = _MakeupTool.blush;

  bool get _hasGpu =>
      widget.whiten != null &&
      widget.smooth != null &&
      widget.slimFace != null &&
      widget.bigEye != null;

  List<FaceFilterEffect> get _looks => widget.styleEffects
      .where((e) => e.id == FaceFilterId.none || e.id.isBeautyGpu)
      .toList();

  List<FaceFilterEffect> get _stickers => widget.styleEffects
      .where((e) => e.id != FaceFilterId.none && e.id.needsFaceMesh)
      .toList();

  RxDouble? get _activeSlider {
    switch (_category) {
      case _FbCategory.beauty:
        switch (_beautyTool) {
          case _BeautyTool.off:
            return null;
          case _BeautyTool.whiten:
            return widget.whiten;
          case _BeautyTool.smooth:
            return widget.smooth;
          case _BeautyTool.rosy:
            return widget.rosy;
          case _BeautyTool.sharpen:
            return widget.sharpen;
        }
      case _FbCategory.reshape:
        return _reshapeTool == _ReshapeTool.slimFace
            ? widget.slimFace
            : widget.bigEye;
      case _FbCategory.makeup:
        return widget.rosy;
      default:
        return null;
    }
  }

  Future<void> _resetBeauty() async {
    widget.beautyOn.value = false;
    widget.whiten?.value = 0;
    widget.smooth?.value = 0;
    widget.rosy?.value = 0;
    widget.sharpen?.value = 0;
    widget.slimFace?.value = 0;
    widget.bigEye?.value = 0;
    widget.selectedFilterId?.value = FaceFilterId.none;
    widget.onStyleSelected?.call(FaceFilterId.none);
    setState(() => _beautyTool = _BeautyTool.off);
    await widget.onApply();
  }

  Future<void> _pickBeauty(_BeautyTool tool) async {
    if (tool == _BeautyTool.off) {
      await _resetBeauty();
      return;
    }
    widget.beautyOn.value = true;
    setState(() => _beautyTool = tool);
    await widget.onApply();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.78),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 3,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            if (_hasGpu && _activeSlider != null)
              _FbIntensitySlider(
                value: _activeSlider!,
                onApply: widget.onApply,
              ),
            SizedBox(height: 92, child: _buildToolStrip()),
            const SizedBox(height: 4),
            _buildCategoryTabs(),
          ],
        ),
      ),
    );
  }

  Widget _buildToolStrip() {
    if (widget.useDeepArFilters) {
      return DeepArFilterCarousel(
        selectedId: widget.deepArSelectedId?.value,
        onSelected: (filter) {
          widget.beautyOn.value = filter != null;
          widget.onDeepArStyleSelected?.call(filter);
          widget.onApply();
        },
      );
    }

    switch (_category) {
      case _FbCategory.beauty:
        return _FbIconRow(
          children: [
            _FbToolIcon(
              icon: Icons.close,
              label: 'Close',
              selected: _beautyTool == _BeautyTool.off,
              onTap: () => _pickBeauty(_BeautyTool.off),
            ),
            _FbToolIcon(
              icon: Icons.face_retouching_natural,
              label: 'Whitening',
              selected: _beautyTool == _BeautyTool.whiten,
              onTap: () => _pickBeauty(_BeautyTool.whiten),
            ),
            _FbToolIcon(
              icon: Icons.blur_on,
              label: 'Smoothing',
              selected: _beautyTool == _BeautyTool.smooth,
              onTap: () => _pickBeauty(_BeautyTool.smooth),
            ),
            _FbToolIcon(
              icon: Icons.favorite,
              label: 'Rosiness',
              selected: _beautyTool == _BeautyTool.rosy,
              enabled: widget.rosy != null,
              onTap: () => _pickBeauty(_BeautyTool.rosy),
            ),
            _FbToolIcon(
              icon: Icons.auto_fix_high,
              label: 'Sharpen',
              selected: _beautyTool == _BeautyTool.sharpen,
              enabled: widget.sharpen != null,
              onTap: () => _pickBeauty(_BeautyTool.sharpen),
            ),
          ],
        );
      case _FbCategory.reshape:
        return _FbIconRow(
          children: [
            _FbToolIcon(
              icon: Icons.face_3_outlined,
              label: 'Slim Face',
              selected: _reshapeTool == _ReshapeTool.slimFace,
              onTap: () {
                widget.beautyOn.value = true;
                setState(() => _reshapeTool = _ReshapeTool.slimFace);
                widget.onApply();
              },
            ),
            _FbToolIcon(
              icon: Icons.visibility_outlined,
              label: 'Big Eye',
              selected: _reshapeTool == _ReshapeTool.bigEye,
              onTap: () {
                widget.beautyOn.value = true;
                setState(() => _reshapeTool = _ReshapeTool.bigEye);
                widget.onApply();
              },
            ),
          ],
        );
      case _FbCategory.makeup:
        return _FbIconRow(
          children: [
            _FbToolIcon(
              icon: Icons.brush_outlined,
              label: 'Blush',
              selected: _makeupTool == _MakeupTool.blush,
              enabled: widget.rosy != null,
              onTap: () {
                widget.beautyOn.value = true;
                setState(() => _makeupTool = _MakeupTool.blush);
                widget.onApply();
              },
            ),
            _FbToolIcon(
              icon: Icons.opacity,
              label: 'Lipstick',
              selected: _makeupTool == _MakeupTool.lipstick,
              enabled: widget.rosy != null,
              onTap: () {
                widget.beautyOn.value = true;
                setState(() => _makeupTool = _MakeupTool.lipstick);
                widget.onApply();
              },
            ),
          ],
        );
      case _FbCategory.filter:
        if (widget.onStyleSelected != null && widget.selectedFilterId != null) {
          return Obx(() => FaceFilterCarousel(
                selectedId: widget.selectedFilterId!.value,
                effects: _looks,
                onSelected: (id) {
                  widget.selectedFilterId!.value = id;
                  widget.beautyOn.value = id != FaceFilterId.none;
                  widget.onStyleSelected!(id);
                  widget.onApply();
                },
              ));
        }
        return const _FbSoonHint('Selecciona un look');
      case _FbCategory.sticker:
        if (_stickers.isEmpty ||
            widget.onStyleSelected == null ||
            widget.selectedFilterId == null) {
          return const _FbSoonHint('Stickers próximamente');
        }
        return Obx(() => FaceFilterCarousel(
              selectedId: widget.selectedFilterId!.value,
              effects: [
                const FaceFilterEffect(
                  id: FaceFilterId.none,
                  title: 'None',
                  icon: Icons.block,
                  accent: Color(0xFF9E9E9E),
                ),
                ..._stickers,
              ],
              onSelected: (id) {
                widget.selectedFilterId!.value = id;
                widget.beautyOn.value = id != FaceFilterId.none;
                widget.onStyleSelected!(id);
                widget.onApply();
              },
            ));
      case _FbCategory.body:
        return const _FbSoonHint('Body beauty próximamente');
      case _FbCategory.virtualBg:
        return const _FbSoonHint('Virtual BG próximamente');
      case _FbCategory.quality:
        return const _FbSoonHint('Calidad: Options → Calidad de video');
    }
  }

  Widget _buildCategoryTabs() {
    const tabs = <(_FbCategory, String)>[
      (_FbCategory.beauty, 'Beauty'),
      (_FbCategory.reshape, 'Reshape'),
      (_FbCategory.makeup, 'Makeup'),
      (_FbCategory.filter, 'Filter'),
      (_FbCategory.sticker, 'Sticker'),
      (_FbCategory.body, 'Body'),
      (_FbCategory.virtualBg, 'Virtual BG'),
      (_FbCategory.quality, 'Quality'),
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 18),
        itemBuilder: (context, i) {
          final (cat, label) = tabs[i];
          final selected = _category == cat;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _category = cat),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white54,
                  fontSize: selected ? 14 : 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FbIntensitySlider extends StatelessWidget {
  const _FbIntensitySlider({
    required this.value,
    required this.onApply,
  });

  final RxDouble value;
  final Future<void> Function() onApply;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
        child: Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: const SliderThemeData(
                  trackHeight: 2.5,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
                  overlayShape: RoundSliderOverlayShape(overlayRadius: 14),
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: Colors.white,
                ),
                child: Slider(
                  value: value.value.clamp(0, 100),
                  min: 0,
                  max: 100,
                  onChanged: (v) {
                    value.value = v;
                    onApply();
                  },
                ),
              ),
            ),
            SizedBox(
              width: 36,
              child: Text(
                '${value.value.round()}',
                textAlign: TextAlign.end,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _FbIconRow extends StatelessWidget {
  const _FbIconRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        for (final c in children) ...[
          c,
          const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _FbToolIcon extends StatelessWidget {
  const _FbToolIcon({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? Colors.white24
        : selected
            ? Colors.white
            : Colors.white70;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 68,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? Colors.white.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.08),
                  border: Border.all(
                    color: selected ? Colors.white : Colors.white24,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FbSoonHint extends StatelessWidget {
  const _FbSoonHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(color: Colors.white54, fontSize: 13),
      ),
    );
  }
}
