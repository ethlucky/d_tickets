import 'package:get/get.dart';
import 'my_tickets_controller.dart';

/// 我的票券页面依赖注入绑定
class MyTicketsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MyTicketsController>(() => MyTicketsController());
  }
}
