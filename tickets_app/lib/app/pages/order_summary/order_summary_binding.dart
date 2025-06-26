import 'package:get/get.dart';
import 'order_summary_controller.dart';

/// 订单摘要页面绑定
class OrderSummaryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OrderSummaryController>(() => OrderSummaryController());
  }
}
