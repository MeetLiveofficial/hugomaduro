import 'package:flutter/material.dart';

enum TermAndPrivacyType { privacyPolicy, termAndCondition }

class TermAndPrivacyScreen extends StatelessWidget {
  final TermAndPrivacyType type;

  const TermAndPrivacyScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('TermAndPrivacyScreen')),
    );
  }
}
