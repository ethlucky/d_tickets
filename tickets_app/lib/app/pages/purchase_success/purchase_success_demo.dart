import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'purchase_success_controller.dart';
import 'purchase_success_view.dart';

/// 购票成功页面演示
class PurchaseSuccessDemo extends GetView<PurchaseSuccessController> {
  const PurchaseSuccessDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const PurchaseSuccessView();
  }
}
