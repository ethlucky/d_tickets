import 'package:get/get.dart';
import '../controllers/solana_controller.dart';
import '../controllers/theme_controller.dart';
import '../controllers/language_controller.dart';
import '../services/solana_service.dart';
import '../services/contract_service.dart';
import '../services/arweave_service.dart';
import '../services/mobile_wallet_service.dart';
import '../services/nft_service.dart';

/// 全局依赖注入绑定
class AppBinding extends Bindings {
  @override
  void dependencies() {
    // 服务层依赖注入 - 优先级顺序很重要
    // 1. 首先初始化SolanaService（基础服务）
    Get.lazyPut<SolanaService>(() => SolanaService(), fenix: true);

    // 2. 然后初始化依赖SolanaService的ContractService
    Get.lazyPut<ContractService>(() => ContractService(), fenix: true);

    // 3. 初始化ArweaveService（图片数据服务）
    Get.lazyPut<ArweaveService>(() => ArweaveService(), fenix: true);

    // 4. 初始化MobileWalletService（移动钱包服务）
    Get.lazyPut<MobileWalletService>(() => MobileWalletService(), fenix: true);

    // 5. 初始化NFTService（NFT票券服务）
    Get.lazyPut<NFTService>(() => NFTService(), fenix: true);

    // 控制器依赖注入 - 懒加载
    Get.lazyPut<SolanaController>(() => SolanaController(), fenix: true);
    Get.lazyPut<ThemeController>(() => ThemeController(), fenix: true);
    Get.lazyPut<LanguageController>(() => LanguageController(), fenix: true);
  }
}
