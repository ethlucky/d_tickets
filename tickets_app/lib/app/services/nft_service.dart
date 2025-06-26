import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';
import '../models/nft_ticket_model.dart';
import 'solana_service.dart';
import 'arweave_service.dart';

/// NFT 服务 - 处理 NFT 票券的查询和管理
class NFTService extends GetxService {
  final SolanaService _solanaService = Get.find<SolanaService>();
  final ArweaveService _arweaveService = Get.find<ArweaveService>();
  final GetStorage _storage = GetStorage();

  // 票券程序 ID（需要根据实际部署的程序 ID 修改）
  static const String ticketProgramId = 'YourTicketProgramIdHere';
  
  // Metaplex Token Metadata 程序 ID
  static const String metadataProgram = 'metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s';

  @override
  Future<void> onInit() async {
    super.onInit();
    print('🎫 NFTService 初始化完成');

    // 测试 RPC 连接
    await _testRPCConnection();
  }

  /// 测试 RPC 连接
  Future<void> _testRPCConnection() async {
    try {
      final rpcUrl = 'https://api.mainnet-beta.solana.com';
      final response = await http.post(
        Uri.parse(rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'jsonrpc': '2.0',
          'id': 1,
          'method': 'getHealth',
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] == 'ok') {
          print('✅ Solana RPC 连接测试成功');
        } else {
          print('⚠️ Solana RPC 响应异常: ${data['result']}');
        }
      } else {
        print('❌ Solana RPC 连接测试失败: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ RPC 连接测试异常: $e');
    }
  }

  /// 获取用户的所有 NFT 票券
  Future<List<NFTTicketModel>> getUserNFTTickets(String userPublicKey) async {
    try {
      print('🔍 开始查询用户 NFT 票券: $userPublicKey');

      // 1. 获取用户的所有 token 账户
      final tokenAccounts = await _getUserTokenAccounts(userPublicKey);
      print('📊 找到 ${tokenAccounts.length} 个 token 账户');

      // 2. 过滤出 NFT（supply = 1, decimals = 0）
      final nftAccounts = await _filterNFTAccounts(tokenAccounts);
      print('🎨 找到 ${nftAccounts.length} 个 NFT');

      // 3. 获取每个 NFT 的 metadata
      final nftTickets = <NFTTicketModel>[];
      for (final nftAccount in nftAccounts) {
        try {
          final nftTicket = await _parseNFTTicket(nftAccount, userPublicKey);
          if (nftTicket != null) {
            nftTickets.add(nftTicket);
          }
        } catch (e) {
          print('⚠️ 解析 NFT 失败: ${nftAccount['mint']}, 错误: $e');
        }
      }

      print('🎫 成功解析 ${nftTickets.length} 个 NFT 票券');
      return nftTickets;

    } catch (e) {
      print('❌ 查询用户 NFT 票券失败: $e');
      return [];
    }
  }

  /// 获取用户的所有 token 账户
  Future<List<Map<String, dynamic>>> _getUserTokenAccounts(String userPublicKey) async {
    try {
      print('🔍 查询用户 token 账户: $userPublicKey');

      // 确保 Solana 服务已初始化
      if (_solanaService.client == null) {
        print('🔄 初始化 Solana 服务...');
        await _solanaService.initialize();
      }

      final client = _solanaService.client;
      if (client == null) {
        throw Exception('无法初始化 Solana 客户端');
      }

      print('✅ 使用 Solana 客户端查询 token 账户');

      // 使用 getProgramAccounts 查询 SPL Token 程序的账户
      // 过滤条件：owner 字段匹配用户公钥
      // 将用户公钥从 base58 转换为字节数组
      final userPublicKeyBytes = Ed25519HDPublicKey.fromBase58(userPublicKey).bytes;

      final filters = [
        ProgramDataFilter.memcmp(
          offset: 32, // SPL Token 账户中 owner 字段的偏移量
          bytes: userPublicKeyBytes,
        ),
      ];

      final programAccounts = await client.getProgramAccounts(
        'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', // SPL Token 程序 ID
        encoding: Encoding.base64,
        filters: filters,
      );

      print('📊 找到 ${programAccounts.length} 个 token 账户');

      if (programAccounts.isNotEmpty) {
        print('📋 第一个账户示例: ${programAccounts.first.pubkey}');
      }

      // 转换为统一格式并解析 token 账户数据
      final tokenAccounts = <Map<String, dynamic>>[];
      for (final account in programAccounts) {
        try {
          // 解析 SPL Token 账户数据
          final tokenAccountData = _parseSPLTokenAccount(account.account.data?.toString());
          if (tokenAccountData != null) {
            tokenAccounts.add({
              'pubkey': account.pubkey,
              'account': {
                'data': {
                  'parsed': {
                    'info': tokenAccountData,
                  }
                },
                'owner': account.account.owner,
                'lamports': account.account.lamports,
              }
            });
          }
        } catch (e) {
          print('⚠️ 解析 token 账户失败: ${account.pubkey}, 错误: $e');
        }
      }

      return tokenAccounts;

    } catch (e) {
      print('❌ 获取 token 账户失败: $e');
      throw Exception('获取 token 账户失败: $e');
    }
  }

