module token_fixed::david_token {
    use std::signer;
    use std::string;
    use aptos_framework::coin;

    const ENOT_ADMIN: u64 = 0;
    const E_ALREADY_HAS_CAPABILITY: u64 = 1;
    const E_DONT_HAVE_CAPABILITY: u64 = 2;
    const SUPPLY: u64 = 10000000000000000;

    struct DavidToken has key {}

    struct CoinCapabilities has key {
        burn_cap: coin::BurnCapability<DavidToken>,
        freeze_cap: coin::FreezeCapability<DavidToken>,
        mint_cap: coin::MintCapability<DavidToken>
    }

    public fun is_admin(addr: address) {
        assert!(addr == @admin, ENOT_ADMIN)
    }


    public entry fun mint(account: &signer, user: address, amount: u64) acquires CoinCapabilities {
        let account_addr = signer::address_of(account);

        is_admin(account_addr);
        have_coin_capabilities(account_addr);

        let mint_cap = &borrow_global<CoinCapabilities>(account_addr).mint_cap;
        let coins = coin::mint<DavidToken>(amount, mint_cap);
        coin::deposit<DavidToken>(user, coins);
    }

    public fun have_coin_capabilities(addr: address) {
        assert!(exists<CoinCapabilities>(addr), E_DONT_HAVE_CAPABILITY)
    }

    public fun not_have_coin_capabilities(addr: address) {
        assert!(!exists<CoinCapabilities>(addr), E_ALREADY_HAS_CAPABILITY);
    }

    fun init_module(account: &signer) {
        let account_addr = signer::address_of(account);
        is_admin(account_addr);
        not_have_coin_capabilities(account_addr);

        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<DavidToken>(
            account,
            string::utf8(b"David Token"),
            string::utf8(b"DTK"),
            18,
            true
        );

        coin::register<DavidToken>(account);
        let coins = coin::mint<DavidToken>(SUPPLY, &mint_cap);
        coin::deposit<DavidToken>(account_addr, coins);
        coin::destroy_mint_cap<DavidToken>(mint_cap);
        move_to(account, CoinCapabilities {burn_cap, freeze_cap, mint_cap});
    }

    public entry fun register(account: &signer) {
        coin::register<DavidToken>(account);
    }

     public entry fun burn(account: &signer, amount: u64) acquires CoinCapabilities {
        // Withdraw from the user.
        let coins = coin::withdraw<DavidToken>(account, amount);
        let burn_cap = &borrow_global<CoinCapabilities>(@admin).burn_cap; 
        coin::burn<DavidToken>(coins, burn_cap);
    }

    public entry fun freeze_user(account: &signer, user: address) acquires CoinCapabilities {
        let account_addr = signer::address_of(account);
        is_admin(account_addr);
        have_coin_capabilities(account_addr);

        let freeze_cap = &borrow_global<CoinCapabilities>(@admin).freeze_cap; 
        coin::freeze_coin_store<DavidToken>(user, freeze_cap);
    }

    public entry fun unfreeze_user(account: &signer, user: address) acquires CoinCapabilities {
        let account_addr = signer::address_of(account);
        is_admin(account_addr);
        have_coin_capabilities(account_addr);

        let freeze_cap = &borrow_global<CoinCapabilities>(@admin).freeze_cap; 
        coin::unfreeze_coin_store<DavidToken>(user, freeze_cap);
    }
}