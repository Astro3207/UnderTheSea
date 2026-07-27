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

// One-line progress marker printed before every significant action, so a
// broken run's log shows exactly where it was.
void step(string msg) {
    print("UTS: " + msg, "blue");
}

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

// Like have_item(), but also sees gear equipped on terrarium familiars,
// which have_item() misses.
boolean have_item_anywhere(item it) {
    if (have_item(it))
        return true;
    foreach fam in $familiars[] {
        if (have_familiar(fam) && familiar_equipped_equipment(fam) == it)
            return true;
    }
    return false;
}

// A function, not a global set by initialization(): the CCS runs in its own
// interpreter where initialization() never executes, so a global set there
// would read as its default.
boolean lowShiny() {
    return !have_item($item[2002 Mr. Store Catalog])
        && !have_item($item[cursed monkey's paw])
        && !have_item($item[august scepter]);
}

// The 9-sheet vocabulary grind is live. Mirrors getCheatsheet()'s loop
// condition in UnderTheSea.ash.
boolean cheatsheetsNeeded() {
    return item_amount($item[mer-kin cheatsheet]) < 9
        && get_property("merkinVocabularyMastery") == "0";
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

// Need-driven wrapper the three pickers call. The cheatsheet is the monitor's
// drop, not the teacher's, so the school targets the monitor while the sheet
// grind is live and falls back to the static table otherwise.
int zoneTarget(location loc) {
    if (loc == $location[mer-kin elementary school] && cheatsheetsNeeded())
        return 852;   // Mer-kin monitor
    if (wantedMonster contains loc)
        return wantedMonster[loc];
    return 0;
}

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

// ─── DETERMINISTIC DIVER PLAN ─────────────────────────────────────────────────
// Use the Force (option 3) forces every NON-CONDITIONAL drop at 100%, without
// winning and without spending the turn. Per mafia's monsters.txt the diver's
// whole payload is non-conditional -- rusty rivet n20/n15/n10/n5, rusty
// porthole n15, rusty broken diving helmet n15 -- so one Forced diver is a
// guaranteed 4 rivets + porthole + helmet, independent of item bonus.
// (Its c-flagged drops, glowing syringe and unholy water, are not forced; we
// want neither.)
//
// Duplicate is not part of this plan: doubling pays only on a WIN, and a
// Forced fight is never won. duplicateMonster() owns the day's cast.

// The rivet hunt is live while nothing that fills the diving-helmet slot is
// owned. Mirrors divingHelmet() in UnderTheSea.ash, which parse order keeps
// out of reach of this file.
boolean diverHuntActive() {
    if (item_amount($item[rusty rivet]) >= 8)
        return false;
    foreach it in $items[Mer-kin gladiator mask, Mer-kin scholar mask,
        crappy Mer-kin mask, aerated diving helmet, Elf Guard SCUBA tank] {
        if (item_amount(it) > 0 || have_equipped(it))
            return false;
    }
    return true;
}

// Mirrors doneWithSeaCow() in UnderTheSea.ash, which parse order keeps out of
// reach of this file.
boolean seaCowNeeded() {
    if (item_amount($item[sea leather]) + available_amount($item[sea chaps])
        + available_amount($item[sea cowboy hat]) < 2)
        return true;
    if (item_amount($item[sea cowbell]) < 3)
        return true;
    return false;
}

boolean prayerbeadsShort() {
    return available_amount($item[mer-kin prayerbeads]) < 3;
}

// ─── THE FORCE BUDGET ─────────────────────────────────────────────────────────
// Five charges a day, claimed in priority order by turns-per-charge:
//   1. the diver (2 while its hunt is live)            ~4 turns each
//   2. the outpost healer while prayerbeads are short  ~2-4 turns
//   3. the sea cow while its drops are owed            ~1.5-2 turns
//   4. the library researcher / free-run of last resort: whatever remains
// Each claim releases the moment its need-check goes false, so a run that
// skips a phase hands the charges down the ladder automatically.
int saberChargesLeft() {
    if (!have_item($item[Fourth of May Cosplay Saber]))
        return 0;
    return 5 - to_int(get_property("_saberForceUses"));
}

boolean diverForceReady() {
    return diverHuntActive() && saberChargesLeft() > 0;
}

// Charges available to each claimant, after every higher-priority claim.
int forcesAfterDiver() {
    return saberChargesLeft() - (diverHuntActive() ? 2 : 0);
}
int forcesAfterHealer() {
    return forcesAfterDiver() - (prayerbeadsShort() ? 1 : 0);
}
int saberForcesFree() {
    return forcesAfterHealer() - (seaCowNeeded() ? 1 : 0);
}

// Weapon-slot pin for the summoned diver fights, so the Force is castable.
string diverSaber() {
    if (diverForceReady())
        return "Fourth of May Cosplay Saber,";
    return "";
}

// CCS entry. On the diver: lay the insurance egg for diver #2 while the fight
// is still open, then Force the drops. Returns true when it Forced -- the
// combat is over and the caller must end the consult pass.
boolean diverForce(monster mob, string page_text) {
    if (mob != $monster[unholy diver])
        return false;
    if (!diverForceReady())
        return false;
    if (!have_equipped($item[Fourth of May Cosplay Saber]))
        return false;
    if (!contains_text(page_text, "Use the Force"))
        return false;
    if (my_familiar() == $familiar[chest mimic])
        use_skill($skill[%fn, lay an egg]);
    step("Use the Force -> unholy diver (rivets " + item_amount($item[rusty rivet]) + "/8)");
    use_skill($skill[Use the Force]);
    return true;
}

// ─── SEA COW: THE SAME TRICK AT THE CORRAL ────────────────────────────────────
// Both of the cow's drops are non-conditional in monsters.txt (sea cowbell n10,
// sea leather n20), so Use the Force hands over a guaranteed leather + cowbell
// exactly as it hands over the diver's rivets. Two Forced cows nearly close the
// corral needs (leather x2, cowbell x3).

// CCS entry, same contract as diverForce(): true means the fight is over and
// the caller must end the consult pass.
boolean seaCowForce(monster mob, string page_text) {
    if (mob != $monster[sea cow])
        return false;
    if (!seaCowNeeded())
        return false;
    // Third claim on the budget: only charges beyond the diver's and the
    // outpost healer's reserves.
    if (forcesAfterHealer() <= 0)
        return false;
    // The skateboard's McTwist forces this table for free, once a day; let the
    // corral branch spend that before a Force charge.
    if (have_equipped($item[pro skateboard]) && get_property("_epicMcTwistUsed") == "false")
        return false;
    // The one-turn corral opener converts early fights via its own
    // McTwist/backup-camera machinery -- stay out of its way.
    if ($location[the coral corral].turns_spent <= 1
        && item_amount($item[sea leather]) == 0
        && available_amount($item[sea cowboy hat]) == 0)
        return false;
    if (!have_equipped($item[Fourth of May Cosplay Saber]))
        return false;
    if (!contains_text(page_text, "Use the Force"))
        return false;
    step("Use the Force -> sea cow");
    use_skill($skill[Use the Force]);
    return true;
}

// ─── OUTPOST HEALER AND LIBRARY RESEARCHER ────────────────────────────────────
// The healer's table is all non-conditional (prayerbeads n5, thingpouch n15,
// healscroll n25), and beads are the run's chronic shortage. A Forced fight
// spends no turn and leaves the lockkey's turns_spent clock alone, so this
// rides the outpost phase for free -- the stall the saberZone() ban guards
// against comes from UNLIMITED last-resort forcing, not a capped targeted one.
// In practice it fires on farmPrayerbeads() trips, where healerSaber() frees
// the weapon slot; the lockkey grind keeps the monodent.
boolean healerForce(monster mob, string page_text) {
    if (mob != $monster[Mer-kin healer])
        return false;
    if (!prayerbeadsShort())
        return false;
    // While the healer is the designated lockkey carrier its WIN matters --
    // the lockkey is a quest drop the Force cannot deliver.
    if (get_property("merkinLockkeyMonster") == "Mer-kin healer")
        return false;
    if (forcesAfterDiver() <= 0)
        return false;
    if (!have_equipped($item[Fourth of May Cosplay Saber]))
        return false;
    if (!contains_text(page_text, "Use the Force"))
        return false;
    step("Use the Force -> Mer-kin healer (prayerbeads)");
    use_skill($skill[Use the Force]);
    return true;
}

// Weapon-slot pin for the bead-farming trips.
string healerSaber() {
    if (prayerbeadsShort()
        && get_property("merkinLockkeyMonster") != "Mer-kin healer"
        && forcesAfterDiver() > 0
        && have_item($item[Fourth of May Cosplay Saber]))
        return "Fourth of May Cosplay Saber,";
    return "";
}

// The researcher's healscroll and killscroll are 10% each -- the slowest slots
// in the library at any bonus -- and one charge lands both, freeing their
// reserved pulls. Lowest priority: only truly unreserved charges.
boolean researcherForce(monster mob, string page_text) {
    if (mob != $monster[Mer-kin researcher])
        return false;
    if (item_amount($item[mer-kin killscroll]) > 0
        && item_amount($item[mer-kin healscroll]) > 0)
        return false;
    if (saberForcesFree() <= 0)
        return false;
    if (!have_equipped($item[Fourth of May Cosplay Saber]))
        return false;
    if (!contains_text(page_text, "Use the Force"))
        return false;
    step("Use the Force -> Mer-kin researcher (scrolls)");
    use_skill($skill[Use the Force]);
    return true;
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
    // Comma-delimited so an id cannot match inside a longer one (360 vs 3604);
    // a false hit here silently skips the pull and callers fall back to farming.
    if (!contains_text("," + get_property("_roninStoragePulls") + ",", "," + to_int(it) + ",")) {
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

// ─── CODPIECE ─────────────────────────────────────────────────────────────────

void codpiece(string input) {
    // Gem mounting is a bonus, not a requirement -- no codpiece, no-op.
    if (!have_item($item[The Eternity Codpiece]))
        return;
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
        // Verify all slots mounted correctly. Entries blanked above were
        // deliberately skipped, so they must not fail verification.
        string verify = visit_url("inventory.php?action=docodpiece");
        foreach num in slots {
            if (slots[num] == "")
                continue;
            if (!contains_text(verify, to_item(slots[num]) + " mounted in slot #" + (num + 1)))
                abort("Codpiece slot incorrect");
        }
    }
    cli_execute("refresh inv");
}

// "item name," if we can equip it, "" if we cannot. ASH resolves calls in parse
// order and this file is imported before UnderTheSea.ash's own functions exist,
// so if_equip has to live here, below codpiece and above its first caller.
string if_equip(item it) {
    if ($items[baseball diamond, peridot of peril, heartstone, blood cubic zirconia] contains it)
        codpiece("none");
    if (it == $item[none] || available_amount(it) == 0)
        return "";
    else
        return to_string(it) + ",";
}

// ─── MAP THE MONSTERS ─────────────────────────────────────────────────────────
// Comprehensive Cartography gives 3 casts a day. Each turns the next fight in a
// zone into a monster of your choosing -- the same job as the Peridot of Peril,
// answered in UnderTheSea_Choice.ash from the same wantedMonster table.
//
// The Peridot is once per zone per day; these are the extra charges once the
// Peridot's is spent. They go to the longest odds first (diver 1-in-5,
// flytrap 1-in-4, sea cow 1-in-3). The outpost is excluded: its lockkey
// gates on turns spent, so a chosen encounter saves nothing there.

boolean mapReady() {
    return have_skill($skill[Map the Monsters])
        && to_int(get_property("_monstersMapped")) < 3
        && get_property("mappingMonsters") == "false";
}

boolean mapZone(location loc) {
    return $locations[The Wreck of the Edgar Fitzsimmons,
        An Octopus's Garden, The Coral Corral,
        Mer-kin Elementary School] contains loc;
}

// Only cast once the Peridot's charge for this zone is gone, so the two do not
// both spend themselves picking the same monster.
void mapMonster(location loc) {
    if (!mapReady() || !mapZone(loc))
        return;
    if (available_amount($item[peridot of peril]) > 0
        && !contains_text("," + get_property("_perilLocations") + ",", "," + to_int(loc) + ","))
        return;
    step("Map the Monsters armed for " + loc);
    use_skill($skill[Map the Monsters]);
}

// Roughly how many noncombat forces this account can field. Deliberately does
// NOT count the Pill Keeper: this is the number we use to decide whether the
// free pill needs reserving for Sneakisol, so counting it would be circular.
int NCForceEstimate(){
    int force = 2;
    // Counts remaining CHARGES, not ownership.
    if (have_item($item[Apriling band tuba]))
        force += max(0, 3 - to_int(get_property("_aprilBandTubaUses")));
    if (have_item($item[McHugeLarge left ski]))
        force += max(0, 3 - to_int(get_property("_mcHugeLargeAvalancheUses")));
    if (have_item($item[Cincho de Mayo]))
        force += min(3, 1 + max(0, total_free_rests() - to_int(get_property("timesRested"))) / 2);
    if (have_item($item[Jurassic Parka]))
        force += max(0, 5 - to_int(get_property("_spikolodonSpikeUses")));
    return force;
}

// ─── SOURCE TERMINAL ──────────────────────────────────────────────────────────
// The terminal is a campground fixture, so it survives ascension and there is
// nothing to install or pull in-run.
//
// Only enhance is routed in. items.enh is a flat +item drops buff lasting 25
// turns, or 100 on a fully chipped terminal, with up to 3 casts a day. It costs
// no turn and carries no risk, and it shortens every drop-farming loop in the
// script, so it is called wherever we are already setting up for +item.
//
// Digitize is deliberately NOT used: its wanderers cost an adventure, arrive
// on their own schedule, cannot be aimed at a zone, displace the noncombats
// the outpost block hunts, and outrank forced noncombats. Map the Monsters
// does the same job aimed and free.

void sourceEnhance() {
    if (get_campground()[$item[Source terminal]] == 0)
        return;
    if (have_effect($effect[items.enh]) > 0)
        return;
    if (to_int(get_property("_sourceTerminalEnhanceUses")) >= 3)
        return;
    cli_execute("terminal enhance items.enh");
}

// duplicate.edu: one cast a day turns a monster into two, and each copy rolls
// the whole drop table -- one extra encounter for no turn. Slotting it
// displaces nothing this script casts. Targeting lives in duplicateMonster();
// a cast against an uncopyable monster does not consume the daily use.

boolean duplicateEducated() {
    return get_property("sourceTerminalEducate1") == "duplicate.edu"
        || get_property("sourceTerminalEducate2") == "duplicate.edu";
}

boolean duplicateReady() {
    if (get_campground()[$item[Source terminal]] == 0)
        return false;
    if (to_int(get_property("_sourceTerminalDuplicateUses")) >= 1)
        return false;
    return contains_text(get_property("sourceTerminalEducateKnown"), "duplicate.edu");
}

void sourceEducate() {
    if (!duplicateReady() || duplicateEducated())
        return;
    cli_execute("terminal educate duplicate.edu");
}

// Called from the CCS. Doubling the diver doubles its HP, attack, defence and
// attacks per round as well as its drops, so it goes out early in the fight
// rather than being saved for last.
void duplicateMonster(monster mob, string page_text) {
    if (!duplicateReady() || !duplicateEducated())
        return;
    // Doubling pays only on a WIN, so never spend the day's cast on a fight
    // the saber is about to Force.
    boolean aboutToForce = have_equipped($item[Fourth of May Cosplay Saber])
        && ((mob == $monster[unholy diver] && diverForceReady())
            || (mob == $monster[sea cow] && seaCowNeeded() && forcesAfterHealer() > 0));
    if (aboutToForce)
        return;
    // Best killed tables the route meets: the golem (free fight, flat 100%
    // crayon shavings -- the Shub deleveler), then the unForced sea cow, the
    // sheet-grind monitor, and the diver only on saberless kits, where a
    // doubled kill's 8 rivets end the hunt outright.
    boolean wanted = (mob == $monster[Black Crayon Golem] && item_amount($item[crayon shavings]) < 4)
        || (mob == $monster[sea cow] && seaCowNeeded() && !diverHuntActive())
        || (mob == $monster[Mer-kin monitor] && cheatsheetsNeeded())
        || (mob == $monster[unholy diver] && item_amount($item[rusty rivet]) < 8
            && !have_item($item[Fourth of May Cosplay Saber]));
    if (!wanted)
        return;
    if (!contains_text(page_text, "Duplicate"))
        return;
    step("Duplicate: " + mob);
    use_skill($skill[Duplicate]);
}

// ─── SEPT-EMBER CENSER ────────────────────────────────────────────────────────
// Seven embers a day. They bank across days rather than resetting at rollover,
// but only once the censer has actually been stoked -- they do not accrue on
// their own, so the run has to go and claim them.
//
// All embers buy Septapus summoning charms: the CCS throws them at the
// shadow slab, and each charm's seven pickpockets take items outside the
// drop roll, immune to the per-slot cap. Nothing else in the shop shortens
// the run.
void censer() {
    if (!have_item($item[Sept-Ember Censer]))
        return;
    if (get_property("_septEmberBalanceChecked") == "false")
        visit_url("shop.php?whichshop=september");
    int wanted = 3 - item_amount($item[Septapus summoning charm]);
    int afford = to_int(get_property("availableSeptEmbers")) / 2;
    if (afford < wanted)
        wanted = afford;
    if (wanted > 0)
        buy($coinmaster[Sept-Ember Censer], wanted, $item[Septapus summoning charm]);
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
// `pill` must be a mafia pillkeeper KEYWORD ([free] explode | extend |
// noncombat | element | stat | familiar | lucky | random); the command does
// not accept pill names.
void pillKeeper(string pill) {
    if (!have_item($item[Eight Days a Week Pill Keeper]))
        return;
    if (get_property("_freePillKeeperUsed") != "false")
        return;
    step("Pill keeper: " + pill);
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
// Drops are rolled when the combat ends, so the +50% applies to the fight it
// is cast in.

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

// ─── TIME-SPINNER ─────────────────────────────────────────────────────────────
// Also handed to you automatically at the start of a run. 10 minutes a day, and
// "Travel to a Recent Fight" costs 3 of them, so 3 uses.
//
// Not a free fight -- the refight costs its adventure; it buys a guaranteed
// encounter where the target is a rare draw. The monster must be in the
// zone's recent-combat queue, so it only fires straight after fighting the
// target there. mafia's "timespinner" CLI covers only food and pranks, so
// the choice chain (1195 -> Travel to a Recent Fight -> 1196, monid submit)
// is walked by hand.

boolean timeSpinnerReady() {
    return have_item($item[Time-Spinner])
        && to_int(get_property("_timeSpinnerMinutesUsed")) <= 7
        && my_adventures() > 0;
}

// Re-fight `mon` for one turn, guaranteed. Only fires straight after fighting
// that monster (last_monster()), which keeps it inside the recent-fights
// window without guessing at the window's exact size -- and works after
// summoned or Forced fights too, since the list records encounters, not wins.
boolean timeSpinnerFight(monster mon) {
    if (!timeSpinnerReady())
        return false;
    if (last_monster() != mon)
        return false;

    step("Time-Spinner: refighting " + mon);
    visit_url("inv_use.php?whichitem=" + to_int($item[Time-Spinner]) + "&pwd=" + my_hash());
    // mafia auto-resolves choices it has handling for, even on visit_url; if
    // nothing is live any manual answer would abort with "Invalid choice".
    if (!handling_choice()) {
        step("Time-Spinner choice was auto-resolved or never opened; skipping");
        return false;
    }
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
        return false;
    }
    run_choice(travel);
    run_choice(1, "monid=" + to_int(mon));
    // The monid submit drops us into the fight; without this the session is
    // left mid-combat and the next adv() errors out.
    run_combat();
    return true;
}

void timeSpinnerRefight(location loc) {
    int target = zoneTarget(loc);
    if (target == 0)
        return;
    // Only worth a turn where the target is genuinely rare; these are the same
    // zones Map the Monsters spends its charges on.
    if (!mapZone(loc))
        return;
    if (my_location() != loc)
        return;
    timeSpinnerFight(to_monster(target));
}

// ─── POCKET PROFESSOR ─────────────────────────────────────────────────────────
// "lecture on relativity" chains a free copy of the current fight. The daily
// pool is gated on buffed familiar weight (next cast needs n^2 + 1 lbs). The
// Professor is a weaker underwater fairy and needs the bathysphere, so it is
// swapped in only where copies beat drop bonus and swapped out when the
// lectures run dry.

// Conservative: familiar_weight() of an inactive familiar is its base weight, so
// this can under-count while Fidoxene's floor is up. Under-counting only ends the
// swap early, which is the safe direction.
int professorLectureLimit() {
    int w = familiar_weight($familiar[Pocket Professor]) + weight_adjustment();
    int n;
    while ((n * n + 1) <= w)
        n += 1;
    return n;
}

boolean professorReady() {
    return have_familiar($familiar[Pocket Professor])
        && to_int(get_property("_pocketProfessorLectures")) < professorLectureLimit();
}

void professorFamiliar() {
    if (!professorReady())
        return;
    // Rivet hunt: under the Force plan a diver pays 4 guaranteed rivets and
    // the second one is a Time-Spinner refight away -- lecture copies add
    // nothing, so keep the better drop familiar out.
    if (diverHuntActive()) {
        if (!diverForceReady())
            use_familiar($familiar[Pocket Professor]);
        return;
    }
    // Corral: once the Force budget there is spent, lecture copies of the sea
    // cow are the next cheapest source of leather and cowbells.
    if (seaCowNeeded() && forcesAfterHealer() <= 0)
        use_familiar($familiar[Pocket Professor]);
}

void lectureOnRelativity(monster mob, string page_text) {
    if (!professorReady())
        return;
    if (my_familiar() != $familiar[Pocket Professor])
        return;
    // Same targets as professorFamiliar(): the diver while rivets are owed,
    // the sea cow while its drops are.
    boolean wanted = (mob == $monster[unholy diver] && item_amount($item[rusty rivet]) < 8)
        || (mob == $monster[sea cow] && seaCowNeeded());
    if (!wanted)
        return;
    // The skill refuses to fire below 2 adventures, even against a free fight.
    if (my_adventures() < 2)
        return;
    if (!contains_text(page_text, "lecture on relativity"))
        return;
    step("Lecture on Relativity: chaining a free " + mob);
    use_skill($skill[lecture on relativity]);
}

// ─── JANUARY'S GARBAGE TOTE: BROKEN CHAMPAGNE BOTTLE ──────────────────────────
// The bottle doubles the item drop BONUS and stacks with Steely-Eyed Squint.
// It holds 11 ounces, one spent per winning combat including free fights, so
// the charges are aimed at the fattest rolled tables rather than worn
// generally. (It doubles the Florist buff but not Otoscope; Squint is the
// reverse, so all three pair cleanly.)

boolean champagneReady() {
    return have_item($item[broken champagne bottle])
        && to_int(get_property("garbageChampagneCharge")) > 0;
}

// Only where a fat table is being ROLLED. Forced drops ignore item bonus, so
// while a Force plan covers the zone the ounces are banked instead.
string champagneEquip(location loc) {
    if (!champagneReady())
        return "";
    if (loc == $location[The Wreck of the Edgar Fitzsimmons] && !diverForceReady())
        return if_equip($item[broken champagne bottle]);
    // The corral inherits the bottle once the Force budget there is spent and
    // the cow's leather/cowbell rolls are back to probability.
    if (loc == $location[The Coral Corral] && seaCowNeeded() && forcesAfterHealer() <= 0)
        return if_equip($item[broken champagne bottle]);
    return "";
}

// Pull the bottle out of the tote once, if we own a tote and have not already
// spent its charges this ascension.
void garbageTote() {
    if (!have_item($item[January's Garbage Tote]))
        return;
    if (have_item($item[broken champagne bottle]))
        return;
    if (to_int(get_property("garbageChampagneCharge")) <= 0)
        return;
    step("Garbage tote: fetching the broken champagne bottle");
    visit_url("inv_use.php?whichitem=" + to_int($item[January's Garbage Tote]) + "&pwd=" + my_hash());
    // Same auto-resolution caveat as everywhere: only answer a LIVE choice.
    if (!handling_choice()) {
        step("Tote choice was auto-resolved or never opened; skipping");
        return;
    }
    int grab;
    int leave;
    foreach num, optionText in available_choice_options() {
        if (contains_text(optionText, "champagne"))
            grab = num;
        if (contains_text(optionText, "Ignore the garbage"))
            leave = num;
    }
    // Never leave the run parked inside a choice we could not read.
    if (grab > 0)
        run_choice(grab);
    else if (leave > 0)
        run_choice(leave);
}

// ─── SPACE JELLYFISH ──────────────────────────────────────────────────────────
// A full fairy underwater, and Extract Jelly can pull stench jelly from
// stench monsters -- a chewable noncombat forcer NCforce() already spends.
// Jelly costs spleen, which fish sauce also needs, so exactly one is taken.

boolean jellyfishReady() {
    return have_familiar($familiar[Space Jellyfish]);
}

void extractJelly(monster mob, string page_text) {
    if (my_familiar() != $familiar[Space Jellyfish])
        return;
    if (mob.attack_element != $element[stench] && mob.defense_element != $element[stench])
        return;
    // Spleen is contested; one forced noncombat is all we are after.
    if (item_amount($item[stench jelly]) > 0)
        return;
    if (!contains_text(page_text, "Extract Jelly"))
        return;
    use_skill($skill[Extract Jelly]);
}

// ─── METEOR LORE: MACROMETEORITE ──────────────────────────────────────────────
// Replaces the current foe with a fresh draw from the zone -- the same job as
// the glove's CHEAT CODE below, but from a skill, so it costs no equipment
// slot. Ten casts a day. Meteor Lore is hardcore-permanent from the first
// read of the guide, so anyone who has ever read it simply has the skill.
boolean macroReady() {
    return have_skill($skill[Macrometeorite])
        && to_int(get_property("_macrometeoriteUses")) < 10;
}

// ─── POWERFUL GLOVE ───────────────────────────────────────────────────────────
// CHEAT CODE: Replace Enemy swaps the current foe for a fresh draw from the
// zone; the 100% daily battery at 10% a cast gives ten re-rolls. It costs an
// accessory slot, so it is equipped only where re-rolls pay and other
// accessories don't compete.

boolean gloveReady() {
    return have_item($item[Powerful Glove])
        && to_int(get_property("_powerfulGloveBatteryPowerUsed")) <= 90;
}

string gloveEquip(location loc) {
    // Macrometeorite does the same job from a skill slot; while it has casts
    // left, the accessory slot goes back to the zirconia and backup camera.
    if (macroReady())
        return "";
    if (gloveReady() && loc == $location[The Wreck of the Edgar Fitzsimmons])
        return if_equip($item[Powerful Glove]);
    return "";
}

// Returns true if this monster provides a free fight. Lives here (not the
// CCS) so the re-roll policies below can refuse to waste a cast on one:
// free wanderers also burn delay, advancing turns_spent wherever they land.
boolean free_monster(monster mob) {
    return $monsters[black crayon golem, time cop,sausage goblin,
        kid who is too old to be Trick-or-Treating,
        suburban security civilian, vandal kid] contains mob;
}

// Casts whichever re-roller is available: Macrometeorite (Meteor Lore, 10 a
// day, no equipment slot) first, the glove's CHEAT CODE second. On true the
// fight holds a NEW monster and the caller MUST re-dispatch the CCS main()
// with last_monster() and a re-fetched fight page -- a bare return would fall
// through to the CCS's safety abort, since mafia does not re-invoke a consult
// script that returns mid-combat.
boolean rerollEnemy(string page_text) {
    if (macroReady() && contains_text(page_text, "Macrometeorite")) {
        step("Macrometeorite: re-rolling the monster");
        use_skill($skill[Macrometeorite]);
        return true;
    }
    if (gloveReady() && have_equipped($item[Powerful Glove])
        && contains_text(page_text, "CHEAT CODE: Replace Enemy")) {
        step("CHEAT CODE: re-rolling the monster");
        use_skill($skill[CHEAT CODE: Replace Enemy]);
        return true;
    }
    return false;
}

// Fitzsimmons policy: re-roll anything that is not the diver while rivets are
// still owed.
boolean replaceEnemy(monster mob, string page_text) {
    if (my_location() != $location[The Wreck of the Edgar Fitzsimmons])
        return false;
    // Never re-roll a free fight: it costs nothing, burns delay, and dies to
    // the location logic's fall-through kill.
    if (free_monster(mob))
        return false;
    // Never re-roll the monster we came for, and stop once its drops are in.
    if (mob == $monster[unholy diver])
        return false;
    if (item_amount($item[rusty rivet]) >= 8)
        return false;
    return rerollEnemy(page_text);
}

// ─── EMOTION CHIP: FEEL NOSTALGIC ─────────────────────────────────────────────
// Feel Nostalgic appends the last copyable monster's whole drop table to the
// current fight at original rates; three casts a day, no equipment slot. The
// fight must be WON, and casting it on the monster being copied does
// nothing. Feel Envy would force drops outright but does not work
// underwater, so it is absent.
void feelNostalgic(monster mob, string page_text) {
    if (!have_skill($skill[Feel Nostalgic]))
        return;
    if (to_int(get_property("_feelNostalgicUsed")) >= 3)
        return;
    // The appended drops only pay out if this fight is WON. When the saber
    // still has Force charges the rest of the script may spend, free_kill()
    // may Use the Force out of the combat, forfeiting the win and the charge
    // with it -- so never overlap the two.
    if (saberForcesFree() > 0 && have_equipped($item[Fourth of May Cosplay Saber]))
        return;
    // Worth a charge only while the copied table still owes us something:
    // the diver's rivets, the sea cow's leather and cowbells, or the
    // monitor's cheatsheet (~capped at itdrop bonuses) during the grind.
    string copied = get_property("lastCopyableMonster");
    boolean wanted = (copied == "unholy diver" && item_amount($item[rusty rivet]) < 8)
        || (copied == "sea cow" && seaCowNeeded())
        || (copied == "Mer-kin monitor" && cheatsheetsNeeded());
    if (!wanted)
        return;
    // Casting it on the monster we are nostalgic for does nothing.
    if (to_string(mob) == copied)
        return;
    if (!contains_text(page_text, "Feel Nostalgic"))
        return;
    step("Feel Nostalgic: re-rolling the " + copied + " table");
    use_skill($skill[Feel Nostalgic]);
}

// ─── LIL' DOCTOR BAG: OTOSCOPE ────────────────────────────────────────────────
// The bag grants three skills, three uses each, and the script was only ever
// spending one of them. freeKill() already equips the bag for Chest X-Ray, so
// the other two ride along in the same accessory slot for nothing.
//
// Otoscope is +200% item drops for that combat. It goes on the diver, whose four
// rivet slots make it the fattest table in the run, and it pairs with the Chest
// X-Ray that free_kill() is about to fire: boost the drops first, then take the
// kill for free. Cast early so the fight cannot end before it lands.
//
// Reflex Hammer, the third skill, is a free runaway plus a 30-turn banish, and
// is wired into free_run() with the other banishes rather than here.
void otoscope(monster mob, string page_text) {
    // A fight the saber is about to Force has its drops forced anyway; the
    // +200% would be a wasted charge.
    if (diverForceReady() && have_equipped($item[Fourth of May Cosplay Saber]))
        return;
    if (to_int(get_property("_otoscopeUsed")) >= 3)
        return;
    if (!have_equipped($item[Lil' Doctor&trade; bag]))
        return;
    if (mob != $monster[unholy diver])
        return;
    if (item_amount($item[rusty rivet]) >= 8)
        return;
    if (!contains_text(page_text, "Otoscope"))
        return;
    step("Otoscope on " + mob);
    use_skill($skill[Otoscope]);
}

// ─── MUMMING TRUNK ────────────────────────────────────────────────────────────
// Prince George is +15% item drops, or +25% on a clothes-wearing familiar, and
// it lasts until rollover rather than for a fixed number of turns. That duration
// is the whole point: it covers every farming turn the costumed familiar is out
// for, which no timed buff manages.
//
// Each costume may be applied once per day, and putting a second costume on a
// familiar overwrites the first, so there is exactly one shot at this. It goes
// on whichever familiar the item setup actually picks, which is why this is
// called from use_familiar("itdrop") rather than at a fixed point in the run.
//
// None of the other six costumes touch turns. The Captain is meat. Beelzebub and
// The Doctor restore MP and HP, which the free rests already cover. Saint
// Patrick, Oliver Cromwell and Miss Funny are stat gains, and this route has no
// level gates. Their familiar-specific riders are all combat-round effects -- a
// stagger, or winning initiative -- and a fight costs one adventure however many
// rounds it runs, so none of them shorten the run.
void mummery() {
    if (!have_item($item[mumming trunk]))
        return;
    // _mummeryMods records what has already been applied today; an Item Drop
    // entry means Prince George is spent.
    if (contains_text(get_property("_mummeryMods"), "Item Drop"))
        return;
    if (my_familiar() == $familiar[none])
        return;
    cli_execute("mummery item");
}

// ─── CARGO CULTIST SHORTS ─────────────────────────────────────────────────────
// One pocket a day, and a pocket once opened is gone for good on the account
// rather than for the run, so this is a permanent spend and worth being fussy
// about.
//
// Pocket 494 is Vinegavotte, +20% item drops for 50 turns. It beats the
// bigger-looking numbers because duration outweighs magnitude at the item bonus
// this script already stacks: Finding Stuff is +30% but runs only 20 turns,
// which does not cover enough of the farming to make the difference back.
//
// The -combat pockets are deliberately left alone. Combat frequency has hard
// diminishing returns past 25 points and this script is already near -50 raw, so
// Barely Visible's -10 would buy about two effective points. See NCforce().
void cargoPocket() {
    if (!have_item($item[Cargo Cultist Shorts]))
        return;
    if (get_property("_cargoPocketEmptied") != "false")
        return;
    // Comma-delimited match so a pocket number cannot match inside another.
    if (contains_text("," + get_property("cargoPocketsEmptied") + ",", ",494,"))
        return;
    step("Cargo shorts: opening pocket 494");
    cli_execute("cargo pocket 494");
}

// ─── KREMLIN'S GREATEST BRIEFCASE ─────────────────────────────────────────────
// Driven through Ezandora's Briefcase script, which owns the dial, handle and
// tab state machine. "briefcase buff item" spends clicks until it lands Items
// Are Forever: +50% item drops for 50 turns, the largest single item effect
// available to this run, for no turn.
//
// Which tab carries which buff is randomised every ascension, so the first
// acquisition in a run also pays some discovery clicks. The budget is 11 clicks
// a day, or 22 once the crank is unlocked, and the script stops cleanly when
// they run out, so there is nothing to guard past not asking for a buff we
// already have.
//
// The case can also hold a -combat enchantment. It is deliberately not set, for
// the same reason the -combat pockets are skipped.
void briefcase() {
    if (!have_item($item[Kremlin's Greatest Briefcase]))
        return;
    if (have_effect($effect[Items Are Forever]) > 0)
        return;
    // An unopened case has no tabs to read, so asking for a buff would only
    // burn clicks. Opening it is a two-day job and not something a run should
    // be spending its budget on.
    if (get_property("_kgbOpened") == "false")
        return;
    if (to_int(get_property("_kgbClicksUsed")) >= 22)
        return;
    cli_execute("briefcase buff item");
}

// ─── NONCOMBAT FORCER ─────────────────────────────────────────────────────────
// Why this script forces noncombats instead of just stacking more -combat:
//
// Combat frequency has hard diminishing returns. The first 25 points of a
// modifier count in full; beyond that, every further 5 points contribute only 1.
// A raw -30 lands at -26, and a raw -50 lands at -30.
//
// The mood("-combat") list already casts roughly -50 raw before the maximizer
// adds any gear, so it is deep in the 5:1 band. Another -5 or -10 raw from any
// source is worth one or two effective points, which is why cheap-looking
// -combat buffs are not worth routing in here.
//
// A forced noncombat -- a "sneak" -- bypasses the roll entirely and is not
// subject to any of this, so forcing is strictly better than buffing once the
// stack is this deep. That is what NCForceEstimate() is counting.

void NCforce() {
    if (get_property("noncombatForcerActive") != "true") {
        if (to_int(get_property("_aprilBandTubaUses")) < 3 && have_item($item[Apriling band tuba])) {
            cli_execute("aprilband play tuba");
        // Enter the Cincho branch only if it can actually fire -- either
        // enough cinch already, or free rests left to restore it.
        } else if (have_item($item[Cincho de Mayo])
            && (to_int(get_property("_cinchUsed")) <= 40
                || to_int(get_property("timesRested")) < total_free_rests())){
            while (to_int(get_property("_cinchUsed")) > 40
                && to_int(get_property("timesRested")) < total_free_rests()) {
                // The helmet sweetens the rest but is optional; equipping it
                // unowned hard-errors.
                if (have_item($item[Apriling band helmet]))
                    cli_execute("unequip hat; equip apriling band helmet");
                cli_execute("camp rest free");
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
            pillKeeper("free noncombat");
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
        visit_url("choice.php?whichchoice=804&pwd=" + my_hash() + "&option=3&whichhouse=" + houseToVisit);
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
    // prefs are matched inside \Q..\E against banishedMonsters, so they must
    // be literal prefixes of the recorded banisher name -- no regex escaping.
    $item[spring shoes]:        new ban("Spring Kick",           $skill[spring kick]),
    $item[monodent of the sea]: new ban("Sea *dent",             $skill[Sea *dent: Throw a Lightning Bolt]),
    $item[Heartstone]:          new ban("Heartstone",            $skill[Heartstone: %banish]),
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
    // No candidate leaves it at $item[none]; writing an override for it would
    // create a junk "noneOverride" property.
    if (it != $item[none]) {
        set_property(to_string(to_slot(it)) + "Override", ", equip " + it);
        print(to_string(to_slot(it)) + "Override");
    }
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

// ─── RUN-START CHECKLISTS ─────────────────────────────────────────────────────
// Logged once at initialization: every supported IOTM and every pull the
// route may ask for, one per line -- blue check for present, red cross for
// absent. Purely informational; every use in the script is ownership-guarded
// regardless.

// Ownership record from the last iotmChecklist() run, keyed by printed name.
// simEstimate() below reads it to model a turn count for the owned kit.
boolean [string] simOwned;

void iotmChecklist() {
    boolean [item] iotmItems = $items[monodent of the sea,
        The Eternity Codpiece,
        closed-circuit pay phone, 2002 Mr. Store Catalog, cursed monkey's paw,
        august scepter, Fourth of May Cosplay Saber, Peridot of Peril,
        blood cubic zirconia, baseball diamond, Heartstone, backup camera,
        Jurassic Parka, spring shoes, Everfull Dart Holster, Mayam Calendar,
        Leprecondo, Cincho de Mayo, McHugeLarge duffel bag,
        Apriling band helmet, April Shower Thoughts shield, bat wings,
        server room key, Time-Spinner, January's Garbage Tote, Powerful Glove,
        combat lover's locket, Lil' Doctor&trade; bag, mumming trunk,
        Kremlin's Greatest Briefcase, Cargo Cultist Shorts,
        Eight Days a Week Pill Keeper, Sept-Ember Censer, vampyric cloake,
        Unwrapped knock-off retro superhero cape, roman candelabra,
        miniature crystal ball, latte lovers member's mug, V for Vivala mask,
        designer sweatpants, tearaway pants, autumn-aton, cosmic bowling ball];
    boolean [skill] iotmSkills = $skills[Just the Facts, Map the Monsters,
        Macrometeorite, Feel Nostalgic];
    boolean [familiar] iotmFamiliars = $familiars[Grouper Groupie,
        Red-Nosed Snapper, Jill-of-All-Trades, Chest Mimic, Patriotic Eagle,
        Sword of S Words, Peace Turkey, Disgeist, Jumpsuited Hound Dog,
        Glover, Foul Ball, Space Jellyfish, Pocket Professor,
        Tiny Plastic Santa Claus Skeleton];

    print("IOTM check — supported IOTMs:");
    clear(simOwned);
    int owned;
    int total;
    foreach it in iotmItems {
        total += 1;
        if (have_item_anywhere(it)) { owned += 1; simOwned[to_string(it)] = true; print("✓ " + it, "blue"); }
        else print("✗ " + it, "red");
    }
    foreach sk in iotmSkills {
        total += 1;
        // have_skill() can flicker at initialization; the owned guide is
        // accepted as a second signal for Macrometeorite.
        boolean has = have_skill(sk)
            || (sk == $skill[Macrometeorite] && have_item($item[Pocket Meteor Guide]));
        if (has) { owned += 1; simOwned[to_string(sk)] = true; print("✓ " + sk, "blue"); }
        else print("✗ " + sk, "red");
    }
    foreach fam in iotmFamiliars {
        total += 1;
        if (have_familiar(fam)) { owned += 1; simOwned[to_string(fam)] = true; print("✓ " + fam, "blue"); }
        else print("✗ " + fam, "red");
    }
    total += 1;
    if (get_workshed() != $item[none]
        || have_item($item[Asdon Martin keyfob (on ring)])
        || have_item($item[model train set])
        || have_item($item[portable Mayo Clinic])
        || have_item($item[TakerSpace letter of Marque])) {
        owned += 1; simOwned["a workshed"] = true; print("✓ a workshed", "blue");
    } else
        print("✗ a workshed", "red");
    total += 1;
    if (get_campground() contains $item[Source terminal]) {
        owned += 1; simOwned["Source Terminal"] = true; print("✓ Source Terminal", "blue");
    } else
        print("✗ Source Terminal", "red");
    print("IOTM check: " + owned + " of " + total + " supported IOTMs owned.");
}

void pullChecklist() {
    boolean [item] pulls = $items[Mer-kin sneakmask, sea lasso, shark jumper,
        scale-mail underwear, Congressional Medal of Insanity,
        Flash Liquidizer Ultra Dousing Accessory, Mer-kin digpick, lodestone,
        comb jelly, Elf Guard SCUBA tank, rusty rivet, sea cowbell,
        Mer-kin prayerbeads, Mer-kin healscroll, Mer-kin killscroll,
        Mer-kin worktea, Mer-kin knucklebone, Mer-kin cheatsheet,
        Mer-kin hallpass, Mer-kin hidepaint, pro skateboard, software glitch,
        pulled yellow taffy, stuffed yam stinkbomb, waffle, skate blade,
        null-day exploit, New Age healing crystal, soggy used band-aid,
        damp old wallet, fish sauce, Aldebaran sardines,
        pie man was not meant to eat, Handheld Allied radio, Clara's bell,
        stench jelly, peppermint parasol, ink bladder, Mer-kin pinkslip,
        Louder Than Bomb, anchor bomb];

    print("Pull check — Hagnk's stock:");
    foreach it in pulls {
        // Catalog credits create these in-run; only worth stocking without it.
        if (have_item($item[2002 Mr. Store Catalog])
            && $items[pro skateboard, software glitch] contains it)
            continue;
        // Never auto-bought (see the pull loop) -- flag it as a nice-to-have.
        if (it == $item[Congressional Medal of Insanity] && storage_amount(it) == 0) {
            print("✗ " + it + " — optional, the script won't buy one", "red");
            continue;
        }
        if (storage_amount(it) > 0)
            print("✓ " + it, "blue");
        else if (is_tradeable(it))
            print("✗ " + it + " — will be mall-bought if the route needs it", "red");
        else
            print("✗ " + it + " — NOT mall-buyable, acquire before it's needed", "red");
    }
}

// ─── SIM MODEL ────────────────────────────────────────────────────────────────
// Turn model behind "UnderTheSea sim". Each owned IOTM, skill and familiar
// contributes weighted "kit power", with later credits discounted since
// savings overlap. The estimate is quadratic in missing power between two
// anchors -- BASELINE turns with no kit, FULLKIT with everything -- so near
// a full kit each missing item costs about its weight, while on a bare
// account the first items are worth several times theirs.

// Kit power of a set of weights: biggest five in full, next five at 75%,
// the rest at half.
float simTierSum(float [int] vals) {
    sort vals by -value;
    float total;
    int rank;
    foreach i in vals {
        if (rank < 5) total += vals[i];
        else if (rank < 10) total += 0.75 * vals[i];
        else total += 0.5 * vals[i];
        rank += 1;
    }
    return total;
}

void simEstimate() {
    float BASELINE = 190.0;   // modeled turns with no supported kit at all
    float FULLKIT = 33.0;     // modeled turns with everything owned
    float FLOOR = 31.0;
    float [string] worth;
    // Route carriers
    worth[to_string($item[closed-circuit pay phone])] = 6.5;
    worth[to_string($item[Fourth of May Cosplay Saber])] = 5.0;
    worth[to_string($item[tearaway pants])] = 3.5;
    worth[to_string($item[2002 Mr. Store Catalog])] = 3.0;
    worth[to_string($item[cursed monkey's paw])] = 3.0;
    worth[to_string($item[The Eternity Codpiece])] = 2.5;
    worth[to_string($item[Jurassic Parka])] = 2.5;
    worth[to_string($item[McHugeLarge duffel bag])] = 2.5;
    worth[to_string($item[Apriling band helmet])] = 2.5;
    worth[to_string($skill[Just the Facts])] = 2.5;
    // Multi-turn drivers
    worth[to_string($item[august scepter])] = 1.5;
    worth[to_string($item[Peridot of Peril])] = 1.5;
    worth[to_string($item[blood cubic zirconia])] = 1.5;
    worth[to_string($item[baseball diamond])] = 1.5;
    worth[to_string($item[backup camera])] = 1.5;
    worth[to_string($item[bat wings])] = 1.5;
    worth[to_string($item[server room key])] = 1.5;
    worth[to_string($item[Time-Spinner])] = 1.5;
    worth[to_string($item[Lil' Doctor&trade; bag])] = 1.5;
    worth[to_string($skill[Map the Monsters])] = 1.5;
    worth[to_string($skill[Macrometeorite])] = 1.5;
    worth[to_string($skill[Feel Nostalgic])] = 1.5;
    worth["a workshed"] = 1.5;
    worth["Source Terminal"] = 1.5;
    // About a turn each
    worth[to_string($item[Heartstone])] = 1.0;
    worth[to_string($item[spring shoes])] = 1.0;
    worth[to_string($item[Everfull Dart Holster])] = 1.0;
    worth[to_string($item[Mayam Calendar])] = 1.0;
    worth[to_string($item[Cincho de Mayo])] = 1.0;
    worth[to_string($item[January's Garbage Tote])] = 1.0;
    worth[to_string($item[combat lover's locket])] = 1.0;
    worth[to_string($item[Kremlin's Greatest Briefcase])] = 1.0;
    worth[to_string($item[Eight Days a Week Pill Keeper])] = 1.0;
    worth[to_string($item[Sept-Ember Censer])] = 1.0;
    worth[to_string($item[vampyric cloake])] = 1.0;
    worth[to_string($item[miniature crystal ball])] = 1.0;
    worth[to_string($item[autumn-aton])] = 1.0;
    // The tail
    worth[to_string($item[Leprecondo])] = 0.5;
    worth[to_string($item[April Shower Thoughts shield])] = 0.5;
    worth[to_string($item[Powerful Glove])] = 0.5;
    worth[to_string($item[mumming trunk])] = 0.5;
    worth[to_string($item[Cargo Cultist Shorts])] = 0.5;
    worth[to_string($item[Unwrapped knock-off retro superhero cape])] = 0.5;
    worth[to_string($item[roman candelabra])] = 0.5;
    worth[to_string($item[latte lovers member's mug])] = 0.5;
    worth[to_string($item[V for Vivala mask])] = 0.5;
    worth[to_string($item[designer sweatpants])] = 0.5;
    worth[to_string($item[cosmic bowling ball])] = 0.5;
    // Familiars
    worth[to_string($familiar[Grouper Groupie])] = 2.5;
    worth[to_string($familiar[Red-Nosed Snapper])] = 1.5;
    worth[to_string($familiar[Jill-of-All-Trades])] = 1.5;
    worth[to_string($familiar[Chest Mimic])] = 1.5;
    worth[to_string($familiar[Patriotic Eagle])] = 1.5;
    worth[to_string($familiar[Sword of S Words])] = 1.5;
    worth[to_string($familiar[Pocket Professor])] = 1.5;
    worth[to_string($familiar[Space Jellyfish])] = 1.0;
    worth[to_string($familiar[Glover])] = 1.0;
    worth[to_string($familiar[Peace Turkey])] = 1.0;
    worth[to_string($familiar[Disgeist])] = 1.0;
    worth[to_string($familiar[Foul Ball])] = 0.5;
    worth[to_string($familiar[Jumpsuited Hound Dog])] = 0.5;

    float [int] all;
    float [int] have;
    float [string] missing;
    foreach name, saving in worth {
        all[count(all)] = saving;
        if (simOwned contains name)
            have[count(have)] = saving;
        else
            missing[name] = saving;
    }

    // Quadratic between the anchors. gap is the kit power still missing;
    // the linear term prices items near a full kit at their published
    // estimates, the squared term stretches an empty kit out to BASELINE.
    float full = simTierSum(all);
    float gap = full - simTierSum(have);
    float b = (BASELINE - FULLKIT - full) / (full * full);
    int est = to_int(FULLKIT + gap + b * gap * gap + 0.5);
    if (est < to_int(FLOOR)) est = to_int(FLOOR);

    print("Modeled run length for this kit: ~" + est + " turns.", "blue");
    print("(Anchors: ~" + to_int(BASELINE) + " turns with no IOTMs -- the community"
        + " 1-day guide expects 180-200 -- and ~33 with a full kit."
        + " Savings overlap, so treat this as a planning number, not a promise.)");
    if (!(simOwned contains to_string($item[monodent of the sea])))
        print("No Monodent of the Sea: the estimate assumes you acquire one -- the route aborts without it.", "red");

    string upgrades;
    for pass from 1 to 3 {
        string best;
        float bestWorth;
        foreach name, saving in missing {
            if (saving > bestWorth) { bestWorth = saving; best = name; }
        }
        if (best == "") break;
        upgrades += (upgrades == "" ? "" : ", ") + best + " (~" + bestWorth + ")";
        remove missing[best];
    }
    if (upgrades != "")
        print("Biggest missing savings: " + upgrades, "red");
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
