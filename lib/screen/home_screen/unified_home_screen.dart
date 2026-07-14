import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/dashboard_screen/dashboard_screen_controller.dart';
import 'package:krimson/screen/feed_screen/feed_screen.dart';
import 'package:krimson/screen/home_screen/home_screen.dart';

/// Unifica Reels (videos) + Feed (posts/stories) en un solo destino del bottom nav.
class UnifiedHomeScreen extends StatelessWidget {
  final User? myUser;

  const UnifiedHomeScreen({super.key, this.myUser});

  @override
  Widget build(BuildContext context) {
    final dash = Get.find<DashboardScreenController>();
    return Obx(() {
      final mode = dash.homeTabMode.value;
      return IndexedStack(
        index: mode == HomeTabMode.reels ? 0 : 1,
        children: [
          const HomeScreen(),
          FeedScreen(myUser: myUser),
        ],
      );
    });
  }
}
