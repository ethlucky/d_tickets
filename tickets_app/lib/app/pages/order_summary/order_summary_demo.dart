import 'package:flutter/material.dart';
import 'order_summary_view.dart';
import 'order_summary_binding.dart';

/// 订单摘要页面演示
class OrderSummaryDemo extends StatelessWidget {
  const OrderSummaryDemo({super.key});

  @override
  Widget build(BuildContext context) {
    // 初始化绑定
    OrderSummaryBinding().dependencies();

    return const OrderSummaryView();
  }
}
