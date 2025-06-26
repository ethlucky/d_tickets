import 'package:get/get.dart';
import 'account_settings_controller.dart';

/// 账户设置页面依赖注入绑定
class AccountSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AccountSettingsController>(() => AccountSettingsController());
  }
}
