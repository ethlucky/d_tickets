/// 票种数据模型
class TicketTypeModel {
  final String eventPda;
  final int ticketTypeId;
  final String typeName;
  final int initialPrice;
  final int currentPrice;
  final int totalSupply;
  final int soldCount;
  final String maxResaleRoyalty;
  final String dynamicPricingRulesHash;
  final bool isTransferable;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TicketTypeModel({
    required this.eventPda,
    required this.ticketTypeId,
    required this.typeName,
    required this.initialPrice,
    required this.currentPrice,
    required this.totalSupply,
    required this.soldCount,
    required this.maxResaleRoyalty,
    required this.dynamicPricingRulesHash,
    required this.isTransferable,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 获取格式化的价格（美元）
  String get formattedCurrentPrice {
    return '\$${(currentPrice / 1000000000).toStringAsFixed(2)}';
  }

  /// 获取格式化的初始价格（美元）
  String get formattedInitialPrice {
    return '\$${(initialPrice / 1000000000).toStringAsFixed(2)}';
  }

  /// 是否有库存
  bool get isAvailable {
    return soldCount < totalSupply;
  }

  /// 剩余数量
  int get remainingTickets {
    return totalSupply - soldCount;
  }

  /// 销售进度
  double get salesProgress {
    if (totalSupply == 0) return 0.0;
    return soldCount / totalSupply;
  }

  /// 从JSON创建TicketTypeModel
  factory TicketTypeModel.fromJson(Map<String, dynamic> json) {
    return TicketTypeModel(
      eventPda: json['event_pda'] ?? '',
      ticketTypeId: json['ticket_type_id'] ?? 0,
      typeName: json['type_name'] ?? '',
      initialPrice: json['initial_price'] ?? 0,
      currentPrice: json['current_price'] ?? 0,
      totalSupply: json['total_supply'] ?? 0,
      soldCount: json['sold_count'] ?? 0,
      maxResaleRoyalty: json['max_resale_royalty'] ?? '0',
      dynamicPricingRulesHash: json['dynamic_pricing_rules_hash'] ?? '',
      isTransferable: json['is_transferable'] ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updated_at'] ?? 0),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'event_pda': eventPda,
      'ticket_type_id': ticketTypeId,
      'type_name': typeName,
      'initial_price': initialPrice,
      'current_price': currentPrice,
      'total_supply': totalSupply,
      'sold_count': soldCount,
      'max_resale_royalty': maxResaleRoyalty,
      'dynamic_pricing_rules_hash': dynamicPricingRulesHash,
      'is_transferable': isTransferable,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  @override
  String toString() {
    return 'TicketTypeModel(typeName: $typeName, currentPrice: $currentPrice, soldCount: $soldCount/$totalSupply)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TicketTypeModel &&
        other.eventPda == eventPda &&
        other.ticketTypeId == ticketTypeId;
  }

  @override
  int get hashCode => Object.hash(eventPda, ticketTypeId);

  /// 创建副本
  TicketTypeModel copyWith({
    String? eventPda,
    int? ticketTypeId,
    String? typeName,
    int? initialPrice,
    int? currentPrice,
    int? totalSupply,
    int? soldCount,
    String? maxResaleRoyalty,
    String? dynamicPricingRulesHash,
    bool? isTransferable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TicketTypeModel(
      eventPda: eventPda ?? this.eventPda,
      ticketTypeId: ticketTypeId ?? this.ticketTypeId,
      typeName: typeName ?? this.typeName,
      initialPrice: initialPrice ?? this.initialPrice,
      currentPrice: currentPrice ?? this.currentPrice,
      totalSupply: totalSupply ?? this.totalSupply,
      soldCount: soldCount ?? this.soldCount,
      maxResaleRoyalty: maxResaleRoyalty ?? this.maxResaleRoyalty,
      dynamicPricingRulesHash:
          dynamicPricingRulesHash ?? this.dynamicPricingRulesHash,
      isTransferable: isTransferable ?? this.isTransferable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
