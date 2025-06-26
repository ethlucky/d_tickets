use anchor_lang::prelude::*;
use crate::{
    state::{EventAccount, TicketTypeAccount, PlatformAccount},
    error::TicketError,
    constants::*,
};

#[derive(Accounts)]
#[instruction(ticket_type_name: String)]
pub struct UpdateTicketType<'info> {
    #[account(
        mut,
        seeds = [EVENT_SEED, organizer.key().as_ref(), event.event_name.as_bytes()],
        bump = event.bump,
        has_one = organizer @ TicketError::NotEventOrganizer
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

    #[account(mut)]
    pub organizer: Signer<'info>,
}

pub fn handler(
    ctx: Context<UpdateTicketType>,
    _ticket_type_name: String,
    new_price: Option<u64>,
    new_max_resale_royalty: Option<u16>,
    new_dynamic_pricing_rules_hash: Option<String>,
) -> Result<()> {
    let ticket_type = &mut ctx.accounts.ticket_type;
    let platform = &ctx.accounts.platform;
    let current_time = Clock::get()?.unix_timestamp;

    // 验证票种状态 - 只有在销售开始前或没有售出的情况下才能修改价格
    if let Some(price) = new_price {
        require!(
            ticket_type.sold_count == 0,
            TicketError::InvalidOperationSequence
        );
        
        // 验证价格范围
        require!(
            price >= platform.min_ticket_price,
            TicketError::PriceBelowMinimum
        );
        require!(
            price <= platform.max_ticket_price,
            TicketError::PriceAboveMaximum
        );

        ticket_type.current_price = price;
        ticket_type.last_price_update = current_time;
    }

    // 更新版税比例
    if let Some(royalty) = new_max_resale_royalty {
        require!(royalty <= 2500, TicketError::InvalidRoyaltyRate); // 最大25%
        ticket_type.max_resale_royalty = royalty;
    }

    // 更新动态定价规则
    if let Some(rules_hash) = new_dynamic_pricing_rules_hash {
        ticket_type.dynamic_pricing_rules_hash = Some(rules_hash);
    }

    Ok(())
} 