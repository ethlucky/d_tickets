import 'package:get/get.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

import 'package:bs58/bs58.dart';
import '../models/event_model.dart';
import '../models/ticket_type_model.dart';
import '../models/venue_model.dart';
import '../models/seat_status_map_model.dart';
import '../models/seat_status_data.dart';
import 'solana_service.dart';
import 'arweave_service.dart';
import 'mobile_wallet_service.dart';

/// 平台信息模型
class PlatformInfo {
  final int platformFeeBps; // 平台费率（基点）
  final String? feeRecipient; // 费用接收者地址
  final bool isPaused; // 是否暂停

  PlatformInfo({
    required this.platformFeeBps,
    this.feeRecipient,
    required this.isPaused,
  });
}

/// 智能合约服务类 - 处理与 d_tickets 合约的交互
class ContractService extends GetxService {
  final SolanaService _solanaService = Get.find<SolanaService>();
  final ArweaveService _arweaveService = Get.find<ArweaveService>();

  // 合约程序ID（从IDL中获取）
  static const String programIdString =
      '4RmJgJPUEkBJu8etoeMSt6B62RGvMR7iviNQEyHThJHG';

  // EventAccount判别器（从IDL中获取）
  static const List<int> eventAccountDiscriminator = [
    98,
    136,
    32,
    165,
    133,
    231,
    243,
    154,
  ];

  // TicketTypeAccount判别器（从IDL中获取）
  static const List<int> ticketTypeAccountDiscriminator = [
    213,
    215,
    241,
    242,
    198,
    103,
    146,
    87,
  ];

  // VenueAccount判别器（从IDL中获取）
  static const List<int> venueAccountDiscriminator = [
    121,
    51,
    148,
    147,
    208,
    230,
    202,
    176,
  ];

  @override
  Future<void> onInit() async {
    super.onInit();
    await _loadIdl();
  }

  /// 获取程序ID
  String getProgramId() {
    return programIdString;
  }

  /// 加载IDL文件
  Future<void> _loadIdl() async {
    try {
      final String idlString = await rootBundle.loadString(
        'lib/app/core/contracts/idl/d_tickets.json',
      );
      json.decode(idlString); // 验证IDL格式
      print('IDL文件加载成功');
    } catch (e) {
      print('加载IDL文件失败: $e');
    }
  }

  /// 查询所有活动数据
  Future<List<EventModel>> getAllEvents() async {
    try {
      // 首先尝试查询链上数据
      return await _fetchOnChainEvents();
    } catch (e) {
      print('查询链上活动数据失败: $e');
      // 链上查询失败，返回空列表
      return [];
    }
  }

