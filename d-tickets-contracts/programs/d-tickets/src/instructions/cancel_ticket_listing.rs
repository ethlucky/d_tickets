use anchor_lang::prelude::*;
use crate::{
    state::{MarketplaceListingAccount, TicketAccount, ListingStatus},
    error::TicketError,
    constants::*,
};

#[derive(Accounts)]
pub struct CancelTicketListing<'info> {
    #[account(
        mut,
        seeds = [MARKETPLACE_LISTING_SEED, listing.ticket_mint.as_ref()],
        bump = listing.bump,
        constraint = listing.status == ListingStatus::Active @ TicketError::ListingNotFound,
        constraint = listing.seller == seller.key() @ TicketError::NotTicketOwner,
        close = seller
    )]
    pub listing: Account<'info, MarketplaceListingAccount>,
    
    #[account(
        mut,
        seeds = [TICKET_SEED, ticket.mint.as_ref()],
        bump = ticket.bump
    )]
    pub ticket: Account<'info, TicketAccount>,
    
    #[account(mut)]
    pub seller: Signer<'info>,
}

pub fn handler(ctx: Context<CancelTicketListing>) -> Result<()> {
    let listing = &mut ctx.accounts.listing;
    let _ticket = &mut ctx.accounts.ticket;
    let current_time = Clock::get()?.unix_timestamp;

    // 更新挂单状态
    listing.status = ListingStatus::Cancelled;
    listing.sold_at = Some(current_time);

    msg!("挂单取消成功: 卖方: {}", ctx.accounts.seller.key());

    Ok(())
} 