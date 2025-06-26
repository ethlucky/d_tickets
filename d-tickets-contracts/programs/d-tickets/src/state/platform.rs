use anchor_lang::prelude::*;

/// 平台配置账户
#[account]
#[derive(InitSpace)]
pub struct PlatformAccount {
    /// 平台管理员
    pub admin: Pubkey,
    /// 平台手续费（基点，1 bps = 0.01%）
    pub platform_fee_bps: u16,
    /// 平台收入账户
    pub fee_recipient: Pubkey,
    /// 平台是否暂停
    pub is_paused: bool,
    /// 最低票价（防止恶意低价）
    pub min_ticket_price: u64,
    /// 最高票价（防止恶意高价）
    pub max_ticket_price: u64,
    /// 支持的代币mints
    #[max_len(5)]
    pub supported_tokens: Vec<Pubkey>,
    /// 平台总收入
    pub total_platform_revenue: u64,
    /// 平台总交易数
    pub total_transactions: u64,
    /// PDA bump值（用于性能优化）
    pub bump: u8,
    /// 创建时间
    pub created_at: i64,
    /// 最后更新时间
    pub updated_at: i64,
    /// 预留空间
    pub _reserved: [u8; 63], // 减少1字节给bump
}



/// 主办方收益账户
#[account]
#[derive(InitSpace)]
pub struct OrganizerEarnings {
    /// 主办方地址
    pub organizer: Pubkey,
    /// 活动地址
    pub event: Pubkey,
    /// 总收益
    pub total_earnings: u64,
    /// 已提取金额
    pub withdrawn_amount: u64,
    /// 待提取金额
    pub pending_amount: u64,
    /// 版税收益（二级市场）
    pub royalty_earnings: u64,
    /// 最后提取时间
    pub last_withdrawal_at: Option<i64>,
    /// 提取次数
    pub withdrawal_count: u32,
    /// PDA bump值（用于性能优化）
    pub bump: u8,
    /// 预留空间
    pub _reserved: [u8; 31], // 减少1字节给bump
}

 