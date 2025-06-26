import 'package:flutter/material.dart';

/// 活动数据模型
class EventModel {
  final String id;
  final String title;
  final String description;
  final String organizer;
  final String category;
  final String status;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime saleStartTime;
  final DateTime saleEndTime;
  final String posterImageHash;
  final String? seatMapHash;
  final String performerDetailsHash;
  final String contactInfoHash;
  final String refundPolicyHash;
  final String venueAccount;
  final int totalTicketsMinted;
  final int totalTicketsSold;
  final int totalTicketsRefunded;
  final int totalRevenue;
  final int ticketTypesCount;
  final List<String> ticketAreaMappings;
  final List<int> gradient;

  const EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.organizer,
    required this.category,
    required this.status,
    required this.startTime,
    required this.endTime,
    required this.saleStartTime,
    required this.saleEndTime,
    required this.posterImageHash,
    this.seatMapHash,
    required this.performerDetailsHash,
    required this.contactInfoHash,
    required this.refundPolicyHash,
    required this.venueAccount,
    required this.totalTicketsMinted,
    required this.totalTicketsSold,
    required this.totalTicketsRefunded,
    required this.totalRevenue,
    required this.ticketTypesCount,
    required this.ticketAreaMappings,
    required this.gradient,
  });

  /// 从JSON创建EventModel
  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      organizer: json['organizer'] ?? '',
      category: json['category'] ?? '',
      status: json['status'] ?? '',
      startTime: DateTime.fromMillisecondsSinceEpoch(json['startTime'] ?? 0),
      endTime: DateTime.fromMillisecondsSinceEpoch(json['endTime'] ?? 0),
      saleStartTime: DateTime.fromMillisecondsSinceEpoch(
        json['saleStartTime'] ?? 0,
      ),
      saleEndTime: DateTime.fromMillisecondsSinceEpoch(
        json['saleEndTime'] ?? 0,
      ),
      posterImageHash: json['posterImageHash'] ?? '',
      seatMapHash: json['seatMapHash'],
      performerDetailsHash: json['performerDetailsHash'] ?? '',
      contactInfoHash: json['contactInfoHash'] ?? '',
      refundPolicyHash: json['refundPolicyHash'] ?? '',
      venueAccount: json['venueAccount'] ?? '',
      totalTicketsMinted: json['totalTicketsMinted'] ?? 0,
      totalTicketsSold: json['totalTicketsSold'] ?? 0,
      totalTicketsRefunded: json['totalTicketsRefunded'] ?? 0,
      totalRevenue: json['totalRevenue'] ?? 0,
      ticketTypesCount: json['ticketTypesCount'] ?? 0,
      ticketAreaMappings: List<String>.from(json['ticketAreaMappings'] ?? []),
      gradient: List<int>.from(json['gradient'] ?? [0xFF6B7280, 0xFF4B5563]),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'organizer': organizer,
      'category': category,
      'status': status,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime.millisecondsSinceEpoch,
      'saleStartTime': saleStartTime.millisecondsSinceEpoch,
      'saleEndTime': saleEndTime.millisecondsSinceEpoch,
      'posterImageHash': posterImageHash,
      'seatMapHash': seatMapHash,
      'performerDetailsHash': performerDetailsHash,
      'contactInfoHash': contactInfoHash,
      'refundPolicyHash': refundPolicyHash,
      'venueAccount': venueAccount,
      'totalTicketsMinted': totalTicketsMinted,
      'totalTicketsSold': totalTicketsSold,
      'totalTicketsRefunded': totalTicketsRefunded,
      'totalRevenue': totalRevenue,
      'ticketTypesCount': ticketTypesCount,
      'ticketAreaMappings': ticketAreaMappings,
      'gradient': gradient,
    };
  }

  /// 获取渐变色对象
  List<Color> get gradientColors {
    return gradient.map((color) => Color(color)).toList();
  }

  /// 获取格式化的开始时间
  String get formattedStartTime {
    return '${startTime.year}年${startTime.month}月${startTime.day}日 ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}';
  }

  /// 获取格式化的结束时间
  String get formattedEndTime {
    return '${endTime.year}年${endTime.month}月${endTime.day}日 ${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}';
  }

  /// 获取活动时长（小时）
  int get durationInHours {
    return endTime.difference(startTime).inHours;
  }

  /// 判断活动是否正在进行
  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  /// 判断活动是否已结束
  bool get isCompleted {
    return DateTime.now().isAfter(endTime);
  }

  /// 判断票务销售是否开始
  bool get isSaleStarted {
    return DateTime.now().isAfter(saleStartTime);
  }

  /// 判断票务销售是否结束
  bool get isSaleEnded {
    return DateTime.now().isAfter(saleEndTime);
  }

  /// 获取售票状态文本
  String get saleStatusText {
    if (!isSaleStarted) {
      return '即将开售';
    } else if (isSaleEnded) {
      return '已停售';
    } else {
      return '正在售票';
    }
  }

  /// 计算销售完成度百分比
  double get salesProgress {
    if (totalTicketsMinted == 0) return 0.0;
    return totalTicketsSold / totalTicketsMinted;
  }

  /// 获取剩余票数
  int get availableTickets {
    return totalTicketsMinted - totalTicketsSold;
  }

  /// 获取完整的海报图片URL
  String get posterImageUrl {
    if (posterImageHash != null && posterImageHash!.isNotEmpty) {
      // 在本地开发环境中，使用arlocal的URL
      // 注意：这里需要根据你的arlocal配置来调整
      return 'http://10.0.2.2:1984/$posterImageHash';
    } else {
      // 如果没有海报，可以返回一个默认的占位图URL
      return 'https://via.placeholder.com/400x300.png?text=No+Image';
    }
  }

  /// 获取格式化的日期时间
  String get formattedDateTime {
    final weekday = _getWeekdayShort(startTime.weekday);
    final month = _getMonthShort(startTime.month);
    final day = startTime.day;
    final hour = startTime.hour > 12 ? startTime.hour - 12 : startTime.hour;
    final minute = startTime.minute.toString().padLeft(2, '0');
    final period = startTime.hour >= 12 ? 'PM' : 'AM';
    return '$weekday, $month $day · $hour:$minute $period';
  }

  /// 获取星期简称
  String _getWeekdayShort(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }

  /// 获取月份简称
  String _getMonthShort(int month) {
    switch (month) {
      case 1:
        return 'Jan';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'Apr';
      case 5:
        return 'May';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return 'Aug';
      case 9:
        return 'Sep';
      case 10:
        return 'Oct';
      case 11:
        return 'Nov';
      case 12:
        return 'Dec';
      default:
        return '';
    }
  }

  @override
  String toString() {
    return 'EventModel(id: $id, title: $title, category: $category, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// 创建副本
  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    String? organizer,
    String? category,
    String? status,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? saleStartTime,
    DateTime? saleEndTime,
    String? posterImageHash,
    String? seatMapHash,
    String? performerDetailsHash,
    String? contactInfoHash,
    String? refundPolicyHash,
    String? venueAccount,
    int? totalTicketsMinted,
    int? totalTicketsSold,
    int? totalTicketsRefunded,
    int? totalRevenue,
    int? ticketTypesCount,
    List<String>? ticketAreaMappings,
    List<int>? gradient,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      organizer: organizer ?? this.organizer,
      category: category ?? this.category,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      saleStartTime: saleStartTime ?? this.saleStartTime,
      saleEndTime: saleEndTime ?? this.saleEndTime,
      posterImageHash: posterImageHash ?? this.posterImageHash,
      seatMapHash: seatMapHash ?? this.seatMapHash,
      performerDetailsHash: performerDetailsHash ?? this.performerDetailsHash,
      contactInfoHash: contactInfoHash ?? this.contactInfoHash,
      refundPolicyHash: refundPolicyHash ?? this.refundPolicyHash,
      venueAccount: venueAccount ?? this.venueAccount,
      totalTicketsMinted: totalTicketsMinted ?? this.totalTicketsMinted,
      totalTicketsSold: totalTicketsSold ?? this.totalTicketsSold,
      totalTicketsRefunded: totalTicketsRefunded ?? this.totalTicketsRefunded,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      ticketTypesCount: ticketTypesCount ?? this.ticketTypesCount,
      ticketAreaMappings: ticketAreaMappings ?? this.ticketAreaMappings,
      gradient: gradient ?? this.gradient,
    );
  }
}
