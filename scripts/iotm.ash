// ─── GLOBALS ──────────────────────────────────────────────────────────────────
int uniInt, uniAdv, pearlsDoneToday;
string clan = get_clan_name();
int estimatedTurns;

// ─── UTILITIES ────────────────────────────────────────────────────────────────

int count_substring(string text, string sub) {
    int count = 0;
    int pos = 0;
    while (true) {
        pos = index_of(text, sub, pos);
        if (pos == -1) break;
        count += 1;
        pos += length(sub);
    }
    return count;
}

boolean [monster] haveLocketMonster = get_locket_monsters();

// Returns true if the item exists anywhere accessible (inventory, equipped, storage, closet)
boolean have_item(item it) {
    return item_amount(it) > 0
        || have_equipped(it)
        || storage_amount(it) > 0
        || closet_amount(it) > 0;
}

// Returns the number of chamois available in the clan slime tube
int chamoixAmount() {
    matcher m = create_matcher("There are (\\d+) chamoi", visit_url("clan_slimetube.php?action=bucket"));
    return m.find() ? to_int(m.group(1)) : 0;
}

// Returns session log text from the current turn onward
string LastAdvTxt() {
    string lastlog = session_logs(1)[0];
    int nowmark = max(
        last_index_of(lastlog, "[" + my_turncount() + "]"),
        last_index_of(lastlog, "[" + (my_turncount() + 1) + "]")
    );
    return substring(lastlog, nowmark);
}

// ─── NONCOMBAT FORCER ─────────────────────────────────────────────────────────

void NCforce() {
    // Use != "true" rather than == "false" so unset property is handled safely
    if (get_property("noncombatForcerActive") != "true") {
        if (to_int(get_property("_aprilBandTubaUses")) < 3) {
            cli_execute("aprilband play tuba");
        } else {
            while (to_int(get_property("_cinchUsed")) > 40
                && to_int(get_property("timesRested")) < total_free_rests()) {
                cli_execute("unequip hat; equip apriling band helmet; camp rest free");
            }
            if (to_int(get_property("_cinchUsed")) <= 40) {
                equip($slot[acc3], $item[cincho de mayo]);
                use_skill($skill[Cincho: Fiesta Exit]);
            }
        }
    }
}

// ─── TRICK OR TREAT ───────────────────────────────────────────────────────────

void candy(string action) {
    int houseToVisit = index_of(get_property("_trickOrTreatBlock"), "D");
    visit_url("place.php?whichplace=town&action=town_trickortreat");
    visit_url("choice.php?whichchoice=804&option=3&whichhouse=" + houseToVisit);
    run_combat();
}

// ─── CYBERZONE FREE FIGHTS ────────────────────────────────────────────────────

void cyberzone() {
    while (to_int(get_property("_cyberFreeFights")) < 10) {
        maximize("item drop", false);

        if (!contains_text(get_property("banishedPhyla"), "construct")) {
            adv1($location[cyberzone 1], 0, "");
            continue;
        }

        // Scout zones we haven't identified yet
        if (get_property("_cyberZone1Hacker") == "") {
            adv1($location[cyberzone 1], 0, "");
            set_property("_cyberZone1Hacker", last_monster());
            continue;
        }
        if (get_property("_cyberZone2Hacker") == ""
            && get_property("_cyberZone1Hacker") != "greyhat hacker") {
            adv1($location[cyberzone 2], 0, "");
            set_property("_cyberZone2Hacker", last_monster());
            continue;
        }
        if (get_property("_cyberZone3Hacker") == ""
            && get_property("_cyberZone1Hacker") != "greyhat hacker"
            && get_property("_cyberZone2Hacker") != "greyhat hacker") {
            adv1($location[cyberzone 3], 0, "");
            set_property("_cyberZone3Hacker", last_monster());
            continue;
        }

        // Adventure in whichever zone has the target hacker
        location [monster] hackerZone = {
            to_monster(get_property("_cyberZone1Hacker")): $location[cyberzone 1],
            to_monster(get_property("_cyberZone2Hacker")): $location[cyberzone 2],
            to_monster(get_property("_cyberZone3Hacker")): $location[cyberzone 3]
        };
        foreach mon in $monsters[greyhat hacker, bluehat hacker, greenhat hacker, redhat hacker, purplehat hacker] {
            if (hackerZone contains mon) {
                adv1(hackerZone[mon], 0, "");
                break;
            }
        }
    }
}

// ─── BANISH UTILITIES ─────────────────────────────────────────────────────────