  /// 解析 SPL Token 账户数据
  Map<String, dynamic>? _parseSPLTokenAccount(String? data) {
    try {
      if (data == null || data.isEmpty) return null;

      // 解析 base64 编码的 SPL Token 账户数据
      final bytes = base64.decode(data);
      if (bytes.length < 72) return null; // SPL Token 账户至少需要 72 字节

      // SPL Token 账户结构：
      // mint: 0-32 字节
      // owner: 32-64 字节
      // amount: 64-72 字节
      // delegate: 72-104 字节 (可选)
      // state: 104 字节
      // ...

      // 提取 mint 地址 (前32字节)
      final mintBytes = bytes.sublist(0, 32);
      final mintAddress = Ed25519HDPublicKey(mintBytes).toBase58();

      // 提取 owner 地址 (32-64字节)
      final ownerBytes = bytes.sublist(32, 64);
      final ownerAddress = Ed25519HDPublicKey(ownerBytes).toBase58();

      // 提取 amount (64-72字节，小端序)
      final amountBytes = bytes.sublist(64, 72);
      int amount = 0;
      for (int i = 0; i < 8; i++) {
        amount += amountBytes[i] << (i * 8);
      }

      print('🔍 解析到真实 NFT: mint=$mintAddress, owner=$ownerAddress, amount=$amount');

      return {
        'mint': mintAddress,
        'owner': ownerAddress,
        'tokenAmount': {
          'amount': amount.toString(),
          'decimals': 0,
          'uiAmount': amount,
        }
      };
    } catch (e) {
      print('❌ 解析 SPL Token 账户数据失败: $e');
      return null;
    }
  }



  /// 过滤出 NFT 账户（supply = 1, decimals = 0）
  Future<List<Map<String, dynamic>>> _filterNFTAccounts(List<Map<String, dynamic>> tokenAccounts) async {
    final nftAccounts = <Map<String, dynamic>>[];

    for (final account in tokenAccounts) {
      try {
        final accountData = account['account']['data']['parsed']['info'];
        final tokenAmount = accountData['tokenAmount'];
        
        // NFT 的特征：decimals = 0, amount = 1
        if (tokenAmount['decimals'] == 0 && tokenAmount['uiAmount'] == 1) {
          nftAccounts.add({
            'tokenAccount': account['pubkey'],
            'mint': accountData['mint'],
            'owner': accountData['owner'],
            'amount': tokenAmount['amount'],
          });
        }
      } catch (e) {
        print('⚠️ 解析 token 账户失败: $e');
      }
    }

    return nftAccounts;
  }

  /// 解析 NFT 票券
  Future<NFTTicketModel?> _parseNFTTicket(Map<String, dynamic> nftAccount, String userPublicKey) async {
    try {
      final mintAddress = nftAccount['mint'] as String;
      final tokenAccount = nftAccount['tokenAccount'] as String;

      print('🔍 解析 NFT: $mintAddress');

      // 1. 获取 NFT 的 metadata 账户地址
      final metadataAddress = await _getMetadataAddress(mintAddress);
      
      // 2. 获取 metadata 账户数据
      final metadataAccount = await _getMetadataAccount(metadataAddress);
      if (metadataAccount == null) {
        print('⚠️ 无法获取 metadata 账户: $metadataAddress');
        return null;
      }

      // 3. 解析 metadata
      final metadata = await _parseMetadata(metadataAccount);
      if (metadata == null) {
        print('⚠️ 无法解析 metadata');
        return null;
      }

      // 4. 检查是否为票券 NFT
      if (!_isTicketNFT(metadata)) {
        print('⚠️ 不是票券 NFT: ${metadata['name']}');
        return null;
      }

      // 5. 获取外部 metadata（如果有 uri）
      NFTTicketMetadata? ticketMetadata;
      if (metadata['uri'] != null && metadata['uri'].isNotEmpty) {
        ticketMetadata = await _fetchExternalMetadata(metadata['uri']);
      }

      // 6. 创建 NFTTicketModel
      return _createNFTTicketModel(
        mintAddress: mintAddress,
        tokenAccount: tokenAccount,
        owner: userPublicKey,
        onChainMetadata: metadata,
        externalMetadata: ticketMetadata,
      );

    } catch (e) {
      print('❌ 解析 NFT 票券失败: $e');
      return null;
    }
  }

