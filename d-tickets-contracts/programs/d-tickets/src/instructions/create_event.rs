use anchor_lang::prelude::*;
use crate::{constants::*, error::TicketError, state::*};

#[derive(Accounts)]
#[instruction(event_name: String)]
pub struct CreateEvent<'info> {
    #[account(
        init,
        payer = organizer,
        space = EventAccount::INIT_SPACE,
        seeds = [EVENT_SEED, organizer.key().as_ref(), event_name.as_bytes()],
        bump
    )]
    pub event: Account<'info, EventAccount>,
    
    #[account(
        init,
        payer = organizer,
        space = OrganizerEarnings::INIT_SPACE,
        seeds = [EARNINGS_SEED, event.key().as_ref()],
        bump
    )]
    pub earnings: Account<'info, OrganizerEarnings>,
    
    #[account(
        seeds = [PLATFORM_SEED],
        bump = platform.bump
    )]
    pub platform: Account<'info, PlatformAccount>,

    /// 关联的场馆账户（必须已存在且为未使用或活跃状态）
    #[account(
        mut,
        constraint = venue.venue_status == VenueStatus::Unused || venue.venue_status == VenueStatus::Active @ TicketError::VenueNotActive
    )]
    pub venue: Account<'info, VenueAccount>,
    
    #[account(mut)]
    pub organizer: Signer<'info>,
    
    pub system_program: Program<'info, System>,
}

pub fn handler(
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
    let current_time = Clock::get()?.unix_timestamp;
    let venue = &mut ctx.accounts.venue;

    // 验证时间参数
    // require!(event_start_time > current_time, TicketError::InvalidEventTime);
    // require!(event_end_time > event_start_time, TicketError::InvalidEventTime);
    // require!(ticket_sale_start_time <= event_start_time, TicketError::InvalidSaleTime);
    // require!(ticket_sale_end_time <= event_start_time, TicketError::InvalidSaleTime);
    // require!(ticket_sale_start_time < ticket_sale_end_time, TicketError::InvalidSaleTime);

    // 验证字符串长度
    require!(event_name.len() <= 100, TicketError::InvalidStringLength);
    require!(event_category.len() <= 50, TicketError::InvalidStringLength);
    
    // 验证场馆状态（允许未使用或已激活的场馆）
    require!(
        venue.venue_status == VenueStatus::Unused || venue.venue_status == VenueStatus::Active,
        TicketError::VenueNotActive
    );

    let event = &mut ctx.accounts.event;
    let earnings = &mut ctx.accounts.earnings;

    // 设置活动信息并保存bump值
    event.organizer = ctx.accounts.organizer.key();
    event.event_name = event_name.clone();
    event.event_description_hash = event_description_hash;
    event.event_poster_image_hash = event_poster_image_hash;
    event.event_start_time = event_start_time;
    event.event_end_time = event_end_time;
    event.ticket_sale_start_time = ticket_sale_start_time;
    event.ticket_sale_end_time = ticket_sale_end_time;
    event.venue_account = venue.key(); // 设置关联的场馆账户
    event.seat_map_hash = seat_map_hash;
    event.event_category = event_category;
    event.performer_details_hash = performer_details_hash;
    event.contact_info_hash = contact_info_hash;
    event.event_status = EventStatus::Upcoming;
    event.refund_policy_hash = refund_policy_hash;
    event.pricing_strategy_type = pricing_strategy_type;
    event.total_tickets_minted = 0;
    event.total_tickets_sold = 0;
    event.total_tickets_refunded = 0;
    event.total_tickets_resale_available = 0;
    event.total_revenue = 0;
    event.ticket_types_count = 0;
    event.ticket_area_mappings = Vec::new(); // 初始化空的票种-区域映射列表
    event.bump = ctx.bumps.event; // 保存event PDA的bump值
    event.created_at = current_time;
    event.updated_at = current_time;

    // 设置收益账户并保存bump值
    earnings.organizer = ctx.accounts.organizer.key();
    earnings.event = event.key();
    earnings.total_earnings = 0;
    earnings.withdrawn_amount = 0;
    earnings.pending_amount = 0;
    earnings.royalty_earnings = 0;
    earnings.last_withdrawal_at = None;
    earnings.withdrawal_count = 0;
    earnings.bump = ctx.bumps.earnings; // 保存earnings PDA的bump值

    // 将场馆状态更新为激活状态
    venue.venue_status = VenueStatus::Active;
    venue.updated_at = current_time;

    msg!(
        "活动创建成功: {}, 主办方: {}, 关联场馆: {} (场馆状态已更新为激活)",
        event_name,
        ctx.accounts.organizer.key(),
        venue.venue_name
    );

    Ok(())
} 