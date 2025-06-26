import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121A21),
      body: SafeArea(
        child: Column(
          children: [
            // 背景图片和内容区域
            Expanded(
              child: Stack(
                children: [
                  // 背景图片区域
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFF121A21),
                      image: DecorationImage(
                        image:
                            AssetImage('assets/images/splash_background.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // 渐变遮罩
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF121A21).withOpacity(0.3),
                          const Color(0xFF121A21).withOpacity(0.7),
                          const Color(0xFF121A21),
                        ],
                        stops: const [0.0, 0.4, 0.7, 1.0],
                      ),
                    ),
                  ),
                  // 标题和副标题
                  Positioned(
                    bottom: 200,
                    left: 16,
                    right: 16,
                    child: Column(
                      children: [
                        // Flash Tickets 标题
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 20,
                          ),
                          child: const Text(
                            'Flash Tickets',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.w700,
                              fontSize: 28,
                              height: 1.25,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        // 副标题
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: const Text(
                            'Experience the event, before it starts',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.w400,
                              fontSize: 16,
                              height: 1.5,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Connect Wallet 按钮
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: controller.connectWallet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF127AEB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Connect Wallet',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            // 底部间距
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
