import 'package:get/get.dart';
import 'event_detail_controller.dart';

/// 活动详情页面绑定
class EventDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EventDetailController>(() => EventDetailController());
  }
}
