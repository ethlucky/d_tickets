import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import '../../models/event_model.dart';
import '../../models/ticket_type_model.dart';
import '../../models/venue_model.dart';
import '../../models/seat_layout_model.dart';
import '../../services/contract_service.dart';
import '../../services/arweave_service.dart';

/// 座位详细选择页面控制器
class SeatDetailController extends GetxController {
  final ContractService _contractService = Get.find<ContractService>();
  final ArweaveService _arweaveService = Get.find<ArweaveService>();

  // 传入参数
  String? seatStatusMapPDA;
  String? eventPda;
  String? ticketTypeName;
  String? areaId;

  // 数据模型
  final Rx<EventModel?> eventInfo = Rx<EventModel?>(null);
  final Rx<TicketTypeModel?> ticketTypeInfo = Rx<TicketTypeModel?>(null);
  final Rx<VenueModel?> venueInfo = Rx<VenueModel?>(null);
  final Rx<SeatLayoutModel?> seatLayout = Rx<SeatLayoutModel?>(null);

  // 当前选择的区域
  final Rx<AreaLayoutModel?> currentArea = Rx<AreaLayoutModel?>(null);

  // 选中的座位
  final RxList<SeatLayoutItemModel> selectedSeats = <SeatLayoutItemModel>[].obs;

  // 所有座位状态（包含选择状态的最新副本）
  final RxList<SeatLayoutItemModel> allSeats = <SeatLayoutItemModel>[].obs;

  // 加载状态
  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;

  // SVG相关
  final RxBool isLoadingSvg = false.obs;
  final RxString svgData = ''.obs;

  // 拖动选择相关状态
  bool _isDragging = false;
  bool _isSelecting = false; // true = 选择模式，false = 取消选择模式
  final List<String> _dragSelectedSeats = [];
  Offset? _lastDragPosition;
  DateTime? _lastProcessTime;
  static const _processThreshold = Duration(milliseconds: 50); // 处理频率限制

  @override
  void onInit() {
    super.onInit();
    print('🚀 SeatDetailController初始化');
    _loadArgumentsAndData();
  }

  /// 从路由参数加载数据
  void _loadArgumentsAndData() {
    // 从Get.arguments获取传递的参数
    final arguments = Get.arguments;
    if (arguments != null && arguments is Map<String, dynamic>) {
      eventPda = arguments['eventPda'] as String?;
      ticketTypeName = arguments['ticketTypeName'] as String?;
      areaId = arguments['areaId'] as String?;

      // Remove any 'event_' prefix from eventPda
      if (eventPda != null && eventPda!.startsWith('event_')) {
        eventPda = eventPda!.substring(6);
      }

      print('📝 接收到参数:');
      print('   - seatStatusMapPDA: $seatStatusMapPDA');
      print('   - eventPda: $eventPda');
      print('   - ticketTypeName: $ticketTypeName');
      print('   - areaId: $areaId');
    }

    // 从URL参数获取（兼容性支持）
    eventPda ??= Get.parameters['eventPda'];
    ticketTypeName ??= Get.parameters['ticketTypeName'];
    areaId ??= Get.parameters['areaId'];

    // Remove any 'event_' prefix from eventPda if it comes from URL parameters
    if (eventPda != null && eventPda!.startsWith('event_')) {
      eventPda = eventPda!.substring(6);
    }

    if (eventPda == null || ticketTypeName == null || areaId == null) {
      _setError('缺少必要参数：活动、票种或区域ID');
      return;
    }

    _loadAllData();
  }

