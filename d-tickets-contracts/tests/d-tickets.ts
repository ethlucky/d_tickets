import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { DTickets } from "../target/types/d_tickets";
import { expect } from "chai";

describe("d-tickets venue-event integration", () => {
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);

  const program = anchor.workspace.DTickets as Program<DTickets>;
  const organizer = provider.wallet;

  let venueAccount: anchor.web3.Keypair;
  let eventPda: anchor.web3.PublicKey;
  let earningsPda: anchor.web3.PublicKey;
  let platformPda: anchor.web3.PublicKey;

  before(async () => {
    // 初始化平台
    [platformPda] = anchor.web3.PublicKey.findProgramAddressSync(
      [Buffer.from("platform")],
      program.programId
    );

    try {
      await program.methods
        .setupPlatform(500, organizer.publicKey, false) // 5% 手续费
        .accounts({
          platform: platformPda,
          admin: organizer.publicKey,
          systemProgram: anchor.web3.SystemProgram.programId,
        })
        .rpc();
    } catch (error) {
      // 平台可能已存在，忽略错误
    }
  });

  it("创建场馆", async () => {
    venueAccount = anchor.web3.Keypair.generate();

    await program.methods
      .createVenue(
        "测试场馆",
        "测试地址123号",
        1000,
        "这是一个测试场馆描述",
        { concert: {} }, // VenueType::Concert
        "联系方式: test@example.com",
        null, // floor_plan_hash
        null  // facilities_info_hash
      )
      .accounts({
        venue: venueAccount.publicKey,
        owner: organizer.publicKey,
        systemProgram: anchor.web3.SystemProgram.programId,
      })
      .signers([venueAccount])
      .rpc();

    // 验证场馆创建成功
    const venue = await program.account.venueAccount.fetch(venueAccount.publicKey);
    expect(venue.venueName).to.equal("测试场馆");
    expect(venue.venueAddress).to.equal("测试地址123号");
    expect(venue.totalCapacity).to.equal(1000);
  });

  it("创建关联场馆的活动", async () => {
    const eventName = "测试音乐会";
    const now = Math.floor(Date.now() / 1000);
    
    // 计算 PDA
    [eventPda] = anchor.web3.PublicKey.findProgramAddressSync(
      [
        Buffer.from("event"),
        organizer.publicKey.toBuffer(),
        Buffer.from(eventName)
      ],
      program.programId
    );

    [earningsPda] = anchor.web3.PublicKey.findProgramAddressSync(
      [Buffer.from("earnings"), eventPda.toBuffer()],
      program.programId
    );

    await program.methods
      .createEvent(
        eventName,
        "QmEventDescription123", // event_description_hash
        "QmEventPoster456",     // event_poster_image_hash
        now + 86400 * 30,      // event_start_time (30天后)
        now + 86400 * 30 + 7200, // event_end_time (活动2小时)
        now + 86400,           // ticket_sale_start_time (1天后开始售票)
        now + 86400 * 29,      // ticket_sale_end_time (活动前1天停售)
        null,                  // seat_map_hash
        "音乐会",              // event_category
        "QmPerformer789",      // performer_details_hash
        "QmContact101",        // contact_info_hash
        "QmRefund202",         // refund_policy_hash
        { fixedPrice: {} }     // pricing_strategy_type
      )
      .accounts({
        event: eventPda,
        earnings: earningsPda,
        platform: platformPda,
        venue: venueAccount.publicKey,
        organizer: organizer.publicKey,
        systemProgram: anchor.web3.SystemProgram.programId,
      })
      .rpc();

    // 验证活动创建成功
    const event = await program.account.eventAccount.fetch(eventPda);
    expect(event.eventName).to.equal(eventName);
    expect(event.venueAccount.toString()).to.equal(venueAccount.publicKey.toString());
    expect(event.organizer.toString()).to.equal(organizer.publicKey.toString());
    
    console.log("✅ 活动成功关联场馆");
    console.log(`   活动名称: ${event.eventName}`);
    console.log(`   关联场馆: ${event.venueAccount.toString()}`);
  });

  it("通过场馆获取活动信息", async () => {
    // 获取活动信息
    const event = await program.account.eventAccount.fetch(eventPda);
    
    // 获取关联的场馆信息
    const venue = await program.account.venueAccount.fetch(event.venueAccount);
    
    console.log("✅ 成功通过活动获取场馆信息");
    console.log(`   活动名称: ${event.eventName}`);
    console.log(`   场馆名称: ${venue.venueName}`);
    console.log(`   场馆地址: ${venue.venueAddress}`);
    console.log(`   场馆容量: ${venue.totalCapacity}`);
    
    // 验证数据一致性
    expect(venue.venueName).to.equal("测试场馆");
    expect(venue.totalCapacity).to.equal(1000);
  });

  it("更新活动信息（不包括场馆）", async () => {
    await program.methods
      .updateEvent(
        "QmNewDescription456", // new_event_description_hash
        null,                  // new_event_poster_image_hash
        "QmNewSeatMap789",     // new_seat_map_hash
        null,                  // new_performer_details_hash
        null,                  // new_contact_info_hash
        null                   // new_refund_policy_hash
      )
      .accounts({
        event: eventPda,
        organizer: organizer.publicKey,
      })
      .rpc();

    // 验证更新成功
    const event = await program.account.eventAccount.fetch(eventPda);
    expect(event.eventDescriptionHash).to.equal("QmNewDescription456");
    expect(event.seatMapHash).to.equal("QmNewSeatMap789");
    
    console.log("✅ 活动信息更新成功");
  });
});
