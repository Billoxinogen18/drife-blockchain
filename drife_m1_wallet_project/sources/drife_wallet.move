module drife_m1_wallet_pkg::drife_wallet {
    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::package::{Self, UpgradeCap, UpgradeTicket, UpgradeReceipt};
    use sui::event;
    use sui::clock::Clock;
    use sui::table::{Self, Table};

    use drife_m1_wallet_pkg::drife_wallet_logic_v1 as logic_v1;

    public struct WalletAdminCap has key, store {
        id: UID
    }

    public struct WalletState has key {
        id: UID,
        version: u64,
        logic_id: ID,
        user_wallets: Table<vector<u8>, logic_v1::WalletInfoV1>,
        sui_address_registry: Table<address, bool>,
        used_nonces: Table<u64, bool>
    }

    public struct LogicUpgraded has copy, drop {
        old_version: u64,
        new_version: u64,
        new_logic_id: ID
    }

    const E_INVALID_BATCH_SIZE: u64 = 2;
    const MAX_BATCH_SIZE: u64 = 50;

    fun init(ctx: &mut TxContext) {
        transfer::public_transfer(WalletAdminCap { id: object::new(ctx) }, ctx.sender());

        let wallet_state = WalletState {
            id: object::new(ctx),
            version: 1,
            logic_id: object::id_from_address(@drife_m1_wallet_pkg),
            user_wallets: table::new(ctx),
            sui_address_registry: table::new(ctx),
            used_nonces: table::new(ctx)
        };
        transfer::public_share_object(wallet_state);
    }

    public entry fun register_wallet(
        admin_cap: &WalletAdminCap,
        state: &mut WalletState,
        user_id: vector<u8>,
        sui_address: address,
        role: vector<u8>,
        nonce: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        logic_v1::register_wallet(admin_cap, state, user_id, sui_address, role, nonce, clock, ctx);
    }

    public entry fun batch_register_wallets(
        admin_cap: &WalletAdminCap,
        state: &mut WalletState,
        user_ids: vector<vector<u8>>,
        sui_addresses: vector<address>,
        roles: vector<vector<u8>>,
        nonce: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(user_ids.length() <= MAX_BATCH_SIZE, E_INVALID_BATCH_SIZE);
        logic_v1::batch_register_wallets(admin_cap, state, user_ids, sui_addresses, roles, nonce, clock, ctx);
    }

    public entry fun authorize_upgrade(
        cap: &mut UpgradeCap,
        policy: u8,
        digest: vector<u8>
    ): UpgradeTicket {
        package::authorize_upgrade(cap, policy, digest)
    }

    public entry fun commit_upgrade(
        state: &mut WalletState,
        cap: &mut UpgradeCap,
        receipt: UpgradeReceipt
    ) {
        let new_package_id = package::receipt_package(&receipt);
        package::commit_upgrade(cap, receipt);

        state.version = state.version + 1;
        state.logic_id = new_package_id;

        event::emit(LogicUpgraded {
            old_version: state.version - 1,
            new_version: state.version,
            new_logic_id: new_package_id,
        });
    }
}
