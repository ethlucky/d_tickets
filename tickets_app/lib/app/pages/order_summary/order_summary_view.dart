import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'order_summary_controller.dart';

/// 订单摘要页面视图
class OrderSummaryView extends GetView<OrderSummaryController> {
  const OrderSummaryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // 顶部导航区域
            _buildHeader(),

            // 滚动内容区域
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event Details
                    _buildEventDetailsTitle(),
                    _buildEventDetails(),

                    // Your Order
                    _buildYourOrderTitle(),
                    _buildOrderItems(),

                    // 价格明细
                    _buildPriceSummary(),

                    // 错误提示
                    _buildErrorMessage(),
                  ],
                ),
              ),
            ),

            // 底部支付按钮
            _buildPayButton(),
          ],
        );
      }),
    );
  }

  /// 构建顶部导航
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFFFAFAFA)),
      padding: const EdgeInsets.only(top: 44, bottom: 8, left: 16, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 返回按钮
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: controller.goBack,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(color: Color(0xFF141414)),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),

          // 标题
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(right: 48),
              alignment: Alignment.center,
              child: const Text(
                'Order Summary',
                style: TextStyle(
                  fontFamily: 'Public Sans',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  height: 1.28,
                  color: Color(0xFF141414),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建Event Details标题
  Widget _buildEventDetailsTitle() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: const Text(
        'Event Details',
        style: TextStyle(
          fontFamily: 'Public Sans',
          fontWeight: FontWeight.w700,
          fontSize: 18,
          height: 1.28,
          color: Color(0xFF141414),
        ),
      ),
    );
  }

  /// 构建活动详情
  Widget _buildEventDetails() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          // 活动图片
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Obx(() {
              final imageUrl = controller.eventInfo.value?.posterImageUrl;
              print('🖼️ 加载活动图片: $imageUrl');

              if (imageUrl == null || imageUrl.isEmpty) {
                print('⚠️ 图片URL为空');
                return Container(
                  width: 56,
                  height: 56,
                  color: const Color(0xFFF5F5F5),
                  child: const Icon(
                    Icons.image_outlined,
                    color: Color(0xFF737373),
                    size: 24,
                  ),
                );
              }

              return Image.network(
                imageUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                cacheWidth: 112, // 2x for high DPI displays
                cacheHeight: 112,
                errorBuilder: (context, error, stackTrace) {
                  print('❌ 加载活动图片失败: $error');
                  print('Stack trace: $stackTrace');
                  return Container(
                    width: 56,
                    height: 56,
                    color: const Color(0xFFF5F5F5),
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: Color(0xFF737373),
                      size: 24,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    print('✅ 图片加载完成');
                    return child;
                  }

                  final progress = loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null;
                  print(
                      '⏳ 图片加载进度: ${(progress ?? 0 * 100).toStringAsFixed(1)}%');

                  return Container(
                    width: 56,
                    height: 56,
                    color: const Color(0xFFF5F5F5),
                    child: Center(
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
              );
            }),
          ),

          const SizedBox(width: 16),

          // 活动信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  child: Obx(
                    () => Text(
                      controller.eventInfo.value?.title ?? 'Loading...',
                      style: const TextStyle(
                        fontFamily: 'Public Sans',
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        height: 1.5,
                        color: Color(0xFF141414),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Obx(
                  () => Text(
                    controller.eventInfo.value?.formattedDateTime ??
                        'Loading...',
                    style: const TextStyle(
                      fontFamily: 'Public Sans',
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      height: 1.5,
                      color: Color(0xFF737373),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // 场馆名称和地址
                Obx(() {
                  final venueName = controller.venueName.value;
                  final venueAddress = controller.venueAddress;

                  if (venueName.isEmpty) {
                    return const Text(
                      'Loading venue...',
                      style: TextStyle(
                        fontFamily: 'Public Sans',
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        height: 1.5,
                        color: Color(0xFF737373),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 场馆名称
                      Text(
                        venueName,
                        style: const TextStyle(
                          fontFamily: 'Public Sans',
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          height: 1.5,
                          color: Color(0xFF141414),
                        ),
                      ),
                      // 场馆地址
                      if (venueAddress != 'No address available')
                        Text(
                          venueAddress,
                          style: const TextStyle(
                            fontFamily: 'Public Sans',
                            fontWeight: FontWeight.w400,
                            fontSize: 11,
                            height: 1.5,
                            color: Color(0xFF737373),
                          ),
                        ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建Your Order标题
  Widget _buildYourOrderTitle() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: const Text(
        'Your Order',
        style: TextStyle(
          fontFamily: 'Public Sans',
          fontWeight: FontWeight.w700,
          fontSize: 18,
          height: 1.28,
          color: Color(0xFF141414),
        ),
      ),
    );
  }

  /// 构建订单项目
  Widget _buildOrderItems() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, 2),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                // 票种信息头部
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // 票种图标和信息
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF667EEA),
                                    Color(0xFF764BA2)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.confirmation_number,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    controller.ticketTypeInfo.value?.typeName ??
                                        'Loading...',
                                    style: const TextStyle(
                                      fontFamily: 'Public Sans',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Obx(() {
                                    final price = controller
                                        .ticketTypeInfo.value?.currentPrice;
                                    if (price != null) {
                                      final priceInSol = price / 1000000000;
                                      return Text(
                                        '${priceInSol.toStringAsFixed(4)} SOL / 张',
                                        style: const TextStyle(
                                          fontFamily: 'Public Sans',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                          color: Color(0xFF6B7280),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 数量标签
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          '${controller.selectedSeatsCount}张',
                          style: const TextStyle(
                            fontFamily: 'Public Sans',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 分隔线
                Container(
                  height: 1,
                  color: const Color(0xFFF3F4F6),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                ),

                // 区域和座位信息
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 区域信息
                      Obx(() {
                        final areaName =
                            controller.areaInfo.value?.areaName ?? '';
                        if (areaName.isNotEmpty) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.location_on,
                                    size: 20,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '区域',
                                      style: TextStyle(
                                        fontFamily: 'Public Sans',
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                    Text(
                                      areaName,
                                      style: const TextStyle(
                                        fontFamily: 'Public Sans',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),

                      // 座位信息
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.event_seat,
                              size: 20,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '座位',
                                  style: TextStyle(
                                    fontFamily: 'Public Sans',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                _buildSeatTags(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建座位标签
  Widget _buildSeatTags() {
    final seatNumbers = controller.selectedSeatNumbers;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: seatNumbers.map((seatNumber) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF3B82F6).withOpacity(0.3),
            ),
          ),
          child: Text(
            seatNumber,
            style: const TextStyle(
              fontFamily: 'Public Sans',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xFF3B82F6),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 构建价格明细
  Widget _buildPriceSummary() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            // 小计
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Subtotal',
                  style: TextStyle(
                    fontFamily: 'Public Sans',
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF737373),
                  ),
                ),
                Text(
                  '\$${controller.subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: 'Public Sans',
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF141414),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 平台费用
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Platform Fee (${(controller.platformFeeRate.value * 100).toStringAsFixed(1)}%)',
                  style: const TextStyle(
                    fontFamily: 'Public Sans',
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF737373),
                  ),
                ),
                Text(
                  '\$${controller.platformFee.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: 'Public Sans',
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF141414),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 场馆费用
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Venue Fee (${(controller.venueFeeRate.value * 100).toStringAsFixed(1)}%)',
                  style: const TextStyle(
                    fontFamily: 'Public Sans',
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF737373),
                  ),
                ),
                Text(
                  '\$${controller.venueFee.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: 'Public Sans',
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF141414),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 分隔线
            const Divider(height: 1, color: Color(0xFFE5E5E5)),
            const SizedBox(height: 8),

            // 总计
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontFamily: 'Public Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    height: 1.5,
                    color: Color(0xFF141414),
                  ),
                ),
                Text(
                  '\$${controller.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: 'Public Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    height: 1.5,
                    color: Color(0xFF141414),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建错误提示
  Widget _buildErrorMessage() {
    return Obx(() {
      if (!controller.hasError.value || controller.errorMessage.value.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            controller.errorMessage.value,
            style: const TextStyle(
              fontFamily: 'Public Sans',
              fontWeight: FontWeight.w400,
              fontSize: 14,
              height: 1.5,
              color: Color(0xFFDC2626),
            ),
          ),
        ),
      );
    });
  }

  /// 构建支付按钮
  Widget _buildPayButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E5E5)),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: controller.isLoading.value ? null : controller.createOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF141414),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFE5E5E5),
            disabledForegroundColor: const Color(0xFF737373),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text(
            controller.isLoading.value ? 'Processing...' : 'Purchase Tickets',
            style: const TextStyle(
              fontFamily: 'Public Sans',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
