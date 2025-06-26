const anchor = require("@coral-xyz/anchor");
const { PublicKey, SystemProgram } = anchor.web3;

/**
 * Setup Platform 初始化脚本
 * 
 * 这个脚本会：
 * 1. 检查platform账户是否存在
 * 2. 如果不存在，初始化platform账户
 * 3. 如果存在，显示当前配置并可选择更新
 */
async function setupPlatform() {
  console.log("🚀 开始设置D-Tickets平台...\n");

  // 设置环境
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);
  const program = anchor.workspace.dTickets;

  try {
    // 获取platform账户地址
    const [platformPda, bump] = PublicKey.findProgramAddressSync(
      [Buffer.from("platform")],
      program.programId
    );

    console.log("📍 Platform信息:");
    console.log(`   PDA: ${platformPda.toString()}`);
    console.log(`   Bump: ${bump}`);
    console.log(`   管理员: ${provider.wallet.publicKey.toString()}`);
    console.log(`   程序ID: ${program.programId.toString()}\n`);

    // 检查platform账户是否已存在
    let platformAccount = null;
    let exists = false;
    
    try {
      platformAccount = await program.account.platformAccount.fetch(platformPda);
      exists = true;
      console.log("✅ Platform账户已存在");
    } catch (error) {
      console.log("ℹ️ Platform账户不存在，将进行初始化");
    }

    if (exists) {
      // 显示当前配置
      console.log("\n📊 当前Platform配置:");
      console.log(`   管理员: ${platformAccount.admin.toString()}`);
      console.log(`   平台手续费: ${platformAccount.platformFeeBps} bps (${(platformAccount.platformFeeBps / 100).toFixed(2)}%)`);
      console.log(`   收款地址: ${platformAccount.feeRecipient.toString()}`);
      console.log(`   暂停状态: ${platformAccount.isPaused ? '已暂停' : '正常运行'}`);
      console.log(`   最小票价: ${platformAccount.minTicketPrice} lamports (${(platformAccount.minTicketPrice / 1000000000).toFixed(3)} SOL)`);
      console.log(`   最大票价: ${platformAccount.maxTicketPrice} lamports (${(platformAccount.maxTicketPrice / 1000000000).toFixed(0)} SOL)`);
      console.log(`   总交易数: ${platformAccount.totalTransactions.toString()}`);
      console.log(`   总平台收入: ${platformAccount.totalPlatformRevenue.toString()} lamports`);
      console.log(`   创建时间: ${new Date(platformAccount.createdAt.toNumber() * 1000).toLocaleString()}`);
      console.log(`   更新时间: ${new Date(platformAccount.updatedAt.toNumber() * 1000).toLocaleString()}`);
      
      // 检查是否是同一个管理员
      if (!platformAccount.admin.equals(provider.wallet.publicKey)) {
        console.log(`\n⚠️ 警告: 当前钱包不是平台管理员！`);
        console.log(`   平台管理员: ${platformAccount.admin.toString()}`);
        console.log(`   当前钱包: ${provider.wallet.publicKey.toString()}`);
        return;
      }

      console.log("\n🔄 您可以选择更新平台设置...");
    }

    // 设置默认参数
    const setupParams = {
      platformFeeBps: exists ? null : 250, // 如果已存在则不更新，新建时设为2.5%
      newFeeRecipient: null, // 使用默认收款地址
      newIsPaused: exists ? null : false, // 如果已存在则不更新，新建时设为不暂停
    };

    console.log("\n⚙️ 执行setup_platform指令...");
    console.log("参数配置:");
    console.log(`   platformFeeBps: ${setupParams.platformFeeBps ?? 'null (保持现有)'}`);
    console.log(`   newFeeRecipient: ${setupParams.newFeeRecipient ?? 'null (使用默认)'}`);
    console.log(`   newIsPaused: ${setupParams.newIsPaused ?? 'null (保持现有)'}`);

    // 执行setup_platform指令
    const tx = await program.methods
      .setupPlatform(
        setupParams.platformFeeBps,
        setupParams.newFeeRecipient,
        setupParams.newIsPaused
      )
      .accounts({
        platform: platformPda,
        admin: provider.wallet.publicKey,
        feeRecipient: null,
        systemProgram: SystemProgram.programId,
      })
      .rpc();

    console.log(`\n✅ 交易成功! 签名: ${tx}`);

    // 重新获取并显示最新配置
    console.log("\n🎉 Platform设置完成! 最新配置:");
    platformAccount = await program.account.platformAccount.fetch(platformPda);
    console.log(`   管理员: ${platformAccount.admin.toString()}`);
    console.log(`   平台手续费: ${platformAccount.platformFeeBps} bps (${(platformAccount.platformFeeBps / 100).toFixed(2)}%)`);
    console.log(`   收款地址: ${platformAccount.feeRecipient.toString()}`);
    console.log(`   暂停状态: ${platformAccount.isPaused ? '已暂停' : '正常运行'}`);
    console.log(`   更新时间: ${new Date(platformAccount.updatedAt.toNumber() * 1000).toLocaleString()}`);

    console.log("\n🎊 Platform设置完成! 现在可以创建活动了!");
    
  } catch (error) {
    console.error("❌ 设置失败:", error);
    
    // 提供一些常见错误的解决建议
    if (error.message.includes("Account does not exist")) {
      console.log("\n💡 建议: 请确保本地验证器正在运行");
    } else if (error.message.includes("Unauthorized")) {
      console.log("\n💡 建议: 请确保您是平台管理员");
    } else if (error.message.includes("InvalidArgument")) {
      console.log("\n💡 建议: 请检查参数是否在有效范围内");
    }
  }
}

// 如果直接运行此脚本
if (require.main === module) {
  setupPlatform()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error("脚本执行失败:", error);
      process.exit(1);
    });
}

module.exports = { setupPlatform }; 