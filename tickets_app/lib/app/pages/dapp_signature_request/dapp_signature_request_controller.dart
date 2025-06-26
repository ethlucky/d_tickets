import 'dart:convert';
import 'dart:typed_data';
import 'package:get/get.dart';
import '../../models/wallet_request_model.dart';
import '../../services/mobile_wallet_service.dart';

/// DApp 签名请求控制器
class DAppSignatureRequestController extends GetxController {
  final MobileWalletService _walletService = Get.find<MobileWalletService>();

  // 状态变量
  final RxBool _isLoading = false.obs;
  SignatureRequest? _signatureRequest;

  // Getters
  bool get isLoading => _isLoading.value;
  SignatureRequest? get signatureRequest => _signatureRequest;
  String get walletAddress => _walletService.publicKey;
  double get walletBalance => _walletService.balance;

  @override
  void onInit() {
    super.onInit();
    // 获取传入的签名请求参数
    final arguments = Get.arguments;
    if (arguments is SignatureRequest) {
      _signatureRequest = arguments;
    }
  }

  /// 用户批准签名请求
  Future<void> onApprove() async {
    _isLoading.value = true;

    try {
      if (_signatureRequest == null) {
        throw Exception('签名请求为空');
      }

      // 如果有消息需要签名
      if (_signatureRequest!.message != null) {
        await _walletService.signMessage(_signatureRequest!.message!);
      }

      // 签名并发送所有交易
      for (final transaction in _signatureRequest!.transactions) {
        final transactionBytes = _getTransactionBytes(transaction);
        if (transactionBytes != null) {
          print('📊 交易字节长度: ${transactionBytes.length}');
          print('📊 交易类型检查...');

          // 检查是否是真实交易
          final isRealTransaction = _isRealSolanaTransaction(transactionBytes);
          print('📊 是否为真实交易: $isRealTransaction');

          // 对于真实交易，发送到网络（内部会处理签名）
          if (isRealTransaction) {
            try {
              print('🚀 开始发送真实交易到网络...');
              print('📊 交易将通过 MobileWalletService.sendTransaction 处理');

              final txSignature = await _walletService.sendTransaction(transactionBytes);
              print('✅ 交易发送成功: $txSignature');

              // 刷新钱包余额
              print('🔄 刷新钱包余额...');
              await _walletService.refreshBalance();
              print('✅ 余额已刷新');

              // 记录成功的交易
              print('📝 真实交易完成，签名: $txSignature');

            } catch (e) {
              print('❌ 发送交易失败: $e');
              print('📊 错误详情: ${e.toString()}');
              rethrow; // 重新抛出错误，让用户知道交易失败
            }
          } else {
            // 对于模拟交易，只进行签名演示
            print('ℹ️ 检测到模拟交易数据，只进行签名演示');
            try {
              final signature = await _walletService.signTransaction(transactionBytes);
              print('✅ 模拟交易签名完成: $signature');
              print('📝 交易数据预览: ${String.fromCharCodes(transactionBytes.take(100))}...');
            } catch (e) {
              print('❌ 模拟交易签名失败: $e');
              rethrow;
            }
          }
        } else {
          throw Exception('交易数据无效：缺少 transactionBytes 或 encodedTransaction');
        }
      }

      // 返回批准结果
      Get.back(result: RequestResult.approved);

      Get.snackbar(
        '签名成功',
        '交易已签名并发送完成',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      // 处理错误
      Get.snackbar(
        '签名失败',
        '签名请求处理失败: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// 用户拒绝签名请求
  void onReject() {
    Get.back(result: RequestResult.rejected);
  }

  /// 用户取消签名请求
  void onCancel() {
    Get.back(result: RequestResult.cancelled);
  }

  /// 获取真实的交易字节数据
  Uint8List? _getTransactionBytes(TransactionInfo transaction) {
    // 优先使用直接提供的交易字节数据
    if (transaction.transactionBytes != null) {
      return Uint8List.fromList(transaction.transactionBytes!);
    }

    // 如果有编码的交易数据，尝试解码
    if (transaction.encodedTransaction != null) {
      try {
        // 尝试 base64 解码
        return Uint8List.fromList(base64.decode(transaction.encodedTransaction!));
      } catch (e) {
        print('Base64 解码失败，尝试其他格式: $e');
        // 可以在这里添加其他解码方式，比如 base58
        return null;
      }
    }

    // 如果都没有提供，返回 null
    print('警告：TransactionInfo 中缺少 transactionBytes 或 encodedTransaction');
    return null;
  }

  /// 判断是否是真实的 Solana 交易字节
  bool _isRealSolanaTransaction(Uint8List transactionBytes) {
    print('🔍 开始检查交易类型...');
    print('🔍 交易字节长度: ${transactionBytes.length}');

    try {
      // 尝试解析为 JSON，如果成功说明是模拟数据
      final jsonString = utf8.decode(transactionBytes);
      final jsonData = jsonDecode(jsonString);

      print('🔍 成功解析为 JSON，这是模拟数据');
      print('🔍 JSON 内容: $jsonData');

      // 如果包含我们模拟数据的特征字段，说明是模拟数据
      if (jsonData is Map &&
          jsonData.containsKey('type') &&
          jsonData.containsKey('timestamp')) {
        print('🔍 确认为模拟数据（包含 type 和 timestamp 字段）');
        return false; // 这是模拟数据
      }
    } catch (e) {
      // 解析 JSON 失败，可能是真实的二进制交易数据
      print('🔍 JSON 解析失败，可能是二进制交易数据: $e');
    }

    // 简单的 Solana 交易字节验证
    if (transactionBytes.length < 32) {
      print('🔍 交易字节太短 (${transactionBytes.length} < 32)，不是真实交易');
      return false; // 太短，不可能是真实交易
    }

    // 检查是否包含 Solana 交易的特征
    // Solana 交易通常以特定的字节模式开始
    print('🔍 交易字节前10个字节: ${transactionBytes.take(10).toList()}');

    // 如果字节数据看起来像二进制数据（不是可打印字符），很可能是真实交易
    bool hasNonPrintableBytes = false;
    for (int i = 0; i < transactionBytes.length && i < 20; i++) {
      if (transactionBytes[i] < 32 || transactionBytes[i] > 126) {
        hasNonPrintableBytes = true;
        break;
      }
    }

    if (hasNonPrintableBytes) {
      print('🔍 检测到二进制数据，判断为真实交易');
      return true;
    }

    print('🔍 无法确定交易类型，默认判断为真实交易');
    return true; // 默认假设是真实交易
  }
}