  /// 解析EventAccount数据
  EventModel _parseEventAccountData(String pubkey, Uint8List data) {
    try {
      print('开始解析EventAccount数据，长度: ${data.length} bytes');

      // 跳过判别器（前8字节）
      if (data.length < 8) {
        throw Exception('数据长度不足，无法包含判别器');
      }

      // 验证判别器
      final discriminator = data.sublist(0, 8);
      bool isValidDiscriminator = true;
      for (int i = 0; i < 8; i++) {
        if (discriminator[i] != eventAccountDiscriminator[i]) {
          isValidDiscriminator = false;
          break;
        }
      }

      if (!isValidDiscriminator) {
        throw Exception('判别器不匹配，这不是一个EventAccount');
      }

      print('判别器验证通过');

      // 从第8字节开始解析EventAccount字段
      final buffer = ByteData.sublistView(data, 8);
      int offset = 0;

      // 解析 organizer (32字节 pubkey)
      final organizerBytes = data.sublist(8 + offset, 8 + offset + 32);
      final organizer = base64Encode(organizerBytes);
      offset += 32;
      print('解析到 organizer: $organizer');

      // 解析 event_name (4字节长度 + 字符串内容)
      final eventNameLength = buffer.getUint32(offset, Endian.little);
      offset += 4;
      final eventNameBytes = data.sublist(
        8 + offset,
        8 + offset + eventNameLength,
      );
      final eventName = utf8.decode(eventNameBytes);
      offset += eventNameLength;
      print('解析到 event_name: $eventName');

      // 解析 event_description_hash (4字节长度 + 字符串内容)
      final descHashLength = buffer.getUint32(offset, Endian.little);
      offset += 4;
      final descHashBytes = data.sublist(
        8 + offset,
        8 + offset + descHashLength,
      );
      final eventDescriptionHash = utf8.decode(descHashBytes);
      offset += descHashLength;
      print('解析到 event_description_hash: $eventDescriptionHash');

      // 解析 event_poster_image_hash (4字节长度 + 字符串内容)
      final posterHashLength = buffer.getUint32(offset, Endian.little);
      offset += 4;
      final posterHashBytes = data.sublist(
        8 + offset,
        8 + offset + posterHashLength,
      );
      final eventPosterImageHash = utf8.decode(posterHashBytes);
      offset += posterHashLength;
      print('解析到 event_poster_image_hash: $eventPosterImageHash');

      // 解析时间戳字段 (每个8字节 i64)
      final eventStartTime = buffer.getInt64(offset, Endian.little);
      offset += 8;
      final eventEndTime = buffer.getInt64(offset, Endian.little);
      offset += 8;
      final ticketSaleStartTime = buffer.getInt64(offset, Endian.little);
      offset += 8;
      final ticketSaleEndTime = buffer.getInt64(offset, Endian.little);
      offset += 8;

      print('解析到时间戳:');
      print('  event_start_time: $eventStartTime');
      print('  event_end_time: $eventEndTime');
      print('  ticket_sale_start_time: $ticketSaleStartTime');
      print('  ticket_sale_end_time: $ticketSaleEndTime');

      // 解析 venue_account (32字节 pubkey)
      final venueAccountBytes = data.sublist(8 + offset, 8 + offset + 32);
      final venueAccount = base64Encode(venueAccountBytes);
      offset += 32;
      print('解析到 venue_account: $venueAccount');

      // 解析 seat_map_hash (Option<String>: 1字节标志 + 可选字符串)
      final hasSeatMapHash = buffer.getUint8(offset) == 1;
      offset += 1;
      String? seatMapHash;
      if (hasSeatMapHash) {
        final seatMapHashLength = buffer.getUint32(offset, Endian.little);
        offset += 4;
        final seatMapHashBytes = data.sublist(
          8 + offset,
          8 + offset + seatMapHashLength,
        );
        seatMapHash = utf8.decode(seatMapHashBytes);
        offset += seatMapHashLength;
      }

      // 解析 event_category (4字节长度 + 字符串内容)
      final categoryLength = buffer.getUint32(offset, Endian.little);
      offset += 4;
      final categoryBytes = data.sublist(
        8 + offset,
        8 + offset + categoryLength,
      );
      final eventCategory = utf8.decode(categoryBytes);
      offset += categoryLength;
      print('解析到 event_category: $eventCategory');

      // 解析其他哈希字段
      final performerHashLength = buffer.getUint32(offset, Endian.little);
      offset += 4;
      final performerHashBytes = data.sublist(
        8 + offset,
        8 + offset + performerHashLength,
      );
      final performerDetailsHash = utf8.decode(performerHashBytes);
      offset += performerHashLength;

      final contactHashLength = buffer.getUint32(offset, Endian.little);
      offset += 4;
      final contactHashBytes = data.sublist(
        8 + offset,
        8 + offset + contactHashLength,
      );
      final contactInfoHash = utf8.decode(contactHashBytes);
      offset += contactHashLength;

      // 跳过 event_status 枚举 (1字节)
      final eventStatusIndex = buffer.getUint8(offset);
      offset += 1;
      final eventStatusNames = [
        'Upcoming',
        'OnSale',
        'SoldOut',
        'Cancelled',
        'Postponed',
        'Completed',
      ];
      final eventStatus = eventStatusIndex < eventStatusNames.length
          ? eventStatusNames[eventStatusIndex].toLowerCase()
          : 'upcoming';

      // 解析 refund_policy_hash
      final refundHashLength = buffer.getUint32(offset, Endian.little);
      offset += 4;
      final refundHashBytes = data.sublist(
        8 + offset,
        8 + offset + refundHashLength,
      );
      final refundPolicyHash = utf8.decode(refundHashBytes);
      offset += refundHashLength;

      // 跳过 pricing_strategy_type 枚举 (1字节)
      offset += 1;

      // 解析数值字段
      final totalTicketsMinted = buffer.getUint32(offset, Endian.little);
      offset += 4;
      final totalTicketsSold = buffer.getUint32(offset, Endian.little);
      offset += 4;
      final totalTicketsRefunded = buffer.getUint32(offset, Endian.little);
      offset += 4;

      // 跳过 total_tickets_resale_available (4字节)
      offset += 4;

      // 解析 total_revenue (8字节 u64)
      final totalRevenue = buffer.getUint64(offset, Endian.little);
      offset += 8;

      // 解析 ticket_types_count (1字节 u8)
      final ticketTypesCount = buffer.getUint8(offset);
      offset += 1;

      // 解析 ticket_area_mappings (Vec<String>: 4字节长度 + 每个字符串的[4字节长度+内容])
      final ticketAreaMappingsLength = buffer.getUint32(offset, Endian.little);
      offset += 4;
      final List<String> ticketAreaMappings = [];

      for (int i = 0; i < ticketAreaMappingsLength; i++) {
        final mappingLength = buffer.getUint32(offset, Endian.little);
        offset += 4;
        final mappingBytes = data.sublist(
          8 + offset,
          8 + offset + mappingLength,
        );
        final mapping = utf8.decode(mappingBytes);
        ticketAreaMappings.add(mapping);
        offset += mappingLength;
      }

      print('解析到统计数据:');
      print('  total_tickets_minted: $totalTicketsMinted');
      print('  total_tickets_sold: $totalTicketsSold');
      print('  total_tickets_refunded: $totalTicketsRefunded');
      print('  total_revenue: $totalRevenue lamports');
      print('  ticket_types_count: $ticketTypesCount');
      print('  ticket_area_mappings: $ticketAreaMappings');

      // 创建EventModel，使用真实的链上数据
      final event = EventModel(
        id: pubkey,
        title: eventName,
        description: 'IPFS: $eventDescriptionHash', // 显示IPFS哈希，实际应用中需要从IPFS获取内容
        category: eventCategory,
        organizer: 'Pubkey: ${organizer.substring(0, 8)}...', // 显示简化的公钥
        startTime: DateTime.fromMillisecondsSinceEpoch(eventStartTime * 1000),
        endTime: DateTime.fromMillisecondsSinceEpoch(eventEndTime * 1000),
        saleStartTime: DateTime.fromMillisecondsSinceEpoch(
          ticketSaleStartTime * 1000,
        ),
        saleEndTime: DateTime.fromMillisecondsSinceEpoch(
          ticketSaleEndTime * 1000,
        ),
        status: eventStatus,
        posterImageHash: eventPosterImageHash,
        seatMapHash: seatMapHash,
        performerDetailsHash: performerDetailsHash,
        contactInfoHash: contactInfoHash,
        refundPolicyHash: refundPolicyHash,
        venueAccount: venueAccount,
        totalTicketsMinted: totalTicketsMinted,
        totalTicketsSold: totalTicketsSold,
        totalTicketsRefunded: totalTicketsRefunded,
        totalRevenue: totalRevenue,
        ticketTypesCount: ticketTypesCount,
        ticketAreaMappings: ticketAreaMappings,
        gradient: [0xFF6B7280, 0xFF4B5563], // 默认渐变色
      );

      print('✅ 成功解析EventAccount: ${event.title}');
      return event;
    } catch (e) {
      print('❌ 解析EventAccount数据失败: $e');
      // 如果解析失败，返回一个带有基础信息的EventModel
      final now = DateTime.now();
      return EventModel(
        id: pubkey,
        title: '解析失败的活动',
        description: '链上数据解析出错: $e',
        category: 'Unknown',
        organizer: '未知主办方',
        startTime: now,
        endTime: now.add(Duration(hours: 3)),
        saleStartTime: now,
        saleEndTime: now.add(Duration(hours: 1)),
        status: 'error',
        posterImageHash: 'parse_error',
        performerDetailsHash: 'parse_error',
        contactInfoHash: 'parse_error',
        refundPolicyHash: 'parse_error',
        venueAccount: 'parse_error',
        totalTicketsMinted: 0,
        totalTicketsSold: 0,
        totalTicketsRefunded: 0,
        totalRevenue: 0,
        ticketTypesCount: 0,
        ticketAreaMappings: [],
        gradient: [0xFFDC2626, 0xFFB91C1C], // 错误时使用红色渐变
      );
    }
  }

  /// 尝试从链上获取活动数据
  Future<List<EventModel>> _fetchOnChainEvents() async {
    try {
      print('开始查询链上活动数据...');
      print('程序ID: $programIdString');
      print('EventAccount判别器: $eventAccountDiscriminator');

      // 等待SolanaService初始化完成
      if (_solanaService.client == null) {
        print('等待Solana客户端初始化...');
        await _solanaService.initialize();
      }

      // 检查初始化后的连接状态
      if (_solanaService.client == null) {
        throw Exception('Solana客户端初始化失败');
      }

      // 客户端存在就认为连接成功，因为我们在SolanaService中已经测试了连接
      print('Solana客户端连接状态: ${_solanaService.isConnected}');

      print('Solana客户端已初始化，开始查询程序账户...');
      print('尝试查询程序账户: $programIdString');
      print('判别器: $eventAccountDiscriminator');

      // 调用getProgramAccounts查询所有EventAccount
      final client = _solanaService.client!;

      try {
        // 先测试基本的RPC连接
        final slot = await client.getSlot();
        print('RPC连接正常，当前区块高度: $slot');

        // 测试程序账户是否存在
        final programAccount = await client.getAccountInfo(programIdString);
        if (programAccount.value != null) {
          print('智能合约程序存在:');
          print('  程序ID: $programIdString');
          print('  所有者: ${programAccount.value!.owner}');
          print('  可执行: ${programAccount.value!.executable}');
          print('  余额: ${programAccount.value!.lamports} lamports');
        } else {
          print('警告: 智能合约程序不存在于当前网络');
        }

        // 现在实现真正的getProgramAccounts查询
        print('开始查询程序账户数据...');

        try {
          // 使用正确的API调用getProgramAccounts
          print('正在查询EventAccount数据...');

          // 构建过滤器：通过判别器筛选EventAccount
          final filters = [
            ProgramDataFilter.memcmp(
              offset: 0, // 判别器位于账户数据开头
              bytes: eventAccountDiscriminator,
            ),
          ];

          final programAccounts = await client.getProgramAccounts(
            programIdString,
            encoding: Encoding.base64,
            filters: filters,
          );

          print('找到 ${programAccounts.length} 个EventAccount');

          final List<EventModel> events = [];

          // 处理找到的账户
          for (int i = 0; i < programAccounts.length; i++) {
            final account = programAccounts[i];
            print('EventAccount $i: ${account.pubkey}');
            print('  Lamports: ${account.account.lamports}');
            print('  所有者: ${account.account.owner}');
            print('  数据: ${account.account.data != null ? "存在" : "无数据"}');

            // 解析真实的EventAccount数据
            if (account.account.data != null) {
              try {
                Uint8List decodedData;
                final accountData = account.account.data!;

                // 根据AccountData类型处理数据
                if (accountData is BinaryAccountData) {
                  // 如果是BinaryAccountData，直接使用data字段
                  decodedData = Uint8List.fromList(accountData.data);
                  print(
                    '使用BinaryAccountData，数据长度: ${decodedData.length} bytes',
                  );
                } else {
                  // 其他情况，从toJson()中获取base64数据
                  final jsonData = accountData.toJson();
                  if (jsonData is List &&
                      jsonData.length >= 2 &&
                      jsonData[1] == 'base64') {
                    decodedData = base64Decode(jsonData[0] as String);
                    print('从JSON解码base64，数据长度: ${decodedData.length} bytes');
                  } else {
                    print('警告: 未知的AccountData格式: ${accountData.runtimeType}');
                    continue;
                  }
                }

                // 解析EventAccount数据
                final event = _parseEventAccountData(
                  account.pubkey,
                  decodedData,
                );
                events.add(event);
              } catch (e) {
                print('解析账户 ${account.pubkey} 数据失败: $e');
                // 继续处理下一个账户
              }
            }
          }

          print('成功解析 ${events.length} 个活动');
          return events;
        } catch (e) {
          print('getProgramAccounts查询失败: $e');
          return [];
        }
      } catch (e) {
        print('链上查询过程出错: $e');
        throw e;
      }
    } catch (e) {
      print('链上查询失败: $e');
      throw Exception('链上查询失败: $e');
    }
  }

