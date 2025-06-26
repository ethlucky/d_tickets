use anchor_lang::prelude::*;

/// 活动账户状态 - 关联场馆版本
#[account]
#[derive(InitSpace)]
pub struct EventAccount {
    /// 主办方钱包地址
    pub organizer: Pubkey,
    /// 活动名称
    #[max_len(100)]
    pub event_name: String,
    /// 活动详细描述的IPFS哈希
    #[max_len(100)]
    pub event_description_hash: String,
    /// 活动海报图片的IPFS哈希
    #[max_len(100)]
    pub event_poster_image_hash: String,
    /// 活动开始时间戳
    pub event_start_time: i64,
    /// 活动结束时间戳
    pub event_end_time: i64,
    /// 门票开始销售时间戳
    pub ticket_sale_start_time: i64,
    /// 门票销售结束时间戳
    pub ticket_sale_end_time: i64,
    /// 关联的场馆账户（必填，引用已创建的场馆）
    pub venue_account: Pubkey,
    /// 座位图布局数据的IPFS哈希（JSON格式，可覆盖场馆默认座位图）
    #[max_len(100)]
    pub seat_map_hash: Option<String>,
    /// 活动分类
    #[max_len(50)]
    pub event_category: String,
    /// 表演者详细信息的IPFS哈希
    #[max_len(100)]
    pub performer_details_hash: String,
    /// 联系信息的IPFS哈希
    #[max_len(100)]
    pub contact_info_hash: String,
    /// 活动当前状态
    pub event_status: EventStatus,
    /// 退票政策的IPFS哈希
    #[max_len(100)]
    pub refund_policy_hash: String,
    /// 定价策略类型
    pub pricing_strategy_type: PricingStrategyType,
    /// 已铸造的门票总数
    pub total_tickets_minted: u32,
    /// 已售出的门票总数
    pub total_tickets_sold: u32,
    /// 已退款的门票总数
    pub total_tickets_refunded: u32,
    /// 退票后可再次销售的门票总数
    pub total_tickets_resale_available: u32,
    /// 总收入（以lamports计算）
    pub total_revenue: u64,
    /// 票种数量
    pub ticket_types_count: u8,
    /// 活动关联的票种-区域ID列表（格式：票种名-区域ID，最多50个项目，每个最长50字符）
    #[max_len(50, 50)]
    pub ticket_area_mappings: Vec<String>,
    /// PDA bump值（用于性能优化）
    pub bump: u8,
    /// 创建时间戳
    pub created_at: i64,
    /// 最后更新时间戳
    pub updated_at: i64,
}



impl EventAccount {
    /// 添加票种-区域映射到活动
    pub fn add_ticket_area_mapping(&mut self, ticket_type_name: &str, area_id: &str) -> Result<()> {
        // 创建拼接字符串，格式为：票种名-区域ID
        let mapping = format!("{}-{}", ticket_type_name, area_id);
        
        msg!("尝试添加票种-区域映射: {} (票种: {}, 区域: {})", mapping, ticket_type_name, area_id);
        
        // 验证拼接后字符串长度
        require!(mapping.len() <= 50, crate::error::TicketError::InvalidStringLength);
        
        // 检查是否已存在
        if !self.ticket_area_mappings.contains(&mapping) {
            // 检查数量限制
            require!(self.ticket_area_mappings.len() < 50, crate::error::TicketError::TooManySeats);
            
            msg!("添加新的票种-区域映射: {}, 当前映射总数: {} -> {}", 
                mapping, 
                self.ticket_area_mappings.len(), 
                self.ticket_area_mappings.len() + 1
            );
            
            self.ticket_area_mappings.push(mapping.clone());
            self.updated_at = Clock::get()?.unix_timestamp;
            
            msg!("票种-区域映射添加成功: {}", mapping);
        } else {
            msg!("票种-区域映射已存在，跳过添加: {}", mapping);
        }
        
        Ok(())
    }
    