record ban {
    string pref;
    skill banSkill;
};

ban [item] banMap = {
    $item[spring shoes]:        new ban("Spring Kick",           $skill[spring kick]),
    $item[monodent of the sea]: new ban("Sea \\*dent",           $skill[Sea *dent: Throw a Lightning Bolt]),
    $item[Heartstone]:          new ban("Heartstone %banish",    $skill[Heartstone: %banish]),
    $item[none]:                new ban("snokebomb",             $skill[snokebomb]),
};

// Returns all locations a given monster can appear in
location [int] monster_found_in(monster m) {
    location [int] output;
    foreach o in $locations[]
        if (o.get_location_monsters() contains m)
            output[count(output)] = o;
    return output;
}

// Returns the monster currently banished by a given banisher string
monster banished(string banisher) {
    matcher m = create_matcher(
        ":([A-Za-z'-]+(?: [A-Za-z'-]+){0,3}):" + banisher,
        get_property("banishedMonsters")
    );
    return m.find() ? to_monster(m.group(1)) : $monster[none];
}

// Returns true if the given banisher has been used on a monster at your current location
boolean banishUsedAtYourLocation(string banisher) {
    foreach num in monster_found_in(banished(banisher)) {
        if (monster_found_in(banished(banisher))[num] == my_location())
            return true;
    }
    return false;
}

// Equips the appropriate banish gear for a location and sets the slot override property.
// NOTE: has the side effect of setting an Override property — callers should be aware.
item banishGear(location loc) {
    item it;
    foreach ite in $items[spring shoes, monodent of the sea, Heartstone] {
        if (appearance_rates(loc)[banished(banMap[ite].pref)] > 0) {
            it = ite;
            break;
        }
    }
    set_property(to_string(to_slot(it)) + "Override", ", equip " + it);
    return it;
}

// Returns the combat banish skill for the first equipped banish item
// whose target is no longer appearing at your location
skill combatBan() {
    foreach ite in $items[spring shoes, monodent of the sea, Heartstone] {
        if (have_equipped(ite)
            && appearance_rates(my_location())[banished(banMap[ite].pref)] == 0) {
            return banMap[ite].banSkill;
        }
    }
    return $skill[none];
}

// ─── EVERFULL DART ────────────────────────────────────────────────────────────

// Returns true if bullseye perks are fully stacked or adventures are low
boolean bullseyeReady() {
    if (my_adventures() < 20)
        return true;
    string perks = get_property("everfullDartPerks");
    return (contains_text(perks, "You are less impressed by bullseyes")
            && contains_text(perks, "Bullseyes do not impress you much"))
        || count_substring(perks, "Bullseyes do not impress you much") >= 2
        || count_substring(perks, "You are less impressed by bullseyes") >= 2;
}

void darts() {
    while (to_int(get_property("_dartsLeft")) > 0
        && have_equipped($item[everfull dart holster])
        && current_round() > 0) {
        if (contains_text(get_property("everfullDartPerks"), "Butt")) {
            matcher m = create_matcher("(\\d+):butt", get_property("_currentDartboard"));
            if (!m.find()) break;
            use_skill(to_skill(to_int(m.group(1))));
        } else {
            use_skill($skill[Darts: Throw at %part1]);
        }
    }
}

// ─── BLOOD CUBIC ZIRCONIA COST ────────────────────────────────────────────────

int BCZcost(string BCZskill) {
    int cast = to_int(get_property("_bcz" + BCZskill));
    if (cast == 12) return 420000;
    if (cast > 12) cast -= 1;
    int castMathFloor = floor(cast / 3);
    int castMathModulo = cast % 3;
    int substatBase;
    switch (castMathModulo) {
        case 0: substatBase = 11; break;
        case 1: substatBase = 23; break;
        case 2: substatBase = 37; break;
    }
    // Pattern: 11, 23, 37, 110, 230, 370, ... 13th cast handled separately but unreachable
    return substatBase * 10 ** ((cast < 12 || (cast > 12 && castMathModulo == 0))
        ? castMathFloor : castMathFloor + 1);
}

// ─── TRAINSET ─────────────────────────────────────────────────────────────────

