import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dapp_signature_request_controller.dart';
import '../../widgets/app_bar_widget.dart';
import '../../models/wallet_request_model.dart';

/// DApp 签名请求页面
class DAppSignatureRequestPage extends StatelessWidget {
  const DAppSignatureRequestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DAppSignatureRequestController());

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBarWidget(
        title: '签名请求',
        showBackButton: true,
        onBackPressed: () => controller.onReject(),
      ),
      body: GetBuilder<DAppSignatureRequestController>(
        builder: (controller) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // DApp 信息卡片
                          _buildDAppInfoCard(controller),
                          SizedBox(height: 24.h),

                          // 交易详情
                          _buildTransactionDetails(controller),
                          SizedBox(height: 24.h),

                          // 钱包信息
                          _buildWalletInfoCard(controller),
                          SizedBox(height: 24.h),

                          // 安全提示
                          _buildSecurityWarning(),
                        ],
                      ),
                    ),
                  ),

                  // 底部按钮
                  _buildActionButtons(controller),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建 DApp 信息卡片
  Widget _buildDAppInfoCard(DAppSignatureRequestController controller) {
    final request = controller.signatureRequest;
    if (request == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // DApp 图标
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                    color: Colors.purple[50],
                  ),
                  child: request.dappIcon != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: Image.network(
                            request.dappIcon!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.edit,
                                size: 24.w,
                                color: Colors.purple[600],
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.edit,
                          size: 24.w,
                          color: Colors.purple[600],
                        ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.dappName,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF141414),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        request.dappUrl,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: const Color(0xFF737373),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.edit,
                    size: 20.w,
                    color: Colors.purple[600],
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      '该应用请求您签名一个交易',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.purple[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建交易详情卡片
  Widget _buildTransactionDetails(DAppSignatureRequestController controller) {
    final request = controller.signatureRequest;
    if (request == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '交易详情',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF141414),
              ),
            ),
            SizedBox(height: 16.h),

            // 如果有消息，显示消息内容
            if (request.message != null) ...[
              _buildDetailRow('消息', request.message!),
              SizedBox(height: 12.h),
            ],

            // 显示交易列表
            if (request.transactions.isNotEmpty)
              ...request.transactions.asMap().entries.map((entry) {
                final index = entry.key;
                final transaction = entry.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (request.transactions.length > 1) ...[
                      Text(
                        '交易 ${index + 1}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF141414),
                        ),
                      ),
                      SizedBox(height: 8.h),
                    ],
                    _buildTransactionCard(transaction),
                    if (index < request.transactions.length - 1)
                      SizedBox(height: 16.h),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }

  /// 构建单个交易卡片
  Widget _buildTransactionCard(TransactionInfo transaction) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('发送方', transaction.fromAddress),
          SizedBox(height: 8.h),
          _buildDetailRow('接收方', transaction.toAddress),
          SizedBox(height: 8.h),
          _buildDetailRow('金额', '${transaction.amount.toStringAsFixed(4)} SOL'),
          if (transaction.programId != null) ...[
            SizedBox(height: 8.h),
            _buildDetailRow('程序ID', transaction.programId!),
          ],
          if (transaction.instruction != null) ...[
            SizedBox(height: 8.h),
            _buildDetailRow('指令', transaction.instruction!),
          ],
        ],
      ),
    );
  }

  /// 构建详情行
  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80.w,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF737373),
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              color: const Color(0xFF141414),
              fontFamily: value.length > 20 ? 'monospace' : null,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建钱包信息卡片
  Widget _buildWalletInfoCard(DAppSignatureRequestController controller) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '签名钱包',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF141414),
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    size: 20.w,
                    color: Colors.green[600],
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '主钱包',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF141414),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        controller.walletAddress,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFF737373),
                          fontFamily: 'monospace',
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '${controller.walletBalance.toStringAsFixed(4)} SOL',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.green[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建安全警告
  Widget _buildSecurityWarning() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber,
            size: 20.w,
            color: Colors.red[600],
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '安全提示',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[700],
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '请仔细检查交易详情。一旦签名，交易将无法撤销。确保您信任此应用并理解交易内容。',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.red[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons(DAppSignatureRequestController controller) {
    return Column(
      children: [
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: controller.isLoading ? null : controller.onReject,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  side: BorderSide(color: Colors.grey[400]!),
                ),
                child: Text(
                  '拒绝',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF737373),
                  ),
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: ElevatedButton(
                onPressed: controller.isLoading ? null : controller.onApprove,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
                child: controller.isLoading
                    ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        '签名',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
