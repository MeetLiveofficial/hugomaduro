import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/screen/coin_wallet_screen/wompi_checkout_frame.dart';

/// Pago con tarjeta dentro de la app, servido por nexusdevtech.com.
class WompiCheckoutScreen extends StatelessWidget {
  const WompiCheckoutScreen({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF09090B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Pagar'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: Get.back,
        ),
      ),
      body: WompiCheckoutFrame(url: url),
    );
  }
}
