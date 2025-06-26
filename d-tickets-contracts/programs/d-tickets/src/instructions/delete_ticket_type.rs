use anchor_lang::prelude::*;
use crate::{
    state::{EventAccount, TicketTypeAccount, PlatformAccount, EventStatus},
    error::TicketError,
    constants::*,
};

#[derive(Accounts)]
#[instruction(event_name: String, ticket_type_name: String)]
pub struct DeleteTicketType<'info> {
    #[account(
        mut,
        seeds = [EVENT_SEED, organizer.key().as_ref(), event_name.as_bytes()],
        bump = event.bump,
        has_one = organizer @ TicketError::NotEventOrganizer
    )]
    pub event: Account<'info, EventAccount>,

    /// 要删除的票种账户
    #[account(
        mut,
        seeds = [TICKET_TYPE_SEED, event.key().as_ref(), ticket_type_name.as_bytes()],
        bump = ticket_type.bump,
        close = organizer
    )]
    pub ticket_type: Account<'info, TicketTypeAccount>,

    #[account(
        seeds = [PLATFORM_SEED],
        bump = platform.bump
    )]
    pub platform: Account<'info, PlatformAccount>,

    #[account(mut)]
    pub organizer: Signer<'info>,
}

pub fn handler(
    ctx: Context<DeleteTicketType>,
    _event_name: String,
    _ticket_type_name: String,
) -> Result<()> {
    let event = &mut ctx.accounts.event;
    let ticket_type = &ctx.accounts.ticket_type;
    let current_time = Clock::get()?.unix_timestamp;

    // 安全检查：只能在活动开始前删除票种
    require!(
        event.event_status == EventStatus::Upcoming,
        TicketError::InvalidOperationSequence
    );

    // 安全检查：只能在票务销售开始前删除
    require!(
        current_time < event.ticket_sale_start_time,
        TicketError::SaleAlreadyStarted
    );

    // 安全检查：只能删除没有售出的票种
    require!(
        ticket_type.sold_count == 0,
        TicketError::TicketAlreadySold
    );

    // 更新活动的票种数量
    event.ticket_types_count = event.ticket_types_count.saturating_sub(1);
    event.updated_at = current_time;

    msg!("票种删除成功: {}", ticket_type.type_name);

    Ok(())
} 