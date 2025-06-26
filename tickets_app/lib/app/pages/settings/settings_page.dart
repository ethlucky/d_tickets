import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/theme_controller.dart';
import '../../controllers/language_controller.dart';

/// 设置页面
class SettingsPage extends GetView<ThemeController> {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('settings'.tr),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 主题设置
          Card(
            child: ListTile(
              leading: Obx(
                () => Icon(
                  controller.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                ),
              ),
              title: Text('theme_settings'.tr),
              subtitle: Obx(
                () => Text(
                  controller.isDarkMode ? 'dark_theme'.tr : 'light_theme'.tr,
                ),
              ),
              trailing: Obx(
                () => Switch(
                  value: controller.isDarkMode,
                  onChanged: (value) => controller.toggleTheme(),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 语言设置
          Card(
            child: ListTile(
              leading: const Icon(Icons.language),
              title: Text('language_settings'.tr),
              subtitle: Obx(
                () => Text(
                  languageController.supportedLanguages.firstWhere(
                    (lang) =>
                        lang['code'] == languageController.currentLanguage,
                  )['name']!,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showLanguageDialog(languageController),
            ),
          ),

          const SizedBox(height: 16),

          // 关于
          Card(
            child: ListTile(
              leading: const Icon(Icons.info),
              title: Text('about'.tr),
              subtitle: const Text('应用信息'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showAboutDialog(),
            ),
          ),
        ],
      ),
    );
  }

  /// 显示语言选择对话框
  void _showLanguageDialog(LanguageController languageController) {
    Get.dialog(
      AlertDialog(
        title: Text('select_language'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languageController.supportedLanguages.map((language) {
            return Obx(
              () => RadioListTile<String>(
                title: Text(language['name']!),
                value: language['code']!,
                groupValue: languageController.currentLanguage,
                onChanged: (value) {
                  if (value != null) {
                    languageController.changeLanguage(value);
                    Get.back();
                  }
                },
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
        ],
      ),
    );
  }

  /// 显示关于对话框
  void _showAboutDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('about'.tr),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🎫 Solana票务应用'),
            SizedBox(height: 8),
            Text('版本: 1.0.0'),
            SizedBox(height: 8),
            Text('基于GetX架构开发'),
            SizedBox(height: 8),
            Text('支持完整的Solana区块链集成'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('confirm'.tr)),
        ],
      ),
    );
  }
}
