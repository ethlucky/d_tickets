import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:solana/solana.dart';
import 'package:solana/dto.dart';
import 'package:solana/encoder.dart';
import 'package:solana_mobile_client/solana_mobile_client.dart';
import 'package:bs58/bs58.dart';
import '../../models/wallet_request_model.dart';
import '../../services/mobile_wallet_service.dart';
import '../../utils/transaction_builder.dart';

/// 交易记录模型
class TransactionRecord {
  final String type;
  final String signature;
  final String timestamp;
  final String status;

  TransactionRecord({
    required this.type,
    required this.signature,
    required this.timestamp,
    required this.status,
  });
}

/// Solana Mobile Wallet Adapter 演示控制器
class SolanaWalletDemoController extends GetxController {
  // Solana 客户端
  late SolanaClient _solanaClient;

  // 钱包连接状态
  bool _isWalletConnected = false;
  String _walletAddress = '';
  double _solBalance = 0.0;
  bool _isLoading = false;

  // 授权结果
  AuthorizationResult? _authResult;

  // 交易历史
  final List<TransactionRecord> _transactionHistory = [];

  // 连接类型
  String _connectionType = '';

  // DApp 连接状态
  bool _isDAppConnected = false;
  String _connectedDAppName = '';
  String _connectedDAppUrl = '';
  String _connectionSessionId = '';

  // Getters
  bool get isLoading => _isLoading;
  bool get isWalletConnected => _isWalletConnected;
  String get walletAddress => _walletAddress;
  double get solBalance => _solBalance;
  String get connectionType => _connectionType;
  List<TransactionRecord> get transactionHistory => _transactionHistory;

  // DApp 连接状态 getters
  bool get isDAppConnected => _isDAppConnected;
  String get connectedDAppName => _connectedDAppName;
  String get connectedDAppUrl => _connectedDAppUrl;
  String get connectionSessionId => _connectionSessionId;

  @override
  void onInit() {
    super.onInit();

    // 根据平台配置 Solana 客户端
    String rpcUrl;
    String wsUrl;

    if (GetPlatform.isAndroid) {
      // Android 模拟器：10.0.2.2 映射到宿主机的 127.0.0.1
      rpcUrl = "http://10.0.2.2:8899";
      wsUrl = "ws://10.0.2.2:8900";
      print('📱 [控制器] Android 平台，使用宿主机地址: $rpcUrl');
    } else {
      // iOS 模拟器或其他平台
      rpcUrl = "http://127.0.0.1:8899";
      wsUrl = "ws://127.0.0.1:8900";
      print('📱 [控制器] iOS/其他平台，使用本地地址: $rpcUrl');
    }

    _solanaClient = SolanaClient(
      rpcUrl: Uri.parse(rpcUrl),
      websocketUrl: Uri.parse(wsUrl),
    );
    _checkWalletAvailability();
    _loadDAppConnectionStatus();
  }

