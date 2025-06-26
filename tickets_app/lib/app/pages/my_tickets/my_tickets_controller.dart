import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../models/nft_ticket_model.dart';
import '../../services/nft_service.dart';
import '../../services/solana_service.dart';

/// 票券状态枚举（保持向后兼容）
enum TicketStatus { valid, redeemed, refunded, availableForResale }

/// 票券数据模型（保持向后兼容）
class TicketModel {
  final String id;
  final String eventName;
  final String date;
  final String time;
  final String venue;
  final String seatInfo;
  final TicketStatus status;
  final String imageUrl;

  TicketModel({
    required this.id,
    required this.eventName,
    required this.date,
    required this.time,
    required this.venue,
    required this.seatInfo,
    required this.status,
    required this.imageUrl,
  });

  String get statusText {
    switch (status) {
      case TicketStatus.valid:
        return 'Valid';
      case TicketStatus.redeemed:
        return 'Redeemed';
      case TicketStatus.refunded:
        return 'Refunded';
      case TicketStatus.availableForResale:
        return 'Available for Resale';
    }
  }

  String get fullDateTimeVenue => '$date · $time · $venue · $seatInfo';

  /// 从 NFTTicketModel 转换为 TicketModel（向后兼容）
  factory TicketModel.fromNFTTicket(NFTTicketModel nftTicket) {
    return TicketModel(
      id: nftTicket.mintAddress,
      eventName: nftTicket.metadata.eventName,
      date: nftTicket.metadata.eventDate,
      time: nftTicket.metadata.eventTime,
      venue: nftTicket.metadata.venue,
      seatInfo: nftTicket.metadata.seatInfo,
      status: _convertNFTStatus(nftTicket.status),
      imageUrl: nftTicket.metadata.image,
    );
  }

  /// 转换 NFT 状态到旧的状态枚举
  static TicketStatus _convertNFTStatus(NFTTicketStatus nftStatus) {
    switch (nftStatus) {
      case NFTTicketStatus.valid:
        return TicketStatus.valid;
      case NFTTicketStatus.redeemed:
        return TicketStatus.redeemed;
      case NFTTicketStatus.refunded:
        return TicketStatus.refunded;
      case NFTTicketStatus.availableForResale:
        return TicketStatus.availableForResale;
      case NFTTicketStatus.expired:
        return TicketStatus.redeemed; // 过期视为已使用
      case NFTTicketStatus.transferred:
        return TicketStatus.redeemed; // 已转让视为已使用
    }
  }
}

/// 我的票券页面控制器
class MyTicketsController extends GetxController {
  // 服务依赖 - 使用延迟初始化
  NFTService? _nftService;
  SolanaService? _solanaService;
  final GetStorage _storage = GetStorage();

  // 状态变量
  final RxBool isLoading = false.obs;
  final RxString userPublicKey = ''.obs;
  final RxString walletId = ''.obs;

  // NFT 票券列表
  final RxList<NFTTicketModel> nftTickets = <NFTTicketModel>[].obs;

  // 兼容性票券列表（用于现有 UI）
  final RxList<TicketModel> tickets = <TicketModel>[].obs;

