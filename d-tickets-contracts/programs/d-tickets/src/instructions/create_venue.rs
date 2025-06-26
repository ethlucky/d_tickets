use anchor_lang::prelude::*;
use crate::state::{VenueAccount, VenueType, VenueStatus};
use crate::error::TicketError;

#[derive(Accounts)]
#[instruction(venue_name: String)]
pub struct CreateVenue<'info> {
    /// 场馆创建者（主办方）
    #[account(mut)]
    pub creator: Signer<'info>,

    /// 场馆账户（PDA）- 使用 InitSpace 自动计算空间
    #[account(
        init,
        payer = creator,
        space = 8 + VenueAccount::INIT_SPACE,
        seeds = [b"venue", creator.key().as_ref(), venue_name.as_bytes()],
        bump
    )]
    pub venue_account: Account<'info, VenueAccount>,

    /// 系统程序
    pub system_program: Program<'info, System>,
}

pub fn handler(
    ctx: Context<CreateVenue>,
    venue_name: String,
    venue_address: String,
    total_capacity: u32,
    venue_description: String,
    venue_type: VenueType,
    contact_info: String,
    floor_plan_hash: Option<String>,
    facilities_info_hash: Option<String>,
) -> Result<()> {
    let venue_account = &mut ctx.accounts.venue_account;
    let creator = &ctx.accounts.creator;
    let clock = Clock::get()?;

    // 验证输入参数 - 对应 #[max_len] 属性
    require!(venue_name.len() <= 100, TicketError::VenueNameTooLong);
    require!(venue_address.len() <= 500, TicketError::VenueAddressTooLong);
    require!(venue_description.len() <= 1000, TicketError::VenueDescriptionTooLong);
    require!(contact_info.len() <= 300, TicketError::ContactInfoTooLong);
    require!(total_capacity > 0, TicketError::InvalidCapacity);

    // 如果提供了平面图哈希，验证其长度
    if let Some(ref hash) = floor_plan_hash {
        require!(hash.len() <= 100, TicketError::InvalidHash);
    }

    // 如果提供了设施信息哈希，验证其长度
    if let Some(ref hash) = facilities_info_hash {
        require!(hash.len() <= 100, TicketError::InvalidHash);
    }

    // 初始化场馆账户
    venue_account.creator = creator.key();
    venue_account.venue_name = venue_name;
    venue_account.venue_address = venue_address;
    venue_account.total_capacity = total_capacity;
    venue_account.venue_description = venue_description;
    venue_account.floor_plan_hash = floor_plan_hash;
    venue_account.seat_map_hash = None; // 初始时没有座位图
    venue_account.venue_type = venue_type;
    venue_account.facilities_info_hash = facilities_info_hash;
    venue_account.contact_info = contact_info;
    venue_account.venue_status = VenueStatus::Unused; // 默认为未使用状态
    venue_account.created_at = clock.unix_timestamp;
    venue_account.updated_at = clock.unix_timestamp;
    venue_account.bump = ctx.bumps.venue_account;

    msg!("场馆创建成功: {}", venue_account.venue_name);
    
    Ok(())
} 