use anchor_lang::prelude::*;

#[error_code]
pub enum TicketError {
    // ===== 通用错误 =====
    #[msg("无效的参数")]
    InvalidArgument,
    
    #[msg("操作未授权")]
    Unauthorized,
    
    #[msg("平台已暂停")]
    PlatformPaused,
    
    #[msg("数值溢出")]
    Overflow,
    
    #[msg("数值下溢")]
    Underflow,

    // ===== 活动相关错误 =====
    #[msg("活动不存在")]
    EventNotFound,
    
    #[msg("活动已存在")]
    EventAlreadyExists,
    
    #[msg("活动已取消")]
    EventCancelled,
    
    #[msg("活动已完成")]
    EventCompleted,
    
    #[msg("活动尚未开始")]
    EventNotStarted,
    
    #[msg("活动已结束")]
    EventEnded,
    
    #[msg("活动时间无效")]
    InvalidEventTime,
    
    #[msg("场馆容量无效")]
    InvalidVenueCapacity,

    // ===== 票务相关错误 =====
    #[msg("票种不存在")]
    TicketTypeNotFound,
    
    #[msg("票种已存在")]
    TicketTypeAlreadyExists,
    
    #[msg("门票不存在")]
    TicketNotFound,
    
    #[msg("门票库存不足")]
    InsufficientTicketSupply,
    
    #[msg("门票已售罄")]
    TicketSoldOut,
    
    #[msg("门票状态无效")]
    InvalidTicketStatus,
    
    #[msg("门票已被核销")]
    TicketAlreadyRedeemed,
    
    #[msg("门票不可转让")]
    TicketNotTransferable,
    
    #[msg("超出最大票种数量")]
    ExceedsMaxTicketTypes,
    
    #[msg("座位总数超出票种库存")]
    ExceedsTicketSupply,

    // ===== 定价相关错误 =====
    #[msg("价格无效")]
    InvalidPrice,
    
    #[msg("价格超出最小限制")]
    PriceBelowMinimum,
    
    #[msg("价格超出最大限制")]
    PriceAboveMaximum,
    
    #[msg("定价策略无效")]
    InvalidPricingStrategy,
    
    #[msg("动态定价规则无效")]
    InvalidDynamicPricingRule,
    
    #[msg("价格滑点超出允许范围")]
    PriceSlippageExceeded,

    // ===== 销售相关错误 =====
    #[msg("销售尚未开始")]
    SaleNotStarted,
    
    #[msg("销售已结束")]
    SaleEnded,
    
    #[msg("销售已开始，不能执行此操作")]
    SaleAlreadyStarted,
    
    #[msg("销售时间设置无效")]
    InvalidSaleTime,
    
    #[msg("购买数量无效")]
    InvalidPurchaseQuantity,
    
    #[msg("超出单次购买限制")]
    ExceedsPurchaseLimit,
    
    #[msg("支付金额不足")]
    InsufficientPayment,
    
    #[msg("支付金额过多")]
    ExcessivePayment,

    // ===== 退票相关错误 =====
    #[msg("不符合退票条件")]
    RefundNotAllowed,
    
    #[msg("退票已截止")]
    RefundDeadlinePassed,
    
    #[msg("门票已被退款")]
    TicketAlreadyRefunded,

    // ===== 二级市场相关错误 =====
    #[msg("挂单不存在")]
    ListingNotFound,
    
    #[msg("挂单已过期")]
    ListingExpired,
    
    #[msg("挂单已取消")]
    ListingCancelled,
    
    #[msg("挂单已售出")]
    ListingAlreadySold,
    
    #[msg("不能购买自己的挂单")]
    CannotBuyOwnListing,
    
    #[msg("版税比例无效")]
    InvalidRoyaltyRate,

    // ===== 权限相关错误 =====
    #[msg("非活动主办方")]
    NotEventOrganizer,
    
    #[msg("非门票持有者")]
    NotTicketOwner,
    
    #[msg("非平台管理员")]
    NotPlatformAdmin,
    
    #[msg("非授权验票员")]
    NotAuthorizedValidator,

    // ===== 时间相关错误 =====
    #[msg("时间戳无效")]
    InvalidTimestamp,
    
    #[msg("操作时间已过")]
    OperationTimeExpired,
    
