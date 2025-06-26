import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/app_bar_widget.dart';
import 'solana_wallet_demo_controller.dart';

/// Solana Mobile Wallet Adapter 演示页面
class SolanaWalletDemoPage extends StatelessWidget {
  const SolanaWalletDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(SolanaWalletDemoController());

    return Scaffold(
      appBar: AppBarWidget(
        title: 'Solana 钱包演示',
        showBackButton: true,
        onBackPressed: () => Get.back(),
      ),
      body: GetBuilder<SolanaWalletDemoController>(
        builder: (controller) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 钱包状态卡片
                _buildWalletStatusCard(controller),
                const SizedBox(height: 20),

                // 使用说明卡片
                _buildInstructionsCard(),
                const SizedBox(height: 20),

                // 功能按钮组
                _buildActionButtons(controller),
                const SizedBox(height: 20),

                // 交易历史记录
                if (controller.transactionHistory.isNotEmpty)
                  _buildTransactionHistory(controller),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 构建钱包状态卡片
  Widget _buildWalletStatusCard(SolanaWalletDemoController controller) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  controller.isWalletConnected
                      ? Icons.account_balance_wallet
                      : Icons.wallet,
                  size: 24,
                  color:
                      controller.isWalletConnected ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  controller.isWalletConnected
                      ? '钱包已连接 (${controller.connectionType})'
                      : '钱包未连接',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (controller.isWalletConnected) ...[
              const SizedBox(height: 12),
              Text(
                '钱包地址:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  controller.walletAddress,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // DApp 连接状态
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: controller.isDAppConnected ? Colors.green[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: controller.isDAppConnected ? Colors.green : Colors.orange,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      controller.isDAppConnected ? Icons.link : Icons.link_off,
                      size: 16,
                      color: controller.isDAppConnected ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DApp 连接状态',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: controller.isDAppConnected ? Colors.green[700] : Colors.orange[700],
                            ),
                          ),
                          Text(
                            controller.connectionStatusText,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SOL 余额:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_formatBalance(controller.solBalance)} SOL',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        '精确值: ${controller.solBalance.toStringAsFixed(8)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建使用说明卡片
  Widget _buildInstructionsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, size: 24, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  '使用说明',
                  style: Theme.of(Get.context!).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '这是一个 Solana Mobile Wallet Adapter 演示应用，实现了以下功能：',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            _buildInstructionItem(
              '1. 钱包连接',
              '连接移动钱包并查看钱包地址和余额',
            ),
            _buildInstructionItem(
              '2. 空投 SOL',
              '在本地测试链上请求空投 1 SOL',
            ),
            _buildInstructionItem(
              '3. DApp 连接请求',
              '模拟外部 DApp 请求连接钱包的流程',
            ),
            _buildInstructionItem(
              '4. DApp 签名请求',
              '模拟外部 DApp 请求签名交易的流程',
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber,
                      size: 20, color: Colors.orange[600]),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '注意：这是演示版本，使用硬编码私钥和模拟交易',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建说明项目
  Widget _buildInstructionItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建功能按钮组
  Widget _buildActionButtons(SolanaWalletDemoController controller) {
    return Column(
      children: [
        // 钱包连接按钮
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: controller.isLoading
                    ? null
                    : () {
                        if (controller.isDAppConnected) {
                          // 如果 DApp 已连接，提供断开 DApp 连接的选项
                          controller.disconnectDApp();
                        } else if (controller.isWalletConnected) {
                          // 如果只是钱包连接，提供断开钱包的选项
                          controller.disconnectWallet();
                        } else {
                          // 如果都没连接，连接钱包
                          controller.connectWallet();
                        }
                      },
                icon: Icon(_getConnectionIcon(controller)),
                label: Text(_getConnectionButtonText(controller)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getConnectionButtonColor(controller),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            if (controller.isWalletConnected) ...[
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      controller.isLoading ? null : controller.refreshBalance,
                  icon: const Icon(Icons.refresh),
                  label: const Text('刷新余额'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 12),

        // 空投 SOL 按钮
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (!controller.isWalletConnected || controller.isLoading)
                ? null
                : () async {
                    await controller.requestAirdrop();
                  },
            icon: const Icon(Icons.monetization_on),
            label: const Text('空投 1 SOL (Localnet)'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 发送交易按钮
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (!controller.isWalletConnected || controller.isLoading)
                ? null
                : () async {
                    await controller.sendTransaction();
                  },
            icon: const Icon(Icons.send),
            label: const Text('发送演示交易'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: Colors.purple[600],
              foregroundColor: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 测试 DApp 连接请求按钮
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: controller.isLoading
                ? null
                : () async {
                    await controller.testConnectionRequest();
                  },
            icon: const Icon(Icons.link),
            label: const Text('测试 DApp 连接请求'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: Colors.orange[600],
              foregroundColor: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 测试 DApp 签名请求按钮
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (!controller.isWalletConnected || controller.isLoading)
                ? null
                : () async {
                    await controller.testSignatureRequest();
                  },
            icon: const Icon(Icons.edit),
            label: const Text('测试 DApp 签名请求'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: Colors.teal[600],
              foregroundColor: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 检查目标地址余额按钮
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: controller.isLoading
                ? null
                : controller.checkTargetBalance,
            icon: const Icon(Icons.account_balance_wallet),
            label: const Text('检查目标地址余额'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              foregroundColor: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 直接 SOL 转账测试按钮
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: controller.isLoading
                ? null
                : controller.testDirectSolTransfer,
            icon: const Icon(Icons.send),
            label: const Text('直接 SOL 转账测试'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建交易历史记录
  Widget _buildTransactionHistory(SolanaWalletDemoController controller) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, size: 24),
                const SizedBox(width: 8),
                Text(
                  '交易历史',
                  style: Theme.of(Get.context!).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.transactionHistory.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final tx = controller.transactionHistory[index];
                return ListTile(
                  dense: true,
                  leading: Icon(
                    _getTransactionIcon(tx.type),
                    color: _getTransactionColor(tx.type),
                  ),
                  title: Text(tx.type),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (tx.signature.isNotEmpty)
                        SelectableText(
                          '签名: ${tx.signature}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      Text(
                        '时间: ${tx.timestamp}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: tx.status == 'success'
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.error, color: Colors.red),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 获取交易图标
  IconData _getTransactionIcon(String type) {
    switch (type) {
      case '空投':
        return Icons.monetization_on;
      case '发送交易':
        return Icons.send;
      default:
        return Icons.receipt;
    }
  }

  /// 获取交易颜色
  Color _getTransactionColor(String type) {
    switch (type) {
      case '空投':
        return Colors.green;
      case '发送交易':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  /// 格式化余额
  String _formatBalance(double balance) {
    if (balance >= 1e9) {
      // 十亿以上显示为 B（十亿）
      return '${(balance / 1e9).toStringAsFixed(2)}B';
    } else if (balance >= 1e6) {
      // 百万以上显示为 M（百万）
      return '${(balance / 1e6).toStringAsFixed(2)}M';
    } else if (balance >= 1e3) {
      // 千以上显示为 K（千）
      return '${(balance / 1e3).toStringAsFixed(2)}K';
    } else if (balance >= 1) {
      // 1 以上保留 4 位小数
      return balance.toStringAsFixed(4);
    } else {
      // 小于 1 保留 8 位小数（适合小额代币）
      return balance.toStringAsFixed(4);
    }
  }

  /// 获取连接按钮图标
  IconData _getConnectionIcon(SolanaWalletDemoController controller) {
    if (controller.isDAppConnected) {
      return Icons.link_off; // DApp 已连接，显示断开图标
    } else if (controller.isWalletConnected) {
      return Icons.link_off; // 钱包已连接，显示断开图标
    } else {
      return Icons.link; // 未连接，显示连接图标
    }
  }

  /// 获取连接按钮文本
  String _getConnectionButtonText(SolanaWalletDemoController controller) {
    if (controller.isDAppConnected) {
      return '断开 DApp'; // DApp 已连接
    } else if (controller.isWalletConnected) {
      return '断开钱包'; // 只有钱包连接
    } else {
      return '连接钱包'; // 未连接
    }
  }

  /// 获取连接按钮颜色
  Color _getConnectionButtonColor(SolanaWalletDemoController controller) {
    if (controller.isDAppConnected) {
      return Colors.orange; // DApp 已连接，橙色表示断开 DApp
    } else if (controller.isWalletConnected) {
      return Colors.red; // 钱包已连接，红色表示断开钱包
    } else {
      return Colors.blue; // 未连接，蓝色表示连接
    }
  }
}
