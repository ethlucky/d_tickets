import 'package:get/get.dart';
import 'home_controller.dart';

/// 首页绑定 - 负责依赖注入
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // 注入Home控制器
    Get.lazyPut<HomeController>(() => HomeController());
  }
}
