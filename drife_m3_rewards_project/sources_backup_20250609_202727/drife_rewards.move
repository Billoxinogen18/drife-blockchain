module drife_m3_rewards_pkg::drife_rewards {
    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, UID};
    use sui::transfer::{Self, transfer, public_transfer};
    use sui::clock::{Self, Clock};
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::event;
    use std::vector;
    
    use drife_token_pkg::drife_token::DRIFE_TOKEN;

    public struct RewardsAdminCap has key, store { id: UID }

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
    const E_BATCH_LENGTH_MISMATCH: u64 = 203;
    const E_BATCH_SIZE_LIMIT_EXCEEDED: u64 = 205;
    const MAX_BATCH_SIZE: u64 = 50;

    fun init(ctx: &mut TxContext) {
        transfer(RewardsAdminCap { id: object::new(ctx) }, ctx.sender());
    }

    public entry fun distribute_single_reward(
        _admin_cap: &RewardsAdminCap,
        drf_treasury_cap: &mut TreasuryCap<DRIFE_TOKEN>,
        user_wallet: address,
        amount: u64,
        campaign_id: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(amount > 0, E_REWARD_AMOUNT_MUST_BE_POSITIVE);
        let drf_coins: Coin<DRIFE_TOKEN> = coin::mint(drf_treasury_cap, amount, ctx);
        public_transfer(drf_coins, user_wallet);
        event::emit(RewardDistributed {
            user_wallet,
            amount,
            campaign_id,
            distribution_timestamp: clock.timestamp_ms()
        });
    }

    public entry fun batch_distribute_rewards_simple(
        _admin_cap: &RewardsAdminCap,
        drf_treasury_cap: &mut TreasuryCap<DRIFE_TOKEN>,
        user_wallets: vector<address>,
        amounts: vector<u64>,
        campaign_ids: vector<vector<u8>>,
        batch_id: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let len = vector::length(&user_wallets);
        assert!(len > 0, E_BATCH_LIST_EMPTY);
        assert!(len <= MAX_BATCH_SIZE, E_BATCH_SIZE_LIMIT_EXCEEDED);
        assert!(len == vector::length(&amounts), E_BATCH_LENGTH_MISMATCH);
        assert!(len == vector::length(&campaign_ids), E_BATCH_LENGTH_MISMATCH);
        
        let mut total_distributed_for_batch = 0u64;
        let mut i = 0;
        
        while (i < len) {
            let amount = *vector::borrow(&amounts, i);
            if (amount > 0) {
                let user_wallet = *vector::borrow(&user_wallets, i);
                let campaign_id = *vector::borrow(&campaign_ids, i);
                
                let drf_coins: Coin<DRIFE_TOKEN> = coin::mint(drf_treasury_cap, amount, ctx);
                public_transfer(drf_coins, user_wallet);

                total_distributed_for_batch = total_distributed_for_batch + amount;

                event::emit(RewardDistributed {
                    user_wallet,
                    amount,
                    campaign_id,
                    distribution_timestamp: clock.timestamp_ms()
                });
            };
            i = i + 1;
        };

        if (total_distributed_for_batch > 0) {
            event::emit(BatchRewardDistributed {
                batch_id,
                user_count: len,
                total_amount_distributed: total_distributed_for_batch,
                distribution_timestamp: clock.timestamp_ms()
            });
        }
    }
}
