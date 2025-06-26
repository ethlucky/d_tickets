import 'package:get/get.dart';
import 'seat_detail_controller.dart';

/// 座位详细选择页面绑定
class SeatDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SeatDetailController>(() => SeatDetailController());
  }
}
