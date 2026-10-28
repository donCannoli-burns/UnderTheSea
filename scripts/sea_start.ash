// sea_start.ash
// Author: doncannoli
// KoLmafia / UnderTheSea aftercore handoff
// Usage: UnderTheSea sea-start status (read-only report)
//        UnderTheSea sea-start        (run workflow)
//        UnderTheSea sea-start restore (recover preference)
//        or call sea_start.ash directly with the same modes
//        call sea_start.ash          (run workflow)
//        call sea_start.ash restore  (recover postloop pref after hard interruption)
//
// Requires a working UnderTheSea command and installed don_custom_functions.ash dependencies.
// Optional: fallbot.ash, Shorter-Order Cook, blue plate, autumn-aton.
// IMPORTANT: UnderTheSea postloop itself calls uts_postloopCommand.

string FARMING_COMMAND = "ashq import <don_custom_functions.ash>; augmentBreakfast();";
string POSTLOOP_PREF = "uts_postloopCommand";
string BACKUP_PREF = "seaStar_previousPostloopCommand";
string PENDING_PREF = "seaStar_postloopRestorePending";

record sea_state {
    boolean king_freed;
    boolean interaction_unlocked;
    int turns_spent;
    int adventures_available;
};

sea_state path_state() {
    sea_state s;
    s.king_freed = to_boolean(get_property("kingLiberated"));
    // can_interact() tests whether KoLmafia believes interaction restrictions
    // are over. This is deliberately NOT labelled "in_ronin()".
    s.interaction_unlocked = can_interact();
    s.turns_spent = my_turncount();
    s.adventures_available = my_adventures();
    return s;
}

string difficulty_type() {
    if (in_hardcore()) return "Hardcore";
    if (in_casual()) return "Casual";
    return "Softcore";
}

void print_astral_inventory() {
    // Fifteen Astral Pet Store equipment choices, plus astral consumables.
    // item_amount() deliberately checks CURRENT INVENTORY ONLY, not Hagnk's.
    string [int] astral_names;
    astral_names[0] = "astral bludgeon";
    astral_names[1] = "astral shield";
    astral_names[2] = "astral chapeau";
    astral_names[3] = "astral bracer";
    astral_names[4] = "astral longbow";
    astral_names[5] = "astral shorts";
    astral_names[6] = "astral mace";
    astral_names[7] = "astral trousers";
    astral_names[8] = "astral ring";
    astral_names[9] = "astral statuette";
    astral_names[10] = "astral pistol";
    astral_names[11] = "astral mask";
    astral_names[12] = "astral pet sweater";
    astral_names[13] = "astral shirt";
    astral_names[14] = "astral belt";
    astral_names[15] = "astral hot dog";
    astral_names[16] = "astral pilsner";
    astral_names[17] = "astral hot dog dinner";
    astral_names[18] = "astral six-pack";
    astral_names[19] = "carton of astral energy drinks";
    astral_names[20] = "astral energy drink";

    print("--- Astral inventory (on-hand only) ---", "blue");
    int found = 0;
    foreach idx, name in astral_names {
        item it = to_item(name);
        if (it == $item[none]) {
            print("Unrecognized in this KoLmafia version: " + name, "orange");
            continue;
        }
        int qty = item_amount(it);
        if (qty > 0) {
            print(it + " x" + qty);
            found = found + 1;
        }
    }
    if (found == 0) print("No listed astral items found in current inventory.");
}

void print_codpiece_gems() {
    print("--- Eternity Codpiece gems (KoLmafia slot view) ---", "blue");
    // KoLmafia recognizes auxiliary equipment slots codpiece1 through codpiece5
    // on builds supporting the Eternity Codpiece. Read-only; no gem changes.
    for (int i = 1; i <= 5; i = i + 1) {
        string label = "codpiece" + i;
        slot target = to_slot(label);
        if (target == $slot[none]) {
            print(label + ": slot unavailable in this KoLmafia build", "orange");
        } else {
            print(label + ": " + equipped_item(target));
        }
    }
    // Same read-only page technique used in don_preAscention_sea.ash:
    // it verifies mounted unblemished pearls even when generic equipment
    // slot reporting does not reflect all the Codpiece's contents.
    if (available_amount($item[The Eternity Codpiece]) > 0) {
        string page = visit_url("inventory.php?action=docodpiece");
        int pearls = 0;
        for (int i = 1; i <= 5; i = i + 1) {
            if (contains_text(page, "unblemished pearl mounted in slot #" + i))
                pearls = pearls + 1;
        }
        print("Codpiece unblemished pearls: " + pearls + "/5");
    } else {
        print("Eternity Codpiece not accessible; cannot inspect mounted pearls.");
    }
}

