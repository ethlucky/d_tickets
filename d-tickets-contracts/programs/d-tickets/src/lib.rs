pub mod constants;
pub mod error;
pub mod instructions;
pub mod state;

use anchor_lang::prelude::*;
use instructions::*;
use state::*;

pub use constants::*;

declare_id!("4RmJgJPUEkBJu8etoeMSt6B62RGvMR7iviNQEyHThJHG");

#[program]
pub mod d_tickets {
    use super::*;

    // ===== 场馆管理功能 =====
    /// 创建新场馆
    pub fn create_venue(
        ctx: Context<CreateVenue>,
        venue_name: String,
        venue_address: String,
        total_capacity: u32,
        venue_description: String,
        venue_type: VenueType,
        contact_info: String,
        floor_plan_hash: Option<String>,
        facilities_info_hash: Option<String>,
    ) -> Result<()> {
        instructions::create_venue::handler(
            ctx,
            venue_name,
            venue_address,
            total_capacity,
            venue_description,
            venue_type,
            contact_info,
            floor_plan_hash,
            facilities_info_hash,
        )
    }

    /// 更新场馆信息
    pub fn update_venue(
        ctx: Context<UpdateVenue>,
        venue_name: String,  // 添加venue_name参数
        new_venue_address: Option<String>,
        new_total_capacity: Option<u32>,
        new_venue_description: Option<String>,
        new_venue_type: Option<VenueType>,
        new_contact_info: Option<String>,
        new_floor_plan_hash: Option<String>,
        new_seat_map_hash: Option<String>,
        new_facilities_info_hash: Option<String>,
        new_venue_status: Option<VenueStatus>,
    ) -> Result<()> {
        instructions::update_venue::handler(
            ctx,
            venue_name,  // 传递venue_name参数
            new_venue_address,
            new_total_capacity,
            new_venue_description,
            new_venue_type,
            new_contact_info,
            new_floor_plan_hash,
            new_seat_map_hash,
            new_facilities_info_hash,
            new_venue_status,
        )
    }

    /// 删除场馆
    pub fn delete_venue(
        ctx: Context<DeleteVenue>,
        venue_name: String,
    ) -> Result<()> {
        instructions::delete_venue::handler(ctx, venue_name)
    }

    /// 配置座位
    pub fn configure_seat(
        ctx: Context<ConfigureSeat>,
        venue_name: String,
        ticket_type_name: String,
        seat_number: String,
        area_id: String,
        row_number: String,
        seat_number_in_row: String,
    ) -> Result<()> {
        instructions::configure_seats::configure_seat(
            ctx,
            venue_name,
            ticket_type_name,
            seat_number,
            area_id,
            row_number,
            seat_number_in_row,
        )
    }

    /// 创建或更新座位状态映射（支持添加和修改）
    pub fn create_seat_status_map(
        ctx: Context<CreateOrUpdateSeatStatusMap>,
        ticket_type_name: String,
        area_id: String,
        seat_layout_hash: String,
        seat_index_map_hash: String,
        total_seats: u32,
    ) -> Result<()> {
        instructions::configure_seats::create_seat_status_map(
            ctx,
            ticket_type_name,
            area_id,
            seat_layout_hash,
            seat_index_map_hash,
            total_seats,
        )
    }

    /// 批量更新座位状态
    pub fn batch_update_seat_status(
        ctx: Context<BatchUpdateSeatStatus>,
        ticket_type_name: String,
        area_id: String,
        seat_updates: Vec<SeatStatusUpdate>,
    ) -> Result<()> {
        instructions::configure_seats::batch_update_seat_status(
            ctx,
            ticket_type_name,
            area_id,
            seat_updates,
        )
    }

    /// 查询座位状态
    pub fn get_seat_status_batch(
        ctx: Context<BatchUpdateSeatStatus>,
        ticket_type_name: String,
        area_id: String,
        seat_indices: Vec<u32>,
    ) -> Result<()> {
        instructions::configure_seats::get_seat_status_batch(
            ctx,
            ticket_type_name,
            area_id,
            seat_indices,
        )
    }

    /// 删除座位状态映射
    pub fn delete_seat_status_map(
        ctx: Context<DeleteSeatStatusMap>,
        ticket_type_name: String,
        area_id: String,
    ) -> Result<()> {
        instructions::configure_seats::delete_seat_status_map(
            ctx,
            ticket_type_name,
            area_id,
        )
    }

    /// 更新座位状态
    pub fn update_seat_status(
        ctx: Context<UpdateSeatStatus>,
        venue_name: String,
        ticket_type_name: String,
        seat_number: String,
        new_status: SeatStatus,
        event_key: Option<Pubkey>,
        ticket_nft: Option<Pubkey>,
        ticket_type_id: Option<u8>,
    ) -> Result<()> {
        instructions::configure_seats::update_seat_status(
            ctx,
            venue_name,
            ticket_type_name,
            seat_number,
            new_status,
            event_key,
            ticket_nft,
            ticket_type_id,
        )
    }



    // ===== 活动管理功能 =====
    /// 创建新活动 - 关联现有场馆
    pub fn create_event(
        ctx: Context<CreateEvent>,
        event_name: String,
        event_description_hash: String,
        event_poster_image_hash: String,
        event_start_time: i64,
        event_end_time: i64,
        ticket_sale_start_time: i64,
        ticket_sale_end_time: i64,
        seat_map_hash: Option<String>,
        event_category: String,
        performer_details_hash: String,
        contact_info_hash: String,
        refund_policy_hash: String,
        pricing_strategy_type: PricingStrategyType,
    ) -> Result<()> {
        instructions::create_event::handler(
            ctx,
            event_name,
            event_description_hash,
            event_poster_image_hash,
            event_start_time,
            event_end_time,
            ticket_sale_start_time,
            ticket_sale_end_time,
            seat_map_hash,
            event_category,
            performer_details_hash,
            contact_info_hash,
            refund_policy_hash,
            pricing_strategy_type,
        )
    }

