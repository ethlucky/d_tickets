import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'my_tickets_controller.dart';

/// 我的票券页面视图
class MyTicketsView extends GetView<MyTicketsController> {
  const MyTicketsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
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
                        color: Color(0xFF141414),
                        size: 24,
                      ),
                    ),
                  ),
                  // 标题
                  const Text(
                    'My Tickets',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      height: 1.28,
                      color: Color(0xFF141414),
                    ),
                  ),
                  const SizedBox(width: 48), // 占位
                ],
              ),
            ),

            // 钱包部分
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Wallet',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    height: 1.28,
                    color: Color(0xFF141414),
                  ),
                ),
              ),
            ),

            // 钱包信息
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  // 钱包图标
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDEDED),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: Color(0xFF141414),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 钱包信息
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Wallet ID',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          height: 1.5,
                          color: Color(0xFF141414),
                        ),
                      ),
                      Obx(
                        () => Text(
                          controller.walletId.value,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                            height: 1.5,
                            color: Color(0xFF737373),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 票券部分
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tickets',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    height: 1.28,
                    color: Color(0xFF141414),
                  ),
                ),
              ),
            ),

            // 票券列表
            Expanded(
              child: Obx(
                () => ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: controller.tickets.length,
                  itemBuilder: (context, index) {
                    final ticket = controller.tickets[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GestureDetector(
                        onTap: () => controller.onTicketTap(ticket),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              // 票券信息
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // 状态标签
                                      Text(
                                        ticket.statusText,
                                        style: const TextStyle(
                                          fontFamily: 'Manrope',
                                          fontWeight: FontWeight.w400,
                                          fontSize: 14,
                                          height: 1.5,
                                          color: Color(0xFF737373),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      // 活动名称
                                      Text(
                                        ticket.eventName,
                                        style: const TextStyle(
                                          fontFamily: 'Manrope',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          height: 1.25,
                                          color: Color(0xFF141414),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      // 详细信息
                                      Text(
                                        ticket.fullDateTimeVenue,
                                        style: const TextStyle(
                                          fontFamily: 'Manrope',
                                          fontWeight: FontWeight.w400,
                                          fontSize: 14,
                                          height: 1.5,
                                          color: Color(0xFF737373),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // 票券图片
                              Container(
                                width: 120,
                                height: 91,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.horizontal(
                                    right: Radius.circular(12),
                                  ),
                                  color: _getTicketColor(ticket.status),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
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
            // 我的票券（当前选中）
            _buildBottomNavItem(
              icon: Icons.confirmation_number,
              label: 'My Tickets',
              onTap: controller.onMyTicketsTap,
              isSelected: true,
            ),
            // 个人资料
            _buildBottomNavItem(
              icon: Icons.person_outline,
              label: 'Profile',
              onTap: controller.onProfileTap,
              isSelected: false,
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

  /// 根据票券状态获取颜色
  Color _getTicketColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.valid:
        return const Color(0xFF4CAF50); // 绿色
      case TicketStatus.redeemed:
        return const Color(0xFF9C27B0); // 紫色
      case TicketStatus.refunded:
        return const Color(0xFFFF9800); // 橙色
      case TicketStatus.availableForResale:
        return const Color(0xFF2196F3); // 蓝色
    }
  }
}
