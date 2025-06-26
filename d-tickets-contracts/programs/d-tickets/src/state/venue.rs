use anchor_lang::prelude::*;
use crate::error::TicketError;

/// 场馆账户状态 - 使用 InitSpace 自动计算空间
#[account]
#[derive(InitSpace)]
pub struct VenueAccount {
    /// 创建者（主办方）钱包地址
    pub creator: Pubkey,
    /// 场馆名称
    #[max_len(100)]
    pub venue_name: String,
    /// 场馆地址
    #[max_len(500)]
    pub venue_address: String,
    /// 场馆总容量
    pub total_capacity: u32,
    /// 场馆描述
    #[max_len(1000)]
    pub venue_description: String,
    /// 场馆平面图的IPFS哈希（SVG或PNG/JPG格式）
    #[max_len(100)]
    pub floor_plan_hash: Option<String>,
    /// 座位图布局数据的IPFS哈希（JSON格式）
    #[max_len(100)]
    pub seat_map_hash: Option<String>,
    /// 场馆类型
    pub venue_type: VenueType,
    /// 场馆设施信息的IPFS哈希
    #[max_len(100)]
    pub facilities_info_hash: Option<String>,
    /// 场馆联系信息
    #[max_len(300)]
    pub contact_info: String,
    /// 场馆状态
    pub venue_status: VenueStatus,
    /// 创建时间戳
    pub created_at: i64,
    /// 最后更新时间戳
    pub updated_at: i64,
    /// PDA bump值（用于性能优化）
    pub bump: u8,
}

/// 场馆类型枚举
#[derive(AnchorSerialize, AnchorDeserialize, Clone, PartialEq, Eq, Debug, InitSpace)]
pub enum VenueType {
    /// 室内场馆
    Indoor,
    /// 室外场馆
    Outdoor,
    /// 体育场
    Stadium,
    /// 剧院
    Theater,
    /// 音乐厅
    Concert,
    /// 会议中心
    Convention,
    /// 展览馆
    Exhibition,
    /// 其他
    Other,
}

/// 场馆状态枚举
#[derive(AnchorSerialize, AnchorDeserialize, Clone, PartialEq, Eq, Debug, InitSpace)]
pub enum VenueStatus {
    /// 未使用状态（默认状态）
    Unused,
    /// 活跃状态
    Active,
    /// 维护中
    Maintenance,
    /// 已停用
    Inactive,
    /// 临时关闭
    TemporarilyClosed,
}

/// 座位区域配置
#[derive(AnchorSerialize, AnchorDeserialize, Clone, Debug, InitSpace)]
pub struct SeatArea {
    /// 区域ID
    #[max_len(50)]
    pub area_id: String,
    /// 区域名称
    #[max_len(100)]
    pub area_name: String,
    /// 该区域的座位数量
    pub seat_count: u32,
    /// 区域在平面图上的坐标信息（JSON格式）
    #[max_len(1000)]
    pub coordinates: String,
    /// 关联的票种ID（如果已关联）
    pub linked_ticket_type_id: Option<u8>,
}

/// 座位状态
#[derive(AnchorSerialize, AnchorDeserialize, Clone, PartialEq, Eq, Debug, InitSpace)]
pub enum SeatStatus {
    /// 可用
    Available,
    /// 已售出
    Sold,
    /// 已退票
    Refunded,
    /// 已核销
    Redeemed,
    /// 临时锁定（购买过程中）
    TempLocked,
    /// 不可用（维修、保留等）
    Unavailable,
}

/// 单个座位信息（用于链上状态追踪）- 使用 InitSpace
#[account]
#[derive(InitSpace)]
pub struct SeatAccount {
    /// 所属场馆
    pub venue: Pubkey,
    /// 所属票种（PDA种子中使用）
    pub ticket_type_key: Pubkey,
    /// 所属活动（如果已关联到具体活动）
    pub event: Option<Pubkey>,
    /// 座位编号（唯一标识）
    #[max_len(20)]
    pub seat_number: String,
    /// 所属区域ID
    #[max_len(20)]
    pub area_id: String,
    /// 排号
    #[max_len(10)]
    pub row_number: String,
    /// 座位号
    #[max_len(10)]
    pub seat_number_in_row: String,
    /// 座位状态
    pub seat_status: SeatStatus,
    /// 关联的NFT门票（如果已售出）
    pub ticket_nft: Option<Pubkey>,
    /// 关联的票种ID
    pub ticket_type_id: Option<u8>,
    /// 创建时间戳
    pub created_at: i64,
    /// 最后更新时间戳
    pub updated_at: i64,
    /// PDA bump值
    pub bump: u8,
}

/// 批量座位数据结构
#[derive(AnchorSerialize, AnchorDeserialize, Clone, Debug, InitSpace)]
pub struct SeatData {
    /// 座位编号
    #[max_len(20)]
    pub seat_number: String,
    /// 所属区域ID
    #[max_len(20)]
    pub area_id: String,
    /// 排号
    #[max_len(10)]
    pub row_number: String,
    /// 座位号
    #[max_len(10)]
    pub seat_number_in_row: String,
}

