import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dapp_connection_request_controller.dart';
import '../../widgets/app_bar_widget.dart';

/// DApp 连接请求页面
class DAppConnectionRequestPage extends StatelessWidget {
  const DAppConnectionRequestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DAppConnectionRequestController());

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBarWidget(
        title: '连接请求',
        showBackButton: true,
        onBackPressed: () => controller.onReject(),
      ),
      body: GetBuilder<DAppConnectionRequestController>(
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

                          // 权限说明
                          _buildPermissionsCard(controller),
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
  Widget _buildDAppInfoCard(DAppConnectionRequestController controller) {
    final request = controller.connectionRequest;
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
                    color: Colors.blue[50],
                  ),
                  child: request.dappIcon != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: Image.network(
                            request.dappIcon!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.apps,
                                size: 24.w,
                                color: Colors.blue[600],
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.apps,
                          size: 24.w,
                          color: Colors.blue[600],
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
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20.w,
                    color: Colors.blue[600],
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      '该应用想要连接到您的钱包',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.blue[700],
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

  /// 构建权限说明卡片
  Widget _buildPermissionsCard(DAppConnectionRequestController controller) {
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
              '连接后该应用将能够：',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF141414),
              ),
            ),
            SizedBox(height: 16.h),
            _buildPermissionItem(
              icon: Icons.visibility,
              title: '查看您的钱包地址',
              description: '应用可以查看您的公钥地址',
            ),
            SizedBox(height: 12.h),
            _buildPermissionItem(
              icon: Icons.account_balance_wallet,
              title: '查看账户余额',
              description: '应用可以查看您的 SOL 和代币余额',
            ),
            SizedBox(height: 12.h),
            _buildPermissionItem(
              icon: Icons.edit,
              title: '请求交易签名',
              description: '应用可以请求您签名交易（需要您确认）',
            ),
          ],
        ),
      ),
    );
  }

  /// 构建权限项目
  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32.w,
          height: 32.w,
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            icon,
            size: 16.w,
            color: Colors.green[600],
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF141414),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFF737373),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建钱包信息卡片
  Widget _buildWalletInfoCard(DAppConnectionRequestController controller) {
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
              '连接的钱包',
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
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    size: 20.w,
                    color: Colors.purple[600],
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
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber,
            size: 20.w,
            color: Colors.orange[600],
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
                    color: Colors.orange[700],
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '请确保您信任此应用。连接后，应用可以查看您的钱包信息并请求交易签名。',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.orange[600],
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
  Widget _buildActionButtons(DAppConnectionRequestController controller) {
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
                  backgroundColor: Colors.blue[600],
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
                        '连接',
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
