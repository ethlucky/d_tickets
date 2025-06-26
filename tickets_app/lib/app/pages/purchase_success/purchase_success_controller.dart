import 'package:get/get.dart';
import '../../models/event_model.dart';
import '../../models/ticket_type_model.dart';
import '../../models/seat_layout_model.dart';

/// 购票成功页面控制器
class PurchaseSuccessController extends GetxController {
  // 真实的购票数据
  final Rx<EventModel?> eventInfo = Rx<EventModel?>(null);
  final Rx<TicketTypeModel?> ticketTypeInfo = Rx<TicketTypeModel?>(null);
  final Rx<AreaLayoutModel?> areaInfo = Rx<AreaLayoutModel?>(null);
  final RxList<SeatLayoutItemModel> selectedSeats = <SeatLayoutItemModel>[].obs;
  final RxDouble total = 0.0.obs;

  // 格式化的票券信息
  final ticketInfo = {
    'eventName': '',
    'date': '',
    'section': '',
    'row': '',
    'seat': '',
  }.obs;

  @override
  void onInit() {
    super.onInit();
    _loadPurchaseData();
  }

  /// 加载购票数据
  void _loadPurchaseData() {
    final arguments = Get.arguments;
    if (arguments != null) {
      eventInfo.value = arguments['event'] as EventModel?;
      ticketTypeInfo.value = arguments['ticketType'] as TicketTypeModel?;
      areaInfo.value = arguments['area'] as AreaLayoutModel?;
      final seats = arguments['selectedSeats'] as List<SeatLayoutItemModel>?;
      if (seats != null) {
        selectedSeats.addAll(seats);
      }
      total.value = arguments['total'] as double? ?? 0.0;

      _updateTicketInfo();
    }
  }

  /// 更新票券信息显示
  void _updateTicketInfo() {
    final event = eventInfo.value;
    final area = areaInfo.value;

    if (event != null) {
      ticketInfo.value = {
        'eventName': event.title,
        'date': _formatDateForUS(event.startTime),
        'section': area?.areaName ?? '',
        'row': '',
        'seat': '',
      };

      if (selectedSeats.isNotEmpty) {
        final firstSeat = selectedSeats.first;

        // 解析行号信息
        String rowLetter = '';
        if (firstSeat.row != null && firstSeat.row!.isNotEmpty) {
          rowLetter = firstSeat.row!;
        } else {
          // 尝试从 seatNumber 中解析行号（例如：A-001 -> A）
          final parts = firstSeat.seatNumber.split('-');
          if (parts.length >= 2) {
            rowLetter = parts[0];
          }
        }

        // 解析座位号信息
        List<String> seatNumbers = [];
        for (final seat in selectedSeats) {
          if (seat.number != null && seat.number!.isNotEmpty) {
            seatNumbers.add(seat.number!);
          } else {
            // 尝试从 seatNumber 中解析座位号
            final parts = seat.seatNumber.split('-');
            if (parts.length >= 2) {
              seatNumbers.add(parts.last);
            } else {
              seatNumbers.add(seat.seatNumber);
            }
          }
        }

        // 美式格式化
        final section = area?.areaName ?? '';
        final row = rowLetter.isNotEmpty ? 'Row $rowLetter' : '';
        final seats = seatNumbers.length == 1
            ? 'Seat ${seatNumbers.first}'
            : 'Seats ${seatNumbers.join(', ')}';

        // 组合成美式格式：Section VIP, Row C, Seats 4, 3
        final seatInfoParts = <String>[];
        if (section.isNotEmpty) seatInfoParts.add(section);
        if (row.isNotEmpty) seatInfoParts.add(row);
        if (seats.isNotEmpty) seatInfoParts.add(seats);

        ticketInfo['section'] = seatInfoParts.join(', ');
        ticketInfo['row'] = ''; // 清空，因为已经包含在 section 中
        ticketInfo['seat'] = ''; // 清空，因为已经包含在 section 中
      }
    }
  }

  /// 查看我的票券
  void viewMyTickets() {
    Get.offAllNamed('/my-tickets-demo');
  }

  /// 返回首页
  void backToHome() {
    Get.offAllNamed('/');
  }

  /// 分享兴奋心情
  void shareExcitement() {
    Get.snackbar('分享成功', '已分享到社交媒体！', snackPosition: SnackPosition.TOP);
  }

  /// 格式化日期为美式格式
  String _formatDateForUS(DateTime dateTime) {
    // 美式格式：June 19, 2025 at 7:30 PM
    final months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    final month = months[dateTime.month];
    final day = dateTime.day;
    final year = dateTime.year;

    // 12小时制时间格式
    int hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';

    if (hour > 12) {
      hour -= 12;
    } else if (hour == 0) {
      hour = 12;
    }

    return '$month $day, $year at $hour:$minute $period';
  }


}
