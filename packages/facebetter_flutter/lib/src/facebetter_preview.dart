import 'package:flutter/material.dart';

import 'facebetter_controller.dart';

/// Preview zero-copy: [Texture] alimentada por FaceBetter nativo.
class FaceBetterPreview extends StatelessWidget {
  const FaceBetterPreview({
    super.key,
    required this.controller,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  final FaceBetterController controller;
  final BoxFit fit;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final id = controller.textureId;
        if (id == null) {
          return placeholder ??
              const ColoredBox(
                color: Colors.black,
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
        }
        return FittedBox(
          fit: fit,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: 720,
            height: 1280,
            child: Texture(textureId: id),
          ),
        );
      },
    );
  }
}
