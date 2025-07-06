/// ====================================================================================
/// DRIFE :: M2 :: Logic Module (v3.6 FINAL & VERIFIED)
///
/// This module contains the core business logic, acting as a controller that calls
/// the public API of the `state` module to perform actions.
/// ====================================================================================
module drife_m2_ride_sync_pkg::drife_ride_sync {
    use sui::tx_context::{Self, TxContext, sender};
    use sui::clock::{Self, Clock, timestamp_ms};
    use std::vector;
    use std::option::Option;

    use drife_m2_ride_sync_pkg::state::{
        Self as state,
        RideInfo, DailyStat, RoleManager, RideSyncState
    };

    const ROLE_ADMIN: vector<u8> = b"Admin";
    const ROLE_RIDER: vector<u8> = b"Rider";
    const ROLE_DRIVER: vector<u8> = b"Driver";
    const ROLE_WRITER: vector<u8> = b"Writer";
    const STATUS_REQUESTED: u8 = 0;
    const STATUS_MATCHED: u8 = 1;
    const STATUS_COMPLETED: u8 = 2;
    const STATUS_CANCELLED: u8 = 3;
    const E_CONTRACT_PAUSED: u64 = 100;
    const E_PERMISSION_DENIED: u64 = 101;
    const E_RIDE_ALREADY_EXISTS: u64 = 102;
    const E_RIDE_NOT_FOUND: u64 = 103;
    const E_INVALID_STATE_FOR_ACTION: u64 = 104;
    const E_FARE_MUST_BE_POSITIVE: u64 = 105;
    const E_INVALID_ROLE: u64 = 106;
    const E_CANNOT_REVOKE_FINAL_ADMIN: u64 = 107;
    const E_CANNOT_ARCHIVE_ACTIVE_RIDE: u64 = 108;

    fun init(ctx: &mut TxContext) { state::init_for_deployment(ctx); }

