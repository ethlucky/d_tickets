use anchor_lang::prelude::*;
use crate::state::{VenueAccount, SeatAccount, SeatStatus, SeatStatusMap, TicketTypeAccount, SeatStatusUpdate, SeatInfo};
use crate::error::TicketError;
use crate::constants::*;

/// 座位售出事件
#[event]
pub struct SeatSoldEvent {
    /// 活动PDA
    pub event_pda: Pubkey,
    /// 活动名称
    pub event_name: String,
    /// 票种PDA
    pub ticket_type_pda: Pubkey,
    /// 票种名称
    pub ticket_type_name: String,
    /// 区域ID
    pub area_id: String,
    /// 座位索引
    pub seat_index: u32,
    /// 座位信息
    pub seat_row: String,
    /// 座位号
    pub seat_number: String,
    /// 购买者地址
    pub buyer: Pubkey,
    /// 票价
    pub ticket_price: u64,
    /// 购买时间戳
    pub purchased_at: i64,
    /// 座位状态映射PDA
    pub seat_status_map_pda: Pubkey,
}

#[derive(Accounts)]
#[instruction(venue_name: String, ticket_type_name: String, seat_number: String)]
pub struct ConfigureSeat<'info> {
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

    /// 票种账户（PDA）
    #[account(
        seeds = [TICKET_TYPE_SEED, event.key().as_ref(), ticket_type_name.as_bytes()],
        bump = ticket_type.bump
    )]
    pub ticket_type: Account<'info, TicketTypeAccount>,

    /// 关联的活动账户
    #[account()]
    pub event: Account<'info, crate::state::EventAccount>,

    /// 座位账户（PDA）- 使用 InitSpace 自动计算空间
    #[account(
        init,
        payer = creator,
        space = 8 + SeatAccount::INIT_SPACE,
        seeds = [b"seat", venue_account.key().as_ref(), ticket_type.key().as_ref(), seat_number.as_bytes()],
        bump
    )]
    pub seat_account: Account<'info, SeatAccount>,

    /// 系统程序
    pub system_program: Program<'info, System>,
}



#[derive(Accounts)]
#[instruction(venue_name: String, ticket_type_name: String, seat_number: String)]
pub struct UpdateSeatStatus<'info> {
    /// 场馆创建者（主办方）
    #[account(mut)]
    pub creator: Signer<'info>,

    /// 场馆账户（PDA）
    #[account(
        seeds = [b"venue", creator.key().as_ref(), venue_name.as_bytes()],
        bump = venue_account.bump,
        has_one = creator
    )]
    pub venue_account: Account<'info, VenueAccount>,

    /// 票种账户（PDA）
    #[account(
        seeds = [TICKET_TYPE_SEED, event.key().as_ref(), ticket_type_name.as_bytes()],
        bump = ticket_type.bump
    )]
    pub ticket_type: Account<'info, TicketTypeAccount>,

    /// 关联的活动账户
    #[account()]
    pub event: Account<'info, crate::state::EventAccount>,

    /// 座位账户（PDA）
    #[account(
        mut,
        seeds = [b"seat", venue_account.key().as_ref(), ticket_type.key().as_ref(), seat_number.as_bytes()],
        bump = seat_account.bump
    )]
    pub seat_account: Account<'info, SeatAccount>,
}

