import 'package:flutter/material.dart';
import 'package:krimson/model/user_model/user_model.dart';

class SubscriptionScreen extends StatelessWidget {
  final Function(User? user)? onUpdateUser;

  const SubscriptionScreen({super.key, this.onUpdateUser});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('SubscriptionScreen')),
    );
  }
}
