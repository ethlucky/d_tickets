import 'dart:convert';
import 'dart:typed_data';
import 'package:get/get.dart';
import '../models/wallet_request_model.dart';
import '../utils/transaction_builder.dart';

/// 交易使用示例
/// 展示如何在不同场景中创建和使用真实的交易数据
class TransactionExamples {
  
  /// 示例1：购票场景
  /// 从购票页面传递真实的交易数据到签名页面
  static Future<void> exampleTicketPurchase() async {
    try {
      // 1. 创建购票交易数据
      final transactionInfo = await TransactionBuilder.createTicketPurchaseTransaction(
        buyerAddress: 'BuyerWalletAddress123...',
        sellerAddress: 'EventOrganizerAddress456...',
        ticketPrice: 99.99,
        ticketId: 'TICKET_001',
        eventId: 'EVENT_123',
        recentBlockhash: 'RecentBlockhash789...',
      );

      // 2. 创建签名请求
      final signatureRequest = SignatureRequest(
        dappName: 'Tickets App',
        dappUrl: 'https://tickets-app.com',
        transactions: [transactionInfo],
        message: '确认购买演唱会门票',
      );

      // 3. 跳转到签名页面
      final result = await Get.toNamed(
        '/dapp-signature-request',
        arguments: signatureRequest,
      );

      // 4. 处理签名结果
      if (result == RequestResult.approved) {
        print('✅ 购票交易签名成功');
        // 继续后续流程...
      } else {
        print('❌ 用户取消了购票交易');
      }
    } catch (e) {
      print('❌ 购票交易失败: $e');
    }
  }

  /// 示例2：SOL 转账场景
  /// 创建 SOL 转账交易
  static Future<void> exampleSolTransfer() async {
    try {
      // 1. 创建 SOL 转账交易
      final transactionInfo = await TransactionBuilder.createSolTransfer(
        fromAddress: 'SenderWalletAddress123...',
        toAddress: 'ReceiverWalletAddress456...',
        lamports: 1000000000, // 1 SOL = 1,000,000,000 lamports
        recentBlockhash: 'RecentBlockhash789...',
      );

      // 2. 创建签名请求
      final signatureRequest = SignatureRequest(
        dappName: 'Wallet App',
        dappUrl: 'https://wallet-app.com',
        transactions: [transactionInfo],
        message: '确认转账 1 SOL',
      );

      // 3. 请求签名
      final result = await Get.toNamed(
        '/dapp-signature-request',
        arguments: signatureRequest,
      );

      if (result == RequestResult.approved) {
        print('✅ SOL 转账签名成功');
      }
    } catch (e) {
      print('❌ SOL 转账失败: $e');
    }
  }

  /// 示例3：代币转账场景
  /// 创建代币转账交易
  static Future<void> exampleTokenTransfer() async {
    try {
      // 1. 创建代币转账交易
      final transactionInfo = await TransactionBuilder.createTokenTransfer(
        fromAddress: 'SenderWalletAddress123...',
        toAddress: 'ReceiverWalletAddress456...',
        amount: 100.0, // 转账 100 个代币
        tokenMint: 'TokenMintAddress789...',
        decimals: 6, // 代币精度
        recentBlockhash: 'RecentBlockhash789...',
      );

      // 2. 创建签名请求
      final signatureRequest = SignatureRequest(
        dappName: 'Token App',
        dappUrl: 'https://token-app.com',
        transactions: [transactionInfo],
        message: '确认转账 100 代币',
      );

      // 3. 请求签名
      final result = await Get.toNamed(
        '/dapp-signature-request',
        arguments: signatureRequest,
      );

      if (result == RequestResult.approved) {
        print('✅ 代币转账签名成功');
      }
    } catch (e) {
      print('❌ 代币转账失败: $e');
    }
  }

  /// 示例4：从编码的交易数据创建
  /// 当你已经有编码后的交易数据时
  static Future<void> exampleFromEncodedTransaction() async {
    try {
      // 假设你从其他地方获得了编码的交易数据
      final encodedTransaction = 'base64EncodedTransactionData...';

      // 1. 从编码数据创建交易信息
      final transactionInfo = TransactionBuilder.fromEncodedTransaction(
        encodedTransaction: encodedTransaction,
        fromAddress: 'SenderAddress123...',
        toAddress: 'ReceiverAddress456...',
        amount: 50.0,
        programId: 'ProgramId789...',
        instruction: 'CustomInstruction',
        additionalData: {
          'customField1': 'value1',
          'customField2': 'value2',
        },
      );

      // 2. 创建签名请求
      final signatureRequest = SignatureRequest(
        dappName: 'Custom App',
        dappUrl: 'https://custom-app.com',
        transactions: [transactionInfo],
        message: '确认自定义交易',
      );

      // 3. 请求签名
      final result = await Get.toNamed(
        '/dapp-signature-request',
        arguments: signatureRequest,
      );

      if (result == RequestResult.approved) {
        print('✅ 自定义交易签名成功');
      }
    } catch (e) {
      print('❌ 自定义交易失败: $e');
    }
  }

  /// 示例5：从原始字节数据创建
  /// 当你有原始的交易字节数据时
  static Future<void> exampleFromTransactionBytes() async {
    try {
      // 假设你从 Solana SDK 或其他地方获得了交易字节
      final transactionBytes = <int>[1, 2, 3, 4, 5]; // 示例字节数据

      // 1. 从字节数据创建交易信息
      final transactionInfo = TransactionBuilder.fromTransactionBytes(
        transactionBytes: transactionBytes,
        fromAddress: 'SenderAddress123...',
        toAddress: 'ReceiverAddress456...',
        amount: 25.0,
        programId: 'ProgramId789...',
        instruction: 'BytesInstruction',
      );

      // 2. 创建签名请求
      final signatureRequest = SignatureRequest(
        dappName: 'Bytes App',
        dappUrl: 'https://bytes-app.com',
        transactions: [transactionInfo],
        message: '确认字节交易',
      );

      // 3. 请求签名
      final result = await Get.toNamed(
        '/dapp-signature-request',
        arguments: signatureRequest,
      );

      if (result == RequestResult.approved) {
        print('✅ 字节交易签名成功');
      }
    } catch (e) {
      print('❌ 字节交易失败: $e');
    }
  }

  /// 示例6：批量交易
  /// 一次签名多个交易
  static Future<void> exampleBatchTransactions() async {
    try {
      // 1. 创建多个交易
      final transaction1 = await TransactionBuilder.createSolTransfer(
        fromAddress: 'SenderAddress123...',
        toAddress: 'ReceiverAddress456...',
        lamports: 500000000, // 0.5 SOL
        recentBlockhash: 'RecentBlockhash789...',
      );

      final transaction2 = await TransactionBuilder.createTicketPurchaseTransaction(
        buyerAddress: 'SenderAddress123...',
        sellerAddress: 'EventOrganizerAddress789...',
        ticketPrice: 75.0,
        ticketId: 'TICKET_002',
        eventId: 'EVENT_456',
        recentBlockhash: 'RecentBlockhash789...',
      );

      // 2. 创建批量签名请求
      final signatureRequest = SignatureRequest(
        dappName: 'Batch App',
        dappUrl: 'https://batch-app.com',
        transactions: [transaction1, transaction2], // 多个交易
        message: '确认批量交易：转账 + 购票',
      );

      // 3. 请求签名
      final result = await Get.toNamed(
        '/dapp-signature-request',
        arguments: signatureRequest,
      );

      if (result == RequestResult.approved) {
        print('✅ 批量交易签名成功');
      }
    } catch (e) {
      print('❌ 批量交易失败: $e');
    }
  }
}
