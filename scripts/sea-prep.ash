// Sea Prep: optional UnderTheSea branch. Independent ASH entrypoint; no legacy imports required.
// Build: 2026-10-28 wallet-finisher v1 (sushi mat, confirmed turn/PvP spending).
// Default: prepare aftercore and ask before end-of-day organ/turn/PvP spending.
// "check" audits without spending/using items.
// Preferences used as optional switches are documented in don_preAscention_README.md.

void don_note(string msg) { print("[Sea Prep] " + msg, "blue"); }
void don_warn(string msg) { print("[Sea Prep WARNING] " + msg, "red"); }

boolean don_flag(string key, boolean default_value) {
    string value = get_property(key);
    if (value == "") return default_value;
    return to_boolean(value);
}

boolean don_aftercore() { return to_boolean(get_property("kingLiberated")); }

void don_borrowed_time(boolean may_act) {
    boolean used = to_boolean(get_property("_borrowedTimeUsed"));
    if (!used && may_act && don_flag("don_preAscUseBorrowedTime", false)) {
        if (item_amount($item[borrowed time]) > 0) {
            don_note("Using owned Borrowed Time before ascending.");
            if (!use(1, $item[borrowed time])) don_warn("Borrowed Time use failed.");
        } else {
            don_warn("Borrowed Time not in inventory; auto-purchase is disabled.");
        }
        used = to_boolean(get_property("_borrowedTimeUsed"));
    }
    // Independent daily observation: never overwrite KoLmafia's authoritative flag.
    if (may_act) set_property("_donPreAscBorrowedTimeObserved", used.to_string());
    if (used) don_note("Borrowed Time: USED today (_borrowedTimeUsed=true).");
    else don_warn("Borrowed Time has NOT been used today (_borrowedTimeUsed=false).");
}

void don_spend_warnings() {
    // item_amount is REAL inventory, not storage, closet, or a stale shop balance.
    int coins = item_amount($item[interesting coin]);
    don_note("Interesting Coins in inventory: " + coins);
    if (coins > 0)
        don_warn("SPEND " + coins + " Interesting Coins BEFORE ascending! Quest currency is lost on ascension. Visit shop.php?whichshop=interesting");

    if (available_amount($item[Sept-Ember Censer]) > 0) {
        // This shop visit is a read/refresh, not a purchase.
        if (!to_boolean(get_property("_septEmberBalanceChecked")))
            visit_url("shop.php?whichshop=september");
        if (to_boolean(get_property("_septEmberBalanceChecked"))) {
            int embers = to_int(get_property("availableSeptEmbers"));
            don_note("Sept-Ember Censer embers available: " + embers);
            if (embers > 0)
                don_warn("SPEND " + embers + " SEPT-EMBERS BEFORE ascending! They carry over at rollover, NOT ascension. Visit shop.php?whichshop=september");
        } else don_warn("Could not verify Sept-Ember balance. Visit the censer shop before ascending.");
    } else {
        don_note("Sept-Ember Censer not accessible in current inventory; no verified ember balance.");
    }
}

// Cleaned-up legacy don_preAscention logic: no recursive calls to don_ascendprep.
void don_boxing_day() {
    if (don_flag("don_preAscBoxingDay", true) == false) return;
    if (my_adventures() <= 4) return;
    if (to_boolean(get_property("haveBoxingDaydreamSoftcore"))) {
        don_note("Boxing Daycare already unlocked.");
        return;
    }
    item pass = $item[10056]; // Boxing Day Pass
    if (item_amount(pass) == 0) {
        if (buy(1, pass, 35000) < 1) don_warn("Could not buy Boxing Day Pass <= 35,000 meat.");
    }
    if (item_amount(pass) > 0) {
        if (!use(1, pass)) don_warn("Boxing Day Pass use failed.");
    }
    if (!to_boolean(get_property("haveBoxingDaydreamSoftcore")))
        don_warn("Boxing Daycare is not unlocked. Original daycare choice chain was unsafe/ambiguous, so manual daycare activity is required.");
}

void don_legacy_turn_burn() {
    if (!don_flag("don_preAscLegacyFarm", true)) return;
    if (my_adventures() == 0) return;
    // available_amount counts accessible pills (inventory plus permitted retrieval sources).
    int pills = available_amount($item[synthetic dog hair pill]) + available_amount($item[distention pill]);
    if (pills < 200) {
        don_note("Combined pills " + pills + " < 200; using dpills first.");
        cli_execute("outfit wineglass");
        cli_execute("ccs don_default");
        cli_execute("dpills " + my_adventures());
    }
    if (my_adventures() > 0) {
        don_note("Running combo for up to " + my_adventures() + " remaining adventures.");
        cli_execute("combo " + my_adventures());
    }
}

void don_legacy_organ_cleanup() {
    if (!don_flag("don_preAscConsume", true)) return;
    don_note("Original pre-ascension organ cleanup.");
    cli_execute("outfit maxorgan");
    if (!to_boolean(get_property("_communismUsed")) && to_int(get_property("familiarSweat")) > 10)
        cli_execute("try; stooperdis");
    cli_execute("CONSUME ALL");
    cli_execute("try; overdrink bucket of wine");
}

void don_workshed() {
    if (!don_flag("don_preAscWorkshedSwap", true)) return;
    if (to_boolean(get_property("_workshedItemUsed"))) return;
    if (available_amount($item[model train set]) == 0 && item_amount($item[TakerSpace letter of Marque]) > 0) {
        don_note("Using TakerSpace letter of Marque (legacy workshed swap).");
        cli_execute("try; use TakerSpace letter of Marque");
    }
}

void don_trophies() {
    if (!don_flag("don_preAscBuyTrophies", true)) return;
    // Claim only trophy IDs that appear in the Trophy Hut purchase form.
    // Capture first, then purchase; never iterate a changing page after buying.
    string page = visit_url("trophy.php");
    matcher m = create_matcher("whichtrophy[^>]*value[^0-9]*([0-9]+)", page);
    boolean [string] seen;
    string [int] ids;
    int found_count = 0;
    while (find(m)) {
        string id = group(m, 1);
        if (seen[id]) continue;
        seen[id] = true;
        ids[found_count] = id;
        found_count = found_count + 1;
    }
    if (found_count == 0) {
        don_note("Trophy Hut: no unclaimed trophy purchase forms found.");
        return;
    }
    int bought_count = 0;
    foreach i, id in ids {
        if (my_meat() < 10000) {
            don_warn("Not enough Meat for trophy " + id + "; stopping.");
            break;
        }
        visit_url("trophy.php?action=buytrophy&whichtrophy=" + id, true);
        string after = visit_url("trophy.php");
        // The game removes the trophy from the unclaimed form on successful purchase.
        matcher still = create_matcher("whichtrophy[^>]*value[^0-9]*" + id + "([^0-9]|$)", after);
        if (find(still)) {
            don_warn("Trophy " + id + " still offered after purchase attempt; no retry.");
        } else {
            bought_count = bought_count + 1;
            don_note("Claimed trophy " + id + ".");
        }
    }
    don_note("Trophies newly claimed: " + bought_count + ".");
}