    /// 从活动中删除票种-区域映射
    pub fn remove_ticket_area_mapping(&mut self, ticket_type_name: &str, area_id: &str) -> Result<()> {
        let mapping = format!("{}-{}", ticket_type_name, area_id);
        
        if let Some(index) = self.ticket_area_mappings.iter().position(|x| x == &mapping) {
            self.ticket_area_mappings.remove(index);
            self.updated_at = Clock::get()?.unix_timestamp;
        }
        
        Ok(())
    }
    
    /// 检查票种-区域映射是否存在
    pub fn has_ticket_area_mapping(&self, ticket_type_name: &str, area_id: &str) -> bool {
        let mapping = format!("{}-{}", ticket_type_name, area_id);
        self.ticket_area_mappings.contains(&mapping)
    }
    
    /// 获取特定票种的所有区域ID
    pub fn get_areas_for_ticket_type(&self, ticket_type_name: &str) -> Vec<String> {
        let prefix = format!("{}-", ticket_type_name);
        self.ticket_area_mappings
            .iter()
            .filter(|mapping| mapping.starts_with(&prefix))
            .map(|mapping| mapping.strip_prefix(&prefix).unwrap_or("").to_string())
            .collect()
    }
    
    /// 获取所有票种名称（去重）
    pub fn get_all_ticket_types(&self) -> Vec<String> {
        let mut ticket_types: Vec<String> = self.ticket_area_mappings
            .iter()
            .filter_map(|mapping| {
                if let Some(index) = mapping.find('-') {
                    Some(mapping[..index].to_string())
                } else {
                    None
                }
            })
            .collect();
        
        ticket_types.sort();
        ticket_types.dedup();
        ticket_types
    }
}

/// 票种配置 - 使用 InitSpace
#[account]
#[derive(InitSpace)]
pub struct TicketTypeAccount {
    /// 所属活动
    pub event: Pubkey,
    /// 票种ID
    pub ticket_type_id: u8,
    /// 票种名称
    #[max_len(50)]
    pub type_name: String,
    /// 初始价格
    pub initial_price: u64,
    /// 当前价格（动态定价会更新）
    pub current_price: u64,
    /// 总发行数量
    pub total_supply: u32,
    /// 已售出数量
    pub sold_count: u32,
    /// 已退票数量
    pub refunded_count: u32,
    /// 二级市场转售时的最大版税比例（基点）
    pub max_resale_royalty: u16,
    /// 是否采用固定价格
    pub is_fixed_price: bool,
    /// 动态定价规则的IPFS哈希
    #[max_len(100)]
    pub dynamic_pricing_rules_hash: Option<String>,
    /// 最后价格更新时间
    pub last_price_update: i64,
    /// PDA bump值（用于性能优化）
    pub bump: u8,
}

/// 活动状态枚举
#[derive(AnchorSerialize, AnchorDeserialize, Clone, PartialEq, Eq, Debug, InitSpace)]
pub enum EventStatus {
    /// 即将到来
    Upcoming,
    /// 正在销售中
    OnSale,
    /// 已售罄
    SoldOut,
    /// 已取消
    Cancelled,
    /// 已延期
    Postponed,
    /// 已完成
    Completed,
}

/// 定价策略类型
#[derive(AnchorSerialize, AnchorDeserialize, Clone, PartialEq, Eq, Debug, InitSpace)]
pub enum PricingStrategyType {
    /// 固定价格
    FixedPrice,
    /// 动态定价
    DynamicPricing,
}

/// 动态定价规则
#[derive(AnchorSerialize, AnchorDeserialize, Clone, Debug, InitSpace)]
pub struct DynamicPricingRule {
    /// 触发条件类型
    pub trigger_type: PricingTriggerType,
    /// 触发阈值
    pub threshold: u64,
    /// 价格调整百分比（基点）
    pub price_adjustment_bps: i16, // 正数为涨价，负数为降价
}

/// 定价触发条件类型
#[derive(AnchorSerialize, AnchorDeserialize, Clone, PartialEq, Eq, Debug, InitSpace)]
pub enum PricingTriggerType {
    /// 基于销售百分比
    SalesPercentage,
    /// 基于时间（距离活动开始的秒数）
    TimeBeforeEvent,
    /// 基于剩余时间（距离销售结束的秒数）
    TimeBeforeSaleEnd,
} 