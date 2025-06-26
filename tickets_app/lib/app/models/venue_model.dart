/// 场馆模型
class VenueModel {
  final String id; // PDA地址
  final String creator; // 创建者地址
  final String venueName; // 场馆名称
  final String venueAddress; // 场馆地址
  final int totalCapacity; // 总容量
  final String venueDescription; // 场馆描述
  final String? floorPlanHash; // 平面图哈希
  final String? seatMapHash; // 座位图哈希
  final String venueType; // 场馆类型
  final String? facilitiesInfoHash; // 设施信息哈希
  final String contactInfo; // 联系信息
  final String venueStatus; // 场馆状态
  final DateTime createdAt; // 创建时间
  final DateTime updatedAt; // 更新时间

  VenueModel({
    required this.id,
    required this.creator,
    required this.venueName,
    required this.venueAddress,
    required this.totalCapacity,
    required this.venueDescription,
    this.floorPlanHash,
    this.seatMapHash,
    required this.venueType,
    this.facilitiesInfoHash,
    required this.contactInfo,
    required this.venueStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 从JSON创建VenueModel实例
  factory VenueModel.fromJson(Map<String, dynamic> json, String pdaAddress) {
    return VenueModel(
      id: pdaAddress,
      creator: json['creator'] ?? '',
      venueName: json['venue_name'] ?? '',
      venueAddress: json['venue_address'] ?? '',
      totalCapacity: json['total_capacity'] ?? 0,
      venueDescription: json['venue_description'] ?? '',
      floorPlanHash: json['floor_plan_hash'],
      seatMapHash: json['seat_map_hash'],
      venueType: json['venue_type'] ?? 'Other',
      facilitiesInfoHash: json['facilities_info_hash'],
      contactInfo: json['contact_info'] ?? '',
      venueStatus: json['venue_status'] ?? 'Unused',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json['created_at'] ?? 0) * 1000,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (json['updated_at'] ?? 0) * 1000,
      ),
    );
  }

  /// 获取格式化的场馆类型
  String get formattedVenueType {
    switch (venueType.toLowerCase()) {
      case 'indoor':
        return '室内场馆';
      case 'outdoor':
        return '室外场馆';
      case 'stadium':
        return '体育场';
      case 'theater':
        return '剧院';
      case 'concert':
        return '音乐厅';
      case 'convention':
        return '会议中心';
      case 'exhibition':
        return '展览馆';
      default:
        return '其他';
    }
  }

  /// 获取格式化的场馆状态
  String get formattedVenueStatus {
    switch (venueStatus.toLowerCase()) {
      case 'unused':
        return '未使用';
      case 'active':
        return '活跃';
      case 'maintenance':
        return '维护中';
      case 'inactive':
        return '未激活';
      case 'temporarilyclosed':
        return '临时关闭';
      default:
        return venueStatus;
    }
  }

  /// 获取场馆完整地址信息
  String get fullLocationInfo {
    if (venueAddress.isNotEmpty) {
      return '$venueName - $venueAddress';
    }
    return venueName;
  }

  /// 创建副本
  VenueModel copyWith({
    String? id,
    String? creator,
    String? venueName,
    String? venueAddress,
    int? totalCapacity,
    String? venueDescription,
    String? floorPlanHash,
    String? seatMapHash,
    String? venueType,
    String? facilitiesInfoHash,
    String? contactInfo,
    String? venueStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VenueModel(
      id: id ?? this.id,
      creator: creator ?? this.creator,
      venueName: venueName ?? this.venueName,
      venueAddress: venueAddress ?? this.venueAddress,
      totalCapacity: totalCapacity ?? this.totalCapacity,
      venueDescription: venueDescription ?? this.venueDescription,
      floorPlanHash: floorPlanHash ?? this.floorPlanHash,
      seatMapHash: seatMapHash ?? this.seatMapHash,
      venueType: venueType ?? this.venueType,
      facilitiesInfoHash: facilitiesInfoHash ?? this.facilitiesInfoHash,
      contactInfo: contactInfo ?? this.contactInfo,
      venueStatus: venueStatus ?? this.venueStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