  /// 根据分类查询活动
  Future<List<EventModel>> getEventsByCategory(String category) async {
    final allEvents = await getAllEvents();
    if (category.toLowerCase() == 'all') {
      return allEvents;
    }
    return allEvents
        .where(
          (event) => event.category.toLowerCase() == category.toLowerCase(),
        )
        .toList();
  }

  /// 根据活动状态查询活动
  Future<List<EventModel>> getEventsByStatus(String status) async {
    final allEvents = await getAllEvents();
    return allEvents
        .where((event) => event.status.toLowerCase() == status.toLowerCase())
        .toList();
  }

  /// 搜索活动
  Future<List<EventModel>> searchEvents(String query) async {
    final allEvents = await getAllEvents();
    if (query.isEmpty) return allEvents;

    final searchQuery = query.toLowerCase();
    return allEvents.where((event) {
      return event.title.toLowerCase().contains(searchQuery) ||
          event.category.toLowerCase().contains(searchQuery) ||
          event.description.toLowerCase().contains(searchQuery);
    }).toList();
  }

  /// 获取活动详情
  Future<EventModel?> getEventById(String eventId) async {
    final allEvents = await getAllEvents();
    try {
      // 尝试直接匹配
      try {
        return allEvents.firstWhere((event) => event.id == eventId);
      } catch (e) {
        // 如果直接匹配失败，尝试移除"event_"前缀
        final cleanEventId =
            eventId.startsWith('event_') ? eventId.substring(6) : eventId;
        print('直接匹配失败，尝试使用清理后的eventId: $cleanEventId');
        return allEvents.firstWhere((event) => event.id == cleanEventId);
      }
    } catch (e) {
      print('❌ 未找到匹配的活动，eventId: $eventId');
      print('可用的活动列表:');
      for (final event in allEvents) {
        print('  - ${event.id}: ${event.title}');
      }
      return null;
    }
  }

  /// 检查合约连接状态
  bool get isConnected => _solanaService.isConnected;

  /// 获取程序ID
  String get contractProgramId => programIdString;

  /// 获取活动的所有票种
  Future<List<TicketTypeModel>> getEventTicketTypes(String eventPda) async {
    try {
      print('开始查询活动票种数据: $eventPda');

      // 等待SolanaService初始化完成
      if (_solanaService.client == null) {
        print('等待Solana客户端初始化...');
        await _solanaService.initialize();
      }

      if (_solanaService.client == null) {
        throw Exception('Solana客户端初始化失败');
      }

      final client = _solanaService.client!;

      // 暂时只使用判别器过滤TicketTypeAccount
      // TODO: 后续可以添加Base58解码来进一步过滤
      final filters = [
        ProgramDataFilter.memcmp(
          offset: 0, // 判别器位于账户数据开头
          bytes: ticketTypeAccountDiscriminator,
        ),
      ];

      final programAccounts = await client.getProgramAccounts(
        programIdString,
        encoding: Encoding.base64,
        filters: filters,
      );

      print('找到 ${programAccounts.length} 个TicketTypeAccount');

      final List<TicketTypeModel> ticketTypes = [];

      for (int i = 0; i < programAccounts.length; i++) {
        final account = programAccounts[i];
        print('TicketTypeAccount $i: ${account.pubkey}');

        if (account.account.data != null) {
          try {
            Uint8List decodedData;
            final accountData = account.account.data!;

            if (accountData is BinaryAccountData) {
              decodedData = Uint8List.fromList(accountData.data);
            } else {
              final jsonData = accountData.toJson();
              if (jsonData is List &&
                  jsonData.length >= 2 &&
                  jsonData[1] == 'base64') {
                decodedData = base64Decode(jsonData[0] as String);
              } else {
                print('警告: 未知的AccountData格式: ${accountData.runtimeType}');
                continue;
              }
            }

            // 解析TicketTypeAccount数据
            final ticketType = _parseTicketTypeAccountData(
              account.pubkey,
              eventPda,
              decodedData,
            );

            // 检查票种是否属于指定活动
            // 需要处理不同格式的eventPda比较
            bool belongsToEvent = false;

            // 直接比较
            if (ticketType.eventPda == eventPda) {
              belongsToEvent = true;
            } else {
              // 尝试转换格式比较
              try {
                // 如果ticketType中的eventPda是base64编码，转换为Base58
                if (ticketType.eventPda.contains('=')) {
                  final base64Bytes = base64Decode(ticketType.eventPda);
                  if (base64Bytes.length == 32) {
                    final convertedEventPda = base58.encode(base64Bytes);

                    // 比较转换后的地址和传入的eventPda（可能带前缀）
                    if (eventPda.contains('event_')) {
                      final cleanEventPda =
                          eventPda.substring(6); // 移除'event_'前缀
                      belongsToEvent = (convertedEventPda == cleanEventPda);
                    } else {
                      belongsToEvent = (convertedEventPda == eventPda);
                    }

                    print('🔍 票种事件PDA匹配检查:');
                    print('  票种中的event (base64): ${ticketType.eventPda}');
                    print('  转换后的Base58: $convertedEventPda');
                    print('  传入的eventPda: $eventPda');
                    print('  匹配结果: $belongsToEvent');
                  }
                }
              } catch (e) {
                print('⚠️ 事件PDA格式转换失败: $e');
              }
            }

            if (belongsToEvent) {
              ticketTypes.add(ticketType);
              print('✅ 票种 ${ticketType.typeName} 属于当前活动');
            } else {
              print('⚠️ 票种 ${ticketType.typeName} 不属于当前活动');
            }
          } catch (e) {
            print('解析票种账户 ${account.pubkey} 数据失败: $e');
          }
        }
      }

      print('成功解析 ${ticketTypes.length} 个属于活动 $eventPda 的票种');

      // 按ticketTypeId排序
      ticketTypes.sort((a, b) => a.ticketTypeId.compareTo(b.ticketTypeId));

      return ticketTypes;
    } catch (e) {
      print('查询票种数据失败: $e');
      return [];
    }
  }

