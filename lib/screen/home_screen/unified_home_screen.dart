import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/dashboard_screen/dashboard_screen_controller.dart';
import 'package:krimson/screen/feed_screen/feed_screen.dart';
import 'package:krimson/screen/home_screen/home_screen.dart';
import 'package:krimson/screen/leaderboard_screen/leaderboard_screen.dart';
import 'package:krimson/screen/live_stream/live_active_discovery/live_active_discovery_screen.dart';

/// Unifica LIVE/Ranking + Reels + Feed en el tab Home.
/// Streamer: Ranking (no discovery de Lives). Cliente: Lives activos.
class UnifiedHomeScreen extends StatelessWidget {
  final User? myUser;

  const UnifiedHomeScreen({super.key, this.myUser});

  @override
  Widget build(BuildContext context) {
    final dash = Get.find<DashboardScreenController>();
    final streamerHome = AppRole.isStreamer(myUser);
    return Obx(() {
      final mode = dash.homeTabMode.value;
      final index = switch (mode) {
        HomeTabMode.live => 0,
        HomeTabMode.reels => 1,
        HomeTabMode.feed => 2,
      };
      return IndexedStack(
        index: index,
        children: [
          streamerHome
              ? const LeaderboardScreen(asTab: true)
              : const LiveActiveDiscoveryScreen(),
          const HomeScreen(),
          FeedScreen(myUser: myUser),
        ],
      );
    });
  }
}
