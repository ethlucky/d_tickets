use anchor_lang::prelude::*;
use crate::{
    state::{EventAccount, EventStatus, VenueAccount, VenueStatus},
    error::TicketError,
    constants::*,
};

#[derive(Accounts)]
pub struct UpdateEvent<'info> {
    #[account(
        mut,
        seeds = [EVENT_SEED, organizer.key().as_ref(), event.event_name.as_bytes()],
        bump = event.bump,
        has_one = organizer @ TicketError::NotEventOrganizer
    )]
    pub event: Account<'info, EventAccount>,

    #[account(mut)]
    pub organizer: Signer<'info>,
}

#[derive(Accounts)]
pub struct UpdateEventVenue<'info> {
    #[account(
        mut,
        seeds = [EVENT_SEED, organizer.key().as_ref(), event.event_name.as_bytes()],
        bump = event.bump,
        has_one = organizer @ TicketError::NotEventOrganizer
    )]
    pub event: Account<'info, EventAccount>,

    /// 原场馆账户（需要更新状态为未使用）
    #[account(mut)]
    pub old_venue: Account<'info, VenueAccount>,

    /// 新的关联场馆账户（必须已存在且为未使用或活跃状态）
    #[account(
        mut,
        constraint = new_venue.venue_status == VenueStatus::Unused || new_venue.venue_status == VenueStatus::Active @ TicketError::VenueNotActive
    )]
    pub new_venue: Account<'info, VenueAccount>,

    #[account(mut)]
    pub organizer: Signer<'info>,
}

pub fn handler(
    ctx: Context<UpdateEvent>,
    new_event_description_hash: Option<String>,
    new_event_poster_image_hash: Option<String>,
    new_seat_map_hash: Option<String>,
    new_performer_details_hash: Option<String>,
    new_contact_info_hash: Option<String>,
    new_refund_policy_hash: Option<String>,
) -> Result<()> {
    let event = &mut ctx.accounts.event;
    let current_time = Clock::get()?.unix_timestamp;

    // 只允许在活动开始前修改
    require!(
        event.event_status == EventStatus::Upcoming,
        TicketError::InvalidOperationSequence
    );

    // 更新事件描述哈希
    if let Some(description_hash) = new_event_description_hash {
        event.event_description_hash = description_hash;
    }

    // 更新海报图片哈希
    if let Some(poster_hash) = new_event_poster_image_hash {
        event.event_poster_image_hash = poster_hash;
    }

    // 更新座位图哈希（可覆盖场馆默认座位图）
    if let Some(seat_map) = new_seat_map_hash {
        event.seat_map_hash = Some(seat_map);
    }

    // 更新表演者详情哈希
    if let Some(performer_hash) = new_performer_details_hash {
        event.performer_details_hash = performer_hash;
    }

    // 更新联系信息哈希
    if let Some(contact_hash) = new_contact_info_hash {
        event.contact_info_hash = contact_hash;
    }

    // 更新退票政策哈希
    if let Some(refund_hash) = new_refund_policy_hash {
        event.refund_policy_hash = refund_hash;
    }

    // 更新时间戳
    event.updated_at = current_time;

    msg!("活动信息已更新: {}", event.event_name);

    Ok(())
}

/// 更换活动关联的场馆
pub fn update_venue_handler(
    ctx: Context<UpdateEventVenue>,
) -> Result<()> {
    let event = &mut ctx.accounts.event;
    let old_venue = &mut ctx.accounts.old_venue;
    let new_venue = &mut ctx.accounts.new_venue;
    let current_time = Clock::get()?.unix_timestamp;

    // 只允许在活动开始前且尚未开始销售时修改场馆
    require!(
        event.event_status == EventStatus::Upcoming,
        TicketError::InvalidOperationSequence
    );
    require!(
        current_time < event.ticket_sale_start_time,
        TicketError::SaleAlreadyStarted
    );

    // 验证原场馆是否与活动关联的场馆一致
    require!(
        old_venue.key() == event.venue_account,
        TicketError::VenueNotFound
    );

    // 验证新场馆状态
    require!(
        new_venue.venue_status == VenueStatus::Unused || new_venue.venue_status == VenueStatus::Active,
        TicketError::VenueNotActive
    );

    // 更新关联的场馆账户
    event.venue_account = new_venue.key();
    event.updated_at = current_time;

    // 将原场馆状态更新为未使用状态
    old_venue.venue_status = VenueStatus::Unused;
    old_venue.updated_at = current_time;

    // 将新场馆状态更新为激活状态
    new_venue.venue_status = VenueStatus::Active;
    new_venue.updated_at = current_time;

    msg!(
        "活动 {} 已更换场馆: {} -> {} (状态已更新)",
        event.event_name,
        old_venue.venue_name,
        new_venue.venue_name
    );

    Ok(())
} 