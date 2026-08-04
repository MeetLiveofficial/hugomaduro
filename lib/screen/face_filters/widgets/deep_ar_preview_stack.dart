import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/manager/haptic_manager.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/screen/face_filters/services/deep_ar_service.dart';
import 'package:krimson/utilities/theme_res.dart';

/// Preview a pantalla completa con DeepAR (solo nativo).
class DeepArPreviewStack extends StatelessWidget {
  const DeepArPreviewStack({
    super.key,
    this.showLoading = true,
  });

  final bool showLoading;

  @override
  Widget build(BuildContext context) {
    final svc = DeepArService.instance;
    return ListenableBuilder(
      listenable: svc,
      builder: (context, _) {
        if (kIsWeb || !svc.isConfigured) {
          return const ColoredBox(
            color: Colors.black,
            child: Center(
              child: Text(
                'DeepAR no disponible',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          );
        }
        if (svc.controller == null) {
          return ColoredBox(
            color: Colors.black,
            child: Center(
              child: showLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'DeepAR no iniciado',
                      style: TextStyle(color: Colors.white70),
                    ),
            ),
          );
        }
        return ColoredBox(
          color: Colors.black,
          child: svc.buildPreview(),
        );
      },
    );
  }
}

/// Carrusel de filtros DeepAR del panel admin.
class DeepArFilterCarousel extends StatelessWidget {
  const DeepArFilterCarousel({
    super.key,
    required this.filters,
    required this.selectedId,
    required this.onSelected,
  });

  final List<DeepARFilters> filters;
  final int? selectedId;

  /// null = None (sin efecto).
  final ValueChanged<DeepARFilters?> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = <DeepARFilters?>[null, ...filters];
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final filter = items[index];
          final selected = filter == null
              ? selectedId == null
              : filter.id == selectedId;
          final title = filter?.title ?? 'None';
          final imageUrl = (filter?.image ?? '').trim();
          final thumb = imageUrl.isEmpty ? null : imageUrl.addBaseURL();

          return GestureDetector(
            onTap: () {
              HapticManager.shared.light();
              onSelected(filter);
            },
            child: AnimatedScale(
              scale: selected ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 160),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: selected ? 64 : 58,
                    height: selected ? 64 : 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black26,
                      border: Border.all(
                        color: selected
                            ? whitePure(context)
                            : whitePure(context).withValues(alpha: 0.45),
                        width: selected ? 3 : 1.5,
                      ),
                      image: thumb != null
                          ? DecorationImage(
                              image: NetworkImage(thumb),
                              fit: BoxFit.cover,
                            )
                          : null,
                      gradient: thumb == null
                          ? LinearGradient(
                              colors: [
                                Colors.grey.shade700,
                                Colors.grey.shade900,
                              ],
                            )
                          : null,
                    ),
                    child: thumb == null
                        ? Icon(
                            Icons.block,
                            color: whitePure(context),
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
                        color: whitePure(context).withValues(alpha: 0.85),
                        fontSize: 10,
                      ),
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
