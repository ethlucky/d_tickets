import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app/core/app_binding.dart';
import 'app/routes/app_pages.dart';
import 'app/translations/app_translations.dart';
import 'app/controllers/theme_controller.dart';
import 'app/controllers/language_controller.dart';

void main() async {
  // 确保Flutter框架初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化GetStorage
  await GetStorage.init();

  // 运行应用
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  // 获取控制器实例
  final themeController = Get.put(ThemeController());
  final languageController = Get.put(LanguageController());

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844), // 设计稿尺寸
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => Obx(
        () => GetMaterialApp(
          // 应用基本配置
          title: 'Solana Tickets dApp',
          debugShowCheckedModeBanner: false,

          // 全局依赖注入
          initialBinding: AppBinding(),

          // 路由配置
          initialRoute: AppPages.initial,
          getPages: AppPages.routes,

          // 国际化配置
          translations: AppTranslations(),
          locale: languageController.currentLocale,
          fallbackLocale: const Locale('zh', 'CN'),

          // 主题配置
          theme: _lightTheme,
          darkTheme: _darkTheme,
          themeMode: themeController.themeMode,

          // 默认过渡动画
          defaultTransition: Transition.cupertino,
          transitionDuration: const Duration(milliseconds: 300),

          // 启用日志（调试模式）
          enableLog: true,
          logWriterCallback: (text, {bool isError = false}) {
            if (isError) {
              debugPrint('GetX Error: $text');
            } else {
              debugPrint('GetX: $text');
            }
          },
        ),
      ),
    );
  }

  /// 浅色主题
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );

  /// 深色主题
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );
}
