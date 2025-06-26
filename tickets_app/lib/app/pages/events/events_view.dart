import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'events_controller.dart';
import '../../models/event_model.dart';
import '../../widgets/arweave_image.dart';

class EventsView extends GetView<EventsController> {
  const EventsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // 顶部导航栏
            _buildHeader(),
            // 主要内容区域
            Expanded(
              child: Column(
                children: [
                  // 分类标签栏
                  _buildCategoryTabs(),
                  // 活动网格
                  Expanded(child: _buildEventsGrid()),
                ],
              ),
            ),
          ],
        ),
      ),
      // 底部导航栏
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: const Color(0xFFF7FAFC),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 左侧菜单图标
          GestureDetector(
            onTap: controller.onMenuTap,
            child: Container(
              width: 48.w,
              height: 48.h,
              child: Icon(
                Icons.menu,
                size: 24.w,
                color: const Color(0xFF0D141C),
              ),
            ),
          ),
          // 中间标题
          Text(
            'Events',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w700,
              fontSize: 18.sp,
              color: const Color(0xFF0D141C),
            ),
          ),
          // 右侧占位（保持平衡）
          SizedBox(width: 48.w),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 0),
      child: Row(
        children: controller.categories.map((category) {
          return Obx(
            () => _buildCategoryTab(
              category,
              controller.selectedCategory.value == category,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryTab(String category, bool isSelected) {
    return GestureDetector(
      onTap: () => controller.onCategorySelected(category),
      child: Container(
        margin: EdgeInsets.only(right: 12.w),
        height: 32.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: const Color(0xFFE8EDF2),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Center(
          child: Text(
            category,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w500,
              fontSize: 14.sp,
              color: const Color(0xFF0D141C),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventsGrid() {
    return Obx(() {
      final filteredEvents = controller.filteredEvents;
      return Container(
        padding: EdgeInsets.all(16.w),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 173 / 210, // 根据Figma设计调整比例
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
          ),
          itemCount: filteredEvents.length,
          itemBuilder: (context, index) {
            return _buildEventCard(filteredEvents[index], index);
          },
        ),
      );
    });
  }

  Widget _buildEventCard(EventModel event, int index) {
    return GestureDetector(
      onTap: () => controller.onEventTap(index),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: Stack(
            children: [
              // 背景图片从 Arweave 加载
              Positioned.fill(
                child: ArweaveImageWithRetry(
                  imageHash: event.posterImageHash,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(12.r),
                  placeholder: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: event.gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),
              ),
              // 渐变覆盖层（确保文字可读性）
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                ),
              ),
              // 底部文字
              Positioned(
                left: 16.w,
                bottom: 16.h,
                right: 16.w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      event.title,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 16.sp,
                        color: const Color(0xFFFFFFFF),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (event.category.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        event.category,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w500,
                          fontSize: 12.sp,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        border: Border(top: BorderSide(color: Color(0xFFEDEDED), width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomNavItem(
            icon: Icons.home_outlined,
            label: 'Home',
            isSelected: false,
            onTap: () => controller.onBottomNavTap(0),
          ),
          _buildBottomNavItem(
            icon: Icons.explore_outlined,
            label: 'Explore',
            isSelected: true,
            onTap: () => controller.onBottomNavTap(1),
          ),
          _buildBottomNavItem(
            icon: Icons.confirmation_number,
            label: 'My Tickets',
            isSelected: false,
            onTap: () => controller.onBottomNavTap(2),
          ),
          _buildBottomNavItem(
            icon: Icons.person_outline,
            label: 'Profile',
            isSelected: false,
            onTap: () => controller.onBottomNavTap(3),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
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
