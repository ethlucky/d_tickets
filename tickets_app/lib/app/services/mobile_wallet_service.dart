import 'dart:convert';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:solana/solana.dart';
import 'package:solana/dto.dart';
import 'package:solana/encoder.dart';
import 'package:bs58/bs58.dart';
import '../models/wallet_request_model.dart';

/// 移动钱包服务
class MobileWalletService extends GetxService {
  // 硬编码的私钥字节数组（用于演示，实际应用中应该安全存储）
  static const List<int> _hardcodedPrivateKeyBytes = [
    218,
    243,
    233,
    157,
    18,
    84,
    212,
    250,
    214,
    131,
    84,
    57,
    223,
    136,
    159,
    139,
    78,
    15,
    30,
    99,
    118,
    2,
    96,
    136,
    179,
    197,
    63,
    172,
    129,
    238,
    19,
    163,
    120,
    102,
    62,
    219,
    46,
    60,
    70,
    162,
    230,
    118,
    36,
    231,
    103,
    19,
    189,
    142,
    239,
    234,
    96,
    54,
    43,
    142,
    242,
    73,
    140,
    48,
    36,
    124,
    61,
    234,
    30,
    142
  ];

  late Ed25519HDKeyPair _keyPair;
  late SolanaClient _solanaClient;
  late String _rpcUrl; // 存储当前使用的 RPC URL

  // 钱包状态
  final RxBool _isInitialized = false.obs;
  final RxString _publicKey = ''.obs;
  final RxDouble _balance = 0.0.obs;

