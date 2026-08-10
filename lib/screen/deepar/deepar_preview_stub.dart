import 'package:flutter/material.dart';
import 'package:krimson/screen/deepar/deepar_camera_controller.dart';
import 'package:krimson/utilities/color_res.dart';

class DeepArPreview extends StatelessWidget {
  const DeepArPreview({
    super.key,
    required this.controller,
    this.fit = BoxFit.cover,
  });

  final DeepArCameraController controller;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: ColorRes.bgVoid,
      child: Center(
        child: Text(
          'DeepAR is not available on web',
          style: TextStyle(color: ColorRes.whitePure),
        ),
      ),
    );
  }
}
