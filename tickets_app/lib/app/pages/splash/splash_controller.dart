import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../controllers/solana_controller.dart';
import '../../services/mobile_wallet_service.dart';
import '../../models/wallet_request_model.dart';
import '../../routes/app_routes.dart';

class SplashController extends GetxController {
  final solanaController = Get.find<SolanaController>();
  final walletService = Get.find<MobileWalletService>();
  final storage = GetStorage();

  // 状态变量
  final RxBool isLoading = false.obs;
  final RxBool isDAppConnected = false.obs;
  final RxString connectedDAppName = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeApp();
  }

  /// 初始化应用
  void _initializeApp() async {
    try {
      // 延迟一下让启动画面显示
      await Future.delayed(const Duration(seconds: 2));

      // 1. 初始化钱包服务
      await _initializeWallet();

      // 2. 检查本地保存的连接信息
      await _checkSavedConnections();

      // 3. 如果已连接，直接跳转到主页
      if (isDAppConnected.value && solanaController.isConnected) {
        print('✅ 检测到已保存的连接，直接跳转到主页');
        Get.offAllNamed(AppRoutes.home);
      }
    } catch (e) {
      print('❌ 应用初始化失败: $e');
    }
  }

  /// 初始化钱包
  Future<void> _initializeWallet() async {
    try {
      // MobileWalletService 在 onInit 中自动初始化
      // 这里只需要等待初始化完成
      if (walletService.isInitialized) {
        print('✅ 钱包已初始化完成');
      } else {
        print('⏳ 等待钱包初始化...');
        // 等待一段时间让钱包服务完成初始化
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      print('❌ 钱包初始化失败: $e');
    }
  }

  /// 检查本地保存的连接信息
  Future<void> _checkSavedConnections() async {
    try {
      // 读取连接状态
      final isConnected = storage.read('is_dapp_connected') ?? false;
      final dappName = storage.read('connected_dapp_name') ?? '';
      final sessionId = storage.read('connection_session_id') ?? '';

      if (isConnected && dappName.isNotEmpty && sessionId.isNotEmpty) {
        isDAppConnected.value = true;
        connectedDAppName.value = dappName;
        print('📱 检测到已连接的 DApp: $dappName');
        print('🔗 会话ID: $sessionId');
      } else {
        print('📱 未检测到已保存的连接');
      }
    } catch (e) {
      print('❌ 检查连接信息失败: $e');
    }
  }

  /// 连接钱包 - 跳转到 DApp 连接授权页面
  Future<void> connectWallet() async {
    try {
      isLoading.value = true;

      // 1. 确保钱包已初始化
      if (!walletService.isInitialized) {
        throw Exception('钱包未初始化，请稍后重试');
      }

      print('🔗 开始 DApp 连接流程...');

      // 2. 创建连接请求
      final connectionRequest = ConnectionRequest(
        dappName: 'Solana Tickets App',
        dappUrl: 'https://tickets.solana.com',
        identityName: 'Solana Tickets Platform',
        identityUri: 'https://tickets.solana.com',
        cluster: 'devnet', // 使用 devnet 进行真实测试
      );

      // 3. 跳转到连接授权页面
      final result = await Get.toNamed(
        '/dapp-connection-request',
        arguments: connectionRequest,
      );

      // 4. 处理连接结果
      if (result == RequestResult.approved) {
        print('✅ DApp 连接授权成功');

        // 更新本地状态
        await _checkSavedConnections();

        // 跳转到主页
        Get.offAllNamed(AppRoutes.home);
      } else {
        print('❌ DApp 连接被拒绝或取消');
        Get.snackbar(
          '连接取消',
          '用户取消了钱包连接',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      print('❌ 连接钱包失败: $e');
      Get.snackbar(
        '连接失败',
        '无法连接钱包: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// 断开连接
  Future<void> disconnectWallet() async {
    try {
      // 清除本地保存的连接信息
      await storage.remove('is_dapp_connected');
      await storage.remove('connected_dapp_name');
      await storage.remove('connected_dapp_url');
      await storage.remove('connection_session_id');
      await storage.remove('current_dapp_connection');
      await storage.remove('dapp_permissions');

      // 更新状态
      isDAppConnected.value = false;
      connectedDAppName.value = '';

      print('✅ 钱包连接已断开');
      Get.snackbar(
        '断开成功',
        '钱包连接已断开',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('❌ 断开连接失败: $e');
    }
  }
}
