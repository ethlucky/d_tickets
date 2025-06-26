const anchor = require("@coral-xyz/anchor");
const { setupPlatform } = require("./setup_platform");

/**
 * D-Tickets 快速启动脚本
 * 
 * 这个脚本会：
 * 1. 检查环境配置
 * 2. 设置platform
 * 3. 提供后续操作指南
 */
async function quickstart() {
  console.log("🎫 欢迎使用D-Tickets去中心化票务系统!\n");

  try {
    // 检查环境
    console.log("🔍 检查环境配置...");
    const provider = anchor.AnchorProvider.env();
    console.log(`✅ RPC URL: ${provider.connection.rpcEndpoint}`);
    console.log(`✅ 钱包: ${provider.wallet.publicKey.toString()}`);
    
    // 检查钱包余额
    const balance = await provider.connection.getBalance(provider.wallet.publicKey);
    console.log(`✅ 余额: ${(balance / 1000000000).toFixed(4)} SOL`);
    
    if (balance < 1000000000) { // 少于1 SOL
      console.log("⚠️ 警告: 钱包余额较低，可能无法完成交易");
    }

    console.log("\n" + "=".repeat(50));
    
    // 设置platform
    await setupPlatform();
    
    console.log("\n" + "=".repeat(50));
    console.log("🎉 快速启动完成!\n");
    
    // 提供后续操作指南
    console.log("📝 后续操作指南:");
    console.log("1. 创建活动:");
    console.log("   - 使用 create_event 指令创建新活动");
    console.log("   - 活动需要包含活动信息、时间、地点等");
    
    console.log("\n2. 添加票种:");
    console.log("   - 使用 add_ticket_type 指令为活动添加不同类型的票");
    console.log("   - 可设置价格、数量、转售版税等");
    
    console.log("\n3. 铸造门票:");
    console.log("   - 使用 mint_tickets 指令批量铸造门票NFT");
    
    console.log("\n4. 测试购票:");
    console.log("   - 使用 purchase_ticket 指令测试购票流程");
    
    console.log("\n📚 更多信息:");
    console.log("   - 查看 tests/ 目录中的测试案例");
    console.log("   - 阅读 programs/d-tickets/src/ 中的智能合约代码");
    console.log("   - 运行 'anchor test' 执行完整测试");
    
    console.log("\n🎊 祝您使用愉快!");
    
  } catch (error) {
    console.error("❌ 快速启动失败:", error);
    console.log("\n🔧 故障排除:");
    console.log("1. 确保本地Solana验证器正在运行:");
    console.log("   solana-test-validator");
    console.log("\n2. 确保钱包有足够的SOL余额");
    console.log("\n3. 确保Anchor配置正确:");
    console.log("   anchor test");
  }
}

// 运行快速启动
if (require.main === module) {
  quickstart()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error("快速启动脚本执行失败:", error);
      process.exit(1);
    });
}

module.exports = { quickstart }; 