void trainset() {
    int pos = to_int(get_property("trainsetPosition")) % 8;
    int [int] slots = {
        (pos)     % 8: 8,   // next station
        (pos + 1) % 8: 1,
        (pos + 2) % 8: 15,
        (pos + 3) % 8: 20,
        (pos + 4) % 8: 3,
        (pos + 5) % 8: 7,
        (pos + 6) % 8: 2,
        (pos + 7) % 8: 19
    };
    visit_url("choice.php?forceoption=0?whichchoice=1485&option=1"
        + "&slot%5B0%5D=" + slots[0]
        + "&slot%5B1%5D=" + slots[1]
        + "&slot%5B2%5D=" + slots[2]
        + "&slot%5B3%5D=" + slots[3]
        + "&slot%5B4%5D=" + slots[4]
        + "&slot%5B5%5D=" + slots[5]
        + "&slot%5B6%5D=" + slots[6]
        + "&slot%5B7%5D=" + slots[7]);
}

// ─── CODPIECE ─────────────────────────────────────────────────────────────────

void codpiece(string input) {
    visit_url("inventory.php?action=docodpiece");
    if (input == "none") {
        for slots from 5 to 1 {
            visit_url("choice.php?whichchoice=1588&option=2&which=" + slots);
        }
    } else {
        string [int] slots = split_string(input, ",");
        foreach num in slots {
            visit_url("choice.php?whichchoice=1588&option=1&which=" + (num + 1)
                + "&iid=" + to_int(to_item(slots[num])));
        }
        // Verify all slots mounted correctly
        string verify = visit_url("inventory.php?action=docodpiece");
        foreach num in slots {
            if (!contains_text(verify, to_item(slots[num]) + " mounted in slot #" + (num + 1)))
                abort("Codpiece slot incorrect");
        }
    }
    cli_execute("refresh all");
}

// ─── LEPRECONDO ───────────────────────────────────────────────────────────────

string [int] lepRoomToNum = {
    1:"buckets of concrete",        2:"thrift store oil painting",
    3:"boxes of old comic books",   4:"second-hand hot plate",
    5:"beer cooler",                6:"free mattress",
    7:"gigantic chess set",         8:"UltraDance karaoke machine",
    9:"cupcake treadmill",          10:"beer pong table",
    11:"padded weight bench",       12:"internet-connected laptop",
    13:"sous vide laboratory",      14:"programmable blender",
    15:"sensory deprivation tank",  16:"fruit-smashing robot",
    17:"ManCave™ sports bar set",   18:"couch and flatscreen",
    19:"kegerator",                 20:"fine upholstered dining table set",
    21:"whiskeybed",                22:"high-end home workout system",
    23:"complete classics library", 24:"ultimate retro game console",
    25:"Omnipot",                   26:"fully-stocked wet bar",
    27:"four-poster bed"
};

void leprecondo(string input) {
    string [int] rooms = split_string(input, ",");
    int [int] lepRoom;
    int count;
    foreach num in rooms {
        int val = to_int(rooms[num]);
        string discovered = get_property("leprecondoDiscovered");
        // Two-digit room numbers need a plain contains; single-digit need comma guards
        // to avoid matching "1" inside "10", "11", etc.
        boolean found = (val >= 10)
            ? contains_text(discovered, rooms[num])
            : contains_text(discovered, "," + rooms[num] + ",");
        if (found) {
            lepRoom[count] = val;
            count += 1;
        }
    }
    cli_execute("leprecondo furnish "
        + lepRoomToNum[lepRoom[0]] + ","
        + lepRoomToNum[lepRoom[1]] + ","
        + lepRoomToNum[lepRoom[2]] + ","
        + lepRoomToNum[lepRoom[3]]);
}

// ─── UNIVERSE CALCULATOR ──────────────────────────────────────────────────────
// Finds the adventure count at which the universe alignment hits 69.
// Sets globals uniInt and uniAdv as a side effect and also returns uniAdv.

int universe() {
    int [string] sign = {
        "Mongoose":1, "Wallaby":2, "Vole":3,    "Platypus":4,
        "Opossum":5,  "Marmot":6,  "Wombat":7,  "Blender":8,
        "Packrat":9,  "Bad Moon":10
    };
    for y from 0 to my_adventures() {
        for x from 1 to 99 {
            if (((x + my_ascensions() + sign[my_sign()])
                * (my_spleen_use() + my_level())
                + (my_adventures() - y)) % 100 == 69) {
                uniInt = x;
                uniAdv = my_adventures() - y;
                break;
            }
        }
        if (uniInt > 0) break;
    }
    return uniAdv;
}

// ─── DELAY CHECKER ────────────────────────────────────────────────────────────
// Returns true if there are free fight resources available to burn for delay.

