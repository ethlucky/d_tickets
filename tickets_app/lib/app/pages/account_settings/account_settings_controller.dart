import 'package:get/get.dart';

/// 账户设置页面控制器
class AccountSettingsController extends GetxController {
  // 用户信息
  final userInfo = {
    'name': 'Ethan Carter',
    'username': '@ethan.carter',
    'joinDate': 'Joined in 2022',
    'avatar': '',
  }.obs;

  /// 个人资料设置
  void profileSettings() {
    Get.snackbar('个人资料', '个人资料设置功能开发中...', snackPosition: SnackPosition.TOP);
  }

  /// 通知设置
  void notificationSettings() {
    Get.snackbar('通知', '通知设置功能开发中...', snackPosition: SnackPosition.TOP);
  }

  /// 应用设置
  void appSettings() {
    Get.snackbar('设置', '应用设置功能开发中...', snackPosition: SnackPosition.TOP);
  }

  /// 关联钱包
  void linkedWallets() {
    Get.snackbar('钱包', '关联钱包功能开发中...', snackPosition: SnackPosition.TOP);
  }

  /// 交易历史
  void transactionHistory() {
    Get.snackbar('交易历史', '交易历史功能开发中...', snackPosition: SnackPosition.TOP);
  }

  /// 帮助中心
  void helpCenter() {
    Get.snackbar('帮助', '帮助中心功能开发中...', snackPosition: SnackPosition.TOP);
  }

  /// 联系我们
  void contactUs() {
    Get.snackbar('联系', '联系我们功能开发中...', snackPosition: SnackPosition.TOP);
  }

  /// 底部导航 - 首页
  void onHomeTap() {
    Get.offAllNamed('/');
  }

  /// 底部导航 - 探索
  void onExploreTap() {
    Get.toNamed('/events');
  }

  /// 底部导航 - 票券
  void onTicketsTap() {
    Get.toNamed('/my-tickets-demo');
  }

  /// 底部导航 - 账户（当前页面）
  void onAccountTap() {
    // 当前页面，无需操作
  }
}
