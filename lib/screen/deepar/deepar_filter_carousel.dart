import 'package:flutter/material.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/screen/deepar/deepar_runtime.dart';
import 'package:krimson/utilities/color_res.dart';

/// Carrusel de filtros DeepAR desde Settings (`deepARFilters`).
class DeepArFilterCarousel extends StatelessWidget {
  const DeepArFilterCarousel({
    super.key,
    required this.selectedId,
    required this.onSelected,
    this.filters,
  });

  final int? selectedId;
  final ValueChanged<DeepARFilters?> onSelected;
  final List<DeepARFilters>? filters;

  @override
  Widget build(BuildContext context) {
    final list = filters ?? DeepArRuntime.filters();
    final items = <DeepARFilters?>[
      null, // None
      ...list,
    ];

    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          final isNone = item == null;
          final selected = isNone
              ? selectedId == null
              : selectedId != null && selectedId == item.id;
          final title = isNone ? 'None' : (item.title ?? 'Filter');
          final imageUrl = isNone ? null : (item.image ?? '').addBaseURL();

          return GestureDetector(
            onTap: () => onSelected(item),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? ColorRes.accentRose
                          : ColorRes.whitePure.withValues(alpha: 0.35),
                      width: selected ? 2.5 : 1,
                    ),
                    color: ColorRes.whitePure.withValues(alpha: 0.08),
                    image: imageUrl != null && imageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(imageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: isNone
                      ? Icon(
                          Icons.block,
                          color: ColorRes.whitePure.withValues(alpha: 0.8),
                          size: 22,
                        )
                      : null,
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 64,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ColorRes.whitePure.withValues(alpha: 0.85),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
