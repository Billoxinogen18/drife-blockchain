module drife_m1_wallet_pkg::drife_wallet_logic_v1 {
    friend drife_m1_wallet_pkg::drife_wallet;

    use sui::tx_context::{Self, TxContext};
    use sui::clock::{Self, Clock};
    use sui::table::{Self, Table, add as table_add, contains as table_contains};
    use std::vector;

    use drife_m1_wallet_pkg::drife_wallet::{WalletAdminCap, WalletState};

    public struct WalletInfoV1 has store {
        user_id_onchain: vector<u8>,
        sui_address: address,
        role: vector<u8>,
        creation_timestamp: u64
    }

    const E_WALLET_ALREADY_EXISTS_FOR_USER_ID: u64 = 101;
    const E_SUI_ADDRESS_ALREADY_REGISTERED: u64 = 102;
    const E_NONCE_ALREADY_USED: u64 = 103;
    const E_BATCH_LENGTH_MISMATCH: u64 = 104;

    fun internal_create_wallet(
        state: &mut WalletState,
        user_id: vector<u8>,
        sui_address: address,
        role: vector<u8>,
        clock: &Clock,
    ) {
        assert!(!table_contains(&state.user_wallets, user_id), E_WALLET_ALREADY_EXISTS_FOR_USER_ID);
        assert!(!table_contains(&state.sui_address_registry, sui_address), E_SUI_ADDRESS_ALREADY_REGISTERED);

        let wallet_info = WalletInfoV1 {
            user_id_onchain: user_id,
            sui_address: sui_address,
            role: role,
            creation_timestamp: clock.timestamp_ms()
        };

        table_add(&mut state.user_wallets, user_id, wallet_info);
        table_add(&mut state.sui_address_registry, sui_address, true);
    }

    public(friend) fun register_wallet(
        _admin_cap: &WalletAdminCap,
        state: &mut WalletState,
        user_id: vector<u8>,
        sui_address: address,
        role: vector<u8>,
        nonce: u64,
        clock: &Clock,
        _ctx: &mut TxContext,
    ) {
        assert!(!table_contains(&state.used_nonces, nonce), E_NONCE_ALREADY_USED);
        table_add(&mut state.used_nonces, nonce, true);

        internal_create_wallet(state, user_id, sui_address, role, clock);
    }

    public(friend) fun batch_register_wallets(
        _admin_cap: &WalletAdminCap,
        state: &mut WalletState,
        user_ids: vector<vector<u8>>,
        sui_addresses: vector<address>,
        roles: vector<vector<u8>>,
        nonce: u64,
        clock: &Clock,
        _ctx: &mut TxContext,
    ) {
        assert!(!table_contains(&state.used_nonces, nonce), E_NONCE_ALREADY_USED);
        table_add(&mut state.used_nonces, nonce, true);

        let len_users = vector::length(&user_ids);
        assert!(len_users == vector::length(&sui_addresses), E_BATCH_LENGTH_MISMATCH);
        assert!(len_users == vector::length(&roles), E_BATCH_LENGTH_MISMATCH);

        let mut i = 0;
        while (i < len_users) {
            internal_create_wallet(
                state,
                *vector::borrow(&user_ids, i),
                *vector::borrow(&sui_addresses, i),
                *vector::borrow(&roles, i),
                clock
            );
            i = i + 1;
        };
    }
}
