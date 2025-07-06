// Module for DRIFE DRF Token Reward Distribution
module drife_m3_rewards_pkg::drife_rewards {
    // Corrected 'use' statements
    use sui::tx_context::{Self, TxContext, epoch_timestamp_ms, sender};
    use sui::object::{Self, UID, new as new_object}; // Import 'new' explicitly
    use sui::transfer::{transfer, public_transfer};
    use sui::event;
    use std::vector::{length as vec_length, borrow as vec_borrow}; // Import specific functions

    // Import DRIFE_TOKEN using the named address from Move.toml
    // The named address 'drife_token_pkg' in Move.toml should point to
    // 0x81e79edb3143aa47525e84b053e337d2d798ff54f480009b09c4164993b19df1
    use drife_token_pkg::drife_token::{DRIFE_TOKEN};

    // Import Coin, TreasuryCap from sui::coin. 'mint' is also directly available.
    use sui::coin::{Coin, TreasuryCap, mint};

    // Assuming 'edition = "2024.beta"' is set in Move.toml, 'public struct' is correct.
    public struct RewardsAdminCap has key {
        id: UID
    }

    public struct RewardMeta has copy, drop, store {
        user_wallet: address,
        amount: u64,
        campaign_id: vector<u8>
    }

    public struct RewardDistributed has copy, drop {
        user_wallet: address,
        amount: u64,
        campaign_id: vector<u8>,
        distribution_timestamp: u64
    }

    public struct BatchRewardDistributed has copy, drop {
        batch_id: vector<u8>,
        user_count: u64,
        total_amount_distributed: u64,
        distribution_timestamp: u64
    }

    const E_REWARD_AMOUNT_MUST_BE_POSITIVE: u64 = 201;
    const E_BATCH_LIST_EMPTY: u64 = 202;
    // Add if you make a _simple entry function for batch rewards
    // const E_BATCH_LENGTH_MISMATCH_REWARDS: u64 = 203;

    fun init(ctx: &mut TxContext) {
        let admin_cap = RewardsAdminCap {
            id: new_object(ctx) // Use the aliased 'new_object' or 'object::new'
        };
        transfer(admin_cap, sender(ctx));
    }

    public entry fun distribute_reward(
        _admin_cap: &RewardsAdminCap,
        drf_treasury_cap: &mut TreasuryCap<DRIFE_TOKEN>, // DRIFE_TOKEN type should be resolved now
        user_wallet: address,
        amount: u64,
        campaign_id: vector<u8>,
        ctx: &mut TxContext
    ) {
        assert!(amount > 0, E_REWARD_AMOUNT_MUST_BE_POSITIVE);

        let drf_coins: Coin<DRIFE_TOKEN> = mint(drf_treasury_cap, amount, ctx); // Use 'mint' directly
        public_transfer(drf_coins, user_wallet);

        event::emit(RewardDistributed {
            user_wallet,
            amount,
            campaign_id,
            distribution_timestamp: epoch_timestamp_ms(ctx)
        });
    }

    // This function is NOT an 'entry' function because vector<RewardMeta> is not a valid entry param.
    // It can be called by other Move functions in this package or by friend modules.
    // For an 'entry' version, you'd need a 'batch_distribute_rewards_simple' like in Milestone 1.
    public fun batch_distribute_rewards(
        _admin_cap: &RewardsAdminCap,
        drf_treasury_cap: &mut TreasuryCap<DRIFE_TOKEN>,
        rewards_list: vector<RewardMeta>,
        batch_id: vector<u8>,
        ctx: &mut TxContext
    ) {
        let mut i = 0; // 'mut' is correct
        let len = vec_length(&rewards_list);
        assert!(len > 0, E_BATCH_LIST_EMPTY);

        let mut total_distributed_for_batch = 0u64; // 'mut' is correct
        let mut users_rewarded_in_batch = 0u64; // 'mut' is correct

        while (i < len) {
            let meta = vec_borrow(&rewards_list, i);
            if (meta.amount > 0) {
                let drf_coins: Coin<DRIFE_TOKEN> = mint(drf_treasury_cap, meta.amount, ctx);
                public_transfer(drf_coins, meta.user_wallet);

                total_distributed_for_batch = total_distributed_for_batch + meta.amount;
                users_rewarded_in_batch = users_rewarded_in_batch + 1;

                event::emit(RewardDistributed {
                    user_wallet: meta.user_wallet,
                    amount: meta.amount,
                    campaign_id: meta.campaign_id,
                    distribution_timestamp: epoch_timestamp_ms(ctx)
                });
            };
            i = i + 1;
        }; // Semicolon here after while loop

        if (users_rewarded_in_batch > 0) {
            event::emit(BatchRewardDistributed {
                batch_id,
                user_count: users_rewarded_in_batch,
                total_amount_distributed: total_distributed_for_batch,
                distribution_timestamp: epoch_timestamp_ms(ctx)
            });
        }
    }

    // You might want an entry function for batch distribution that takes primitive vectors
    // if you need to call batch distribution directly from client.
    // For now, this module only has an entry function for single reward distribution.
    // The 'distribute_single_reward' in your snippet is just an alias to 'distribute_reward'.
    // It can be kept if you want that specific name for an entry point.
    public entry fun distribute_single_reward(
        _admin_cap: &RewardsAdminCap,
        drf_treasury_cap: &mut TreasuryCap<DRIFE_TOKEN>,
        user_wallet: address,
        amount: u64,
        campaign_id: vector<u8>,
        ctx: &mut TxContext
    ) {
        distribute_reward(_admin_cap, drf_treasury_cap, user_wallet, amount, campaign_id, ctx);
    }
}