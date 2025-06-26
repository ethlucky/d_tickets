import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:bs58/bs58.dart';
import '../../routes/app_routes.dart';
import '../../models/event_model.dart';
import '../../models/ticket_type_model.dart';
import '../../models/venue_model.dart';

import '../../widgets/venue_svg_viewer.dart';
import '../../services/contract_service.dart';
import '../../services/arweave_service.dart';

/// 活动详情页面控制器
class EventDetailController extends GetxController {
  final ContractService _contractService = Get.find<ContractService>();
  final ArweaveService _arweaveService = Get.find<ArweaveService>();

  // 活动信息
  late final Rx<EventModel?> eventInfo;

  // 票种信息
  final RxList<TicketTypeModel> ticketTypes = <TicketTypeModel>[].obs;

  // 从Arweave加载的数据
  final RxString eventDescription = ''.obs;
  final Rx<Uint8List?> posterImageData = Rx<Uint8List?>(null);
  final RxMap<String, dynamic> performerDetails = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> contactInfo = <String, dynamic>{}.obs;
  final RxString refundPolicy = ''.obs;
  final RxString venueName = ''.obs;

  // 场馆详细信息
  final Rx<VenueModel?> venueDetails = Rx<VenueModel?>(null);

  // 加载状态
  final RxBool isLoading = false.obs;
  final RxBool isLoadingTicketTypes = false.obs;
  final RxBool isLoadingArweaveData = false.obs;

  // 错误信息
  final RxString errorMessage = ''.obs;

  // 活动PDA
  String? eventPda;

  // === 座位选择相关功能 ===
  // 选中的座位
  final RxList<Seat> selectedSeats = <Seat>[].obs;

  // 座位布局数据
  final RxList<List<Seat>> seatLayout = <List<Seat>>[].obs;

  // 座位区域信息
  final RxList<SeatAreaInfo> seatAreas = <SeatAreaInfo>[].obs;

  // 聚焦的区域ID
  final RxString focusedAreaId = ''.obs;

  // 座位选择加载状态
  final RxBool isLoadingVenue = false.obs;

  // SVG相关
  final RxBool isLoadingSvg = false.obs;
  final RxString svgData = ''.obs;