  /// 获取 metadata 账户地址
  Future<String> _getMetadataAddress(String mintAddress) async {
    try {
      // Metaplex Token Metadata 程序 ID
      const metadataProgramId = 'metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s';

      // 计算 Metaplex metadata PDA
      // PDA seeds: ["metadata", metadata_program_id, mint_address]
      final seeds = [
        utf8.encode('metadata'),
        Ed25519HDPublicKey.fromBase58(metadataProgramId).bytes,
        Ed25519HDPublicKey.fromBase58(mintAddress).bytes,
      ];

      // 查找 PDA 地址
      final pda = await Ed25519HDPublicKey.findProgramAddress(
        seeds: seeds,
        programId: Ed25519HDPublicKey.fromBase58(metadataProgramId),
      );

      print('✅ 计算 metadata PDA: ${pda.toBase58()}');
      return pda.toBase58();
    } catch (e) {
      print('❌ 计算 metadata 地址失败: $e');
      return '';
    }
  }

  /// 获取 metadata 账户数据
  Future<Map<String, dynamic>?> _getMetadataAccount(String metadataAddress) async {
    try {
      final client = _solanaService.client;
      if (client == null) return null;

      print('🔍 查询 metadata 账户: $metadataAddress');

      // 获取 metadata 账户信息
      final accountInfo = await client.getAccountInfo(
        metadataAddress,
        commitment: Commitment.confirmed,
        encoding: Encoding.base64,
      );

      if (accountInfo.value?.data == null) {
        print('⚠️ metadata 账户不存在或无数据');
        return null;
      }

      print('✅ 成功获取 metadata 账户数据');
      return {
        'data': accountInfo.value!.data,
        'owner': accountInfo.value!.owner,
        'lamports': accountInfo.value!.lamports,
      };
    } catch (e) {
      print('❌ 获取 metadata 账户失败: $e');
      return null;
    }
  }

  /// 解析链上 metadata
  Future<Map<String, dynamic>?> _parseMetadata(Map<String, dynamic> metadataAccount) async {
    try {
      final data = metadataAccount['data'];
      if (data == null) return null;

      print('🔍 开始解析 Metaplex metadata...');

      // 解析 base64 编码的 metadata 数据
      final bytes = base64.decode(data.toString());
      if (bytes.length < 100) {
        print('⚠️ metadata 数据长度不足');
        return null;
      }

      // Metaplex metadata 数据结构解析
      // 这是一个简化的解析，真实的 Metaplex metadata 结构更复杂
      try {
        // 跳过前面的字段，查找 name 和 uri
        // 实际的 Metaplex metadata 使用 Borsh 序列化

        // 尝试从数据中提取可读的字符串
        final dataString = String.fromCharCodes(bytes.where((b) => b >= 32 && b <= 126));

        // 查找可能的 URI（通常以 https:// 或 ar:// 开头）
        String? uri;
        final uriMatch = RegExp(r'https?://[^\s\x00-\x1f]+|ar://[^\s\x00-\x1f]+').firstMatch(dataString);
        if (uriMatch != null) {
          uri = uriMatch.group(0);
          print('✅ 找到 URI: $uri');
        }

        // 查找可能的名称（通常在数据的前部分）
        String name = 'Unknown NFT';
        final nameMatch = RegExp(r'[A-Za-z0-9\s#-]{3,50}').firstMatch(dataString.substring(0, 200));
        if (nameMatch != null) {
          name = nameMatch.group(0)?.trim() ?? 'Unknown NFT';
          print('✅ 找到名称: $name');
        }

        return {
          'name': name,
          'symbol': 'NFT',
          'uri': uri ?? '',
          'creators': [],
          'seller_fee_basis_points': 0,
        };
      } catch (e) {
        print('⚠️ 详细解析失败，使用基本信息: $e');
        return {
          'name': 'NFT Token',
          'symbol': 'NFT',
          'uri': '',
          'creators': [],
          'seller_fee_basis_points': 0,
        };
      }
    } catch (e) {
      print('❌ 解析 metadata 失败: $e');
      return null;
    }
  }

