import 'package:get/get.dart';
import '../services/solana_service.dart';

/// Solana控制器 - 管理Solana相关的状态
class SolanaController extends GetxController {
  final SolanaService _solanaService = Get.find<SolanaService>();

  // 响应式状态变量
  final RxString _publicKey = ''.obs;
  final RxDouble _balance = 0.0.obs;
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;
  final RxBool _isConnected = false.obs;

  // Getters
  String get publicKey => _publicKey.value;
  double get balance => _balance.value;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  bool get isConnected => _isConnected.value;

  @override
  void onInit() {
    super.onInit();
    // 控制器初始化时自动连接
    initialize();
  }

  /// 初始化Solana连接
  Future<void> initialize() async {
    try {
      _isLoading.value = true;
      _error.value = '';

      await _solanaService.initialize();
      _isConnected.value = true;

      // 显示成功消息
      Get.snackbar(
        '连接成功',
        '已连接到Solana Devnet',
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      _error.value = e.toString();
      _isConnected.value = false;

      // 显示错误消息
      Get.snackbar('连接失败', e.toString(), snackPosition: SnackPosition.TOP);
    } finally {
      _isLoading.value = false;
    }
  }

  /// 生成新钱包
  Future<void> generateWallet() async {
    try {
      _isLoading.value = true;
      _error.value = '';

      final publicKey = await _solanaService.generateWallet();
      _publicKey.value = publicKey;

      // 生成钱包后自动获取余额
      await updateBalance();

      // 显示成功消息
      Get.snackbar(
        '钱包生成成功',
        '钱包地址: ${publicKey.substring(0, 8)}...',
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      _error.value = e.toString();

      // 显示错误消息
      Get.snackbar('钱包生成失败', e.toString(), snackPosition: SnackPosition.TOP);
    } finally {
      _isLoading.value = false;
    }
  }

  /// 更新余额
  Future<void> updateBalance() async {
    if (!_isConnected.value || _publicKey.value.isEmpty) return;

    try {
      final balance = await _solanaService.getBalance();
      _balance.value = balance;
    } catch (e) {
      _error.value = e.toString();
    }
  }

  /// 申请测试代币
  Future<void> requestAirdrop() async {
    try {
      _isLoading.value = true;
      _error.value = '';

      final signature = await _solanaService.requestAirdrop();

      // 显示成功消息
      Get.snackbar(
        '申请成功',
        '交易签名: ${signature.substring(0, 8)}...',
        snackPosition: SnackPosition.TOP,
      );

      // 延迟后更新余额
      await Future.delayed(const Duration(seconds: 3));
      await updateBalance();
    } catch (e) {
      _error.value = e.toString();

      // 显示错误消息
      Get.snackbar('申请失败', e.toString(), snackPosition: SnackPosition.TOP);
    } finally {
      _isLoading.value = false;
    }
  }

  /// 刷新余额
  Future<void> refreshBalance() async {
    try {
      _isLoading.value = true;
      await updateBalance();

      // 显示刷新成功消息
      Get.snackbar('刷新成功', '余额已更新', snackPosition: SnackPosition.TOP);
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  /// 清除错误信息
  void clearError() {
    _error.value = '';
  }

  @override
  void onClose() {
    // 控制器销毁时断开连接
    _solanaService.disconnect();
    super.onClose();
  }
}