  // 场馆信息
  final RxString venueFloorPlanHash = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // 明确初始化eventInfo
    eventInfo = Rx<EventModel?>(null);
    _getEventPda();
    _loadEventDetail();
  }

  /// 获取活动PDA
  void _getEventPda() {
    // 从路由参数获取活动PDA
    eventPda = Get.parameters['id'] ?? Get.arguments as String?;

    if (eventPda == null || eventPda!.isEmpty) {
      errorMessage.value = 'Missing event identifier';
      print('错误: 未找到活动PDA参数');
      return;
    }

    print('获取到活动PDA: $eventPda');
  }

  /// 加载活动详情
  void _loadEventDetail() async {
    if (eventPda == null || eventPda!.isEmpty) {
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      print('开始加载活动详情: $eventPda');

      // 获取活动详情
      final event = await _contractService.getEventById(eventPda!);

      if (event != null) {
        eventInfo.value = event;
        print('✅ 成功加载活动: ${event.title}');

        // 加载票种信息
        await _loadTicketTypes();

        // 加载Arweave数据
        await _loadArweaveData();

        // 加载座位区域信息
        await loadSeatAreas();

        // 加载场馆SVG数据
        await _loadVenueData();
      } else {
        errorMessage.value = 'Event not found';
        print('❌ 未找到活动信息');
      }
    } catch (e) {
      errorMessage.value = 'Failed to load event details: $e';
      print('❌ 加载活动详情失败: $e');
      Get.snackbar('Error', 'Failed to load event details');
    } finally {
      isLoading.value = false;
    }
  }

  /// 加载票种信息
  Future<void> _loadTicketTypes() async {
    if (eventPda == null || eventPda!.isEmpty) {
      return;
    }

    try {
      isLoadingTicketTypes.value = true;

      print('开始加载票种信息: $eventPda');

      // 提取真正的PDA地址（去掉event_前缀）
      final actualEventPda = eventPda!.startsWith('event_')
          ? eventPda!.substring(6) // 去掉"event_"前缀
          : eventPda!;

      final eventTicketTypes =
          await _contractService.getEventTicketTypes(actualEventPda);

      ticketTypes.value = eventTicketTypes;
      print('✅ 成功加载 ${eventTicketTypes.length} 个票种');

      if (eventTicketTypes.isEmpty) {
        print('⚠️ 该活动暂无可用票种');
      }
    } catch (e) {
      print('❌ 加载票种信息失败: $e');
      // 票种加载失败不显示错误提示，只在控制台记录
    } finally {
      isLoadingTicketTypes.value = false;
    }
  }

  /// 加载Arweave数据
  Future<void> _loadArweaveData() async {
    if (eventInfo.value == null) return;

    try {
      isLoadingArweaveData.value = true;
      final event = eventInfo.value!;

      print('开始加载Arweave数据...');

      // 并行加载各种数据
      final futures = <Future>[];

      // 加载活动描述
      if (event.description.contains('IPFS:')) {
        final descHash = event.description.split('IPFS: ')[1];
        futures.add(_loadEventDescription(descHash));
      }

      // 加载海报图片
      if (event.posterImageHash.isNotEmpty &&
          event.posterImageHash != 'parse_error') {
        futures.add(_loadPosterImage(event.posterImageHash));
      }

      // 加载表演者详情
      if (event.performerDetailsHash.isNotEmpty &&
          event.performerDetailsHash != 'parse_error') {
        futures.add(_loadPerformerDetails(event.performerDetailsHash));
      }

      // 加载联系信息
      if (event.contactInfoHash.isNotEmpty &&
          event.contactInfoHash != 'parse_error') {
        futures.add(_loadContactInfo(event.contactInfoHash));
      }

      // 加载退款政策
      if (event.refundPolicyHash.isNotEmpty &&
          event.refundPolicyHash != 'parse_error') {
        futures.add(_loadRefundPolicy(event.refundPolicyHash));
      }

      // 场馆信息将在_loadVenueData中统一加载

      // 等待所有数据加载完成
      await Future.wait(futures);

      print('✅ Arweave数据加载完成');
    } catch (e) {
      print('❌ 加载Arweave数据失败: $e');
    } finally {
      isLoadingArweaveData.value = false;
    }
  }

  /// 加载活动描述
  Future<void> _loadEventDescription(String hash) async {
    try {
      final description = await _arweaveService.getTextData(hash);
      if (description != null) {
        eventDescription.value = description;
        print('✅ 活动描述加载成功');
      }
    } catch (e) {
      print('❌ 加载活动描述失败: $e');
    }
  }

  /// 加载海报图片
  Future<void> _loadPosterImage(String hash) async {
    try {
      final imageData = await _arweaveService.getImageData(hash);
      if (imageData != null) {
        posterImageData.value = imageData;
        print('✅ 海报图片加载成功');
      }
    } catch (e) {
      print('❌ 加载海报图片失败: $e');
    }
  }

  /// 加载表演者详情
  Future<void> _loadPerformerDetails(String hash) async {
    try {
      final details = await _arweaveService.getJsonData(hash);
      if (details != null) {
        performerDetails.value = details;
        print('✅ 表演者详情加载成功');
      }
    } catch (e) {
      print('❌ 加载表演者详情失败: $e');
    }
  }

  /// 加载联系信息
  Future<void> _loadContactInfo(String hash) async {
    try {
      final contact = await _arweaveService.getJsonData(hash);
      if (contact != null) {
        contactInfo.value = contact;
        print('✅ 联系信息加载成功');
      }
    } catch (e) {
      print('❌ 加载联系信息失败: $e');
    }
  }

  /// 加载退款政策
  Future<void> _loadRefundPolicy(String hash) async {
    try {
      final policy = await _arweaveService.getTextData(hash);
      if (policy != null) {
        refundPolicy.value = policy;
        print('✅ 退款政策加载成功');
      }
    } catch (e) {
      print('❌ 加载退款政策失败: $e');
    }
  }

  /// 加载场馆名称
  Future<void> _loadVenueName(String venueAccount) async {
    try {
      print('=== 开始查询场馆信息 ===');
      print('原始venue_account: $venueAccount');
      print('venue_account长度: ${venueAccount.length}');
      print('是否包含=号: ${venueAccount.contains('=')}');

      // venueAccount可能是以下几种格式：
      // 1. Base64编码的32字节pubkey（从链上解析得到）
      // 2. Base58编码的Solana地址
      // 3. Arweave哈希值

      String? venueIdToQuery;

      // 首先尝试将base64转换为Base58格式的Solana地址
      try {
        if (venueAccount.length > 20 && venueAccount.contains('=')) {
          // 看起来像base64编码，尝试转换为Base58
          final base64Bytes = base64Decode(venueAccount);
          if (base64Bytes.length == 32) {
            // 32字节的pubkey，转换为Base58格式的Solana地址
            venueIdToQuery = base58.encode(base64Bytes);
            print('✅ 成功转换base64到Base58: $venueIdToQuery');
          } else {
            print('⚠️ base64解码后长度不是32字节: ${base64Bytes.length}');
            venueIdToQuery = null;
          }
        } else if (venueAccount.length >= 32 && venueAccount.length <= 44) {
          // 看起来像Base58编码的Solana地址
          venueIdToQuery = venueAccount;
          print('✅ 检测到Base58格式地址: $venueIdToQuery');
        } else {
          // 可能是Arweave哈希值，暂时不处理
          print('可能是Arweave哈希值: $venueAccount');
          venueIdToQuery = null;
        }
      } catch (e) {
        print('地址格式转换失败: $e');
        venueIdToQuery = null;
      }

      // 如果有有效的地址，尝试查询场馆信息
      if (venueIdToQuery != null) {
        final venue = await _contractService.getVenueById(venueIdToQuery);

        if (venue != null) {
          venueName.value = venue.venueName;
          venueDetails.value = venue; // 保存完整的场馆信息
          print('✅ 成功获取场馆信息: ${venue.venueName}');
          print('  场馆地址: ${venue.venueAddress}');
          print('  场馆类型: ${venue.formattedVenueType}');
          print('  场馆容量: ${venue.totalCapacity}');
          return;
        }
      }

      // 如果Base58查询失败，尝试直接使用原始的base64编码查询
      if (venueAccount.length > 20 && venueAccount.contains('=')) {
        print('🔄 Base58查询失败，尝试使用原始base64地址查询');
        final venue = await _contractService.getVenueById(venueAccount);

        if (venue != null) {
          venueName.value = venue.venueName;
          venueDetails.value = venue; // 保存完整的场馆信息
          print('✅ 使用base64地址成功获取场馆信息: ${venue.venueName}');
          return;
        }
      }

      // 如果是Arweave哈希，尝试从Arweave加载场馆名称
      if (venueAccount.length == 43 || venueAccount.length == 44) {
        try {
          final venueData = await _arweaveService.getJsonData(venueAccount);
          if (venueData != null && venueData['venue_name'] != null) {
            venueName.value = venueData['venue_name'];
            print('✅ 从Arweave获取场馆名称: ${venueData['venue_name']}');
            return;
          }
        } catch (e) {
          print('从Arweave加载场馆信息失败: $e');
        }
      }

      // 所有方法都失败时的回退显示
      print('⚠️ 未找到场馆信息，使用简化显示');
      if (venueAccount.length > 12) {
        venueName.value =
            '${venueAccount.substring(0, 8)}...${venueAccount.substring(venueAccount.length - 4)}';
      } else {
        venueName.value = venueAccount;
      }
    } catch (e) {
      print('❌ 加载场馆信息失败: $e');
      // 出错时使用简化的PDA显示
      if (venueAccount.length > 12) {
        venueName.value =
            '${venueAccount.substring(0, 8)}...${venueAccount.substring(venueAccount.length - 4)}';
      } else {
        venueName.value = venueAccount;
      }
    }
  }

  /// 刷新数据
  void refreshData() {
    _loadEventDetail();
  }

  /// 跳转到座位选择页面
  void goToSeatSelection() {
    if (eventPda == null || eventPda!.isEmpty) {
      Get.snackbar('Error', 'Event information not available');
      return;
    }

    if (eventInfo.value == null) {
      Get.snackbar('Error', 'Event details not loaded');
      return;
    }

    // 检查是否有座位区域映射
    final mappings = seatAreaMappings;
    if (mappings.isEmpty) {
      // 如果没有座位区域映射，显示提示信息
      Get.snackbar(
        'Notice',
        'No seating areas configured for this event',
        backgroundColor: Colors.orange[100],
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // 如果只有一个区域映射，直接跳转到座位详细选择页面
    if (mappings.length == 1) {
      _navigateToSeatDetail(mappings.first);
      return;
    }

    // 如果有多个区域映射，显示选择对话框
    _showAreaSelectionDialog(mappings);
  }

  /// 显示区域选择对话框
  void _showAreaSelectionDialog(List<Map<String, String>> mappings) {
    Get.dialog(
      AlertDialog(
        title: const Text(
          'Select Seating Area',
          style: TextStyle(
            fontFamily: 'Public Sans',
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: mappings.length,
            itemBuilder: (context, index) {
              final mapping = mappings[index];
              final ticketType = mapping['ticketType']!;
              final areaId = mapping['areaId']!;

              return ListTile(
                title: Text(
                  'Area $areaId - $ticketType',
                  style: const TextStyle(
                    fontFamily: 'Public Sans',
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  'Select seats in $areaId area',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                onTap: () {
                  Get.back(); // 关闭对话框
                  _navigateToSeatDetail(mapping);
                },
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Public Sans',
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 跳转到座位详细选择页面
  void _navigateToSeatDetail(Map<String, String> mapping) {
    final ticketTypeName = mapping['ticketType']!;
    final areaId = mapping['areaId']!;

    print('🚀 从活动详情页面跳转到座位详细选择页面');
    print('   - 活动: ${eventInfo.value?.title}');
    print('   - 票种: $ticketTypeName');
    print('   - 区域: $areaId');
    print('   - EventPDA: $eventPda');

    // 根据智能合约IDL生成SeatStatusMap PDA
    // 实际项目中这应该通过智能合约SDK计算
    final mockSeatStatusMapPDA =
        'seat_status_map_${eventPda}_${ticketTypeName}_${areaId}_${DateTime.now().millisecondsSinceEpoch}';

    // 跳转到座位详细选择页面
    Get.toNamed(
      AppRoutes.getSeatDetailRoute(
        seatStatusMapPDA: mockSeatStatusMapPDA,
        eventPda: eventPda,
        ticketTypeName: ticketTypeName,
        areaId: areaId,
      ),
      arguments: {
        'seatStatusMapPDA': mockSeatStatusMapPDA,
        'eventPda': eventPda,
        'ticketTypeName': ticketTypeName,
        'areaId': areaId,
        'eventInfo': eventInfo.value,
        'isFromEventDetail': true, // 标记来源于活动详情页面
      },
    );
  }

  /// 购买票券（保留原方法以防其他地方使用）
  void buyTicket(TicketTypeModel ticketType) {
    if (!ticketType.isAvailable) {
      Get.snackbar('Notice', 'This ticket type is sold out');
      return;
    }

    // 现在使用统一的座位选择逻辑
    goToSeatSelection();
  }

  /// 返回上一页
  void goBack() {
    Get.back();
  }

  /// 获取格式化的活动日期
  String get formattedEventDate {
    if (eventInfo.value == null) return '';

    final event = eventInfo.value!;
    final startTime = event.startTime;

    // 使用美国日期格式 MM/DD/YYYY
    return '${startTime.month.toString().padLeft(2, '0')}/${startTime.day.toString().padLeft(2, '0')}/${startTime.year}';
  }

  /// 获取格式化的活动时间
  String get formattedEventTime {
    if (eventInfo.value == null) return '';

    final event = eventInfo.value!;
    final startTime = event.startTime;

    return '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
  }

  /// 获取活动场馆信息
  String get venueInfo {
    if (eventInfo.value == null) return '';

    // 优先显示场馆名称
    if (venueName.value.isNotEmpty) {
      return venueName.value;
    }

    final event = eventInfo.value!;
    // 如果有venue_account，显示简化的场馆信息
    if (event.venueAccount.isNotEmpty && event.venueAccount != 'parse_error') {
      // 显示前8位和后4位，中间用省略号
      final venue = event.venueAccount;
      if (venue.length > 12) {
        return '${venue.substring(0, 8)}...${venue.substring(venue.length - 4)}';
      }
      return venue;
    }

    return 'No venue information';
  }

  /// 获取活动状态文本
  String get statusText {
    if (eventInfo.value == null) return '';

    final event = eventInfo.value!;
    switch (event.status.toLowerCase()) {
      case 'upcoming':
        return 'Upcoming';
      case 'onsale':
        return 'On Sale';
      case 'soldout':
        return 'Sold Out';
      case 'cancelled':
        return 'Cancelled';
      case 'postponed':
        return 'Postponed';
      case 'completed':
        return 'Completed';
      default:
        return event.status;
    }
  }

  /// 是否可以购买
  bool get canPurchase {
    if (eventInfo.value == null) return false;

    final event = eventInfo.value!;
    final now = DateTime.now();

    // 检查销售时间
    if (now.isBefore(event.saleStartTime) || now.isAfter(event.saleEndTime)) {
      return false;
    }

    // 检查活动状态
    final status = event.status.toLowerCase();
    return status == 'onsale' || status == 'upcoming';
  }

  /// 获取购买按钮文本
  String get purchaseButtonText {
    if (eventInfo.value == null) return 'Loading...';

    if (!canPurchase) {
      final event = eventInfo.value!;
      final now = DateTime.now();

      if (now.isBefore(event.saleStartTime)) {
        return 'Sale Not Started';
      } else if (now.isAfter(event.saleEndTime)) {
        return 'Sale Ended';
      } else {
        return 'Not Available';
      }
    }

    return 'Buy Tickets';
  }

  /// 获取座位区域映射信息
  List<Map<String, String>> get seatAreaMappings {
    if (eventInfo.value == null ||
        eventInfo.value!.ticketAreaMappings.isEmpty) {
      return [];
    }

    final List<Map<String, String>> mappings = [];

    for (final mapping in eventInfo.value!.ticketAreaMappings) {
      // 解析格式："票种名-区域ID"
      final parts = mapping.split('-');
      if (parts.length >= 2) {
        final ticketTypeName = parts[0].trim();
        final areaId = parts.sublist(1).join('-').trim(); // 支持区域ID包含多个"-"

        mappings.add({
          'ticketType': ticketTypeName,
          'areaId': areaId,
        });
      }
    }

    return mappings;
  }

  /// 获取格式化的座位区域信息
  String get formattedSeatAreas {
    final mappings = seatAreaMappings;
    if (mappings.isEmpty) {
      return 'No seating areas configured';
    }

    final areaGroups = <String, List<String>>{};

    // 按区域ID分组票种
    for (final mapping in mappings) {
      final areaId = mapping['areaId']!;
      final ticketType = mapping['ticketType']!;

      if (areaGroups.containsKey(areaId)) {
        areaGroups[areaId]!.add(ticketType);
      } else {
        areaGroups[areaId] = [ticketType];
      }
    }

    // 格式化为可读文本
    final List<String> formattedAreas = [];
    for (final entry in areaGroups.entries) {
      final areaId = entry.key;
      final ticketTypes = entry.value.join(', ');
      formattedAreas.add('$areaId: $ticketTypes');
    }

    return formattedAreas.join('\n');
  }

  /// 获取场馆SVG数据（用于UI显示）
  String get venueFloorPlan => svgData.value;

  /// 是否有场馆SVG数据
  bool get hasVenueFloorPlan => svgData.value.isNotEmpty;

  /// 获取当前聚焦的区域ID
  String get currentFocusedAreaId => focusedAreaId.value;

  /// 获取场馆地址信息
  String get venueAddress {
    final venue = venueDetails.value;
    if (venue != null && venue.venueAddress.isNotEmpty) {
      return venue.venueAddress;
    }
    return 'No address available';
  }

  /// 获取场馆容量信息
  String get venueCapacity {
    final venue = venueDetails.value;
    if (venue != null && venue.totalCapacity > 0) {
      return '${venue.totalCapacity} seats';
    }
    return 'Capacity not specified';
  }

  /// 获取场馆描述信息
  String get venueDescription {
    final venue = venueDetails.value;
    if (venue != null && venue.venueDescription.isNotEmpty) {
      return venue.venueDescription;
    }
    return 'No description available';
  }

  /// 获取场馆类型信息
  String get venueType {
    final venue = venueDetails.value;
    if (venue != null) {
      return venue.formattedVenueType;
    }
    return 'Type not specified';
  }

  // === 座位选择功能方法 ===

  /// 加载座位区域信息
  Future<void> loadSeatAreas() async {
    if (eventInfo.value == null) return;

    try {
      final event = eventInfo.value!;
      final areas = <SeatAreaInfo>[];

      print('🔍 开始加载座位区域信息');
      print('📋 活动名称: ${event.title}');
      print('📋 票种-区域映射数量: ${event.ticketAreaMappings.length}');

      if (event.ticketAreaMappings.isNotEmpty) {
        print('📋 票种-区域映射列表:');
        for (int i = 0; i < event.ticketAreaMappings.length; i++) {
          print('   [$i] ${event.ticketAreaMappings[i]}');
        }
      }

      // 解析活动的座位区域映射
      for (final mapping in event.ticketAreaMappings) {
        final parts = mapping.split('-');
        if (parts.length >= 2) {
          final ticketTypeName = parts[0].trim();
          final areaId = parts.sublist(1).join('-').trim();

          print('🎯 解析区域映射: $ticketTypeName -> $areaId');

          // 从智能合约获取真实的座位数量
          final seatCounts =
              await _getSeatCountsFromContract(ticketTypeName, areaId);

          // 只有在成功获取到真实数据时才创建区域信息
          if (seatCounts.isNotEmpty &&
              seatCounts['totalSeats'] != null &&
              seatCounts['totalSeats']! > 0) {
            // 生成区域信息
            final area = SeatAreaInfo(
              areaId: areaId,
              ticketTypeName: ticketTypeName,
              x: _getAreaX(areaId),
              y: _getAreaY(areaId),
              width: 24,
              height: 24,
              totalSeats: seatCounts['totalSeats']!,
              availableSeats: seatCounts['availableSeats']!,
            );

            areas.add(area);
            print(
                '✅ 创建区域信息: ${area.areaId} 位置(${area.x}, ${area.y}) 座位${area.availableSeats}/${area.totalSeats}');
          } else {
            print('❌ 跳过区域 $areaId - 未能从区块链获取到有效的座位数据');
          }
        }
      }

      seatAreas.value = areas;
      print('✅ 成功加载 ${areas.length} 个座位区域');

      // 如果没有区域映射或没有有效数据，不创建任何数据
      if (areas.isEmpty) {
        print('⚠️ 没有座位区域数据，不显示座位区域列表');
      }
    } catch (e) {
      print('❌ 加载座位区域失败: $e');
    }
  }

  /// 从智能合约获取座位数量信息
  Future<Map<String, int>> _getSeatCountsFromContract(
      String ticketTypeName, String areaId) async {
    try {
      if (eventPda == null || eventPda!.isEmpty) {
        print('❌ EventPDA为空，无法查询座位数量');
        return {};
      }

      print('🔍 查询座位数量 - 票种: $ticketTypeName, 区域: $areaId');
      print('🔍 当前EventPDA: $eventPda');

      // 1. 提取真正的PDA地址（去掉event_前缀）
      final actualEventPda = eventPda!.startsWith('event_')
          ? eventPda!.substring(6) // 去掉"event_"前缀
          : eventPda!;

      print('🔍 处理后的EventPDA: $actualEventPda');

      // 2. 首先获取活动的所有票种，找到对应的票种
      final ticketTypes =
          await _contractService.getEventTicketTypes(actualEventPda);
      print(
          '📋 获取到 ${ticketTypes.length} 个票种: ${ticketTypes.map((t) => t.typeName).join(', ')}');

      final targetTicketType =
          ticketTypes.where((t) => t.typeName == ticketTypeName).firstOrNull;

      if (targetTicketType == null) {
        print('❌ 未找到票种: $ticketTypeName');
        print('📋 可用票种: ${ticketTypes.map((t) => t.typeName).join(', ')}');
        return {};
      }

      print('✅ 找到目标票种: ${targetTicketType.typeName}');

      // 3. 生成票种PDA
      final ticketTypePDA = await _contractService.generateTicketTypePDA(
          actualEventPda, ticketTypeName);
      print('🔍 生成票种PDA: $ticketTypePDA');

      // 4. 根据智能合约的seeds逻辑构造SeatStatusMap PDA
      // seeds = [b"seat_status_map", event.key().as_ref(), ticket_type.key().as_ref(), area_id.as_bytes()]
      final seatStatusMapPDA = await _contractService.generateSeatStatusMapPDA(
        actualEventPda,
        ticketTypePDA,
        areaId,
      );

      print('🔍 生成SeatStatusMap PDA: $seatStatusMapPDA');

      // 4. 尝试获取 SeatStatusMap 账户数据
      print('🔍 开始查询SeatStatusMap账户数据...');
      final seatStatusMapData =
          await _contractService.getSeatStatusMapData(seatStatusMapPDA);

      if (seatStatusMapData == null) {
        print('❌ 未找到SeatStatusMap账户: $seatStatusMapPDA');
        print('💡 这可能是因为：');
        print('   1. PDA生成算法不正确（目前是模拟的）');
        print('   2. 该区域的座位配置尚未发布到链上');
        print('   3. 网络连接问题');
        return {};
      }

      final totalSeats = seatStatusMapData.totalSeats;
      final soldSeats = seatStatusMapData.soldSeats;
      final seatLayoutHash = seatStatusMapData.seatLayoutHash;

      print('✅ 成功获取SeatStatusMap数据:');
      print('   总座位: $totalSeats');
      print('   已售座位: $soldSeats');
      print('   座位布局哈希: $seatLayoutHash');

      // 5. 如果有 seat_layout_hash，从 Arweave 获取详细座位信息
      if (seatLayoutHash.isNotEmpty) {
        print('🔍 尝试从Arweave获取详细座位布局数据...');
        final seatLayoutData =
            await _arweaveService.getJsonData(seatLayoutHash);
        if (seatLayoutData != null) {
          final areas = seatLayoutData['areas'] as List?;
          if (areas != null) {
            // 查找匹配的区域
            for (final areaData in areas) {
              if (areaData['areaId'] == areaId) {
                final seats = areaData['seats'] as List?;
                final arweaveTotalSeats = seats?.length ?? totalSeats;
                final availableSeats = arweaveTotalSeats - soldSeats;

                print('✅ 从Arweave获取到详细座位数据:');
                print('   区域: $areaId');
                print('   详细座位数: $arweaveTotalSeats');
                print('   可用座位: $availableSeats');

                return {
                  'totalSeats': arweaveTotalSeats,
                  'availableSeats': availableSeats,
                };
              }
            }
            print('⚠️ 在Arweave数据中未找到区域: $areaId');
          }
        } else {
          print('❌ 无法从Arweave获取座位布局数据');
        }
      }

      // 6. 如果没有详细数据，使用合约中的基本信息
      final availableSeats = totalSeats - soldSeats;

      print('✅ 使用合约基本数据:');
      print('   总座位: $totalSeats');
      print('   可用座位: $availableSeats');

      return {
        'totalSeats': totalSeats,
        'availableSeats': availableSeats,
      };
    } catch (e) {
      print('❌ 获取座位数量失败: $e');
      print('🔍 错误堆栈: ${StackTrace.current}');
      return {};
    }
  }

  /// 根据区域ID获取X坐标
  double _getAreaX(String areaId) {
    switch (areaId.toLowerCase()) {
      case 'a':
      case 'vip':
      case 'vip001':
        return 80;
      case 'b':
      case '普通席':
      case 'normal':
      case 'normal001':
        return 200;
      case 'c':
      case '经济席':
        return 320;
      case 'd':
        return 120;
      case 'e':
        return 280;
      default:
        final hash = areaId.hashCode;
        return 60 + ((hash % 280).abs().toDouble());
    }
  }

  /// 根据区域ID获取Y坐标
  double _getAreaY(String areaId) {
    switch (areaId.toLowerCase()) {
      case 'a':
      case 'vip':
      case 'vip001':
        return 80;
      case 'b':
      case '普通席':
      case 'normal':
      case 'normal001':
        return 150;
      case 'c':
      case '经济席':
        return 220;
      case 'd':
        return 100;
      case 'e':
        return 180;
      default:
        final hash = areaId.hashCode;
        return 60 + ((hash % 180).abs().toDouble());
    }
  }

  /// 点击区域事件
  void onAreaTap(SeatAreaInfo area) {
    print('🎯 点击了区域: ${area.areaId} (${area.ticketTypeName})');

    // 只设置聚焦区域，不进行页面跳转
    focusedAreaId.value = area.areaId;
  }

  /// 格式化区域ID显示
  String formatAreaDisplay(String areaId) {
    // 处理像 "vip001-A-012" 这样的格式，提取最后两部分并合并
    final parts = areaId.split('-');

    if (parts.length >= 2) {
      // 取最后两部分
      final letter = parts[parts.length - 2]; // 如 "A"
      final number = parts[parts.length - 1]; // 如 "012"

      // 移除前导零并组合
      final cleanNumber = int.tryParse(number)?.toString() ?? number;
      return '$letter$cleanNumber'; // 如 "A12"
    }

    // 如果格式不符合预期，返回原始值
    return areaId;
  }

  /// 加载场馆数据（包括SVG）
  Future<void> _loadVenueData() async {
    if (eventInfo.value == null) {
      print('❌ 无活动信息，无法加载场馆数据');
      return;
    }

    try {
      isLoadingVenue.value = true;
      final event = eventInfo.value!;
      print('🏟️ 开始加载场馆数据: ${event.venueAccount}');

      // 加载场馆信息
      final venue = await _contractService.getVenueById(event.venueAccount);

      if (venue != null) {
        print('✅ 成功加载场馆信息: ${venue.venueName}');
        print('  - 场馆地址: ${venue.venueAddress}');

        venueDetails.value = venue;
        venueName.value = venue.venueName; // 同时设置场馆名称

        print('  - 场馆数据已设置到响应式变量');

        // 处理场馆描述
        final description = venue.venueDescription;
        if (description.isNotEmpty) {
          String? descHash;

          // 检查是否是IPFS格式
          if (description.startsWith('IPFS: ')) {
            descHash = description.split('IPFS: ')[1];
          }
          // 检查是否直接是hash值（43或44个字符的Arweave hash）
          else if (description.length >= 43 && description.length <= 44) {
            descHash = description;
          }

          // 如果找到了hash，尝试从Arweave加载内容
          if (descHash != null) {
            print('🔍 从Arweave加载场馆描述: $descHash');
            try {
              final actualDescription =
                  await _arweaveService.getTextData(descHash);
              if (actualDescription != null) {
                // 创建一个新的VenueModel实例，更新描述
                venueDetails.value =
                    venue.copyWith(venueDescription: actualDescription);
                print('✅ 成功加载场馆描述');
              }
            } catch (e) {
              print('❌ 加载场馆描述失败: $e');
            }
          }
        }

        // 如果场馆有平面图，加载SVG数据
        if (venue.floorPlanHash?.isNotEmpty == true) {
          venueFloorPlanHash.value = venue.floorPlanHash!;
          await _loadVenueSvg(venue.floorPlanHash!);
        }
      } else {
        print('❌ 未找到场馆信息');
      }
    } catch (e) {
      print('❌ 加载场馆数据失败: $e');
    } finally {
      isLoadingVenue.value = false;
    }
  }

  /// 加载场馆SVG平面图
  Future<void> _loadVenueSvg(String floorPlanHash) async {
    try {
      isLoadingSvg.value = true;
      print('🔍 加载场馆SVG: $floorPlanHash');

      final svg = await _arweaveService.getSvgDataEnhanced(floorPlanHash);
      print(
          '🔍 ArweaveService返回的SVG结果: ${svg != null ? "非空" : "null"}, 长度: ${svg?.length ?? 0}');

      // 模仿seat_detail_controller的逻辑，只检查非null
      if (svg != null) {
        svgData.value = svg;
        print('✅ 成功加载场馆SVG，长度: ${svg.length} 字符');

        // 额外的验证信息
        if (svg.toLowerCase().contains('<svg')) {
          print('📄 SVG验证: 包含<svg>标签 ✓');
        } else {
          print('⚠️ SVG验证: 未找到<svg>标签');
        }

        if (svg.toLowerCase().contains('</svg>')) {
          print('📄 SVG验证: 包含</svg>标签 ✓');
        } else {
          print('⚠️ SVG验证: 未找到</svg>标签');
        }

        print('📄 SVG开头: ${svg.length > 100 ? svg.substring(0, 100) : svg}');
      } else {
        print('❌ 加载场馆SVG失败: ArweaveService返回null');
      }
    } catch (e) {
      print('❌ 加载场馆SVG失败: $e');
    } finally {
      isLoadingSvg.value = false;
    }
  }

  /// 聚焦到指定区域
  void focusOnArea(String areaId) {
    print('🎯 聚焦到区域: $areaId');
    focusedAreaId.value = areaId;
  }

  /// 清除聚焦
  void clearFocus() {
    print('🎯 清除聚焦');
    focusedAreaId.value = '';
  }

  /// 用于VenueSvgViewer的聚焦控制
  void focusOnAreaFromViewer(String areaId) {
    focusOnArea(areaId);
  }

  /// 刷新场馆数据
  Future<void> refreshVenueData() async {
    await _loadVenueData();
  }

  /// 重新加载SVG数据
  Future<void> reloadVenueSvg() async {
    if (venueFloorPlanHash.value.isNotEmpty) {
      await _loadVenueSvg(venueFloorPlanHash.value);
    }
  }

  /// 初始化座位布局
  void initializeSeatLayout() {
    List<List<Seat>> layout = [];
    for (int row = 0; row < 6; row++) {
      List<Seat> rowSeats = [];
      for (int col = 0; col < 8; col++) {
        rowSeats.add(
          Seat(
            id: 'R${row + 1}S${col + 1}',
            row: row + 1,
            seatNumber: col + 1,
            status: _getRandomSeatStatus(),
          ),
        );
      }
      layout.add(rowSeats);
    }
    seatLayout.value = layout;
  }

  /// 获取随机座位状态
  SeatStatus _getRandomSeatStatus() {
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    if (random < 70) return SeatStatus.available;
    if (random < 85) return SeatStatus.occupied;
    return SeatStatus.reserved;
  }

  /// 点击座位
  void onSeatTap(Seat seat) {
    if (seat.status != SeatStatus.available) {
      Get.snackbar('Notice', 'This seat is not available');
      return;
    }

    if (selectedSeats.contains(seat)) {
      selectedSeats.remove(seat);
    } else {
      selectedSeats.add(seat);
    }
  }

  /// 确认选择座位
  void confirmSeatSelection() {
    if (selectedSeats.isEmpty) {
      Get.snackbar('Notice', 'Please select seats first');
      return;
    }

    Get.toNamed(AppRoutes.getOrderSummaryRoute());
  }
}

/// 座位模型
class Seat {
  final String id;
  final int row;
  final int seatNumber;
  final SeatStatus status;

  Seat({
    required this.id,
    required this.row,
    required this.seatNumber,
    required this.status,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Seat && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// 座位状态枚举
enum SeatStatus {
  available, // 可选择
  selected, // 已选中
  occupied, // 已占用
  reserved, // 已预订
}