void print_live_list() {
    sea_state s = path_state();
    print("===== sea_start.ash | live character report =====", "blue");
    print("Player: " + my_name());
    print("Path: " + my_path());
    print("Difficulty: " + difficulty_type());
    print("Class: " + my_class());
    print("Moon sign: " + my_sign());
    print("Adventures: " + s.adventures_available);
    print("Liver: " + my_inebriety() + "/" + inebriety_limit());
    print("Spleen: " + my_spleen_use() + "/" + spleen_limit());
    print("Stomach: " + my_fullness() + "/" + fullness_limit());
    print("King freed (kingLiberated): " + s.king_freed);
    print("Interaction restrictions cleared (can_interact): " + s.interaction_unlocked);
    print("Turns spent this ascension: " + s.turns_spent);
    print("Adventures available: " + s.adventures_available);
    print("uts_postloopCommand: " + get_property(POSTLOOP_PREF));
    print_astral_inventory();
    print_codpiece_gems();
    print("===============================================", "blue");
}

void set_auto_recovery() {
    // Persistent user-requested defaults; intentionally not restored afterward.
    if (get_property("hpAutoRecovery") != "0.65")
        set_property("hpAutoRecovery", "0.65");
    if (get_property("hpAutoRecoveryTarget") != "0.95")
        set_property("hpAutoRecoveryTarget", "0.95");
    if (get_property("mpAutoRecovery") != "0.65")
        set_property("mpAutoRecovery", "0.65");
    if (get_property("mpAutoRecoveryTarget") != "0.95")
        set_property("mpAutoRecoveryTarget", "0.95");
    print("Auto-recovery targets: HP/MP 65% -> 95%", "green");
}