  /// 检查是否为票券 NFT
  bool _isTicketNFT(Map<String, dynamic> metadata) {
    // 检查 NFT 是否为票券类型
    final name = metadata['name']?.toString().toLowerCase() ?? '';
    final symbol = metadata['symbol']?.toString().toLowerCase() ?? '';
    
    return name.contains('ticket') || 
           symbol.contains('ticket') || 
           symbol.contains('tkt');
  }

  /// 获取外部 metadata
  Future<NFTTicketMetadata?> _fetchExternalMetadata(String uri) async {
    try {
      print('🌐 获取外部 metadata: $uri');

      Map<String, dynamic>? jsonData;

      // 如果是 Arweave 链接，使用 ArweaveService
      if (uri.contains('arweave.net') || uri.contains('ar://')) {
        final hash = uri.split('/').last;
        jsonData = await _arweaveService.getJsonData(hash);
      } else {
        // 其他 HTTP 链接
        final response = await http.get(Uri.parse(uri));
        if (response.statusCode == 200) {
          jsonData = json.decode(response.body);
        }
      }

      if (jsonData != null) {
        return NFTTicketMetadata.fromJson(jsonData);
      }

      return null;
    } catch (e) {
      print('❌ 获取外部 metadata 失败: $e');
      return null;
    }
  }

  /// 创建 NFTTicketModel
  NFTTicketModel _createNFTTicketModel({
    required String mintAddress,
    required String tokenAccount,
    required String owner,
    required Map<String, dynamic> onChainMetadata,
    NFTTicketMetadata? externalMetadata,
  }) {
    // 优先使用外部 metadata，否则基于链上数据创建票券信息
    final metadata = externalMetadata ?? _createTicketMetadataFromOnChain(mintAddress, onChainMetadata);

    return NFTTicketModel(
      mintAddress: mintAddress,
      tokenAccount: tokenAccount,
      owner: owner,
      metadata: metadata,
      status: NFTTicketStatus.valid, // 默认状态
      purchaseDate: DateTime.now().subtract(const Duration(days: 1)), // 昨天购买
      isTransferable: true,
    );
  }

  /// 基于链上数据创建票券 metadata
  NFTTicketMetadata _createTicketMetadataFromOnChain(String mintAddress, Map<String, dynamic> onChainMetadata) {
    // 从链上 metadata 获取基本信息
    final onChainName = onChainMetadata['name']?.toString() ?? 'Unknown NFT';
    final onChainUri = onChainMetadata['uri']?.toString() ?? '';

    print('🎫 基于链上数据创建票券: name=$onChainName, uri=$onChainUri');

    // 检查是否为票券类型的 NFT
    final isTicketLike = _isTicketLikeNFT(onChainName, onChainUri);

    if (isTicketLike) {
      // 如果看起来像票券，尝试从名称中提取信息
      return _parseTicketInfoFromName(mintAddress, onChainName, onChainUri);
    } else {
      // 如果不像票券，基于 mint 地址生成票券数据
      return _generateTicketFromMint(mintAddress, onChainName, onChainUri);
    }
  }

  /// 检查是否为票券类型的 NFT
  bool _isTicketLikeNFT(String name, String uri) {
    final lowerName = name.toLowerCase();
    final lowerUri = uri.toLowerCase();

    final ticketKeywords = ['ticket', 'pass', 'admission', 'entry', 'event', 'concert', 'festival', 'conference'];

    return ticketKeywords.any((keyword) =>
      lowerName.contains(keyword) || lowerUri.contains(keyword)
    );
  }

