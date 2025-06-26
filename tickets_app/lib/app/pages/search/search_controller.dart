import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

class SearchController extends GetxController {
  // 搜索文本控制器
  final TextEditingController searchTextController = TextEditingController();

  // 响应式变量
  final RxString searchQuery = ''.obs;
  final RxString selectedCategory = 'All'.obs;
  final RxString selectedDateFilter = ''.obs;
  final RxString selectedPriceFilter = ''.obs;

  // 筛选选项
  final List<String> categories = [
    'All',
    'Concerts',
    'Sports',
    'Theater',
    'Comedy',
  ];
  final List<String> dateFilters = [
    'Today',
    'This Week',
    'This Month',
    'This Year',
  ];
  final List<String> priceFilters = [
    'Under \$50',
    '\$50-\$100',
    '\$100-\$200',
    'Over \$200',
  ];

  // 活动数据
  final List<Map<String, dynamic>> upcomingEvents = [
    {
      'id': '1',
      'category': 'Live Music',
      'title': 'The Lumineers',
      'venue': 'The Fillmore, San Francisco',
      'image': 'assets/images/lumineers.jpg',
      'price': 85.0,
      'date': DateTime.now().add(const Duration(days: 7)),
    },
    {
      'id': '2',
      'category': 'Live Music',
      'title': 'Coldplay',
      'venue': 'Levi\'s Stadium, Santa Clara',
      'image': 'assets/images/coldplay.jpg',
      'price': 120.0,
      'date': DateTime.now().add(const Duration(days: 14)),
    },
    {
      'id': '3',
      'category': 'Live Music',
      'title': 'Taylor Swift',
      'venue': 'Oracle Park, San Francisco',
      'image': 'assets/images/taylor_swift.jpg',
      'price': 200.0,
      'date': DateTime.now().add(const Duration(days: 21)),
    },
    {
      'id': '4',
      'category': 'Live Music',
      'title': 'Ed Sheeran',
      'venue': 'Chase Center, San Francisco',
      'image': 'assets/images/ed_sheeran.jpg',
      'price': 95.0,
      'date': DateTime.now().add(const Duration(days: 28)),
    },
    {
      'id': '5',
      'category': 'Live Music',
      'title': 'Billie Eilish',
      'venue': 'Golden Gate Park, San Francisco',
      'image': 'assets/images/billie_eilish.jpg',
      'price': 75.0,
      'date': DateTime.now().add(const Duration(days: 35)),
    },
  ];

  // 获取筛选后的活动列表
  List<Map<String, dynamic>> get filteredEvents {
    List<Map<String, dynamic>> filtered = List.from(upcomingEvents);

    // 按搜索关键词筛选
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered.where((event) {
        return event['title'].toLowerCase().contains(
              searchQuery.value.toLowerCase(),
            ) ||
            event['venue'].toLowerCase().contains(
              searchQuery.value.toLowerCase(),
            ) ||
            event['category'].toLowerCase().contains(
              searchQuery.value.toLowerCase(),
            );
      }).toList();
    }

    // 按分类筛选
    if (selectedCategory.value != 'All' && selectedCategory.value.isNotEmpty) {
      filtered = filtered.where((event) {
        return event['category'].toLowerCase().contains(
          selectedCategory.value.toLowerCase(),
        );
      }).toList();
    }

    // 按价格筛选
    if (selectedPriceFilter.value.isNotEmpty) {
      filtered = filtered.where((event) {
        double price = event['price'];
        switch (selectedPriceFilter.value) {
          case 'Under \$50':
            return price < 50;
          case '\$50-\$100':
            return price >= 50 && price <= 100;
          case '\$100-\$200':
            return price > 100 && price <= 200;
          case 'Over \$200':
            return price > 200;
          default:
            return true;
        }
      }).toList();
    }

    return filtered;
  }

  @override
  void onInit() {
    super.onInit();
    // 监听搜索输入
    searchTextController.addListener(() {
      searchQuery.value = searchTextController.text;
    });
  }

  @override
  void onClose() {
    searchTextController.dispose();
    super.onClose();
  }

  // 搜索功能
  void onSearchChanged(String query) {
    searchQuery.value = query;
  }

  // 清除搜索
  void clearSearch() {
    searchTextController.clear();
    searchQuery.value = '';
  }

  // 选择分类
  void selectCategory(String category) {
    selectedCategory.value = category;
  }

  // 显示日期筛选
  void showDateFilter() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Date',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...dateFilters.map(
              (filter) => ListTile(
                title: Text(filter),
                onTap: () {
                  selectedDateFilter.value = filter;
                  Get.back();
                },
                trailing: selectedDateFilter.value == filter
                    ? const Icon(Icons.check, color: Colors.black)
                    : null,
              ),
            ),
            ListTile(
              title: const Text('Clear Filter'),
              onTap: () {
                selectedDateFilter.value = '';
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }

  // 显示价格筛选
  void showPriceFilter() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Price Range',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...priceFilters.map(
              (filter) => ListTile(
                title: Text(filter),
                onTap: () {
                  selectedPriceFilter.value = filter;
                  Get.back();
                },
                trailing: selectedPriceFilter.value == filter
                    ? const Icon(Icons.check, color: Colors.black)
                    : null,
              ),
            ),
            ListTile(
              title: const Text('Clear Filter'),
              onTap: () {
                selectedPriceFilter.value = '';
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }

  // 显示分类筛选
  void showCategoryFilter() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...categories.map(
              (category) => ListTile(
                title: Text(category),
                onTap: () {
                  selectedCategory.value = category;
                  Get.back();
                },
                trailing: selectedCategory.value == category
                    ? const Icon(Icons.check, color: Colors.black)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 活动点击
  void onEventTap(String eventId) {
    Get.toNamed(AppRoutes.getEventDetailRoute(eventId));
  }

  /// 处理底部导航栏点击
  void onBottomNavTap(int index) {
    switch (index) {
      case 0:
        // Home - 跳转到首页
        Get.offAllNamed(AppRoutes.getHomeRoute());
        break;
      case 1:
        // Search - 当前页面，无需操作
        break;
      case 2:
        // Tickets - 跳转到我的票券页面
        Get.toNamed(AppRoutes.getMyTicketsDemoRoute());
        break;
      case 3:
        // Wallet - 跳转到钱包页面
        // Get.toNamed(AppRoutes.getWalletRoute());
        break;
      case 4:
        // Profile - 跳转到账户设置页面
        Get.toNamed(AppRoutes.getAccountSettingsDemoRoute());
        break;
    }
  }
}
