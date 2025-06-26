const anchor = require('@coral-xyz/anchor');
const { Connection, PublicKey } = require('@solana/web3.js');

// 配置
const CONFIG = {
  // 根据你的环境调整RPC URL
  rpcUrl: 'http://localhost:8899', // 本地测试网
  // rpcUrl: 'https://api.devnet.solana.com', // Devnet
  
  // 你需要替换为实际的值
  programId: '4RmJgJPUEkBJu8etoeMSt6B62RGvMR7iviNQEyHThJHG', // 替换为你的程序ID
  
  // 活动信息 - 用于计算PDA
  organizerPublicKey: '2XM48QdtTv3dAHccUjVdZ2CF7Es3estfNRAqjjde8QdL', // 替换为主办方公钥
  eventName: '222', // 替换为活动名称
  
  // 或者直接提供活动PDA地址（如果已知）
  eventPDA: 'D12fnCPwddW85WskgPAjPpCmsYwWKpJW4LzutMiHBt3m', // 如果知道直接PDA地址，可以在这里设置
};

async function testEventQuery() {
  console.log('🚀 开始测试活动查询...\n');
  
  try {
    // 1. 建立连接
    console.log('📡 连接到 Solana 网络...');
    const connection = new Connection(CONFIG.rpcUrl, 'confirmed');
    console.log(`   RPC URL: ${CONFIG.rpcUrl}`);
    
    // 检查网络连接
    const version = await connection.getVersion();
    console.log(`   Solana 版本: ${version['solana-core']}\n`);
    
    // 2. 计算或使用活动PDA
    let eventPDA;
    
    if (CONFIG.eventPDA) {
      // 使用提供的PDA地址
      eventPDA = new PublicKey(CONFIG.eventPDA);
      console.log('📍 使用提供的活动PDA:');
    } else {
      // 计算PDA地址
      console.log('🧮 计算活动PDA...');
      console.log(`   程序ID: ${CONFIG.programId}`);
      console.log(`   主办方: ${CONFIG.organizerPublicKey}`);
      console.log(`   活动名称: ${CONFIG.eventName}`);
      
      const programId = new PublicKey(CONFIG.programId);
      const organizerKey = new PublicKey(CONFIG.organizerPublicKey);
      
      [eventPDA] = PublicKey.findProgramAddressSync(
        [
          Buffer.from("event"),
          organizerKey.toBuffer(),
          Buffer.from(CONFIG.eventName)
        ],
        programId
      );
      console.log('✅ PDA计算完成:');
    }
    
    console.log(`   活动PDA: ${eventPDA.toString()}\n`);
    
    // 3. 检查账户是否存在
    console.log('🔍 检查账户存在性...');
    const accountInfo = await connection.getAccountInfo(eventPDA);
    
    if (!accountInfo) {
      console.error('❌ 错误: 活动账户不存在!');
      console.log('💡 可能的原因:');
      console.log('   1. PDA计算错误');
      console.log('   2. 活动尚未创建');
      console.log('   3. 网络或程序ID错误');
      return;
    }
    
    console.log('✅ 账户存在');
    console.log(`   所有者: ${accountInfo.owner.toString()}`);
    console.log(`   数据大小: ${accountInfo.data.length} 字节`);
    console.log(`   余额: ${accountInfo.lamports} lamports\n`);
    
    // 4. 重点：手动解析账户数据
    console.log('🔧 手动解析账户数据 (因为IDL可能不匹配)...');
    parseEventAccountData(accountInfo.data);

    console.log('\n' + '✅'.repeat(20));
    console.log('✅ 查询完成!');
    console.log('✅'.repeat(20));
    
  } catch (error) {
    console.error('\n❌ 查询过程中发生错误:');
    console.error('错误类型:', error.constructor.name);
    console.error('错误信息:', error.message);
    
    if (error.logs) {
      console.error('程序日志:', error.logs);
    }
    
    console.error('\n完整错误:', error);
    
    console.log('\n💡 故障排除建议:');
    console.log('1. 检查配置中的所有地址是否正确');
    console.log('2. 确认程序已部署到正确的网络');
    console.log('3. **非常重要**: 确保 `target/idl/d_tickets.json` 文件是最新版本 (通过 `anchor build` 生成)');
  }
}

