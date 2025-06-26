import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'search_controller.dart' as search;

class SearchView extends GetView<search.SearchController> {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // 顶部标题栏（添加返回按钮）
            _buildHeader(),

            // 搜索栏
            _buildSearchBar(),

            // 主要内容区域
            Expanded(
              child: Column(
                children: [
                  // 筛选选项
                  _buildFilterOptions(),

                  // "Upcoming"标题
                  _buildUpcomingTitle(),

                  // 活动列表
                  Expanded(child: _buildEventsList()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 顶部标题栏（添加返回按钮）
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 左侧返回按钮
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 48.w,
              height: 48.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Center(
                child: Icon(
                  Icons.arrow_back_ios,
                  size: 20.w,
                  color: const Color(0xFF141414),
                ),
              ),
            ),
          ),
          // 中间的标题
          Text(
            'Search',
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

  // 搜索栏
  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
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
                decoration: const BoxDecoration(color: Color(0xFFEDEDED)),
                child: Center(
                  child: TextField(
                    controller: controller.searchTextController,
                    textAlignVertical: TextAlignVertical.center,
                    style: TextStyle(
                      fontFamily: 'Public Sans',
                      fontWeight: FontWeight.w400,
                      fontSize: 16.sp,
                      color: const Color(0xFF141414),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search events, artists, venues',
                      hintStyle: TextStyle(
                        fontFamily: 'Public Sans',
                        fontWeight: FontWeight.w400,
                        fontSize: 16.sp,
                        color: const Color(0xFF737373),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    onChanged: controller.onSearchChanged,
                  ),
                ),
              ),
            ),
            // 清除按钮
            Obx(
              () => controller.searchQuery.value.isNotEmpty
                  ? GestureDetector(
                      onTap: controller.clearSearch,
                      child: Container(
                        width: 48.w,
                        height: 48.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDEDED),
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(8.r),
                            bottomRight: Radius.circular(8.r),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.clear,
                            size: 20.w,
                            color: const Color(0xFF737373),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      width: 16.w,
                      height: 48.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDEDED),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(8.r),
                          bottomRight: Radius.circular(8.r),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // 筛选选项
  Widget _buildFilterOptions() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
      child: Row(
        children: [
          // Category筛选
          _buildFilterButton('Category', controller.showCategoryFilter),
          SizedBox(width: 12.w),

          // Date筛选
          _buildFilterButton('Date', controller.showDateFilter),
          SizedBox(width: 12.w),

          // Price筛选
          _buildFilterButton('Price', controller.showPriceFilter),
        ],
      ),
    );
  }

  // 筛选按钮
  Widget _buildFilterButton(String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32.h,
        padding: EdgeInsets.fromLTRB(16.w, 0, 8.w, 0),
        decoration: BoxDecoration(
          color: const Color(0xFFEDEDED),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Public Sans',
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
                color: const Color(0xFF141414),
                height: 1.5,
              ),
            ),
            SizedBox(width: 8.w),
            Icon(
              Icons.keyboard_arrow_down,
              size: 20.sp,
              color: const Color(0xFF141414),
            ),
          ],
        ),
      ),
    );
  }

  // "Upcoming"标题
  Widget _buildUpcomingTitle() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 12.h),
      child: Text(
        'Upcoming',
        style: TextStyle(
          fontFamily: 'Public Sans',
          fontWeight: FontWeight.w700,
          fontSize: 22.sp,
          color: const Color(0xFF141414),
          height: 1.27,
        ),
      ),
    );
  }

  // 活动列表
  Widget _buildEventsList() {
    return Obx(() {
      final events = controller.filteredEvents;

      if (events.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64.sp,
                color: const Color(0xFF737373),
              ),
              SizedBox(height: 16.h),
              Text(
                'No events found',
                style: TextStyle(
                  fontFamily: 'Public Sans',
                  fontWeight: FontWeight.w500,
                  fontSize: 16.sp,
                  color: const Color(0xFF737373),
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return _buildEventCard(event);
        },
      );
    });
  }

  // 活动卡片
  Widget _buildEventCard(Map<String, dynamic> event) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: GestureDetector(
        onTap: () => controller.onEventTap(event['id']),
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 活动信息
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 分类标签
                      Text(
                        event['category'],
                        style: TextStyle(
                          fontFamily: 'Public Sans',
                          fontWeight: FontWeight.w400,
                          fontSize: 14.sp,
                          color: const Color(0xFF737373),
                          height: 1.5,
                        ),
                      ),

                      SizedBox(height: 4.h),

                      // 活动标题
                      Text(
                        event['title'],
                        style: TextStyle(
                          fontFamily: 'Public Sans',
                          fontWeight: FontWeight.w700,
                          fontSize: 16.sp,
                          color: const Color(0xFF141414),
                          height: 1.25,
                        ),
                      ),

                      SizedBox(height: 4.h),

                      // 场馆信息
                      Text(
                        event['venue'],
                        style: TextStyle(
                          fontFamily: 'Public Sans',
                          fontWeight: FontWeight.w400,
                          fontSize: 14.sp,
                          color: const Color(0xFF737373),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(width: 16.w),

              // 活动图片
              Container(
                width: 70.w,
                height: 70.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: _getEventGradient(event['id']),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 获取活动渐变色
  LinearGradient _getEventGradient(String eventId) {
    switch (eventId) {
      case '1':
        return const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case '2':
        return const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case '3':
        return const LinearGradient(
          colors: [Color(0xFFEC4899), Color(0xFFBE185D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case '4':
        return const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case '5':
        return const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }
}
