use anchor_lang::prelude::*;
use crate::{constants::*, error::TicketError, state::*};

#[derive(Accounts)]
#[instruction(ticket_type_name: String)]
pub struct MintTickets<'info> {
    #[account(
        mut,
        constraint = event.organizer == organizer.key() @ TicketError::NotEventOrganizer
    )]
    pub event: Account<'info, EventAccount>,
    
    #[account(
        mut,
        seeds = [TICKET_TYPE_SEED, event.key().as_ref(), ticket_type_name.as_bytes()],
        bump
    )]
    pub ticket_type: Account<'info, TicketTypeAccount>,
    
    #[account(mut)]
    pub organizer: Signer<'info>,
}

pub fn handler(
    ctx: Context<MintTickets>,
    ticket_type_name: String,
    quantity: u32,
) -> Result<()> {
    let event = &mut ctx.accounts.event;
    let ticket_type = &ctx.accounts.ticket_type;

    // 验证票种名称匹配
    require!(
        ticket_type.type_name == ticket_type_name,
        TicketError::TicketTypeNotFound
    );

    // 验证数量
    require!(quantity > 0, TicketError::InvalidArgument);

    // 这里简化处理，实际需要批量创建NFT mints
    // 更新铸造数量
    event.total_tickets_minted = event.total_tickets_minted
        .checked_add(quantity)
        .ok_or(TicketError::Overflow)?;

    msg!(
        "批量铸造门票成功: 票种名称: {}, 数量: {}",
        ticket_type_name,
        quantity
    );

    Ok(())
} 