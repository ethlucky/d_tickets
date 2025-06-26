import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 顶部标题栏
            SliverToBoxAdapter(child: _buildHeader()),
            // 搜索栏
            SliverToBoxAdapter(child: _buildSearchBar()),
            // 精选活动标题
            SliverToBoxAdapter(child: _buildSectionTitle('Featured')),
            // 精选活动水平滚动
            SliverToBoxAdapter(child: _buildFeaturedEvents()),
            // 即将到来的活动标题
            SliverToBoxAdapter(child: _buildSectionTitle('Upcoming Events')),
            // 即将到来的活动网格
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 173 / 210,
                  crossAxisSpacing: 12.w,
                  mainAxisSpacing: 12.h,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildUpcomingEventCard(index),
                  childCount: controller.upcomingEvents.length,
                ),
              ),
            ),
            // 底部留白
            SliverToBoxAdapter(child: SizedBox(height: 20.h)),
          ],
        ),
      ),
      // 底部导航栏
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 左侧留空保持平衡
          SizedBox(width: 48.w),
          // 中间的标题
          Text(
            'Tickit',
            style: TextStyle(
              fontFamily: 'Public Sans',
              fontWeight: FontWeight.w700,
              fontSize: 18.sp,
              color: const Color(0xFF141414),
            ),
          ),
          // 右侧留空保持平衡
          SizedBox(width: 48.w),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 16.h, 16.w, 0),
      child: GestureDetector(
        onTap: controller.onSearchTap,
        child: Container(
          height: 48.h,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.r)),
          child: Row(
            children: [
              // 搜索图标容器
              Container(
                width: 56.w,
                height: 48.h,
                padding: EdgeInsets.only(left: 16.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDEDED),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8.r),
                    bottomLeft: Radius.circular(8.r),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.search,
                    size: 24.w,
                    color: const Color(0xFF737373),
                  ),
                ),
              ),
              // 搜索输入框
              Expanded(
                child: Container(
                  height: 48.h,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDEDED),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(8.r),
                      bottomRight: Radius.circular(8.r),
                    ),
                  ),
                  child: Center(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Search events, artists, venues',
                        style: TextStyle(
                          fontFamily: 'Public Sans',
                          fontWeight: FontWeight.w400,
                          fontSize: 16.sp,
                          color: const Color(0xFF737373),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 12.w, 0),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Public Sans',
          fontWeight: FontWeight.w700,
          fontSize: 22.sp,
          color: const Color(0xFF141414),
        ),
      ),
    );
  }

  Widget _buildFeaturedEvents() {
    return Container(
      height: 200.h,
      margin: EdgeInsets.only(top: 16.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: controller.featuredEvents.length,
        itemBuilder: (context, index) {
          final event = controller.featuredEvents[index];
          return GestureDetector(
            onTap: () => controller.onFeaturedEventTap(index),
            child: Container(
              width: 280.w,
              margin: EdgeInsets.only(right: 12.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 图片区域
                    Container(
                      height: 120.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8.r),
                          topRight: Radius.circular(8.r),
                        ),
                        gradient: LinearGradient(
                          colors: event['gradient'] as List<Color>,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    // 文字信息
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              event['title'] as String,
                              style: TextStyle(
                                fontFamily: 'Public Sans',
                                fontWeight: FontWeight.w500,
                                fontSize: 16.sp,
                                color: const Color(0xFF141414),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              event['subtitle'] as String,
                              style: TextStyle(
                                fontFamily: 'Public Sans',
                                fontWeight: FontWeight.w400,
                                fontSize: 14.sp,
                                color: const Color(0xFF737373),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUpcomingEventCard(int index) {
    final event = controller.upcomingEvents[index];
    return GestureDetector(
      onTap: () => controller.onUpcomingEventTap(index),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图片区域
            Container(
              height: 97.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8.r),
                  topRight: Radius.circular(8.r),
                ),
                gradient: LinearGradient(
                  colors: event['gradient'] as List<Color>,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // 文字信息
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      event['title'] as String,
                      style: TextStyle(
                        fontFamily: 'Public Sans',
                        fontWeight: FontWeight.w500,
                        fontSize: 16.sp,
                        color: const Color(0xFF141414),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      event['subtitle'] as String,
                      style: TextStyle(
                        fontFamily: 'Public Sans',
                        fontWeight: FontWeight.w400,
                        fontSize: 14.sp,
                        color: const Color(0xFF737373),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
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
            isSelected: true,
            onTap: () => controller.onBottomNavTap(0),
          ),
          _buildBottomNavItem(
            icon: Icons.explore_outlined,
            label: 'Explore',
            isSelected: false,
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
