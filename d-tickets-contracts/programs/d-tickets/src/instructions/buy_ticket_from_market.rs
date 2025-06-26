use anchor_lang::prelude::*;
use crate::{
    state::{MarketplaceListingAccount, TicketAccount, TicketTypeAccount, OrganizerEarnings, PlatformAccount, ListingStatus},
    error::TicketError,
    constants::*,
};

#[derive(Accounts)]
pub struct BuyTicketFromMarket<'info> {
    #[account(
        mut,
        seeds = [MARKETPLACE_LISTING_SEED, listing.ticket_mint.as_ref()],
        bump = listing.bump,
        constraint = listing.status == ListingStatus::Active @ TicketError::ListingNotFound
    )]
    pub listing: Account<'info, MarketplaceListingAccount>,

    #[account(
        mut,
        seeds = [TICKET_SEED, ticket.mint.as_ref()],
        bump = ticket.bump
    )]
    pub ticket: Account<'info, TicketAccount>,

    #[account(
        mut,
        seeds = [TICKET_TYPE_SEED, ticket.event.as_ref(), ticket.ticket_type_name.as_bytes()],
        bump = ticket_type.bump
    )]
    pub ticket_type: Account<'info, TicketTypeAccount>,

    #[account(
        mut,
        seeds = [EARNINGS_SEED, ticket.event.as_ref()],
        bump = earnings.bump
    )]
    pub earnings: Account<'info, OrganizerEarnings>,

    #[account(
        seeds = [PLATFORM_SEED],
        bump = platform.bump
    )]
    pub platform: Account<'info, PlatformAccount>,

    #[account(mut)]
    pub buyer: Signer<'info>,
}

pub fn handler(ctx: Context<BuyTicketFromMarket>) -> Result<()> {
    let listing = &mut ctx.accounts.listing;
    let ticket = &mut ctx.accounts.ticket;
    let ticket_type = &mut ctx.accounts.ticket_type;
    let earnings = &mut ctx.accounts.earnings;
    let platform = &ctx.accounts.platform;
    let clock = Clock::get()?;

    // 验证买家不是卖家
    require!(
        listing.seller != ctx.accounts.buyer.key(),
        TicketError::CannotBuyOwnListing
    );

    // 计算费用
    let price = listing.price;
    let platform_fee = price
        .checked_mul(platform.platform_fee_bps as u64)
        .unwrap()
        .checked_div(10000)
        .unwrap();
    
    let royalty_fee = price
        .checked_mul(ticket_type.max_resale_royalty as u64)
        .unwrap()
        .checked_div(10000)
        .unwrap();

    let _seller_amount = price
        .checked_sub(platform_fee)
        .unwrap()
        .checked_sub(royalty_fee)
        .unwrap();

    // 验证支付金额
    require!(
        ctx.accounts.buyer.lamports() >= price,
        TicketError::InsufficientPayment
    );

    // 更新挂单状态
    listing.status = ListingStatus::Sold;
    listing.buyer = Some(ctx.accounts.buyer.key());
    listing.sold_at = Some(clock.unix_timestamp);
    listing.sold_price = Some(price);

    // 更新门票所有者
    ticket.current_owner = ctx.accounts.buyer.key();
    ticket.transfer_count += 1;
    ticket.last_transfer_at = Some(clock.unix_timestamp);

    // 更新收益
    earnings.royalty_earnings += royalty_fee;

    Ok(())
} 