import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import '../../models/event_model.dart';
import '../../models/ticket_type_model.dart';
import '../../models/seat_layout_model.dart';
import '../../models/venue_model.dart';
import '../../models/wallet_request_model.dart';
import '../../services/contract_service.dart';
import '../../services/mobile_wallet_service.dart';
import '../../utils/transaction_builder.dart';

/// 订单摘要页面控制器
class OrderSummaryController extends GetxController {
  final ContractService _contractService = Get.find<ContractService>();

  // 传入的数据
  final Rx<EventModel?> eventInfo = Rx<EventModel?>(null);
  final Rx<TicketTypeModel?> ticketTypeInfo = Rx<TicketTypeModel?>(null);
  final Rx<AreaLayoutModel?> areaInfo = Rx<AreaLayoutModel?>(null);
  final RxList<SeatLayoutItemModel> selectedSeats = <SeatLayoutItemModel>[].obs;

  // 场馆信息
  final Rx<VenueModel?> venueDetails = Rx<VenueModel?>(null);
  final RxString venueName = ''.obs;

  // 价格信息
  final RxDouble platformFeeRate = 0.0.obs;
  final RxDouble venueFeeRate = 0.03.obs; // 3% 场馆费率
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // 获取路由参数
    final arguments = Get.arguments;
    if (arguments != null) {
      eventInfo.value = arguments['event'] as EventModel?;
      ticketTypeInfo.value = arguments['ticketType'] as TicketTypeModel?;
      areaInfo.value = arguments['area'] as AreaLayoutModel?;
      final seats = arguments['selectedSeats'] as List<SeatLayoutItemModel>?;
      if (seats != null) {
        selectedSeats.addAll(seats);
      }
    }
    _loadPlatformInfo();
    _loadVenueInfo();
  }

  /// 加载平台信息
  Future<void> _loadPlatformInfo() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final platformInfo = await _contractService.getPlatformInfo();
      if (platformInfo != null) {
        platformFeeRate.value = platformInfo.platformFeeBps / 10000; // 转换基点为百分比
      } else {
        hasError.value = true;
        errorMessage.value = '无法获取平台费率信息';
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = '加载平台信息失败: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// 加载场馆信息
  Future<void> _loadVenueInfo() async {
    final event = eventInfo.value;
    if (event == null || event.venueAccount.isEmpty) {
      print('❌ 无活动信息或场馆账户信息');
      return;
    }

    try {
      print('🏟️ 开始加载场馆信息: ${event.venueAccount}');

      final venue = await _contractService.getVenueById(event.venueAccount);

      if (venue != null) {
        print('✅ 成功加载场馆信息: ${venue.venueName}');
        print('  - 场馆地址: ${venue.venueAddress}');

        venueDetails.value = venue;
        venueName.value = venue.venueName;
      } else {
        print('❌ 未找到场馆信息');
      }
    } catch (e) {
      print('❌ 加载场馆信息失败: $e');
    }
  }

  /// 获取场馆地址信息
  String get venueAddress {
    final venue = venueDetails.value;
    if (venue != null && venue.venueAddress.isNotEmpty) {
      return venue.venueAddress;
    }
    return 'No address available';
  }

  /// 获取票价小计
  double get subtotal {
    if (ticketTypeInfo.value == null || selectedSeats.isEmpty) return 0;
    return ticketTypeInfo.value!.currentPrice /
        1000000000 *
        selectedSeats.length;
  }

  /// 获取平台费用
  double get platformFee {
    return subtotal * platformFeeRate.value;
  }

  /// 获取场馆费用
  double get venueFee {
    return subtotal * venueFeeRate.value;
  }

  /// 获取总价
  double get total {
    return subtotal + platformFee + venueFee;
  }

  /// 获取选中的座位数量
  int get selectedSeatsCount => selectedSeats.length;

  /// 获取选中的座位编号列表
  List<String> get selectedSeatNumbers {
    return selectedSeats.map((seat) => seat.seatNumber).toList();
  }

  /// 创建订单
  Future<void> createOrder() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      // 1. 创建购票交易数据
      final transactionInfo = await _createPurchaseTransaction();

      // 2. 请求用户签名交易
      final signatureResult = await _requestTransactionSignature(transactionInfo);

      if (signatureResult == RequestResult.approved) {
        // 3. 交易签名成功，跳转到购买成功页面
        Get.toNamed(
          AppRoutes.purchaseSuccess,
          arguments: {
            'event': eventInfo.value,
            'ticketType': ticketTypeInfo.value,
            'area': areaInfo.value,
            'selectedSeats': selectedSeats,
            'total': total,
          },
        );
      } else {
        throw Exception('用户取消了交易签名');
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = '创建订单失败: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// 创建购票交易数据
  Future<TransactionInfo> _createPurchaseTransaction() async {
    final event = eventInfo.value;
    final ticketType = ticketTypeInfo.value;
    final area = areaInfo.value;

    if (event == null || ticketType == null || area == null) {
      throw Exception('缺少活动、票种或区域信息');
    }

    if (selectedSeats.isEmpty) {
      throw Exception('未选择座位');
    }

    print('🎫 开始创建购票交易:');
    print('  - 活动: ${event.title}');
    print('  - 票种: ${ticketType.typeName}');
    print('  - 区域: ${area.areaId}');
    print('  - 座位数量: ${selectedSeats.length}');

    try {
      // 1. 生成活动PDA
      final eventPda = await _contractService.generateEventPDA(
        event.organizer,
        event.title,
      );
      print('📍 活动PDA: $eventPda');

      if (eventPda.isEmpty) {
        throw Exception('生成活动PDA失败');
      }

      // 2. 生成票种PDA
      final ticketTypePda = await _contractService.generateTicketTypePDA(
        eventPda,
        ticketType.typeName,
      );
      print('📍 票种PDA: $ticketTypePda');

      if (ticketTypePda.isEmpty) {
        throw Exception('生成票种PDA失败');
      }

      // 3. 生成座位状态映射PDA
      final seatStatusMapPda = await _contractService.generateSeatStatusMapPDA(
        eventPda,
        ticketTypePda,
        area.areaId,
      );
      print('📍 座位状态映射PDA: $seatStatusMapPda');

      if (seatStatusMapPda.isEmpty) {
        throw Exception('生成座位状态映射PDA失败');
      }

      // 4. 准备座位状态更新数据
      final seatUpdates = await _prepareSeatStatusUpdates();
      print('📊 座位更新数据: ${seatUpdates.length} 个座位');

      // 5. 调用合约服务创建批量更新座位状态的交易
      final transactionBytes = await _contractService.batchUpdateSeatStatus(
        eventPda: eventPda,
        ticketTypeName: ticketType.typeName,
        areaId: area.areaId,
        seatUpdates: seatUpdates,
      );

      print('✅ 交易创建成功，字节长度: ${transactionBytes.length}');

      // 6. 获取钱包地址
      final walletService = Get.find<MobileWalletService>();

      // 7. 创建交易信息对象
      return TransactionInfo.fromTransactionBytes(
        transactionBytes: transactionBytes,
        fromAddress: walletService.publicKey,
        toAddress: eventPda, // 使用活动PDA作为接收方
        amount: total,
        programId: _contractService.getProgramId(),
        instruction: 'batch_update_seat_status',
        additionalData: {
          'event_title': event.title,
          'ticket_type': ticketType.typeName,
          'area_id': area.areaId,
          'seat_count': selectedSeats.length,
          'seat_numbers': selectedSeats.map((s) => s.seatNumber).toList(),
        },
      );

    } catch (e) {
      print('❌ 创建购票交易失败: $e');
      rethrow;
    }
  }

  /// 准备座位状态更新数据
  Future<List<Map<String, dynamic>>> _prepareSeatStatusUpdates() async {
    final area = areaInfo.value;
    if (area == null) {
      throw Exception('缺少区域信息');
    }

    try {
      // 1. 生成必要的PDA
      final eventPda = await _contractService.generateEventPDA(
        eventInfo.value!.organizer,
        eventInfo.value!.title,
      );

      final ticketTypePda = await _contractService.generateTicketTypePDA(
        eventPda,
        ticketTypeInfo.value!.typeName,
      );

      final seatStatusMapPda = await _contractService.generateSeatStatusMapPDA(
        eventPda,
        ticketTypePda,
        area.areaId,
      );

      // 2. 尝试获取座位状态数据
      var seatStatusData = await _contractService.getSeatStatusData(seatStatusMapPda);

      // 3. 如果座位状态映射不存在，则使用座位布局数据创建索引映射
      Map<String, int>? seatIndexMap;

      if (seatStatusData?.seatIndexMap == null) {
        print('⚠️ 座位状态映射不存在，从座位布局创建索引映射');

        // 从座位布局数据创建索引映射
        seatIndexMap = await _createSeatIndexMapFromLayout();

        if (seatIndexMap == null) {
          throw Exception('无法创建座位索引映射');
        }
      } else {
        seatIndexMap = seatStatusData!.seatIndexMap!;
      }

      final seatUpdates = <Map<String, dynamic>>[];

      // 4. 为每个选中的座位创建更新数据
      for (final seat in selectedSeats) {
        final seatIndex = seatIndexMap[seat.seatNumber];
        if (seatIndex == null) {
          throw Exception('座位 ${seat.seatNumber} 未找到对应的索引');
        }

        // 创建座位状态更新数据
        seatUpdates.add({
          'seat_index': seatIndex,
          'new_status': {'Sold': {}}, // 设置为已售出状态
        });

        print('📍 座位更新: ${seat.seatNumber} -> 索引 $seatIndex -> Sold');
      }

      return seatUpdates;
    } catch (e) {
      print('❌ 准备座位状态更新数据失败: $e');
      rethrow;
    }
  }

  /// 从座位布局数据创建索引映射
  Future<Map<String, int>?> _createSeatIndexMapFromLayout() async {
    try {
      final area = areaInfo.value;
      if (area == null) return null;

      print('🔍 从选中座位创建索引映射');
      print('  - 区域: ${area.areaId}');
      print('  - 选中座位数量: ${selectedSeats.length}');

      final seatIndexMap = <String, int>{};

      // 将选中的座位按行号和座位号排序
      final sortedSeats = List<SeatLayoutItemModel>.from(selectedSeats);
      sortedSeats.sort((a, b) {
        // 从座位号中提取行号和座位号进行排序
        final aParts = a.seatNumber.split('-');
        final bParts = b.seatNumber.split('-');

        if (aParts.length >= 3 && bParts.length >= 3) {
          final aRow = aParts[1];
          final bRow = bParts[1];
          final aNum = int.tryParse(aParts[2]) ?? 0;
          final bNum = int.tryParse(bParts[2]) ?? 0;

          final rowCompare = aRow.compareTo(bRow);
          if (rowCompare != 0) return rowCompare;
          return aNum.compareTo(bNum);
        }

        return a.seatNumber.compareTo(b.seatNumber);
      });

      // 为每个座位分配索引
      for (int i = 0; i < sortedSeats.length; i++) {
        final seat = sortedSeats[i];
        seatIndexMap[seat.seatNumber] = i;
        print('  📍 ${seat.seatNumber} -> 索引 $i');
      }

      print('✅ 从选中座位创建索引映射: ${seatIndexMap.length} 个座位');
      return seatIndexMap;
    } catch (e) {
      print('❌ 从座位布局创建索引映射失败: $e');
      return null;
    }
  }

  /// 请求交易签名
  Future<RequestResult> _requestTransactionSignature(TransactionInfo transactionInfo) async {
    // 构建签名请求
    final signatureRequest = SignatureRequest(
      dappName: 'Tickets App',
      dappUrl: 'https://tickets-app.com',
      transactions: [transactionInfo],
      message: '确认购买 ${eventInfo.value?.title} 的门票',
    );

    // 跳转到签名确认页面
    final result = await Get.toNamed(
      '/dapp-signature-request',
      arguments: signatureRequest,
    );

    return result ?? RequestResult.cancelled;
  }

  /// 返回上一页
  void goBack() {
    Get.back();
  }
}

/// 订单票券模型
class OrderTicket {
  final String ticketType;
  final String seatInfo;

  OrderTicket({required this.ticketType, required this.seatInfo});
}
