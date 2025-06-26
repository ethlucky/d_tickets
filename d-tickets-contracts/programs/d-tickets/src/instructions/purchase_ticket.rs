use anchor_lang::prelude::*;
use anchor_spl::{
    associated_token::AssociatedToken,
    token::{self, Mint, Token, TokenAccount, MintTo},
};
use crate::{
    state::{EventAccount, TicketTypeAccount, TicketAccount, TicketStatus, OrganizerEarnings, PlatformAccount},
    error::TicketError,
    constants::*,
};

#[derive(Accounts)]
#[instruction(ticket_type_name: String)]
pub struct PurchaseTicket<'info> {
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
        mut,
        seeds = [EARNINGS_SEED, event.key().as_ref()],
        bump = earnings.bump
    )]
    pub earnings: Account<'info, OrganizerEarnings>,

    #[account(
        seeds = [PLATFORM_SEED],
        bump = platform.bump
    )]
    pub platform: Account<'info, PlatformAccount>,

    #[account(
        init,
        payer = buyer,
        mint::decimals = 0,
        mint::authority = buyer,
        mint::freeze_authority = buyer,
        seeds = [TICKET_MINT_SEED, event.key().as_ref(), &ticket_type_name.as_bytes(), &ticket_type.sold_count.to_le_bytes()],
        bump
    )]
    pub ticket_mint: Account<'info, Mint>,

    #[account(
        init,
        payer = buyer,
        associated_token::mint = ticket_mint,
        associated_token::authority = buyer
    )]
    pub buyer_token_account: Account<'info, TokenAccount>,

    #[account(
        init,
        payer = buyer,
        space = TicketAccount::INIT_SPACE,
        seeds = [TICKET_SEED, ticket_mint.key().as_ref()],
        bump
    )]
    pub ticket: Account<'info, TicketAccount>,

    #[account(mut)]
    pub buyer: Signer<'info>,

    pub token_program: Program<'info, Token>,
    pub associated_token_program: Program<'info, AssociatedToken>,
    pub system_program: Program<'info, System>,
    pub rent: Sysvar<'info, Rent>,
}

pub fn handler(
    ctx: Context<PurchaseTicket>,
    ticket_type_name: String,
) -> Result<()> {
    let event = &mut ctx.accounts.event;
    let ticket_type = &mut ctx.accounts.ticket_type;
    let ticket = &mut ctx.accounts.ticket;
    let earnings = &mut ctx.accounts.earnings;
    let platform = &ctx.accounts.platform;
    let current_time = Clock::get()?.unix_timestamp;

    // 验证活动状态和时间
    require!(
        current_time >= event.ticket_sale_start_time,
        TicketError::SaleNotStarted
    );
    require!(
        current_time <= event.ticket_sale_end_time,
        TicketError::SaleEnded
    );

    // 验证库存
    require!(
        ticket_type.sold_count < ticket_type.total_supply,
        TicketError::InsufficientTicketSupply
    );

    // 计算费用
    let ticket_price = ticket_type.current_price;
    let platform_fee = ticket_price
        .checked_mul(platform.platform_fee_bps as u64)
        .unwrap()
        .checked_div(10000)
        .unwrap();
    let organizer_amount = ticket_price.checked_sub(platform_fee).unwrap();

    // 验证支付金额（这里简化，实际应该处理SOL转账）
    require!(
        ctx.accounts.buyer.lamports() >= ticket_price,
        TicketError::InsufficientPayment
    );

    // 铸造NFT
    let cpi_accounts = MintTo {
        mint: ctx.accounts.ticket_mint.to_account_info(),
        to: ctx.accounts.buyer_token_account.to_account_info(),
        authority: ctx.accounts.buyer.to_account_info(),
    };
    let cpi_program = ctx.accounts.token_program.to_account_info();
    let cpi_ctx = CpiContext::new(cpi_program, cpi_accounts);
    
    token::mint_to(cpi_ctx, 1)?;

    // 设置门票账户并保存bump值
    ticket.event = event.key();
    ticket.ticket_type_name = ticket_type_name;
    ticket.mint = ctx.accounts.ticket_mint.key();
    ticket.current_owner = ctx.accounts.buyer.key();
    ticket.original_buyer = ctx.accounts.buyer.key();
    ticket.seat_number = Some(format!("SEAT-{}", ticket_type.sold_count + 1));
    ticket.original_price = ticket_price;
    ticket.current_status = TicketStatus::Sold;
    ticket.purchased_at = current_time;
    ticket.redeemed_at = None;
    ticket.metadata_hash = format!("ticket-{}-{}", event.event_name, ticket_type.sold_count + 1);
    ticket.transferable = true;
    ticket.transfer_count = 0;
    ticket.last_transfer_at = None;
    ticket.bump = ctx.bumps.ticket; // 保存ticket PDA的bump值

    // 更新统计数据
    ticket_type.sold_count += 1;
    event.total_tickets_sold += 1;
    event.total_revenue += ticket_price;
    earnings.total_earnings += organizer_amount;
    earnings.pending_amount += organizer_amount;

    // 更新时间戳
    event.updated_at = current_time;

    Ok(())
} 