  // Getters
  bool get isInitialized => _isInitialized.value;
  String get publicKey => _publicKey.value;
  double get balance => _balance.value;
  Ed25519HDKeyPair get keyPair => _keyPair;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeWallet();
  }

  /// 初始化钱包
  Future<void> _initializeWallet() async {
    try {
      // 初始化 Solana 客户端
      // 在 Android 模拟器中，使用 10.0.2.2 来访问宿主机的 localhost
      // 在 iOS 模拟器中，可以直接使用 localhost 或 127.0.0.1
      String wsUrl;

      // 检测平台并设置合适的 URL
      if (GetPlatform.isAndroid) {
        // Android 模拟器：10.0.2.2 映射到宿主机的 127.0.0.1
        _rpcUrl = "http://10.0.2.2:8899";
        wsUrl = "ws://10.0.2.2:8900";
        print('📱 Android 平台，使用宿主机地址: $_rpcUrl');
      } else {
        // iOS 模拟器或其他平台
        _rpcUrl = "http://127.0.0.1:8899";
        wsUrl = "ws://127.0.0.1:8900";
        print('📱 iOS/其他平台，使用本地地址: $_rpcUrl');
      }

      _solanaClient = SolanaClient(
        rpcUrl: Uri.parse(_rpcUrl),
        websocketUrl: Uri.parse(wsUrl),
      );

      // 生成密钥对（使用硬编码私钥字节）
      final privateKeyBytes =
          Uint8List.fromList(_hardcodedPrivateKeyBytes.take(32).toList());
      _keyPair = await Ed25519HDKeyPair.fromPrivateKeyBytes(
        privateKey: privateKeyBytes,
      );

      _publicKey.value = _keyPair.address;
      _isInitialized.value = true;

      print('✅ 钱包初始化成功，地址: ${_keyPair.address}');

      // 获取初始余额
      await refreshBalance();
    } catch (e) {
      print('❌ 钱包初始化失败: $e');
      rethrow;
    }
  }



  /// 刷新余额
  Future<void> refreshBalance() async {
    if (!_isInitialized.value) {
      print('❌ 钱包未初始化，无法刷新余额');
      return;
    }

    try {
      print('🔄 开始刷新余额，钱包地址: ${_keyPair.address}');

      final balance =
          await _solanaClient.rpcClient.getBalance(_keyPair.address);
      final solBalance = balance.value / 1000000000; // 转换为 SOL

      print('✅ 余额查询成功: ${balance.value} lamports = $solBalance SOL');

      _balance.value = solBalance;
    } catch (e) {
      print('❌ 获取余额失败: $e');
      print('📍 钱包地址: ${_keyPair.address}');
      print('📍 RPC URL: $_rpcUrl');
      // 设置余额为0，避免显示错误的数据
      _balance.value = 0.0;
    }
  }

  /// 处理连接请求
  Future<RequestResult> handleConnectionRequest(
      ConnectionRequest request) async {
    // 显示连接确认对话框
    final result = await Get.toNamed(
      '/dapp-connection-request',
      arguments: request,
    );

    return result ?? RequestResult.cancelled;
  }

  /// 处理签名请求
  Future<RequestResult> handleSignatureRequest(SignatureRequest request) async {
    // 显示签名确认对话框
    final result = await Get.toNamed(
      '/dapp-signature-request',
      arguments: request,
    );

    return result ?? RequestResult.cancelled;
  }

  /// 签名交易
  Future<String> signTransaction(Uint8List transactionBytes) async {
    if (!_isInitialized.value) {
      throw Exception('钱包未初始化');
    }

    try {
      final signature = await _keyPair.sign(transactionBytes);
      return base58.encode(Uint8List.fromList(signature.bytes));
    } catch (e) {
      throw Exception('签名失败: $e');
    }
  }

  /// 签名消息
  Future<String> signMessage(String message) async {
    if (!_isInitialized.value) {
      throw Exception('钱包未初始化');
    }

    try {
      final messageBytes = Uint8List.fromList(message.codeUnits);
      final signature = await _keyPair.sign(messageBytes);
      return base58.encode(Uint8List.fromList(signature.bytes));
    } catch (e) {
      throw Exception('签名失败: $e');
    }
  }

  /// 发送交易（接收未签名的交易字节，内部进行签名和发送）
  Future<String> sendTransaction(Uint8List transactionBytes) async {
    if (!_isInitialized.value) {
      throw Exception('钱包未初始化');
    }

    try {
      print('🚀 开始处理交易...');
      print('📊 交易字节长度: ${transactionBytes.length}');

      // 1. 对交易进行签名
      print('✍️ 对交易进行签名...');
      final signature = await _keyPair.sign(transactionBytes);
      print('✅ 交易签名完成');

      // 2. 构造已签名的交易（使用正确的 Solana 格式）
      print('🔨 构造已签名交易...');

      // 从交易字节创建 CompiledMessage
      final compiledMessage = CompiledMessage(ByteArray(transactionBytes));

      // 创建已签名交易
      final signedTx = SignedTx(
        compiledMessage: compiledMessage,
        signatures: [Signature(signature.bytes, publicKey: _keyPair.publicKey)],
      );

      // 3. 编码已签名交易
      final encodedTransaction = signedTx.encode();
      print('✅ 已签名交易编码完成');

      print('📤 发送交易到网络...');

      // 4. 发送交易到 Solana 网络
      final txSignature = await _solanaClient.rpcClient.sendTransaction(
        encodedTransaction,
        encoding: Encoding.base64,
        preflightCommitment: Commitment.confirmed,
      );

      print('✅ 交易发送成功，签名: $txSignature');

      // 5. 等待交易确认
      print('⏳ 等待交易确认...');
      await _waitForTransactionConfirmation(txSignature);

      print('🎉 交易确认完成: $txSignature');
      return txSignature;
    } catch (e) {
      print('❌ 发送交易失败: $e');
      throw Exception('发送交易失败: $e');
    }
  }

  /// 等待交易确认
  Future<void> _waitForTransactionConfirmation(String signature) async {
    const maxRetries = 30; // 最多等待30次，每次1秒
    const retryDelay = Duration(seconds: 1);

    for (int i = 0; i < maxRetries; i++) {
      try {
        final statusResult = await _solanaClient.rpcClient.getSignatureStatuses([signature]);

        if (statusResult.value.isNotEmpty && statusResult.value.first != null) {
          final status = statusResult.value.first!;
          final confirmationStatus = status.confirmationStatus;

          if (confirmationStatus == Commitment.confirmed || confirmationStatus == Commitment.finalized) {
            print('✅ 交易已确认，状态: $confirmationStatus');
            return;
          }

          if (status.err != null) {
            throw Exception('交易失败: ${status.err}');
          }
        }

        print('⏳ 等待确认中... (${i + 1}/$maxRetries)');
        await Future.delayed(retryDelay);
      } catch (e) {
        if (i == maxRetries - 1) {
          throw Exception('等待交易确认超时: $e');
        }
        await Future.delayed(retryDelay);
      }
    }

    throw Exception('交易确认超时');
  }
}
