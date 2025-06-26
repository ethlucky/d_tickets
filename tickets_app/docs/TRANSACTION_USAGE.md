# 真实交易数据使用指南

本文档详细说明如何在应用中使用真实的交易数据，而不是模拟数据。

## 概述

之前的实现使用模拟数据创建交易字节：

```dart
// ❌ 旧的模拟实现
final transactionBytes = _createMockTransactionBytes(transaction);
await _walletService.signTransaction(transactionBytes);
```

现在支持真实的交易数据：

```dart
// ✅ 新的真实数据实现
final transactionBytes = _getTransactionBytes(transaction);
if (transactionBytes != null) {
  await _walletService.signTransaction(transactionBytes);
}
```

## TransactionInfo 模型更新

### 新增字段

```dart
class TransactionInfo {
  // 原有字段...
  final String fromAddress;
  final String toAddress;
  final double amount;
  final String? programId;
  final String? instruction;
  final Map<String, dynamic>? additionalData;
  
  // 🆕 新增字段
  final List<int>? transactionBytes;      // 原始交易字节数据
  final String? encodedTransaction;       // 编码后的交易数据
}
```

### 新增工厂构造函数

```dart
// 从编码的交易数据创建
TransactionInfo.fromEncodedTransaction({
  required String encodedTransaction,
  required String fromAddress,
  required String toAddress,
  required double amount,
  // ...其他参数
});

// 从交易字节数据创建
TransactionInfo.fromTransactionBytes({
  required List<int> transactionBytes,
  required String fromAddress,
  required String toAddress,
  required double amount,
  // ...其他参数
});
```

## 使用方式

### 方式1：传递交易字节数据

```dart
// 在调用页面（如购票页面）
final transactionBytes = await buildSolanaTransaction(); // 构建真实交易

final transactionInfo = TransactionInfo.fromTransactionBytes(
  transactionBytes: transactionBytes,
  fromAddress: buyerAddress,
  toAddress: sellerAddress,
  amount: ticketPrice,
  programId: 'TicketProgramId',
  instruction: 'PurchaseTicket',
);

// 创建签名请求
final signatureRequest = SignatureRequest(
  dappName: 'Tickets App',
  dappUrl: 'https://tickets-app.com',
  transactions: [transactionInfo],
  message: '确认购买门票',
);

// 跳转到签名页面
final result = await Get.toNamed(
  '/dapp-signature-request',
  arguments: signatureRequest,
);
```

### 方式2：传递编码的交易数据

```dart
// 在调用页面
final encodedTransaction = base64.encode(transactionBytes);

final transactionInfo = TransactionInfo.fromEncodedTransaction(
  encodedTransaction: encodedTransaction,
  fromAddress: buyerAddress,
  toAddress: sellerAddress,
  amount: ticketPrice,
  programId: 'TicketProgramId',
  instruction: 'PurchaseTicket',
);

// 其余步骤相同...
```

## TransactionBuilder 工具类

为了简化交易创建，提供了 `TransactionBuilder` 工具类：

### SOL 转账

```dart
final transactionInfo = await TransactionBuilder.createSolTransfer(
  fromAddress: 'SenderAddress...',
  toAddress: 'ReceiverAddress...',
  lamports: 1000000000, // 1 SOL
  recentBlockhash: 'RecentBlockhash...',
);
```

### 代币转账

```dart
final transactionInfo = await TransactionBuilder.createTokenTransfer(
  fromAddress: 'SenderAddress...',
  toAddress: 'ReceiverAddress...',
  amount: 100.0,
  tokenMint: 'TokenMintAddress...',
  decimals: 6,
  recentBlockhash: 'RecentBlockhash...',
);
```

### 购票交易

```dart
final transactionInfo = await TransactionBuilder.createTicketPurchaseTransaction(
  buyerAddress: 'BuyerAddress...',
  sellerAddress: 'SellerAddress...',
  ticketPrice: 99.99,
  ticketId: 'TICKET_001',
  eventId: 'EVENT_123',
  recentBlockhash: 'RecentBlockhash...',
);
```

## 实际应用示例

### 购票页面集成

```dart
// 在 OrderSummaryController 中
Future<void> createOrder() async {
  try {
    // 1. 创建真实的购票交易
    final transactionInfo = await TransactionBuilder.createTicketPurchaseTransaction(
      buyerAddress: await _getBuyerAddress(),
      sellerAddress: event.organizer,
      ticketPrice: total,
      ticketId: _generateTicketId(),
      eventId: event.id,
      recentBlockhash: await _getRecentBlockhash(),
    );
    
    // 2. 请求用户签名
    final result = await _requestTransactionSignature(transactionInfo);
    
    if (result == RequestResult.approved) {
      // 3. 签名成功，继续后续流程
      _navigateToSuccess();
    }
  } catch (e) {
    _handleError(e);
  }
}
```

### 转账页面集成

```dart
// 在转账页面
Future<void> sendTransfer() async {
  try {
    // 1. 创建 SOL 转账交易
    final transactionInfo = await TransactionBuilder.createSolTransfer(
      fromAddress: senderAddress,
      toAddress: receiverAddress,
      lamports: (amount * 1000000000).toInt(),
      recentBlockhash: await _getRecentBlockhash(),
    );
    
    // 2. 请求签名
    final signatureRequest = SignatureRequest(
      dappName: 'Wallet App',
      dappUrl: 'https://wallet-app.com',
      transactions: [transactionInfo],
      message: '确认转账 $amount SOL',
    );
    
    final result = await Get.toNamed(
      '/dapp-signature-request',
      arguments: signatureRequest,
    );
    
    if (result == RequestResult.approved) {
      // 转账成功
    }
  } catch (e) {
    // 处理错误
  }
}
```

## 批量交易

支持一次签名多个交易：

```dart
final signatureRequest = SignatureRequest(
  dappName: 'Batch App',
  dappUrl: 'https://batch-app.com',
  transactions: [
    transaction1,  // SOL 转账
    transaction2,  // 购票交易
    transaction3,  // 代币转账
  ],
  message: '确认批量交易',
);
```

## 注意事项

1. **安全性**：确保交易数据来源可信
2. **验证**：在签名前验证交易参数
3. **错误处理**：妥善处理交易构建和签名失败的情况
4. **用户体验**：提供清晰的交易信息展示

## 迁移指南

### 从模拟数据迁移

1. 移除 `_createMockTransactionBytes` 方法
2. 使用 `TransactionBuilder` 创建真实交易
3. 更新调用代码使用新的 `TransactionInfo` 构造函数
4. 测试所有交易流程

### 示例迁移

```dart
// ❌ 旧代码
final transactionBytes = _createMockTransactionBytes(transaction);

// ✅ 新代码
final transactionInfo = await TransactionBuilder.createTicketPurchaseTransaction(
  buyerAddress: buyerAddress,
  sellerAddress: sellerAddress,
  ticketPrice: price,
  ticketId: ticketId,
  eventId: eventId,
  recentBlockhash: recentBlockhash,
);
```

这样就完成了从模拟数据到真实交易数据的迁移！
