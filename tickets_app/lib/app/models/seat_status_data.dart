import 'package:flutter/material.dart';
import 'seat_layout_model.dart';

/// 座位状态数据模型
class SeatStatusData {
  /// 座位状态映射PDA
  final String seatStatusMapPda;

  /// 座位布局哈希
  final String seatLayoutHash;

  /// 座位索引映射哈希
  final String seatIndexMapHash;

  /// 总座位数
  final int totalSeats;

  /// 已售座位数
  final int soldSeats;

  /// 座位状态映射
  final Map<String, dynamic> seatStatusMap;

  /// 座位状态位图（从合约获取的原始字节数据）
  /// 注意：这是区域级别的位图，仅包含当前区域内的座位状态
  /// 每个区域都有自己独立的位图，不是全场馆的位图
  final List<int>? seatStatusBitmap;

  /// 座位索引映射（座位号 -> 区域内索引）
  /// 注意：索引是区域内的相对索引，从0开始
  /// 例如：VIP区-A-001 -> 0, VIP区-A-002 -> 1
  final Map<String, int>? seatIndexMap;

  SeatStatusData({
    required this.seatStatusMapPda,
    required this.seatLayoutHash,
    required this.seatIndexMapHash,
    required this.totalSeats,
    required this.soldSeats,
    required this.seatStatusMap,
    this.seatStatusBitmap,
    this.seatIndexMap,
  });

  /// 获取指定座位的状态
  SeatLayoutStatus getStatusForSeat(String seatNumber) {
    // 优先使用位图数据（如果可用）
    if (seatStatusBitmap != null && seatIndexMap != null) {
      final seatIndex = seatIndexMap![seatNumber];
      if (seatIndex != null) {
        return _getSeatStatusFromBitmap(seatIndex);
      }
    }

    // 回退到传统的状态映射
    final status = seatStatusMap[seatNumber];
    if (status == null) return SeatLayoutStatus.available;

    switch (status.toString().toLowerCase()) {
      case 'sold':
      case 'occupied':
        return SeatLayoutStatus.occupied;
      case 'reserved':
        return SeatLayoutStatus.reserved;
      case 'templocked':
      case 'locked':
        return SeatLayoutStatus.locked;
      case 'unavailable':
        return SeatLayoutStatus.unavailable;
      default:
        return SeatLayoutStatus.available;
    }
  }

  /// 从位图中获取座位状态
  SeatLayoutStatus _getSeatStatusFromBitmap(int seatIndex) {
    if (seatStatusBitmap == null || seatIndex >= totalSeats) {
      return SeatLayoutStatus.available;
    }

    try {
      // 计算字节索引和位索引
      final byteIndex = seatIndex ~/ 4; // 整数除法
      final bitIndex = (seatIndex % 4) * 2; // 每个座位占2位

      if (byteIndex >= seatStatusBitmap!.length) {
        return SeatLayoutStatus.available;
      }

      // 获取状态字节
      final statusByte = seatStatusBitmap![byteIndex];

      // 提取2位状态
      final statusBits = (statusByte >> bitIndex) & 0x03;

      // 根据合约逻辑映射状态
      switch (statusBits) {
        case 0:
          return SeatLayoutStatus.available; // Available
        case 1:
          return SeatLayoutStatus.occupied;   // Sold
        case 2:
          return SeatLayoutStatus.locked;     // TempLocked
        case 3:
          return SeatLayoutStatus.unavailable; // Unavailable
        default:
          return SeatLayoutStatus.available;
      }
    } catch (e) {
      print('❌ 解析位图状态失败: seatIndex=$seatIndex, error=$e');
      return SeatLayoutStatus.available;
    }
  }

  /// 获取位图中所有座位的状态统计
  Map<SeatLayoutStatus, int> getBitmapStatusCounts() {
    final counts = <SeatLayoutStatus, int>{
      SeatLayoutStatus.available: 0,
      SeatLayoutStatus.occupied: 0,
      SeatLayoutStatus.locked: 0,
      SeatLayoutStatus.unavailable: 0,
    };

    if (seatStatusBitmap == null) {
      counts[SeatLayoutStatus.available] = totalSeats;
      return counts;
    }

    for (int seatIndex = 0; seatIndex < totalSeats; seatIndex++) {
      final status = _getSeatStatusFromBitmap(seatIndex);
      counts[status] = (counts[status] ?? 0) + 1;
    }

    return counts;
  }

  /// 可用座位数
  int get availableSeats => totalSeats - soldSeats;

  /// 是否有可用座位
  bool get hasAvailableSeats => availableSeats > 0;

  /// 是否售罄
  bool get isSoldOut => availableSeats == 0;

  /// 售出比例（0.0 - 1.0）
  double get soldRatio => totalSeats > 0 ? soldSeats / totalSeats : 0.0;
}
