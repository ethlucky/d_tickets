import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// 主题控制器 - 管理应用主题
class ThemeController extends GetxController {
  final _storage = GetStorage();
  final RxBool _isDarkMode = false.obs;

  // Getters
  bool get isDarkMode => _isDarkMode.value;
  ThemeMode get themeMode =>
      _isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  @override
  void onInit() {
    super.onInit();
    // 从本地存储读取主题设置
    _loadThemeFromStorage();
  }

  /// 从本地存储加载主题设置
  void _loadThemeFromStorage() {
    final isDark = _storage.read('isDarkMode') ?? false;
    _isDarkMode.value = isDark;
  }

  /// 切换主题
  void toggleTheme() {
    _isDarkMode.value = !_isDarkMode.value;
    _saveThemeToStorage();

    // 应用主题变更
    Get.changeTheme(_isDarkMode.value ? _darkTheme : _lightTheme);

    // 显示切换提示
    Get.snackbar(
      '主题切换',
      _isDarkMode.value ? '已切换到深色主题' : '已切换到浅色主题',
      snackPosition: SnackPosition.TOP,
    );
  }

  /// 设置主题模式
  void setThemeMode(bool isDark) {
    _isDarkMode.value = isDark;
    _saveThemeToStorage();
    Get.changeTheme(isDark ? _darkTheme : _lightTheme);
  }

  /// 保存主题设置到本地存储
  void _saveThemeToStorage() {
    _storage.write('isDarkMode', _isDarkMode.value);
  }

  /// 浅色主题配置
  ThemeData get _lightTheme => ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.deepPurple,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );

  /// 深色主题配置
  ThemeData get _darkTheme => ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.deepPurple,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );

  /// 获取当前主题数据
  ThemeData get currentTheme => _isDarkMode.value ? _darkTheme : _lightTheme;
}