  /// 加载所有相关数据
  Future<void> _loadAllData() async {
    try {
      isLoading.value = true;
      hasError.value = false;

      // 1. 从智能合约获取座位状态映射信息
      await _loadSeatStatusMapInfo();

      // 2. 加载活动信息
      if (eventPda != null) {
        await _loadEventInfo();
      }

      // 3. 加载票种信息
      if (eventPda != null && ticketTypeName != null) {
        await _loadTicketTypeInfo();
      }

      // 4. 加载场馆信息
      if (eventInfo.value?.venueAccount != null) {
        await _loadVenueInfo();
      }

      // 5. 加载座位布局数据
      await _loadSeatLayoutData();
    } catch (e) {
      print('❌ 加载数据失败: $e');
      _setError('加载数据失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 从智能合约获取座位状态映射信息
  Future<void> _loadSeatStatusMapInfo() async {
    try {
      print('🔍 获取座位状态映射信息: $seatStatusMapPDA');

      // 这里应该调用智能合约获取座位状态映射的详细信息
      // 包括 event, ticket_type, seat_layout_hash 等
      // 暂时跳过，使用传入的参数
    } catch (e) {
      print('❌ 获取座位状态映射信息失败: $e');
      throw Exception('获取座位状态映射信息失败: $e');
    }
  }

  /// 加载活动信息
  Future<void> _loadEventInfo() async {
    if (eventPda == null) return;

    try {
      print('🔍 加载活动信息: $eventPda');
      final event = await _contractService.getEventById(eventPda!);

      if (event != null) {
        eventInfo.value = event;
        print('✅ 成功加载活动信息: ${event.title}');
      } else {
        print('❌ 未找到活动信息');
      }
    } catch (e) {
      print('❌ 加载活动信息失败: $e');
    }
  }

  /// 加载票种信息
  Future<void> _loadTicketTypeInfo() async {
    if (eventPda == null || ticketTypeName == null) return;

    try {
      print('🔍 加载票种信息: $ticketTypeName');
      final ticketTypes = await _contractService.getEventTicketTypes(eventPda!);

      final targetTicketType = ticketTypes.firstWhereOrNull(
        (ticket) => ticket.typeName == ticketTypeName,
      );

      if (targetTicketType != null) {
        ticketTypeInfo.value = targetTicketType;
        print('✅ 成功加载票种信息: ${targetTicketType.typeName}');
      } else {
        print('❌ 未找到指定票种: $ticketTypeName');
      }
    } catch (e) {
      print('❌ 加载票种信息失败: $e');
    }
  }

  /// 加载场馆信息
  Future<void> _loadVenueInfo() async {
    final venueAccount = eventInfo.value?.venueAccount;
    if (venueAccount == null) return;

    try {
      print('🔍 加载场馆信息: $venueAccount');
      final venue = await _contractService.getVenueById(venueAccount);

      if (venue != null) {
        venueInfo.value = venue;
        print('✅ 成功加载场馆信息: ${venue.venueName}');

        // 加载场馆SVG平面图
        if (venue.floorPlanHash?.isNotEmpty == true) {
          await _loadVenueSvg(venue.floorPlanHash!);
        }
      } else {
        print('❌ 未找到场馆信息');
      }
    } catch (e) {
      print('❌ 加载场馆信息失败: $e');
    }
  }

  /// 加载场馆SVG平面图
  Future<void> _loadVenueSvg(String floorPlanHash) async {
    try {
      isLoadingSvg.value = true;
      print('🔍 加载场馆SVG: $floorPlanHash');

      final svg = await _arweaveService.getSvgDataEnhanced(floorPlanHash);
      if (svg != null) {
        svgData.value = svg;
        print('✅ 成功加载场馆SVG');
      } else {
        print('❌ 加载场馆SVG失败');
      }
    } catch (e) {
      print('❌ 加载场馆SVG失败: $e');
    } finally {
      isLoadingSvg.value = false;
    }
  }

  /// 加载座位布局数据
  Future<void> _loadSeatLayoutData() async {
    try {
      print('🔍 加载座位布局数据...');

      // 1. 生成票种PDA
      final ticketTypePDA = await _contractService.generateTicketTypePDA(
        eventPda!,
        ticketTypeName!,
      );
      print('🔍 生成票种PDA: $ticketTypePDA');

      // 2. 生成座位状态映射PDA
      final seatStatusMapPDA = await _contractService.generateSeatStatusMapPDA(
        eventPda!,
        ticketTypePDA,
        areaId!,
      );
      print('🔍 生成座位状态映射PDA: $seatStatusMapPDA');

      // 3. 获取座位状态映射信息
      final seatStatusMapData =
          await _contractService.getSeatStatusMapData(seatStatusMapPDA);
      if (seatStatusMapData == null) {
        throw Exception('无法获取座位状态映射数据');
      }

      print('✅ 成功获取座位状态映射数据:');
      print('  - 活动: ${seatStatusMapData.event}');
      print('  - 票种: ${seatStatusMapData.ticketType}');
      print('  - 座位布局哈希: ${seatStatusMapData.seatLayoutHash}');
      print('  - 座位索引映射哈希: ${seatStatusMapData.seatIndexMapHash}');
      print('  - 总座位数: ${seatStatusMapData.totalSeats}');
      print('  - 已售座位数: ${seatStatusMapData.soldSeats}');

      final seatLayoutHash = seatStatusMapData.seatLayoutHash;
      print('🔍 从Arweave获取座位布局: $seatLayoutHash');

      // 3. 从Arweave加载座位布局数据
      final layoutData = await _arweaveService.getJsonData(seatLayoutHash);
      if (layoutData != null) {
        print('✅ 成功从Arweave获取座位布局数据:');
        print('  - 数据结构: ${layoutData.keys.join(', ')}');

        final layout = SeatLayoutModel.fromJson(layoutData);
        print('  - 场馆: ${layout.venue}');
        print('  - 总座位数: ${layout.totalSeats}');
        print('  - 区域数量: ${layout.areas.length}');
        seatLayout.value = layout;

        // 4. 找到指定区域
        if (areaId != null) {
          print('🔍 查找指定区域: $areaId');
          // 首先尝试直接匹配
          var area = layout.areas.firstWhereOrNull(
            (area) => area.areaId == areaId,
          );

          // 如果找不到，尝试在票种-区域映射中查找
          if (area == null && eventInfo.value != null) {
            final mapping =
                eventInfo.value!.ticketAreaMappings.firstWhereOrNull(
              (mapping) {
                final parts = mapping.split('-');
                return parts.length >= 2 &&
                    parts[0].trim() == ticketTypeName &&
                    parts.sublist(1).join('-').trim() == areaId;
              },
            );

            if (mapping != null) {
              // 找到匹配的映射，现在尝试用区域ID查找
              final searchAreaId = areaId ?? '';
              area = layout.areas.firstWhereOrNull(
                (area) =>
                    area.areaId == searchAreaId ||
                    area.areaName.contains(searchAreaId),
              );
            }
          }

          if (area != null) {
            print('✅ 找到指定区域:');
            print('  - 区域ID: ${area.areaId}');
            print('  - 区域名称: ${area.areaName}');
            print('  - 座位数量: ${area.seats.length}');
            currentArea.value = area;

            // 5. 获取区域座位状态
            print('🔍 加载区域座位状态...');
            final seats =
                await _loadAreaSeatStatus(area.seats, seatStatusMapPDA);
            print('✅ 成功加载座位状态:');
            print('  - 总座位数: ${seats.length}');
            print(
                '  - 可选座位: ${seats.where((s) => s.status == SeatLayoutStatus.available).length}');
            print(
                '  - 已售座位: ${seats.where((s) => s.status == SeatLayoutStatus.occupied).length}');
            allSeats.value = seats;
            print('✅ 成功加载区域座位: ${area.areaName} (${seats.length}个座位)');
          } else {
            print('❌ 未找到指定区域: $areaId');
            print(
                '  可用区域: ${layout.areas.map((a) => "${a.areaId} (${a.areaName})").join(', ')}');
            if (eventInfo.value != null) {
              print(
                  '  票种-区域映射: ${eventInfo.value!.ticketAreaMappings.join(', ')}');
            }
            _setError('未找到区域"$areaId"。请检查区域ID是否正确，或联系活动主办方。');
          }
        } else {
          // 如果没有指定区域，使用第一个区域
          if (layout.areas.isNotEmpty) {
            final firstArea = layout.areas.first;
            print('ℹ️ 未指定区域，使用第一个区域:');
            print('  - 区域ID: ${firstArea.areaId}');
            print('  - 区域名称: ${firstArea.areaName}');
            currentArea.value = firstArea;
            final seats =
                await _loadAreaSeatStatus(firstArea.seats, seatStatusMapPDA);
            allSeats.value = seats;
            print('✅ 使用第一个区域: ${firstArea.areaName}');
          } else {
            print('❌ 座位布局中没有区域数据');
            _setError('座位布局中没有区域数据');
          }
        }
      } else {
        print('❌ 从Arweave加载座位布局失败');
        throw Exception('无法从Arweave加载座位布局数据');
      }
    } catch (e) {
      print('❌ 加载座位布局数据失败: $e');
      print('错误堆栈: ${StackTrace.current}');
      _setError('加载座位布局数据失败: $e');
    }
  }

  /// 加载区域座位状态
  Future<List<SeatLayoutItemModel>> _loadAreaSeatStatus(
      List<SeatLayoutItemModel> seats, String seatStatusMapPDA) async {
    try {
      print('🔍 开始加载区域座位状态...');
      print('  - 原始座位数量: ${seats.length}');
      print('  - 使用PDA: $seatStatusMapPDA');

      // 从智能合约获取座位状态
      print('🔍 从合约获取座位状态数据: $seatStatusMapPDA');
      final seatStatusData =
          await _contractService.getSeatStatusData(seatStatusMapPDA);

      if (seatStatusData == null) {
        print('⚠️ 未能获取座位状态数据，返回原始座位状态');
        return seats;
      }

      print('✅ 成功获取座位状态数据:');
      print('  - 布局哈希: ${seatStatusData.seatLayoutHash}');
      print('  - 索引映射哈希: ${seatStatusData.seatIndexMapHash}');
      print('  - 总座位数: ${seatStatusData.totalSeats}');
      print('  - 已售座位数: ${seatStatusData.soldSeats}');

      // 更新每个座位的状态
      final updatedSeats = seats.map((seat) {
        final status = seatStatusData.getStatusForSeat(seat.seatNumber);
        if (status != seat.status) {
          print('  更新座位 ${seat.seatNumber} 状态: ${seat.status} -> $status');
        }
        return seat.copyWith(status: status);
      }).toList();

      // 统计状态
      final statusCounts = <SeatLayoutStatus, int>{};
      for (final seat in updatedSeats) {
        statusCounts[seat.status] = (statusCounts[seat.status] ?? 0) + 1;
      }

      print('✅ 座位状态统计:');
      for (final entry in statusCounts.entries) {
        print('  - ${entry.key.displayName}: ${entry.value}');
      }

      return updatedSeats;
    } catch (e) {
      print('❌ 加载座位状态失败: $e');
      print('错误堆栈: ${StackTrace.current}');
      return seats; // 发生错误时返回原始座位状态
    }
  }

  /// 开始拖动选择
  void startSeatSelection(Offset position) {
    print('🎯 开始选择座位: $position');
    _isDragging = true;
    _lastDragPosition = position;
    _lastProcessTime = null;

    // 检查起始位置的座位状态来决定是选择还是取消选择模式
    final seat = _findSeatAtPosition(position);
    if (seat != null) {
      // 如果点击的是已选中的座位，则进入取消选择模式
      // 如果点击的是可选座位，则进入选择模式
      _isSelecting = seat.status == SeatLayoutStatus.available;
      print('🔄 选择模式: ${_isSelecting ? "选择" : "取消选择"}');
      _dragSelectedSeats.clear();
      _processSeatAtPosition(position);
    }
  }

  /// 更新拖动选择
  void updateSeatSelection(Offset position) {
    if (!_isDragging) return;

    // 检查处理频率
    final now = DateTime.now();
    if (_lastProcessTime != null) {
      final timeDiff = now.difference(_lastProcessTime!);
      if (timeDiff < _processThreshold) {
        return; // 跳过过于频繁的更新
      }
    }
    _lastProcessTime = now;

    // 计算拖动方向和距离
    if (_lastDragPosition != null) {
      final dx = position.dx - _lastDragPosition!.dx;
      final dy = position.dy - _lastDragPosition!.dy;

      // 如果拖动距离太小，跳过处理
      if (dx.abs() < 2 && dy.abs() < 2) {
        return;
      }

      // 处理拖动路径上的所有座位
      _processSeatsInPath(_lastDragPosition!, position);
    }

    _lastDragPosition = position;
    print('🔄 更新选择位置: $position');
  }

  /// 处理拖动路径上的所有座位
  void _processSeatsInPath(Offset start, Offset end) {
    // 计算路径上的点
    final points = _getPointsOnPath(start, end);

    // 处理每个点对应的座位
    for (final point in points) {
      _processSeatAtPosition(point);
    }
  }

  /// 获取两点之间路径上的所有点
  List<Offset> _getPointsOnPath(Offset start, Offset end) {
    final points = <Offset>[];

    // 使用Bresenham算法计算路径上的点
    int x0 = start.dx.round();
    int y0 = start.dy.round();
    int x1 = end.dx.round();
    int y1 = end.dy.round();

    final dx = (x1 - x0).abs();
    final dy = (y1 - y0).abs();
    final sx = x0 < x1 ? 1 : -1;
    final sy = y0 < y1 ? 1 : -1;
    var err = dx - dy;

    while (true) {
      points.add(Offset(x0.toDouble(), y0.toDouble()));

      if (x0 == x1 && y0 == y1) break;

      final e2 = 2 * err;
      if (e2 > -dy) {
        err -= dy;
        x0 += sx;
      }
      if (e2 < dx) {
        err += dx;
        y0 += sy;
      }
    }

    return points;
  }

  /// 结束拖动选择
  void endSeatSelection() {
    print('✅ 结束选择');
    _isDragging = false;
    _dragSelectedSeats.clear();
    _lastDragPosition = null;
    _lastProcessTime = null;
  }

  /// 处理指定位置的座位
  void _processSeatAtPosition(Offset position) {
    final seat = _findSeatAtPosition(position);
    if (seat == null) return;

    // 如果这个座位已经在本次拖动中处理过，跳过
    if (_dragSelectedSeats.contains(seat.seatNumber)) return;

    print('🎯 处理座位: ${seat.seatNumber} (${seat.status})');

    // 只处理可选择或已选择的座位
    if (seat.status != SeatLayoutStatus.available &&
        seat.status != SeatLayoutStatus.selected) {
      print('⚠️ 座位不可选: ${seat.seatNumber} (${seat.status})');
      return;
    }

    // 检查座位状态是否与当前模式匹配
    if (_isSelecting && seat.status != SeatLayoutStatus.available) {
      print('⚠️ 选择模式下跳过非可选座位: ${seat.seatNumber}');
      return;
    }
    if (!_isSelecting && seat.status != SeatLayoutStatus.selected) {
      print('⚠️ 取消模式下跳过非已选座位: ${seat.seatNumber}');
      return;
    }

    _dragSelectedSeats.add(seat.seatNumber);

    if (_isSelecting) {
      print('✅ 选择座位: ${seat.seatNumber}');
      _selectSeat(seat);
    } else {
      print('❌ 取消选择: ${seat.seatNumber}');
      _unselectSeat(seat);
    }
  }

  /// 查找指定位置的座位
  SeatLayoutItemModel? _findSeatAtPosition(Offset position) {
    try {
      // 计算座位的大小（包括间距）
      const seatSize = 36.0;
      const spacing = 4.0;
      const totalSize = seatSize + spacing;
      const padding = 16.0; // 考虑内边距

      // 调整位置，考虑内边距
      final adjustedX = position.dx - padding;
      final adjustedY = position.dy - padding;

      // 如果位置在边界外，返回null
      if (adjustedX < 0 || adjustedY < 0) return null;

      // 计算行和列
      final row = adjustedY ~/ totalSize;
      final col = adjustedX ~/ totalSize;

      // 计算每行的座位数
      final seatsPerRow = ((Get.width - 2 * padding) / totalSize).floor();

      // 计算在这个位置的座位索引
      final index = row * seatsPerRow + col;

      if (index >= 0 && index < allSeats.length) {
        final seat = allSeats[index];
        print('🔍 找到座位: ${seat.seatNumber} at ($row, $col)');
        return seat;
      }
    } catch (e) {
      print('❌ 查找座位时出错: $e');
    }
    return null;
  }

  /// 切换座位选择状态
  void toggleSeat(SeatLayoutItemModel seat) {
    if (!seat.status.isSelectable && seat.status != SeatLayoutStatus.selected) {
      Get.snackbar(
        'Notice',
        'This seat is ${seat.status.displayName.toLowerCase()}, cannot be selected',
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    final index = allSeats.indexWhere((s) => s.seatNumber == seat.seatNumber);
    if (index == -1) return;

    if (seat.status == SeatLayoutStatus.selected) {
      _unselectSeat(seat);
    } else {
      _selectSeat(seat);
    }
  }

  /// 选择座位
  void _selectSeat(SeatLayoutItemModel seat) {
    if (!seat.status.isSelectable) return;

    final index = allSeats.indexWhere((s) => s.seatNumber == seat.seatNumber);
    if (index == -1) return;

    allSeats[index] = seat.copyWithSelected();
    if (!selectedSeats.any((s) => s.seatNumber == seat.seatNumber)) {
      selectedSeats.add(allSeats[index]);
    }
    print('✅ Selected seat: ${seat.seatNumber}');
    _updateUI();
  }

  /// 取消选择座位
  void _unselectSeat(SeatLayoutItemModel seat) {
    final index = allSeats.indexWhere((s) => s.seatNumber == seat.seatNumber);
    if (index == -1) return;

    allSeats[index] = seat.copyWithAvailable();
    selectedSeats.removeWhere((s) => s.seatNumber == seat.seatNumber);
    print('🔄 Unselected seat: ${seat.seatNumber}');
    _updateUI();
  }

  /// 确认选择座位
  void confirmSeatSelection() {
    if (selectedSeats.isEmpty) {
      Get.snackbar('提示', '请先选择座位');
      return;
    }

    print('🎯 确认选择 ${selectedSeats.length} 个座位');

    // 跳转到订单摘要页面
    Get.toNamed(
      AppRoutes.getOrderSummaryRoute(),
      arguments: {
        'selectedSeats': selectedSeats.toList(),
        'ticketType': ticketTypeInfo.value,
        'event': eventInfo.value,
        'area': currentArea.value,
      },
    );
  }

  /// 返回上一页
  void goBack() {
    Get.back();
  }

  /// 设置错误状态
  void _setError(String message) {
    hasError.value = true;
    errorMessage.value = message;
    isLoading.value = false;
  }

  /// 更新UI
  void _updateUI() {
    update(['seat_layout', 'seat_count', 'bottom_button']);
  }

  /// 重新加载数据
  void retryLoad() {
    hasError.value = false;
    errorMessage.value = '';
    _loadAllData();
  }

  /// 取消选择所有已选座位
  void clearAllSelectedSeats() {
    // 遍历所有已选座位，将其状态改回可选状态
    for (final seat in selectedSeats) {
      final index = allSeats.indexWhere((s) => s.seatNumber == seat.seatNumber);
      if (index != -1) {
        allSeats[index] = seat.copyWithAvailable();
      }
    }
    // 清空已选座位列表
    selectedSeats.clear();
    print('🔄 取消选择所有座位');
    _updateUI();
  }

  /// 取消选择指定座位
  void unselectSeats(List<SeatLayoutItemModel> seats) {
    for (final seat in seats) {
      _unselectSeat(seat);
    }
    print('🔄 取消选择 ${seats.length} 个座位');
  }
}