    public entry fun pause(state: &mut RideSyncState, roles: &RoleManager, ctx: &TxContext) {
        assert_has_role(roles, sender(ctx), &ROLE_ADMIN);
        state::set_paused(state, true);
    }
    public entry fun unpause(state: &mut RideSyncState, roles: &RoleManager, ctx: &TxContext) {
        assert_has_role(roles, sender(ctx), &ROLE_ADMIN);
        state::set_paused(state, false);
    }
    public entry fun assign_role(roles: &mut RoleManager, user: address, role: vector<u8>, ctx: &TxContext) {
        let admin_addr = sender(ctx);
        assert_has_role(roles, admin_addr, &ROLE_ADMIN);
        assert!(is_valid_role(&role), E_INVALID_ROLE);
        state::manage_role(roles, user, &role, true, admin_addr);
    }
    public entry fun revoke_role(roles: &mut RoleManager, user: address, role: vector<u8>, ctx: &TxContext) {
        let admin_addr = sender(ctx);
        assert_has_role(roles, admin_addr, &ROLE_ADMIN);
        assert!(is_valid_role(&role), E_INVALID_ROLE);
        if (role == ROLE_ADMIN) {
            assert!(state::admin_count(roles) > 1 || user != admin_addr, E_CANNOT_REVOKE_FINAL_ADMIN);
        };
        state::manage_role(roles, user, &role, false, admin_addr);
    }
    public entry fun request_ride(state: &mut RideSyncState, roles: &RoleManager, ride_id: vector<u8>, fare: u64, date_yyyymmdd: u32, clock: &Clock, ctx: &TxContext) {
        assert!(!state::is_paused(state), E_CONTRACT_PAUSED);
        let rider_addr = sender(ctx);
        assert!(state::has_role(roles, rider_addr, &ROLE_RIDER) || state::has_role(roles, rider_addr, &ROLE_ADMIN), E_PERMISSION_DENIED);
        assert!(!state::ride_exists(state, &ride_id), E_RIDE_ALREADY_EXISTS);
        assert!(fare > 0, E_FARE_MUST_BE_POSITIVE);
        let ride_info = state::add_new_ride(state, ride_id, fare, rider_addr, timestamp_ms(clock));
        state::update_stats(state, rider_addr, STATUS_REQUESTED, date_yyyymmdd);
    }
    public entry fun match_driver(state: &mut RideSyncState, roles: &RoleManager, ride_id: vector<u8>, driver_wallet: address, date_yyyymmdd: u32, clock: &Clock, ctx: &TxContext) {
        assert!(!state::is_paused(state), E_CONTRACT_PAUSED);
        let caller_addr = sender(ctx);
        assert!(state::has_role(roles, caller_addr, &ROLE_DRIVER) || state::has_role(roles, caller_addr, &ROLE_WRITER) || state::has_role(roles, caller_addr, &ROLE_ADMIN), E_PERMISSION_DENIED);
        assert!(state::ride_exists(state, &ride_id), E_RIDE_NOT_FOUND);
        let ride_info = state::ride_info(state, &ride_id);
        assert!(state::ride_info_status(&ride_info) == STATUS_REQUESTED, E_INVALID_STATE_FOR_ACTION);
        let updated_ride = state::assign_driver_to_ride(state, &ride_id, driver_wallet, timestamp_ms(clock));
        let rider_addr = state::ride_info_rider_wallet(&updated_ride);
        state::update_stats(state, rider_addr, STATUS_MATCHED, date_yyyymmdd);
    }
    public entry fun complete_ride(state: &mut RideSyncState, roles: &RoleManager, ride_id: vector<u8>, date_yyyymmdd: u32, clock: &Clock, ctx: &TxContext) {
        assert!(!state::is_paused(state), E_CONTRACT_PAUSED);
        let caller_addr = sender(ctx);
        assert!(state::has_role(roles, caller_addr, &ROLE_RIDER) || state::has_role(roles, caller_addr, &ROLE_DRIVER) || state::has_role(roles, caller_addr, &ROLE_ADMIN), E_PERMISSION_DENIED);
        assert!(state::ride_exists(state, &ride_id), E_RIDE_NOT_FOUND);
        let ride_info = state::ride_info(state, &ride_id);
        assert!(state::ride_info_status(&ride_info) == STATUS_MATCHED, E_INVALID_STATE_FOR_ACTION);
        let updated_ride = state::complete_ride_status(state, &ride_id, timestamp_ms(clock));
        let rider_addr = state::ride_info_rider_wallet(&updated_ride);
        state::update_stats(state, rider_addr, STATUS_COMPLETED, date_yyyymmdd);
    }
    public entry fun cancel_ride(state: &mut RideSyncState, roles: &RoleManager, ride_id: vector<u8>, clock: &Clock, ctx: &TxContext) {
        assert!(!state::is_paused(state), E_CONTRACT_PAUSED);
        let caller_addr = sender(ctx);
        assert!(state::has_role(roles, caller_addr, &ROLE_RIDER) || state::has_role(roles, caller_addr, &ROLE_DRIVER) || state::has_role(roles, caller_addr, &ROLE_ADMIN), E_PERMISSION_DENIED);
        assert!(state::ride_exists(state, &ride_id), E_RIDE_NOT_FOUND);
        let ride_info = state::ride_info(state, &ride_id);
        let current_status = state::ride_info_status(&ride_info);
        assert!(current_status == STATUS_REQUESTED || current_status == STATUS_MATCHED, E_INVALID_STATE_FOR_ACTION);
        state::cancel_ride_status(state, &ride_id, timestamp_ms(clock));
    }
    public entry fun archive_ride(state: &mut RideSyncState, roles: &RoleManager, ride_id: vector<u8>, ctx: &TxContext) {
        assert_has_role(roles, sender(ctx), &ROLE_ADMIN);
        assert!(state::ride_exists(state, &ride_id), E_RIDE_NOT_FOUND);
        let ride_info = state::ride_info(state, &ride_id);
        let status = state::ride_info_status(&ride_info);
        assert!(status == STATUS_COMPLETED || status == STATUS_CANCELLED, E_CANNOT_ARCHIVE_ACTIVE_RIDE);
        state::remove_archived_ride(state, ride_id);
    }
    public entry fun emit_full_ride(state: &RideSyncState, ride_id: vector<u8>) {
        assert!(state::ride_exists(state, &ride_id), E_RIDE_NOT_FOUND);
        let ride_info = state::ride_info(state, &ride_id);
        state::emit_full_ride_for_indexer(ride_info);
    }

    fun assert_has_role(roles: &RoleManager, user: address, role: &vector<u8>) { assert!(state::has_role(roles, user, role), E_PERMISSION_DENIED); }
    fun is_valid_role(role: &vector<u8>): bool { *role == ROLE_ADMIN || *role == ROLE_RIDER || *role == ROLE_DRIVER || *role == ROLE_WRITER }
    public fun is_paused(state: &RideSyncState): bool { state::is_paused(state) }
    public fun get_ride_info(state: &RideSyncState, ride_id: vector<u8>): RideInfo { state::ride_info(state, &ride_id) }
    public fun get_all_ride_ids(state: &RideSyncState): vector<vector<u8>> { *state::all_ride_ids(state) }
    public fun get_rides_paginated(state: &RideSyncState, start: u64, limit: u64): vector<RideInfo> {
        let all_ids = state::all_ride_ids(state);
        let mut i = start;
        let len = vector::length(all_ids);
        let end = if (start + limit > len) { len } else { start + limit };
        let mut rides = vector::empty<RideInfo>();
        while (i < end) {
            let ride_id = vector::borrow(all_ids, i);
            vector::push_back(&mut rides, state::ride_info(state, ride_id));
            i = i + 1;
        };
        rides
    }
    public fun get_total_stats(state: &RideSyncState): (u64, u64, u64) { state::total_stats(state) }
    public fun get_unique_rider_count(state: &RideSyncState): u64 { state::unique_rider_count(state) }
    public fun get_daily_stats(state: &RideSyncState, date_yyyymmdd: u32): Option<DailyStat> { state::daily_stats(state, date_yyyymmdd) }
}
