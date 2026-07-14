import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

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
    return const SizedBox(
      height: 80,
      child: Center(child: Text('Location error')),
    );
  }
}

class LocationSheet extends StatelessWidget {
  const LocationSheet({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
