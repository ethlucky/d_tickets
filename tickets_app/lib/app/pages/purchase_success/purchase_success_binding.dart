import 'package:get/get.dart';
import 'purchase_success_controller.dart';

/// 购票成功页面依赖注入绑定
class PurchaseSuccessBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PurchaseSuccessController>(() => PurchaseSuccessController());
  }
}
