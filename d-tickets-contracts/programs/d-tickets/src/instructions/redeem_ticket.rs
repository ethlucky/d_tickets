use anchor_lang::prelude::*;
use crate::{constants::*, error::TicketError, state::*};

#[derive(Accounts)]
pub struct RedeemTicket<'info> {
    #[account(
        constraint = event.event_status == EventStatus::OnSale || event.event_status == EventStatus::Completed @ TicketError::InvalidOperationSequence
    )]
    pub event: Account<'info, EventAccount>,
    
    #[account(
        mut,
        seeds = [TICKET_SEED, ticket.mint.as_ref()],
        bump,
        constraint = ticket.current_status == TicketStatus::Sold @ TicketError::InvalidTicketStatus
    )]
    pub ticket: Account<'info, TicketAccount>,
    
    /// CHECK: 验票员，需要是主办方或授权人员
    #[account(
        constraint = validator.key() == event.organizer @ TicketError::NotAuthorizedValidator
    )]
    pub validator: Signer<'info>,
}

pub fn handler(ctx: Context<RedeemTicket>) -> Result<()> {
    let ticket = &mut ctx.accounts.ticket;
    let event = &ctx.accounts.event;
    let clock = Clock::get()?;
    let current_time = clock.unix_timestamp;

    // 检查活动时间
    require!(
        current_time >= event.event_start_time,
        TicketError::EventNotStarted
    );
    require!(
        current_time <= event.event_end_time,
        TicketError::EventEnded
    );

    // 检查门票状态
    require!(
        ticket.current_status == TicketStatus::Sold,
        TicketError::InvalidTicketStatus
    );
    require!(
        ticket.redeemed_at.is_none(),
        TicketError::TicketAlreadyRedeemed
    );

    // 更新门票状态
    ticket.current_status = TicketStatus::Redeemed;
    ticket.redeemed_at = Some(current_time);

    msg!(
        "门票核销成功: 门票mint: {}, 核销时间: {}",
        ticket.mint,
        current_time
    );

    Ok(())
} 