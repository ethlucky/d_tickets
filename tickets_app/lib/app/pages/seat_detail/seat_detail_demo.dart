import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';

/// 座位详细选择演示页面
class SeatDetailDemo extends StatelessWidget {
  const SeatDetailDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('座位详细选择演示'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '选择不同区域查看座位详细选择页面',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // VIP区域
            _buildDemoButton(
              label: 'VIP区域',
              color: const Color(0xFF6366F1),
              onTap: () => _navigateToSeatDetail(
                areaId: 'VIP',
                ticketTypeName: 'VIP',
              ),
            ),

            const SizedBox(height: 16),

            // 普通席区域
            _buildDemoButton(
              label: '普通席A区',
              color: const Color(0xFF10B981),
              onTap: () => _navigateToSeatDetail(
                areaId: 'A',
                ticketTypeName: 'General Admission',
              ),
            ),

            const SizedBox(height: 16),

            // 经济席区域
            _buildDemoButton(
              label: '经济席B区',
              color: const Color(0xFFF59E0B),
              onTap: () => _navigateToSeatDetail(
                areaId: 'B',
                ticketTypeName: 'Economy',
              ),
            ),

            const SizedBox(height: 16),

            // 特殊区域
            _buildDemoButton(
              label: '无障碍座位区',
              color: const Color(0xFF8B5CF6),
              onTap: () => _navigateToSeatDetail(
                areaId: 'ACCESSIBILITY',
                ticketTypeName: 'Accessibility',
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              '点击按钮将跳转到对应区域的座位详细选择页面',
              style: TextStyle(fontSize: 14, color: Color(0xFF737373)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建演示按钮
  Widget _buildDemoButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 32,
          vertical: 16,
        ),
        minimumSize: const Size(200, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Public Sans',
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }

  /// 跳转到座位详细选择页面
  void _navigateToSeatDetail({
    required String areaId,
    required String ticketTypeName,
  }) {
    // 模拟数据
    final mockSeatStatusMapPDA =
        'demo_seat_status_map_${areaId}_${DateTime.now().millisecondsSinceEpoch}';
    final mockEventPda = 'demo_event_pda_123456';

    print('🚀 演示跳转到座位详细选择页面');
    print('   - 区域: $areaId');
    print('   - 票种: $ticketTypeName');
    print('   - SeatStatusMap PDA: $mockSeatStatusMapPDA');

    Get.toNamed(
      AppRoutes.getSeatDetailRoute(
        seatStatusMapPDA: mockSeatStatusMapPDA,
        eventPda: mockEventPda,
        ticketTypeName: ticketTypeName,
        areaId: areaId,
      ),
      arguments: {
        'seatStatusMapPDA': mockSeatStatusMapPDA,
        'eventPda': mockEventPda,
        'ticketTypeName': ticketTypeName,
        'areaId': areaId,
        'isDemo': true, // 标记为演示模式
      },
    );
  }
}