/// 创建或更新座位状态映射账户
#[derive(Accounts)]
#[instruction(ticket_type_name: String, area_id: String)]
pub struct CreateOrUpdateSeatStatusMap<'info> {
    /// 活动创建者
    #[account(mut)]
    pub creator: Signer<'info>,

    /// 活动账户
    #[account(
        mut,
        constraint = event.organizer == creator.key()
    )]
    pub event: Account<'info, crate::state::EventAccount>,

    /// 票种账户
    #[account(
        seeds = [TICKET_TYPE_SEED, event.key().as_ref(), ticket_type_name.as_bytes()],
        bump = ticket_type.bump
    )]
    pub ticket_type: Account<'info, TicketTypeAccount>,

    /// 座位状态映射账户（PDA）- 支持创建或更新
    #[account(
        init_if_needed,
        payer = creator,
        space = 8 + SeatStatusMap::INIT_SPACE,
        seeds = [b"seat_status_map", event.key().as_ref(), ticket_type.key().as_ref(), area_id.as_bytes()],
        bump
    )]
    pub seat_status_map: Account<'info, SeatStatusMap>,

    /// 系统程序
    pub system_program: Program<'info, System>,
}

/// 批量更新座位状态（新方案）
#[derive(Accounts)]
#[instruction(ticket_type_name: String, area_id: String)]
pub struct BatchUpdateSeatStatus<'info> {
    /// 授权用户（可以是创建者或购票者）
    #[account(mut)]
    pub authority: Signer<'info>,

    /// 活动账户
    #[account(mut)]
    pub event: Account<'info, crate::state::EventAccount>,

    /// 票种账户
    #[account(
        mut,
        seeds = [TICKET_TYPE_SEED, event.key().as_ref(), ticket_type_name.as_bytes()],
        bump = ticket_type.bump
    )]
    pub ticket_type: Account<'info, TicketTypeAccount>,

    /// 座位状态映射账户
    #[account(
        mut,
        seeds = [b"seat_status_map", event.key().as_ref(), ticket_type.key().as_ref(), area_id.as_bytes()],
        bump = seat_status_map.bump
    )]
    pub seat_status_map: Account<'info, SeatStatusMap>,

    /// 主办方收益账户
    #[account(
        mut,
        seeds = [EARNINGS_SEED, event.key().as_ref()],
        bump = earnings.bump
    )]
    pub earnings: Account<'info, crate::state::OrganizerEarnings>,

    /// 平台账户
    #[account(
        seeds = [PLATFORM_SEED],
        bump = platform.bump
    )]
    pub platform: Account<'info, crate::state::PlatformAccount>,

    /// 系统程序
    pub system_program: Program<'info, System>,
}

/// 删除座位状态映射账户
#[derive(Accounts)]
#[instruction(ticket_type_name: String, area_id: String)]
pub struct DeleteSeatStatusMap<'info> {
    /// 活动创建者
    #[account(mut)]
    pub creator: Signer<'info>,

    /// 活动账户
    #[account(
        mut,
        constraint = event.organizer == creator.key()
    )]
    pub event: Account<'info, crate::state::EventAccount>,

    /// 票种账户
    #[account(
        seeds = [TICKET_TYPE_SEED, event.key().as_ref(), ticket_type_name.as_bytes()],
        bump = ticket_type.bump
    )]
    pub ticket_type: Account<'info, TicketTypeAccount>,

    /// 座位状态映射账户（PDA）- 待删除
    #[account(
        mut,
        close = creator,
        seeds = [b"seat_status_map", event.key().as_ref(), ticket_type.key().as_ref(), area_id.as_bytes()],
        bump = seat_status_map.bump
    )]
    pub seat_status_map: Account<'info, SeatStatusMap>,
}



