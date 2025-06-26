import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/ticket_type_model.dart';
import '../../widgets/venue_svg_viewer.dart';
import 'event_detail_controller.dart';

/// 活动详情页面视图
class EventDetailView extends GetView<EventDetailController> {
  const EventDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        // 显示错误信息
        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  controller.errorMessage.value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.refreshData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // 如果没有活动数据
        if (controller.eventInfo.value == null) {
          return const Center(
            child: Text(
              'Event not found',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
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
                    // 活动图片区域
                    _buildEventImage(),

                    // 活动标题
                    _buildEventTitle(),

                    // 活动分类
                    _buildEventCategory(),

                    // 活动描述
                    _buildEventDescription(),

                    // 活动信息（日期、时间、地点）
                    _buildEventInfo(),

                    // 场馆信息区域
                    _buildVenueInfo(),

                    // 场馆平面图（如果有的话）
                    _buildVenueFloorPlan(),

                    // 座位区域列表
                    _buildSeatAreasList(),

                    // 票价标题
                    _buildTicketPricesTitle(),

                    // 票价列表
                    _buildTicketPrices(),
                  ],
                ),
              ),
            ),

            // 底部购买按钮
            _buildBuyButton(),
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
                'Event Details',
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

  /// 构建活动图片
  Widget _buildEventImage() {
    return Obx(() {
      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            // 主图片
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: controller.posterImageData.value != null
                  ? Image.memory(
                      controller.posterImageData.value!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: double.infinity,
                      height: 200,
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(
                          Icons.image,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
                    ),
            ),

            // 加载状态指示器
            if (controller.isLoadingArweaveData.value)
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  /// 构建活动标题
  Widget _buildEventTitle() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Text(
        controller.eventInfo.value?.title ?? '',
        style: const TextStyle(
          fontFamily: 'Public Sans',
          fontWeight: FontWeight.w700,
          fontSize: 22,
          height: 1.27,
          color: Color(0xFF141414),
        ),
      ),
    );
  }

  /// 构建活动分类
  Widget _buildEventCategory() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              controller.eventInfo.value?.category ?? '',
              style: const TextStyle(
                fontFamily: 'Public Sans',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建活动描述
  Widget _buildEventDescription() {
    return Obx(() {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 显示简要描述或加载状态
            if (controller.isLoadingArweaveData.value)
              // 加载状态
              Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Loading event information...',
                    style: TextStyle(
                      fontFamily: 'Public Sans',
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              )
            else if (controller.eventDescription.value.isEmpty &&
                controller.performerDetails.isEmpty)
              // 只有当没有其他描述内容时，显示占位文本
              Text(
                'Loading event details...',
                style: TextStyle(
                  fontFamily: 'Public Sans',
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),

            // 如果有表演者信息，显示表演者详情
            if (controller.performerDetails.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Performer Information',
                style: TextStyle(
                  fontFamily: 'Public Sans',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xFF141414),
                ),
              ),
              const SizedBox(height: 8),
              ...controller.performerDetails.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${entry.key}: ${entry.value}',
                    style: const TextStyle(
                      fontFamily: 'Public Sans',
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      height: 1.5,
                      color: Color(0xFF737373),
                    ),
                  ),
                );
              }),
            ],

            // 如果有活动描述的详细内容，直接显示
            if (controller.eventDescription.value.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                controller.eventDescription.value,
                style: const TextStyle(
                  fontFamily: 'Public Sans',
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xFF737373),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  /// 构建活动信息
  Widget _buildEventInfo() {
    return Obx(() {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 第一行：日期和时间
            Row(
              children: [
                // 日期
                Expanded(
                  child: _buildInfoItem('Date', controller.formattedEventDate),
                ),
                const SizedBox(width: 24),
                // 时间
                Expanded(
                  child: _buildInfoItem('Time', controller.formattedEventTime),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // 第二行：地点和状态
            Row(
              children: [
                Expanded(
                  child: _buildVenueInfoItem(),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildInfoItem('Status', controller.statusText),
                ),
              ],
            ),

            // 如果有联系信息，显示联系信息
            if (controller.contactInfo.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFFE5E8EB), width: 1),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contact Information',
                      style: TextStyle(
                        fontFamily: 'Public Sans',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Color(0xFF141414),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...controller.contactInfo.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${entry.key}: ${entry.value}',
                          style: const TextStyle(
                            fontFamily: 'Public Sans',
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                            height: 1.5,
                            color: Color(0xFF737373),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  /// 构建信息项
  Widget _buildInfoItem(String label, String value) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE5E8EB), width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Public Sans',
              fontWeight: FontWeight.w400,
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF737373),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
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
    );
  }

  /// 构建场馆信息项（包含名称和地址）
  Widget _buildVenueInfoItem() {
    return Obx(() {
      return Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE5E8EB), width: 1)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Venue',
              style: TextStyle(
                fontFamily: 'Public Sans',
                fontWeight: FontWeight.w400,
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF737373),
              ),
            ),
            const SizedBox(height: 4),
            // 场馆名称
            Text(
              controller.venueName.value.isNotEmpty
                  ? controller.venueName.value
                  : controller.venueInfo,
              style: const TextStyle(
                fontFamily: 'Public Sans',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF141414),
              ),
            ),
            // 场馆地址
            if (controller.venueAddress != 'No address available')
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  controller.venueAddress,
                  style: const TextStyle(
                    fontFamily: 'Public Sans',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    height: 1.5,
                    color: Color(0xFF737373),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  /// 构建场馆信息
  Widget _buildVenueInfo() {
    return Obx(() {
      // 如果没有场馆详细信息或正在加载，可以选择不显示或显示加载状态
      if (controller.venueDetails.value == null &&
          !controller.isLoadingArweaveData.value) {
        return const SizedBox.shrink();
      }

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 20,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                const Text(
                  'Venue Information',
                  style: TextStyle(
                    fontFamily: 'Public Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF141414),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 如果正在加载，显示加载状态
            if (controller.isLoadingArweaveData.value &&
                controller.venueDetails.value == null)
              Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Loading venue information...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              )
            else ...[
              // 场馆名称和类型
              _buildVenueInfoRow(
                Icons.business_outlined,
                'Name',
                controller.venueName.value.isNotEmpty
                    ? controller.venueName.value
                    : 'Loading...',
              ),

              // 场馆地址
              _buildVenueInfoRow(
                Icons.place_outlined,
                'Address',
                controller.venueAddress,
              ),

              // 场馆容量
              _buildVenueInfoRow(
                Icons.people_outlined,
                'Capacity',
                controller.venueCapacity,
              ),

              // 场馆类型
              _buildVenueInfoRow(
                Icons.category_outlined,
                'Type',
                controller.venueType,
              ),

              // 场馆描述（如果有的话）
              if (controller.venueDescription != 'No description available')
                _buildVenueDescriptionRow(controller.venueDescription),
            ],
          ],
        ),
      );
    });
  }

  /// 构建场馆信息行
  Widget _buildVenueInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey[500],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF141414),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建场馆描述行
  Widget _buildVenueDescriptionRow(String description) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                size: 16,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 8),
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 24),
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF141414),
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建场馆平面图
  Widget _buildVenueFloorPlan() {
    return Obx(() {
      // 只有当有SVG平面图或正在加载时才显示
      if (!controller.hasVenueFloorPlan && !controller.isLoadingSvg.value) {
        return const SizedBox.shrink();
      }

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.map_outlined,
                    size: 20,
                    color: Color(0xFF141414),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Venue Floor Plan',
                    style: TextStyle(
                      fontFamily: 'Public Sans',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      height: 1.28,
                      color: Color(0xFF141414),
                    ),
                  ),
                ],
              ),
            ),

            // SVG查看器
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFE5E8EB),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: controller.isLoadingSvg.value
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text(
                                'Loading venue floor plan...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : controller.hasVenueFloorPlan
                          ? VenueSvgViewer(
                              floorPlanHash:
                                  controller.venueFloorPlanHash.value,
                              seatAreas: controller.seatAreas,
                              focusedAreaId: controller.currentFocusedAreaId,
                              onAreaTap: controller.onAreaTap,
                              width: Get.width - 64,
                              height: 300,
                            )
                          : const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.map_outlined,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No floor plan available',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                ),
              ),
            ),

            // 如果有座位区域，显示提示信息
            if (controller.seatAreas.isNotEmpty &&
                controller.hasVenueFloorPlan) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  'Tap on highlighted areas to select seats',
                  style: TextStyle(
                    fontFamily: 'Public Sans',
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  /// 构建座位区域列表
  Widget _buildSeatAreasList() {
    return Obx(() {
      if (controller.seatAreas.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 20,
                    color: Color(0xFF141414),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Seating Areas',
                    style: TextStyle(
                      fontFamily: 'Public Sans',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      height: 1.28,
                      color: Color(0xFF141414),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${controller.seatAreas.length} areas',
                    style: TextStyle(
                      fontFamily: 'Public Sans',
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // 区域列表
            ...controller.seatAreas.asMap().entries.map((entry) {
              final index = entry.key;
              final area = entry.value;
              final isLast = index == controller.seatAreas.length - 1;
              final isSelected = controller.currentFocusedAreaId == area.areaId;

              return Container(
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(
                          bottom: BorderSide(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                ),
                child: Material(
                  color: isSelected ? Colors.blue[50] : Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // 只聚焦到区域，不进行跳转
                      controller.onAreaTap(area);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // 区域颜色标识
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getAreaColor(area),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // 区域信息
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  controller.formatAreaDisplay(area.areaId),
                                  style: TextStyle(
                                    fontFamily: 'Public Sans',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: isSelected
                                        ? Colors.blue[700]
                                        : const Color(0xFF141414),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${area.availableSeats}/${area.totalSeats} seats available',
                                  style: TextStyle(
                                    fontFamily: 'Public Sans',
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 可用性状态
                          _buildAvailabilityBadge(area),

                          const SizedBox(width: 8),

                          // 箭头图标
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: isSelected ? Colors.blue : Colors.grey[400],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      );
    });
  }

  /// 获取区域颜色
  Color _getAreaColor(dynamic area) {
    // 根据区域ID或票种类型分配不同颜色
    final colors = [
      const Color(0xFF3B82F6), // 蓝色
      const Color(0xFF10B981), // 绿色
      const Color(0xFFF59E0B), // 橙色
      const Color(0xFF8B5CF6), // 紫色
      const Color(0xFFEF4444), // 红色
      const Color(0xFF14B8A6), // 青色
    ];

    final index = area.areaId.hashCode % colors.length;
    return colors[index.abs()];
  }

  /// 构建可用性徽章
  Widget _buildAvailabilityBadge(dynamic area) {
    final availableRatio =
        area.totalSeats > 0 ? area.availableSeats / area.totalSeats : 0.0;

    Color badgeColor;
    String badgeText;

    if (area.availableSeats == 0) {
      badgeColor = Colors.red;
      badgeText = 'Sold Out';
    } else if (availableRatio <= 0.2) {
      badgeColor = Colors.orange;
      badgeText = 'Few Left';
    } else if (availableRatio <= 0.5) {
      badgeColor = Colors.blue;
      badgeText = 'Available';
    } else {
      badgeColor = Colors.green;
      badgeText = 'Available';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Text(
        badgeText,
        style: TextStyle(
          fontFamily: 'Public Sans',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: badgeColor,
        ),
      ),
    );
  }

  /// 构建票价标题
  Widget _buildTicketPricesTitle() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: const Text(
        'Ticket Prices',
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

  /// 构建票价列表
  Widget _buildTicketPrices() {
    return Obx(() {
      if (controller.isLoadingTicketTypes.value) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      if (controller.ticketTypes.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: const Center(
            child: Text(
              'No available ticket types',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
        );
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 动态构建票种行
            ...controller.ticketTypes.asMap().entries.map((entry) {
              final index = entry.key;
              final ticketType = entry.value;

              // 每两个票种一行
              if (index % 2 == 0) {
                final nextTicketType = index + 1 < controller.ticketTypes.length
                    ? controller.ticketTypes[index + 1]
                    : null;

                return Column(
                  children: [
                    if (index > 0) const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildTicketPriceItem(ticketType),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: nextTicketType != null
                              ? _buildTicketPriceItem(nextTicketType)
                              : const SizedBox(),
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                return const SizedBox.shrink();
              }
            }).toList(),
          ],
        ),
      );
    });
  }

  /// 构建票价项
  Widget _buildTicketPriceItem(TicketTypeModel ticketType) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE5E8EB), width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            ticketType.typeName,
            style: const TextStyle(
              fontFamily: 'Public Sans',
              fontWeight: FontWeight.w400,
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF737373),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  ticketType.formattedCurrentPrice,
                  style: const TextStyle(
                    fontFamily: 'Public Sans',
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF141414),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (!ticketType.isAvailable)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Sold Out',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.red,
                    ),
                  ),
                ),
            ],
          ),
          if (ticketType.isAvailable && ticketType.remainingTickets < 10)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Only ${ticketType.remainingTickets} left',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建购买按钮
  Widget _buildBuyButton() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: Color(0xFFFAFAFA)),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: controller.canPurchase
              ? const Color(0xFF000000)
              : Colors.grey[400],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: controller.canPurchase
                ? () => controller.goToSeatSelection()
                : null,
            child: Center(
              child: Text(
                controller.purchaseButtonText,
                style: const TextStyle(
                  fontFamily: 'Public Sans',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  height: 1.5,
                  color: Color(0xFFFAFAFA),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
