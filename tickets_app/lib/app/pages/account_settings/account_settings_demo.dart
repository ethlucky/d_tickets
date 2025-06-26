import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'account_settings_controller.dart';
import 'account_settings_view.dart';

/// 账户设置页面演示
class AccountSettingsDemo extends GetView<AccountSettingsController> {
  const AccountSettingsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const AccountSettingsView();
  }
}
