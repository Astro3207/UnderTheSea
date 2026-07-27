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

// Use a skill if it appears as an option on the current page
void use_if_have_skill(string page_text, skill sk) {
    if (contains_text(page_text, to_string(sk)))
        use_skill(sk);
}

// Returns true if the item exists anywhere accessible (inventory, equipped, storage, closet)
boolean have_item(item it) {
    return item_amount(it) > 0
        || have_equipped(it)
        || storage_amount(it) > 0;
}

// ─── WANTED MONSTER PER ZONE ──────────────────────────────────────────────────
// Which monster we are actually trying to reach in each zone. Three separate
// monster-pickers read this table -- the Peridot of Peril (choice 1557), Map the
// Monsters (choice 1435) and the Time-Spinner (choice 1196) -- so keeping one
// copy here means they can never disagree about the target. It lives in iotm.ash
// rather than in the choice script because the main script needs it too.
int [location] wantedMonster = {
    $location[An Octopus's Garden]:                 740,   // Neptune flytrap
    $location[The Wreck of the Edgar Fitzsimmons]:  745,   // unholy diver
    $location[The Sleazy Back Alley]:               159,
    $location[The Haunted Pantry]:                  145,
    $location[The Overgrown Lot]:                   1752,
    $location[The Coral Corral]:                    775,   // sea cow
    $location[The Marinara Trench]:                 762,
    $location[Anemone Mine]:                        765,
    $location[The Dive Bar]:                        768,
    $location[Cyberzone 1]:                         2458,
    $location[Mer-kin Library]:                     840,   // Mer-kin researcher
    $location[the mer-kin outpost]:                 773,
    $location[the caliginous abyss]:                1373,
    $location[mer-kin elementary school]:           838,   // Mer-kin teacher
    $location[The Outskirts of Cobb's Knob]:        152,
    $location[Madness Bakery]:                      1750
};

// ─── FOURTH OF MAY COSPLAY SABER ──────────────────────────────────────────────
// The saber is handed to you automatically at the start of a run, so there is
// nothing to pull or buy. "Use the Force" leaves combat without spending an
// adventure and hands over the monster's non-conditional drops.
//
// That makes it a drop-farming tool, NOT a general free kill:
//   - it forfeits the combat win, so it never advances a quest counter, and
//   - it does not burn a turn, so it cannot advance a turns_spent gate.
// The Mer-kin Outpost is the trap: the lockkey needs ~25 turns actually spent
// there, so forcing your way out would stall that loop forever. Anywhere we are
// looping purely on an item count, it is a straight turn saving.

boolean saberReady() {
    return have_item($item[Fourth of May Cosplay Saber])
        && to_int(get_property("_saberForceUses")) < 5;
}

// False in zones that gate progress on turns spent rather than on drops.
boolean saberZone(location loc) {
    return !($locations[The Mer-Kin Outpost] contains loc);
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

boolean pullSequence(item it) {
    if (pulls_remaining() == 0)
        return false;
    if (!contains_text(get_property("_roninStoragePulls"), to_int(it))) {
        if (storage_amount(it) == 0){
            if (mall_price(it) > to_int(get_property("autoBuyPriceLimit"))){
                if (!user_confirm("Price of " + it + " exeeds autoBuyPriceLimit, skip?"))
                    abort("Price of " + it + " exeeds autoBuyPriceLimit");
            }
            buy_using_storage(it);
        }
        return take_storage(1, it);
    }
    return false;
}

// ─── MAP THE MONSTERS ─────────────────────────────────────────────────────────
// Comprehensive Cartography gives 3 casts a day. Each turns the next fight in a
// zone into a monster of your choosing -- the same job as the Peridot of Peril,
// answered in UnderTheSea_Choice.ash from the same wantedMonster table.
//
// The Peridot is once per zone per day, so these are the extra charges for when
// you still need more of a drop after the Peridot there is spent. Charges are
// scarce, so they go to the longest odds first. Chance of drawing the monster we
// actually want, per combats.txt:
//
//     The Wreck of the Edgar Fitzsimmons   unholy diver       1 in 5
//     An Octopus's Garden                  Neptune flytrap    1 in 4
//     The Coral Corral                     sea cow            1 in 3
//
// The Mer-kin Outpost is left out for the same reason the saber is: the lockkey
// needs ~25 turns actually spent there, so skipping to a chosen monster and
// shortening the zone saves nothing.

boolean mapReady() {
    return have_skill($skill[Map the Monsters])
        && to_int(get_property("_monstersMapped")) < 3
        && get_property("mappingMonsters") == "false";
}

boolean mapZone(location loc) {
    return $locations[The Wreck of the Edgar Fitzsimmons,
        An Octopus's Garden, The Coral Corral] contains loc;
}

// Only cast once the Peridot's charge for this zone is gone, so the two do not
// both spend themselves picking the same monster.
void mapMonster(location loc) {
    if (!mapReady() || !mapZone(loc))
        return;
    if (available_amount($item[peridot of peril]) > 0
        && !contains_text(get_property("_perilLocations"), to_string(to_int(loc))))
        return;
    use_skill($skill[Map the Monsters]);
}

// Roughly how many noncombat forces this account can field. Deliberately does
// NOT count the Pill Keeper: this is the number we use to decide whether the
// free pill needs reserving for Sneakisol, so counting it would be circular.
int NCForceEstimate(){
    int force = 2;
    if (have_item($item[Apriling band tuba]))
        force += 3;
    if (have_item($item[McHugeLarge left ski]))
        force += 3;
    if (have_item($item[Cincho de Mayo]))
        force += 7;
    if (have_item($item[Jurassic Parka]))
        force += 5;
    return force;
}

// ─── EIGHT DAYS A WEEK PILL KEEPER ────────────────────────────────────────────
// The first pill each day is free; every one after costs 3 spleen, which we need
// for fish sauce to stay Fishy, so only ever take the free one.
//
// Fidoxene is the default. Familiars start an ascension at very low weight and
// the script leans on Grouper Groupie (underwater,item0) for +item nearly
// everywhere, so 30 turns of "every familiar is at least 20 lbs" cuts farming
// turns directly. Chest Mimic and Jill-of-All-Trades are item0 as well.
//
// Explodinall is deliberately not used. It reads like a forced-drop effect, but
// it is a yellow ray: it grants Everything Looks Yellow for 29 turns, which
// collides with the Jurassic Parka dilophosaur ray the script already fires at
// the unholy diver, so it would cost more than it gives.
void pillKeeper(string pill) {
    if (!have_item($item[Eight Days a Week Pill Keeper]))
        return;
    if (get_property("_freePillKeeperUsed") != "false")
        return;
    cli_execute("pillkeeper " + pill);
}

// ─── VAMPYRIC CLOAKE ──────────────────────────────────────────────────────────
// Handed to you automatically at the start of a run, so there is nothing to pull.
// Two separate wins, and the passive one is easy to overlook:
//
//   1. The cloake itself is a back item worth a flat +15% Item Drops. The
//      maximizer will normally find that on its own, but the back slot has to
//      actually stay free for it, and we want it pinned anyway for reason 2.
//   2. "Become a Bat" grants Bat-Adjacent Form, +50% Item Drops, for one
//      adventure. It is an in-combat skill, so it costs no turn, and the three
//      cloake forms share 10 uses per day.
//
// Only one form may be used per combat (they stack only in free fights), and we
// never want the other two -- Wolfish Form is +muscle/+meat and Misty Form is
// elemental resistance, neither of which shortens a farming loop -- so all 10
// charges go to Become a Bat.
//
// The form is granted mid-combat and item drops are rolled when the combat ends,
// so the +50% applies to the fight it is cast in. That is the one link in this
// chain taken from how every other mid-combat +item effect behaves rather than
// from a direct spade, so if drops ever look wrong, check here first.

boolean cloakeReady() {
    return have_item($item[vampyric cloake])
        && to_int(get_property("_vampyreCloakeFormUses")) < 10;
}

// Only the zones we grind purely for a drop count. Anywhere gated on turns spent
// or on finding a noncombat, a bigger item bonus buys nothing, and there are
// only 10 charges to spread across the run.
boolean cloakeZone(location loc) {
    return $locations[The Wreck of the Edgar Fitzsimmons, An Octopus's Garden,
        The Coral Corral, Mer-kin Library, Mer-kin Elementary School] contains loc;
}

// Pins the cloake into the back slot so the skill is actually available in
// combat. Callers set gear up before adv(), so the target zone is passed in
// explicitly -- my_location() is still the previous zone at that point.
string cloakeEquip(location loc) {
    if (cloakeReady() && cloakeZone(loc))
        return "vampyric cloake,";
    return "";
}

// Cast from the CCS at the top of every round. Cheap to call repeatedly: once
// the form is up, have_effect() short-circuits it, which also enforces the
// one-form-per-combat rule for free.
void becomeBat(string page_text) {
    if (!cloakeReady() || !cloakeZone(my_location()))
        return;
    if (have_effect($effect[Bat-Adjacent Form]) > 0)
        return;
    if (!have_equipped($item[vampyric cloake]))
        return;
    if (!contains_text(page_text, "Become a Bat"))
        return;
    use_skill($skill[Become a Bat]);
}

// ─── GOD LOBSTER ──────────────────────────────────────────────────────────────
// Three free fights a day. Worth being blunt about the size of this one: the
// fights cost no adventure, but they also advance no quest, so on their own they
// save nothing. Everything here rides on one reward.
//
// Winning offers regalia, a blessing, or experience. The blessing depends on
// which piece of regalia the God Lobster is wearing, and exactly one of the six
// is turn-relevant: with God Lobster's Ring equipped you get Silence of the God
// Lobster, -5% combat frequency for 33 adventures.
//
// -5% across the Outpost block is worth roughly a turn, so this is a small win,
// not a large one -- the script already fields around twenty noncombat forces.
// It is included because the fights are free and the downside is zero: with no
// Ring in hand we simply take regalia instead and work toward one, which costs
// nothing and leaves the account better set up for the next run.
//
// The other five blessings are all dead ends here: Wisdom is MP, Intuition is
// stats per fight, Carapace is resistance, Taste is stat gains from food, and
// Color is actively harmful -- it raises combat frequency.
//
// Two costs worth knowing about, neither of which is a turn:
//   - The regalia scales the monster up. With the Ring on it is Scale +20 with
//     30% physical resistance, so the CCS kills it with saucegeyser rather than
//     anything physical. Elemental resistance stays at 0 until the Rod, which we
//     never equip.
//   - Character equipment is left exactly as the previous zone set it. Nothing
//     here calls maximize() or tempEquipment(), so the loop's gear survives the
//     detour untouched; only the familiar changes, and familiars carry their own
//     equipment, so swapping back restores the farming familiar as it was.
// The CCS has a matching guard so that none of this fight's rounds spend the
// previous zone's banishes, free kills, darts or cloake charges.

boolean godLobsterReady() {
    return have_familiar($familiar[God Lobster])
        && to_int(get_property("_godLobsterFights")) < 3;
}

// Called once, immediately before the Outpost hunt, so a Silence blessing covers
// the block it was fetched for rather than expiring on the way there.
void godLobster() {
    if (!godLobsterReady())
        return;
    familiar previous = my_familiar();
    // Bounded by attempt count as well as by the daily counter: if a fight ever
    // fails to register, we back out rather than spin here forever.
    int attempts;
    while (godLobsterReady() && attempts < 3) {
        attempts += 1;
        int before = to_int(get_property("_godLobsterFights"));
        use_familiar($familiar[God Lobster]);
        // The Ring is what turns the blessing into Silence. Without it we are
        // only here to collect regalia, and the choice handler picks that up.
        if (available_amount($item[God Lobster's Ring]) > 0)
            equip($slot[familiar], $item[God Lobster's Ring]);
        visit_url("main.php?fightgodlobster=1");
        run_combat();
        if (to_int(get_property("_godLobsterFights")) == before) {
            print("God Lobster fight did not register, skipping", "red");
            break;
        }
        // Stop after the blessing lands; the remaining fights are worth more
        // banked for a later day than spent on stats we have no gate on.
        if (have_effect($effect[Silence of the God Lobster]) > 0)
            break;
    }
    use_familiar(previous);
}

// ─── TIME-SPINNER ─────────────────────────────────────────────────────────────
// Also handed to you automatically at the start of a run. 10 minutes a day, and
// "Travel to a Recent Fight" costs 3 of them, so 3 uses.
//
// It is NOT a free fight -- the refight costs an adventure. What it buys is
// certainty: instead of spending a turn on a 1-in-4 or 1-in-5 roll for the
// monster we want, we spend a turn on that monster directly. At Fitzsimmons the
// unholy diver is 1 of 5, so each use replaces about five random turns with one.
// That makes it the same trade as Map the Monsters, just paid for with a turn,
// and it stacks on top of the three Map charges rather than competing with them.
//
// The monster has to be in the zone's combat queue, which means it must have
// been encountered in the last five combats there. Rather than guess, we only
// fire immediately after winning against the target in that very zone, which
// guarantees it is queued.
//
// mafia's own "timespinner" CLI command only covers food and pranks, so the
// choice chain is walked by hand: 1195 -> Travel to a Recent Fight -> 1196,
// where the monster is submitted as monid.

boolean timeSpinnerReady() {
    return have_item($item[Time-Spinner])
        && to_int(get_property("_timeSpinnerMinutesUsed")) <= 7
        && my_adventures() > 0;
}

void timeSpinnerRefight(location loc) {
    if (!timeSpinnerReady() || !(wantedMonster contains loc))
        return;
    // Only worth a turn where the target is genuinely rare; these are the same
    // zones Map the Monsters spends its charges on.
    if (!mapZone(loc))
        return;
    if (my_location() != loc || last_monster().id != wantedMonster[loc])
        return;

    visit_url("inv_use.php?whichitem=" + to_int($item[Time-Spinner]) + "&pwd=" + my_hash());
    int travel;
    int backOut;
    foreach num, optionText in available_choice_options() {
        if (contains_text(optionText, "Travel to a Recent Fight"))
            travel = num;
        if (contains_text(optionText, "Maybe Later"))
            backOut = num;
    }
    // Never leave the run parked inside a choice we could not read.
    if (travel == 0) {
        if (backOut > 0)
            run_choice(backOut);
        return;
    }
    run_choice(travel);
    run_choice(1, "monid=" + wantedMonster[loc]);
}

// ─── NONCOMBAT FORCER ─────────────────────────────────────────────────────────

void NCforce() {
    if (get_property("noncombatForcerActive") != "true") {
        if (to_int(get_property("_aprilBandTubaUses")) < 3 && have_item($item[Apriling band tuba])) {
            cli_execute("aprilband play tuba");
        } else if (have_item($item[Cincho de Mayo])){
            while (to_int(get_property("_cinchUsed")) > 40
                && to_int(get_property("timesRested")) < total_free_rests()) {
                cli_execute("unequip hat; equip apriling band helmet; camp rest free");
            }
            if (to_int(get_property("_cinchUsed")) <= 40) {
                equip($slot[acc3], $item[cincho de mayo]);
                use_skill($skill[Cincho: Fiesta Exit]);
            }
        } else if (have_item($item[Eight Days a Week Pill Keeper])
            && get_property("_freePillKeeperUsed") == "false") {
            // Sneakisol has Clara's bell's noncombat-forcing behaviour and is
            // free, so it comes before anything that costs a pull. If the free
            // pill already went on Fidoxene this call is a no-op.
            pillKeeper("sneakisol");
        } else if (!have_item($item[mchugelarge duffel bag]) && !have_item($item[jurassic parka]) && !have_item($item[allied radio backpack])){
            foreach it in $items[Handheld Allied radio, Clara's bell, stench jelly]{
                if (!contains_text(get_property("_roninStoragePulls"), to_int(it))){
                    if (it == $item[Clara's Bell] && storage_amount(it) == 0)
                        continue;
                    if (pulls_remaining() == 0)
                        return;
                    pullSequence(it);
                    if (it == $item[Clara's bell])
                        use (it);
                    else if (it == $item[Handheld Allied radio])
                        cli_execute("alliedradio misc sniper");
                    else if (it == $item[stench jelly])
                        chew(it);
                    break;
                }
            }
        }
    }
}

// ─── TRICK OR TREAT ───────────────────────────────────────────────────────────

void candy(string action) {
    if (action == "fight"){
        int houseToVisit = index_of(get_property("_trickOrTreatBlock"), "D");
        visit_url("place.php?whichplace=town&action=town_trickortreat");
        visit_url("choice.php?whichchoice=80&pwd=" + my_hash() + "&option=3&whichhouse=" + houseToVisit);
        run_combat();
    } else if (action == "treat"){
        while(contains_text(get_property("_trickOrTreatBlock"),"L")){
            int houseToVisit = index_of(get_property("_trickOrTreatBlock"), "L");
            visit_url("place.php?whichplace=town&action=town_trickortreat");
            visit_url("choice.php?whichchoice=804&pwd=" + my_hash() + "&option=3&whichhouse=" + houseToVisit);
        }
    }
}

int [string] clan_to_ID {
    "Hyrule" : 72876,
    "Dread and Final" : 2047010985,
    "Dread Mart" : 2047010683,
    "Dread Outlet Bargain Market" : 2047010572,
    "Dreadleys" : 2047010988,
    "DreadNugget" : 2047010986,
    "Dreadway" : 2047010667,
    "Fart Sauce Annex" : 2047010939
};

void whitelist(string clan){
    visit_url("showclan.php?whichclan="+clan_to_ID[clan]+"&action=joinclan&confirm=on");
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
    matcher m = create_matcher("([^:]+):\\Q" + banisher,
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

// Equips the appropriate banish gear for a location (that hasn't been used yet) and sets the slot override property.
// NOTE: has the side effect of setting an Override property — callers should be aware.
item banishGear(location loc) {
    item it;
    foreach ite in $items[spring shoes, monodent of the sea, Heartstone] {
        if (ite == $item[Heartstone] && get_property("heartstoneBanishUnlocked") == "false")
            continue;
        if (appearance_rates(loc)[banished(banMap[ite].pref)] == 0 && have_item(ite)) {
            it = ite;
            break;
        }
    }
    set_property(to_string(to_slot(it)) + "Override", ", equip " + it);
    print(to_string(to_slot(it)) + "Override");
    return it;
}

// Returns the combat banish skill for the first equipped banish item
// whose target is no longer appearing at your location
skill combatBan() {
    foreach ite in $items[spring shoes, monodent of the sea, Heartstone] {
        if (ite == $item[Heartstone] && get_property("heartstoneBanishUnlocked") == "false")
            continue;
        if (have_equipped(ite)
            && appearance_rates(my_location())[banished(banMap[ite].pref)] == 0) {
            print("Banish item being considered " + ite + " parsed banished monster is " + banished(banMap[ite].pref) + " and the calculated appearance rate at current location is " + appearance_rates(my_location())[banished(banMap[ite].pref)]);
            cli_execute("get banishedMonsters");
            return banMap[ite].banSkill;
        }
    }
    return $skill[none];
}

// ─── EVERFULL DART ────────────────────────────────────────────────────────────
string perks = get_property("everfullDartPerks");
boolean bullseyeReady() {
    int n = count_substring(perks, "25% Better bullseye targeting") + count_substring(perks, "25% better chance to hit bullseyes") + count_substring(perks, "25% More Accurate bullseye targeting");
    return (n >= 2);
}

boolean everfullReady(){
    if (!bullseyeReady())
        return false;
    return (contains_text(perks, "You are less impressed by bullseyes")
            && contains_text(perks, "Bullseyes do not impress you much"))
        || count_substring(perks, "Bullseyes do not impress you much") >= 2
        || count_substring(perks, "You are less impressed by bullseyes") >= 2;
    return true;
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
        string verify = visit_url("inventory.php?action=docodpiece");
        if (!contains_text(verify, " mounted in slot #"))
            return;
        for slots from 1 to 5 {
            if (contains_text(verify," Empty slot #" + slots )){
                continue;
            } else { 
                visit_url("choice.php?whichchoice=1588&option=2&which=" + slots);
            }
        }
    } else {
        string [int] slots = split_string(input, ",");
        foreach num in slots {
            if (available_amount(to_item(slots[num])) == 0 ){
                slots[num] = "";
                continue;
            }
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
    cli_execute("refresh inv");
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
        + lepRoomToNum[lepRoom[3]] + ","
        + lepRoomToNum[lepRoom[2]] + ","
        + lepRoomToNum[lepRoom[1]] + ","
        + lepRoomToNum[lepRoom[0]]);
}

// ─── UNIVERSE CALCULATOR ──────────────────────────────────────────────────────
// Finds the adventure count at which the universe alignment hits 69.
// Sets globals uniInt and uniAdv as a side effect and also returns uniAdv.

int [string] sign = {
    "Mongoose":1, "Wallaby":2, "Vole":3,    "Platypus":4,
    "Opossum":5,  "Marmot":6,  "Wombat":7,  "Blender":8,
    "Packrat":9,  "Bad Moon":10
};

int universe() {
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

boolean free_Run() {
    if (to_int(get_property("_snokebombUsed")) < 3)
        return true;
    if (have_effect($effect[everything looks green]) == 0)
        return true;
    return false;
}

boolean free_Kill(){
    if (have_effect($effect[everything looks red]) == 0 && bullseyeReady())
        return true;
    if (have_effect($effect[everything looks yellow]) == 0)
        return true;
    return false;
}

boolean wanderer() {
    if (total_turns_played() >= to_int(get_property("clubEmNextWeekMonsterTurn")) + 8
        && get_property("clubEmNextWeekMonster") != "")
        return true;
    // Fixed: was incorrectly checking clubEmNextWeekMonster for the VHS tape condition
    if (total_turns_played() >= to_int(get_property("spookyVHSTapeMonsterTurn")) + 8
        && get_property("spookyVHSTapeMonster") != "")
        return true;
        if (item_amount($item[&quot;I Voted!&quot; sticker]) > 0
        && total_turns_played() % 11 == 1
        && to_int(get_property("_voteFreeFights")) < 3)
        return true;
    return false;
}

boolean delay(){
    if (wanderer() || free_Run())
        return true;
    return false;
}

// ─── CHAMOIS / CAMO ───────────────────────────────────────────────────────────

void camo() {
    if (chamoixAmount() < 1) {
        string current_clan = get_clan_id();
        try {
            foreach str in $strings[2046992052,2047010985,2047010683,2047010572,2047010988,2047010986,2047010667]{
                visit_url("showclan.php?whichclan="+ str +"&action=joinclan&confirm=on");
                if (chamoixAmount() >= 1)
                    break;
                if (str == 2047010667)
                    abort("out of chamoix");
            }
            visit_url("clan_slimetube.php?action=chamois");
        } finally {
            visit_url("showclan.php?whichclan=" + current_clan + "&action=joinclan&confirm=on");
        }
    } else {
        visit_url("clan_slimetube.php?action=chamois");
    }
}

// ─── BASEBALL ─────────────────────────────────────────────────────────────────

int baseballPlayers(){
    string [int] lineup = split_string(get_property("baseballTeam"), ",");
    int players;
    foreach num in lineup { players = num + 1; }
    return players;
}

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
void baseballD() {
    string [int] lineup = split_string(get_property("baseballTeam"), ",");
    int players;
    foreach num in lineup { players = num + 1; }
    if (players != 9) return;

    try {
        int YRPitchNum;
        int FKPitchNum;
        int BanishPitchNum;

        // Scan 9→3, take the latest slot for each outcome type
        for x from 9 to 3 {
            if (YRPitchNum == 0 && $strings[745,838,775,773,765,768,762,763] contains lineup[x-1]) {
                YRPitchNum = x;
                set_property("pitchNum" + x, "1");
            }
            if (FKPitchNum == 0 && $strings[2499] contains lineup[x-1]) {
                FKPitchNum = x;
                set_property("pitchNum" + x, "3");
            }
            // Banish (third pitch) only activates if slot 9 is already claimed by another outcome
            if (BanishPitchNum == 0 && $strings[764] contains lineup[x-1]
                && (YRPitchNum == 9 || FKPitchNum == 9)) {
                BanishPitchNum = x;
                set_property("pitchNum" + x, "2");
            }
        }

        if (YRPitchNum == 0 && FKPitchNum == 0) {
            print("No yellow ray or free kill pitchers in lineup, skipping.", "red");
            return;
        }

        // Assigning other pitches
        int [int] pitchOrder   = {1: YRPitchNum, 2: BanishPitchNum, 3: FKPitchNum};
        string [int] pitchChoice = {1: "1", 2: "2",        3: "3"};

        //Ordering pitches from latest to earliest
        for i from 1 to 3 {
            for j from 1 to (3 - i) {
                if (pitchOrder[j] < pitchOrder[j+1]) {
                    int tmpS = pitchOrder[j];   pitchOrder[j]   = pitchOrder[j+1]; pitchOrder[j+1]   = tmpS;
                    string tmpP = pitchChoice[j]; pitchChoice[j] = pitchChoice[j+1]; pitchChoice[j+1] = tmpP;
                }
            }
        }

        foreach i in pitchOrder {
            if (pitchOrder[i] > 0)
                fillPrereqs(pitchOrder[i], pitchChoice[i]);
        }

        visit_url("inventory.php?pwd&action=pball&pwd=" + my_hash() + "&action=pball", false);
        for x from 1 to 9 {
            string pitch = get_property("pitchNum" + x);
            run_choice(pitch == "" ? 4 : to_int(pitch));
        }
        run_choice(6);

    } finally {
        for x from 1 to 9 {
            set_property("pitchNum" + x, "");
        }
    }
}

// ─── FINISHER ─────────────────────────────────────────────────────────────────
// Resets all script overrides and hands control back to garbo
void starter(){
    set_property("hpAutoRecovery",0.75);
    set_property("hpAutoRecoveryTarget",0.95);
    set_property("mpAutoRecovery",0.25);
    set_property("mpAutoRecoveryTarget",0.3);
    set_auto_attack(0);
    set_property("battleAction", "custom combat script");
    buffer ccs = "consult unlockerCCS.ash \n abort";
        write_ccs(ccs, "CCCS");
    set_ccs ("CCCS");
    set_property("betweenBattleScript","preadventure.ash");
    set_property("afterAdventureScript","postadventure.ash");
    set_property("choiceAdventureScript", "generalChoice.ash");
}
void finisher() {
    set_property("script", "");
    set_property("subscript", "");
    set_property("afterAdventureScript", "");
    set_property("choiceAdventureScript", "garbo_choice.js");
    set_property("betweenBattleScript", "");
    foreach slotName in $strings[max, fam, hat, main, weapon, off, back, shirt, pants, acc1, acc2, acc3, famEquip] {
        set_property(slotName + "Override", "");
    }
}
