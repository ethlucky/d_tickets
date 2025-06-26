import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'ticket_details_controller.dart';
import 'ticket_details_view.dart';

/// 票券详情页面演示
class TicketDetailsDemo extends GetView<TicketDetailsController> {
  const TicketDetailsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const TicketDetailsView();
  }
}
