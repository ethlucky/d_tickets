use anchor_lang::prelude::*;
use crate::{constants::*, error::TicketError, state::*};

#[derive(Accounts)]
pub struct SetupPlatform<'info> {
    #[account(
        init_if_needed,
        payer = admin,
        space = PlatformAccount::INIT_SPACE,
        seeds = [PLATFORM_SEED],
        bump
    )]
    pub platform: Account<'info, PlatformAccount>,
    
    #[account(mut)]
    pub admin: Signer<'info>,
    
    /// CHECK: 收款账户，可以是任何有效的钱包地址。如果为None，将使用默认地址或保持现有地址
    pub fee_recipient: Option<AccountInfo<'info>>,
    
    pub system_program: Program<'info, System>,
}

pub fn handler(
    ctx: Context<SetupPlatform>,
    platform_fee_bps: Option<u16>,
    new_fee_recipient: Option<Pubkey>,
    new_is_paused: Option<bool>,
) -> Result<()> {
    let platform = &mut ctx.accounts.platform;
    let clock = Clock::get()?;
    let current_time = clock.unix_timestamp;

    // 检查是否是新初始化的账户
    let is_new_account = platform.admin == Pubkey::default();

    if is_new_account {
        // 初始化逻辑
        msg!("初始化新的platform账户");
        
        let default_fee_bps = platform_fee_bps.unwrap_or(DEFAULT_PLATFORM_FEE_BPS);
        
        // 验证手续费比例
        require!(
            default_fee_bps <= MAX_PLATFORM_FEE_BPS,
            TicketError::InvalidArgument
        );

        // 设置收款地址优先级：new_fee_recipient > fee_recipient account > 默认地址
        let fee_recipient = if let Some(recipient) = new_fee_recipient {
            recipient
        } else if let Some(recipient_account) = &ctx.accounts.fee_recipient {
            recipient_account.key()
        } else {
            DEFAULT_FEE_RECIPIENT.parse::<Pubkey>().unwrap()
        };

        // 初始化平台账户
        platform.admin = ctx.accounts.admin.key();
        platform.platform_fee_bps = default_fee_bps;
        platform.fee_recipient = fee_recipient;
        platform.is_paused = false;
        platform.min_ticket_price = MIN_TICKET_PRICE;
        platform.max_ticket_price = MAX_TICKET_PRICE;
        platform.supported_tokens = vec![];
        platform.total_platform_revenue = 0;
        platform.total_transactions = 0;
        platform.bump = ctx.bumps.platform;
        platform.created_at = current_time;
        platform.updated_at = current_time;
        platform._reserved = [0; 63];

        msg!(
            "平台初始化完成，管理员: {}, 手续费: {}bps, 收款地址: {}",
            ctx.accounts.admin.key(),
            default_fee_bps,
            fee_recipient
        );
    } else {
        // 更新逻辑
        msg!("更新现有platform账户");
        
        // 验证权限
        require!(
            platform.admin == ctx.accounts.admin.key(),
            TicketError::Unauthorized
        );

        // 更新收款地址
        if let Some(recipient) = new_fee_recipient {
            platform.fee_recipient = recipient;
            msg!("Fee recipient updated to: {}", recipient);
        } else if let Some(recipient_account) = &ctx.accounts.fee_recipient {
            platform.fee_recipient = recipient_account.key();
            msg!("Fee recipient updated to: {}", recipient_account.key());
        }

        // 更新平台手续费
        if let Some(fee_bps) = platform_fee_bps {
            require!(
                fee_bps <= MAX_PLATFORM_FEE_BPS,
                TicketError::InvalidArgument
            );
            platform.platform_fee_bps = fee_bps;
            msg!("Platform fee updated to: {}bps", fee_bps);
        }

        // 更新暂停状态
        if let Some(is_paused) = new_is_paused {
            platform.is_paused = is_paused;
            msg!("Platform pause status updated to: {}", is_paused);
        }

        platform.updated_at = current_time;

        msg!(
            "Platform settings updated by admin: {}",
            ctx.accounts.admin.key()
        );
    }

    Ok(())
} 