void don_legend_food() {
    if (!don_flag("don_preAscCraftLegend", true)) return;
    int a = mall_price($item[Yeast of Boris]);
    int b = mall_price($item[Vegetable of Jarlsberg]);
    int c = mall_price($item[St. Sneaky Pete's Whey]);
    int price = 2 * (a + b + c);
    int threshold = 50 * to_int(get_property("valueOfAdventure"));
    if (a <= 0 || b <= 0 || c <= 0 || threshold <= 0 || price >= threshold) {
        don_warn("Legend foods skipped: bad/unknown ingredients price or price " + price + " >= budget " + threshold);
        return;
    }
    foreach it in $items[calzone of legend, deep dish of legend, pizza of legend] {
        int needed = 3 - available_amount(it);
        if (needed > 0) {
            don_note("Crafting " + needed + " " + it);
            if (!cli_execute("make " + needed + " " + it)) don_warn("Could not make " + it);
        }
    }
}

void don_other_legacy_tasks() {
    if (don_flag("don_preAscExtraDailies", false)) {
        cli_execute("try; garden pick");
        cli_execute("try; raffle");
        if (!to_boolean(get_property("breakfastCompleted"))) cli_execute("try; breakfast");
        if (to_int(get_property("_freeBeachWalksUsed")) < 11) cli_execute("try; comb");
    }
    if (don_flag("don_preAscPonyWishes", false)) {
        int wishes_left = 3 - to_int(get_property("_genieWishesUsed"));
        if (wishes_left > 0 && wishes_left <= 3)
            for i from 1 to wishes_left {
                cli_execute("try; genie item pony");
            }
    }
    // Original codMaster coldRes step, made optional to avoid changing Sea equipment.
    if (don_flag("don_preAscColdResGems", false)) cli_execute("try; codMaster equip coldRes");
}

void don_legacy_prep() {
    don_legacy_organ_cleanup();
    don_boxing_day();
    don_legacy_turn_burn();
    don_workshed();
    don_trophies();
    don_legend_food();
    don_other_legacy_tasks();
}

// Required final two actions, deliberately last in the main() RUN path.
// "try" keeps flogger reachable if the PvP script exits with an error.
void don_final_scripts() {
    don_note("Final 1/2: pvp_mab");
    cli_execute("try; call pvp_mab");
    don_note("Final 2/2: flogger.ash");
    cli_execute("try; call flogger.ash");
}

// UnderTheSea specifics from repository README (main, 2026-10-28).
void don_sea_check_item(item it, string label) {
    int owned = available_amount(it) + storage_amount(it);
    if (owned > 0) don_note("Sea requirement OK: " + label + " (" + owned + ")");
    else don_warn("Sea requirement MISSING: " + label);
}

void don_sea_check_familiar(familiar fam) {
    if (have_familiar(fam)) don_note("Sea familiar OK: " + fam);
    else don_warn("Sea familiar MISSING: " + fam);
}

int don_sea_codpiece_slotted() {
    if (available_amount($item[The Eternity Codpiece]) <= 0) return -1;
    string page = visit_url("inventory.php?action=docodpiece");
    int count = 0;
    for i from 1 to 5
        if (contains_text(page, "unblemished pearl mounted in slot #" + i)) count = count + 1;
    return count;
}

// Stock a full set of FIVE pearls in real inventory before asking codMaster to equip.
// The price lookup is a fresh, exact-name Mall search on EVERY purchase iteration.
// mall_price() represents the fifth-cheapest buyable copy, not the absolute lowest.
// buy() has a separate HARD per-item price ceiling so no stale/racing quote can
// authorize spending 100,000 Meat or more on a single pearl.
boolean don_sea_stock_pearls() {
    item pearl = $item[unblemished pearl];
    int held = item_amount(pearl);
    don_note("Unblemished pearls in inventory: " + held + "/5");

    if (held >= 5) return true;
    if (!don_flag("don_preAscSeaBuyPearls", true)) {
        don_warn("Automatic pearl purchase disabled; have " + held + "/5 in inventory.");
        return false;
    }

    // At most five single-item purchases. Stop immediately if price/stock changes.
    for attempt from 1 to 5 {
        held = item_amount(pearl);
        if (held >= 5) return true;

        // Unlike a bare mall_price(), searchmall issues an actual Mall request.
        // Quoting the name ensures the resulting quote applies to this exact item.
        if (!cli_execute("searchmall \"unblemished pearl\"")) {
            don_warn("Fresh Mall search failed. No further pearls purchased.");
            return false;
        }
        int live_quote = mall_price(pearl);
        don_note("Live Mall fifth-cheapest pearl quote: " + live_quote + " Meat (strict limit: under 100,000).");
        if (live_quote <= 0 || live_quote >= 100000) {
            don_warn("Pearl price unavailable or 100,000+ Meat. Stopping at " + held + "/5 inventory.");
            return false;
        }

        int bought = buy(1, pearl, 99999);
        int after = item_amount(pearl);
        if (bought < 1 || after <= held) {
            don_warn("Single-pearl Mall purchase failed or did not increase real inventory (" + held + " -> " + after + "). Stopping.");
            return false;
        }
        don_note("Purchased 1 unblemished pearl; actual inventory now " + after + "/5.");
    }
    return item_amount(pearl) >= 5;
}

// codMaster's 'equip NAME' command reads a named property map saved under
// data/cod_master/saves/. Generate a dedicated namespaced config without using
// its interactive 'set' command or its overwrite-confirming 'save' command.
// This calls codMaster to perform the actual slotting; no homegrown slot writes.
void don_sea_load_codpiece() {
    if (!don_flag("don_preAscSeaLoadCodpiece", true)) return;
    if (available_amount($item[The Eternity Codpiece]) == 0) {
        don_warn("The Eternity Codpiece is not accessible; cannot load pearls.");
        return;
    }
    int already = don_sea_codpiece_slotted();
    if (already == 5) {
        don_note("Codpiece already has all 5 pearls loaded; no purchases needed.");
        return;
    }
    if (!don_sea_stock_pearls()) {
        don_warn("Codpiece loading skipped: fewer than 5 inventory pearls or Mall price limit reached.");
        return;
    }

    string [string] gem_config;
    for i from 1 to 5
        gem_config["cod_master_Slot_" + i] = "" + to_int($item[unblemished pearl]);

    string config_path = "data/cod_master/saves/don_sea_pearls.txt";
    if (!map_to_file(gem_config, config_path)) {
        don_warn("Could not write the codMaster pearl configuration at " + config_path);
        return;
    }
    string [string] persisted;
    if (!file_to_map(config_path, persisted)) {
        don_warn("Could not read back codMaster pearl config. No equipment change attempted.");
        return;
    }
    for i from 1 to 5 {
        if (persisted["cod_master_Slot_" + i] != "" + to_int($item[unblemished pearl])) {
            don_warn("codMaster config failed readback for slot " + i + ". No equipment change attempted.");
            return;
        }
    }
    don_note("Invoking codMaster to equip five pearls (config: don_sea_pearls).");
    if (!cli_execute("codMaster equip don_sea_pearls"))
        don_warn("codMaster reported an equip error; check its installation/configuration.");

    int now = don_sea_codpiece_slotted();
    if (now != 5) don_warn("Codpiece verification FAILED: " + now + "/5 pearls. Fix before ascending.");
    else don_note("The Eternity Codpiece verified with 5/5 unblemished pearls using codMaster.");
}

// Coinmaster helpers: all game mutations stay in RUN or SPEND mode.
// Interesting Coin daily-stock items permit at most 3 purchases per item/day.
// Check item and currency inventory AFTER every purchase; never retry a mismatch.
boolean don_buy_interesting_one(coinmaster shop, item reward, int expected_cost) {
    item coin = $item[interesting coin];
    int before_coins = item_amount(coin);
    int before_reward = item_amount(reward);
    int shop_cost = sell_price(shop, reward);
    if (shop_cost != expected_cost || before_coins < expected_cost) {
        don_warn("Coin purchase blocked: " + reward + " costs " + shop_cost
            + " coins (expected " + expected_cost + "); held " + before_coins + ".");
        return false;
    }
    if (!buy(shop, 1, reward)) {
        don_warn("Interesting Coin shop declined 1 " + reward + "; stopping currency purchases.");
        return false;
    }
    int after_coins = item_amount(coin);
    int after_reward = item_amount(reward);
    if (after_coins != before_coins - expected_cost || after_reward != before_reward + 1) {
        don_warn("Interesting Coin trade mismatch for " + reward + ": coins " + before_coins
            + " -> " + after_coins + ", items " + before_reward + " -> " + after_reward
            + ". Stopping to prevent duplicate transactions.");
        return false;
    }
    don_note("Interesting Coins: bought 1 " + reward + " for " + expected_cost
        + "; remaining " + after_coins + ".");
    return true;
}

boolean don_coin_daily_slot_open(item reward) {
    // This is maintained by KoLmafia's InterestingCoinRequest shop handler.
    return to_int(get_property("_itemBoughtPerDay" + to_int(reward))) < 3;
}

void spend_interesting_coins() {
    item coin = $item[interesting coin];
    int start = item_amount(coin);
    don_note("Interesting Coin spend: actual inventory " + start + ".");
    if (start <= 0) return;
    if (!don_flag("don_preAscSeaSpendInterestingCoins", true)) {
        don_warn("Interesting Coin auto-spend disabled by preference.");
        return;
    }
    coinmaster shop = to_coinmaster("Spend your Interesting Coins");
    if (shop == $coinmaster[none]) {
        don_warn("Interesting Coin shop not recognized by KoLmafia. No coins spent.");
        return;
    }
    if (!visit(shop)) {
        don_warn("Could not load Interesting Coin shop. No coins spent.");
        return;
    }
    if (!is_accessible(shop)) {
        don_warn("Interesting Coin shop is inaccessible: " + inaccessible_reason(shop));
        return;
    }

    // The requested singles: first Liquid Asset and Intangible Asset, each up
    // to its DAILY limit of three. This is also safe for balances over 7.
    for cycle from 1 to 3 {
        foreach reward in $items[liquid asset, intangible asset] {
            if (item_amount(coin) == 0) break;
            if (!don_coin_daily_slot_open(reward)) continue;
            if (!don_buy_interesting_one(shop, reward, 1)) return;
        }
    }
    // Necessary for a 7-coin balance: the first two rewards can buy only 6/day.
    // Toxic Asset is also a one-coin, three/day shop reward.
    for cycle from 1 to 3 {
        if (item_amount(coin) == 0) break;
        if (!don_coin_daily_slot_open($item[toxic asset])) break;
        if (!don_buy_interesting_one(shop, $item[toxic asset], 1)) return;
    }

    // For larger balances, buy up to 3 of each eligible 2- or 3-coin daily
    // reward; do NOT buy expensive collectibles or permanent items.
    if (item_amount(coin) > 0 && don_flag("don_preAscSeaSpendCoinFallbacks", true)) {
        for cycle from 1 to 3 {
            foreach reward in $items[invisible hand, circle of overdraft protection scroll, mint, solvent] {
                if (item_amount(coin) == 0) break;
                int cost = 2;
                if (reward == $item[solvent]) cost = 3;
                if (item_amount(coin) < cost || !don_coin_daily_slot_open(reward)) continue;
                if (!don_buy_interesting_one(shop, reward, cost)) return;
            }
        }
    }
    int left = item_amount(coin);
    if (left == 0) don_note("Interesting Coin spend completed: all " + start + " coins spent.");
    else don_warn("Interesting Coin spend incomplete: " + left + " remain (stock/price restrictions). Never loop-buy past daily caps.");
}

// Force a new shop GET before trusting a Sept-Ember balance. KoLmafia normally
// only parses this shop the first time each day; reset its read-cache flag.
int don_refresh_sept_embers() {
    if (available_amount($item[Sept-Ember Censer]) == 0) return -1;
    set_property("_septEmberBalanceChecked", "false");
    string page = visit_url("shop.php?whichshop=september");
    if (!contains_text(page, "Ember") || !to_boolean(get_property("_septEmberBalanceChecked"))) return -1;
    return to_int(get_property("availableSeptEmbers"));
}

void spend_spet_embers() {
    // Name mirrors the requested helper; purchases occur only in RUN/SPEND.
    if (!don_flag("don_preAscSeaSpendSeptEmbers", true)) {
        don_warn("Sept-Ember auto-spend disabled by preference.");
        return;
    }
    int embers = don_refresh_sept_embers();
    if (embers < 0) {
        don_warn("Sept-Ember balance not verifiable. No Censer purchases made.");
        return;
    }
    don_note("Sept-Ember spend: fresh shop balance " + embers + ".");
    if (embers == 0) return;
    coinmaster shop = to_coinmaster("Sept-Ember Censer");
    if (shop == $coinmaster[none] || !is_accessible(shop)) {
        don_warn("Sept-Ember Censer coinmaster not accessible. No purchases.");
        return;
    }
    item mouthwash = $item[Mmm-brr! brand mouthwash];
    item wheel = $item[wheel of camembert];
    if (embers >= 2 && sell_price(shop, mouthwash) != 2) {
        don_warn("Sept-Ember mouthwash price is not the expected 2 embers. No purchases.");
        return;
    }
    int quantity = embers / 2; // integer division: floor
    if (quantity > 0) {
        int before_item = item_amount(mouthwash);
        if (!buy(shop, quantity, mouthwash)) {
            don_warn("Mouthwash purchase declined. Rechecking balance; no automatic retries.");
            int remain = don_refresh_sept_embers();
            don_warn("Sept-Embers remaining: " + remain + ".");
            return;
        }
        int now = don_refresh_sept_embers();
        int now_item = item_amount(mouthwash);
        if (now != embers - 2 * quantity || now_item != before_item + quantity) {
            don_warn("Mouthwash verification mismatch: expected " + (embers - 2 * quantity)
                + " embers, observed " + now + "; item count " + before_item + " -> "
                + now_item + ". Stopping without retries.");
            return;
        }
        don_note("Sept-Embers: bought " + quantity + " Mmm-brr! brand mouthwash; now " + now + " embers.");
        embers = now;
    }
    if (embers == 1) {
        if (sell_price(shop, wheel) != 1) {
            don_warn("Wheel of camembert is not priced at 1 ember; leaving 1 ember unspent.");
            return;
        }
        int before_wheel = item_amount(wheel);
        if (!buy(shop, 1, wheel)) {
            don_warn("Wheel of camembert purchase failed; leaving 1 ember.");
            return;
        }
        int now = don_refresh_sept_embers();
        if (now != 0 || item_amount(wheel) != before_wheel + 1) {
            don_warn("Wheel purchase not verified; ember balance=" + now + ". No retry.");
            return;
        }
        don_note("Sept-Embers: bought 1 wheel of camembert; balance now zero.");
    }
    int final_balance = don_refresh_sept_embers();
    if (final_balance == 0) don_note("Sept-Ember Censer spend complete: 0 embers.");
    else don_warn("Sept-Ember spend incomplete: remaining=" + final_balance + ".");
}


// Wallet quest: Big Brother -> 50 sand dollars -> damp old boot -> Old Man's wallet.
// Route adapted from rhovious/kol-thesea/src/scripts/TheSea.ash, with explicit
// bounds and rollback of outfit/familiar/mood/CCS/choice. No live action in check.
boolean don_sea_big_brother_unlocked() {
    if (to_boolean(get_property("bigBrotherRescued"))) return true;
    if (available_amount($item[bubblin' stone]) > 0) return true;
    string monkees = get_property("questS02Monkees");
    if (monkees == "finished") return true;
    if (contains_text(visit_url("monkeycastle.php"), "#brothers\"")) return true;
    return false;
}

// Explicitly use owned Borrowed Time before spending adventures; never buy it.
void don_wallet_borrowed_time() {
    if (to_boolean(get_property("_borrowedTimeUsed"))) {
        don_note("Wallet route: Borrowed Time already used today.");
        return;
    }
    if (item_amount($item[borrowed time]) < 1) {
        don_warn("Wallet route: Borrowed Time unused but none held; continuing without buying one.");
        return;
    }
    don_note("Wallet route: using owned Borrowed Time before adventuring.");
    if (!use(1, $item[borrowed time]) || !to_boolean(get_property("_borrowedTimeUsed")))
        don_warn("Wallet route: Borrowed Time use did not verify.");
}

// Requires a prepared underwater outfit, Red-Nosed Snapper and configured CCS.
// Saves and restores temporary battle configuration EVEN if a step fails.
boolean don_sea_unlock_big_brother() {
    if (don_sea_big_brother_unlocked()) return true;
    if (my_adventures() < 1) {
        don_warn("Wallet route: no adventures available to unlock Big Brother.");
        return false;
    }
    if (!have_familiar($familiar[Red-Nosed Snapper])) {
        don_warn("Wallet route: Red-Nosed Snapper familiar missing. No adventures spent.");
        return false;
    }
    familiar old_familiar = my_familiar();
    string old_mood = get_property("currentMood");
    string old_ccs = get_property("customCombatScript");
    string old_battle_action = get_property("battleAction");
    string old_choice = get_property("choiceAdventure299");
    boolean rescued = false;
    // Explicit checkpoint stores equipment; familiar, mood, CCS & choice saved separately.
    if (!cli_execute("checkpoint")) {
        don_warn("Could not checkpoint current equipment; declining to change outfit.");
        return false;
    }
    try {
        if (!cli_execute("outfit sea_prep")) {
            don_warn("Wallet route: missing/invalid outfit sea_prep.");
            return false;
        }
        if (!use_familiar($familiar[Red-Nosed Snapper])) {
            don_warn("Wallet route: could not switch to Red-Nosed Snapper.");
            return false;
        }
        if (available_amount($item[toy cupid bow]) > 0) {
            if (!equip($slot[familiar], $item[toy cupid bow]))
                don_warn("Wallet route: couldn't equip toy cupid bow; continuing with existing familiar gear.");
        } else don_warn("Wallet route: toy cupid bow unavailable; relying on outfit's underwater equipment.");
        if (!cli_execute("mood sea_prep") || !cli_execute("ccs snapper fish")) {
            don_warn("Wallet route: mood sea_prep / CCS snapper fish could not be selected.");
            return false;
        }
        set_property("battleAction", "custom combat script");
        if (!boolean_modifier("Adventure Underwater")) {
            don_warn("Wallet route: sea_prep does not currently provide underwater breathing.");
            return false;
        }
        don_wallet_borrowed_time();
        // Start the Old Guy's quest if needed; this is only a GET/quest start.
        if (get_property("questS01OldGuy") == "unstarted")
            visit_url("place.php?whichplace=sea_oldman&action=oldman_oldman");
        string seafloor = visit_url("seafloor.php");
        int max_garden = to_int(get_property("don_preAscSeaWalletGardenMaxTurns"));
        if (max_garden <= 0) max_garden = 40;
        if (max_garden > 100) max_garden = 100;
        // Little Brother is revealed after using a wriggling flytrap pellet.
        if (!contains_text(seafloor, "monkeycastle.gif")) {
            don_note("Wallet route: acquiring wriggling flytrap pellet in An Octopus's Garden.");
            for turn from 1 to max_garden {
                if (item_amount($item[wriggling flytrap pellet]) > 0 || my_adventures() == 0) break;
                int before = my_adventures();
                if (!adventure(1, $location[An Octopus's Garden])) {
                    don_warn("Wallet route: garden adventure failed; stopping.");
                    return false;
                }
                if (my_adventures() >= before) {
                    don_warn("Wallet route: garden did not consume an adventure; stopping ambiguous loop.");
                    return false;
                }
            }
            if (item_amount($item[wriggling flytrap pellet]) < 1) {
                don_warn("Wallet route: pellet not found inside bounded garden search.");
                return false;
            }
            if (!use(1, $item[wriggling flytrap pellet])) {
                don_warn("Wallet route: failed to use wriggling flytrap pellet.");
                return false;
            }
            seafloor = visit_url("seafloor.php");
        }
        if (!contains_text(seafloor, "monkeycastle.gif")) {
            don_warn("Wallet route: Sea Monkee Castle still locked after pellet.");
            return false;
        }
        // Little Brother identifies his missing sibling and opens the Wreck route.
        visit_url("monkeycastle.php?who=1");
        if (don_sea_big_brother_unlocked()) return true;
        set_property("choiceAdventure299", "1");
        int max_wreck = to_int(get_property("don_preAscSeaWalletWreckMaxTurns"));
        if (max_wreck <= 0) max_wreck = 60;
        if (max_wreck > 150) max_wreck = 150;
        don_note("Wallet route: looking for Down at the Hatch (option 1) in the Wreck, max " + max_wreck + " turns.");
        for turn from 1 to max_wreck {
            if (don_sea_big_brother_unlocked()) break;
            if (my_adventures() == 0) break;
            int before = my_adventures();
            if (!adventure(1, $location[The Wreck of the Edgar Fitzsimmons])) {
                don_warn("Wallet route: Wreck adventure failed; stopping.");
                return false;
            }
            if (my_adventures() >= before) {
                don_warn("Wallet route: Wreck turncount did not advance; stopping ambiguous loop.");
                return false;
            }
            // KoLmafia sets bigBrotherRescued when the hatch option rescues him.
            if (to_boolean(get_property("bigBrotherRescued"))) break;
            if (contains_text(visit_url("monkeycastle.php"), "#brothers\"")) break;
        }
        if (!don_sea_big_brother_unlocked()) {
            don_warn("Wallet route: Big Brother not unlocked within the bounded Wreck search.");
            return false;
        }
        visit_url("monkeycastle.php?who=2");
        rescued = don_sea_big_brother_unlocked();
    } finally {
        // Never leave the Wreck choice, temporary outfit or combat configuration active.
        set_property("choiceAdventure299", old_choice);
        if (!use_familiar(old_familiar)) don_warn("Could not restore previous familiar.");
        if (!cli_execute("outfit checkpoint")) don_warn("Could not restore original outfit checkpoint.");
        if (old_mood != "") cli_execute("mood " + old_mood);
        if (old_ccs != "") cli_execute("ccs " + old_ccs);
        set_property("battleAction", old_battle_action);
        don_note("Wallet route: attempted to restore original gear, familiar, mood, CCS, and choice #299.");
    }
    return rescued;
}

// Invoked by RUN (before any legacy turn burn), or stand-alone WALLET mode.
void get_wallet_function() {
    item wallet = $item[damp old wallet];
    item boot = $item[damp old boot];
    item dollars = $item[3575]; // sand dollar
    if (item_amount(wallet) > 0) {
        don_note("Damp old wallet already in real inventory (" + item_amount(wallet) + "); skipping.");
        return;
    }
    if (get_property("questS01OldGuy") == "finished" && item_amount(boot) == 0) {
        don_warn("Old Guy quest already finished and wallet is not in inventory (may have been used). Cannot obtain another this ascension.");
        return;
    }
    if (get_property("questS01OldGuy") == "unstarted")
        visit_url("place.php?whichplace=sea_oldman&action=oldman_oldman");
    // A boot is unique in this quest. Any positive count is ready to exchange.
    if (item_amount(boot) == 0) {
        if (!don_sea_big_brother_unlocked()) {
            if (!user_confirm("Big Brother is locked. Spend adventures to get the damp old wallet?")) {
                don_note("Damp wallet rescue declined; continuing without spending adventures or Meat.");
                return;
            }
            if (!don_sea_unlock_big_brother()) {
                don_warn("Could not unlock Big Brother. Wallet left for manual attention.");
                return;
            }
        }
        coinmaster big = to_coinmaster("Big Brother");
        if (big == $coinmaster[none]) {
            don_warn("KoLmafia does not recognize Big Brother coinmaster; no sand dollars purchased.");
            return;
        }
        if (to_boolean(get_property("dampOldBootPurchased"))) {
            don_warn("KoLmafia reports damp old boot already purchased this ascension; cannot buy twice.");
            return;
        }
        int held = item_amount(dollars);
        if (held < 50) {
            int needed = 50 - held;
            don_note("Wallet route: buying " + needed + " sand dollars in the Mall (to reach 50 in inventory).");
            boolean bought = buy(needed, dollars);
            if (!bought || item_amount(dollars) < 50) {
                don_warn("Could not obtain 50 sand dollars (inventory " + item_amount(dollars) + "). No boot purchase.");
                return;
            }
        }
        if (!visit(big)) {
            don_warn("Cannot visit Big Brother's shop; check underwater access.");
            return;
        }
        int boot_cost = sell_price(big, boot);
        if (boot_cost != 50) {
            don_warn("Big Brother boot price was " + boot_cost + " sand dollars, expected 50; no purchase.");
            return;
        }
        int dollars_before = item_amount(dollars);
        if (item_amount(boot) == 0 && !buy(big, 1, boot)) {
            don_warn("Big Brother declined damp old boot; no automatic retry.");
            return;
        }
        if (item_amount(boot) < 1 || item_amount(dollars) != dollars_before - 50) {
            don_warn("Boot trade inventory/currency verification mismatch. No Old Man reward attempted.");
            return;
        }
        don_note("Bought damp old boot from Big Brother; verifying Old Man exchange.");
    }
    // Official route for choosing the wallet reward is whichreward=6313.
    string oldman = visit_url("place.php?whichplace=sea_oldman&action=oldman_oldman");
    if (item_amount(wallet) > 0) {
        don_note("Damp old wallet received from Old Man.");
        return;
    }
    if (!contains_text(oldman, "6313") && !contains_text(to_lower_case(oldman), "damp old wallet")) {
        don_warn("Old Man does not visibly offer wallet reward. No blind POST; inspect the quest manually.");
        return;
    }
    visit_url("place.php?whichplace=sea_oldman&action=oldman_oldman&preaction=pickreward&whichreward=6313");
    if (item_amount(wallet) > 0) don_note("SUCCESS: damp old wallet obtained and in real inventory.");
    else don_warn("Old Man reward was attempted but wallet not found in inventory; no repeated claim.");
}

// Wallet end-of-day extension. A wallet is a single quest reward: > 0 means present.
// Read-only mat check first: visiting the Old Man can refresh quest inventory/state.
void don_sea_check_sushi_mat() {
    item mat = $item[3581]; // sushi-rolling mat
    if (item_amount(mat) == 0) {
        don_note("No sushi-rolling mat in inventory; checking the Old Man.");
        visit_url("place.php?whichplace=sea_oldman&action=oldman_oldman");
    }
    if (item_amount(mat) > 0)
        don_note("sushi-rolling mat owned (" + item_amount(mat) + ").");
    else
        don_warn("you need to unlock the sushi-rolling mat in your next sea ascension");
}

// Match original don_preAscention.ash: (dog hair pills + distention pills) / 2.
// Under 100 combined pairs: dpills followed by combo for leftover turns.
// At or above 100 pairs: combo directly. We read actual inventory, not storage.
void don_sea_drain_extra_adventures() {
    if (don_flag("don_preAscConsume", true)) {
        don_note("Extra-adventure cleanup: outfit maxorgan, consume all value 3500.");
        if (!cli_execute("outfit maxorgan"))
            don_warn("Could not equip outfit maxorgan; proceeding with current equipment.");
        if (!cli_execute("consume all value 3500"))
            don_warn("consume all value 3500 did not report success.");
        if (my_inebriety() <= inebriety_limit()) {
            don_note("Not yet overdrunk: attempting bucket of wine nightcap.");
            if (!cli_execute("try; overdrink bucket of wine"))
                don_warn("Bucket of wine nightcap did not report success.");
        } else {
            don_note("Already overdrunk; skipping bucket of wine.");
        }
    }
    if (!don_flag("don_preAscLegacyFarm", true)) {
        don_note("Adventure farming disabled by don_preAscLegacyFarm=false.");
        return;
    }
    if (my_adventures() <= 0) return;
    int dog_pills = item_amount($item[synthetic dog hair pill]);
    int dist_pills = item_amount($item[distention pill]);
    int pair_count = (dog_pills + dist_pills) / 2;
    don_note("Pills in inventory: " + dog_pills + " dog hair + " + dist_pills
        + " distention; original pair threshold=" + pair_count + "/100.");
    if (pair_count < 100) {
        don_note("Under 100 pairs: dpills route, then combo for leftover adventures.");
        if (!cli_execute("outfit wineglass"))
            don_warn("outfit wineglass failed; dpills may not be able to adventure while overdrunk.");
        if (!cli_execute("ccs don_default"))
            don_warn("ccs don_default failed; dpills will use the current CCS.");
        if (!cli_execute("dpills " + my_adventures()))
            don_warn("dpills returned failure; checking adventures before fallback.");
    } else {
        don_note("At least 100 pill pairs: direct combo route.");
    }
    if (my_adventures() > 0) {
        don_note("Using combo for " + my_adventures() + " remaining adventures.");
        if (!cli_execute("combo " + my_adventures()))
            don_warn("combo reported a failure. No automatic retry.");
    }
}

void don_sea_leftover_warning() {
    int remaining_advs = my_adventures();
    int remaining_pvp = pvp_attacks_left();
    if (remaining_advs > 2 || remaining_pvp > 0)
        don_warn("you have " + remaining_advs + " Adventures and " + remaining_pvp + " pvp-fites to spend");
    else
        don_note("End-of-day balance: " + remaining_advs + " Adventures, "
            + remaining_pvp + " PvP fights remaining.");
}

void don_sea_pvp() {
    don_note("Spending PvP fights with pvp_mab.");
    if (!cli_execute("try; call pvp_mab"))
        don_warn("pvp_mab call failed; PvP balance will be reported.");
}

void don_sea_flogger() {
    don_note("Last step: flogger.ash.");
    if (!cli_execute("try; call flogger.ash"))
        don_warn("flogger.ash call failed.");
}

// Called from WALLET and full RUN, but never from CHECK/SPEND/PEARLS.
// The user decides whether to burn adventures; otherwise only trophies and an
// explicitly authorized PvP branch can change game state here.
void don_sea_wallet_end_of_day() {
    boolean has_wallet = item_amount($item[damp old wallet]) > 0;
    boolean farm_approved = false;
    if (has_wallet && my_adventures() > 2) {
        don_note("Ye be a sea-worth salt dog!");
        farm_approved = user_confirm("Spend extra adventures? This will equip maxorgan, consume, optionally overdrink, then run dpills/combo.");
    }
    if (farm_approved) don_sea_drain_extra_adventures();
    else if (has_wallet && my_adventures() > 2)
        don_note("Extra-adventure spending declined; no consume/overdrink/dpills/combo.");
    else if (!has_wallet)
        don_warn("Damp old wallet not held; skipping optional adventure-spend prompt.");

    // Trophy check is performed regardless of adventure-spend answer.
    don_trophies();

    boolean ran_pvp = false;
    // In the affirmative adventure branch, PvP starts automatically when >1.
    // When adventure spending was declined, PvP gets its own Yes/No gate.
    if (pvp_attacks_left() > 1) {
        if (farm_approved || user_confirm("Spend your remaining PvP fights with pvp_mab?")) {
            don_sea_pvp();
            ran_pvp = true;
        } else don_note("PvP spending declined.");
    } else don_note("Not enough PvP fights (>1 required); pvp_mab skipped.");

    // Print the warning at the end, before flogger when it has been authorized.
    don_sea_leftover_warning();
    if (farm_approved || ran_pvp) don_sea_flogger();
}


// Home clan is the only clan whose photo booth we use for Sea prep.
// clanhop is a separate user-installed script (not a built-in KoLmafia command).
string home_clan = "The Meat Packers Union Of Slave Labor";

void don_photo_green(string msg) {
    print("[Sea Prep] " + msg, "green");
}

int sea_prep_booth_remaining(string text, string action, int cap) {
    // Parsed counts are only trusted when the associated menu label is present.
    // Choice 1533 displays labels followed by the daily remaining count.
    if (!contains_text(text, action)) return -1;
    matcher found_count = create_matcher(action + "[^0-9]{0,90}([0-3])\\s+(?:more\\s+)?times?", text);
    if (!find(found_count)) return -1;
    int remaining = to_int(group(found_count, 1));
    if (remaining < 0 || remaining > cap) return -1;
    return remaining;
}

void sea_prep_photo_booth(boolean may_hop) {
    don_note("Home clan photo booth: " + home_clan + ".");
    string current_clan = get_clan_name();
    if (current_clan != home_clan) {
        if (!may_hop) {
            don_warn("Photo booth not verified: currently in '" + current_clan
                + "'. CHECK will not change clans. Use 'sea-prep booth' for a live home-clan check.");
            foreach prop in $items[sheriff pistol, sheriff moustache, sheriff badge] {
                if (available_amount(prop) > 0)
                    don_photo_green("Sheriff prop held: " + prop + " (" + available_amount(prop) + ").");
                else
                    don_note("Sheriff prop " + prop + ": not held; home-clan booth not yet verified.");
            }
            return;
        }
        don_note("Switching to home clan via clanhop.");
        if (!cli_execute("clanhop " + home_clan)) {
            don_warn("clanhop failed or is not installed. No photo booth checked.");
            return;
        }
        current_clan = get_clan_name();
        if (current_clan != home_clan) {
            don_warn("Cannot verify home clan after clanhop (current: '" + current_clan
                + "'). Refusing to claim Sheriff props available.");
            return;
        }
    }

    // A GET for booth status; this function never borrows props or uses any photo credit.
    string raw = visit_url("clan_viplounge.php?action=photobooth");
    string clean = to_lower_case(replace_all(create_matcher("(?s)<[^>]*>", raw), " "));
    clean = replace_all(create_matcher("\\s+", clean), " ");
    boolean has_effect = contains_text(clean, "get your photo taken");
    boolean has_prop = contains_text(clean, "borrow a prop");
    boolean has_group = contains_text(clean, "take a group photo");
    // Some exhausted actions are omitted or disabled in the page;
    // the other visible actions still provide booth evidence.
    boolean booth_verified = has_effect || has_prop || has_group
        || contains_text(raw, "whichchoice=1533");

    if (!booth_verified) {
        don_warn("Home clan photo booth not confirmed by its page. No automatic green availability claims.");
        foreach prop in $items[sheriff pistol, sheriff moustache, sheriff badge] {
            if (available_amount(prop) > 0)
                don_photo_green("Sheriff prop held: " + prop + " (" + available_amount(prop) + ").");
            else don_warn("Sheriff prop not held and booth unverified: " + prop + ".");
        }
        return;
    }

    don_photo_green("Home clan photobooth verified; Sheriff pistol, moustache and badge are booth prop options.");
    int effects_left = sea_prep_booth_remaining(clean, "get your photo taken", 3);
    int props_left = sea_prep_booth_remaining(clean, "borrow a prop", 3);
    int groups_left = sea_prep_booth_remaining(clean, "take a group photo", 1);

    if (effects_left < 0) {
        effects_left = max(0, 3 - to_int(get_property("_photoBoothEffects")));
        don_note("Get your photo taken: " + effects_left + "/3 remaining (KoLmafia daily preference; page count not confirmed).");
    } else
        don_photo_green("Get your photo taken: " + effects_left + "/3 remaining (photobooth page).");

    if (props_left < 0) {
        props_left = max(0, 3 - to_int(get_property("_photoBoothEquipment")));
        don_note("Borrow a prop: " + props_left + "/3 remaining (KoLmafia daily preference; page count not confirmed).");
    } else
        don_photo_green("Borrow a prop: " + props_left + "/3 remaining (photobooth page).");

    if (groups_left < 0) {
        if (has_group) don_photo_green("Take a group photo: option present; remaining count unconfirmed (daily cap 1).");
        else don_note("Take a group photo: option/count not shown; daily cap 1.");
    } else
        don_photo_green("Take a group photo: " + groups_left + "/1 remaining (photobooth page).");

    foreach prop in $items[sheriff pistol, sheriff moustache, sheriff badge] {
        if (available_amount(prop) > 0)
            don_photo_green("Sheriff prop ready: " + prop + " (" + available_amount(prop) + " held).");
        else
            don_photo_green("Sheriff prop supported by VERIFIED home clan photo booth: " + prop
                + " (" + props_left + " daily borrows remaining, not yet held).");
    }
    if (props_left == 0)
        don_warn("All 3 daily photobooth prop borrows are exhausted. Sheriff items not held cannot be borrowed again today.");
    else
        don_note("Photo booth availability audit only: no prop borrowed automatically.");
}

void don_sea_setup(boolean may_act) {
    if (may_act) {
        set_property("autoSatisfyWithNPCs", "true");
        // Strictly postloop options: user can enable other expensive steps themselves.
        if (don_flag("don_preAscSeaConfigurePostloop", true))
            set_property("uts_postLoopPrepCodpiece", "true");
        don_sea_load_codpiece();
    }
    don_note("Sea path: UnderTheSea (11,037 Leagues Under the Sea). Requires KoLmafia r29057+.");
    don_note("Sea recommendation: run UnderTheSea sim in gCLI before ascending (read-only checklist).");
    don_note("Install if missing: git checkout donCannoli-burns/UnderTheSea");
    if (may_act && don_flag("don_preAscSeaRunSim", true)) {
        don_note("Running UnderTheSea sim checklist (no pulls/fights/spending).");
        cli_execute("try; UnderTheSea sim");
    }
    don_sea_check_item($item[Monodent of the Sea], "Monodent of the Sea");
    don_sea_check_item($item[The Eternity Codpiece], "The Eternity Codpiece");
    don_sea_check_item($item[Congressional Medal of Insanity], "Congressional Medal of Insanity");
    don_sea_check_item($item[damp old wallet], "damp old wallet (recommended, not mandatory)");
    if (!may_act && item_amount($item[damp old wallet]) == 0)
        don_note("CHECK-ONLY wallet prep: sea-prep wallet to acquire it.");
    don_sea_check_familiar($familiar[Grouper Groupie]);
    don_sea_check_familiar($familiar[glover]);
    don_sea_check_familiar($familiar[foul ball]);
    don_note("Unblemished pearls held in actual inventory: " + item_amount($item[unblemished pearl]) + "/5");
    int pearls = don_sea_codpiece_slotted();
    if (pearls >= 0) {
        don_note("Pearls slotted in codpiece: " + pearls + "/5");
        if (pearls < 5) {
            don_warn("Load 5 unblemished pearls before ascending.");
            if (!may_act)
                don_note("CHECK-ONLY cannot load them. Run: sea-prep pearls");
        }
    } else don_warn("Codpiece not available for slot verification.");
    don_note("MANUAL: confirm all underwater maps completed before ascending.");
    don_note("OPTIONAL: locket black crayon golem + unholy diver; clear Mer-kin Graffiti from NC queue.");
    sea_prep_photo_booth(may_act);
    if (available_amount($item[Clan VIP Lounge key]) == 0)
        don_warn("Clan VIP Lounge key not accessible; photobooth may be unavailable.");
}

// Optional ASH varargs: no gCLI/dropdown prompt when launched without arguments.

/* Branch-exclusive CLI entrypoint (sim never visits URLs or runs CLI actions). */
void sea_prep_help() {
    don_note("Sea Prep optional branch: commands and descriptions.");
    don_note("sea-prep help    - show this command reference; default without arguments.");
    don_note("sea-prep booth   - clanhop to configured home clan, inspect photo booth and Sheriff prop access (no borrowing).");
    don_note("sea-prep sim     - READ-ONLY full preparation simulation and resource plan.");
    don_note("sea-prep check   - Sea checklist/resource warnings; no spending.");
    don_note("sea-prep run     - FULL Sea aftercore suite; may spend Meat, items, turns and PvP.");
    don_note("sea-prep wallet  - wallet/boot quest, sushi mat, optional prompted end-of-day.");
    don_note("sea-prep pearls  - acquire up to 5 unblemished pearls and load via codMaster.");
    don_note("sea-prep spend   - pearls + Interesting Coins + Sept-Embers; no turn farm.");
    don_note("KoLmafia git checkout donCannoli-burns/UnderTheSea sea-prep ; git update");
}

void sea_prep_sim() {
    don_note("SIM ONLY: projected FULL sea-prep run. No purchases, adventures, visits, prompts, CLI commands, or property changes.");
    if (!don_aftercore())
        don_warn("SIM: not in aftercore; actual RUN would stop before preparation.");
    else
        don_note("SIM: aftercore detected; full RUN would be eligible to start.");

    int wallets = item_amount($item[damp old wallet]);
    int boots = item_amount($item[damp old boot]);
    int dollars = item_amount($item[3575]);
    boolean brother = to_boolean(get_property("bigBrotherRescued"));
    don_note("SIM wallet: wallet=" + wallets + "; boot=" + boots + "; sand dollars=" + dollars
        + "; Big Brother rescued=" + brother + ".");
    if (wallets > 0) don_note("SIM wallet: already owned; skip wallet acquisition.");
    else if (boots > 0) don_note("SIM wallet: present Old Man's boot for wallet reward; verify inventory.");
    else if (to_boolean(get_property("dampOldBootPurchased")))
        don_warn("SIM wallet: boot already purchased this ascension; do not repurchase.");
    else {
        if (!brother) don_note("SIM wallet: would PROMPT before unlocking Big Brother (bounded Garden/Wreck adventures).");
        don_note("SIM wallet: once Big Brother is accessible, obtain up to "
            + max(0, 50 - dollars) + " sand dollars, buy boot, return boot and take wallet.");
    }
    if (item_amount($item[3581]) > 0)
        don_note("SIM sushi mat: owned.");
    else don_warn("SIM sushi mat: inspect Old Man; if still absent, unlock it on the next Sea ascension.");

    int loose = item_amount($item[unblemished pearl]);
    int censer = available_amount($item[Sept-Ember Censer]);
    don_note("SIM Codpiece: " + loose + " unblemished pearls in inventory; would check five Codpiece slots.");
    if (available_amount($item[The Eternity Codpiece]) <= 0)
        don_warn("SIM Codpiece: missing; pearling/loading cannot proceed.");
    else
        don_note("SIM Codpiece: if under five slotted, stock only as needed under the 100,000 Meat each cap and invoke codMaster.");
    don_note("SIM equipment requirements: Monodent=" + available_amount($item[Monodent of the Sea])
        + "; Codpiece=" + available_amount($item[The Eternity Codpiece])
        + "; Medal=" + available_amount($item[Congressional Medal of Insanity]) + ".");
    don_note("SIM familiars: Grouper Groupie=" + have_familiar($familiar[Grouper Groupie])
        + "; Glover=" + have_familiar($familiar[glover])
        + "; Foul Ball=" + have_familiar($familiar[foul ball]) + ".");

    int coins = item_amount($item[interesting coin]);
    don_note("SIM coins: " + coins + " actual-inventory Interesting Coins; full RUN would shop while daily stock permits.");
    if (censer > 0) {
        if (!to_boolean(get_property("_septEmberBalanceChecked")))
            don_warn("SIM Sept-Embers: current balance not verified; full RUN would refresh the shop first.");
        else {
            int embers = to_int(get_property("availableSeptEmbers"));
            don_note("SIM Sept-Embers: " + embers + "; plan up to " + (embers / 2)
                + " mouthwashes and " + (embers % 2) + " wheel(s) of camembert, subject to shop stock.");
        }
    } else don_note("SIM Sept-Ember Censer not available; cannot verify balance without visiting shop.");

    if (!to_boolean(get_property("_borrowedTimeUsed")))
        don_note("SIM Borrowed Time: unused today; full RUN uses an owned one only if don_preAscUseBorrowedTime=true.");
    else don_note("SIM Borrowed Time: already used today.");
    don_note("SIM optional dailies: Boxing Day, workshed, legend food, extra dailies use their don_preAsc* preferences.");
    don_note("SIM Sea: full RUN calls the UnderTheSea sim checklist (when don_preAscSeaRunSim=true).");
    don_note("SIM trophies: full RUN checks the Trophy Hut and buys eligible unclaimed trophies.");
    don_note("SIM photo booth: full RUN would switch via clanhop to the home clan and inspect its photo booth. No SIM switch, visit or borrow.");
    int adv = my_adventures();
    int pvp = pvp_attacks_left();
    don_note("SIM cleanup: " + adv + " adventures, " + pvp + " PvP fights remain.");
    if (wallets > 0 && adv > 2)
        don_note("SIM cleanup: would PROMPT before maxorgan, consume value 3500, overdrink and dpills/combo.");
    else don_note("SIM cleanup: no automatic adventure farm prompt at present.");
    if (pvp > 1)
        don_note("SIM PvP: full RUN may call pvp_mab following its existing confirmation/cleanup policy, then flogger.");
    else don_note("SIM PvP: <=1 fights, no automatic pvp_mab call.");
    don_note("SIM END: no state-changing actions were issued.");
}

void main(string... modes) {
    don_note("Sea build: optional branch v1 (2026-10-28).");
    string mode = "help";
    if (count(modes) > 0) mode = to_lower_case(modes[0]);
    if (mode == "help") { sea_prep_help(); return; }
    if (mode == "sim") { sea_prep_sim(); return; }
    if (mode == "booth") { sea_prep_photo_booth(true); return; }
    if (mode == "check") {
        don_note("Sea pre-ascension CHECK-ONLY (no purchases, no Codpiece changes).");
        don_sea_setup(false);
        if (item_amount($item[3581]) > 0) don_note("sushi-rolling mat owned.");
        else don_warn("sushi-rolling mat absent from inventory; use wallet mode or run to check the Old Man.");
        don_borrowed_time(false);
        don_spend_warnings();
        return;
    }
    if (mode != "" && mode != "run" && mode != "spend" && mode != "pearls" && mode != "wallet") {
        don_warn("Usage: sea-prep [help|sim|booth|run|check|wallet|pearls|spend]");
        return;
    }
    if (!don_aftercore()) { don_warn("Run this before ascending, in aftercore (king liberated)."); return; }
    if (mode == "wallet") {
        don_note("WALLET MODE: acquire wallet, check sushi mat, then offer optional end-of-day cleanup.");
        get_wallet_function();
        don_sea_check_sushi_mat();
        don_sea_wallet_end_of_day();
        return;
    }
    if (mode == "pearls") {
        don_note("PEARLS-ONLY: stocking/loading pearls, no other purchases or legacy tasks.");
        don_sea_load_codpiece();
        return;
    }
    if (mode == "spend") {
        don_note("SPEND-ONLY: load Codpiece and spend Interesting Coins/Sept-Embers, no legacy turn burn.");
        don_sea_load_codpiece();
        spend_interesting_coins();
        spend_spet_embers();
        don_spend_warnings();
        return;
    }
    don_note("Sea aftercore prep: wallet/mat, Sea readiness, legacy non-farm tasks, currency, and prompted end-of-day cleanup.");
    get_wallet_function(); // gated quest unlock; restores gear on exit
    don_sea_check_sushi_mat();
    don_borrowed_time(true); // optional use is before any approved farming
    // Preserve previous safe legacy side tasks, but route organ/turn spending
    // and trophies through the new prompted end-of-day coordinator below.
    don_boxing_day();
    don_workshed();
    don_legend_food();
    don_other_legacy_tasks();
    don_sea_setup(true);
    spend_interesting_coins();
    spend_spet_embers();
    don_spend_warnings();
    don_sea_wallet_end_of_day();
}
