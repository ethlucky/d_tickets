import 'package:solana/solana.dart';
import 'package:bip39/bip39.dart' as bip39;

/// Solana服务层 - 处理与Solana区块链的所有交互
class SolanaService {
  RpcClient? _client;
  Ed25519HDKeyPair? _keyPair;
  String? _publicKey;

  // Getters
  RpcClient? get client => _client;
  String? get publicKey => _publicKey;
  Ed25519HDKeyPair? get keyPair => _keyPair;
  bool get isConnected => _client != null;
  bool get hasWallet => _publicKey != null;

  /// 初始化Solana连接
  Future<void> initialize() async {
    try {
      // 根据环境变量确定连接的网络
      const String solanaNetwork = String.fromEnvironment(
        'SOLANA_NETWORK',
        defaultValue: 'localnet',
      );

      String rpcUrl;
      String wsUrl;
      switch (solanaNetwork) {
        case 'localnet':
          rpcUrl = 'http://10.0.2.2:8899';
          wsUrl = 'ws://10.0.2.2:8900';
          break;
        case 'devnet':
          rpcUrl = 'https://api.devnet.solana.com';
          wsUrl = 'ws://api.devnet.solana.com';
          break;
        case 'mainnet':
          rpcUrl = 'https://api.mainnet-beta.solana.com';
          wsUrl = 'wss://api.mainnet-beta.solana.com';
          break;
        default:
          rpcUrl = 'http://10.0.2.2:8899';
          wsUrl = 'ws://10.0.2.2:8900';
      }

      print('Solana RPC URL: $rpcUrl');

      _client = RpcClient(rpcUrl);

      // 测试网络连接
      try {
        final slot = await _client!.getSlot();
        print('已连接到Solana网络: $solanaNetwork ($rpcUrl)');
        print('当前区块高度: $slot');
      } catch (e) {
        print('网络连接测试失败: $e');
        _client = null;
        throw Exception('无法连接到Solana网络: $e');
      }
    } catch (e) {
      throw Exception('初始化Solana连接失败: $e');
    }
  }

  /// 生成新钱包
  Future<String> generateWallet() async {
    try {
      // 生成助记词
      final mnemonic = bip39.generateMnemonic();

      // 从助记词生成密钥对
      _keyPair = await Ed25519HDKeyPair.fromMnemonic(mnemonic);
      _publicKey = _keyPair!.address;

      return _publicKey!;
    } catch (e) {
      throw Exception('钱包生成失败: $e');
    }
  }

  /// 获取账户余额
  Future<double> getBalance() async {
    if (_client == null || _publicKey == null) {
      throw Exception('客户端或钱包未初始化');
    }

    try {
      final balanceResponse = await _client!.getBalance(_publicKey!);
      return (balanceResponse.value) / lamportsPerSol;
    } catch (e) {
      throw Exception('获取余额失败: $e');
    }
  }

  /// 申请测试代币（仅在devnet上可用）
  Future<String> requestAirdrop() async {
    if (_client == null || _publicKey == null) {
      throw Exception('客户端或钱包未初始化');
    }

    try {
      // 申请1个SOL的测试代币
      final signature = await _client!.requestAirdrop(
        _publicKey!,
        lamportsPerSol,
      );

      return signature;
    } catch (e) {
      throw Exception('申请测试代币失败: $e');
    }
  }

  /// 断开连接
  void disconnect() {
    _client = null;
    _keyPair = null;
    _publicKey = null;
  }
}
