use anchor_lang::prelude::*;
use crate::{
    state::{TicketAccount, MarketplaceListingAccount, ListingStatus},
    error::TicketError,
    constants::*,
};

#[derive(Accounts)]
pub struct ListTicketForSale<'info> {
    #[account(
        mut,
        seeds = [TICKET_SEED, ticket.mint.as_ref()],
        bump = ticket.bump
    )]
    pub ticket: Account<'info, TicketAccount>,

    #[account(
        init,
        payer = seller,
        space = MarketplaceListingAccount::INIT_SPACE,
        seeds = [MARKETPLACE_LISTING_SEED, ticket.mint.as_ref()],
        bump
    )]
    pub listing: Account<'info, MarketplaceListingAccount>,

    #[account(mut)]
    pub seller: Signer<'info>,
    pub system_program: Program<'info, System>,
}

pub fn handler(
    ctx: Context<ListTicketForSale>,
    price: u64,
) -> Result<()> {
    let ticket = &mut ctx.accounts.ticket;
    let listing = &mut ctx.accounts.listing;
    let clock = Clock::get()?;

    // 验证门票状态
    require!(
        ticket.transferable,
        TicketError::TicketNotTransferable
    );

    // 设置挂单信息并保存bump值
    listing.ticket_mint = ticket.mint;
    listing.seller = ctx.accounts.seller.key();
    listing.price = price;
    listing.listed_at = clock.unix_timestamp;
    listing.status = ListingStatus::Active;
    listing.buyer = None;
    listing.sold_at = None;
    listing.sold_price = None;
    listing.royalty_bps = 0; // 设置默认值
    listing.platform_fee_bps = 250; // 2.5%
    listing.bump = ctx.bumps.listing; // 保存listing PDA的bump值

    Ok(())
} 