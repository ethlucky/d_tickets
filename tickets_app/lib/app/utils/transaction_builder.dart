import 'dart:convert';
import 'package:solana/solana.dart';
import '../models/wallet_request_model.dart';

/// Solana 交易构建工具类
/// 用于创建真实的 Solana 交易数据
class TransactionBuilder {
  
  /// 创建 SOL 转账交易
  ///
  /// [fromAddress] 发送方地址
  /// [toAddress] 接收方地址
  /// [lamports] 转账金额（以 lamports 为单位，1 SOL = 1,000,000,000 lamports）
  /// [recentBlockhash] 最近的区块哈希
  static Future<TransactionInfo> createSolTransfer({
    required String fromAddress,
    required String toAddress,
    required int lamports,
    required String recentBlockhash,
  }) async {
    try {
      print('🔨 开始构建 SOL 转账交易...');
      print('📊 从: $fromAddress');
      print('📊 到: $toAddress');
      print('📊 金额: $lamports lamports');
      print('📊 区块哈希: $recentBlockhash');

      // 创建转账指令
      final instruction = SystemInstruction.transfer(
        fundingAccount: Ed25519HDPublicKey.fromBase58(fromAddress),
        recipientAccount: Ed25519HDPublicKey.fromBase58(toAddress),
        lamports: lamports,
      );
      print('✅ 转账指令创建完成');

      // 创建交易消息
      final message = Message(
        instructions: [instruction],
      );
      print('✅ 交易消息创建完成');

      // 编译消息为字节
      final compiledMessage = message.compile(
        recentBlockhash: recentBlockhash,
        feePayer: Ed25519HDPublicKey.fromBase58(fromAddress),
      );
      print('✅ 交易消息编译完成');

      // 获取交易字节
      final transactionBytes = compiledMessage.toByteArray().toList();
      print('✅ 交易字节获取完成，长度: ${transactionBytes.length}');
      print('📊 交易字节前20个: ${transactionBytes.take(20).toList()}');

      return TransactionInfo.fromTransactionBytes(
        transactionBytes: transactionBytes,
        fromAddress: fromAddress,
        toAddress: toAddress,
        amount: lamports / 1000000000, // 转换为 SOL
        programId: SystemProgram.programId,
        instruction: 'Transfer',
        additionalData: {
          'lamports': lamports,
          'recentBlockhash': recentBlockhash,
        },
      );
    } catch (e) {
      print('❌ 创建 SOL 转账交易失败: $e');
      throw Exception('创建 SOL 转账交易失败: $e');
    }
  }

  /// 创建代币转账交易
  ///
  /// 注意：此方法需要更复杂的实现来处理关联代币账户
  /// 当前版本暂时不支持，建议使用外部工具构建代币转账交易
  static Future<TransactionInfo> createTokenTransfer({
    required String fromAddress,
    required String toAddress,
    required double amount,
    required String tokenMint,
    required int decimals,
    required String recentBlockhash,
  }) async {
    // TODO: 实现真正的代币转账交易构建
    // 这需要处理关联代币账户的创建和验证
    throw UnimplementedError(
      '代币转账功能暂未实现。请使用外部工具构建代币转账交易，'
      '然后使用 TransactionBuilder.fromEncodedTransaction() 或 '
      'TransactionBuilder.fromTransactionBytes() 创建 TransactionInfo。'
    );
  }

  /// 从已编码的交易字符串创建 TransactionInfo
  /// 
  /// [encodedTransaction] base64 或 base58 编码的交易字符串
  /// [fromAddress] 发送方地址
  /// [toAddress] 接收方地址
  /// [amount] 交易金额
  /// [programId] 程序 ID
  /// [instruction] 指令类型
  static TransactionInfo fromEncodedTransaction({
    required String encodedTransaction,
    required String fromAddress,
    required String toAddress,
    required double amount,
    String? programId,
    String? instruction,
    Map<String, dynamic>? additionalData,
  }) {
    return TransactionInfo.fromEncodedTransaction(
      encodedTransaction: encodedTransaction,
      fromAddress: fromAddress,
      toAddress: toAddress,
      amount: amount,
      programId: programId,
      instruction: instruction,
      additionalData: additionalData,
    );
  }

  /// 从原始字节数据创建 TransactionInfo
  /// 
  /// [transactionBytes] 交易字节数据
  /// [fromAddress] 发送方地址
  /// [toAddress] 接收方地址
  /// [amount] 交易金额
  /// [programId] 程序 ID
  /// [instruction] 指令类型
  static TransactionInfo fromTransactionBytes({
    required List<int> transactionBytes,
    required String fromAddress,
    required String toAddress,
    required double amount,
    String? programId,
    String? instruction,
    Map<String, dynamic>? additionalData,
  }) {
    return TransactionInfo.fromTransactionBytes(
      transactionBytes: transactionBytes,
      fromAddress: fromAddress,
      toAddress: toAddress,
      amount: amount,
      programId: programId,
      instruction: instruction,
      additionalData: additionalData,
    );
  }

  /// 创建购票交易示例
  /// 这是一个示例，展示如何为购票场景创建交易
  static Future<TransactionInfo> createTicketPurchaseTransaction({
    required String buyerAddress,
    required String sellerAddress,
    required double ticketPrice,
    required String ticketId,
    required String eventId,
    required String recentBlockhash,
  }) async {
    try {
      // 在实际应用中，这里应该调用票务智能合约
      // 这里只是一个示例实现
      
      // 创建购票数据
      final purchaseData = {
        'action': 'purchase_ticket',
        'buyer': buyerAddress,
        'seller': sellerAddress,
        'ticketId': ticketId,
        'eventId': eventId,
        'price': ticketPrice,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // 序列化为字节
      final jsonString = jsonEncode(purchaseData);
      final transactionBytes = utf8.encode(jsonString);

      return TransactionInfo.fromTransactionBytes(
        transactionBytes: transactionBytes,
        fromAddress: buyerAddress,
        toAddress: sellerAddress,
        amount: ticketPrice,
        programId: 'TicketProgram', // 实际应该是票务程序的 ID
        instruction: 'PurchaseTicket',
        additionalData: {
          'ticketId': ticketId,
          'eventId': eventId,
          'recentBlockhash': recentBlockhash,
        },
      );
    } catch (e) {
      throw Exception('创建购票交易失败: $e');
    }
  }
}