  /// 解析TicketTypeAccount数据
  TicketTypeModel _parseTicketTypeAccountData(
    String pubkey,
    String expectedEventPda,
    Uint8List data,
  ) {
    try {
      print('开始解析TicketTypeAccount数据，长度: ${data.length} bytes');

      // 跳过判别器（前8字节）
      if (data.length < 8) {
        throw Exception('数据长度不足，无法包含判别器');
      }

      // 验证判别器
      final discriminator = data.sublist(0, 8);
      bool isValidDiscriminator = true;
      for (int i = 0; i < 8; i++) {
        if (discriminator[i] != ticketTypeAccountDiscriminator[i]) {
          isValidDiscriminator = false;
          break;
        }
      }

      if (!isValidDiscriminator) {
        throw Exception('判别器不匹配，这不是一个TicketTypeAccount');
      }

      // 从第8字节开始解析TicketTypeAccount字段
      final buffer = ByteData.sublistView(data, 8);
      int offset = 0;

      // 解析 event (32字节 pubkey)
      final eventBytes = data.sublist(8 + offset, 8 + offset + 32);
      final eventPda = base64Encode(eventBytes); // 临时使用base64编码表示
      offset += 32;
      print('解析到 event PDA: $eventPda');

      // 解析 ticket_type_id (1字节 u8)
      final ticketTypeId = buffer.getUint8(offset);
      offset += 1;
      print('解析到 ticket_type_id: $ticketTypeId');

      // 解析 type_name (4字节长度 + 字符串内容)
      final typeNameLength = buffer.getUint32(offset, Endian.little);
      offset += 4;
      final typeNameBytes = data.sublist(
        8 + offset,
        8 + offset + typeNameLength,
      );
      final typeName = utf8.decode(typeNameBytes);
      offset += typeNameLength;
      print('解析到 type_name: $typeName');

      // 解析 initial_price (8字节 u64)
      final initialPrice = buffer.getUint64(offset, Endian.little);
      offset += 8;

      // 解析 current_price (8字节 u64)
      final currentPrice = buffer.getUint64(offset, Endian.little);
      offset += 8;

      // 解析 total_supply (4字节 u32)
      final totalSupply = buffer.getUint32(offset, Endian.little);
      offset += 4;

      // 解析 sold_count (4字节 u32)
      final soldCount = buffer.getUint32(offset, Endian.little);
      offset += 4;

      // 解析 refunded_count (4字节 u32) - IDL中有这个字段
      final refundedCount = buffer.getUint32(offset, Endian.little);
      offset += 4;

      print('解析到价格和数量信息:');
      print('  initial_price: $initialPrice lamports');
      print('  current_price: $currentPrice lamports');
      print('  total_supply: $totalSupply');
      print('  sold_count: $soldCount');
      print('  refunded_count: $refundedCount');

      // 解析 max_resale_royalty (2字节 u16)
      final maxResaleRoyalty = buffer.getUint16(offset, Endian.little);
      offset += 2;

      // 解析 is_fixed_price (1字节 bool) - IDL中有这个字段
      final isFixedPrice = buffer.getUint8(offset) == 1;
      offset += 1;

      // 解析 dynamic_pricing_rules_hash (Option<String>: 1字节标志 + 可选字符串)
      final hasDynamicPricingRules = buffer.getUint8(offset) == 1;
      offset += 1;
      String dynamicPricingRulesHash = '';
      if (hasDynamicPricingRules) {
        final rulesHashLength = buffer.getUint32(offset, Endian.little);
        offset += 4;
        final rulesHashBytes = data.sublist(
          8 + offset,
          8 + offset + rulesHashLength,
        );
        dynamicPricingRulesHash = utf8.decode(rulesHashBytes);
        offset += rulesHashLength;
      }

      // 解析 last_price_update (8字节 i64)
      final lastPriceUpdate = buffer.getInt64(offset, Endian.little);
      offset += 8;

      // 解析 bump (1字节 u8)
      final bump = buffer.getUint8(offset);
      offset += 1;

      print('解析到其他信息:');
      print('  max_resale_royalty: $maxResaleRoyalty');
      print('  is_fixed_price: $isFixedPrice');
      print('  dynamic_pricing_rules_hash: $dynamicPricingRulesHash');
      print('  last_price_update: $lastPriceUpdate');
      print('  bump: $bump');

      // 创建TicketTypeModel（由于IDL结构变化，需要适配）
      final now = DateTime.now();
      final ticketType = TicketTypeModel(
        eventPda: eventPda, // 使用解析出的eventPda
        ticketTypeId: ticketTypeId,
        typeName: typeName,
        initialPrice: initialPrice,
        currentPrice: currentPrice,
        totalSupply: totalSupply,
        soldCount: soldCount,
        maxResaleRoyalty: maxResaleRoyalty.toString(),
        dynamicPricingRulesHash: dynamicPricingRulesHash,
        isTransferable: true, // IDL中没有这个字段，使用默认值
        createdAt: now, // IDL中没有created_at字段，使用当前时间
        updatedAt: DateTime.fromMillisecondsSinceEpoch(lastPriceUpdate * 1000),
      );

      print('✅ 成功解析TicketTypeAccount: ${ticketType.typeName}');
      return ticketType;
    } catch (e) {
      print('❌ 解析TicketTypeAccount数据失败: $e');
      // 如果解析失败，返回一个带有基础信息的TicketTypeModel
      final now = DateTime.now();
      return TicketTypeModel(
        eventPda: expectedEventPda,
        ticketTypeId: 0,
        typeName: '解析失败的票种',
        initialPrice: 0,
        currentPrice: 0,
        totalSupply: 0,
        soldCount: 0,
        maxResaleRoyalty: '0',
        dynamicPricingRulesHash: 'parse_error',
        isTransferable: false,
        createdAt: now,
        updatedAt: now,
      );
    }
  }

  /// Base58解码辅助方法
  List<int> _base58ToBytes(String base58String) {
    // 这是一个简化的Base58解码实现
    // 在实际项目中，您可能需要使用专门的Base58库
    try {
      // 这里需要实现Base58解码
      // 暂时返回空数组，实际使用时需要正确的Base58解码
      return List.filled(32, 0);
    } catch (e) {
      print('Base58解码失败: $e');
      return List.filled(32, 0);
    }
  }

  /// 生成活动PDA
  Future<String> generateEventPDA(String organizer, String eventName) async {
    try {
      print('🔍 开始生成活动PDA:');
      print('  organizer: $organizer');
      print('  eventName: $eventName');

      // 检查 organizer 是否是有效的 Solana 地址格式
      String validOrganizerAddress;
      if (organizer.startsWith('Pubkey:') || organizer.length < 32) {
        // 如果是显示格式或无效格式，使用测试钱包地址
        validOrganizerAddress = '2XM48QdtTv3dAHccUjVdZ2CF7Es3estfNRAqjjde8QdL';
        print('⚠️ 使用测试钱包地址替代无效的 organizer: $validOrganizerAddress');
      } else {
        validOrganizerAddress = organizer;
      }

      // 生成活动的PDA
      // seeds = [b"event", organizer.key().as_ref(), event_name.as_bytes()]
      final seeds = [
        utf8.encode("event"),
        base58.decode(validOrganizerAddress),
        utf8.encode(eventName),
      ];

      print('🔍 生成活动PDA seeds:');
      print('  seed[0]: "event" (${utf8.encode("event").length} bytes)');
      print('  seed[1]: organizer (${base58.decode(validOrganizerAddress).length} bytes)');
      print('  seed[2]: event_name "$eventName" (${utf8.encode(eventName).length} bytes)');

      // 使用Solana PDA生成算法
      final programId = Ed25519HDPublicKey.fromBase58(getProgramId());
      final result = await Ed25519HDPublicKey.findProgramAddress(
        seeds: seeds,
        programId: programId,
      );

      final eventPda = result.toBase58();
      print('✅ 生成活动PDA成功: $eventPda');

      return eventPda;
    } catch (e) {
      print('❌ 生成活动PDA失败: $e');
      print('❌ 错误详情: ${e.toString()}');
      return '';
    }
  }

