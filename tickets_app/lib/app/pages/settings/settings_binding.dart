import 'package:get/get.dart';
import '../../controllers/theme_controller.dart';
import '../../controllers/language_controller.dart';

/// 设置页面绑定 - 负责依赖注入
class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    // 注入主题控制器和语言控制器
    Get.lazyPut<ThemeController>(() => ThemeController());
    Get.lazyPut<LanguageController>(() => LanguageController());
  }
}
