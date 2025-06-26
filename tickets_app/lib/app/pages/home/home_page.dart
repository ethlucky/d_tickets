import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/solana_controller.dart';
import '../../controllers/theme_controller.dart';

/// 首页页面
class HomePage extends GetView<SolanaController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('app_name'.tr),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // 主题切换按钮
          IconButton(
            icon: Obx(
              () => Icon(
                themeController.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              ),
            ),
            onPressed: () => themeController.toggleTheme(),
          ),
          // 设置按钮
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Get.toNamed('/settings'),
          ),
        ],
      ),
      body: Obx(
        () => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // 连接状态指示器
              _buildConnectionStatus(),
              const SizedBox(height: 24),

              // 钱包信息
              if (controller.publicKey.isNotEmpty) ...[
                _buildWalletInfo(),
                const SizedBox(height: 16),
                _buildBalanceInfo(),
                const SizedBox(height: 24),
              ],

              // 错误信息
              if (controller.error.isNotEmpty) ...[
                _buildErrorInfo(),
                const SizedBox(height: 16),
              ],

              // 加载指示器
              if (controller.isLoading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('loading'.tr),
                const SizedBox(height: 24),
              ],

              // 操作按钮
              if (!controller.isLoading) _buildActionButtons(),

              const SizedBox(height: 32),

              // 项目信息
              _buildProjectInfo(),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建连接状态
  Widget _buildConnectionStatus() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: controller.isConnected
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: controller.isConnected ? Colors.green : Colors.grey,
        ),
      ),
      child: Row(
        children: [
          Icon(
            controller.isConnected ? Icons.check_circle : Icons.circle_outlined,
            color: controller.isConnected ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            controller.isConnected
                ? 'connected_to_solana'.tr
                : 'disconnected'.tr,
            style: TextStyle(
              color: controller.isConnected ? Colors.green : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建钱包信息
  Widget _buildWalletInfo() {
    return Column(
      children: [
        Text(
          'wallet_address'.tr,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            controller.publicKey,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  /// 构建余额信息
  Widget _buildBalanceInfo() {
    return Text(
      '${'balance'.tr}: ${controller.balance.toStringAsFixed(4)} SOL',
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.deepPurple,
      ),
    );
  }

  /// 构建错误信息
  Widget _buildErrorInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              controller.error,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () => controller.clearError(),
          ),
        ],
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons() {
    if (controller.publicKey.isEmpty) {
      return ElevatedButton.icon(
        onPressed: () => controller.generateWallet(),
        icon: const Icon(Icons.account_balance_wallet),
        label: Text('generate_wallet'.tr),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: () => controller.requestAirdrop(),
            icon: const Icon(Icons.water_drop),
            label: Text('request_airdrop'.tr),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => controller.refreshBalance(),
            icon: const Icon(Icons.refresh),
            label: Text('refresh_balance'.tr),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      );
    }
  }

  /// 构建项目信息
  Widget _buildProjectInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '🎫 ${'app_name'.tr}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '基于Espresso Cash提供的Solana Flutter SDK构建',
            style: TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(
            '支持完整的Solana JSON RPC API、交易签名和移动钱包适配器',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