pub fn configure_seat(
    ctx: Context<ConfigureSeat>,
    _venue_name: String,
    _ticket_type_name: String,
    seat_number: String,
    area_id: String,
    row_number: String,
    seat_number_in_row: String,
) -> Result<()> {
    let seat_account = &mut ctx.accounts.seat_account;
    let venue_account = &ctx.accounts.venue_account;
    let ticket_type = &ctx.accounts.ticket_type;
    let event = &ctx.accounts.event;
    let clock = Clock::get()?;

    // 验证输入参数
    require!(seat_number.len() <= 20, TicketError::SeatNumberTooLong);
    require!(area_id.len() <= 20, TicketError::AreaIdTooLong);
    require!(row_number.len() <= 10, TicketError::RowNumberTooLong);
    require!(seat_number_in_row.len() <= 10, TicketError::SeatNumberInRowTooLong);

    // 初始化座位账户
    seat_account.venue = venue_account.key();
    seat_account.ticket_type_key = ticket_type.key();
    seat_account.event = Some(event.key());
    seat_account.seat_number = seat_number;
    seat_account.area_id = area_id;
    seat_account.row_number = row_number;
    seat_account.seat_number_in_row = seat_number_in_row;
    seat_account.seat_status = SeatStatus::Available;
    seat_account.ticket_nft = None;
    seat_account.ticket_type_id = Some(ticket_type.ticket_type_id);
    seat_account.created_at = clock.unix_timestamp;
    seat_account.updated_at = clock.unix_timestamp;
    seat_account.bump = ctx.bumps.seat_account;

    msg!("座位配置成功: {}", seat_account.seat_number);
    
    Ok(())
}

/// 创建或更新座位状态映射（支持添加和修改两种情况）
pub fn create_seat_status_map(
    ctx: Context<CreateOrUpdateSeatStatusMap>,
    ticket_type_name: String,
    area_id: String,
    seat_layout_hash: String,
    seat_index_map_hash: String,
    total_seats: u32,
) -> Result<()> {
    let seat_status_map = &mut ctx.accounts.seat_status_map;
    let event = &ctx.accounts.event;
    let ticket_type = &ctx.accounts.ticket_type;
    let clock = Clock::get()?;

    // 验证输入参数
    require!(seat_layout_hash.len() <= 100, TicketError::InvalidHash);
    require!(seat_index_map_hash.len() <= 100, TicketError::InvalidHash);
    // 验证座位总数不能超过票种的总库存
    require!(
        total_seats <= ticket_type.total_supply, 
        TicketError::ExceedsTicketSupply
    );

    // 检查是创建还是更新
    let is_new_account = seat_status_map.event == Pubkey::default();
    
    if is_new_account {
        // 创建新的座位状态映射
        seat_status_map.event = event.key();
        seat_status_map.ticket_type = ticket_type.key();
        seat_status_map.sold_seats = 0;
        seat_status_map.created_at = clock.unix_timestamp;
        seat_status_map.bump = ctx.bumps.seat_status_map;
        
        // 初始化位图（所有座位默认为可用状态）
        seat_status_map.initialize_bitmap(total_seats)?;
        
        // 将票种-区域映射添加到活动的映射列表中
        let event_account = &mut ctx.accounts.event;
        event_account.add_ticket_area_mapping(&ticket_type_name, &area_id)?;
        
        msg!(
            "座位状态映射创建成功: 票种={}, 区域={}, 总座位数={}, IPFS布局={}, IPFS索引={}",
            ticket_type_name,
            area_id,
            total_seats,
            seat_layout_hash,
            seat_index_map_hash
        );
    } else {
        // 更新现有的座位状态映射
        // 验证是否允许修改（例如：没有已售座位或特定权限）
        require!(
            seat_status_map.sold_seats == 0, 
            TicketError::CannotModifyWithSoldSeats
        );
        
        // 如果座位数量发生变化，需要重新初始化位图
        if seat_status_map.total_seats != total_seats {
            seat_status_map.initialize_bitmap(total_seats)?;
        }
        
        // 确保票种-区域映射存在于活动中（即使是更新操作）
        let event_account = &mut ctx.accounts.event;
        event_account.add_ticket_area_mapping(&ticket_type_name, &area_id)?;
        
        msg!(
            "座位状态映射更新成功: 票种={}, 区域={}, 总座位数={} -> {}, IPFS布局={}, IPFS索引={}",
            ticket_type_name,
            area_id,
            seat_status_map.total_seats,
            total_seats,
            seat_layout_hash,
            seat_index_map_hash
        );
    }

    // 更新或设置通用字段
    seat_status_map.seat_layout_hash = seat_layout_hash.clone();
    seat_status_map.seat_index_map_hash = seat_index_map_hash.clone();
    seat_status_map.updated_at = clock.unix_timestamp;

    Ok(())
}

