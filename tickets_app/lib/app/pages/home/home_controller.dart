import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

class HomeController extends GetxController {
  // 精选活动数据
  final List<Map<String, dynamic>> featuredEvents = [
    {
      'title': 'Live Music Festival',
      'subtitle': 'Featuring top artists',
      'gradient': [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
    },
    {
      'title': 'NBA Playoffs',
      'subtitle': 'Game 7',
      'gradient': [const Color(0xFFEF4444), const Color(0xFFF97316)],
    },
    {
      'title': 'Blockbuster Movie Premiere',
      'subtitle': 'Limited time only',
      'gradient': [const Color(0xFF10B981), const Color(0xFF059669)],
    },
  ];

  // 即将到来的活动数据
  final List<Map<String, dynamic>> upcomingEvents = [
    {
      'title': 'Solana 钱包演示',
      'subtitle': 'Mobile Wallet Adapter Demo',
      'gradient': [const Color(0xFFDC2626), const Color(0xFFEA580C)],
      'type': 'solana_demo',
    },
    {
      'title': 'Tech Conference',
      'subtitle': 'Innovation and Networking',
      'gradient': [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
    },
    {
      'title': 'Art Exhibition',
      'subtitle': 'Modern and Contemporary Art',
      'gradient': [const Color(0xFFEC4899), const Color(0xFFBE185D)],
    },
    {
      'title': 'Local Theater',
      'subtitle': 'A Classic Play',
      'gradient': [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
    },
  ];

  // 搜索功能
  void onSearchTap() {
    // 跳转到搜索页面
    Get.toNamed(AppRoutes.getSearchRoute());
  }

  // 精选活动点击
  void onFeaturedEventTap(int index) {
    // 跳转到活动详情页面
    Get.toNamed(AppRoutes.getEventDetailRoute('event_$index'));
  }

  // 即将到来的活动点击
  void onUpcomingEventTap(int index) {
    final event = upcomingEvents[index];
    if (event['type'] == 'solana_demo') {
      // 跳转到 Solana 钱包演示页面
      Get.toNamed(AppRoutes.getSolanaWalletDemoRoute());
    } else {
      // 跳转到活动详情页面
      Get.toNamed(AppRoutes.getEventDetailRoute('upcoming_event_$index'));
    }
  }

  /// 处理底部导航栏点击
  void onBottomNavTap(int index) {
    switch (index) {
      case 0:
        // Home - 当前页面，无需操作
        break;
      case 1:
        // Explore - 跳转到活动页面
        Get.toNamed(AppRoutes.getEventsRoute());
        break;
      case 2:
        // My Tickets - 跳转到我的票券页面
        Get.toNamed(AppRoutes.getMyTicketsDemoRoute());
        break;
      case 3:
        // Profile - 跳转到账户设置页面
        Get.toNamed(AppRoutes.getAccountSettingsDemoRoute());
        break;
    }
  }
}