  /// 生成座位状态映射PDA
  Future<String> generateSeatStatusMapPDA(
      String eventPda, String ticketTypePda, String areaId) async {
    try {
      // 生成座位状态映射的PDA
      // seeds = [b"seat_status_map", event.key().as_ref(), ticket_type.key().as_ref(), area_id.as_bytes()]

      final seeds = [
        utf8.encode("seat_status_map"),
        base58.decode(eventPda),
        base58.decode(ticketTypePda),
        utf8.encode(areaId),
      ];

      print('🔍 生成座位状态映射PDA seeds:');
      print(
          '  seed[0]: "seat_status_map" (${utf8.encode("seat_status_map").length} bytes)');
      print('  seed[1]: event PDA (${base58.decode(eventPda).length} bytes)');
      print(
          '  seed[2]: ticket_type PDA (${base58.decode(ticketTypePda).length} bytes)');
      print(
          '  seed[3]: area_id "$areaId" (${utf8.encode(areaId).length} bytes)');

      // 使用Solana PDA生成算法
      final programId = Ed25519HDPublicKey.fromBase58(getProgramId());
      final result = await Ed25519HDPublicKey.findProgramAddress(
        seeds: seeds,
        programId: programId,
      );

      final pda = result.toBase58();
      print('✅ 成功生成座位状态映射PDA: $pda');

      return pda;
    } catch (e) {
      print('❌ 生成座位状态映射PDA失败: $e');
      return '';
    }
  }

  /// 根据票种名称获取票种PDA
  Future<String> generateTicketTypePDA(
      String eventPda, String ticketTypeName) async {
    try {
      // 生成票种的PDA
      // seeds = [b"ticket_type", event.key().as_ref(), ticket_type_name.as_bytes()]

      final seeds = [
        utf8.encode("ticket_type"),
        base58.decode(eventPda),
        utf8.encode(ticketTypeName),
      ];

      print('🔍 生成票种PDA seeds:');
      print(
          '  seed[0]: "ticket_type" (${utf8.encode("ticket_type").length} bytes)');
      print('  seed[1]: event PDA (${base58.decode(eventPda).length} bytes)');
      print(
          '  seed[2]: ticket_type_name "$ticketTypeName" (${utf8.encode(ticketTypeName).length} bytes)');

      // 使用Solana PDA生成算法
      final programId = Ed25519HDPublicKey.fromBase58(getProgramId());
      final result = await Ed25519HDPublicKey.findProgramAddress(
        seeds: seeds,
        programId: programId,
      );

      final pda = result.toBase58();
      print('✅ 成功生成票种PDA: $pda');

      return pda;
    } catch (e) {
      print('❌ 生成票种PDA失败: $e');
      return '';
    }
  }

  /// 获取座位状态映射数据
  Future<SeatStatusMapModel?> getSeatStatusMapData(
      String seatStatusMapPda) async {
    try {
      print('查询座位状态映射: $seatStatusMapPda');

      // 等待SolanaService初始化完成
      if (_solanaService.client == null) {
        print('等待Solana客户端初始化...');
        await _solanaService.initialize();
      }

      if (_solanaService.client == null) {
        throw Exception('Solana客户端初始化失败');
      }

      final client = _solanaService.client!;

      // 查询座位状态映射账户
      final accountInfo = await client.getAccountInfo(
        seatStatusMapPda,
        encoding: Encoding.base64,
      );

      if (accountInfo.value == null) {
        print('未找到座位状态映射账户: $seatStatusMapPda');
        return null;
      }

      print('找到座位状态映射账户');

      // 解析SeatStatusMap数据
      final accountData = accountInfo.value!.data;
      Uint8List decodedData;

      if (accountData is BinaryAccountData) {
        decodedData = Uint8List.fromList(accountData.data);
      } else {
        final jsonData = accountData?.toJson();
        if (jsonData is List &&
            jsonData.length >= 2 &&
            jsonData[1] == 'base64') {
          decodedData = base64Decode(jsonData[0] as String);
        } else {
          throw Exception('无法解析账户数据');
        }
      }

      // 解析SeatStatusMap结构
      final mapData = _parseSeatStatusMapData(decodedData);
      return SeatStatusMapModel.fromMap(mapData);
    } catch (e) {
      print('获取座位状态映射失败: $e');
      return null;
    }
  }

  /// 获取座位状态数据（区域级别）
  /// 注意：每个区域都有自己独立的 seatStatusMapPda 和位图数据
  /// seatStatusMapPda 是基于 eventPda + ticketTypePda + areaId 生成的
  Future<SeatStatusData?> getSeatStatusData(String seatStatusMapPda) async {
    try {
      print('获取区域座位状态数据: $seatStatusMapPda');

      // 1. 检查座位状态映射账户是否存在
      final mapData = await getSeatStatusMapData(seatStatusMapPda);

      if (mapData == null) {
        print('⚠️ 座位状态映射账户不存在，这是正常的，因为账户在第一次购票时才会创建');
        // 返回一个空的状态数据，表示所有座位都是可用状态
        return SeatStatusData(
          seatStatusMapPda: seatStatusMapPda,
          seatLayoutHash: '',
          seatIndexMapHash: '',
          totalSeats: 0,
          soldSeats: 0,
          seatStatusMap: {},
          seatStatusBitmap: null,
          seatIndexMap: null,
        );
      }

      // 2. 获取位图数据
      final bitmapData = await _getSeatStatusBitmap(seatStatusMapPda);

      // 3. 从Arweave获取座位索引映射数据（如果存在）
      Map<String, dynamic>? indexMapData;
      Map<String, int>? seatIndexMap;

      if (mapData.seatIndexMapHash.isNotEmpty) {
        indexMapData = await _arweaveService.getJsonData(mapData.seatIndexMapHash);

        if (indexMapData != null && indexMapData['seatIndexMap'] != null) {
          seatIndexMap = Map<String, int>.from(
            indexMapData['seatIndexMap'].map((key, value) =>
              MapEntry(key.toString(), int.tryParse(value.toString()) ?? 0)
            )
          );
        }
      }

      print('✅ 座位状态数据获取完成:');
      print('  - 位图数据长度: ${bitmapData?.length ?? 0} 字节');
      print('  - 座位索引映射: ${seatIndexMap?.length ?? 0} 个座位');

      // 4. 创建座位状态数据对象
      return SeatStatusData(
        seatStatusMapPda: seatStatusMapPda,
        seatLayoutHash: mapData.seatLayoutHash,
        seatIndexMapHash: mapData.seatIndexMapHash,
        totalSeats: mapData.totalSeats,
        soldSeats: mapData.soldSeats,
        seatStatusMap: indexMapData?['seatStatusMap'] ?? {},
        seatStatusBitmap: bitmapData,
        seatIndexMap: seatIndexMap,
      );
    } catch (e) {
      print('获取座位状态数据失败: $e');
      return null;
    }
  }

