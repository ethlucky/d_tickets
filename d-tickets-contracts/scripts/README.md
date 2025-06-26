# D-Tickets 初始化脚本

本目录包含D-Tickets平台的初始化和管理脚本。

## 脚本列表

### 🚀 quickstart.js - 快速启动脚本
完整的项目初始化脚本，包含环境检查和platform设置。

**使用方法:**
```bash
# 使用npm script
yarn quickstart
# 或直接运行
node scripts/quickstart.js
```

**功能:**
- ✅ 检查环境配置（RPC URL、钱包、余额）
- ✅ 自动设置platform账户
- ✅ 提供后续操作指南
- ✅ 错误处理和故障排除建议

### ⚙️ setup_platform.js - Platform设置脚本
专门用于platform账户的初始化和管理。

**使用方法:**
```bash
# 使用npm script
yarn setup-platform
# 或直接运行
node scripts/setup_platform.js
```

**功能:**
- ✅ 自动检测platform账户是否存在
- ✅ 如果不存在，创建新的platform账户
- ✅ 如果存在，显示当前配置
- ✅ 支持更新platform设置
- ✅ 管理员权限验证

## 使用前准备

### 1. 启动本地验证器
```bash
solana-test-validator
```

### 2. 配置Solana CLI
```bash
# 设置为本地网络
solana config set --url localhost

# 检查配置
solana config get
```

### 3. 确保钱包有足够余额
```bash
# 查看余额
solana balance

# 如果余额不足，可以空投一些SOL（仅限本地网络）
solana airdrop 5
```

### 4. 编译项目
```bash
anchor build
```

## 使用流程

### 🎯 推荐流程（新项目）

1. **启动验证器**
   ```bash
   solana-test-validator
   ```

2. **运行快速启动**
   ```bash
   yarn quickstart
   ```

3. **根据输出指南进行后续操作**

### 🔧 手动流程

1. **仅设置platform**
   ```bash
   yarn setup-platform
   ```

2. **创建活动**（在你的前端代码中调用）
   ```javascript
   await program.methods.createEvent(...)
   ```

## 参数说明

### Setup Platform 参数

- **platformFeeBps**: 平台手续费（基点）
  - 默认: 250 (2.5%)
  - 范围: 0-1000 (0%-10%)

- **newFeeRecipient**: 收款地址
  - 默认: 使用常量中定义的默认地址
  - 可选: 任何有效的Solana地址

- **newIsPaused**: 平台暂停状态
  - 默认: false (正常运行)
  - 可选: true (暂停平台)

## 错误处理

### 常见错误和解决方案

1. **"Account does not exist"**
   - 确保本地验证器正在运行
   - 检查RPC连接是否正常

2. **"Unauthorized"**
   - 确保当前钱包是platform管理员
   - 检查钱包配置

3. **"InvalidArgument"**
   - 检查参数是否在有效范围内
   - 手续费不能超过10%

4. **"HTTP 502 Bad Gateway"**
   - 本地验证器未运行或未完全启动
   - 等待几秒后重试

## 脚本输出示例

```
🎫 欢迎使用D-Tickets去中心化票务系统!

🔍 检查环境配置...
✅ RPC URL: http://localhost:8899
✅ 钱包: 9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM
✅ 余额: 499.9995 SOL

==================================================
🚀 开始设置D-Tickets平台...

📍 Platform信息:
   PDA: 7xKXwzj4kTbNKhEeDaLh4WBKhF3sJKmCs8k34bKhKZ8a
   Bump: 255
   管理员: 9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM
   程序ID: EiFFwrg9Fx9qob7289i1SMZkd6aciLb9D4sCguom2aHd

ℹ️ Platform账户不存在，将进行初始化

⚙️ 执行setup_platform指令...
参数配置:
   platformFeeBps: 250
   newFeeRecipient: null (使用默认)
   newIsPaused: false

✅ 交易成功! 签名: 5KrVmYzZZr...

🎉 Platform设置完成! 最新配置:
   管理员: 9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM
   平台手续费: 250 bps (2.50%)
   收款地址: 11111111111111111111111111111112
   暂停状态: 正常运行
   更新时间: 2024-1-15 下午3:45:23

🎊 Platform设置完成! 现在可以创建活动了!
```

## 注意事项

1. **安全性**: 生产环境中请使用硬件钱包或多重签名
2. **网络**: 确保在正确的网络上操作（localnet/devnet/mainnet）
3. **备份**: 妥善保管钱包私钥和助记词
4. **测试**: 在主网部署前请在devnet充分测试

## 技术支持

如果遇到问题，请检查：
1. Anchor版本是否正确 (0.31.1)
2. Solana CLI是否最新
3. Node.js版本是否兼容
4. 网络连接是否正常 