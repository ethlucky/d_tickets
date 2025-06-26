use anchor_lang::prelude::*;
use crate::{
    state::{VenueAccount, VenueStatus},
    error::TicketError,
};

#[derive(Accounts)]
#[instruction(venue_name: String)]
pub struct DeleteVenue<'info> {
    /// 场馆创建者（主办方）
    #[account(mut)]
    pub creator: Signer<'info>,

    /// 要删除的场馆账户（PDA）
    #[account(
        mut,
        seeds = [b"venue", creator.key().as_ref(), venue_name.as_bytes()],
        bump = venue_account.bump,
        has_one = creator @ TicketError::NotVenueOwner,
        close = creator
    )]
    pub venue_account: Account<'info, VenueAccount>,
}

pub fn handler(
    ctx: Context<DeleteVenue>,
    _venue_name: String,
) -> Result<()> {
    let venue_account = &ctx.accounts.venue_account;

    // 安全检查：只能删除未使用状态的场馆
    // require!(
    //     venue_account.venue_status == VenueStatus::Unused,
    //     TicketError::OnlyUnusedVenueCanBeDeleted
    // );

    msg!("场馆删除成功: {}", venue_account.venue_name);

    // 账户会通过 #[account(close = creator)] 自动关闭并退还租金
    Ok(())
} 