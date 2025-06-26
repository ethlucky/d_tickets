/// 座位状态映射模型
class SeatStatusMapModel {
  /// 所属活动
  final String event;

  /// 所属票种
  final String ticketType;

  /// 座位布局IPFS哈希
  final String seatLayoutHash;

  /// 座位索引映射IPFS哈希
  final String seatIndexMapHash;

  /// 总座位数量
  final int totalSeats;

  /// 已售座位数量
  final int soldSeats;

  /// 可用座位数量
  int get availableSeats => totalSeats - soldSeats;

  /// 售出比例（0.0 - 1.0）
  double get soldRatio => totalSeats > 0 ? soldSeats / totalSeats : 0.0;

  /// 是否有可用座位
  bool get hasAvailableSeats => availableSeats > 0;

  /// 是否售罄
  bool get isSoldOut => availableSeats == 0;

  SeatStatusMapModel({
    required this.event,
    required this.ticketType,
    required this.seatLayoutHash,
    required this.seatIndexMapHash,
    required this.totalSeats,
    required this.soldSeats,
  });

  /// 从Map创建模型
  factory SeatStatusMapModel.fromMap(Map<String, dynamic> map) {
    return SeatStatusMapModel(
      event: map['event'] ?? '',
      ticketType: map['ticketType'] ?? '',
      seatLayoutHash: map['seatLayoutHash'] ?? '',
      seatIndexMapHash: map['seatIndexMapHash'] ?? '',
      totalSeats: map['totalSeats'] ?? 0,
      soldSeats: map['soldSeats'] ?? 0,
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'event': event,
      'ticketType': ticketType,
      'seatLayoutHash': seatLayoutHash,
      'seatIndexMapHash': seatIndexMapHash,
      'totalSeats': totalSeats,
      'soldSeats': soldSeats,
    };
  }

  @override
  String toString() {
    return 'SeatStatusMapModel(event: $event, ticketType: $ticketType, totalSeats: $totalSeats, soldSeats: $soldSeats)';
  }
}
