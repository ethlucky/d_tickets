use anchor_lang::prelude::*;
use crate::{
    state::{EventAccount, TicketTypeAccount, PlatformAccount},
    error::TicketError,
    constants::*,
};

#[derive(Accounts)]
#[instruction(ticket_type_name: String)]
pub struct UpdateDynamicPricing<'info> {
    #[account(
        mut,
        seeds = [EVENT_SEED, event.organizer.as_ref(), event.event_name.as_bytes()],
        bump = event.bump
    )]
    pub event: Account<'info, EventAccount>,

    #[account(
        mut,
        seeds = [TICKET_TYPE_SEED, event.key().as_ref(), ticket_type_name.as_bytes()],
        bump = ticket_type.bump
    )]
    pub ticket_type: Account<'info, TicketTypeAccount>,

    #[account(
        seeds = [PLATFORM_SEED],
        bump = platform.bump
    )]
    pub platform: Account<'info, PlatformAccount>,
}

pub fn handler(
    ctx: Context<UpdateDynamicPricing>,
    _ticket_type_name: String,
    new_price: u64,
) -> Result<()> {
    let ticket_type = &mut ctx.accounts.ticket_type;
    let platform = &ctx.accounts.platform;
    let current_time = Clock::get()?.unix_timestamp;

    // 验证价格范围
    require!(
        new_price >= platform.min_ticket_price,
        TicketError::PriceBelowMinimum
    );
    require!(
        new_price <= platform.max_ticket_price,
        TicketError::PriceAboveMaximum
    );

    // 更新价格
    ticket_type.current_price = new_price;
    ticket_type.last_price_update = current_time;

    Ok(())
} 