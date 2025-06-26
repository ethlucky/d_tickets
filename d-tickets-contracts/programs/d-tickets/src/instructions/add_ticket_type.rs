use anchor_lang::prelude::*;
use crate::{constants::*, error::TicketError, state::*};

#[derive(Accounts)]
#[instruction(type_name: String)]
pub struct AddTicketType<'info> {
    #[account(
        mut,
        seeds = [EVENT_SEED, organizer.key().as_ref(), event.event_name.as_bytes()],
        bump = event.bump,
        has_one = organizer @ TicketError::NotEventOrganizer
    )]
    pub event: Account<'info, EventAccount>,
    
    #[account(
        init,
        payer = organizer,
        space = TicketTypeAccount::INIT_SPACE,
        seeds = [TICKET_TYPE_SEED, event.key().as_ref(), type_name.as_bytes()],
        bump
    )]
    pub ticket_type: Account<'info, TicketTypeAccount>,
    
    #[account(
        seeds = [PLATFORM_SEED],
        bump = platform.bump
    )]
    pub platform: Account<'info, PlatformAccount>,
    
    #[account(mut)]
    pub organizer: Signer<'info>,
    
    pub system_program: Program<'info, System>,
}

pub fn handler(
    ctx: Context<AddTicketType>,
    type_name: String,
    initial_price: u64,
    total_supply: u32,
    max_resale_royalty: u16,
    is_fixed_price: bool,
    dynamic_pricing_rules_hash: Option<String>,
) -> Result<()> {
    let event = &mut ctx.accounts.event;
    let ticket_type = &mut ctx.accounts.ticket_type;
    let platform = &ctx.accounts.platform;
    let current_time = Clock::get()?.unix_timestamp;

    // 验证票种名称长度
    require!(type_name.len() <= 50, TicketError::InvalidStringLength);
    require!(!type_name.is_empty(), TicketError::RequiredFieldEmpty);

    // 验证价格
    require!(
        initial_price >= platform.min_ticket_price,
        TicketError::PriceBelowMinimum
    );
    require!(
        initial_price <= platform.max_ticket_price,
        TicketError::PriceAboveMaximum
    );

    // 验证供应量
    require!(total_supply > 0, TicketError::InvalidArgument);

    // 验证版税比例
    require!(max_resale_royalty <= 2500, TicketError::InvalidRoyaltyRate); // 最大25%

    // 验证票种数量限制
    require!(
        event.ticket_types_count < MAX_TICKET_TYPES_PER_EVENT,
        TicketError::ExceedsMaxTicketTypes
    );

    // 设置票种账户并保存bump值
    ticket_type.event = event.key();
    ticket_type.ticket_type_id = event.ticket_types_count;
    ticket_type.type_name = type_name;
    ticket_type.initial_price = initial_price;
    ticket_type.current_price = initial_price;
    ticket_type.total_supply = total_supply;
    ticket_type.sold_count = 0;
    ticket_type.refunded_count = 0;
    ticket_type.max_resale_royalty = max_resale_royalty;
    ticket_type.is_fixed_price = is_fixed_price;
    ticket_type.dynamic_pricing_rules_hash = dynamic_pricing_rules_hash;
    ticket_type.last_price_update = current_time;
    ticket_type.bump = ctx.bumps.ticket_type; // 保存ticket_type PDA的bump值

    // 更新活动账户
    event.ticket_types_count += 1;
    event.updated_at = current_time;

    msg!(
        "票种添加成功: {} (ID: {}), 价格: {} lamports, 供应量: {}",
        ticket_type.type_name,
        event.ticket_types_count,
        initial_price,
        total_supply
    );

    Ok(())
} 