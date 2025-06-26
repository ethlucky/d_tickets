import 'package:get/get.dart';
import 'ticket_details_controller.dart';

/// 票券详情页面依赖注入绑定
class TicketDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TicketDetailsController>(() => TicketDetailsController());
  }
}
