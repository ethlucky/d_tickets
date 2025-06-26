import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'my_tickets_controller.dart';
import 'my_tickets_view.dart';

/// 我的票券页面演示
class MyTicketsDemo extends GetView<MyTicketsController> {
  const MyTicketsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const MyTicketsView();
  }
}