/// 删除座位状态映射
pub fn delete_seat_status_map(
    ctx: Context<DeleteSeatStatusMap>,
    ticket_type_name: String,
    area_id: String,
) -> Result<()> {
    let seat_status_map = &ctx.accounts.seat_status_map;
    let event_account = &mut ctx.accounts.event;
    let _ticket_type = &ctx.accounts.ticket_type;

    // 验证删除权限：确保没有已售出的座位
    require!(
        seat_status_map.sold_seats == 0, 
        TicketError::CannotDeleteWithSoldSeats
    );

    // 从活动的票种-区域映射列表中删除对应映射
    event_account.remove_ticket_area_mapping(&ticket_type_name, &area_id)?;

    msg!(
        "座位状态映射删除成功: 活动={}, 票种={}, 区域={}, 总座位数={}",
        event_account.event_name,
        ticket_type_name,
        area_id,
        seat_status_map.total_seats
    );

    // 账户会自动通过 close = creator 约束关闭并返还租金
    Ok(())
}

/// 批量更新座位状态
pub fn batch_update_seat_status(
    ctx: Context<BatchUpdateSeatStatus>,
    _ticket_type_name: String,
    _area_id: String,
    seat_updates: Vec<SeatStatusUpdate>,
) -> Result<()> {
    let seat_status_map = &mut ctx.accounts.seat_status_map;
    let ticket_type = &mut ctx.accounts.ticket_type;
    let event = &mut ctx.accounts.event;
    let earnings = &mut ctx.accounts.earnings;
    let platform = &ctx.accounts.platform;
    let current_time = Clock::get()?.unix_timestamp;

    // 限制批量更新数量
    require!(seat_updates.len() <= 50, TicketError::TooManySeats);
    require!(seat_updates.len() > 0, TicketError::RequiredFieldEmpty);

    msg!("开始批量更新座位状态: {} 个座位", seat_updates.len());

    // 分别处理每个座位更新
    for update in seat_updates {
        let old_status = seat_status_map.get_seat_status(update.seat_index)?;
        
        // 如果是从可用状态变为已售出状态，需要特殊处理
        if old_status != SeatStatus::Sold && update.new_status == SeatStatus::Sold {
            // 验证购票者信息和座位信息是否提供
            let buyer = update.buyer.ok_or(TicketError::RequiredFieldEmpty)?;
            let seat_info = update.seat_info.as_ref().ok_or(TicketError::RequiredFieldEmpty)?;
            
            // 验证票种库存
            require!(
                ticket_type.sold_count < ticket_type.total_supply,
                TicketError::InsufficientTicketSupply
            );

            // 计算价格和费用
            let ticket_price = ticket_type.current_price;
            let platform_fee = ticket_price
                .checked_mul(platform.platform_fee_bps as u64)
                .unwrap()
                .checked_div(10000)
                .unwrap();
            let organizer_amount = ticket_price.checked_sub(platform_fee).unwrap();

            // 更新统计数据和座位状态
            
            // 更新票种和活动统计数据
            ticket_type.sold_count += 1;
            event.total_tickets_sold += 1;
            event.total_revenue += ticket_price;
            earnings.total_earnings += organizer_amount;
            earnings.pending_amount += organizer_amount;

            // 发出座位售出事件，供后台监听和处理NFT铸造
            emit!(SeatSoldEvent {
                event_pda: event.key(),
                event_name: event.event_name.clone(),
                ticket_type_pda: ticket_type.key(),
                ticket_type_name: ticket_type.type_name.clone(),
                area_id: seat_info.area_id.clone(),
                seat_index: update.seat_index,
                seat_row: seat_info.row_number.clone(),
                seat_number: seat_info.seat_number_in_row.clone(),
                buyer,
                ticket_price,
                purchased_at: current_time,
                seat_status_map_pda: seat_status_map.key(),
            });

            msg!(
                "座位售出 - 活动:{}, 票种:{}, 区域:{}, 座位索引:{}, 排号:{}, 座号:{}, 购买者:{}, 价格:{} lamports",
                event.event_name,
                ticket_type.type_name,
                seat_info.area_id,
                update.seat_index,
                seat_info.row_number, 
                seat_info.seat_number_in_row,
                buyer,
                ticket_price
            );

        } 
        // else if old_status == SeatStatus::Sold && update.new_status != SeatStatus::Sold {
        //     // 如果是从已售出状态变为其他状态（如退票），需要处理退款逻辑
            
        //     // 计算退款金额
        //     let refund_amount = ticket_type.current_price;
            
        //     // 更新统计数据
        //     ticket_type.sold_count = ticket_type.sold_count.saturating_sub(1);
        //     ticket_type.refunded_count += 1;
        //     event.total_tickets_sold = event.total_tickets_sold.saturating_sub(1);
        //     event.total_tickets_refunded += 1;
        //     event.total_revenue = event.total_revenue.saturating_sub(refund_amount);
        //     earnings.total_earnings = earnings.total_earnings.saturating_sub(refund_amount);
        //     earnings.pending_amount = earnings.pending_amount.saturating_sub(refund_amount);

        //     msg!(
        //         "座位 {} 从已售出状态变更为 {:?}: 退款金额={} lamports",
        //         update.seat_index,
        //         update.new_status,
        //         refund_amount
        //     );
        // }

        // 更新座位状态
        seat_status_map.update_seat_status(update.seat_index, update.new_status.clone())?;
        msg!("座位索引 {} 状态更新为 {:?}", update.seat_index, update.new_status);
    }

    // 更新时间戳
    event.updated_at = current_time;
    ticket_type.last_price_update = current_time;

    msg!(
        "批量座位状态更新完成: 已售={}/{}, 总收入={} lamports",
        seat_status_map.sold_seats,
        seat_status_map.total_seats,
        event.total_revenue
    );

    Ok(())
}

