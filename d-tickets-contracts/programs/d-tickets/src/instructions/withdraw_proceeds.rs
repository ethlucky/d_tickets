use anchor_lang::prelude::*;
use crate::{
    state::{EventAccount, OrganizerEarnings},
    error::TicketError,
    constants::*,
};

#[derive(Accounts)]
pub struct WithdrawProceeds<'info> {
    #[account(
        mut,
        seeds = [EVENT_SEED, organizer.key().as_ref(), event.event_name.as_bytes()],
        bump = event.bump,
        has_one = organizer @ TicketError::NotEventOrganizer
    )]
    pub event: Account<'info, EventAccount>,

    #[account(
        mut,
        seeds = [EARNINGS_SEED, event.key().as_ref()],
        bump = earnings.bump
    )]
    pub earnings: Account<'info, OrganizerEarnings>,

    #[account(mut)]
    pub organizer: Signer<'info>,
}

pub fn handler(
    ctx: Context<WithdrawProceeds>,
    amount: u64,
) -> Result<()> {
    let earnings = &mut ctx.accounts.earnings;
    let current_time = Clock::get()?.unix_timestamp;

    // 验证提取金额
    require!(amount > 0, TicketError::InvalidArgument);
    require!(
        amount <= earnings.pending_amount,
        TicketError::WithdrawAmountTooLarge
    );

    // 更新收益记录
    earnings.pending_amount -= amount;
    earnings.withdrawn_amount += amount;
    earnings.withdrawal_count += 1;
    earnings.last_withdrawal_at = Some(current_time);

    msg!(
        "收益提取成功: 主办方: {}, 金额: {} lamports",
        ctx.accounts.organizer.key(),
        amount
    );

    Ok(())
} 