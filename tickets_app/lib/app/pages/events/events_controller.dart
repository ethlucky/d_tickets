import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../models/event_model.dart';
import '../../services/contract_service.dart';

class EventsController extends GetxController {
  final ContractService _contractService = Get.find<ContractService>();

  // 当前选中的分类
  final RxString selectedCategory = 'All'.obs;

  // 分类列表
  final List<String> categories = ['All', 'Music', 'Comedy', 'Sports'];

  // 活动数据 - 使用EventModel
  final RxList<EventModel> events = <EventModel>[].obs;

  // 加载状态
  final RxBool isLoading = false.obs;

  // 获取筛选后的活动
  List<EventModel> get filteredEvents {
    if (selectedCategory.value == 'All') {
      return events;
    }
    return events
        .where((event) => event.category == selectedCategory.value)
        .toList();
  }

  // 分类选择
  void onCategorySelected(String category) {
    selectedCategory.value = category;
  }

  // 活动卡片点击
  void onEventTap(int index) {
    final event = filteredEvents[index];
    // 跳转到活动详情页面
    Get.toNamed(AppRoutes.getEventDetailRoute('event_${event.id}'));
  }

  // 菜单按钮点击
  void onMenuTap() {
    // TODO: 显示侧边菜单
    Get.snackbar('菜单', '菜单功能开发中...', snackPosition: SnackPosition.TOP);
  }

  /// 处理底部导航栏点击
  void onBottomNavTap(int index) {
    switch (index) {
      case 0:
        // Home - 返回首页
        Get.offAllNamed(AppRoutes.home);
        break;
      case 1:
        // Explore - 当前页面，无需操作
        break;
      case 2:
        // My Tickets - 跳转到我的票券页面
        Get.toNamed(AppRoutes.getMyTicketsDemoRoute());
        break;
      case 3:
        // Profile - 跳转到账户设置页面
        Get.toNamed(AppRoutes.getAccountSettingsDemoRoute());
        break;
    }
  }

  @override
  void onInit() {
    super.onInit();
    // 初始化加载数据
    _loadEvents();
  }

  /// 从ContractService加载活动数据
  Future<void> _loadEvents() async {
    try {
      isLoading.value = true;
      print('开始从ContractService加载活动数据...');

      final eventList = await _contractService.getAllEvents();
      events.assignAll(eventList);

      print('成功加载 ${eventList.length} 个活动');
    } catch (e) {
      print('加载活动数据失败: $e');
      Get.snackbar(
        '错误',
        '加载活动数据失败: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// 刷新数据
  Future<void> refreshEvents() async {
    await _loadEvents();
  }

  /// 搜索功能
  Future<void> searchEvents(String query) async {
    try {
      isLoading.value = true;

      if (query.isEmpty) {
        // 重置为所有活动
        await _loadEvents();
        return;
      }

      final searchResults = await _contractService.searchEvents(query);
      events.assignAll(searchResults);
    } catch (e) {
      print('搜索失败: $e');
      Get.snackbar(
        '搜索失败',
        e.toString(),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// 按分类过滤
  Future<void> filterByCategory(String category) async {
    try {
      isLoading.value = true;
      selectedCategory.value = category;

      final categoryEvents = await _contractService.getEventsByCategory(
        category,
      );
      events.assignAll(categoryEvents);
    } catch (e) {
      print('按分类过滤失败: $e');
      Get.snackbar(
        '过滤失败',
        e.toString(),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
    } finally {
      isLoading.value = false;
    }
  }
}
