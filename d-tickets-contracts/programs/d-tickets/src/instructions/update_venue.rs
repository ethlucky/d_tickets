use anchor_lang::prelude::*;
use crate::state::{VenueAccount, VenueType, VenueStatus};
use crate::error::TicketError;

#[derive(Accounts)]
#[instruction(venue_name: String)]
pub struct UpdateVenue<'info> {
    /// 场馆创建者（主办方）
    #[account(mut)]
    pub creator: Signer<'info>,

    /// 场馆账户（PDA）
    #[account(
        mut,
        seeds = [b"venue", creator.key().as_ref(), venue_name.as_bytes()],
        bump = venue_account.bump,
        has_one = creator
    )]
    pub venue_account: Account<'info, VenueAccount>,

    /// 系统程序
    pub system_program: Program<'info, System>,
}

pub fn handler(
    ctx: Context<UpdateVenue>,
    venue_name: String,
    new_venue_address: Option<String>,
    new_total_capacity: Option<u32>,
    new_venue_description: Option<String>,
    new_venue_type: Option<VenueType>,
    new_contact_info: Option<String>,
    new_floor_plan_hash: Option<String>,
    new_seat_map_hash: Option<String>,
    new_facilities_info_hash: Option<String>,
    new_venue_status: Option<VenueStatus>,
) -> Result<()> {
    let venue_account = &mut ctx.accounts.venue_account;

    // 注意：venue_name 不能修改，因为它是 PDA 种子，修改会导致 PDA 地址改变
    require!(
        venue_name == venue_account.venue_name,
        TicketError::InvalidVenueName
    );

    // 验证并更新场馆地址 - 对应 #[max_len(500)]
    if let Some(address) = new_venue_address {
        require!(address.len() <= 500, TicketError::VenueAddressTooLong);
        venue_account.venue_address = address;
    }

    // 更新总容量
    if let Some(capacity) = new_total_capacity {
        require!(capacity > 0, TicketError::InvalidCapacity);
        venue_account.total_capacity = capacity;
    }

    // 验证并更新场馆描述 - 对应 #[max_len(1000)]
    if let Some(description) = new_venue_description {
        require!(description.len() <= 1000, TicketError::VenueDescriptionTooLong);
        venue_account.venue_description = description;
    }

    // 更新场馆类型
    if let Some(venue_type) = new_venue_type {
        venue_account.venue_type = venue_type;
    }

    // 验证并更新联系信息 - 对应 #[max_len(300)]
    if let Some(contact) = new_contact_info {
        require!(contact.len() <= 300, TicketError::ContactInfoTooLong);
        venue_account.contact_info = contact;
    }

    // 验证并更新平面图哈希 - 对应 #[max_len(100)]
    if let Some(hash) = new_floor_plan_hash {
        require!(hash.len() <= 100, TicketError::InvalidHash);
        venue_account.floor_plan_hash = Some(hash);
    }

    // 验证并更新座位图哈希 - 对应 #[max_len(100)]
    if let Some(hash) = new_seat_map_hash {
        require!(hash.len() <= 100, TicketError::InvalidHash);
        venue_account.seat_map_hash = Some(hash);
    }

    // 验证并更新设施信息哈希 - 对应 #[max_len(100)]
    if let Some(hash) = new_facilities_info_hash {
        require!(hash.len() <= 100, TicketError::InvalidHash);
        venue_account.facilities_info_hash = Some(hash);
    }

    // 更新场馆状态
    if let Some(status) = new_venue_status {
        venue_account.venue_status = status;
    }

    // 更新时间戳
    let clock = Clock::get()?;
    venue_account.updated_at = clock.unix_timestamp;

    msg!("场馆信息更新成功: {}", venue_name);
    
    Ok(())
} 