/// 查询座位状态（只读操作）
pub fn get_seat_status_batch(
    ctx: Context<BatchUpdateSeatStatus>,
    _ticket_type_name: String,
    _area_id: String,
    seat_indices: Vec<u32>,
) -> Result<()> {
    let seat_status_map = &ctx.accounts.seat_status_map;

    require!(seat_indices.len() <= 100, TicketError::TooManySeats);

    msg!("查询座位状态:");
    for seat_index in seat_indices {
        let status = seat_status_map.get_seat_status(seat_index)?;
        msg!("座位索引 {}: {:?}", seat_index, status);
    }

    Ok(())
}

pub fn update_seat_status(
    ctx: Context<UpdateSeatStatus>,
    _venue_name: String,
    _ticket_type_name: String,
    _seat_number: String,
    new_status: SeatStatus,
    event_key: Option<Pubkey>,
    ticket_nft: Option<Pubkey>,
    ticket_type_id: Option<u8>,
) -> Result<()> {
    let seat_account = &mut ctx.accounts.seat_account;
    let clock = Clock::get()?;

    // 更新座位状态
    seat_account.seat_status = new_status.clone();
    
    if let Some(event) = event_key {
        seat_account.event = Some(event);
    }
    
    if let Some(nft) = ticket_nft {
        seat_account.ticket_nft = Some(nft);
    }
    
    if let Some(type_id) = ticket_type_id {
        seat_account.ticket_type_id = Some(type_id);
    }

    seat_account.updated_at = clock.unix_timestamp;

    msg!("座位状态更新成功: {} -> {:?}", seat_account.seat_number, new_status);
    
    Ok(())
}





 