# TransactionBuilder 修复说明

## 🔧 修复的问题

### 1. **Message 构造函数错误**
**问题**: `Message` 构造函数不接受 `recentBlockhash` 参数
```dart
// ❌ 错误的用法
final message = Message(
  instructions: [instruction],
  recentBlockhash: recentBlockhash, // 这个参数不存在
);
```

**修复**: `recentBlockhash` 应该在 `compile` 方法中传递
```dart
// ✅ 正确的用法
final message = Message(
  instructions: [instruction],
);

final compiledMessage = message.compile(
  recentBlockhash: recentBlockhash,
  feePayer: Ed25519HDPublicKey.fromBase58(fromAddress),
);
```

### 2. **AssociatedTokenAccountProgram API 错误**
**问题**: `AssociatedTokenAccountProgram.getAssociatedTokenAccount` 方法不存在

**修复**: 暂时移除代币转账功能，专注于 SOL 转账
```dart
// ✅ 现在的实现
static Future<TransactionInfo> createTokenTransfer(...) async {
  throw UnimplementedError(
    '代币转账功能暂未实现。请使用外部工具构建代币转账交易，'
    '然后使用 TransactionBuilder.fromEncodedTransaction() 创建 TransactionInfo。'
  );
}
```

### 3. **ByteArray 转换**
**问题**: `toByteArray()` 返回 `ByteArray` 类型，不是 `List<int>`

**修复**: 使用 `toList()` 方法转换
```dart
// ✅ 正确的转换
final transactionBytes = compiledMessage.toByteArray().toList();
```

## ✅ 当前可用功能

### 1. **SOL 转账交易**
```dart
final transactionInfo = await TransactionBuilder.createSolTransfer(
  fromAddress: 'SenderAddress...',
  toAddress: 'ReceiverAddress...',
  lamports: 1000000000, // 1 SOL
  recentBlockhash: 'RecentBlockhash...',
);
```

### 2. **购票交易**
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

### 3. **从编码数据创建**
```dart
final transactionInfo = TransactionBuilder.fromEncodedTransaction(
  encodedTransaction: 'base64EncodedData...',
  fromAddress: 'SenderAddress...',
  toAddress: 'ReceiverAddress...',
  amount: 50.0,
);
```

### 4. **从字节数据创建**
```dart
final transactionInfo = TransactionBuilder.fromTransactionBytes(
  transactionBytes: [1, 2, 3, 4, 5],
  fromAddress: 'SenderAddress...',
  toAddress: 'ReceiverAddress...',
  amount: 25.0,
);
```

## 🚫 暂不可用功能

### 1. **代币转账**
- 原因：需要处理关联代币账户的复杂逻辑
- 替代方案：使用外部工具构建交易，然后用 `fromEncodedTransaction` 创建

### 2. **复杂的智能合约交互**
- 原因：需要特定的程序 ID 和指令格式
- 替代方案：手动构建交易字节或使用专门的 SDK

## 📋 使用建议

### 1. **测试环境**
```dart
// 使用模拟数据测试签名流程
final mockData = {
  'type': 'transfer',
  'from': fromAddress,
  'to': toAddress,
  'amount': 0.1,
  'note': '这是模拟数据',
};
final transactionBytes = utf8.encode(jsonEncode(mockData));

final transactionInfo = TransactionBuilder.fromTransactionBytes(
  transactionBytes: transactionBytes,
  fromAddress: fromAddress,
  toAddress: toAddress,
  amount: 0.1,
);
```

### 2. **生产环境**
```dart
// 使用真实的 Solana 交易
final transactionInfo = await TransactionBuilder.createSolTransfer(
  fromAddress: await getWalletAddress(),
  toAddress: recipientAddress,
  lamports: (amount * 1000000000).toInt(),
  recentBlockhash: await getRecentBlockhash(),
);
```

### 3. **错误处理**
```dart
try {
  final transactionInfo = await TransactionBuilder.createSolTransfer(...);
  // 使用 transactionInfo
} catch (e) {
  if (e is UnimplementedError) {
    // 功能未实现
    print('功能暂未实现: ${e.message}');
  } else {
    // 其他错误
    print('创建交易失败: $e');
  }
}
```

## 🔮 未来改进

### 1. **代币转账支持**
- 实现关联代币账户查找
- 支持代币账户创建
- 处理代币精度转换

### 2. **更多交易类型**
- NFT 转账
- 质押操作
- 投票交易
- 程序部署

### 3. **网络集成**
- 自动获取最新区块哈希
- 交易费用估算
- 网络状态检查

## 📝 总结

经过修复，`TransactionBuilder` 现在可以：
- ✅ 创建基本的 SOL 转账交易
- ✅ 创建购票交易（模拟）
- ✅ 处理编码的交易数据
- ✅ 处理原始交易字节
- ❌ 暂不支持代币转账（需要更复杂的实现）

这个实现足以支持大部分基本的交易需求，特别是 SOL 转账和购票场景。对于更复杂的需求，建议使用外部工具构建交易，然后通过 `fromEncodedTransaction` 或 `fromTransactionBytes` 方法创建 `TransactionInfo`。