void prepare_meatcar() {
    item car = $item[bitchin' meatcar];
    if (item_amount(car) > 0) {
        print("Bitchin' meatcar is already in inventory.");
        return;
    }
    print("Attempting to make one bitchin' meatcar...");
    if (create(1, car)) print("Bitchin' meatcar created.", "green");
    else print("Could not create a bitchin' meatcar; continuing.", "orange");
}

void prepare_cook() {
    familiar cook = $familiar[Shorter-Order Cook];
    item plate = $item[blue plate];
    if (!have_familiar(cook)) {
        print("Shorter-Order Cook unavailable; skipping blue plate.", "orange");
        return;
    }
    if (familiar_equipped_equipment(cook) == plate) {
        print("Shorter-Order Cook already has blue plate.");
        return;
    }
    if (item_amount(plate) == 0) {
        print("Blue plate not in current inventory; skipping equip.", "orange");
        return;
    }
    if (!equip(cook, plate))
        print("Could not equip blue plate on Shorter-Order Cook.", "orange");
}

void prepare_mcd() {
    // 11 is valid only with access to Little Canadia. Attempting it
    // elsewhere can abort KoLmafia instead of returning false.
    int desired = 10;
    if (canadia_available()) desired = 11;
    if (current_mcd() == desired) {
        print("MCD already at " + desired);
        return;
    }
    if (change_mcd(desired) && current_mcd() == desired) {
        print("MCD set to " + desired + ".", "green");
        return;
    }
    print("Unable to set MCD to " + desired + "; current=" + current_mcd(), "orange");
}

void log_transition(string stage) {
    sea_state s = path_state();
    print("sea_start " + stage + ": turncount=" + s.turns_spent +
        ", adventures=" + s.adventures_available +
        ", kingFreed=" + s.king_freed +
        ", canInteract=" + s.interaction_unlocked, "blue");
    // Retain per-stage values for later inspection without modifying KoL status.
    set_property("seaStar_lastStage", stage);
    set_property("seaStar_lastTurns", to_string(s.turns_spent));
    set_property("seaStar_lastAdventures", to_string(s.adventures_available));
}

void don_newlife_sea(boolean run_postloop) {
    log_transition("don_newlife_sea begin");
    prepare_meatcar();
    prepare_cook();
    prepare_mcd();
    set_auto_recovery();

    if (item_amount($item[autumn-aton]) > 0) {
        print("Autumn-aton found; calling fallbot.ash...");
        if (!cli_execute("call fallbot.ash")) {
            print("fallbot.ash did not complete; stopping before postloop.", "red");
            return;
        }
    } else {
        print("No autumn-aton in current inventory; skipping fallbot.");
    }

    // UnderTheSea's full loop already runs postloop and invokes FARMING_COMMAND.
    // Running postloop a second time could repeat the farm command and spend
    // postloop resources twice. The already-finished branch below explicitly
    // calls postloop; the freshly-completed full-loop branch does not.
    if (!run_postloop) {
        print("Postloop already handled by the completed UnderTheSea full run.", "green");
        return;
    }
    print("Running UnderTheSea postloop -> " + FARMING_COMMAND);
    log_transition("before UnderTheSea postloop");
    if (!cli_execute("UnderTheSea postloop")) {
        print("UnderTheSea postloop failed or was interrupted.", "red");
        return;
    }
    log_transition("after UnderTheSea postloop");
}

// Only manually use this after a hard kill, or let the next run detect it.
// Never clobber a different command installed by someone else meanwhile.
boolean restore_pending() {
    if (!to_boolean(get_property(PENDING_PREF))) return true;
    string current = get_property(POSTLOOP_PREF);
    string backup = get_property(BACKUP_PREF);
    if (current != FARMING_COMMAND && current != backup) {
        print("Recovery needs manual review: uts_postloopCommand was changed externally.", "red");
        print("Saved original: " + backup);
        print("Current: " + current);
        return false;
    }
    set_property(POSTLOOP_PREF, backup);
    set_property(PENDING_PREF, "false");
    print("Recovered previous uts_postloopCommand: " + backup, "green");
    return true;
}

void run_sea_start() {
    sea_state s = path_state();
    print_live_list();
    log_transition("start");

    // Completion means both King liberated and interaction restrictions cleared.
    // NOTE: king freed + STILL in Ronin is not a normal achievable end state.
    if (s.king_freed && s.interaction_unlocked) {
        don_newlife_sea(true);
        return;
    }

    if (s.king_freed != s.interaction_unlocked) {
        print("King liberation and interaction status disagree. Refresh status manually", "red");
        print("and inspect the current path before allowing automatic adventuring.", "red");
        return;
    }
    if (s.adventures_available <= 2) {
        print("At most 2 adventures available and the run is not complete; stopping.", "orange");
        return;
    }

    print("Run unfinished: refresh all -> breakfast -> UnderTheSea.");
    if (!cli_execute("refresh all")) {
        print("refresh all failed; stopping.", "red");
        return;
    }
    if (!cli_execute("breakfast")) {
        print("breakfast failed; stopping.", "red");
        return;
    }
    log_transition("before UnderTheSea full run");
    if (!cli_execute("UnderTheSea")) {
        print("UnderTheSea failed or was interrupted; stopping.", "red");
        return;
    }

    s = path_state();
    log_transition("after UnderTheSea full run");
    if (s.king_freed && s.interaction_unlocked) {
        don_newlife_sea(false);
    } else {
        print("UnderTheSea returned without a freed King + cleared restrictions; no aftercore handoff.", "orange");
    }
}

// Varargs avoids KoLmafia requesting a mandatory argument when launched
// with no arguments from the script menu or CLI.
void main(string... modes) {
    string mode = "";
    if (count(modes) > 0) mode = modes[0];
    if (mode == "status") {
        print_live_list();
        return;
    }
    if (mode == "restore") {
        restore_pending();
        return;
    }
    if (mode != "") {
        print("Usage: call sea_start.ash [status|restore]", "red");
        return;
    }
    if (to_boolean(get_property(PENDING_PREF))) {
        print("Found a previous unfinished preference override.", "orange");
        // Recover safely, but do not proceed automatically after an unknown prior stop.
        restore_pending();
        print("Re-run sea_start.ash to start the workflow after reviewing recovery.");
        return;
    }

    // Only the active run changes state; status and restore never refresh or wait.
    set_property("choiceAdventure1564", "1");
    if (!cli_execute("refresh all")) {
        print("refresh all failed; stopping before sea-start workflow.", "red");
        return;
    }
    wait(5);

    string previous_pref = get_property(POSTLOOP_PREF);
    set_property(BACKUP_PREF, previous_pref);
    set_property(PENDING_PREF, "true");
    try {
        set_property(POSTLOOP_PREF, FARMING_COMMAND);
        run_sea_start();
    }
    finally {
        set_property(POSTLOOP_PREF, previous_pref);
        set_property(PENDING_PREF, "false");
        print("Restored uts_postloopCommand: " + previous_pref, "green");
    }
}
