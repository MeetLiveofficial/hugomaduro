import 'package:flutter/material.dart';
import 'package:krimson/screen/camera_screen/camera_screen.dart';

class CameraBottomView extends StatelessWidget {
  final CameraScreenType cameraType;

  const CameraBottomView({super.key, required this.cameraType});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 80);
  }
}
