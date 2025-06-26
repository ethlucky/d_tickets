import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'seat_detail_controller.dart';
import '../../models/seat_layout_model.dart';

/// 座位详细选择页面视图
class SeatDetailView extends GetView<SeatDetailController> {
  const SeatDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // 顶部导航栏
            Container(
              decoration: const BoxDecoration(color: Color(0xFFFAFAFA)),
              padding: const EdgeInsets.only(
                  top: 44, bottom: 8, left: 16, right: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 返回按钮
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration:
                            const BoxDecoration(color: Color(0xFF141414)),
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
                        'Select Seats',
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

                  // 右侧占位
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // 主要内容区域
            Expanded(
              child: Stack(
                children: [
                  // 滚动内容
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 主要内容区域
                        Obx(() {
                          if (controller.isLoading.value) {
                            return _buildLoadingState();
                          }

                          if (controller.hasError.value) {
                            return _buildErrorState();
                          }

                          return _buildMainContent();
                        }),

                        // 为底部选座信息栏留出空间
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),

                  // 底部选座信息栏
                  Obx(() {
                    if (controller.selectedSeats.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          top: false,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 选座信息
                              Container(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 12, 16, 12),
                                child: Row(
                                  children: [
                                    // 选座数量
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${controller.selectedSeats.length} seats selected',
                                          style: const TextStyle(
                                            fontFamily: 'Public Sans',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF141414),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Tap to view details',
                                          style: TextStyle(
                                            fontFamily: 'Public Sans',
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    // 取消选择按钮
                                    TextButton.icon(
                                      onPressed: () {
                                        Get.dialog(
                                          AlertDialog(
                                            title: const Text(
                                              '取消选择',
                                              style: TextStyle(
                                                fontFamily: 'Public Sans',
                                                fontWeight: FontWeight.w600,
                                                fontSize: 18,
                                              ),
                                            ),
                                            content: Text(
                                              '确定要取消选择${controller.selectedSeats.length}个座位吗？',
                                              style: const TextStyle(
                                                fontFamily: 'Public Sans',
                                                fontSize: 16,
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Get.back(),
                                                child: const Text(
                                                  '取消',
                                                  style: TextStyle(
                                                    fontFamily: 'Public Sans',
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  controller
                                                      .clearAllSelectedSeats();
                                                  Get.back();
                                                },
                                                child: const Text(
                                                  '确定',
                                                  style: TextStyle(
                                                    fontFamily: 'Public Sans',
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.close,
                                        size: 18,
                                        color: Colors.red,
                                      ),
                                      label: const Text(
                                        'Clear',
                                        style: TextStyle(
                                          fontFamily: 'Public Sans',
                                          fontSize: 14,
                                          color: Colors.red,
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // 确认按钮
                              Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: ElevatedButton(
                                  onPressed: controller.confirmSeatSelection,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF141414),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Confirm Selection',
                                    style: TextStyle(
                                      fontFamily: 'Public Sans',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建加载状态
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF141414)),
          ),
          SizedBox(height: 16),
          Text(
            '正在加载座位布局...',
            style: TextStyle(
              fontFamily: 'Public Sans',
              fontSize: 14,
              color: Color(0xFF737373),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建错误状态
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Color(0xFF737373),
          ),
          const SizedBox(height: 16),
          Text(
            controller.errorMessage.value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Public Sans',
              fontSize: 16,
              color: Color(0xFF737373),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: controller.retryLoad,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF141414),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('重新加载'),
          ),
        ],
      ),
    );
  }

  /// 构建主要内容
  Widget _buildMainContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 区域信息
        _buildAreaInfo(),

        const SizedBox(height: 20),

        // 座位布局
        _buildSeatGrid(),

        const SizedBox(height: 20),

        // 座位状态图例
        _buildSeatLegend(),
      ],
    );
  }

  /// 构建区域信息
  Widget _buildAreaInfo() {
    return Obx(() {
      final area = controller.currentArea.value;
      final ticketType = controller.ticketTypeInfo.value;

      if (area == null) return const SizedBox.shrink();

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _parseColor(area.areaColor),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  area.areaName,
                  style: const TextStyle(
                    fontFamily: 'Public Sans',
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: Color(0xFF141414),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (ticketType != null) ...[
              Text(
                'Ticket Type: ${ticketType.typeName}',
                style: const TextStyle(
                  fontFamily: 'Public Sans',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Color(0xFF737373),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Price: ${ticketType.formattedCurrentPrice}',
                style: const TextStyle(
                  fontFamily: 'Public Sans',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xFF141414),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  /// 构建座位布局
  Widget _buildSeatGrid() {
    return Obx(() {
      final seats = controller.allSeats;
      if (seats.isEmpty) {
        return const Center(
          child: Text(
            'No seats available',
            style: TextStyle(
              fontFamily: 'Public Sans',
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        );
      }

      return Column(
        children: [
          // 舞台指示器
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'STAGE',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Public Sans',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          // 按行渲染座位
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: _buildSeatsByRows(seats),
          ),
        ],
      );
    });
  }

  /// 按行渲染座位
  Widget _buildSeatsByRows(List<SeatLayoutItemModel> seats) {
    // 按行分组座位
    final Map<String, List<SeatLayoutItemModel>> seatsByRow = {};

    for (final seat in seats) {
      final rowNumber = seat.row ?? _extractRowFromSeatNumber(seat.seatNumber);
      if (rowNumber != null) {
        seatsByRow[rowNumber] ??= [];
        seatsByRow[rowNumber]!.add(seat);
      }
    }

    // 按行号排序
    final sortedRows = seatsByRow.keys.toList()..sort();

    return Column(
      children: sortedRows.map((rowNumber) {
        final rowSeats = seatsByRow[rowNumber]!;
        // 按座位号在行内排序
        rowSeats.sort((a, b) {
          final aNum = _extractSeatNumberInRow(a.seatNumber);
          final bNum = _extractSeatNumberInRow(b.seatNumber);
          return aNum.compareTo(bNum);
        });

        return _buildSeatRow(rowNumber, rowSeats);
      }).toList(),
    );
  }

  /// 构建单行座位
  Widget _buildSeatRow(String rowNumber, List<SeatLayoutItemModel> rowSeats) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 行号标签
          Container(
            width: 30,
            height: 36,
            alignment: Alignment.center,
            child: Text(
              rowNumber,
              style: const TextStyle(
                fontFamily: 'Public Sans',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 座位
          Expanded(
            child: GestureDetector(
              onPanStart: (details) {
                controller.startSeatSelection(details.localPosition);
              },
              onPanUpdate: (details) {
                controller.updateSeatSelection(details.localPosition);
              },
              onPanEnd: (_) {
                controller.endSeatSelection();
              },
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: rowSeats.map((seat) {
                  return GestureDetector(
                    onTap: () => controller.toggleSeat(seat),
                    child: Container(
                      key: ValueKey('seat_${seat.seatNumber}'),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _getSeatColor(seat),
                        borderRadius: BorderRadius.circular(4),
                        border: seat.status == SeatLayoutStatus.selected
                            ? Border.all(
                                color: Colors.white,
                                width: 2,
                              )
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          _getSeatDisplayNumber(seat.seatNumber),
                          style: TextStyle(
                            fontFamily: 'Public Sans',
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            color: seat.status.isSelectable ||
                                    seat.status == SeatLayoutStatus.selected
                                ? Colors.white
                                : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 右侧行号标签
          Container(
            width: 30,
            height: 36,
            alignment: Alignment.center,
            child: Text(
              rowNumber,
              style: const TextStyle(
                fontFamily: 'Public Sans',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 从座位号中提取行号
  String? _extractRowFromSeatNumber(String seatNumber) {
    try {
      // 座位号格式: "VIP区-A-001"
      final parts = seatNumber.split('-');
      if (parts.length >= 3) {
        return parts[1]; // 返回行号部分 "A"
      }
    } catch (e) {
      print('提取行号失败: $seatNumber, 错误: $e');
    }
    return null;
  }

  /// 从座位号中提取行内座位号
  int _extractSeatNumberInRow(String seatNumber) {
    try {
      // 座位号格式: "VIP区-A-001"
      final parts = seatNumber.split('-');
      if (parts.length >= 3) {
        return int.parse(parts[2]); // 返回座位号部分 001 -> 1
      }
    } catch (e) {
      print('提取座位号失败: $seatNumber, 错误: $e');
    }
    return 0;
  }

  /// 获取座位显示号码
  String _getSeatDisplayNumber(String seatNumber) {
    try {
      // 座位号格式: "VIP区-A-001"
      final parts = seatNumber.split('-');
      if (parts.length >= 3) {
        final rowNumber = parts[1];
        final seatNum = int.parse(parts[2]);
        return '$rowNumber$seatNum'; // 返回 "A1"
      }
    } catch (e) {
      print('获取显示号码失败: $seatNumber, 错误: $e');
    }
    return seatNumber;
  }

  /// 构建座位状态图例
  Widget _buildSeatLegend() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seat Status',
            style: TextStyle(
              fontFamily: 'Public Sans',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildLegendItem(
                color: const Color(0xFF10B981),
                label: 'Available',
                status: SeatLayoutStatus.available,
              ),
              _buildLegendItem(
                color: const Color(0xFF141414),
                label: 'Selected',
                status: SeatLayoutStatus.selected,
              ),
              _buildLegendItem(
                color: const Color(0xFFEF4444),
                label: 'Sold',
                status: SeatLayoutStatus.occupied,
              ),
              _buildLegendItem(
                color: const Color(0xFFF59E0B),
                label: 'Reserved',
                status: SeatLayoutStatus.reserved,
              ),
              _buildLegendItem(
                color: const Color(0xFF737373),
                label: 'Unavailable',
                status: SeatLayoutStatus.unavailable,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建图例项
  Widget _buildLegendItem({
    required Color color,
    required String label,
    required SeatLayoutStatus status,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Public Sans',
            fontWeight: FontWeight.w400,
            fontSize: 12,
            color: Color(0xFF737373),
          ),
        ),
      ],
    );
  }

  /// 获取座位颜色
  Color _getSeatColor(SeatLayoutItemModel seat) {
    switch (seat.status) {
      case SeatLayoutStatus.available:
        return const Color(0xFF10B981); // 绿色 - 可选择
      case SeatLayoutStatus.selected:
        return const Color(0xFF141414); // 黑色 - 已选中
      case SeatLayoutStatus.occupied:
        return const Color(0xFFEF4444); // 红色 - 已占用
      case SeatLayoutStatus.reserved:
        return const Color(0xFFF59E0B); // 黄色 - 已预订
      case SeatLayoutStatus.locked:
        return const Color(0xFF8B5CF6); // 紫色 - 锁定中
      case SeatLayoutStatus.unavailable:
        return const Color(0xFF737373); // 灰色 - 不可用
    }
  }

  /// 解析颜色字符串
  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(
            int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
      }
      return const Color(0xFF3B82F6); // 默认蓝色
    } catch (e) {
      return const Color(0xFF3B82F6); // 默认蓝色
    }
  }

  /// 构建状态图例项
  Widget _buildStatusItem({required Color color, required String label}) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Public Sans',
              fontSize: 12,
              color: Color(0xFF141414),
            ),
          ),
        ],
      ),
    );
  }
}