  /// 获取座位状态位图数据
  Future<List<int>?> _getSeatStatusBitmap(String seatStatusMapPda) async {
    try {
      print('🔍 获取座位状态位图: $seatStatusMapPda');

      // 等待SolanaService初始化完成
      if (_solanaService.client == null) {
        print('等待Solana客户端初始化...');
        await _solanaService.initialize();
      }

      if (_solanaService.client == null) {
        throw Exception('Solana客户端初始化失败');
      }

      final client = _solanaService.client!;

      // 查询座位状态映射账户
      final accountInfo = await client.getAccountInfo(
        seatStatusMapPda,
        encoding: Encoding.base64,
      );

      if (accountInfo.value == null) {
        print('未找到座位状态映射账户: $seatStatusMapPda');
        return null;
      }

      // 解析账户数据
      final accountData = accountInfo.value!.data;
      Uint8List decodedData;

      if (accountData is BinaryAccountData) {
        decodedData = Uint8List.fromList(accountData.data);
      } else {
        final jsonData = accountData?.toJson();
        if (jsonData is List &&
            jsonData.length >= 2 &&
            jsonData[1] == 'base64') {
          decodedData = base64Decode(jsonData[0] as String);
        } else {
          throw Exception('无法解析账户数据');
        }
      }

      // 解析位图数据
      final bitmapData = _extractSeatStatusBitmap(decodedData);

      if (bitmapData != null) {
        print('✅ 成功获取座位状态位图: ${bitmapData.length} 字节');
      } else {
        print('⚠️ 未找到座位状态位图数据');
      }

      return bitmapData;
    } catch (e) {
      print('❌ 获取座位状态位图失败: $e');
      return null;
    }
  }

  /// 从账户数据中提取座位状态位图
  List<int>? _extractSeatStatusBitmap(Uint8List data) {
    try {
      // 跳过固定字段，找到位图数据
      int offset = 0;
      final buffer = ByteData.sublistView(data);

      // 跳过 event 字段 (4字节长度 + 字符串)
      if (offset + 4 > data.length) return null;
      final eventLength = buffer.getUint32(offset, Endian.little);
      offset += 4 + eventLength;

      // 跳过 ticket_type 字段 (4字节长度 + 字符串)
      if (offset + 4 > data.length) return null;
      final ticketTypeLength = buffer.getUint32(offset, Endian.little);
      offset += 4 + ticketTypeLength;

      // 跳过 seat_layout_hash 字段 (4字节长度 + 字符串)
      if (offset + 4 > data.length) return null;
      final seatLayoutHashLength = buffer.getUint32(offset, Endian.little);
      offset += 4 + seatLayoutHashLength;

      // 跳过 seat_index_map_hash 字段 (4字节长度 + 字符串)
      if (offset + 4 > data.length) return null;
      final seatIndexMapHashLength = buffer.getUint32(offset, Endian.little);
      offset += 4 + seatIndexMapHashLength;

      // 跳过 total_seats (4字节 u32)
      offset += 4;

      // 跳过 sold_seats (4字节 u32)
      offset += 4;

      // 读取位图长度 (4字节 u32)
      if (offset + 4 > data.length) return null;
      final bitmapLength = buffer.getUint32(offset, Endian.little);
      offset += 4;

      // 读取位图数据
      if (offset + bitmapLength > data.length) return null;
      final bitmapBytes = data.sublist(offset, offset + bitmapLength);

      print('📊 位图数据解析完成:');
      print('  - 位图长度: $bitmapLength 字节');
      print('  - 数据偏移: $offset');

      return bitmapBytes;
    } catch (e) {
      print('❌ 提取位图数据失败: $e');
      return null;
    }
  }

  /// 批量更新座位状态
  Future<List<int>> batchUpdateSeatStatus({
    required String eventPda,
    required String ticketTypeName,
    required String areaId,
    required List<Map<String, dynamic>> seatUpdates,
  }) async {
    try {
      print('🎫 开始创建批量更新座位状态交易:');
      print('  - 活动PDA: $eventPda');
      print('  - 票种名称: $ticketTypeName');
      print('  - 区域ID: $areaId');
      print('  - 座位更新数量: ${seatUpdates.length}');

      // 1. 生成票种PDA
      final ticketTypePda = await generateTicketTypePDA(eventPda, ticketTypeName);
      print('📍 票种PDA: $ticketTypePda');

      // 2. 生成座位状态映射PDA
      final seatStatusMapPda = await generateSeatStatusMapPDA(
        eventPda,
        ticketTypePda,
        areaId,
      );
      print('📍 座位状态映射PDA: $seatStatusMapPda');

      // 3. 获取钱包地址
      final walletService = Get.find<MobileWalletService>();
      final authority = walletService.publicKey;
      if (authority.isEmpty) {
        throw Exception('钱包未连接');
      }
      print('👤 授权用户: $authority');

      // 4. 检查座位状态映射账户是否存在
      final existingMapData = await getSeatStatusMapData(seatStatusMapPda);
      final needsInitialization = existingMapData == null;

      if (needsInitialization) {
        print('⚠️ 座位状态映射账户不存在，交易将包含初始化逻辑');
      }

      // 5. 编码交易数据
      final transactionData = await _encodeBatchUpdateSeatStatusTransaction(
        authority: authority,
        eventPda: eventPda,
        ticketTypePda: ticketTypePda,
        seatStatusMapPda: seatStatusMapPda,
        ticketTypeName: ticketTypeName,
        areaId: areaId,
        seatUpdates: seatUpdates,
        needsInitialization: needsInitialization,
      );

      print('✅ 交易数据创建成功，字节长度: ${transactionData.length}');
      return transactionData;
    } catch (e) {
      print('❌ 创建批量更新座位状态交易失败: $e');
      rethrow;
    }
  }

  /// 编码批量更新座位状态交易数据
  Future<List<int>> _encodeBatchUpdateSeatStatusTransaction({
    required String authority,
    required String eventPda,
    required String ticketTypePda,
    required String seatStatusMapPda,
    required String ticketTypeName,
    required String areaId,
    required List<Map<String, dynamic>> seatUpdates,
    bool needsInitialization = false,
  }) async {
    try {
      print('🔨 构建购票交易数据...');

      // 使用 SystemInstruction.transfer 作为模板创建一个简单的转账交易
      // 这样可以确保交易格式正确，钱包可以正确处理

      // 创建一个简单的 SOL 转账交易作为占位符
      // 实际的合约调用逻辑将在后续版本中实现
      final transferInstruction = SystemInstruction.transfer(
        fundingAccount: Ed25519HDPublicKey.fromBase58(authority),
        recipientAccount: Ed25519HDPublicKey.fromBase58(eventPda),
        lamports: 10000, // 0.00001 SOL 作为交易费用
      );

      // 创建交易消息
      final message = Message(instructions: [transferInstruction]);

      // 获取最新的区块哈希
      final recentBlockhash = await _getRecentBlockhash();

      // 编译消息
      final compiledMessage = message.compile(
        recentBlockhash: recentBlockhash,
        feePayer: Ed25519HDPublicKey.fromBase58(authority),
      );

      // 获取交易字节
      final transactionBytes = compiledMessage.toByteArray().toList();

      print('📊 购票交易数据构建完成:');
      print('  - 指令: SOL transfer (临时实现)');
      print('  - 程序ID: ${SystemProgram.programId}');
      print('  - 从: $authority');
      print('  - 到: $eventPda');
      print('  - 金额: 10000 lamports');
      print('  - 交易字节长度: ${transactionBytes.length}');

      return transactionBytes;
    } catch (e) {
      print('❌ 构建购票交易数据失败: $e');
      rethrow;
    }
  }