    /// 添加票种配置
    pub fn add_ticket_type(
        ctx: Context<AddTicketType>,
        type_name: String,
        initial_price: u64,
        total_supply: u32,
        max_resale_royalty: u16,
        is_fixed_price: bool,
        dynamic_pricing_rules_hash: Option<String>,
    ) -> Result<()> {
        instructions::add_ticket_type::handler(
            ctx,
            type_name,
            initial_price,
            total_supply,
            max_resale_royalty,
            is_fixed_price,
            dynamic_pricing_rules_hash,
        )
    }

    /// 修改票种配置
    pub fn update_ticket_type(
        ctx: Context<UpdateTicketType>,
        ticket_type_name: String,
        new_price: Option<u64>,
        new_max_resale_royalty: Option<u16>,
        new_dynamic_pricing_rules_hash: Option<String>,
    ) -> Result<()> {
        instructions::update_ticket_type::handler(
            ctx,
            ticket_type_name,
            new_price,
            new_max_resale_royalty,
            new_dynamic_pricing_rules_hash,
        )
    }

    /// 删除票种配置
    pub fn delete_ticket_type(
        ctx: Context<DeleteTicketType>,
        event_name: String,
        ticket_type_name: String,
    ) -> Result<()> {
        instructions::delete_ticket_type::handler(ctx, event_name, ticket_type_name)
    }

    /// 批量铸造门票NFT
    pub fn mint_tickets(
        ctx: Context<MintTickets>,
        ticket_type_name: String,
        quantity: u32,
    ) -> Result<()> {
        instructions::mint_tickets::handler(ctx, ticket_type_name, quantity)
    }

    /// 更新活动状态
    pub fn update_event_status(
        ctx: Context<UpdateEventStatus>,
        event_name: String,
        new_status: EventStatus,
    ) -> Result<()> {
        instructions::update_event_status::handler(ctx, event_name, new_status)
    }

    /// 修改活动信息（不包括场馆信息）
    pub fn update_event(
        ctx: Context<UpdateEvent>,
        new_event_description_hash: Option<String>,
        new_event_poster_image_hash: Option<String>,
        new_seat_map_hash: Option<String>,
        new_performer_details_hash: Option<String>,
        new_contact_info_hash: Option<String>,
        new_refund_policy_hash: Option<String>,
    ) -> Result<()> {
        instructions::update_event::handler(
            ctx,
            new_event_description_hash,
            new_event_poster_image_hash,
            new_seat_map_hash,
            new_performer_details_hash,
            new_contact_info_hash,
            new_refund_policy_hash,
        )
    }

    /// 更换活动关联的场馆
    pub fn update_event_venue(
        ctx: Context<UpdateEventVenue>,
    ) -> Result<()> {
        instructions::update_event::update_venue_handler(ctx)
    }

    // ===== 定价策略功能 =====
    /// 更新动态定价
    pub fn update_dynamic_pricing(
        ctx: Context<UpdateDynamicPricing>,
        ticket_type_name: String,
        new_price: u64,
    ) -> Result<()> {
        instructions::update_dynamic_pricing::handler(ctx, ticket_type_name, new_price)
    }

    // ===== 购买和转移功能 =====
    /// 购买门票
    pub fn purchase_ticket(
        ctx: Context<PurchaseTicket>,
        ticket_type_name: String,
    ) -> Result<()> {
        instructions::purchase_ticket::handler(ctx, ticket_type_name)
    }

    /// 退票
    pub fn refund_ticket(
        ctx: Context<RefundTicket>,
    ) -> Result<()> {
        instructions::refund_ticket::handler(ctx)
    }

    // ===== 二级市场功能 =====
    /// 上架门票到二级市场
    pub fn list_ticket_for_sale(
        ctx: Context<ListTicketForSale>,
        price: u64,
    ) -> Result<()> {
        instructions::list_ticket_for_sale::handler(ctx, price)
    }

    /// 从二级市场购买门票
    pub fn buy_ticket_from_market(
        ctx: Context<BuyTicketFromMarket>,
    ) -> Result<()> {
        instructions::buy_ticket_from_market::handler(ctx)
    }

    /// 取消二级市场挂单
    pub fn cancel_ticket_listing(
        ctx: Context<CancelTicketListing>,
    ) -> Result<()> {
        instructions::cancel_ticket_listing::handler(ctx)
    }

    // ===== 入场核销功能 =====
    /// 核销门票（入场验证）
    pub fn redeem_ticket(
        ctx: Context<RedeemTicket>,
    ) -> Result<()> {
        instructions::redeem_ticket::handler(ctx)
    }

    // ===== 管理功能 =====
    /// 设置平台（初始化或更新）- 统一方法
    pub fn setup_platform(
        ctx: Context<SetupPlatform>,
        platform_fee_bps: Option<u16>,
        new_fee_recipient: Option<Pubkey>,
        new_is_paused: Option<bool>,
    ) -> Result<()> {
        instructions::setup_platform::handler(ctx, platform_fee_bps, new_fee_recipient, new_is_paused)
    }

    /// 提取收益（主办方）
    pub fn withdraw_proceeds(
        ctx: Context<WithdrawProceeds>,
        amount: u64,
    ) -> Result<()> {
        instructions::withdraw_proceeds::handler(ctx, amount)
    }
}