function parseEventAccountData(data) {
  try {
    console.log('\n' + '='.repeat(60));
    console.log('📋 活动详细信息 (手动解析)');
    console.log('='.repeat(60));
    
    let offset = 8; // 跳过 8 字节的 discriminator

    function readString(buffer, offset) {
      const length = buffer.readUInt32LE(offset);
      if (length > 1024 || length < 0) { // 安全检查
          throw new Error(`Invalid string length: ${length}`);
      }
      offset += 4;
      const str = buffer.slice(offset, offset + length).toString('utf-8');
      return { value: str, newOffset: offset + length };
    }
    
    const organizer = new PublicKey(data.slice(offset, offset + 32));
    offset += 32;
    console.log(`👤 主办方: ${organizer.toString()}`);

    let result = readString(data, offset);
    console.log(`🎭 活动名称: ${result.value}`);
    offset = result.newOffset;
    
    // event_description_hash
    result = readString(data, offset);
    offset = result.newOffset;

    // event_poster_image_hash
    result = readString(data, offset);
    offset = result.newOffset;

    // event_start_time
    offset += 8;
    // event_end_time
    offset += 8;
    // ticket_sale_start_time
    offset += 8;
    // ticket_sale_end_time
    offset += 8;

    // venue_account
    const venue_account = new PublicKey(data.slice(offset, offset + 32));
    offset += 32;
    console.log(`🏢 场馆: ${venue_account.toString()}`);
    
    // seat_map_hash (Option<String>)
    const hasSeatMapHash = data.readUInt8(offset) === 1;
    offset += 1;
    if (hasSeatMapHash) {
        result = readString(data, offset);
        offset = result.newOffset;
    }

    // event_category
    result = readString(data, offset);
    console.log(`🎯 活动分类: ${result.value}`);
    offset = result.newOffset;
    
    // performer_details_hash
    result = readString(data, offset);
    offset = result.newOffset;
    
    // contact_info_hash
    result = readString(data, offset);
    offset = result.newOffset;
    
    // event_status (enum)
    offset += 1;
    
    // refund_policy_hash
    result = readString(data, offset);
    offset = result.newOffset;
    
    // pricing_strategy_type (enum)
    offset += 1;
    
    // total_tickets_minted
    const total_tickets_minted = data.readUInt32LE(offset);
    offset += 4;
    console.log(`   已铸造门票: ${total_tickets_minted}`);

    // total_tickets_sold
    const total_tickets_sold = data.readUInt32LE(offset);
    offset += 4;
    console.log(`   已售出门票: ${total_tickets_sold}`);
    
    // total_tickets_refunded
    offset += 4;
    // total_tickets_resale_available
    offset += 4;
    
    // total_revenue
    const total_revenue = data.readBigInt64LE(offset);
    offset += 8;
    console.log(`   总收入: ${total_revenue.toString()} lamports`);

    // ticket_types_count
    const ticket_types_count = data.readUInt8(offset);
    offset += 1;
    console.log(`   票种数量: ${ticket_types_count}`);
    
    // 重点: 解析 ticket_area_mappings (Vec<String>)
    console.log('\n' + '🎯'.repeat(20));
    console.log('🎯 票种-区域映射信息（重点检查）');
    console.log('🎯'.repeat(20));
    
    const vecLength = data.readUInt32LE(offset);
    offset += 4;
    console.log(`📊 映射数量: ${vecLength}`);

    if (vecLength > 0 && vecLength < 100) { // 添加合理性检查
      console.log('✅ 找到票种-区域映射:');
      for (let i = 0; i < vecLength; i++) {
        result = readString(data, offset);
        offset = result.newOffset;
        
        const mapping = result.value;
        const parts = mapping.split('-');
        if (parts.length >= 2) {
            const ticketType = parts[0];
            const areaId = parts.slice(1).join('-');
            console.log(`   ${i + 1}. 票种: "${ticketType}" -> 区域: "${areaId}"`);
        } else {
            console.log(`   ${i + 1}. 原始映射: "${mapping}"`);
        }
      }
    } else if (vecLength === 0) {
      console.log('❌ 没有找到任何票种-区域映射!');
    } else {
      console.log(`⚠️  映射数量 (${vecLength}) 看起来不合理，可能数据解析错位。`);
    }

  } catch (e) {
    console.error('❌ 手动解析数据时发生错误:', e);
    console.log('💡 可能的原因: 账户数据结构与解析逻辑严重不符。请确保合约代码没有大的变动。');
  }
}

// 显示使用说明
function showUsageInstructions() {
  console.log('📖 使用说明:');
  console.log('1. 在文件顶部的 CONFIG 对象中设置正确的值');
  console.log('2. 运行: node test-event-query.js');
  console.log('');
  console.log('⚙️  需要配置的值:');
  console.log('   - programId: 你的程序ID');
  console.log('   - organizerPublicKey: 主办方公钥');
  console.log('   - eventName: 活动名称');
  console.log('   - 或直接设置 eventPDA 地址');
  console.log('');
  console.log('🔍 配置检查:');
  console.log(`   程序ID: ${CONFIG.programId}`);
  console.log(`   主办方: ${CONFIG.organizerPublicKey}`);
  console.log(`   活动名称: ${CONFIG.eventName}`);
  console.log(`   直接PDA: ${CONFIG.eventPDA || '(未设置)'}`);
  console.log('');
}

// 检查配置
function checkConfig() {
  const hasDirectPDA = CONFIG.eventPDA && CONFIG.eventPDA !== 'YOUR_EVENT_PDA_HERE';
  const hasPDAComponents = 
    CONFIG.programId !== 'YOUR_PROGRAM_ID_HERE' &&
    CONFIG.organizerPublicKey !== 'YOUR_ORGANIZER_PUBLIC_KEY_HERE' &&
    CONFIG.eventName !== 'YOUR_EVENT_NAME_HERE';
  
  if (!hasDirectPDA && !hasPDAComponents) {
    console.log('⚠️  配置不完整!');
    showUsageInstructions();
    return false;
  }
  
  return true;
}

// 主函数
async function main() {
  console.log('🎪 D-Tickets 活动查询测试工具');
  console.log('='.repeat(50));
  console.log('');
  
  if (!checkConfig()) {
    process.exit(1);
  }
  
  await testEventQuery();
}

// 运行测试
if (require.main === module) {
  main().catch(console.error);
}

module.exports = { testEventQuery, CONFIG }; 