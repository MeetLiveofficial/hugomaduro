import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:krimson/languages/languages_keys.dart';

class LocationErrorWidget extends StatelessWidget {
  final bool showError;
  final void Function(Position position)? onCompletion;

  const LocationErrorWidget({
    super.key,
    required this.showError,
    this.onCompletion,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Center(child: Text(LKey.locationError.tr)),
    );
  }
}

class LocationSheet extends StatelessWidget {
  const LocationSheet({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