  // 错误信息
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeController();
  }

  /// 初始化控制器
  Future<void> _initializeController() async {
    try {
      print('🎫 初始化我的票券页面...');

      // 1. 初始化服务依赖
      await _initializeServices();

      // 2. 获取用户公钥
      await _getUserPublicKey();

      // 3. 加载用户的 NFT 票券
      if (userPublicKey.value.isNotEmpty) {
        await loadUserTickets();
      } else {
        errorMessage.value = '未找到连接的钱包地址';
        print('❌ 未找到用户公钥');
      }
    } catch (e) {
      errorMessage.value = '初始化失败: $e';
      print('❌ 控制器初始化失败: $e');
    }
  }

  /// 初始化服务依赖
  Future<void> _initializeServices() async {
    try {
      // 确保服务已经注册，如果没有则注册
      if (!Get.isRegistered<NFTService>()) {
        Get.put<NFTService>(NFTService());
      }
      if (!Get.isRegistered<SolanaService>()) {
        Get.put<SolanaService>(SolanaService());
      }

      // 获取服务实例
      _nftService = Get.find<NFTService>();
      _solanaService = Get.find<SolanaService>();

      print('✅ 服务依赖初始化完成');
    } catch (e) {
      print('❌ 服务依赖初始化失败: $e');
      // 即使服务初始化失败，也要继续执行，使用模拟数据
    }
  }

  /// 获取用户公钥
  Future<void> _getUserPublicKey() async {
    try {
      String? publicKey;

      // 1. 从连接信息获取
      if (_nftService != null) {
        publicKey = _nftService!.getUserPublicKeyFromConnection();
      }

      // 2. 从 Solana 服务获取
      if ((publicKey == null || publicKey.isEmpty) && _solanaService != null) {
        publicKey = _solanaService!.publicKey;
      }

      // 3. 使用测试钱包地址作为后备
      if (publicKey == null || publicKey.isEmpty) {
        publicKey = '2XM48QdtTv3dAHccUjVdZ2CF7Es3estfNRAqjjde8QdL';
        print('⚠️ 使用测试钱包地址: $publicKey');
      }

      userPublicKey.value = publicKey;
      walletId.value = '${publicKey.substring(0, 4)}...${publicKey.substring(publicKey.length - 4)}';

      print('✅ 用户公钥: $publicKey');
      print('📱 钱包ID: ${walletId.value}');
    } catch (e) {
      print('❌ 获取用户公钥失败: $e');
      // 设置默认测试钱包地址
      userPublicKey.value = '2XM48QdtTv3dAHccUjVdZ2CF7Es3estfNRAqjjde8QdL';
      walletId.value = '2XM4...8QdL';
    }
  }

  /// 加载用户票券
  Future<void> loadUserTickets() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      print('🔍 开始加载用户票券...');
      print('👤 用户公钥: ${userPublicKey.value}');

      List<NFTTicketModel> userNFTTickets = [];

      // 1. 查询用户的 NFT 票券（如果服务可用）
      if (_nftService != null) {
        try {
          userNFTTickets = await _nftService!.getUserNFTTickets(userPublicKey.value);
          print('🎫 查询到 ${userNFTTickets.length} 个 NFT 票券');
        } catch (e) {
          print('⚠️ NFT 查询失败: $e');
        }
      } else {
        print('⚠️ NFTService 不可用，跳过 NFT 查询');
      }

      // 2. 更新 NFT 票券列表
      nftTickets.assignAll(userNFTTickets);

      // 3. 转换为兼容格式（用于现有 UI）
      final compatibleTickets = userNFTTickets.map((nft) => TicketModel.fromNFTTicket(nft)).toList();
      tickets.assignAll(compatibleTickets);

      // 4. 如果没有找到票券，显示空列表
      if (userNFTTickets.isEmpty) {
        print('⚠️ 该钱包地址没有找到任何 NFT 票券');
        errorMessage.value = '该钱包地址没有找到任何 NFT 票券';
      }

      print('✅ 票券加载完成，共 ${tickets.length} 张票券');
    } catch (e) {
      errorMessage.value = '加载票券失败: $e';
      print('❌ 加载用户票券失败: $e');

      // 不再使用模拟数据，保持空列表
      tickets.clear();
      nftTickets.clear();
    } finally {
      isLoading.value = false;
    }
  }



  /// 刷新票券列表
  Future<void> refreshTickets() async {
    await loadUserTickets();
  }

  /// 点击票券
  void onTicketTap(TicketModel ticket) {
    // 如果是真实的 NFT 票券，传递 NFT 数据
    NFTTicketModel? nftTicket;
    try {
      nftTicket = nftTickets.firstWhereOrNull((nft) => nft.mintAddress == ticket.id);
    } catch (e) {
      print('⚠️ 查找 NFT 票券失败: $e');
    }

    if (nftTicket != null) {
      Get.toNamed('/ticket-details-demo', arguments: nftTicket);
    } else {
      Get.toNamed('/ticket-details-demo', arguments: ticket);
    }
  }

  /// 底部导航 - 首页
  void onHomeTap() {
    Get.offAllNamed('/');
  }

  /// 底部导航 - 探索
  void onExploreTap() {
    Get.toNamed('/events');
  }

  /// 底部导航 - 我的票券（当前页面）
  void onMyTicketsTap() {
    // 当前页面，无需操作
  }

  /// 底部导航 - 个人资料
  void onProfileTap() {
    Get.toNamed('/account-settings-demo');
  }
}
