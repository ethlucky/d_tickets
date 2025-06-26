import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'account_settings_controller.dart';

/// 账户设置页面视图
class AccountSettingsView extends GetView<AccountSettingsController> {
  const AccountSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Column(
          children: [
            // 顶部导航栏
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 返回按钮
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF121417),
                        size: 24,
                      ),
                    ),
                  ),
                  // 标题
                  const Text(
                    'Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      height: 1.28,
                      color: Color(0xFF121417),
                    ),
                  ),
                  const SizedBox(width: 48), // 占位
                ],
              ),
            ),

            // 主要内容
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // 用户信息区域
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // 头像
                          Container(
                            width: 128,
                            height: 128,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(64),
                              color: const Color(0xFFE0E0E0),
                              // 这里应该是用户头像
                            ),
                          ),
                          const SizedBox(height: 16),
                          // 用户信息
                          Obx(
                            () => Column(
                              children: [
                                Text(
                                  controller.userInfo['name']!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 22,
                                    height: 1.27,
                                    color: Color(0xFF121417),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  controller.userInfo['username']!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w400,
                                    fontSize: 16,
                                    height: 1.5,
                                    color: Color(0xFF61738A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  controller.userInfo['joinDate']!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w400,
                                    fontSize: 16,
                                    height: 1.5,
                                    color: Color(0xFF61738A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // General 部分
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'General',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            height: 1.28,
                            color: Color(0xFF121417),
                          ),
                        ),
                      ),
                    ),

                    // 设置项列表
                    _buildSettingItem(
                      icon: Icons.person_outline,
                      title: 'Profile',
                      onTap: controller.profileSettings,
                    ),
                    _buildSettingItem(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      onTap: controller.notificationSettings,
                    ),
                    _buildSettingItem(
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      onTap: controller.appSettings,
                    ),

                    // Wallet 部分
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Wallet',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            height: 1.28,
                            color: Color(0xFF121417),
                          ),
                        ),
                      ),
                    ),

                    _buildSettingItem(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Linked Wallets',
                      onTap: controller.linkedWallets,
                    ),
                    _buildSettingItem(
                      icon: Icons.history,
                      title: 'Transaction History',
                      onTap: controller.transactionHistory,
                    ),

                    // Support 部分
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Support',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            height: 1.28,
                            color: Color(0xFF121417),
                          ),
                        ),
                      ),
                    ),

                    _buildSettingItem(
                      icon: Icons.help_outline,
                      title: 'Help Center',
                      onTap: controller.helpCenter,
                    ),
                    _buildSettingItem(
                      icon: Icons.contact_support_outlined,
                      title: 'Contact Us',
                      onTap: controller.contactUs,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // 底部导航栏
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFAFAFA),
          border: Border(top: BorderSide(color: Color(0xFFEDEDED), width: 1)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // 首页
            _buildBottomNavItem(
              icon: Icons.home_outlined,
              label: 'Home',
              onTap: controller.onHomeTap,
              isSelected: false,
            ),
            // 探索
            _buildBottomNavItem(
              icon: Icons.explore_outlined,
              label: 'Explore',
              onTap: controller.onExploreTap,
              isSelected: false,
            ),
            // 我的票券
            _buildBottomNavItem(
              icon: Icons.confirmation_number,
              label: 'My Tickets',
              onTap: controller.onTicketsTap,
              isSelected: false,
            ),
            // 个人资料（当前选中）
            _buildBottomNavItem(
              icon: Icons.person_outline,
              label: 'Profile',
              onTap: controller.onAccountTap,
              isSelected: true,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建设置项
  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 56,
        child: Row(
          children: [
            // 图标背景
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF121417), size: 24),
            ),
            const SizedBox(width: 16),
            // 标题
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  height: 1.5,
                  color: Color(0xFF121417),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建底部导航项
  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: isSelected
            ? BoxDecoration(borderRadius: BorderRadius.circular(27))
            : null,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                icon,
                size: 24,
                color: isSelected
                    ? const Color(0xFF141414)
                    : const Color(0xFF737373),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w500,
                fontSize: 12,
                height: 1.5,
                color: isSelected
                    ? const Color(0xFF141414)
                    : const Color(0xFF737373),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
