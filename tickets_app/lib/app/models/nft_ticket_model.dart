import 'package:flutter/material.dart';

/// NFT 票券状态枚举
enum NFTTicketStatus { 
  valid,           // 有效
  redeemed,        // 已使用
  refunded,        // 已退款
  availableForResale, // 可转售
  expired,         // 已过期
  transferred      // 已转让
}

/// NFT 票券元数据模型
class NFTTicketMetadata {
  final String name;
  final String description;
  final String image;
  final String eventName;
  final String eventDate;
  final String eventTime;
  final String venue;
  final String seatInfo;
  final String ticketType;
  final Map<String, dynamic> attributes;
  final Map<String, dynamic> properties;

  const NFTTicketMetadata({
    required this.name,
    required this.description,
    required this.image,
    required this.eventName,
    required this.eventDate,
    required this.eventTime,
    required this.venue,
    required this.seatInfo,
    required this.ticketType,
    required this.attributes,
    required this.properties,
  });

  factory NFTTicketMetadata.fromJson(Map<String, dynamic> json) {
    return NFTTicketMetadata(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      image: json['image'] ?? '',
      eventName: json['event_name'] ?? json['eventName'] ?? '',
      eventDate: json['event_date'] ?? json['eventDate'] ?? '',
      eventTime: json['event_time'] ?? json['eventTime'] ?? '',
      venue: json['venue'] ?? '',
      seatInfo: json['seat_info'] ?? json['seatInfo'] ?? '',
      ticketType: json['ticket_type'] ?? json['ticketType'] ?? '',
      attributes: json['attributes'] ?? {},
      properties: json['properties'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'image': image,
      'event_name': eventName,
      'event_date': eventDate,
      'event_time': eventTime,
      'venue': venue,
      'seat_info': seatInfo,
      'ticket_type': ticketType,
      'attributes': attributes,
      'properties': properties,
    };
  }
}

/// NFT 票券模型
class NFTTicketModel {
  final String mintAddress;      // NFT 的 mint 地址
  final String tokenAccount;     // 用户的 token 账户地址
  final String owner;            // 所有者公钥
  final NFTTicketMetadata metadata; // NFT 元数据
  final NFTTicketStatus status;  // 票券状态
  final DateTime? purchaseDate;  // 购买日期
  final DateTime? usedDate;      // 使用日期
  final String? transactionHash; // 相关交易哈希
  final double? purchasePrice;   // 购买价格（SOL）
  final bool isTransferable;     // 是否可转让

  const NFTTicketModel({
    required this.mintAddress,
    required this.tokenAccount,
    required this.owner,
    required this.metadata,
    required this.status,
    this.purchaseDate,
    this.usedDate,
    this.transactionHash,
    this.purchasePrice,
    this.isTransferable = true,
  });

  /// 状态文本
  String get statusText {
    switch (status) {
      case NFTTicketStatus.valid:
        return 'Valid';
      case NFTTicketStatus.redeemed:
        return 'Redeemed';
      case NFTTicketStatus.refunded:
        return 'Refunded';
      case NFTTicketStatus.availableForResale:
        return 'Available for Resale';
      case NFTTicketStatus.expired:
        return 'Expired';
      case NFTTicketStatus.transferred:
        return 'Transferred';
    }
  }

  /// 状态颜色
  Color get statusColor {
    switch (status) {
      case NFTTicketStatus.valid:
        return const Color(0xFF4CAF50); // 绿色
      case NFTTicketStatus.redeemed:
        return const Color(0xFF9E9E9E); // 灰色
      case NFTTicketStatus.refunded:
        return const Color(0xFFF44336); // 红色
      case NFTTicketStatus.availableForResale:
        return const Color(0xFF2196F3); // 蓝色
      case NFTTicketStatus.expired:
        return const Color(0xFFFF9800); // 橙色
      case NFTTicketStatus.transferred:
        return const Color(0xFF9C27B0); // 紫色
    }
  }

  /// 完整的日期时间地点信息
  String get fullDateTimeVenue => 
      '${metadata.eventDate} · ${metadata.eventTime} · ${metadata.venue} · ${metadata.seatInfo}';

  /// 简短的 mint 地址
  String get shortMintAddress => 
      '${mintAddress.substring(0, 4)}...${mintAddress.substring(mintAddress.length - 4)}';

  /// 是否已过期
  bool get isExpired {
    if (status == NFTTicketStatus.expired) return true;
    
    try {
      final eventDateTime = DateTime.parse('${metadata.eventDate} ${metadata.eventTime}');
      return DateTime.now().isAfter(eventDateTime);
    } catch (e) {
      return false;
    }
  }

  /// 是否可以使用
  bool get canBeUsed => status == NFTTicketStatus.valid && !isExpired;

  /// 是否可以转售
  bool get canBeResold => 
      isTransferable && 
      (status == NFTTicketStatus.valid || status == NFTTicketStatus.availableForResale) && 
      !isExpired;

  factory NFTTicketModel.fromJson(Map<String, dynamic> json) {
    return NFTTicketModel(
      mintAddress: json['mint_address'] ?? '',
      tokenAccount: json['token_account'] ?? '',
      owner: json['owner'] ?? '',
      metadata: NFTTicketMetadata.fromJson(json['metadata'] ?? {}),
      status: NFTTicketStatus.values.firstWhere(
        (s) => s.toString().split('.').last == (json['status'] ?? 'valid'),
        orElse: () => NFTTicketStatus.valid,
      ),
      purchaseDate: json['purchase_date'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['purchase_date'])
          : null,
      usedDate: json['used_date'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['used_date'])
          : null,
      transactionHash: json['transaction_hash'],
      purchasePrice: json['purchase_price']?.toDouble(),
      isTransferable: json['is_transferable'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mint_address': mintAddress,
      'token_account': tokenAccount,
      'owner': owner,
      'metadata': metadata.toJson(),
      'status': status.toString().split('.').last,
      'purchase_date': purchaseDate?.millisecondsSinceEpoch,
      'used_date': usedDate?.millisecondsSinceEpoch,
      'transaction_hash': transactionHash,
      'purchase_price': purchasePrice,
      'is_transferable': isTransferable,
    };
  }

  @override
  String toString() {
    return 'NFTTicketModel(mintAddress: $shortMintAddress, eventName: ${metadata.eventName}, status: $statusText)';
  }
}