boolean delay() {
    if (to_int(get_property("_snokebombUsed")) < 3)
        return true;
    if (have_effect($effect[everything looks green]) == 0)
        return true;
    if (item_amount($item[&quot;I Voted!&quot; sticker]) > 0
        && total_turns_played() % 11 == 1
        && to_int(get_property("_voteFreeFights")) < 3)
        return true;
    if (total_turns_played() >= to_int(get_property("clubEmNextWeekMonsterTurn")) + 8
        && get_property("clubEmNextWeekMonster") != "")
        return true;
    // Fixed: was incorrectly checking clubEmNextWeekMonster for the VHS tape condition
    if (total_turns_played() >= to_int(get_property("spookyVHSTapeMonsterTurn")) + 8
        && get_property("spookyVHSTapeMonster") != "")
        return true;
    return false;
}

// ─── CHAMOIS / CAMO ───────────────────────────────────────────────────────────

void camo() {
    if (chamoixAmount() < 1) {
        string current_clan = get_clan_id();
        try {
            visit_url("showclan.php?whichclan=2046992052&action=joinclan&confirm=on");
            if (chamoixAmount() < 10)
                abort("low on chamois");
            visit_url("clan_slimetube.php?action=chamois");
        } finally {
            visit_url("showclan.php?whichclan=" + current_clan + "&action=joinclan&confirm=on");
        }
    } else {
        visit_url("clan_slimetube.php?action=chamois");
    }
}

// ─── BASEBALL ─────────────────────────────────────────────────────────────────

// Fills 2 prereq slots immediately before a given outcome slot
void fillPrereqs(int outcomeSlot, string pitchType) {
    int filled = 0;
    int before = outcomeSlot - 1;
    while (filled < 2 && before >= 1) {
        if (get_property("pitchNum" + before) == "") {
            set_property("pitchNum" + before, pitchType);
            filled += 1;
        }
        before -= 1;
    }
    if (filled < 2)
        abort("Not enough open slots to fill prereqs for outcome at slot " + outcomeSlot);
}

int baseballPlayers(){
    string [int] lineup = split_string(get_property("baseballTeam"), ",");
    int players;
    foreach num in lineup { players = num + 1; }
    return players;
}

void baseballD() {
    string [int] lineup = split_string(get_property("baseballTeam"), ",");
    int players;
    foreach num in lineup { players = num + 1; }
    if (players != 9) return;

    try {
        int bbYR;
        int bbFreeKill;

        // Scan 9→3, take the latest slot for each outcome type
        for x from 9 to 3 {
            if (bbYR == 0 && $strings[745,765,768,762,763] contains lineup[x-1]) {
                bbYR = x;
                set_property("pitchNum" + x, "1");
            }
            if (bbFreeKill == 0 && $strings[2499] contains lineup[x-1]) {
                bbFreeKill = x;
                set_property("pitchNum" + x, "3");
            }
        }

        if (bbYR == 0 && bbFreeKill == 0) {
            print("No yellow ray or free kill pitchers in lineup, skipping.", "red");
            return;
        }

        // Fill prereqs for the later outcome first to avoid slot collisions
        int [int] outcomeSlots;
        string [int] outcomePitches;
        if (bbYR >= bbFreeKill) {
            outcomeSlots[0] = bbYR;       outcomePitches[0] = "1";
            outcomeSlots[1] = bbFreeKill; outcomePitches[1] = "3";
        } else {
            outcomeSlots[0] = bbFreeKill; outcomePitches[0] = "3";
            outcomeSlots[1] = bbYR;       outcomePitches[1] = "1";
        }
        foreach i in outcomeSlots {
            if (outcomeSlots[i] > 0)
                fillPrereqs(outcomeSlots[i], outcomePitches[i]);
        }

        // Execute all 9 pitches then confirm
        visit_url("inventory.php?pwd&action=pball&pwd=" + my_hash() + "&action=pball", false);
        for x from 1 to 9 {
            string pitch = get_property("pitchNum" + x);
            run_choice(pitch == "" ? 4 : to_int(pitch));
        }
        run_choice(6);

    } finally {
        for x from 3 to 9 {
            set_property("pitchNum" + x, "");
        }
    }
}

// ─── FINISHER ─────────────────────────────────────────────────────────────────
// Resets all script overrides and hands control back to garbo

void finisher() {
    set_property("script", "");
    set_property("subscript", "");
    set_property("afterAdventureScript", "");
    set_property("choiceAdventureScript", "garbo_choice.js");
    set_property("betweenBattleScript", "");
    foreach slotName in $strings[max, fam, hat, main, off, back, shirt, pants, acc1, acc2, acc3] {
        set_property(slotName + "Override", "");
    }
}
