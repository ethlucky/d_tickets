import 'package:get/get.dart';

/// 应用国际化翻译
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    // 中文翻译
    'zh_CN': {
      // 通用
      'app_name': 'Solana票务应用',
      'confirm': '确认',
      'cancel': '取消',
      'loading': '加载中...',
      'error': '错误',
      'success': '成功',
      'warning': '警告',
      'info': '信息',

      // 连接状态
      'connected': '已连接',
      'disconnected': '未连接',
      'connecting': '连接中...',
      'connection_success': '连接成功',
      'connection_failed': '连接失败',
      'connected_to_solana': '已连接到Solana Devnet',

      // 钱包相关
      'wallet_address': '钱包地址',
      'balance': '余额',
      'generate_wallet': '生成钱包',
      'wallet_generated': '钱包生成成功',
      'wallet_generation_failed': '钱包生成失败',
      'request_airdrop': '申请测试币',
      'airdrop_success': '申请成功',
      'airdrop_failed': '申请失败',
      'refresh_balance': '刷新余额',
      'balance_updated': '余额已更新',

      // 主题相关
      'theme_switched': '主题切换',
      'dark_theme': '已切换到深色主题',
      'light_theme': '已切换到浅色主题',
      'theme_settings': '主题设置',

      // 语言相关
      'language_changed': '语言已切换',
      'language_settings': '语言设置',
      'select_language': '选择语言',

      // 错误信息
      'client_not_initialized': '客户端未初始化',
      'wallet_not_initialized': '钱包未初始化',
      'network_error': '网络错误',
      'transaction_failed': '交易失败',
    },

    // 英文翻译
    'en_US': {
      // 通用
      'app_name': 'Solana Tickets App',
      'confirm': 'Confirm',
      'cancel': 'Cancel',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'warning': 'Warning',
      'info': 'Info',

      // 连接状态
      'connected': 'Connected',
      'disconnected': 'Disconnected',
      'connecting': 'Connecting...',
      'connection_success': 'Connection Successful',
      'connection_failed': 'Connection Failed',
      'connected_to_solana': 'Connected to Solana Devnet',

      // 钱包相关
      'wallet_address': 'Wallet Address',
      'balance': 'Balance',
      'generate_wallet': 'Generate Wallet',
      'wallet_generated': 'Wallet Generated Successfully',
      'wallet_generation_failed': 'Wallet Generation Failed',
      'request_airdrop': 'Request Airdrop',
      'airdrop_success': 'Airdrop Successful',
      'airdrop_failed': 'Airdrop Failed',
      'refresh_balance': 'Refresh Balance',
      'balance_updated': 'Balance Updated',

      // 主题相关
      'theme_switched': 'Theme Switched',
      'dark_theme': 'Switched to Dark Theme',
      'light_theme': 'Switched to Light Theme',
      'theme_settings': 'Theme Settings',

      // 语言相关
      'language_changed': 'Language Changed',
      'language_settings': 'Language Settings',
      'select_language': 'Select Language',

      // 错误信息
      'client_not_initialized': 'Client Not Initialized',
      'wallet_not_initialized': 'Wallet Not Initialized',
      'network_error': 'Network Error',
      'transaction_failed': 'Transaction Failed',
    },

    // 日文翻译
    'ja_JP': {
      // 通用
      'app_name': 'Solanaチケットアプリ',
      'confirm': '確認',
      'cancel': 'キャンセル',
      'loading': '読み込み中...',
      'error': 'エラー',
      'success': '成功',
      'warning': '警告',
      'info': '情報',

      // 連接状態
      'connected': '接続済み',
      'disconnected': '未接続',
      'connecting': '接続中...',
      'connection_success': '接続成功',
      'connection_failed': '接続失敗',
      'connected_to_solana': 'Solana Devnetに接続しました',

      // ウォレット関連
      'wallet_address': 'ウォレットアドレス',
      'balance': '残高',
      'generate_wallet': 'ウォレット生成',
      'wallet_generated': 'ウォレット生成成功',
      'wallet_generation_failed': 'ウォレット生成失敗',
      'request_airdrop': 'テストトークン申請',
      'airdrop_success': '申請成功',
      'airdrop_failed': '申請失敗',
      'refresh_balance': '残高更新',
      'balance_updated': '残高が更新されました',

      // テーマ関連
      'theme_switched': 'テーマ切換',
      'dark_theme': 'ダークテーマに切り替えました',
      'light_theme': 'ライトテーマに切り替えました',
      'theme_settings': 'テーマ設定',

      // 言語関連
      'language_changed': '言語が変更されました',
      'language_settings': '言語設定',
      'select_language': '言語選択',

      // エラー情報
      'client_not_initialized': 'クライアントが初期化されていません',
      'wallet_not_initialized': 'ウォレットが初期化されていません',
      'network_error': 'ネットワークエラー',
      'transaction_failed': '取引失敗',
    },
  };
}
