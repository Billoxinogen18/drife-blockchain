/// ====================================================================================
/// DRIFE :: M2 :: State Module (v3.6 FINAL & VERIFIED)
///
/// This module defines all data structures, events, and provides a complete public
/// API for other modules to interact with the state in a safe, controlled manner.
/// All fields are private; access is only granted via this module's public functions.
/// ====================================================================================
module drife_m2_ride_sync_pkg::state {
    use sui::object::{UID, new};
    use sui::table::{Self, Table, length, contains, add, remove, borrow, borrow_mut};
    use sui::tx_context::{TxContext, sender};
    use sui::transfer::{public_share_object, transfer};
    use sui::event;
    use std::option::{Option, none, some};
    use std::vector;

    // --- Ride Status ---
    const STATUS_REQUESTED: u8 = 0;
    const STATUS_MATCHED: u8 = 1;
    const STATUS_COMPLETED: u8 = 2;
    const STATUS_CANCELLED: u8 = 3;

    // ======== Struct Definitions ========
    public struct RideSyncAdminCap has key, store { id: UID }
    public struct RideInfo has store, copy, drop {
        ride_id: vector<u8>,
        rider_wallet: address,
        driver_wallet: Option<address>,
        fare: u64,
        status: u8,
        requested_timestamp_ms: u64,
        last_updated_timestamp_ms: u64,
    }
    public struct DailyStat has store, copy, drop {
        date_yyyymmdd: u32,
        requests: u64,
        matches: u64,
        completions: u64,
    }
    public struct RideStats has store {
        total_requests: u64,
        total_matches: u64,
        total_completions: u64,
        unique_riders: Table<address, bool>,
        daily_stats: Table<u32, DailyStat>,
    }
    public struct RoleManager has key, store {
        id: UID,
        admins: Table<address, bool>,
        riders: Table<address, bool>,
        drivers: Table<address, bool>,
        writers: Table<address, bool>,
    }
    public struct RideSyncState has key, store {
        id: UID,
        is_paused: bool,
        rides: Table<vector<u8>, RideInfo>,
        all_ride_ids: vector<vector<u8>>,
        stats: RideStats,
    }

    // ======== Event Definitions ========
    public struct ContractPaused has copy, drop { is_paused: bool }
    public struct AdminActionLog has copy, drop { admin_address: address, action: vector<u8>, affected_address: address, role: vector<u8> }
    public struct RideStatusChanged has copy, drop { ride_info: RideInfo }
    public struct FullRideEmittedForIndexer has copy, drop { ride_info: RideInfo }

    // ======== INITIALIZATION ========
    public fun init_for_deployment(ctx: &mut TxContext) {
        let deployer = sender(ctx);
        transfer(RideSyncAdminCap { id: new(ctx) }, deployer);
        let mut admins = table::new(ctx);
        add(&mut admins, deployer, true);
        public_share_object(RoleManager {
            id: new(ctx), admins,
            riders: table::new(ctx), drivers: table::new(ctx), writers: table::new(ctx),
        });
        public_share_object(RideSyncState {
            id: new(ctx), is_paused: false,
            rides: table::new(ctx), all_ride_ids: vector::empty(),
            stats: RideStats {
                total_requests: 0, total_matches: 0, total_completions: 0,
                unique_riders: table::new(ctx), daily_stats: table::new(ctx),
            },
        });
    }

    // ======== PUBLIC GETTERS ========
    public fun is_paused(state: &RideSyncState): bool { state.is_paused }
    public fun ride_exists(state: &RideSyncState, ride_id: &vector<u8>): bool { contains(&state.rides, *ride_id) }
    public fun ride_info(state: &RideSyncState, ride_id: &vector<u8>): RideInfo { *borrow(&state.rides, *ride_id) }
    public fun ride_info_status(info: &RideInfo): u8 { info.status }
    public fun ride_info_rider_wallet(info: &RideInfo): address { info.rider_wallet }
    public fun all_ride_ids(state: &RideSyncState): &vector<vector<u8>> { &state.all_ride_ids }
    public fun total_stats(state: &RideSyncState): (u64, u64, u64) { (state.stats.total_requests, state.stats.total_matches, state.stats.total_completions) }
    public fun unique_rider_count(state: &RideSyncState): u64 { length(&state.stats.unique_riders) }
    public fun daily_stats(state: &RideSyncState, date: u32): Option<DailyStat> { if (contains(&state.stats.daily_stats, date)) { some(*borrow(&state.stats.daily_stats, date)) } else { none() }}
    public fun has_role(roles: &RoleManager, user: address, role: &vector<u8>): bool {
        if (*role == b"Admin") { contains(&roles.admins, user) }
        else if (*role == b"Rider") { contains(&roles.riders, user) }
        else if (*role == b"Driver") { contains(&roles.drivers, user) }
        else if (*role == b"Writer") { contains(&roles.writers, user) }
        else { false }
    }
    public fun admin_count(roles: &RoleManager): u64 { length(&roles.admins) }