  /// 解析SeatStatusMap数据
  Map<String, dynamic> _parseSeatStatusMapData(Uint8List data) {
    try {
      print('开始解析SeatStatusMap数据，长度: ${data.length} bytes');

      // 跳过判别器（前8字节）
      if (data.length < 8) {
        throw Exception('数据长度不足，无法包含判别器');
      }

      final buffer = ByteData.sublistView(data, 8);
      int offset = 0;

      // 解析 event (32字节 pubkey)
      final eventBytes = data.sublist(8 + offset, 8 + offset + 32);
      final event = base58.encode(eventBytes);
      offset += 32;

      // 解析 ticket_type (32字节 pubkey)
      final ticketTypeBytes = data.sublist(8 + offset, 8 + offset + 32);
      final ticketType = base58.encode(ticketTypeBytes);
      offset += 32;

      // 解析 seat_layout_hash (4字节长度 + 字符串内容)
      final seatLayoutHashLength = buffer.getUint32(offset, Endian.little);
      offset += 4;
      final seatLayoutHashBytes = data.sublist(
        8 + offset,
        8 + offset + seatLayoutHashLength,
      );
      final seatLayoutHash = utf8.decode(seatLayoutHashBytes);
      offset += seatLayoutHashLength;

      // 解析 seat_index_map_hash (4字节长度 + 字符串内容)
      final seatIndexMapHashLength = buffer.getUint32(offset, Endian.little);
      offset += 4;
      final seatIndexMapHashBytes = data.sublist(
        8 + offset,
        8 + offset + seatIndexMapHashLength,
      );
      final seatIndexMapHash = utf8.decode(seatIndexMapHashBytes);
      offset += seatIndexMapHashLength;

      // 解析 total_seats (4字节 u32)
      final totalSeats = buffer.getUint32(offset, Endian.little);
      offset += 4;

      // 解析 sold_seats (4字节 u32)
      final soldSeats = buffer.getUint32(offset, Endian.little);
      offset += 4;

      print('解析到SeatStatusMap数据:');
      print('  event: $event');
      print('  ticket_type: $ticketType');
      print('  seat_layout_hash: $seatLayoutHash');
      print('  seat_index_map_hash: $seatIndexMapHash');
      print('  total_seats: $totalSeats');
      print('  sold_seats: $soldSeats');

      return {
        'event': event,
        'ticketType': ticketType,
        'seatLayoutHash': seatLayoutHash,
        'seatIndexMapHash': seatIndexMapHash,
        'totalSeats': totalSeats,
        'soldSeats': soldSeats,
      };
    } catch (e) {
      print('解析SeatStatusMap数据失败: $e');
      throw e;
    }
  }

  /// 根据PDA查询场馆信息
  Future<VenueModel?> getVenueById(String venueIdString) async {
    try {
      print('=== ContractService.getVenueById ===');
      print('查询场馆PDA: $venueIdString');
      print('PDA长度: ${venueIdString.length}');

      // 调用Solana服务获取账户信息
      final client = _solanaService.client;
      if (client == null) {
        throw Exception('Solana客户端未初始化');
      }

      // 确保地址是Base58格式
      String addressToQuery = venueIdString;
      if (venueIdString.contains('=') && venueIdString.length > 20) {
        try {
          // 如果是base64编码的32字节pubkey，转换为Base58
          final base64Bytes = base64Decode(venueIdString);
          if (base64Bytes.length == 32) {
            addressToQuery = base58.encode(base64Bytes);
            print('🔄 转换base64地址为Base58: $addressToQuery');
          }
        } catch (e) {
          print('⚠️ base64转换失败，使用原始地址: $e');
          addressToQuery = venueIdString;
        }
      }

      print('🔍 正在查询账户信息: $addressToQuery');
      final accountInfo = await client.getAccountInfo(
        addressToQuery,
        encoding: Encoding.base64, // 明确指定编码格式
      );

      if (accountInfo.value == null) {
        print('未找到场馆账户: $venueIdString');
        return null;
      }

      // 获取账户数据
      final accountData = accountInfo.value!.data;
      Uint8List decodedData;

      // 根据AccountData类型处理数据
      if (accountData is BinaryAccountData) {
        // 如果是BinaryAccountData，直接使用data字段
        decodedData = Uint8List.fromList(accountData.data);
        print('使用BinaryAccountData，数据长度: ${decodedData.length} bytes');
      } else {
        // 其他情况，从toJson()中获取base64数据
        final jsonData = accountData!.toJson();
        if (jsonData is List &&
            jsonData.length >= 2 &&
            jsonData[1] == 'base64') {
          decodedData = base64Decode(jsonData[0] as String);
          print('从JSON解码base64，数据长度: ${decodedData.length} bytes');
        } else {
          print('警告: 未知的AccountData格式: ${accountData.runtimeType}');
          throw Exception('无法解析AccountData格式');
        }
      }

      // 解析VenueAccount数据
      final venue = _parseVenueAccountData(venueIdString, decodedData);
      print('✅ 成功查询场馆: ${venue.venueName}');
      return venue;
    } catch (e) {
      print('❌ 查询场馆信息失败: $e');
      return null;
    }
  }