  /// 检查 MWA 兼容钱包可用性
  Future<void> _checkWalletAvailability() async {
    try {
      final isAvailable = await LocalAssociationScenario.isAvailable();
      if (!isAvailable) {
        Get.snackbar(
          '钱包不可用',
          '未找到兼容的 MWA 钱包，请安装 Phantom 或 Solflare 等钱包',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      // 检查钱包可用性时出错: $e
    }
  }

  /// 连接钱包
  Future<void> connectWallet() async {
    try {
      _setLoading(true);

      // 方式1: 尝试使用 MWA 连接
      bool mwaConnected = await _tryMWAConnection();

      if (!mwaConnected) {
        // 方式2: 使用本地钱包服务作为备选
        bool localConnected = await _tryLocalWalletConnection();

        if (!localConnected) {
          throw Exception('无法连接钱包：未找到兼容的钱包或服务');
        }
      }

      // 刷新余额
      await refreshBalance();

      Get.snackbar(
        '连接成功',
        '钱包已成功连接',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        '连接失败',
        '连接钱包失败: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _setLoading(false);
    }
  }

  /// 尝试 MWA 连接
  Future<bool> _tryMWAConnection() async {
    try {
      // 检查钱包可用性
      if (!await LocalAssociationScenario.isAvailable()) {
        print('MWA 不可用，尝试其他连接方式');
        return false;
      }

      // 创建本地关联场景
      final scenario = await LocalAssociationScenario.create();

      // 启动活动结果
      scenario.startActivityForResult(null).ignore();

      // 启动场景并获取客户端
      final client = await scenario.start();

      // 授权
      final result = await client.authorize(
        identityUri: Uri.parse('https://tickets-app.com'),
        iconUri: Uri.parse('favicon.ico'),
        identityName: 'Tickets App',
        cluster: 'devnet',
      );

      // 关闭场景
      scenario.close();

      if (result != null) {
        // 保存授权结果
        _authResult = result;
        _walletAddress = base58.encode(result.publicKey);
        _isWalletConnected = true;
        _connectionType = 'MWA';
        return true;
      }
      return false;
    } catch (e) {
      print('MWA 连接失败: $e');
      return false;
    }
  }

  /// 尝试本地钱包连接
  Future<bool> _tryLocalWalletConnection() async {
    try {
      final mobileWalletService = Get.find<MobileWalletService>();

      if (!mobileWalletService.isInitialized) {
        print('本地钱包服务未初始化');
        return false;
      }

      // 使用本地钱包服务
      _walletAddress = mobileWalletService.publicKey;
      _isWalletConnected = true;
      _connectionType = '本地钱包';

      // 刷新余额
      _solBalance = mobileWalletService.balance;

      return true;
    } catch (e) {
      print('本地钱包连接失败: $e');
      return false;
    }
  }

  /// 断开钱包连接
  void disconnectWallet() {
    _isWalletConnected = false;
    _walletAddress = '';
    _solBalance = 0.0;
    _authResult = null;
    _transactionHistory.clear();

    update();

    Get.snackbar(
      '已断开连接',
      '钱包连接已断开',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// 请求空投
  Future<void> requestAirdrop() async {
    if (!_isWalletConnected) {
      Get.snackbar('错误', '请先连接钱包', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      _setLoading(true);

      String? signature;
      Ed25519HDPublicKey? publicKey;

      if (_connectionType == 'MWA' && _authResult != null) {
        // MWA 连接的空投
        publicKey = Ed25519HDPublicKey(_authResult!.publicKey.toList());
      } else if (_connectionType == '本地钱包') {
        // 本地钱包的空投
        final mobileWalletService = Get.find<MobileWalletService>();
        publicKey =
            Ed25519HDPublicKey.fromBase58(mobileWalletService.publicKey);
      }

      if (publicKey != null) {
        // 请求空投 1 SOL
        const lamportsPerSol = 1000000000;
        signature = await _solanaClient.requestAirdrop(
          address: publicKey,
          lamports: 1 * lamportsPerSol,
        );
      }

      // 添加到交易历史
      _addTransactionRecord(
        type: '空投',
        signature: signature ?? '',
        status: signature != null ? 'success' : 'failed',
      );

      if (signature != null) {
        // 等待确认并刷新余额
        await Future.delayed(const Duration(seconds: 2));
        await refreshBalance();

        Get.snackbar(
          '空投成功',
          '1 SOL 已空投到您的钱包',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('无法获取钱包地址');
      }
    } catch (e) {
      // 空投失败: $e
      _addTransactionRecord(
        type: '空投',
        signature: '',
        status: 'failed',
      );

      Get.snackbar(
        '空投失败',
        '空投失败: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _setLoading(false);
    }
  }

  /// 演示交易（简化版本）
  Future<void> sendTransaction() async {
    if (!_isWalletConnected) {
      Get.snackbar('错误', '请先连接钱包', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      _setLoading(true);

      // 模拟交易处理
      await Future.delayed(const Duration(seconds: 1));

      // 添加模拟交易记录
      _addTransactionRecord(
        type: '演示交易 (${_connectionType})',
        signature: 'demo_${DateTime.now().millisecondsSinceEpoch}',
        status: 'success',
      );

      Get.snackbar(
        '交易模拟完成',
        '这是一个演示交易，实际应用中需要实现真实的交易签名\n连接类型: $_connectionType',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      // 交易失败: $e
      _addTransactionRecord(
        type: '演示交易',
        signature: '',
        status: 'failed',
      );

      Get.snackbar(
        '交易失败',
        '交易失败: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _setLoading(false);
    }
  }

  /// 测试 DApp 连接请求 - 真实 DApp 连接
  Future<void> testConnectionRequest() async {
    try {
      print('🔗 开始真实 DApp 连接请求...');

      final result = await Get.toNamed(
        '/dapp-connection-request',
        arguments: ConnectionRequest(
          dappName: 'Solana Tickets App',
          dappUrl: 'https://tickets.solana.com',
          identityName: 'Solana Tickets Platform',
          identityUri: 'https://tickets.solana.com',
          cluster: 'devnet', // 使用 devnet 进行真实测试
        ),
      );

      if (result == RequestResult.approved) {
        print('✅ DApp 连接已批准');

        // 刷新 DApp 连接状态
        _loadDAppConnectionStatus();

        _addTransactionRecord(
          type: '真实 DApp 连接',
          signature: 'connection_${DateTime.now().millisecondsSinceEpoch}',
          status: 'success',
        );

        Get.snackbar(
          '连接成功',
          '真实 DApp 连接已建立',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else if (result == RequestResult.rejected) {
        print('❌ DApp 连接被拒绝');
        Get.snackbar(
          '连接拒绝',
          '用户拒绝了 DApp 连接',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      print('❌ DApp 连接失败: $e');
      Get.snackbar(
        '连接失败',
        '真实 DApp 连接失败: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// 测试 DApp 签名请求 - 真实 SOL 转账
  Future<void> testSignatureRequest() async {
    if (!_isWalletConnected) {
      Get.snackbar('错误', '请先连接钱包', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      print('🚀 开始创建真实的 SOL 转账交易...');

      // 目标地址
      const targetAddress = '2XM48QdtTv3dAHccUjVdZ2CF7Es3estfNRAqjjde8QdL';
      const transferAmount = 0.01; // 转账 0.01 SOL（测试用小额）

      // 1. 获取最新的区块哈希
      print('📡 获取最新区块哈希...');
      final recentBlockhash = await _getRecentBlockhash();
      print('✅ 区块哈希: $recentBlockhash');

      // 2. 创建真实的 SOL 转账交易
      print('🔨 构建 SOL 转账交易...');
      final transactionInfo = await TransactionBuilder.createSolTransfer(
        fromAddress: _walletAddress,
        toAddress: targetAddress,
        lamports: (transferAmount * 1000000000).toInt(), // 转换为 lamports
        recentBlockhash: recentBlockhash,
      );
      print('✅ 交易构建完成');

      // 3. 请求用户签名
      print('📝 请求用户签名...');
      final result = await Get.toNamed(
        '/dapp-signature-request',
        arguments: SignatureRequest(
          dappName: 'Solana Wallet Demo',
          dappUrl: 'https://solana-wallet-demo.com',
          transactions: [transactionInfo],
          message: '确认转账 $transferAmount SOL 到 $targetAddress',
        ),
      );

      if (result == RequestResult.approved) {
        _addTransactionRecord(
          type: '真实 SOL 转账 (${_connectionType})',
          signature: 'real_transfer_${DateTime.now().millisecondsSinceEpoch}',
          status: 'success',
        );

        // 刷新余额
        await refreshBalance();

        Get.snackbar(
          '转账成功',
          '真实 SOL 转账已完成，余额已刷新',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else if (result == RequestResult.rejected) {
        Get.snackbar(
          '转账取消',
          '用户取消了 SOL 转账',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      print('❌ 真实转账失败: $e');
      Get.snackbar(
        '转账失败',
        '真实 SOL 转账失败: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// 获取最新的区块哈希
  Future<String> _getRecentBlockhash() async {
    try {
      final response = await _solanaClient.rpcClient.getLatestBlockhash();
      return response.value.blockhash;
    } catch (e) {
      print('❌ 获取区块哈希失败: $e');
      throw Exception('获取区块哈希失败: $e');
    }
  }

  /// 检查目标地址余额
  Future<void> checkTargetBalance() async {
    const targetAddress = '2XM48QdtTv3dAHccUjVdZ2CF7Es3estfNRAqjjde8QdL';

    try {
      print('🔍 查询目标地址余额: $targetAddress');
      final balance = await _solanaClient.rpcClient.getBalance(targetAddress);
      final solBalance = balance.value / 1000000000;

      print('💰 目标地址当前余额: ${balance.value} lamports = $solBalance SOL');

      Get.snackbar(
        '余额查询',
        '目标地址余额: $solBalance SOL',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('❌ 查询目标地址余额失败: $e');
      Get.snackbar(
        '查询失败',
        '无法查询目标地址余额: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// 直接测试 SOL 转账（简化版本）
  Future<void> testDirectSolTransfer() async {
    if (!_isWalletConnected) {
      Get.snackbar('错误', '请先连接钱包', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    const targetAddress = '2XM48QdtTv3dAHccUjVdZ2CF7Es3estfNRAqjjde8QdL';
    const transferAmount = 0.01; // 0.01 SOL

    try {
      print('🚀 开始直接 SOL 转账测试...');

      // 获取钱包服务
      final mobileWalletService = Get.find<MobileWalletService>();

      // 获取最新区块哈希
      final recentBlockhash = await _getRecentBlockhash();
      print('✅ 获取区块哈希: $recentBlockhash');

      // 创建转账指令
      final instruction = SystemInstruction.transfer(
        fundingAccount: Ed25519HDPublicKey.fromBase58(_walletAddress),
        recipientAccount: Ed25519HDPublicKey.fromBase58(targetAddress),
        lamports: (transferAmount * 1000000000).toInt(),
      );
      print('✅ 创建转账指令完成');

      // 创建交易消息
      final message = Message(instructions: [instruction]);

      // 编译交易
      final compiledMessage = message.compile(
        recentBlockhash: recentBlockhash,
        feePayer: Ed25519HDPublicKey.fromBase58(_walletAddress),
      );
      print('✅ 编译交易完成');

      // 签名交易
      final signature = await mobileWalletService.keyPair.sign(compiledMessage.toByteArray());
      print('✅ 签名交易完成');

      // 构造已签名交易
      final publicKey = mobileWalletService.keyPair.publicKey;

      final signedTx = SignedTx(
        compiledMessage: compiledMessage,
        signatures: [Signature(signature.bytes, publicKey: publicKey)],
      );

      // 发送交易
      final txSignature = await _solanaClient.rpcClient.sendTransaction(
        signedTx.encode(),
        encoding: Encoding.base64,
        preflightCommitment: Commitment.confirmed,
      );

      print('✅ 交易发送成功: $txSignature');

      // 刷新余额
      await refreshBalance();

      Get.snackbar(
        '转账成功',
        '直接 SOL 转账成功！\n交易签名: $txSignature',
        snackPosition: SnackPosition.BOTTOM,
      );

    } catch (e) {
      print('❌ 直接 SOL 转账失败: $e');
      Get.snackbar(
        '转账失败',
        '直接 SOL 转账失败: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// 刷新余额
  Future<void> refreshBalance() async {
    if (!_isWalletConnected) return;

    try {
      print('🔄 [钱包控制器] 开始刷新余额，连接类型: $_connectionType');

      if (_connectionType == 'MWA' && _authResult != null) {
        // MWA 连接的余额刷新
        final publicKey = Ed25519HDPublicKey(_authResult!.publicKey.toList());
        print('📍 [MWA] 查询地址: ${publicKey.toBase58()}');

        final balance =
            await _solanaClient.rpcClient.getBalance(publicKey.toBase58());
        _solBalance = balance.value / 1000000000; // 转换为 SOL

        print('✅ [MWA] 余额查询成功: ${balance.value} lamports = $_solBalance SOL');
      } else if (_connectionType == '本地钱包') {
        // 本地钱包的余额刷新
        final mobileWalletService = Get.find<MobileWalletService>();
        print('📍 [本地钱包] 查询地址: ${mobileWalletService.publicKey}');

        await mobileWalletService.refreshBalance();
        _solBalance = mobileWalletService.balance;

        print('✅ [本地钱包] 余额更新完成: $_solBalance SOL');
      }

      update();
      print('🔄 [钱包控制器] UI更新完成');
    } catch (e) {
      print('❌ [钱包控制器] 刷新余额失败: $e');
    }
  }

  /// 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    update();
  }

  /// 添加交易记录
  void _addTransactionRecord({
    required String type,
    required String signature,
    required String status,
  }) {
    _transactionHistory.insert(
        0,
        TransactionRecord(
          type: type,
          signature: signature,
          timestamp: DateTime.now().toString().substring(0, 19),
          status: status,
        ));
    update();
  }

  /// 加载 DApp 连接状态
  void _loadDAppConnectionStatus() {
    try {
      final storage = GetStorage();

      _isDAppConnected = storage.read('is_dapp_connected') ?? false;
      _connectedDAppName = storage.read('connected_dapp_name') ?? '';
      _connectedDAppUrl = storage.read('connected_dapp_url') ?? '';
      _connectionSessionId = storage.read('connection_session_id') ?? '';

      if (_isDAppConnected) {
        print('📱 检测到已连接的 DApp: $_connectedDAppName');
        print('🔗 会话ID: $_connectionSessionId');
      }

      update();
    } catch (e) {
      print('❌ 加载 DApp 连接状态失败: $e');
    }
  }

  /// 断开 DApp 连接
  Future<void> disconnectDApp() async {
    try {
      print('🔌 开始断开 DApp 连接...');

      final storage = GetStorage();

      // 清除连接状态
      await storage.remove('is_dapp_connected');
      await storage.remove('connected_dapp_name');
      await storage.remove('connected_dapp_url');
      await storage.remove('connection_session_id');
      await storage.remove('current_dapp_connection');
      await storage.remove('dapp_permissions');

      // 更新本地状态
      _isDAppConnected = false;
      _connectedDAppName = '';
      _connectedDAppUrl = '';
      _connectionSessionId = '';

      print('✅ DApp 连接已断开');

      Get.snackbar(
        'DApp 连接已断开',
        '已成功断开与 DApp 的连接',
        snackPosition: SnackPosition.BOTTOM,
      );

      update();
    } catch (e) {
      print('❌ 断开 DApp 连接失败: $e');
      Get.snackbar(
        '断开连接失败',
        '断开 DApp 连接时出错: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// 刷新 DApp 连接状态
  void refreshDAppConnectionStatus() {
    _loadDAppConnectionStatus();
  }

  /// 获取连接状态显示文本
  String get connectionStatusText {
    if (_isDAppConnected) {
      return '已连接到 $_connectedDAppName';
    } else if (_isWalletConnected) {
      return '钱包已连接，等待 DApp 连接';
    } else {
      return '未连接';
    }
  }

}
