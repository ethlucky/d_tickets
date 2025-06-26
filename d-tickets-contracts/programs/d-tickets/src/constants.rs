/// 程序种子常量
pub const PLATFORM_SEED: &[u8] = b"platform";
pub const EVENT_SEED: &[u8] = b"event";
pub const TICKET_TYPE_SEED: &[u8] = b"ticket_type";
pub const TICKET_SEED: &[u8] = b"ticket";
pub const TICKET_MINT_SEED: &[u8] = b"ticket_mint";
pub const EARNINGS_SEED: &[u8] = b"earnings";
pub const MARKETPLACE_LISTING_SEED: &[u8] = b"marketplace_listing";
pub const MARKETPLACE_TRANSACTION_SEED: &[u8] = b"marketplace_transaction";
pub const TRANSFER_RECORD_SEED: &[u8] = b"transfer_record";

/// 业务常量
pub const MAX_EVENT_NAME_LENGTH: usize = 100;
pub const MAX_VENUE_NAME_LENGTH: usize = 100;
pub const MAX_VENUE_ADDRESS_LENGTH: usize = 200;
pub const MAX_CATEGORY_LENGTH: usize = 50;
pub const MAX_TICKET_TYPE_NAME_LENGTH: usize = 50;
pub const MAX_SEAT_NUMBER_LENGTH: usize = 20;
pub const IPFS_HASH_LENGTH: usize = 46;

/// 票务限制常量
pub const MAX_TICKET_TYPES_PER_EVENT: u8 = 10;
pub const MAX_TICKETS_PER_PURCHASE: u32 = 10;
pub const MIN_TICKET_PRICE: u64 = 1_000_000; // 0.001 SOL
pub const MAX_TICKET_PRICE: u64 = 1_000_000_000_000; // 1000 SOL

/// 手续费常量（基点）
pub const MAX_PLATFORM_FEE_BPS: u16 = 1000; // 10%
pub const MAX_ROYALTY_BPS: u16 = 2500; // 25%
pub const DEFAULT_PLATFORM_FEE_BPS: u16 = 250; // 2.5%
pub const BASIS_POINTS_DIVISOR: u64 = 10000;

/// 默认收款地址（可以在运行时修改）
pub const DEFAULT_FEE_RECIPIENT: &str = "4RmJgJPUEkBJu8etoeMSt6B62RGvMR7iviNQEyHThJHG"; // System Program地址作为占位符

/// 时间常量
pub const MIN_SALE_DURATION: i64 = 3600; // 1小时
pub const MAX_SALE_DURATION: i64 = 365 * 24 * 3600; // 1年
pub const MIN_EVENT_NOTICE: i64 = 24 * 3600; // 24小时
pub const DEFAULT_LISTING_DURATION: i64 = 30 * 24 * 3600; // 30天

/// 动态定价常量
pub const MAX_PRICE_INCREASE_BPS: i16 = 5000; // 最大涨价50%
pub const MAX_PRICE_DECREASE_BPS: i16 = -2000; // 最大降价20%
pub const PRICING_UPDATE_INTERVAL: i64 = 3600; // 价格更新间隔1小时

/// NFT相关常量
pub const NFT_SYMBOL: &str = "DTIX";
pub const NFT_CREATOR_ROYALTY_BPS: u16 = 500; // 5%

/// 账户discriminator偏移量
pub const DISCRIMINATOR_LENGTH: usize = 8;
