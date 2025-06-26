use anchor_lang::prelude::*;

/// 门票NFT账户状态
#[account]
#[derive(InitSpace)]
pub struct TicketAccount {
    /// 所属活动
    pub event: Pubkey,
    /// 票种名称
    #[max_len(50)]
    pub ticket_type_name: String,
    /// 门票NFT的mint地址
    pub mint: Pubkey,
    /// 当前持有者
    pub current_owner: Pubkey,
    /// 原始购买者
    pub original_buyer: Pubkey,
    /// 座位号（如果适用）
    #[max_len(20)]
    pub seat_number: Option<String>,
    /// 原始购买价格
    pub original_price: u64,
    /// 当前状态
    pub current_status: TicketStatus,
    /// 购买时间戳
    pub purchased_at: i64,
    /// 核销时间戳（如果已核销）
    pub redeemed_at: Option<i64>,
    /// NFT元数据的IPFS哈希
    #[max_len(46)]
    pub metadata_hash: String,
    /// 是否允许转售
    pub transferable: bool,
    /// 转售次数
    pub transfer_count: u32,
    /// 最后转售时间
    pub last_transfer_at: Option<i64>,
    /// PDA bump值（用于性能优化）
    pub bump: u8,
    /// 预留空间
    pub _reserved: [u8; 31], // 减少1字节给bump
}



/// 门票状态枚举
#[derive(AnchorSerialize, AnchorDeserialize, Clone, PartialEq, Eq, Debug, InitSpace)]
pub enum TicketStatus {
    /// 已铸造（未售出）
    Minted,
    /// 已售出（有效）
    Sold,
    /// 已转让
    Transferred,
    /// 已核销（已入场）
    Redeemed,
    /// 已退款
    Refunded,
    /// 已销毁
    Burned,
    /// 可再次售卖（退票后）
    AvailableForResale,
    /// 二级市场挂单中
    ListedForSale,
}

/// 门票转售记录
#[account]
#[derive(InitSpace)]
pub struct TicketTransferRecord {
    /// 门票账户
    pub ticket: Pubkey,
    /// 转让方
    pub from: Pubkey,
    /// 接收方
    pub to: Pubkey,
    /// 转售价格
    pub price: u64,
    /// 版税金额
    pub royalty_amount: u64,
    /// 平台手续费
    pub platform_fee: u64,
    /// 转让时间戳
    pub transferred_at: i64,
    /// 转让类型
    pub transfer_type: TransferType,
}



/// 转让类型
#[derive(AnchorSerialize, AnchorDeserialize, Clone, PartialEq, Eq, Debug, InitSpace)]
pub enum TransferType {
    /// 首次购买
    InitialPurchase,
    /// 二级市场转售
    SecondaryMarketSale,
    /// 赠送转让
    Gift,
    /// 退票回收
    Refund,
}

/// 市场挂单状态枚举
#[derive(AnchorSerialize, AnchorDeserialize, Clone, Copy, PartialEq, Eq, Debug, InitSpace)]
pub enum ListingStatus {
    /// 活跃挂单
    Active,
    /// 已售出
    Sold,
    /// 已取消
    Cancelled,
    /// 已过期
    Expired,
}

/// 票务市场挂单信息
#[account]
#[derive(InitSpace)]
pub struct MarketplaceListingAccount {
    /// 挂单的门票mint
    pub ticket_mint: Pubkey,
    /// 卖家地址
    pub seller: Pubkey,
    /// 挂单价格
    pub price: u64,
    /// 挂单时间
    pub listed_at: i64,
    /// 挂单状态
    pub status: ListingStatus,
    /// 买家地址（如果已售出）
    pub buyer: Option<Pubkey>,
    /// 售出时间
    pub sold_at: Option<i64>,
    /// 实际成交价格
    pub sold_price: Option<u64>,
    /// 版税比例（基点）
    pub royalty_bps: u16,
    /// 平台手续费（基点）
    pub platform_fee_bps: u16,
    /// PDA bump值（用于性能优化）
    pub bump: u8,
    /// 预留空间
    pub _reserved: [u8; 31], // 减少1字节给bump
}

 