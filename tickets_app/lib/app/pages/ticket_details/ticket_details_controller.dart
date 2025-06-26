import 'package:get/get.dart';
import '../my_tickets/my_tickets_controller.dart';

/// 票券详情页面控制器
class TicketDetailsController extends GetxController {
  // 票券信息
  late final Rx<TicketModel> ticket;

  // NFT详情
  final nftDetails = {
    'chainId': '137',
    'contractAddress': '0x123...abc',
    'metadata': 'View Metadata',
  }.obs;

  @override
  void onInit() {
    super.onInit();
    // 从路由参数获取票券信息
    final args = Get.arguments;
    if (args is TicketModel) {
      ticket = args.obs;
    } else {
      // 默认票券信息
      ticket = TicketModel(
        id: '1',
        eventName: 'Electronic Music Festival',
        date: 'Saturday, July 20, 2024',
        time: '7:00 PM',
        venue: 'VIP',
        seatInfo: 'Row: 12 · Seat: 3',
        status: TicketStatus.valid,
        imageUrl: '',
      ).obs;
    }
  }

  /// 转售票券
  void resellTicket() {
    Get.snackbar('转售', '票券转售功能开发中...', snackPosition: SnackPosition.TOP);
  }

  /// 退票
  void refundTicket() {
    Get.snackbar('退票', '退票功能开发中...', snackPosition: SnackPosition.TOP);
  }

  /// 查看元数据
  void viewMetadata() {
    Get.snackbar('元数据', '正在查看NFT元数据...', snackPosition: SnackPosition.TOP);
  }
}
