/// 座位布局模型 - 对应Arweave存储的数据结构
class SeatLayoutModel {
  final String venue;
  final int totalSeats;
  final List<AreaLayoutModel> areas;

  SeatLayoutModel({
    required this.venue,
    required this.totalSeats,
    required this.areas,
  });

  factory SeatLayoutModel.fromJson(Map<String, dynamic> json) {
    return SeatLayoutModel(
      venue: json['venue'] ?? '',
      totalSeats: json['totalSeats'] ?? 0,
      areas: (json['areas'] as List<dynamic>?)
              ?.map((area) => AreaLayoutModel.fromJson(area))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'venue': venue,
      'totalSeats': totalSeats,
      'areas': areas.map((area) => area.toJson()).toList(),
    };
  }
}

/// 区域布局模型
class AreaLayoutModel {
  final String areaId;
  final String areaName;
  final String areaColor;
  final String areaType;
  final String ticketTypeId;
  final List<CoordinatePoint> coordinates; // SVG坐标点数组
  final List<SeatLayoutItemModel> seats;

  AreaLayoutModel({
    required this.areaId,
    required this.areaName,
    required this.areaColor,
    required this.areaType,
    required this.ticketTypeId,
    required this.coordinates,
    required this.seats,
  });

  factory AreaLayoutModel.fromJson(Map<String, dynamic> json) {
    return AreaLayoutModel(
      areaId: json['areaId'] ?? '',
      areaName: json['areaName'] ?? '',
      areaColor: json['areaColor'] ?? '#000000',
      areaType: json['areaType'] ?? '',
      ticketTypeId: json['ticketTypeId'] ?? '',
      coordinates: (json['coordinates'] as List<dynamic>?)
              ?.map((coord) => CoordinatePoint.fromJson(coord))
              .toList() ??
          [],
      seats: (json['seats'] as List<dynamic>?)
              ?.map((seat) => SeatLayoutItemModel.fromJson(seat))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'areaId': areaId,
      'areaName': areaName,
      'areaColor': areaColor,
      'areaType': areaType,
      'ticketTypeId': ticketTypeId,
      'coordinates': coordinates.map((coord) => coord.toJson()).toList(),
      'seats': seats.map((seat) => seat.toJson()).toList(),
    };
  }
}

/// 坐标点模型
class CoordinatePoint {
  final double x;
  final double y;

  CoordinatePoint({
    required this.x,
    required this.y,
  });

  factory CoordinatePoint.fromJson(Map<String, dynamic> json) {
    return CoordinatePoint(
      x: (json['x'] ?? 0).toDouble(),
      y: (json['y'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
    };
  }
}

/// 座位布局项模型
class SeatLayoutItemModel {
  final String seatNumber;
  final CoordinatePoint coordinates; // 座位在SVG中的坐标
  final String? row;
  final String? number;
  final SeatLayoutStatus status;
  final String? seatType;
  final Map<String, dynamic> metadata;

  SeatLayoutItemModel({
    required this.seatNumber,
    required this.coordinates,
    this.row,
    this.number,
    this.status = SeatLayoutStatus.available,
    this.seatType,
    this.metadata = const {},
  });

  factory SeatLayoutItemModel.fromJson(Map<String, dynamic> json) {
    // 从不同的字段中提取行号信息
    String? rowNumber;
    if (json['rowNumber'] != null) {
      rowNumber = json['rowNumber'].toString();
    } else if (json['row'] != null) {
      rowNumber = json['row'].toString();
    }

    // 从不同的字段中提取座位号信息
    String? seatNumberInRow;
    if (json['seatNumberInRow'] != null) {
      seatNumberInRow = json['seatNumberInRow'].toString();
    } else if (json['number'] != null) {
      seatNumberInRow = json['number'].toString();
    }

    // 从 metadata 中提取状态信息
    String statusString = 'available';
    if (json['metadata'] != null && json['metadata']['status'] != null) {
      statusString = json['metadata']['status'].toString();
    } else if (json['status'] != null) {
      statusString = json['status'].toString();
    }

    return SeatLayoutItemModel(
      seatNumber: json['seatNumber'] ?? '',
      coordinates: CoordinatePoint.fromJson(json['coordinates'] ?? {}),
      row: rowNumber,
      number: seatNumberInRow,
      status: SeatLayoutStatus.values.firstWhere(
        (status) => status.toString().split('.').last == statusString,
        orElse: () => SeatLayoutStatus.available,
      ),
      seatType: json['seatType'] ??
                (json['metadata'] != null ? json['metadata']['seatType'] : null),
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seatNumber': seatNumber,
      'coordinates': coordinates.toJson(),
      'row': row,
      'number': number,
      'status': status.toString().split('.').last,
      'seatType': seatType,
      'metadata': metadata,
    };
  }

  /// 创建已选择状态的副本
  SeatLayoutItemModel copyWithSelected() {
    return copyWith(status: SeatLayoutStatus.selected);
  }

  /// 创建可用状态的副本
  SeatLayoutItemModel copyWithAvailable() {
    return copyWith(status: SeatLayoutStatus.available);
  }

  /// 创建新状态的副本
  SeatLayoutItemModel copyWith({
    String? seatNumber,
    CoordinatePoint? coordinates,
    String? row,
    String? number,
    SeatLayoutStatus? status,
    String? seatType,
    Map<String, dynamic>? metadata,
  }) {
    return SeatLayoutItemModel(
      seatNumber: seatNumber ?? this.seatNumber,
      coordinates: coordinates ?? this.coordinates,
      row: row ?? this.row,
      number: number ?? this.number,
      status: status ?? this.status,
      seatType: seatType ?? this.seatType,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// 座位布局状态枚举
enum SeatLayoutStatus {
  available, // 可选择
  selected, // 已选中
  occupied, // 已占用
  reserved, // 已预订
  locked, // 锁定中
  unavailable, // 不可用
}

/// 座位布局状态扩展
extension SeatLayoutStatusExtension on SeatLayoutStatus {
  String get displayName {
    switch (this) {
      case SeatLayoutStatus.available:
        return '可选择';
      case SeatLayoutStatus.selected:
        return '已选中';
      case SeatLayoutStatus.occupied:
        return '已占用';
      case SeatLayoutStatus.reserved:
        return '已预订';
      case SeatLayoutStatus.locked:
        return '锁定中';
      case SeatLayoutStatus.unavailable:
        return '不可用';
    }
  }

  bool get isSelectable {
    return this == SeatLayoutStatus.available;
  }
}
