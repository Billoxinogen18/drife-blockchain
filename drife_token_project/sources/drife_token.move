// Module for the DRF Fungible Token  
module drife_token_pkg::drife_token {
    use sui::coin;
    use sui::transfer::public_transfer;
    use sui::tx_context::{sender};
    use std::option;
    use sui::url::Url;
    
    /// One-time witness struct - must be uppercase of module name "drife_token" = "DRIFE_TOKEN"
    public struct DRIFE_TOKEN has drop {}
    
    fun init(witness: DRIFE_TOKEN, ctx: &mut sui::tx_context::TxContext) {
        let (treasury_cap, metadata) = coin::create_currency<DRIFE_TOKEN>(
            witness,
            6,
            b"DRF",
            b"Drife Token", 
            b"Drife Ecosystem Token",
            option::none<Url>(),
            ctx
        );
        
        public_transfer(treasury_cap, sender(ctx));
        public_transfer(metadata, sender(ctx));
    }
}