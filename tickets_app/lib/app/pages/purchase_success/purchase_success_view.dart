import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'purchase_success_controller.dart';

/// 购票成功页面视图
class PurchaseSuccessView extends GetView<PurchaseSuccessController> {
  const PurchaseSuccessView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // 顶部关闭按钮
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(
                        Icons.close,
                        color: Color(0xFF0F141A),
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 主要内容
            Expanded(
              child: Column(
                children: [
                  // 成功标题
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
                    child: Text(
                      'Congratulations! Ticket purchased successfully!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 28,
                        height: 1.25,
                        color: Color(0xFF0F141A),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 票券信息卡片 - 占满屏幕宽度，只保留少量边距
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          // 票券图片区域
                          Container(
                            height: 201,
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              color: Color(0xFFFAFAFA),
                              // 这里应该是票券的背景图片
                            ),
                          ),

                          // 票券详情
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(12),
                              ),
                            ),
                            child: Obx(
                              () => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 活动名称
                                  Text(
                                    controller.ticketInfo['eventName']!,
                                    style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 20,
                                      height: 1.3,
                                      color: Color(0xFF0F141A),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // 票券信息（美式格式）
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // 日期信息
                                      Text(
                                        controller.ticketInfo['date']!,
                                        style: const TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          fontWeight: FontWeight.w400,
                                          fontSize: 16,
                                          height: 1.5,
                                          color: Color(0xFF59738C),
                                        ),
                                      ),

                                      const SizedBox(height: 4),

                                      // 座位信息（美式格式）
                                      Text(
                                        controller.ticketInfo['section']!,
                                        style: const TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          fontWeight: FontWeight.w400,
                                          fontSize: 16,
                                          height: 1.5,
                                          color: Color(0xFF59738C),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // 底部按钮组
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
                    child: Column(
                      children: [
                        // View My Tickets 按钮
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: controller.viewMyTickets,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD1E3F2),
                              foregroundColor: const Color(0xFF0F141A),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: const Text(
                              'View My Tickets',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Back to Home 按钮
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: controller.backToHome,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F141A),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: const Text(
                              'Back to Home',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