  /// 解析VenueAccount数据
  VenueModel _parseVenueAccountData(String pubkey, Uint8List data) {
    try {
      print('开始解析VenueAccount数据，长度: ${data.length} bytes');

      // 跳过判别器（前8字节）
      if (data.length < 8) {
        throw Exception('数据长度不足，无法包含判别器');
      }

      // 验证判别器
      final discriminator = data.sublist(0, 8);
      bool isValidDiscriminator = true;
      for (int i = 0; i < 8; i++) {
        if (discriminator[i] != venueAccountDiscriminator[i]) {
          isValidDiscriminator = false;
          break;
        }
      }

      if (!isValidDiscriminator) {
        throw Exception('判别器不匹配，这不是一个VenueAccount');
      }

      print('判别器验证通过');

      // 从第8字节开始解析VenueAccount字段
      final buffer = ByteData.sublistView(data, 8);
      int offset = 0;

      // 解析 creator (32字节 pubkey)
      final creatorBytes = data.sublist(8 + offset, 8 + offset + 32);
      final creator = base64Encode(creatorBytes);
      offset += 32;
      print('解析到 creator: $creator');

      // 解析 venue_name (4字节长度 + 字符串内容)
      final venueNameLength = buffer.getUint32(offset, Endian.little);
      offset += 4;
      final venueNameBytes = data.sublist(
        8 + offset,
        8 + offset + venueNameLength,
      );
      final venueName = utf8.decode(venueNameBytes);
      offset += venueNameLength;
      print('解析到 venue_name: $venueName');

      // 解析 venue_address (4字节长度 + 字符串内容)
      final venueAddressLength = buffer.getUint32(offset, Endian.little);
      offset += 4;
      final venueAddressBytes = data.sublist(
        8 + offset,
        8 + offset + venueAddressLength,
      );
      final venueAddress = utf8.decode(venueAddressBytes);
      offset += venueAddressLength;
      print('解析到 venue_address: $venueAddress');

      // 解析 total_capacity (4字节 u32)
      final totalCapacity = buffer.getUint32(offset, Endian.little);
      offset += 4;
      print('解析到 total_capacity: $totalCapacity');

      // 解析 venue_description (4字节长度 + 字符串内容)
      final venueDescLength = buffer.getUint32(offset, Endian.little);
      offset += 4;
      final venueDescBytes = data.sublist(
        8 + offset,
        8 + offset + venueDescLength,
      );
      final venueDescription = utf8.decode(venueDescBytes);
      offset += venueDescLength;
      print('解析到 venue_description: $venueDescription');

      // 解析 floor_plan_hash (Option<String>: 1字节标志 + 可选字符串)
      final hasFloorPlanHash = buffer.getUint8(offset) == 1;
      offset += 1;
      String? floorPlanHash;
      if (hasFloorPlanHash) {
        final floorPlanHashLength = buffer.getUint32(offset, Endian.little);
        offset += 4;
        final floorPlanHashBytes = data.sublist(
          8 + offset,
          8 + offset + floorPlanHashLength,
        );
        floorPlanHash = utf8.decode(floorPlanHashBytes);
        offset += floorPlanHashLength;
      }

      // 解析 seat_map_hash (Option<String>: 1字节标志 + 可选字符串)
      final hasSeatMapHash = buffer.getUint8(offset) == 1;
      offset += 1;
      String? seatMapHash;
      if (hasSeatMapHash) {
        final seatMapHashLength = buffer.getUint32(offset, Endian.little);
        offset += 4;
        final seatMapHashBytes = data.sublist(
          8 + offset,
          8 + offset + seatMapHashLength,
        );
        seatMapHash = utf8.decode(seatMapHashBytes);
        offset += seatMapHashLength;
      }

      // 解析 venue_type (枚举，1字节)
      final venueTypeIndex = buffer.getUint8(offset);
      offset += 1;
      final venueTypes = [
        'Indoor',
        'Outdoor',
        'Stadium',
        'Theater',
        'Concert',
        'Convention',
        'Exhibition',
        'Other'
      ];
      final venueType = venueTypeIndex < venueTypes.length
          ? venueTypes[venueTypeIndex]
          : 'Other';
      print('解析到 venue_type: $venueType');

      // 解析 facilities_info_hash (Option<String>: 1字节标志 + 可选字符串)
      final hasFacilitiesInfo = buffer.getUint8(offset) == 1;
      offset += 1;
      String? facilitiesInfoHash;
      if (hasFacilitiesInfo) {
        final facilitiesInfoLength = buffer.getUint32(offset, Endian.little);
        offset += 4;
        final facilitiesInfoBytes = data.sublist(
          8 + offset,
          8 + offset + facilitiesInfoLength,
        );
        facilitiesInfoHash = utf8.decode(facilitiesInfoBytes);
        offset += facilitiesInfoLength;
      }

      // 解析 contact_info (4字节长度 + 字符串内容)
      final contactInfoLength = buffer.getUint32(offset, Endian.little);
      offset += 4;
      final contactInfoBytes = data.sublist(
        8 + offset,
        8 + offset + contactInfoLength,
      );
      final contactInfo = utf8.decode(contactInfoBytes);
      offset += contactInfoLength;
      print('解析到 contact_info: $contactInfo');

      // 解析 venue_status (枚举，1字节)
      final venueStatusIndex = buffer.getUint8(offset);
      offset += 1;
      final venueStatuses = [
        'Unused',
        'Active',
        'Maintenance',
        'Inactive',
        'TemporarilyClosed'
      ];
      final venueStatus = venueStatusIndex < venueStatuses.length
          ? venueStatuses[venueStatusIndex]
          : 'Unused';
      print('解析到 venue_status: $venueStatus');

      // 解析时间戳字段 (每个8字节 i64)
      final createdAt = buffer.getInt64(offset, Endian.little);
      offset += 8;
      final updatedAt = buffer.getInt64(offset, Endian.little);
      offset += 8;

      print('解析到时间戳:');
      print('  created_at: $createdAt');
      print('  updated_at: $updatedAt');

      // 创建VenueModel
      final venue = VenueModel(
        id: pubkey,
        creator: creator,
        venueName: venueName,
        venueAddress: venueAddress,
        totalCapacity: totalCapacity,
        venueDescription: venueDescription,
        floorPlanHash: floorPlanHash,
        seatMapHash: seatMapHash,
        venueType: venueType,
        facilitiesInfoHash: facilitiesInfoHash,
        contactInfo: contactInfo,
        venueStatus: venueStatus,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt * 1000),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt * 1000),
      );

      print('✅ 成功解析VenueAccount: ${venue.venueName}');
      return venue;
    } catch (e) {
      print('❌ 解析VenueAccount数据失败: $e');
      // 如果解析失败，返回一个带有基础信息的VenueModel
      final now = DateTime.now();
      return VenueModel(
        id: pubkey,
        creator: 'parse_error',
        venueName: '解析失败的场馆',
        venueAddress: '',
        totalCapacity: 0,
        venueDescription: '',
        venueType: 'Other',
        contactInfo: '',
        venueStatus: 'Unused',
        createdAt: now,
        updatedAt: now,
      );
    }
  }

  /// 获取平台信息
  Future<PlatformInfo?> getPlatformInfo() async {
    try {
      print('🔍 获取平台信息...');

      // 生成平台PDA
      final platformPDA = await _generatePlatformPDA();
      print('  - 平台PDA: $platformPDA');

      // 获取账户数据
      final accountInfo = await _solanaService.client?.getAccountInfo(
        platformPDA,
        commitment: Commitment.confirmed,
        encoding: Encoding.base64,
      );

      if (accountInfo == null) {
        print('❌ 未找到平台账户数据');
        return null;
      }

      // 解析账户数据
      final data = base64Decode(accountInfo.toString());
      final buffer = ByteData.sublistView(data);

      // 跳过判别器（8字节）
      int offset = 8;

      // 解析平台费率（2字节 u16）
      final platformFeeBps = buffer.getUint16(offset, Endian.little);
      offset += 2;

      // 解析费用接收者（32字节 pubkey）
      final feeRecipientBytes = data.sublist(offset, offset + 32);
      final feeRecipient = base58.encode(feeRecipientBytes);
      offset += 32;

      // 解析暂停状态（1字节 bool）
      final isPaused = buffer.getUint8(offset) == 1;

      print('✅ 平台信息解析完成:');
      print('  - 费率: ${platformFeeBps}基点');
      print('  - 接收者: $feeRecipient');
      print('  - 暂停状态: $isPaused');

      return PlatformInfo(
        platformFeeBps: platformFeeBps,
        feeRecipient: feeRecipient,
        isPaused: isPaused,
      );
    } catch (e) {
      print('❌ 获取平台信息失败: $e');
      return null;
    }
  }

  /// 生成平台PDA
  Future<String> _generatePlatformPDA() async {
    final seeds = [utf8.encode('platform')];
    final programId = Ed25519HDPublicKey.fromBase58(programIdString);
    final result = await Ed25519HDPublicKey.findProgramAddress(
      seeds: seeds,
      programId: programId,
    );
    return result.toString();
  }

  /// 获取最新的区块哈希
  Future<String> _getRecentBlockhash() async {
    try {
      final client = _solanaService.client;
      if (client == null) {
        throw Exception('Solana 客户端未初始化');
      }
      final response = await client.getLatestBlockhash();
      return response.value.blockhash;
    } catch (e) {
      print('❌ 获取区块哈希失败: $e');
      // 返回一个默认的区块哈希作为后备
      return '11111111111111111111111111111111';
    }
  }
}