    // ======== PUBLIC MUTATORS ========
    public fun set_paused(state: &mut RideSyncState, paused_status: bool) {
        state.is_paused = paused_status;
        event::emit(ContractPaused { is_paused: paused_status });
    }
    public fun manage_role(roles: &mut RoleManager, user: address, role: &vector<u8>, assign: bool, admin_addr: address) {
        let action = if (assign) {
            if (*role == b"Admin") { if (!contains(&roles.admins, user)) { add(&mut roles.admins, user, true); }}
            else if (*role == b"Rider") { if (!contains(&roles.riders, user)) { add(&mut roles.riders, user, true); }}
            else if (*role == b"Driver") { if (!contains(&roles.drivers, user)) { add(&mut roles.drivers, user, true); }}
            else if (*role == b"Writer") { if (!contains(&roles.writers, user)) { add(&mut roles.writers, user, true); }};
            b"ASSIGN_ROLE"
        } else {
            if (*role == b"Admin") { if (contains(&roles.admins, user)) { remove(&mut roles.admins, user); }}
            else if (*role == b"Rider") { if (contains(&roles.riders, user)) { remove(&mut roles.riders, user); }}
            else if (*role == b"Driver") { if (contains(&roles.drivers, user)) { remove(&mut roles.drivers, user); }}
            else if (*role == b"Writer") { if (contains(&roles.writers, user)) { remove(&mut roles.writers, user); }};
            b"REVOKE_ROLE"
        };
        event::emit(AdminActionLog { admin_address: admin_addr, action, affected_address: user, role: *role });
    }
    public fun add_new_ride(state: &mut RideSyncState, ride_id: vector<u8>, fare: u64, rider_addr: address, timestamp: u64): RideInfo {
        let ride_info = RideInfo {
            ride_id, rider_wallet: rider_addr, driver_wallet: none(), fare, status: STATUS_REQUESTED,
            requested_timestamp_ms: timestamp, last_updated_timestamp_ms: timestamp,
        };
        add(&mut state.rides, ride_id, ride_info);
        vector::push_back(&mut state.all_ride_ids, ride_id);
        event::emit(RideStatusChanged { ride_info });
        ride_info
    }
    public fun assign_driver_to_ride(state: &mut RideSyncState, ride_id: &vector<u8>, driver_wallet: address, timestamp: u64): RideInfo {
        let ride = borrow_mut(&mut state.rides, *ride_id);
        ride.driver_wallet = some(driver_wallet);
        ride.status = STATUS_MATCHED;
        ride.last_updated_timestamp_ms = timestamp;
        event::emit(RideStatusChanged { ride_info: *ride });
        *ride
    }
    public fun complete_ride_status(state: &mut RideSyncState, ride_id: &vector<u8>, timestamp: u64): RideInfo {
        let ride = borrow_mut(&mut state.rides, *ride_id);
        ride.status = STATUS_COMPLETED;
        ride.last_updated_timestamp_ms = timestamp;
        event::emit(RideStatusChanged { ride_info: *ride });
        *ride
    }
    public fun cancel_ride_status(state: &mut RideSyncState, ride_id: &vector<u8>, timestamp: u64): RideInfo {
        let ride = borrow_mut(&mut state.rides, *ride_id);
        ride.status = STATUS_CANCELLED;
        ride.last_updated_timestamp_ms = timestamp;
        event::emit(RideStatusChanged { ride_info: *ride });
        *ride
    }
    public fun remove_archived_ride(state: &mut RideSyncState, ride_id: vector<u8>) {
        let _old_ride: RideInfo = remove(&mut state.rides, ride_id);
        let (found, index) = vector::index_of(&state.all_ride_ids, &ride_id);
        if (found) { vector::remove(&mut state.all_ride_ids, index); };
    }
    public fun update_stats(state: &mut RideSyncState, rider_wallet: address, status: u8, date_yyyymmdd: u32) {
        let stats = &mut state.stats;
        if (status == STATUS_REQUESTED) {
            stats.total_requests = stats.total_requests + 1;
            if (!contains(&stats.unique_riders, rider_wallet)) { add(&mut stats.unique_riders, rider_wallet, true); }
        } else if (status == STATUS_MATCHED) {
            stats.total_matches = stats.total_matches + 1;
        } else if (status == STATUS_COMPLETED) {
            stats.total_completions = stats.total_completions + 1;
        };
        let daily = if (contains(&stats.daily_stats, date_yyyymmdd)) {
            borrow_mut(&mut stats.daily_stats, date_yyyymmdd)
        } else {
            add(&mut stats.daily_stats, date_yyyymmdd, DailyStat { date_yyyymmdd, requests: 0, matches: 0, completions: 0 });
            borrow_mut(&mut stats.daily_stats, date_yyyymmdd)
        };
        if (status == STATUS_REQUESTED) { daily.requests = daily.requests + 1; }
        else if (status == STATUS_MATCHED) { daily.matches = daily.matches + 1; }
        else if (status == STATUS_COMPLETED) { daily.completions = daily.completions + 1; };
    }
    public fun emit_full_ride_for_indexer(ride_info: RideInfo) { event::emit(FullRideEmittedForIndexer { ride_info }); }
}
