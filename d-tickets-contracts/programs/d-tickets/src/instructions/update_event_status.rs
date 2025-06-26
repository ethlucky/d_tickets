use anchor_lang::prelude::*;
use crate::{
    state::{EventAccount, EventStatus, VenueAccount, VenueStatus},
    error::TicketError,
    constants::*,
};

#[derive(Accounts)]
#[instruction(event_name: String)]
pub struct UpdateEventStatus<'info> {
    #[account(
        mut,
        seeds = [EVENT_SEED, organizer.key().as_ref(), event_name.as_bytes()],
        bump = event.bump,
        has_one = organizer @ TicketError::NotEventOrganizer
    )]
    pub event: Account<'info, EventAccount>,

    /// 关联的场馆账户（用于状态更新）
    #[account(mut)]
    pub venue: Account<'info, VenueAccount>,

    #[account(mut)]
    pub organizer: Signer<'info>,
}

pub fn handler(
    ctx: Context<UpdateEventStatus>,
    _event_name: String,
    new_status: EventStatus,
) -> Result<()> {
    let event = &mut ctx.accounts.event;
    let venue = &mut ctx.accounts.venue;
    let current_time = Clock::get()?.unix_timestamp;

    // 验证场馆是否与活动关联
    require!(
        venue.key() == event.venue_account,
        TicketError::VenueNotFound
    );

    // 验证状态转换的合法性
    match (&event.event_status, &new_status) {
        (EventStatus::Upcoming, EventStatus::OnSale) => {
            require!(
                current_time >= event.ticket_sale_start_time,
                TicketError::InvalidStateTransition
            );
        }
        (EventStatus::OnSale, EventStatus::SoldOut) => {
            // 可以手动设置为售罄状态
        }
        (EventStatus::OnSale, EventStatus::Completed) => {
            require!(
                current_time >= event.event_end_time,
                TicketError::InvalidStateTransition
            );
        }
        (EventStatus::SoldOut, EventStatus::Completed) => {
            require!(
                current_time >= event.event_end_time,
                TicketError::InvalidStateTransition
            );
        }
        (_, EventStatus::Cancelled) => {
            // 可以随时取消活动
        }
        (_, EventStatus::Postponed) => {
            // 可以随时延期活动
        }
        (EventStatus::Postponed, EventStatus::Upcoming) => {
            // 可以从延期状态恢复到即将到来状态
        }
        _ => {
            return Err(TicketError::InvalidStateTransition.into());
        }
    }

    // 更新状态和时间戳
    event.event_status = new_status.clone();
    event.updated_at = current_time;

    // 如果活动被取消或完成，将场馆状态更新为未使用状态
    match new_status {
        EventStatus::Cancelled | EventStatus::Completed => {
            venue.venue_status = VenueStatus::Unused;
            venue.updated_at = current_time;
            msg!("场馆状态已更新为未使用: {}", venue.venue_name);
        }
        _ => {
            // 其他状态不需要更新场馆状态
        }
    }

    msg!(
        "活动状态更新成功: {} -> {:?}",
        event.event_name,
        event.event_status
    );

    Ok(())
} 