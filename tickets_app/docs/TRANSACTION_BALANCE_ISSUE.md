# 为什么签名成功后余额没有变少？

## 🔍 问题分析

您遇到的问题是：`testSignatureRequest` 测试转账签名成功后，钱包余额没有减少。

### 原因分析

#### 1. **只签名，没有发送交易**
原来的实现只调用了 `signTransaction`（签名），但没有调用 `sendTransaction`（发送到网络）：

```dart
// ❌ 原来的实现：只签名，不发送
await _walletService.signTransaction(transactionBytes);
```

**签名 ≠ 发送交易**
- `signTransaction`: 只是用私钥对交易数据进行数字签名
- `sendTransaction`: 将签名后的交易发送到 Solana 网络执行

#### 2. **使用模拟数据**
`_createRealTransactionBytes()` 创建的是 JSON 格式的模拟数据，不是真正的 Solana 交易：

```dart
// ❌ 这不是真正的 Solana 交易字节
final exampleTransactionData = {
  'type': 'transfer',
  'from': _walletAddress,
  'to': 'So11111111111111111111111111111111111111112',
  'amount': 0.1,
  'timestamp': DateTime.now().millisecondsSinceEpoch,
};
```

#### 3. **没有刷新余额**
签名成功后没有调用余额刷新方法。

## ✅ 解决方案

### 1. **修改签名处理逻辑**

现在的实现会：
1. 先签名交易
2. 判断是否为真实交易数据
3. 如果是真实交易，发送到网络
4. 刷新钱包余额

```dart
// ✅ 新的实现
for (final transaction in _signatureRequest!.transactions) {
  final transactionBytes = _getTransactionBytes(transaction);
  if (transactionBytes != null) {
    // 1. 签名交易
    final signature = await _walletService.signTransaction(transactionBytes);
    
    // 2. 如果是真实交易，发送到网络
    if (_isRealSolanaTransaction(transactionBytes)) {
      final txSignature = await _walletService.sendTransaction(transactionBytes);
      await _walletService.refreshBalance(); // 刷新余额
    }
  }
}
```

### 2. **区分真实交易和模拟数据**

添加了 `_isRealSolanaTransaction()` 方法来判断：

```dart
bool _isRealSolanaTransaction(Uint8List transactionBytes) {
  try {
    // 尝试解析为 JSON
    final jsonString = utf8.decode(transactionBytes);
    final jsonData = jsonDecode(jsonString);
    
    // 如果包含模拟数据特征，说明是模拟数据
    if (jsonData is Map && 
        jsonData.containsKey('type') && 
        jsonData.containsKey('timestamp')) {
      return false; // 模拟数据
    }
  } catch (e) {
    // 解析失败，可能是真实的二进制数据
  }
  
  return true; // 假设是真实交易
}
```

### 3. **添加余额刷新**

在测试方法中添加余额刷新：

```dart
if (result == RequestResult.approved) {
  // 刷新余额
  await refreshBalance();
  
  Get.snackbar(
    '签名成功',
    'DApp 签名请求已批准，余额已刷新',
    snackPosition: SnackPosition.BOTTOM,
  );
}
```

## 🧪 测试场景

### 场景1：模拟数据测试
- **目的**: 测试签名流程
- **结果**: 签名成功，但不会实际转账
- **余额**: 不会变化（因为没有真实交易）

### 场景2：真实交易测试
- **目的**: 测试完整的转账流程
- **结果**: 签名 + 发送交易
- **余额**: 会减少（如果交易成功）

## 🔧 如何创建真实转账

### 使用 TransactionBuilder

```dart
// 创建真实的 SOL 转账交易
final transactionInfo = await TransactionBuilder.createSolTransfer(
  fromAddress: senderAddress,
  toAddress: receiverAddress,
  lamports: 100000000, // 0.1 SOL
  recentBlockhash: await getRecentBlockhash(),
);

// 请求签名
final signatureRequest = SignatureRequest(
  dappName: 'Test App',
  dappUrl: 'https://test-app.com',
  transactions: [transactionInfo],
  message: '确认转账 0.1 SOL',
);
```

### 手动构建交易

```dart
// 使用 Solana SDK 构建
final instruction = SystemInstruction.transfer(
  fundingAccount: Ed25519HDPublicKey.fromBase58(fromAddress),
  recipientAccount: Ed25519HDPublicKey.fromBase58(toAddress),
  lamports: 100000000,
);

final message = Message(
  instructions: [instruction],
  recentBlockhash: recentBlockhash,
);

final compiledMessage = message.compile(
  feePayer: Ed25519HDPublicKey.fromBase58(fromAddress),
  addressLookupTableAccounts: [],
);

final transactionBytes = compiledMessage.toByteArray().toList();
```

## ⚠️ 注意事项

### 1. **网络环境**
- 确保连接到正确的 Solana 网络（localnet/devnet/mainnet）
- 确保网络节点正常运行

### 2. **余额要求**
- 发送方必须有足够的 SOL 余额
- 需要支付交易费用（通常很少）

### 3. **地址有效性**
- 确保发送方和接收方地址有效
- 地址格式必须正确

### 4. **测试建议**
- 在 devnet 或 localnet 上测试
- 使用小额度进行测试
- 先测试模拟数据，再测试真实交易

## 📝 总结

余额没有变少的主要原因是：
1. **只签名了交易，没有发送到网络**
2. **使用的是模拟数据，不是真实交易**
3. **没有刷新余额显示**

现在的修改解决了这些问题：
- ✅ 签名后会发送真实交易
- ✅ 区分模拟数据和真实交易
- ✅ 自动刷新余额
- ✅ 提供了创建真实交易的工具和示例

如果您想测试真实的转账，请使用 `TransactionBuilder` 创建真实的交易数据，而不是模拟的 JSON 数据。