    #[msg("操作时间未到")]
    OperationTimeNotReached,

    // ===== 账户相关错误 =====
    #[msg("账户初始化失败")]
    AccountInitializationFailed,
    
    #[msg("账户数据无效")]
    InvalidAccountData,
    
    #[msg("账户无效")]
    InvalidAccount,
    
    #[msg("账户空间不足")]
    InsufficientAccountSpace,
    
    #[msg("账户已关闭")]
    AccountClosed,

    // ===== NFT相关错误 =====
    #[msg("NFT铸造失败")]
    MintFailed,
    
    #[msg("NFT转移失败")]
    TransferFailed,
    
    #[msg("NFT销毁失败")]
    BurnFailed,
    
    #[msg("NFT元数据无效")]
    InvalidMetadata,
    
    #[msg("NFT不存在")]
    NFTNotFound,

    // ===== 收益相关错误 =====
    #[msg("余额不足")]
    InsufficientBalance,
    
    #[msg("提取金额过大")]
    WithdrawAmountTooLarge,
    
    #[msg("收益账户不存在")]
    EarningsAccountNotFound,
    
    #[msg("手续费计算错误")]
    FeeCalculationError,

    // ===== 数据验证错误 =====
    #[msg("字符串长度超限")]
    StringTooLong,
    
    #[msg("字符串长度无效")]
    InvalidStringLength,
    
    #[msg("数组长度超限")]
    ArrayTooLong,
    
    #[msg("必填字段为空")]
    RequiredFieldEmpty,
    
    #[msg("数据格式错误")]
    InvalidDataFormat,

    // ===== 业务逻辑错误 =====
    #[msg("操作序列错误")]
    InvalidOperationSequence,
    
    #[msg("状态转换无效")]
    InvalidStateTransition,
    
    #[msg("重复操作")]
    DuplicateOperation,
    
    #[msg("操作冲突")]
    OperationConflict,

    // ===== 票种删除相关错误 =====
    #[msg("票种已有门票售出，不能删除")]
    TicketAlreadySold,
    
    #[msg("票种已被铸造，不能删除")]
    TicketAlreadyMinted,

    // ===== 场馆相关错误 =====
    #[msg("场馆名称过长")]
    VenueNameTooLong,
    
    #[msg("场馆名称不匹配")]
    InvalidVenueName,
    
    #[msg("场馆地址过长")]
    VenueAddressTooLong,
    
    #[msg("场馆描述过长")]
    VenueDescriptionTooLong,
    
    #[msg("联系信息过长")]
    ContactInfoTooLong,
    
    #[msg("场馆容量无效")]
    InvalidCapacity,
    
    #[msg("哈希值无效")]
    InvalidHash,
    
    #[msg("场馆不存在")]
    VenueNotFound,
    
    #[msg("场馆已存在")]
    VenueAlreadyExists,

    // ===== 座位相关错误 =====
    #[msg("座位编号过长")]
    SeatNumberTooLong,
    
    #[msg("区域ID过长")]
    AreaIdTooLong,
    
    #[msg("排号过长")]
    RowNumberTooLong,
    
    #[msg("座位号过长")]
    SeatNumberInRowTooLong,
    
    #[msg("座位不存在")]
    SeatNotFound,
    
    #[msg("座位已存在")]
    SeatAlreadyExists,
    
    #[msg("座位不可用")]
    SeatNotAvailable,

    #[msg("批量座位数量过多")]
    TooManySeats,
    
    #[msg("座位索引无效")]
    InvalidSeatIndex,
    
    #[msg("座位状态无效")]
    InvalidSeatStatus,

    #[msg("存在已售座位，不能修改座位配置")]
    CannotModifyWithSoldSeats,

    #[msg("存在已售座位，不能删除座位状态映射")]
    CannotDeleteWithSoldSeats,

    // ===== 场馆删除相关错误 =====
    #[msg("非场馆拥有者")]
    NotVenueOwner,
    
    #[msg("场馆仍处于活跃状态，不能删除")]
    VenueStillActive,
    
    #[msg("只能删除未使用状态的场馆")]
    OnlyUnusedVenueCanBeDeleted,
    
    #[msg("场馆未激活")]
    VenueNotActive,
}