/// 座位状态更新数据结构
#[derive(AnchorSerialize, AnchorDeserialize, Clone, Debug, InitSpace)]
pub struct SeatStatusUpdate {
    /// 座位索引
    pub seat_index: u32,
    /// 新的座位状态
    pub new_status: SeatStatus,
    /// 购票者地址（仅当状态为 Sold 时需要）
    pub buyer: Option<Pubkey>,
    /// 座位详细信息（用于 NFT 元数据）
    pub seat_info: Option<SeatInfo>,
}

/// 座位详细信息结构体（用于 NFT 元数据）
#[derive(AnchorSerialize, AnchorDeserialize, Clone, Debug, InitSpace)]
pub struct SeatInfo {
    /// 座位编号
    #[max_len(20)]
    pub seat_number: String,
    /// 区域ID
    #[max_len(20)]
    pub area_id: String,
    /// 排号
    #[max_len(10)]
    pub row_number: String,
    /// 排内座位号
    #[max_len(10)]
    pub seat_number_in_row: String,
}

/// 座位状态管理账户 - 使用位图高效存储
#[account]
#[derive(InitSpace)]
pub struct SeatStatusMap {
    /// 所属活动
    pub event: Pubkey,
    /// 所属票种
    pub ticket_type: Pubkey,
    /// 座位布局IPFS哈希（详细座位信息）
    #[max_len(100)]
    pub seat_layout_hash: String,
    /// 座位索引映射IPFS哈希
    #[max_len(100)]
    pub seat_index_map_hash: String,
    /// 总座位数量
    pub total_seats: u32,
    /// 已售座位数量
    pub sold_seats: u32,
    /// 座位状态位图（每座位2位：00=可用，01=已售，10=锁定，11=不可用）
    /// 最多支持16000个座位（4000字节 * 8位 / 2位 = 16000座位）
    #[max_len(4000)]
    pub seat_status_bitmap: Vec<u8>,
    /// 创建时间
    pub created_at: i64,
    /// 更新时间
    pub updated_at: i64,
    /// PDA bump
    pub bump: u8,
}

impl SeatStatusMap {
    /// 初始化座位状态位图
    pub fn initialize_bitmap(&mut self, total_seats: u32) -> Result<()> {
        let bytes_needed = ((total_seats + 3) / 4) as usize; // 每4个座位需要1字节
        require!(bytes_needed <= 4000, TicketError::TooManySeats);
        
        self.seat_status_bitmap = vec![0u8; bytes_needed];
        self.total_seats = total_seats;
        Ok(())
    }
    
    /// 获取座位状态
    pub fn get_seat_status(&self, seat_index: u32) -> Result<SeatStatus> {
        require!(seat_index < self.total_seats, TicketError::InvalidSeatIndex);
        
        let byte_index = (seat_index / 4) as usize;
        let bit_index = (seat_index % 4) * 2;
        
        require!(byte_index < self.seat_status_bitmap.len(), TicketError::InvalidSeatIndex);
        
        let status_byte = self.seat_status_bitmap[byte_index];
        let status_bits = (status_byte >> bit_index) & 0x03;
        
        match status_bits {
            0 => Ok(SeatStatus::Available),
            1 => Ok(SeatStatus::Sold),
            2 => Ok(SeatStatus::TempLocked),
            3 => Ok(SeatStatus::Unavailable),
            _ => Err(TicketError::InvalidSeatStatus.into()),
        }
    }
    
    /// 更新座位状态
    pub fn update_seat_status(&mut self, seat_index: u32, new_status: SeatStatus) -> Result<()> {
        require!(seat_index < self.total_seats, TicketError::InvalidSeatIndex);
        
        let old_status = self.get_seat_status(seat_index)?;
        
        let byte_index = (seat_index / 4) as usize;
        let bit_index = (seat_index % 4) * 2;
        
        let status_bits = match new_status {
            SeatStatus::Available => 0,
            SeatStatus::Sold => 1,
            SeatStatus::TempLocked => 2,
            SeatStatus::Unavailable => 3,
            _ => return Err(TicketError::InvalidSeatStatus.into()),
        };
        
        // 清除原状态位
        self.seat_status_bitmap[byte_index] &= !(0x03 << bit_index);
        // 设置新状态位
        self.seat_status_bitmap[byte_index] |= status_bits << bit_index;
        
        // 更新计数器
        if old_status == SeatStatus::Sold && new_status != SeatStatus::Sold {
            self.sold_seats = self.sold_seats.saturating_sub(1);
        } else if old_status != SeatStatus::Sold && new_status == SeatStatus::Sold {
            self.sold_seats += 1;
        }
        
        self.updated_at = Clock::get()?.unix_timestamp;
        Ok(())
    }
    
    /// 批量更新座位状态
    pub fn batch_update_status(&mut self, updates: Vec<SeatStatusUpdate>) -> Result<()> {
        for update in updates {
            self.update_seat_status(update.seat_index, update.new_status)?;
        }
        Ok(())
    }
} 