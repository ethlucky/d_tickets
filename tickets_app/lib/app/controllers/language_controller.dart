import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// 语言控制器 - 管理应用国际化
class LanguageController extends GetxController {
  final _storage = GetStorage();
  final RxString _currentLanguage = 'zh_CN'.obs;

  // Getters
  String get currentLanguage => _currentLanguage.value;
  Locale get currentLocale => _getLocaleFromLanguage(_currentLanguage.value);

  @override
  void onInit() {
    super.onInit();
    // 从本地存储读取语言设置
    _loadLanguageFromStorage();
  }

  /// 从本地存储加载语言设置
  void _loadLanguageFromStorage() {
    final language = _storage.read('language') ?? 'zh_CN';
    _currentLanguage.value = language;
  }

  /// 切换语言
  void changeLanguage(String languageCode) {
    _currentLanguage.value = languageCode;
    _saveLanguageToStorage();

    // 应用语言变更
    final locale = _getLocaleFromLanguage(languageCode);
    Get.updateLocale(locale);

    // 显示切换提示
    Get.snackbar(
      'language_changed'.tr,
      _getLanguageName(languageCode),
      snackPosition: SnackPosition.TOP,
    );
  }

  /// 保存语言设置到本地存储
  void _saveLanguageToStorage() {
    _storage.write('language', _currentLanguage.value);
  }

  /// 根据语言代码获取Locale
  Locale _getLocaleFromLanguage(String languageCode) {
    switch (languageCode) {
      case 'zh_CN':
        return const Locale('zh', 'CN');
      case 'en_US':
        return const Locale('en', 'US');
      case 'ja_JP':
        return const Locale('ja', 'JP');
      default:
        return const Locale('zh', 'CN');
    }
  }

  /// 获取语言显示名称
  String _getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'zh_CN':
        return '简体中文';
      case 'en_US':
        return 'English';
      case 'ja_JP':
        return '日本語';
      default:
        return '简体中文';
    }
  }

  /// 获取支持的语言列表
  List<Map<String, String>> get supportedLanguages => [
    {'code': 'zh_CN', 'name': '简体中文'},
    {'code': 'en_US', 'name': 'English'},
    {'code': 'ja_JP', 'name': '日本語'},
  ];

  /// 检查是否为中文
  bool get isChinese => _currentLanguage.value == 'zh_CN';

  /// 检查是否为英文
  bool get isEnglish => _currentLanguage.value == 'en_US';

  /// 检查是否为日文
  bool get isJapanese => _currentLanguage.value == 'ja_JP';
}