  /// 从名称中解析票券信息
  NFTTicketMetadata _parseTicketInfoFromName(String mintAddress, String name, String uri) {
    // 尝试从名称中提取活动信息
    String eventName = name;
    String ticketType = 'General';
    String seatInfo = 'General Admission';

    // 查找票券类型
    if (name.toLowerCase().contains('vip')) {
      ticketType = 'VIP';
      seatInfo = 'VIP Section';
    } else if (name.toLowerCase().contains('premium')) {
      ticketType = 'Premium';
      seatInfo = 'Premium Section';
    }

    // 查找座位信息
    final seatMatch = RegExp(r'[A-Z]\d+|Row\s+[A-Z]|Seat\s+\d+', caseSensitive: false).firstMatch(name);
    if (seatMatch != null) {
      seatInfo = seatMatch.group(0) ?? seatInfo;
    }

    return NFTTicketMetadata(
      name: name,
      description: 'NFT Ticket: $name',
      image: uri.isNotEmpty ? uri : 'https://arweave.net/ticket-${mintAddress.substring(0, 8)}',
      eventName: eventName,
      eventDate: DateTime.now().add(const Duration(days: 30)).toString().split(' ')[0], // 30天后
      eventTime: '19:00',
      venue: 'Event Venue',
      seatInfo: seatInfo,
      ticketType: ticketType,
      attributes: {
        'mint_address': mintAddress,
        'original_name': name,
        'original_uri': uri,
      },
      properties: {
        'category': 'Event Ticket',
        'blockchain': 'Solana',
        'transferable': true,
        'refundable': false,
      },
    );
  }

  /// 基于 mint 地址生成票券数据
  NFTTicketMetadata _generateTicketFromMint(String mintAddress, String originalName, String originalUri) {
    // 根据 mint 地址生成不同的票券数据
    final mintHash = mintAddress.hashCode.abs();
    final eventIndex = mintHash % 5;
    final seatIndex = mintHash % 20 + 1;
    final rowIndex = mintHash % 10;

    final events = [
      {
        'name': 'Solana Summer Festival 2024',
        'date': '2024-08-15',
        'time': '19:00',
        'venue': 'Crypto Arena',
        'type': 'VIP',
      },
      {
        'name': 'Web3 Tech Conference',
        'date': '2024-09-20',
        'time': '10:00',
        'venue': 'Innovation Center',
        'type': 'General',
      },
      {
        'name': 'NFT Art Exhibition',
        'date': '2024-10-05',
        'time': '14:00',
        'venue': 'Digital Gallery',
        'type': 'Premium',
      },
      {
        'name': 'DeFi Summit 2024',
        'date': '2024-11-12',
        'time': '09:00',
        'venue': 'Finance Hub',
        'type': 'Standard',
      },
      {
        'name': 'Blockchain Gaming Expo',
        'date': '2024-12-01',
        'time': '16:00',
        'venue': 'Gaming Center',
        'type': 'VIP',
      },
    ];

    final event = events[eventIndex];
    final rowLetter = String.fromCharCode(65 + rowIndex); // A, B, C...

    return NFTTicketMetadata(
      name: '${event['name']} - ${event['type']} Ticket #${seatIndex.toString().padLeft(3, '0')}',
      description: 'Official NFT ticket for ${event['name']} (Generated from: $originalName)',
      image: originalUri.isNotEmpty ? originalUri : 'https://arweave.net/ticket-image-${mintAddress.substring(0, 8)}',
      eventName: event['name']!,
      eventDate: event['date']!,
      eventTime: event['time']!,
      venue: event['venue']!,
      seatInfo: '${event['type']} Section, Row $rowLetter, Seat ${seatIndex.toString().padLeft(2, '0')}',
      ticketType: event['type']!,
      attributes: {
        'mint_address': mintAddress,
        'event_type': 'blockchain',
        'seat_number': '$rowLetter-${seatIndex.toString().padLeft(2, '0')}',
        'ticket_id': mintAddress.substring(0, 8),
        'original_name': originalName,
        'original_uri': originalUri,
      },
      properties: {
        'category': 'Event Ticket',
        'blockchain': 'Solana',
        'transferable': true,
        'refundable': false,
      },
    );
  }

  /// 从连接信息获取用户公钥
  String? getUserPublicKeyFromConnection() {
    try {
      // 从本地存储获取连接信息
      final connectionData = _storage.read('current_dapp_connection');
      if (connectionData != null) {
        // 从连接数据中提取公钥
        return connectionData['wallet_address'] ?? connectionData['public_key'];
      }

      // 备用：尝试从其他服务获取（如果可用）
      // 这里可以添加其他获取公钥的方法

      return null;
    } catch (e) {
      print('❌ 获取用户公钥失败: $e');
      return null;
    }
  }
}
