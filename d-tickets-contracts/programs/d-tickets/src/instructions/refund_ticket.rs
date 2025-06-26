use anchor_lang::prelude::*;
use crate::{
    state::{TicketTypeAccount, TicketAccount, OrganizerEarnings, EventAccount},
    error::TicketError,
    constants::*,
};

#[derive(Accounts)]
pub struct RefundTicket<'info> {
    #[account(
        mut,
        seeds = [EVENT_SEED, event.organizer.as_ref(), event.event_name.as_bytes()],
        bump = event.bump
    )]
    pub event: Account<'info, EventAccount>,

    #[account(
        mut,
        seeds = [TICKET_TYPE_SEED, event.key().as_ref(), ticket.ticket_type_name.as_bytes()],
        bump = ticket_type.bump
    )]
    pub ticket_type: Account<'info, TicketTypeAccount>,

    #[account(
        mut,
        seeds = [TICKET_SEED, ticket.mint.as_ref()],
        bump = ticket.bump
    )]
    pub ticket: Account<'info, TicketAccount>,

    #[account(
        mut,
        seeds = [EARNINGS_SEED, event.key().as_ref()],
        bump = earnings.bump
    )]
    pub earnings: Account<'info, OrganizerEarnings>,

    #[account(mut)]
    pub refund_requester: Signer<'info>,
}

pub fn handler(ctx: Context<RefundTicket>) -> Result<()> {
    let ticket = &mut ctx.accounts.ticket;
    let ticket_type = &mut ctx.accounts.ticket_type;
    let event = &mut ctx.accounts.event;
    let earnings = &mut ctx.accounts.earnings;
    let current_time = Clock::get()?.unix_timestamp;

    // 验证退票权限
    require!(
        ticket.current_owner == ctx.accounts.refund_requester.key(),
        TicketError::NotTicketOwner
    );

    // 验证是否在退票时间范围内
    require!(
        current_time < event.event_start_time,
        TicketError::RefundDeadlinePassed
    );

    // 计算退款金额
    let refund_amount = ticket.original_price;

    // 更新统计数据
    ticket_type.refunded_count += 1;
    ticket_type.sold_count = ticket_type.sold_count.saturating_sub(1);
    event.total_tickets_refunded += 1;
    event.total_tickets_sold = event.total_tickets_sold.saturating_sub(1);
    event.total_revenue = event.total_revenue.saturating_sub(refund_amount);
    earnings.total_earnings = earnings.total_earnings.saturating_sub(refund_amount);
    earnings.pending_amount = earnings.pending_amount.saturating_sub(refund_amount);

    // 更新时间戳
    event.updated_at = current_time;

    Ok(())
} 