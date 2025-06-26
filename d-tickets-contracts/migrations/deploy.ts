// Migrations are an early feature. Currently, they're nothing more than this
// single deploy script that's invoked from the CLI, injecting a provider
// configured from the workspace's Anchor.toml.

import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { DTickets } from "../target/types/d_tickets";

module.exports = async function (provider: anchor.AnchorProvider) {
  // Configure client to use the provider.
  anchor.setProvider(provider);

  const program = anchor.workspace.dTickets as Program<DTickets>;
  
  try {
    // 获取platform账户地址
    const [platformPda] = anchor.web3.PublicKey.findProgramAddressSync(
      [Buffer.from("platform")],
      program.programId
    );

    console.log("Platform PDA:", platformPda.toString());
    console.log("Admin:", provider.wallet.publicKey.toString());

    // 尝试初始化platform（如果还没有初始化的话）
    const tx = await program.methods
      .setupPlatform(
        250, // 2.5% platform fee
        null, // 使用默认fee_recipient
        false // 不暂停
      )
      .accounts({
        platform: platformPda,
        admin: provider.wallet.publicKey,
        feeRecipient: null,
        systemProgram: anchor.web3.SystemProgram.programId,
      })
      .rpc();

    console.log("Platform setup transaction signature:", tx);
    console.log("Platform initialized/updated successfully!");
    
  } catch (error) {
    console.log("Platform setup error:", error);
    // 如果已经初始化，这是正常的
    if (error.message.includes("already in use")) {
      console.log("Platform already initialized - this is normal");
    }
  }
};
