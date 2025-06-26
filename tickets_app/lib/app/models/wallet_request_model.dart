/// DApp 连接请求模型
class ConnectionRequest {
  final String dappName;
  final String dappUrl;
  final String? dappIcon;
  final String identityName;
  final String identityUri;
  final String? iconUri;
  final String cluster;

  ConnectionRequest({
    required this.dappName,
    required this.dappUrl,
    this.dappIcon,
    required this.identityName,
    required this.identityUri,
    this.iconUri,
    required this.cluster,
  });
}

/// 签名请求模型
class SignatureRequest {
  final String dappName;
  final String dappUrl;
  final String? dappIcon;
  final List<TransactionInfo> transactions;
  final String? message;

  SignatureRequest({
    required this.dappName,
    required this.dappUrl,
    this.dappIcon,
    required this.transactions,
    this.message,
  });
}

/// 交易信息模型
class TransactionInfo {
  final String fromAddress;
  final String toAddress;
  final double amount;
  final String? programId;
  final String? instruction;
  final Map<String, dynamic>? additionalData;

  // 新增：真实的交易字节数据
  final List<int>? transactionBytes;

  // 新增：已编码的交易数据（base64 或 base58）
  final String? encodedTransaction;

  TransactionInfo({
    required this.fromAddress,
    required this.toAddress,
    required this.amount,
    this.programId,
    this.instruction,
    this.additionalData,
    this.transactionBytes,
    this.encodedTransaction,
  });

  /// 从编码的交易数据创建 TransactionInfo
  factory TransactionInfo.fromEncodedTransaction({
    required String encodedTransaction,
    required String fromAddress,
    required String toAddress,
    required double amount,
    String? programId,
    String? instruction,
    Map<String, dynamic>? additionalData,
  }) {
    return TransactionInfo(
      fromAddress: fromAddress,
      toAddress: toAddress,
      amount: amount,
      programId: programId,
      instruction: instruction,
      additionalData: additionalData,
      encodedTransaction: encodedTransaction,
    );
  }

  /// 从交易字节数据创建 TransactionInfo
  factory TransactionInfo.fromTransactionBytes({
    required List<int> transactionBytes,
    required String fromAddress,
    required String toAddress,
    required double amount,
    String? programId,
    String? instruction,
    Map<String, dynamic>? additionalData,
  }) {
    return TransactionInfo(
      fromAddress: fromAddress,
      toAddress: toAddress,
      amount: amount,
      programId: programId,
      instruction: instruction,
      additionalData: additionalData,
      transactionBytes: transactionBytes,
    );
  }
}

/// 请求结果枚举
enum RequestResult {
  approved,
  rejected,
  cancelled,
}
