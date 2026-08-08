import iotm.ash;
import <seedfinder/seedfinder.ash>;

// ─── PER-ACCOUNT CONFIG ───────────────────────────────────────────────────────
// Per-account preferences, set once with the mafia CLI; all default to off.
// uts_godRunGuard, uts_postloopCommand, uts_postLoopRunOutEagleBanish,
// uts_postLoopFarmPearls, uts_postLoopCloverFishy and
// uts_postLoopPrepCodpiece -- see the README for what each does.
//
// ─── GLOBALS ──────────────────────────────────────────────────────────────────
    familiar chosenFamiliar = $familiar[none]; //For kidoblivious
    string choiceStorage = get_property("choiceAdventureScript");
    string CCSStorage = get_property("customCombatScript");
    // "temp" is this script's own scratch CCS. Reading it back means a previous
    // run was killed while it was selected; restoring it would make it the
    // user's permanent setting.
    if (CCSStorage == "temp")
        CCSStorage = "default";
    string choice1387Storage = get_property("choiceAdventure1387");
    string seaFit,boss,modes;
    boolean warnedPantsFallback;
    string [stat] pearlRes = {
        $stat[mysticality]: "hot res",
        $stat[moxie]:       "sleaze res",
        $stat[muscle]:      "spooky res"
    };
    location [stat] pearlLoc = {
        $stat[mysticality]: $location[The Marinara Trench],
        $stat[moxie]:       $location[The Dive Bar],
        $stat[muscle]:      $location[Anemone Mine]
    };
    int [item] pasta_prices;
    foreach it in $items[Frutti di Scatoletta,Pesto alla Marziano,Arrattabbattabiata,Orzo di Riso,Pasta Grimavera,Linguini Ubriacapa,Gnocci Domani,Formica e Pepe,Tubetto Gelatto]{
        pasta_prices[it] = mall_price(it);
    }

// ─── ITEM/OUTFIT UTILITIES ────────────────────────────────────────────────────

    boolean seaOutfit() {
        foreach str in $strings[Crappy Mer-kin Disguise,
            Mer-kin Gladiatorial Gear, Mer-kin Scholar's Vestments] {
            if (have_outfit(str)) {
                seaFit = str;
                return true;
            }
        }
        return false;
    }

    item divingHelmet() {
        item it;
        foreach ite in $items[Mer-kin gladiator mask,
            Mer-kin scholar mask, crappy Mer-kin mask, aerated diving helmet, Elf Guard SCUBA tank] {
            if (item_amount(ite) > 0 || have_equipped(ite)){
                it = ite;
                break;
            }
        }
        return it;
    }

    item tailpiece() {
        item it;
        foreach ite in $items[Mer-kin gladiator tailpiece,
            Mer-kin scholar tailpiece, crappy Mer-kin tailpiece, teflon swim fins] {
            if (item_amount(ite) > 0 || have_equipped(ite)){
                it = ite;
                break;
            }
        }
        return it;
    }

    string swimmingTrunks(){
        string str;
        if (have_effect($effect[driving waterproofly]) > 0)
            return "";
        if (my_path().id == 55){
            str = "really nice swimming trunks,";
        } else if (my_path().id == 0){
            str = "Elf Guard SCUBA tank,";
        }
        return str;
    }
    void equipSwimTrunks(){
        if (have_effect($effect[driving waterproofly]) > 0)
            return;
        if (my_path().id == 55){
            equip($item[really, really nice swimming trunks]);
        } else if (my_path().id == 0){
            equip($item[Elf Guard SCUBA tank]);
        }
    }
    // Pants for the underwater combat outfits. On a path-55 run whose account
    // opted in via the Kramco (see kramcoCoversScaleMail), the scale-mail
    // pull is skipped and the trunks (free from the Old Man, +90 all stats
    // underwater) fill the slot; MP rides on topUpMp()'s free rests and soda
    // water as it already does between casts. Mirrors swimmingTrunks() under
    // Driving Waterproofly: slot left to the maximizer. Path 0 has no
    // scale-mail pull at all (the storage-pull loop is path-55-only), and
    // swimmingTrunks()'s path-0 branch is a waterbreathing container, not
    // pants -- so a path-0 account without a stocked scale-mail leaves the
    // slot to the maximizer, where it used to abort "Missing"; announced
    // once so the change is observable.
    string underwaterPants(){
        if (available_amount($item[scale-mail underwear]) > 0)
            return "scale-mail underwear,";
        if (my_path().id == 55)
            return swimmingTrunks();
        if (!warnedPantsFallback) {
            warnedPantsFallback = true;
            print("No scale-mail underwear in inventory -- leaving the pants slot to the maximizer.", "red");
        }
        return "";
    }

    void buyScholarGear() {
        if (available_amount($item[Mer-kin scholar mask]) == 0
            && !have_equipped($item[Mer-kin scholar mask])) {
            equip($slot[hat], $item[none]);
            equipSwimTrunks();
            buy($coinmaster[Grandma Sea Monkey],1,$item[Mer-kin scholar mask]);
        }
        if (available_amount($item[Mer-kin scholar tailpiece]) == 0
            && !have_equipped($item[Mer-kin scholar tailpiece])) {
            equip($slot[pants], $item[none]);
            equipSwimTrunks();
            buy($coinmaster[Grandma Sea Monkey],1,$item[Mer-kin scholar tailpiece]);
        }
    }

    // if_equip() now lives in iotm.ash: champagneEquip() and gloveEquip() there
    // call it, and imports are parsed before this file's own functions exist.

    // Arm a yellow ray for the next fight if Everything Looks Yellow allows:
    // the parka's dilophosaur ray, or a spitball as the shieldless fallback.
    void yellowRayPrep(){
        if (have_effect($effect[everything looks yellow]) == 0){
            if (have_item($item[jurassic parka]))
                cli_execute("parka dilophosaur; equip jurassic parka");
            else if (have_item($item[April Shower Thoughts shield]))
                create($item[spitball]);
        }
    }

    // Equip the saber only where a turn-free exit actually buys us something.
    // Takes the target location explicitly because callers set equipment up
    // before adv(), so my_location() is still the previous zone here.
    string saberEquip(location loc) {
        if (saberReady() && saberZone(loc))
            return if_equip($item[Fourth of May Cosplay Saber]);
        return "";
    }

    // Lucky! for the hermit-clover adventures. The august scepter grants it free
    // (5 scepter casts per day, and we only spend one on Waffle Day), so reach
    // for that before burning one of the three purchasable 11-leaf clovers.
    void getLucky() {
        if (have_effect($effect[Lucky!]) > 0)
            return;
        if (have_skill($skill[Aug. 2nd: Find an Eleven-Leaf Clover Day])
            && get_property("_aug2Cast") == "false"
            && to_int(get_property("_augSkillsCast")) < 5) {
            use_skill($skill[Aug. 2nd: Find an Eleven-Leaf Clover Day]);
            if (have_effect($effect[Lucky!]) > 0)
                return;
        }
        use($item[11-leaf clover]);
    }

    boolean highShiny(){
        boolean bool;
        if (get_workshed() == $item[Asdon Martin keyfob (on ring)] && to_int(get_property("garbo_valueOfFreeFight")) > to_int(get_property("valueOfAdventure")))
            bool = true;
        return bool;
    }

    // How many of the day's 20 pulls must be held back rather than spent on
    // whatever asks first. Only one of each unique item may be pulled per
    // day, so every entry reserves at most ONE slot.
    int reservedPulls(){
        int n;
        if (available_amount($item[peppermint parasol]) == 0 && available_amount($item[navel ring of navel gazing]) == 0 && available_amount($item[greatest american pants]) == 0)
            n += 1;
        if (available_amount($item[crayon shavings]) < 9)
            n += 1;
        // One slot each, held only while the item is BOTH still wanted and still
        // pullable today. Comma-delimited match so an id cannot match inside a
        // longer one.
        string pulledToday = "," + get_property("_roninStoragePulls") + ",";
        if (available_amount($item[mer-kin pinkslip]) == 0
            && !contains_text(pulledToday, "," + to_int($item[mer-kin pinkslip]) + ","))
            n += 1;
        if (available_amount($item[mer-kin prayerbeads]) < 3
            && !contains_text(pulledToday, "," + to_int($item[mer-kin prayerbeads]) + ","))
            n += 1;
        if (item_amount($item[sea cowbell]) < 3
            && !contains_text(pulledToday, "," + to_int($item[sea cowbell]) + ","))
            n += 1;
        if (available_amount($item[ink bladder]) == 0
            && !contains_text(pulledToday, "," + to_int($item[ink bladder]) + ","))
            n += 1;
        if (have_effect($effect[Jelly Combed]) == 0
            && available_amount($item[comb jelly]) == 0
            && !contains_text(pulledToday, "," + to_int($item[comb jelly]) + ","))
            n += 1;
        // One slot for the skate blade while the war is still open -- same test
        // the cleanup loop uses to decide it has work left. Holey Rollers only
        // fires with a blade equipped; without one the zone serves Picking
        // Sides instead, so the park costs an extra turn and an extra forced
        // noncombat. Unreserved, a discretionary pull elsewhere takes the slot
        // and the phase is left to chance.
        // Path check first: skatePark() is only reachable on path 55 or on a
        // path-0 Yogurt run, and skateParkStatus defaults to "war", so without
        // it a path-0 Shub/Dad run would hold the slot all run for a pull it
        // never makes.
        if ((my_path().id == 55 || boss == "Yogurt")
            && get_property("skateParkStatus") == "war"
            && !contains_text($location[The Skate Park].noncombat_queue, "Holey Rollers")
            && available_amount($item[skate blade]) == 0
            && !contains_text(pulledToday, "," + to_int($item[skate blade]) + ","))
            n += 1;
        // One slot for the Shub deleveler while he is alive and the banked
        // delevelers cannot floor him (multiplicative test -- a raw shavings
        // count passes mixes the CCS's product math rejects). While Yog-Urt
        // is still ahead, two shavings are spoken for: her deleveler ladder
        // throws up to two before Shub is fought, so a bank that is exactly
        // at the floor today is below it by then.
        if (get_property("shubJigguwattDefeated") == "false"
            && shubPrepShort(get_property("yogUrtDefeated") == "false" ? 2 : 0)
            && item_amount($item[null-day exploit]) == 0
            && !contains_text(pulledToday, "," + to_int($item[null-day exploit]) + ","))
            n += 1;
        return n;
    }

    string freeKill() {
        if (have_effect($effect[everything looks red]) == 0 && available_amount($item[everfull dart holster]) > 0)
            return if_equip($item[everfull dart holster]);
        if (highShiny() && have_effect($effect[everything looks yellow]) == 0){
            modes = "parka dilophosaur";
            return if_equip($item[jurassic parka]);
        }
        if (highShiny())
            return "";
        if (to_int(get_property("_assertYourAuthorityCast")) < 3 && (my_location() == $location[An octopus's garden] || my_location() == $location[mer-kin gymnasium] || my_location() == $location[the caliginous abyss]))
            return "Sheriff moustache,Sheriff badge,Sheriff pistol,";
        if (to_int(get_property("_chestXRayUsed")) < 3 && have_item($item[Lil' Doctor&trade; bag]))
            return "Lil' Doctor™ bag,";
        if ((my_basestat($stat[submoxie]) - 22500) > BCZcost("SweatBulletsCasts"))
            return if_equip($item[blood cubic zirconia]);
        return "";
    }

    string freeRun() {
        if (have_effect($effect[Everything Looks Green]) == 0)
            return if_equip($item[spring shoes]);
        if (available_amount($item[greatest american pants]) > 0 && to_int(get_property("_navelRunaways")) < 3 && have_effect($effect[driving waterproofly]) > 0)
            return if_equip($item[greatest american pants]);
        if (available_amount($item[V for vivala mask]) > 0 && get_property("_vmaskBanisherUsed") == false)
            return if_equip($item[V for vivala mask]);
        if (available_amount($item[latte lovers member's mug]) > 0 && get_property("_latteBanishUsed") == false)
            return if_equip($item[latte lovers member's mug]);
        return freeKill();
    }

    string baseball_equip(){
        if (baseballPlayers() < 9 && !highShiny())
            return if_equip($item[baseball diamond]);
        return "";
    }

    string bathysphere(item it) {
        if (!my_familiar().underwater && have_effect($effect[driving waterproofly]) == 0)
            return "little bitty bathysphere,";
        if (it != $item[none])
            return if_equip(it);
        return "";
    }

    boolean badMaxString(string str){
        foreach c in $strings[\,,0,1,2,3,4,5,6,7,8,9] {
            if (contains_text(str, c))
                return true;
        }
        return false;
    }

    void tempEquipment(string maximizerInput, string itemInput){
        string [int] itemMap = split_string(itemInput, ",");
        item [slot] equipmentSelection;
        foreach str in itemMap{
            // Every caller builds itemInput with a trailing comma, and
            // split_string keeps the empty field after it -- skip it instead of
            // reporting a bogus item mismatch on every call.
            if (itemMap[str] == "")
                continue;
            if (to_item(itemMap[str]) == $item[none]){
                print("String to item mismatch, item is " + itemMap[str] + ", notify fart scauce","red");
                continue;
            }
            if (equipmentSelection[to_slot(to_item(itemMap[str]))] == $item[none]){
                equipmentSelection[to_slot(to_item(itemMap[str]))] = to_item(itemMap[str]); 
                continue;
            }
            if (to_slot(to_item(itemMap[str])) == $slot[weapon] && have_skill($skill[Double-Fisted Skull Smashing])){
                if (equipmentSelection[$slot[off-hand]] == $item[none]){
                    equipmentSelection[$slot[off-hand]] = to_item(itemMap[str]); 
                    continue;
                }
            }
            if (to_slot(to_item(itemMap[str])) == $slot[acc1]){
                if (equipmentSelection[$slot[acc2]] == $item[none]){
                    equipmentSelection[$slot[acc2]] = to_item(itemMap[str]); 
                    continue;
                }
                if (equipmentSelection[$slot[acc3]] == $item[none]){
                    equipmentSelection[$slot[acc3]] = to_item(itemMap[str]); 
                    continue;
                }
            }
        }
        // A still-free off-hand on a drop-farming trip carries the Kramco:
        // its goblins are free fights that burn delay wherever they land.
        // Anything pinned above (champagne bottle, baseball diamond, a
        // Double-Fisted second weapon) keeps the slot.
        if (contains_text(maximizerInput, "item drop")
            && equipmentSelection[$slot[off-hand]] == $item[none]
            && have_item($item[Kramco Sausage-o-Matic&trade;]))
            equipmentSelection[$slot[off-hand]] = $item[Kramco Sausage-o-Matic&trade;];
        string maximizerString = maximizerInput;
        foreach slo in equipmentSelection{
            if (available_amount(equipmentSelection[slo]) == 0)
                abort("Missing " + equipmentSelection[slo]);
            if (badMaxString(to_string(equipmentSelection[slo])))
                maximizerString += ", equip [" + to_int(equipmentSelection[slo]) + "]";
            else
                maximizerString += ", equip " + equipmentSelection[slo];
        }
        if (!maximize(maximizerString, false))
            abort("Maximizer failed");
        if (modes != "")
            cli_execute(modes);
    }

// ─── MOOD ─────────────────────────────────────────────────────────────────────

    void use_familiar(string mod){
        if (mod == "-combat"){
            foreach fam in $familiars[peace turkey, disgeist]{
                if (have_familiar(fam)){
                    use_familiar(fam);
                    return;
                }
            }
        }
        if (mod == "combat"){
            foreach fam in $familiars[Jumpsuited Hound Dog]{
                if (have_familiar(fam)){
                    use_familiar(fam);
                    return;
                }
            }
        }
        familiar fam;
        if (mod == "itdrop"){
            if (chosenFamiliar != $familiar[none])
                fam = chosenFamiliar;
            else if (highShiny() && have_familiar($familiar[Melodramedary]) && to_int(get_property("camelSpit")) < 100 && to_slot(divingHelmet()) != $slot[hat])
                fam = $familiar[Melodramedary];
            else if (have_familiar($familiar[Red-Nosed Snapper]))
                fam = $familiar[Red-Nosed Snapper];
            else if (have_effect($effect[driving waterproofly]) > 0)
                fam = $familiar[jill-of-all-trades];
            // Underwater the jellyfish is a full Fairy, so this costs nothing
            // against Grouper Groupie and adds Extract Jelly on top.
            else if (jellyfishReady())
                fam = $familiar[Space Jellyfish];
        }
        if (fam == $familiar[none]){
            fam = $familiar[grouper groupie];
        }
        use_familiar(fam);
        // Prince George goes on whichever familiar the item setup just settled
        // on, and only the first time, since the costume is once a day and
        // lasts until rollover.
        if (mod == "itdrop")
            mummery();
        return;
    }

    void mood(string mod) {
        void applyEffects(effect [int] effects) {
            foreach i, ef in effects {
                if (to_skill(ef) != $skill[none] && !have_skill(to_skill(ef)))
                    continue;
                if (ef == $effect[Party Soundtrack] && !have_item($item[Cincho de Mayo]))
                    continue;
                if (ef == $effect[Who's Going to Pay This Drunken Sailor?] && !have_item($item[Cincho de Mayo]))
                    continue;
                if (have_effect(ef) == 0)
                    cli_execute(ef.default);
            }
            print("Item drop is " + numeric_modifier("item drop"));
        }

        switch (mod) {
            case "itdrop":
                effect [int] itdrop = {
                    $effect[Who's Going to Pay This Drunken Sailor?],
                    $effect[Fat Leon's Phat Loot Lyric], $effect[Lubricating Sauce],
                    $effect[Thoughtful Empathy], $effect[Singer's Faithful Ocelot],
                    $effect[Leash of Linguini], $effect[Empathy],
                    $effect[donho's bubbly ballad], $effect[the ballad of richie thingfinder]
                };
                applyEffects(itdrop);
                // Free +item from the Source Terminal. Guarded internally, so
                // calling it on every itdrop setup just tops the buff back up
                // when it lapses and is a no-op the rest of the time.
                sourceEnhance();
                // Same idea for the briefcase's +50% item tab buff: internally
                // guarded, so this just re-acquires it when the 50 turns lapse.
                briefcase();
                break;
            case "superitdrop":
                effect [int] superitdrop = {$effect[Hustlin'], $effect[Steely-Eyed Squint],
                    $effect[Party Soundtrack], $effect[Best Pals]};
                applyEffects(superitdrop);
                break;
            case "-combat":
                foreach ef in $effects[the sonata of sneakiness, ultra-soft steps,
                    Wild and Westy!, hiding from seekers, life goals,
                    Smooth Movements, Apriling Band Patrol Beat,
                    silent running, feeling lonely] {
                    if (have_effect(ef) == 0) {
                        if (ef == $effect[ultra-soft steps]
                            && item_amount($item[ultra-soft ferns]) == 0) continue;
                        if (ef == $effect[life goals]
                            && item_amount($item[Life Goals Pamphlet]) == 0) continue;
                        // Ownership first: the cli command hard-errors
                        // without the helmet.
                        if (ef == $effect[Apriling Band Patrol Beat] && (!have_item($item[Apriling band helmet]) || total_turns_played() < to_int(get_property("nextAprilBandTurn")))) continue;
                        if (to_skill(ef) != $skill[none] && !have_skill(to_skill(ef))) continue;
                        cli_execute(ef.default);
                    }
                }
                print("Combat rate is " + numeric_modifier("Combat Rate"));
                break;
            case "combat":
                foreach ef in $effects[Carlweather's Cantata of Confrontation,
                    Fresh Breath, Musk of the Moose, Crunchy Steps, Apriling Band Battle Cadence,
                    Towering Muscles, Attracting Snakes, Bloodbathed] {
                    if (have_effect(ef) == 0) {
                        if (ef == $effect[Crunchy Steps]
                            && item_amount($item[crunchy brush]) == 0) continue;
                        if (ef == $effect[Towering Muscles]
                            && (get_property("yogUrtDefeated") == "false"
                                || to_int(get_property("_photoBoothEffects")) >= 3)) continue;
                        if (ef == $effect[Fresh Breath]
                            && get_property("_aug6Cast") == "true") continue;
                        if (ef == $effect[Bloodbathed]
                            && lowShiny() == true) continue;
                        if (ef == $effect[Apriling Band Battle Cadence] && (!have_item($item[Apriling band helmet]) || total_turns_played() < to_int(get_property("nextAprilBandTurn")))) continue;
                        if (to_skill(ef) != $skill[none] && !have_skill(to_skill(ef))) continue;
                        cli_execute(ef.default);
                    }
                }
                print("Combat rate is " + numeric_modifier("Combat Rate"));
                break;
            case "hotres":
            case "spookyres":
            case "stenchres":
                foreach ef in $effects[Astral Shell, Minor Invulnerability,
                    Elemental Saucesphere] {
                    if (ef == $effect[Minor Invulnerability]
                        && item_amount($item[scroll of minor invulnerability]) == 0) continue;
                    if (to_skill(ef) != $skill[none] && !have_skill(to_skill(ef))) continue;
                    if (have_effect(ef) == 0) cli_execute(ef.default);
                }
                break;
            case "sleazeres":
            case "coldres":
                foreach ef in $effects[Astral Shell, Minor Invulnerability,
                    Elemental Saucesphere, scarysauce] {
                    if (ef == $effect[Minor Invulnerability]
                        && item_amount($item[scroll of minor invulnerability]) == 0) continue;
                    if (to_skill(ef) != $skill[none] && !have_skill(to_skill(ef))) continue;
                    if (have_effect(ef) == 0) cli_execute(ef.default);
                }
                break;
            case "colosseum":
                foreach ef in $effects[Ultraheart, Carol of the Hells,
                    Elron's Explosive Etude, Big, Favored by Lyle,
                    The Magical Mojomuscular Melody,
                    Tubes of Universal Meat, Mariachi Moisture,Everybody Calls Him Gorgon] {
                    if (to_skill(ef) != $skill[none] && !have_skill(to_skill(ef))) continue;
                    if (ef == $effect[Ultraheart] && get_property("heartstoneBuffUnlocked") == false) continue;
                    if (ef == $effect[Everybody Calls Him Gorgon] && !lowShiny()) continue;
                    if (have_effect(ef) == 0) cli_execute(ef.default);
                }
                break;
        }
    }

// Seeding
    int seedPoss(){
        SeedData[int] possibleSeeds=find_seeds();
        return count(possibleSeeds);
    }

    boolean isKBandSushiEnough(){
        SeedData[int] possibleSeeds=find_seeds();
        boolean bool = true;
        string DS4to7poss;
        foreach idx, seed in possibleSeeds {
            if (!contains_text(DS4to7poss,possibleSeeds[idx].dreadscroll[4]+":"+possibleSeeds[idx].dreadscroll[7])){
                DS4to7poss += possibleSeeds[idx].dreadscroll[4]+":"+possibleSeeds[idx].dreadscroll[7];
            } else {
                bool = false;
            }
        }
        return bool;
    }

// ─── Other Utilies ───────────────────────────────────────────────────────────────────

    void blackGlass(){
        use_familiar("itdrop");
        equip($item[really, really nice swimming trunks]);
        visit_url("monkeycastle.php?who=1");
        if (available_amount($item[black glass]) == 0) 
            buy($coinmaster[Big Brother], 1, $item[black glass]);
    }

    void useMapIfAvailable() {
        if (highShiny())
            return;
        if (!have_equipped($item[backup camera])) return;
        boolean isFreeMonster = $strings[
            kid who is too old to be Trick-or-Treating,
            suburban security civilian,
            vandal kid,
            Black Crayon Golem
        ] contains get_property("lastCopyableMonster");
        if (isFreeMonster) return;
        if (get_property("_mapToACandyRichBlockUsed") == "false") {
            if (item_amount($item[map to a candy-rich block]) > 0)
                use($item[map to a candy-rich block]);
        }
        if (get_property("_mapToACandyRichBlockUsed") == "true")
            candy("fight");
    }

    string adjacentCaverns(int x_coor, int y_coor) {
        buffer buf;
        int [int] nums = {
            0: (8 * y_coor) + (x_coor - 1),
            1: (8 * y_coor) + (x_coor + 1),
            2: (8 * (y_coor - 1)) + x_coor,
            3: (8 * (y_coor + 1)) + x_coor
        };
        foreach i in nums {
            matcher m = create_matcher(
                "#" + nums[i] + "<img src=\"[^\"]*/([^\"]+)\\.gif\"",
                get_property("mineLayout3")
            );
            if (m.find())
                append(buf, to_string(m.group(1)));
        }
        return to_string(buf);
    }

    boolean doSWord(){
        boolean bool;
        if (have_familiar($familiar[Sword of S Words]) && to_int(get_property("swordOfSWordsMonster")) == 776){
            if ((highShiny()) && item_amount($item[sea lasso]) < 6)
                bool = true;
            if (!have_item($item[closed-circuit pay phone]) && item_amount($item[sea lasso]) < 4)
                bool = true;
        }
        return bool;
    }

    int count_summons(){
        int n;
        if (get_property("_photocopyUsed") == "false")
            n += 1;
        if (available_amount($item[combat lover's locket]) > 0){
            string [int] lockets = split_string(get_property("_locketMonstersFought"), ",");
            n += 3-count(lockets);
        }
        if (have_familiar($familiar[chest mimic]))
            n += floor($familiar[chest mimic].experience/200);
        return n;
    }
    
    void useAutumnaton(){
        use($item[autumn-aton]);
        string [string] upgradeLocation = {
            "mid indoor":"rightleg1",
            "low underground":"leftleg1",
            "mid outdoor":"rightarm1",
            "low indoor":"leftarm1",
            "high underground":"collectionprow1"
        };
        string autumnOptions = visit_url("inv_use.php?" + my_hash() + "&which=3&whichitem=10954");
        int [int] locations;
        matcher m = create_matcher(
            "<option\\s+value=\"([0-9]+)\">\\s*([^<]+?)\\s*</option>",
            autumnOptions
        );

        int n;
        while (m.find()) {
            int id = to_int(m.group(1));
            string name = m.group(2);
            locations[n] = id;
            n += 1;
        }

        foreach key in locations {
            if (locations[key] == to_int($location[anemone mine]) && available_amount($item[mer-kin digpick]) == 0){
                cli_execute("autumnaton send anemone mine");
                return;
            }
        }
        foreach key in locations {
            if (locations[key] == to_int($location[Shadow Rift (The Misspelled Cemetary)])){
                cli_execute("autumnaton send Shadow Rift");
                return;
            }
        }
        foreach key in locations {
            string type = (to_location(locations[key]).difficulty_level + " " + to_location(locations[key]).environment);
            if (!contains_text(get_property("autumnatonUpgrades"),upgradeLocation[type]) && upgradeLocation[type] != ""){
                cli_execute("autumnaton send " + to_location(locations[key]));
                return;
            }
        }
        cli_execute("autumnaton send noob cave");
        return;
    }

    int delevelers(){
        int n;
        foreach it in $items[Mer-kin mouthsoap,crayon shavings,table tennis ball,Mer-kin mouthsoap,sea cowbell]{
            if (item_amount(it) > 0)
                n += 1;
        }
        return n;
    }

// ─── POST ADVENTURE ───────────────────────────────────────────────────────────
    void eatSushi(){
        string [item] sushi_map = {
            $item[beefy fish meat]:	"beefy nigiri",
            $item[glistening fish meat]:	"glistening nigiri",
            $item[slick fish meat]:	"slick nigiri"
        };
        foreach it in sushi_map{
            if (item_amount(it) > 0) {
                cli_execute("make " + sushi_map[it]);
                return;
            }
        }
    }

    void dreadSeedCheck(){
        if (seedPoss() == 1){
            for x from 1 to 8{
                if (get_property("dreadScroll" + x) == 0){
                    SeedData[int] possibleSeeds=find_seeds();
                    foreach idx, seed in possibleSeeds 
                        set_property("dreadScroll" + x,possibleSeeds[idx].dreadscroll[x-1]);
                }
            }
        } else {
            print(seedPoss() + " possible seeds right now");
        }
    }

    // Mafia's autorecovery aborts the run when it cannot reach its MP target
    // -- and with no meat it cannot buy a single restorer. Free rests are
    // spent first (they cost nothing but compete with the Cincho), then NPC
    // soda water only while meat covers it.
    void topUpMp(int target) {
        while (my_mp() < target
            && total_free_rests() > to_int(get_property("timesRested")))
            cli_execute("camp rest free");
        // Same junk sale post_adv() makes when meat runs low: spare scales
        // fund the soda water.
        if (my_mp() < target && my_meat() < 300)
            foreach it in $items[dull fish scale, rough fish scale]
                autosell(item_amount(it), it);
        while (my_mp() < target && my_meat() >= npc_price($item[soda water])) {
            int need = min((target - my_mp()) / 4 + 1,
                my_meat() / npc_price($item[soda water]));
            buy(need, $item[soda water]);
            use(min(need, item_amount($item[soda water])), $item[soda water]);
        }
        if (my_mp() < target)
            print("MP top-up stalled at " + my_mp() + "/" + target
                + " -- out of free rests and meat. Autorecovery may abort;"
                + " sell some junk or fight for meat and rerun.", "red");
    }

    // Lift Beaten Up by the cheapest route available. The Walrus cast needs
    // MP the flows that lose fights often lack (Shub prep empties the pool
    // and turns MP restore off), so top up before casting; without the
    // skill, rest -- free rests first, then campground turns.
    void liftBeatenUp() {
        if (have_effect($effect[beaten up]) == 0)
            return;
        if (have_skill($skill[Tongue of the Walrus])) {
            topUpMp(mp_cost($skill[Tongue of the Walrus]));
            // A free rest inside the top-up may already have lifted it --
            // don't dump the just-restored MP on a debuff that's gone.
            if (have_effect($effect[beaten up]) > 0
                && my_mp() >= mp_cost($skill[Tongue of the Walrus]))
                use_skill($skill[Tongue of the Walrus]);
        }
        if (have_effect($effect[beaten up]) > 0)
            cli_execute("rest");
    }

    // Mafia's recovery thresholds are ratios of max HP, but what this script
    // actually wants is an absolute floor -- 570 HP, or 800 in the gymnasium,
    // or full in the colosseum. Storing an absolute as a ratio means the ratio
    // is only true for the gear it was computed in, so it has to be recomputed
    // whenever the outfit moves max HP. post_adv() does that after every adv();
    // the pearl walk has to ask for it, because adv1() does not go through
    // post_adv() and its per-zone re-dress swings max HP by about half.
    void setRecoveryTargets() {
        float mpTar = min(1, 250 / to_float(my_maxmp()));
        float hpTar;
        if (my_location() == $location[mer-kin colosseum]){
            hpTar = 1;
        } else if (my_location() == $location[mer-kin gymnasium]){
            hpTar = min(1, 800 / to_float(my_maxhp()));
        } else {
            hpTar = min(1, 570 / to_float(my_maxhp()));
        }
        string hpAutoRecovery = to_float(round(hpTar * 0.75 * 10000))/10000;
        string hpAutoRecoveryTarget = to_float(round(hpTar * 10000))/10000;
        string mpAutoRecovery = to_float(round(mpTar * 0.5 * 10000))/10000;
        string mpAutoRecoveryTarget = to_float(round(mpTar * 10000))/10000;
        set_property("hpAutoRecovery",       hpAutoRecovery);
        set_property("hpAutoRecoveryTarget", hpAutoRecoveryTarget);
        set_property("mpAutoRecovery",       mpAutoRecovery);
        set_property("mpAutoRecoveryTarget", mpAutoRecoveryTarget);
    }

    void post_adv() {
        if (get_property("_lastCombatLost") == "true"){
            // liftBeatenUp() rather than the old inline pair: with the
            // Walrus known, the rest fallback here was unreachable, and a
            // Shub loss reaches this line with MP deliberately emptied and
            // recovery off -- the cast failed and the rerun started still
            // Beaten Up.
            liftBeatenUp();
            set_property("_lastCombatLost", "false");
            abort("It appears you lost the last combat, look into that");
        }
        modes = "";
        if ((get_property("dolphinItem") == "Mer-kin prayerbeads" || get_property("dolphinItem") == "rusty rivet") && have_item($item[durable dolphin whistle]) && lowShiny())
            use($item[durable dolphin whistle]);
        if (have_effect($effect[really quite poisoned]) > 0)
            cli_execute("uneffect really quite poisoned");
        if (get_property("NCtoC") == "true")
            set_property("NCtoC", "false");
        if (my_location() == $location[mer-kin elementary school] && to_monster(get_property("lastEncounter")) == $monster[none] && $ints[396, 397, 398, 399, 400, 401] contains last_choice()){
            buffer elementaryQueue = to_buffer(get_property("elementaryQueue"));
            append(elementaryQueue, ", " + last_choice());
            delete(elementaryQueue,0,5);
            set_property("elementaryQueue",to_string(elementaryQueue));
        }
        if (my_meat( ) < 300){
            foreach it in $items[dull fish scale, rough fish scale]{
                autosell( item_amount(it), it );
            }
        }
        if (get_property("isMerkinHighPriest") == "false" && get_property("seahorseName") != ""){
            dreadSeedCheck();
        }
        if (my_path().id == 55){
            if (my_adventures() == 0) {
                if (item_amount($item[astral pilsner]) == 0
                    && item_amount($item[astral six-pack]) > 0) {
                    use($item[astral six-pack]);
                    cli_execute("shrug Donho's Bubbly Ballad");
                    if (have_skill($skill[The Ode to Booze]))
                        use_skill($skill[the ode to booze]);
                    drink($item[astral pilsner]);
                } else if (item_amount($item[astral pilsner]) > 0) {
                    cli_execute("shrug Donho's Bubbly Ballad");            
                    if (have_skill($skill[The Ode to Booze]))
                        use_skill($skill[the ode to booze]);
                    drink($item[astral pilsner]);
                } else {
                    abort("no more easy diet");
                }
            }
            if (have_effect($effect[Driving Waterproofly]) == 0) {
                if (get_workshed() == $item[Asdon Martin keyfob (on ring)]){
                    if (get_fuel() == 0 && !contains_text(get_property("_roninStoragePulls"),"7372")){
                        pullSequence($item[pie man was not meant to eat]);
                        cli_execute("asdonmartin fuel 1 pie man was not meant to eat");
                    }
                    if (get_fuel() >= 37)
                        cli_execute("asdonmartin drive Waterproofly");
                    else
                        abort("Asdon Martin owners, fuel car manually until I can get some guidance on which foods are best");
                }
            }
            if (have_effect($effect[fishy]) == 0) {
                if (have_item($item[fishy pipe]) && item_amount($item[closed-circuit pay phone]) > 0 && have_item($item[Monodent of the Sea]) && have_item($item[Platinum Yendorian Express Card]) && get_property("_fishyPipeUsed") == "false" && lowShiny() == false){
                        if (item_amount($item[fishy pipe]) == 0)
                            cli_execute("pull fishy pipe");
                        use($item[fishy pipe]);
                } else if (highShiny() || lowShiny() && !contains_text(get_property("_roninStoragePulls"), "9466")){
                    item cheap_pasta;
                    int lowest_value = 999999999;

                    foreach it, value in pasta_prices {
                        if (value < lowest_value) {
                            lowest_value = value;
                            cheap_pasta = it;
                        }
                    }
                    if (pullSequence(cheap_pasta))
                        eat(cheap_pasta);
                    if (pullSequence($item[Aldebaran sardines]))
                        eat($item[Aldebaran sardines]);
                } else if (!contains_text(get_property("_roninStoragePulls"), "10360")) {
                    pullSequence($item[fish sauce]);
                    chew($item[fish sauce]);
                } else if (get_property("dreadScroll7") == "0"
                    && item_amount($item[mer-kin worktea]) > 0
                    && item_amount($item[mer-kin dreadscroll]) > 0) {
                    retrieve_item($item[white rice]);
                    eatSushi();
                } else {
                    retrieve_item($item[white rice]);
                    eatSushi();
                }
                if (have_effect($effect[fishy]) == 0)
                    abort("acquire fishy failed");
            }
        } else if (my_path().id == 0){
            if (item_amount($item[sea lasso]) == 0)
                retrieve_item($item[sea lasso]);
            if (my_adventures() == 0) {
                abort("Out of adventures, run consume");
            }
            if (have_effect($effect[fishy]) == 0 && have_effect($effect[Driving Waterproofly]) == 0) {
                if (have_item($item[fishy pipe]) && get_property("_fishyPipeUsed") == "false"){
                    use($item[fishy pipe]);
                } else if (my_spleen_use() < spleen_limit()) {
                    retrieve_item($item[fish sauce]);
                    chew($item[fish sauce]);
                } else {
                    abort("get fishy or driving waterproofily");
                }
            }
        }

        if (get_property("autumnatonQuestLocation") == "" && item_amount($item[autumn-aton]) > 0) {
            useAutumnaton();
        }
        if (to_int(get_property("_universeCalculated")) < min(2, to_int(get_property("skillLevel144"))) && uniAdv <= my_adventures()) {
            if (universe() == my_adventures()) {
                cli_execute("numberology 69");
            }
        }

        if (to_int(get_property("trainsetPosition"))
            >= to_int(get_property("lastTrainsetConfiguration")) + 42) {
            visit_url("campground.php?action=workshed");
            trainset();
        }

        if (have_effect($effect[resined]) == 0
            && item_amount($item[inflammable leaf]) > 50)
            use($item[distilled resin]);

        if (have_item($item[bat wings])
            && (my_mp() < (my_maxmp() - 1000) || my_mp() < 150)) {
            equip($item[bat wings]);
            use_skill($skill[rest upside down]);
        }

        // VHS tape monster follow-up
        if (total_turns_played()
            >= to_int(get_property("spookyVHSTapeMonsterTurn")) + 8
            && get_property("spookyVHSTapeMonster") != "") {
            if (doSWord())
                use_familiar($familiar[sword of s words]);
            else
                use_familiar("itdrop");
            tempEquipment(pearlRes[my_primestat()],if_equip(divingHelmet()) + if_equip($item[legendary seal-clubbing club]) + "shark jumper," + underwaterPants() + bathysphere($item[none]));
            adv1(pearlLoc[my_primestat()]);
        }

        // VHS tape recording window
        if (item_amount($item[spooky VHS tape]) > 0
            && get_property("spookyVHSTapeMonster") == ""
            && to_int(get_property("momSeaMonkeeProgress")) < 33
            && to_int(get_property("momSeaMonkeeProgress")) > 22) {
            use_familiar("itdrop");
            string conditional;
            if (!contains_text(get_property("banishedMonsters"), "school of many"))
                conditional += "monodent of the sea,";
            tempEquipment("item drop",if_equip(divingHelmet()) + "shark jumper," + underwaterPants() + "black glass," + if_equip($item[peridot of peril]) 
                + freeKill() + bathysphere($item[toy cupid bow]) + conditional);
            adv1($location[The Caliginous Abyss]);
        }

        // Club em next week monster follow-up
        if (total_turns_played()
            >= to_int(get_property("clubEmNextWeekMonsterTurn")) + 8
            && get_property("clubEmNextWeekMonster") != "") {
            if (my_location() != $location[mer-kin elementary school]
                && !(my_location() == $location[mer-kin library])) {
                use_familiar("itdrop");
                tempEquipment(pearlRes[my_primestat()],swimmingTrunks() + "legendary seal-clubbing club," + bathysphere($item[none]));
                adv1(pearlLoc[my_primestat()]);
            }
        }

        setRecoveryTargets();

        if (item_amount($item[whirled peas]) >= 2)
            retrieve_item($item[handful of split pea soup]);
    }

    void adv(location loc) {
        adv1(loc);
        post_adv();
    }

// ─── INITIALIZATION ───────────────────────────────────────────────────────────

    void initialization() {
        if (get_revision() < 29057)
            abort("Please update mafia to newer than 29057");
        // A pearl farm that aborted mid-loop leaves this set, and a stuck
        // "true" reduces the whole CCS to cleanUp(); in-run zones need the
        // full consult.
        set_property("_utsPearlFarm", "false");
        if (chosenFamiliar != $familiar[none]){
            use_familiar($familiar[none]);
            int itdrop1 = numeric_modifier("item drop");
            use_familiar(chosenFamiliar);
            if (numeric_modifier("item drop") <= itdrop1){
                if (!user_confirm("Chosen familiar is not +item, would make some RNG worse. Continue?"))
                    abort();
            }
        }
        if (get_property("autoSatisfyWithNPCs") == "false")
            abort("set autoSatisfyWithNPCs = true, the script isn't going to work if it's false");
        iotmChecklist();
        if (my_path().id == 55)
            pullChecklist();
        write_ccs(to_buffer("consult UnderTheSeaCCS.ash \n abort"), "temp");
        set_ccs("temp");
        set_property("battleAction", "custom combat script");
        // lowShiny() is now a function in iotm.ash; see the note there.
        if (get_property("questS01OldGuy") == "unstarted"){
            set_property("ascensionTime",time_to_string( ));
            visit_url("place.php?whichplace=sea_oldman&action=oldman_oldman");
        }
        if (to_int(get_property("_photoBoothEquipment")) < 3){
            foreach it in $items[sheriff pistol, sheriff moustache, sheriff badge]{
                if (available_amount(it) == 0)
                    cli_execute("photobooth item " + it);
            }
        }
        if (to_int(get_property("_photoBoothEquipment")) < 3)
            abort("It seems that your clan may have an incomplete photobooth, join BAFH and rerun");
        if (my_path().id == 0){
            if (my_fullness() > (fullness_limit() - 5))
                abort("Have at least 4 fullness");
            if (my_spleen_use() > (spleen_limit() - 5))
                abort("Have at least 5 spleen");
        }
        if (have_item($item[tiny stillsuit]) && have_familiar($familiar[tickle-me emilio])){
            use_familiar($familiar[tickle-me emilio]);
            equip($item[tiny stillsuit]);
        }
        if (available_amount($item[black glass]) == 0 && item_amount($item[sand dollar]) > 13)
            blackGlass();
        if (my_path().id == 55){
            if (get_property("questM05Toot") == "started") {
                council();
                visit_url("tutorial.php?action=toot");
                council();
            }

            // Use/open daily items
            foreach it in $items[letter from King Ralph XI, pork elf goodies sack,
                sushi-rolling mat, 2002 Mr. Store Catalog] {
                if (it == $item[2002 Mr. Store Catalog]
                    && get_property("_2002MrStoreCreditsCollected") == "true")
                    continue;
                if (item_amount(it) > 0)
                    use(it, item_amount(it));
            }

            // Daily skills
            foreach sk in $skills[Aug. 24th: Waffle Day!, Summon Kokomo Resort Pass] {
                if (have_skill(sk))
                    use_skill(sk);
            }

            // Open the run with +item up rather than waiting for the first
            // farming loop to ask for it.
            sourceEnhance();

            // Slot duplicate.edu now so the skill is in hand for the first
            // fat table the route kills (the golem recall, or sooner on
            // saberless kits), and claim the day's embers.
            sourceEducate();
            cargoPocket();
            garbageTote();
            censer();

            // One free saber upgrade per day. Choice 1386 is answered in
            // UnderTheSea_Choice.ash; we take the familiar weight option, since
            // the elemental resistance one only matters for farming unblemished
            // pearls and those are smuggled in via the codpiece.
            if (have_item($item[Fourth of May Cosplay Saber])
                && get_property("_saberMod") == "0") {
                // mafia may auto-resolve the choice this visit redirects
                // into (choiceAdventure1386 steers it to option 4, the +10
                // familiar weight chip). Only answer a choice that is still
                // open, and only with an option the page actually offers --
                // otherwise leave via Maybe Later.
                step("initialization: saber daily upgrade (choice 1386)");
                set_property("choiceAdventure1386", "4");
                visit_url("main.php?action=may4");
                if (handling_choice() && last_choice() == 1386) {
                    if (available_choice_options() contains 4)
                        run_choice(4);
                    else
                        run_choice(5);
                }
            }

            // Autosell junk gems
            foreach it in $items[hamethyst, baconstone, porquoise, kokomo resort pass] {
                if (it == $item[porquoise] && have_item($item[portable pantogram]))
                    continue;
                autosell(item_amount(it), it);
            }

            step("initialization: Mayam rings");
            // MAYAM rings
            if (get_property("_mayamSymbolsUsed") == "" && have_item($item[Mayam Calendar])) {
                if (!use_familiar($familiar[chest mimic]))
                    use_familiar("itdrop");
                cli_execute("mayam rings vessel yam cheese explosion;"
                    + " mayam rings fur lightning eyepatch yam;"
                    + " mayam rings eye meat yam clock");
            }

            // Leprecondo setup
            if (get_property("leprecondoInstalled") == "0,0,0,0" && item_amount($item[Leprecondo]) > 0){
                if (highShiny())
                    leprecondo("10,11,12,24,4,5,6");
                else
                    leprecondo("22,24,12,11,10,4,5,6");
            }

            // Misc daily setup
            visit_url("campground.php?preaction=leaves");

            if (item_amount($item[S.I.T. Course Completion Certificate]) > 0
                && get_property("_sitCourseCompleted") == "false")
                use($item[S.I.T. Course Completion Certificate]);

            if (get_property("_aprilBandInstruments") == "0" && have_item($item[Apriling band helmet])){
                cli_execute("aprilband item tuba");
                if (highShiny()){
                    cli_execute("aprilband item quad tom");
                } else if (have_familiar($familiar[chest mimic])){
                    use_familiar($familiar[chest mimic]);
                    cli_execute("aprilband item piccolo; aprilband play piccolo; aprilband play piccolo; aprilband play piccolo");
                }
            }

            if (have_item($item[McHugeLarge duffel bag]))
                visit_url("inventory.php?action=skiduffel");

            if (get_property("_aprilShowerGlobsCollected") == "false"
                && have_item($item[April Shower Thoughts shield]))
                visit_url("inventory.php?action=shower");

            // Mr Store 2002 credits — buy in specific order
            if (get_property("availableMrStore2002Credits") == "3") {
                if (highShiny()){
                    create(3, $item[Spooky VHS Tape]);
                } else {
                    foreach it in $items[pro skateboard, Spooky VHS Tape, Spooky VHS Tape] {
                        create(1, it);
                    }
                }
            }

            step("initialization: workshed");
            // Workshed activation
            if (get_property("_workshedItemUsed") == "false" && get_workshed() == $item[none]) {
                if (available_amount($item[Asdon Martin keyfob (on ring)]) > 0)
                    use($item[Asdon Martin keyfob (on ring)]);
                else if (item_amount($item[portable Mayo Clinic]) > 0)
                    use($item[portable Mayo Clinic]);
                else if (item_amount($item[model train set]) == 1)
                    use($item[model train set]);
                else if (have_item($item[TakerSpace letter of Marque])) {
                    use($item[TakerSpace letter of Marque]);
                    if ((get_property("_takerSpaceSuppliesDelivered") == "false"
                        || get_property("takerSpaceGold") == "1")
                        && get_workshed() == $item[TakerSpace letter of Marque])
                        create(1, $item[anchor bomb]);
                }
            }

            step("initialization: storage pulls");
            // Storage pulls for sea gear
            foreach it in $items[mer-kin sneakmask, sea lasso, shark jumper,
                scale-mail underwear, Congressional Medal of Insanity,
                Flash Liquidizer Ultra Dousing Accessory] {
                if (available_amount(it) == 0 && !contains_text(get_property("_roninStoragePulls"), to_int(it))) {
                    if (it == $item[sea lasso] && (lowShiny() == true || (have_familiar($familiar[Sword of S Words]) && count_summons() >= 3)))
                        continue;
                    // Path-55 only, so path-0 outfits keep their scale-mail
                    // untouched; underwaterPants() wears the trunks in its
                    // place everywhere it was hard-named.
                    if (it == $item[scale-mail underwear] && my_path().id == 55
                        && kramcoCoversScaleMail())
                        continue;
                    if (storage_amount(it) == 0){
                        if (it == $item[Congressional Medal of Insanity])
                            { print("No Congressional Medal of Insanity in storage -- skipping it (optional, the script won't buy one).", "red"); continue; }
                        buy_using_storage(it);
                    }
                    take_storage(1, it);
                }
            }

            //DoD Spading
            if (get_property("lastBangPotion827") == ""){
                foreach it in $items[ten-leaf clover,large box] {
                    if (available_amount(it) == 0 && !contains_text(get_property("_roninStoragePulls"), to_int(it))) {
                        if (storage_amount(it) == 0){
                            buy_using_storage(it);
                        }
                        take_storage(1, it);
                    }
                    if (available_amount($item[large box]) > 0)
                        create($item[blessed large box]);
                    if (available_amount($item[blessed large box]) > 0)
                        use($item[blessed large box]);
                }
            }
        }
        // Asdon missile fuel: free_kill() fires the missile (one free kill
        // a day, 100 fuel) only on mid-shiny accounts, and ronin blocks
        // the mall, so only aftercore can top the tank up. Soda bread
        // fuels roughly its adventure yield (~6 a loaf), hence 17.
        if (get_workshed() == $item[Asdon Martin keyfob (on ring)] && !highShiny()
            && my_path().id == 0 && get_property("_missileLauncherUsed") == "false"
            && get_property("_utsMissileFailed") != "true"
            && get_fuel() < 100 && retrieve_item(17, $item[loaf of soda bread]))
            cli_execute("asdonmartin fuel 17 loaf of soda bread");
    }



// ─── Questing ─────────────────────────────────────────────────────────────

    void unlockGuild() {
        // Stat → quest property / location map
        string [stat] questProp = {
            $stat[mysticality]: "questG07Myst",
            $stat[moxie]:       "questG08Moxie",
            $stat[muscle]:      "questG09Muscle"
        };
        location [stat] questLoc = {
            $stat[mysticality]: $location[The Haunted Pantry],
            $stat[moxie]:       $location[The Sleazy Back Alley],
            $stat[muscle]:      $location[The Outskirts of Cobb's Knob]
        };

        stat ps = my_primestat();
        string qprop = questProp[ps];

        if (get_property(qprop) != "finished") {
            // Moxie shortcut — tearaway pants skip the grind
            if (ps == $stat[moxie] && have_item($item[tearaway pants])) {
                equip($item[tearaway pants]);
                visit_url("guild.php?place=challenge");
                return;
            }
            if (get_property(qprop) == "unstarted")
                visit_url("guild.php?place=challenge");
            if (doSWord() == true)
                use_familiar($familiar[Sword of S Words]);
            else if (have_familiar($familiar[red-nosed snapper]))
                use_familiar("itdrop");
            else
                use_familiar("-combat");
            if (my_familiar() == $familiar[red-nosed snapper])
                cli_execute("snapper fish");
            mood("itdrop");
            while (get_property(qprop) == "started") {
                tempEquipment("item drop","monodent of the sea," + if_equip($item[M&ouml;bius ring]) + if_equip($item[everfull dart holster])
                    + if_equip($item[spring shoes]) + if_equip($item[toy cupid bow]) + if_equip($item[designer sweatpants]) + baseball_equip());
                adv1(questLoc[ps]);
            }
            visit_url("guild.php?place=challenge");
        }
    }

    int mineNum() {
        int num, x_coor, y_coor;
        string itzmine = visit_url("mining.php?mine=3");
        matcher mining_spot = create_matcher(
            "Promising Chunk of Wall \\((\\d+),(\\d+)\\)", itzmine);

        // Try preferred spots first
        foreach str in $strings[(3\,6),(3\,5),(3\,4),(3\,3),(3\,2),(2\,2),(4\,2),(5\,2)] {
            if (!contains_text(itzmine, "Open Cavern " + str)) {
                matcher open_spot = create_matcher("(\\d),(\\d)", str);
                if (open_spot.find()) {
                    x_coor = to_int(open_spot.group(1));
                    y_coor = to_int(open_spot.group(2));
                    num = (8 * y_coor) + x_coor;
                    break;
                }
            }
        }

        // Fall back to promising chunks not near bad ore
        if (num == 0) {
            while (mining_spot.find()) {
                x_coor = to_int(mining_spot.group(1));
                y_coor = to_int(mining_spot.group(2));
                if (y_coor >= 4
                    || contains_text(adjacentCaverns(x_coor, y_coor), "velcroore")
                    || contains_text(adjacentCaverns(x_coor, y_coor), "vinylore"))
                    continue;
                num = (8 * y_coor) + x_coor;
                break;
            }
        }

        // Last resort: any promising chunk not too deep
        if (num == 0) {
            while (mining_spot.find()) {
                x_coor = to_int(mining_spot.group(1));
                y_coor = to_int(mining_spot.group(2));
                print(x_coor + ", " + y_coor);
                if (y_coor >= 4) continue;
                num = (8 * y_coor) + x_coor;
                break;
            }
        }
        if (num == 0)
            abort("Generic mining did not find teflon ore, mine manually. TIP: the ores show up in adjacent veins of 5.");
        return num;
    }

    void teflon() {
        equip($item[mer-kin digpick]);
        equipSwimTrunks();
        use_familiar("itdrop");
        visit_url("mining.php?mine=3&which=" + mineNum());
        if (my_hp() == 0)
            cli_execute("restore HP");
        // liftBeatenUp() rather than the old inline pair: that version made
        // the rest fallback unreachable whenever the Walrus was known, so a
        // walrus-owning character at 0 MP left here still Beaten Up.
        liftBeatenUp();
        post_adv();
    }

    void gymnasium(){
        use_familiar("combat");
        string conditional;
            // Only bank a noncombat here while the park still has a use for
            // one. skateParkStatus is the reliable test: the queue stops
            // listing Holey Rollers once the zone flips to Ice Skate
            // Territory, so gating on the queue alone re-arms the ski for a
            // park that is already resolved -- and the next pass through the
            // gladiator grind then aborts on the forcer this call banked.
            if (get_property("skateParkStatus") == "war"
                && !contains_text($location[The Skate Park].noncombat_queue, "Holey Rollers")){
                if (have_item($item[mchugelarge left ski]) && to_int(get_property("_mcHugeLargeAvalancheUses")) < 3)
                    conditional += "mchugelarge left ski,";
                else if (have_item($item[jurassic parka])  && to_int(get_property("_spikolodonSpikeUses")) < 5){
                    conditional += "jurassic parka,";
                    modes = "parka spikolodon";
                }
            }
        conditional += baseball_equip();
        tempEquipment("combat", if_equip(divingHelmet()) + if_equip(tailpiece()) + freeRun() + freeKill() + bathysphere($item[none]) + conditional);
        mood("combat");
        if (get_property("noncombatForcerActive") == "true")
            abort("Sneak active while trying to adventure in gymnasium, get rid of it");
        adv($location[Mer-kin Gymnasium]);
    }

    boolean parkaForceAvailable(){
        if (have_item($item[jurassic parka]) && to_int(get_property("_spikolodonSpikeUses")) < 5)
            return true;
        return false;
    }

    boolean leftSkiAvailable(){
        if (have_item($item[mchugelarge left ski]) && to_int(get_property("_mcHugeLargeAvalancheUses")) < 3)
            return true;
        return false;
    }

    void skatePark() {
        NCforce();
        if (get_property("noncombatForcerActive") != "true" && (parkaForceAvailable() || leftSkiAvailable()))
            gymnasium();
        else if (!parkaForceAvailable() && !leftSkiAvailable() && have_item($item[allied radio backpack]))
            cli_execute("alliedradio sniper");
        // The blade now holds one of the reserved slots, so spending down TO
        // the line is the point -- ">" would leave the reservation blocking its
        // own pull. Skip once a blade is in hand: a blade that arrived without
        // a pull (drop, mall, closet) leaves the id absent from
        // _roninStoragePulls, so pullSequence would happily buy a second one.
        if (available_amount($item[skate blade]) == 0
            && pulls_remaining( ) >= reservedPulls())
            pullSequence($item[skate blade]);
        if (get_property("noncombatForcerActive") == "true"){
            equipSwimTrunks();
            cli_execute("unequip peridot");
            if (item_amount($item[skate blade]) > 0)
                equip($item[skate blade]);
        } else {
            use_familiar("-combat");
            if (available_amount($item[skate blade]) > 0){
                equip($slot[weapon],$item[skate blade]);
            }
            tempEquipment("-combat, -weapon","really nice swimming trunks," + bathysphere($item[toy cupid bow]));
            mood("-combat");
        }
        adv($location[The Skate Park]);
    }

    void recallCaliginous(){
        if (available_amount($item[black glass]) == 0) 
            buy($coinmaster[Big Brother], 1, $item[black glass]);
        use_familiar("-combat");
        tempEquipment("item drop", if_equip(divingHelmet()) + "shark jumper," + underwaterPants() + "black glass,peridot of peril,monodent of the sea,"
            + bathysphere($item[none]) + freeKill());
        if (have_effect($effect[jelly combed]) == 0 && pullSequence($item[comb jelly])) 
            use($item[comb jelly]);
        adv($location[The Caliginous Abyss]);
    }

    boolean libraryReady(){
        if ((have_item($item[mer-kin scholar mask]) || have_item($item[mer-kin facecowl])) 
            && (have_item($item[mer-kin scholar tailpiece]) || have_item($item[mer-kin waistrope])) 
            && ((item_amount($item[mer-kin wordquiz]) * 10) + to_int(get_property("merkinVocabularyMastery"))) >= 90)
            return true;
        return false;
    }

    void finishCaliginous(){
        use_familiar("itdrop");
        string conditional;
        if (!contains_text(get_property("banishedMonsters"), "school of many"))
            conditional += "monodent of the sea,";
        tempEquipment("mys","shark jumper," + underwaterPants() + "black glass," + if_equip($item[Congressional Medal of Insanity])
            + if_equip(divingHelmet()) + bathysphere($item[none]) + if_equip($item[blood cubic zirconia]) + conditional);
        adv($location[The Caliginous Abyss]);
    }

    void getSandDollar(){
        if (item_amount($item[mer-kin thingpouch]) > 0) {
            use(item_amount($item[mer-kin thingpouch]), $item[mer-kin thingpouch]);
        } else if (item_amount($item[sand penny]) >= 100){
            buy($coinmaster[Wet Crap For Sale], 1, $item[water-logged pill]);
        } else if (storage_amount($item[damp old wallet]) > 0 && pullSequence($item[damp old wallet])) {
            use($item[damp old wallet]);
        } else {
            getLucky();
            adv($location[The Mer-Kin Outpost]);
        }
    }

    void oldGuy(){
        while (item_amount($item[sand dollar]) < 50) {
            getSandDollar();
        }
        blackGlass();
        if (available_amount($item[damp old boot]) == 0 && get_property("questS01OldGuy") == "started") 
            buy($coinmaster[Big Brother], 1, $item[damp old boot]);
        visit_url("place.php?whichplace=sea_oldman&action=oldman_oldman"
            + "&preaction=pickreward&whichreward=6313");
    }

    void merkinLib(){
        use_familiar("itdrop");

        string conditional;
        if (lowShiny() == true)
            conditional += if_equip($item[Congressional Medal of Insanity]);
        if (to_int(get_property("_backUpUses")) < 11 && have_item($item[backup camera]) && !highShiny())
            conditional += "backup camera,";
        // One Force charge on the researcher lands both scrolls (10% slots,
        // the slowest in the zone) and frees their reserved pulls. saberEquip()
        // below already pins the saber -- but both are weapons, so what
        // actually lets it into the slot is keeping the monodent OUT while a
        // truly spare charge exists. worktea and knucklebone come from the
        // other two monsters, so the monodent keeps the slot for those.
        boolean saberForResearcher = (item_amount($item[mer-kin killscroll]) == 0
                || item_amount($item[mer-kin healscroll]) == 0)
            && saberForcesFree() > 0
            && have_item($item[Fourth of May Cosplay Saber]);
        if (!saberForResearcher
            && (item_amount($item[mer-kin killscroll]) == 0 || item_amount($item[mer-kin healscroll]) == 0 || item_amount($item[mer-kin worktea]) == 0 || item_amount($item[mer-kin knucklebone]) == 0))
            conditional += "monodent of the sea,";
        conditional += saberEquip($location[mer-kin library]);
        conditional += cloakeEquip($location[mer-kin library]);
        if (item_amount($item[mer-kin dreadscroll]) == 0) {
            tempEquipment("item drop", "mer-kin scholar mask,mer-kin scholar tailpiece,"
                + if_equip($item[blood cubic zirconia]) + conditional);
        } else {
            mood("-combat");
            tempEquipment("-combat", "mer-kin scholar mask,mer-kin scholar tailpiece," + conditional);
        }

        mood("itdrop");
        useMapIfAvailable();
        adv($location[mer-kin library]);
    }

    boolean doneWithCowboy(){
        boolean bool = true;
        if (to_int(get_property("lassoTrainingCount")) + (3*item_amount($item[sea lasso])) < 21)
            bool = false;
        return bool;
    }

    boolean doneWithSeaCow(){
        boolean bool = true;
        if (item_amount($item[sea leather]) + available_amount($item[sea chaps]) + available_amount($item[sea cowboy hat]) < 2)
            bool = false;
        if (item_amount($item[sea cowbell]) < 3)
            bool = false;
        return bool;
    }

    void getMissingCorralItems(){
        string conditional;
        use_familiar("itdrop");
        // Backup Fidoxene site for reruns that skip the outpost phase; the
        // free-pill guard inside makes repeat calls a no-op.
        if (NCForceEstimate() >= 4)
            pillKeeper("free familiar");
        // Lecture copies of the sea cow once the Force budget is spent;
        // internally gated, a no-op the rest of the time.
        professorFamiliar();
        if (!contains_text(get_property("banishedMonsters"),"Mer-kin rustler")
            || (doneWithCowboy() && !contains_text(get_property("banishedMonsters"),"sea cowboy"))
            || (doneWithSeaCow() && !contains_text(get_property("banishedMonsters"),"sea cow:")))
            conditional += if_equip(banishGear($location[The Coral Corral]));
        if (lowShiny())
            conditional += if_equip($item[Congressional Medal of Insanity]);
        conditional += saberEquip($location[The Coral Corral]);
        conditional += cloakeEquip($location[The Coral Corral]);
        conditional += champagneEquip($location[The Coral Corral]);
        tempEquipment("item drop", "really nice swimming trunks," + if_equip($item[legendary seal-clubbing club]) + bathysphere($item[toy cupid bow]) + conditional);
        if (!doneWithSeaCow())
            set_property("choiceAdventure1589","1&victim=775");
        else if (!doneWithCowboy())
            set_property("choiceAdventure1589","1&victim=776");
        // Whichever victim we are hunting, its whole table is non-conditional,
        // so once the Force budget is out the ray forces the same result. The
        // CCS kill path fires it via Spit jurassic acid.
        if (forcesAfterHealer() <= 0)
            yellowRayPrep();

        // Unconditional: the itdrop buffs must go up on every pass, victim
        // set or not.
        mood("itdrop");
        // sea cow is 1 of 3 here and this loop runs until lasso, cowbell x3 and
        // leather x2 are all in hand, so it is the third-best use of a charge.
        mapMonster($location[The Coral Corral]);
        adv($location[The Coral Corral]);
        timeSpinnerRefight($location[The Coral Corral]);
        if (contains_text(get_property("baseballTeam"),"775") && baseballPlayers() == 9 && item_amount($item[sea cowbell]) <3)
            baseballD();
    }

    void monkeypaw(item it){
        if (available_amount($item[cursed monkey's paw]) == 0 || to_int(get_property("_monkeyPawWishesUsed")) == 5){
            while (available_amount(it) == 0){
                getMissingCorralItems();
            if (get_property("dolphinItem") == to_string(it) && have_item($item[durable dolphin whistle]))
                use($item[durable dolphin whistle]);
            }
        } else
            cli_execute("monkeypaw item " + it);
    }

    void shadowRift() {
        if (!have_item($item[closed-circuit pay phone]))
            return;
        if (have_effect($effect[shadow waters]) == 0) {
            if (get_property("questRufus") == "unstarted")
                use($item[closed-circuit pay phone]);
            if (get_property("questRufus") == "started") {
                NCforce();
                adv1($location[Shadow Rift (The Misspelled Cemetary)]);
            }
            if (get_property("_seadentWaveUsed") == "false")
                use_skill($skill[Sea *dent: Summon a Wave]);
            use($item[closed-circuit pay phone]);
            adv1($location[Shadow Rift (The Misspelled Cemetary)]);
        } else {
            if (to_int(get_property("encountersUntilSRChoice")) > 9
                && get_property("questRufus") == "unstarted"
                && item_amount($item[Closed-circuit pay phone]) > 0) {
                tempEquipment("item drop","Flash Liquidizer Ultra Dousing Accessory,monodent of the sea,"
                + if_equip($item[bat wings]) + baseball_equip() + if_equip($item[Everfull Dart Holster]));
                use($item[closed-circuit pay phone]);
            }
            if (get_property("questRufus") == "unstarted")
                use($item[closed-circuit pay phone]);
            if (have_effect($effect[shadow affinity]) > 0) {
                if (item_amount($item[sea lasso]) == 0) {
                    equip($item[really, really nice swimming trunks]);
                    equip($item[little bitty bathysphere]);
                    monkeypaw($item[sea lasso]);
                }
                if (!use_familiar($familiar[jill-of-all-trades]))
                    use_familiar("itdrop");
                
                if (to_int(get_property("lassoTrainingCount")) < 20) {
                    tempEquipment("item drop","Flash Liquidizer Ultra Dousing Accessory,monodent of the sea,sea cowboy hat,sea chaps,"
                    + if_equip($item[bat wings]) + if_equip($item[Everfull Dart Holster]) + if_equip($item[toy cupid bow]) + baseball_equip());
                } else {
                    tempEquipment("item drop","Flash Liquidizer Ultra Dousing Accessory,monodent of the sea,"
                    + if_equip($item[bat wings]) + if_equip($item[Everfull Dart Holster]) + if_equip($item[toy cupid bow]) + baseball_equip());
                }
                mood("itdrop");
                adv1($location[Shadow Rift (The Misspelled Cemetary)]);
                if (get_property("_seadentWaveUsed") == "false"
                    && have_effect($effect[shadow affinity]) > 0) {
                    adv1($location[Shadow Rift (The Misspelled Cemetary)]);
                    use_skill($skill[Sea *dent: Summon a Wave]);
                }
                if (get_property("encountersUntilSRChoice") == "0")
                    adv1($location[Shadow Rift (The Misspelled Cemetary)]);
            }
        }
    }

// Other Utilities Part 2
    void curveballBurn(){
        if (!contains_text(get_property("_perilLocations"), "196") && available_amount($item[mer-kin digpick]) == 0){
            mood("spookyres");
            use_familiar("itdrop");
            cli_execute("unequip peridot of peril");
            codpiece("blood cubic zirconia, peridot of peril");
            tempEquipment("spooky res", swimmingTrunks() + if_equip($item[The Eternity Codpiece]) + "monodent of the sea" + bathysphere($item[none]));
            adv1($location[Anemone Mine]);
        } else if (!contains_text(get_property("_perilLocations"), "195")){
            mood("hotres");
            use_familiar("itdrop");
            cli_execute("unequip peridot of peril");
            codpiece("blood cubic zirconia, peridot of peril");
            tempEquipment("hot res", swimmingTrunks() + if_equip($item[The Eternity Codpiece]) + "monodent of the sea" + bathysphere($item[none]));
            adv1($location[the marinara trench]);
        } else if (!contains_text(get_property("_perilLocations"), "197")){
            mood("sleazeres");
            use_familiar("itdrop");
            codpiece("blood cubic zirconia, peridot of peril");
            tempEquipment("sleaze res", swimmingTrunks() + if_equip($item[The Eternity Codpiece]) + "monodent of the sea" + bathysphere($item[none]));
            adv1($location[the dive bar]); 
        } else if (!contains_text(get_property("_perilLocations"), "196")){
            mood("spookyres");
            use_familiar("itdrop");
            cli_execute("unequip peridot of peril");
            codpiece("blood cubic zirconia, peridot of peril");
            tempEquipment("spooky res", swimmingTrunks() + if_equip($item[The Eternity Codpiece]) + "monodent of the sea" + bathysphere($item[none]));
            adv1($location[Anemone Mine]);
        } else {
            tempEquipment("item drop","monodent of the sea");
            adv1($location[The Outskirts of Cobb's Knob]);
        }
        codpiece("none");
    }

    void summon(monster mon){
        if (haveLocketMonster[mon] && !contains_text(get_property("_locketMonstersFought"),to_int(mon)) && count_substring(get_property("_locketMonstersFought"),",") < 2) {
            cli_execute("reminisce " + mon);
        } else {
            if (have_item($item[Combat lover's locket]))
                equip($slot[acc3], $item[Combat lover's locket]);
            if (get_property("_photocopyUsed") == "false" && (faxbot(mon) || faxbot(mon) || faxbot(mon))){
                use($item[photocopied monster]);
                run_combat();
            } else if ($familiar[chest mimic].experience > 200) {
                if (!contains_text(get_property("mimicEggMonsters"),to_int(mon)))
                    cli_execute("c2t_megg extract " + mon);
                if (item_amount($item[mimic egg]) == 0)
                    abort("mimice egg failed to extract. Rerun and if this happens again ping FS");
                cli_execute("c2t_megg fight " + mon);
                run_combat();
                // A Force cast during the egg fight can strand the session
                // in choice 1387 if nothing auto-resolved it.
                if (handling_choice() && last_choice() == 1387)
                    run_choice(3);
            } else if (have_skill($skill[just the facts])){
                if (item_amount($item[pocket wish]) == 0){
                    if (my_class() == $class[accordion thief]){
                        tempEquipment("item drop", if_equip($item[peridot of peril]));
                        adv($location[The Overgrown Lot]);
                    }
                }
                if (item_amount($item[pocket wish]) > 0) {
                    tempEquipment("item drop",if_equip($item[legendary seal-clubbing club]) + if_equip($item[McHugeLarge left pole]));
                    cli_execute("genie monster " + mon);
                    run_combat();
                } else
                    abort("This is an old line that should not happen any more. If you hit this you've hit a bug, let FS know");
            } else {
                abort("This is an old line that should not happen any more. If you hit this you've hit a bug, let FS know");
            }
        }
    }

    // NCForceEstimate() now lives in iotm.ash so initialization() can consult it
    // when deciding whether to reserve the free pill for Sneakisol.

    boolean MomNCyber(){
        if (have_familiar($familiar[patriotic eagle]) && have_item($item[server room key]) && have_skill($skill[Overclock(10)]) && have_skill($skill[Just the Facts]))
            return true;
        return false;
    }

    boolean lassoShadow(){
        if (have_item($item[monodent of the sea]) && have_item($item[Closed-circuit pay phone]))
            return true;
        return false;
    }

    void backupLasso() {
        if (!contains_text(get_property("_roninStoragePulls"), "11453"))
            cli_execute("pull elf guard scuba");
        if (item_amount($item[sea lasso]) == 0){
            equip($item[really, really nice swimming trunks]);
            equip($item[little bitty bathysphere]);
            monkeypaw($item[sea lasso]);
        }

        string [stat] resType = {
            $stat[mysticality]: "hot res, item drop",
            $stat[moxie]:       "sleaze res, item drop",
            $stat[muscle]:      "spooky res"
        };
        location [stat] lassoLoc = {
            $stat[mysticality]: $location[The Marinara Trench],
            $stat[moxie]:       $location[The Dive Bar],
            $stat[muscle]:      $location[Anemone Mine]
        };
        stat ps = my_primestat();
        use_familiar("itdrop");
        if (available_amount($item[pristine fish scale]) < 6)
            mood("itdrop");
        tempEquipment(resType[ps],"elf guard scuba tank,monodent of the sea,sea cowboy hat,sea chaps" + bathysphere($item[none]));
        adv(lassoLoc[ps]);
    }

    // The day's one prayerbead pull is free where a farming trip costs a turn,
    // so take it before any loop starts spending adventures. Kept separate from
    // farmPrayerbeads(): combatScrollHint() calls that purely to burn a turn,
    // and a version that could no-op would spin it forever.
    void pullPrayerbead(){
        if (available_amount($item[mer-kin prayerbeads]) < 3)
            pullSequence($item[mer-kin prayerbeads]);
    }

    void farmPrayerbeads(){
        use_familiar("-combat");
        string conditional;
        if (lowShiny() == true)
            conditional += if_equip($item[Congressional Medal of Insanity]);
        // The weapon slot is free on these trips, so the saber rides along:
        // any healer that slips through the -combat stack gets Forced for a
        // guaranteed prayerbead + thingpouch, with the turn refunded.
        conditional += healerSaber();
        // swimmingTrunks() picks what the path actually allows; the path-55
        // trunks are quest-gated and abort a path-0 run outright.
        tempEquipment("-combat", swimmingTrunks() + bathysphere($item[toy cupid bow]) + conditional);
        
        mood("-combat");
        adv($location[the mer-kin outpost]);
    }

    void getCheatsheet(){
        put_closet(item_amount($item[mer-kin hallpass]),
            $item[mer-kin hallpass]);
        use_familiar("itdrop");
        string conditional;
        string conditionalMax;
        if (to_int(get_property("_backUpUses")) < 11 && have_item($item[backup camera]))
            conditional += "backup camera,";
        else if (have_skill($skill[Double-Fisted Skull Smashing]))
            conditional += "monodent of the sea,";
        if (item_amount($item[mer-kin bunwig]) == 0
            && !have_equipped($item[mer-kin bunwig]))
            conditionalMax += ", hat drop";
        conditional += saberEquip($location[mer-kin elementary school]);
        conditional += cloakeEquip($location[mer-kin elementary school]);
        tempEquipment("item drop" + conditionalMax, if_equip(divingHelmet()) + if_equip(tailpiece()) + if_equip($item[blood cubic zirconia]) + if_equip($item[legendary seal-clubbing club])
            + if_equip($item[M&ouml;bius ring]) + bathysphere($item[toy cupid bow]) + conditional);
        set_property("choiceAdventure1589","1&victim=852");
        if (get_property("merkinElementaryTeacherUnlock") == "false")
            mood("-combat");
        mood("itdrop");
        useMapIfAvailable();
        // Leftover Map charges force a monitor here (zoneTarget picks it while
        // the sheet grind is live); the refight buys a guaranteed monitor for
        // one turn straight after fighting one.
        mapMonster($location[mer-kin elementary school]);
        adv($location[mer-kin elementary school]);
        timeSpinnerRefight($location[mer-kin elementary school]);
        put_closet(item_amount($item[mer-kin hallpass]),
            $item[mer-kin hallpass]);
    }

    void combatScrollHint(){
        if (get_property("dreadScroll5") == "0"){
            while (item_amount($item[mer-kin killscroll]) == 0){
                if (item_amount($item[mer-kin thingpouch]) > 0)
                    use(item_amount($item[mer-kin thingpouch]), $item[mer-kin thingpouch]);
                else if (lowShiny() == false && pulls_remaining() > reservedPulls())
                    pullSequence($item[mer-kin killscroll]);
                else
                    farmPrayerbeads();
            }
        }
        if (get_property("dreadScroll2") == "0"){
            while (item_amount($item[mer-kin healscroll]) == 0){
                if (lowShiny() == false && pulls_remaining() > reservedPulls())
                    pullSequence($item[mer-kin healscroll]);
                else
                    farmPrayerbeads();
            }
        }
        if (get_property("dreadScroll5") == "0" || get_property("dreadScroll2") == "0"){
            gymnasium();
        }
    }

// ─── SEA MONKEES ──────────────────────────────────────────────────────────────

void seaMonkees() {
    //Use Sword of S Words to get sea lasso
    if (have_familiar($familiar[Sword of S Words]) && count_summons() >= 3 && to_float(get_property("swordOfSWordsMonster")) < 10 && (highShiny() || !have_item($item[closed-circuit pay phone]))){
        use_familiar($familiar[Sword of S Words]);
        tempEquipment("item drop", baseball_equip() + freeKill());
        mood("itdrop");
        cli_execute("recover hp");
        summon($monster[sea cowboy]);
    } 

    // ── Guild unlock prerequisite ─────────────────────────────────────────────
    step("phase: guild unlock");
    if (get_property("questG03Ego") == "unstarted" && item_amount($item[Closed-circuit pay phone]) > 0 && my_path().id == 55 && !highShiny()) {
        unlockGuild();
        if (get_property("questG03Ego") == "unstarted") {
            visit_url("guild.php?place=ocg");
            visit_url("guild.php?place=ocg");
        }
    }
    post_adv();
    // ── Step: Flytrap pellet ──────────────────────────────────────────────────
    step("phase: flytrap pellet (Sea Monkees start)");
    if (get_property("questS02Monkees") == "unstarted") {
        // Get citizen/RWB ray on neptune flytrap
        while (item_amount($item[wriggling flytrap pellet]) == 0 && have_effect($effect[Citizen of a Zone]) == 0
            && have_effect($effect[Everything Looks Red, White and Blue]) == 0 && have_familiar($familiar[patriotic eagle])) {
            use_familiar($familiar[patriotic eagle]);
            string conditional;
            if (lowShiny())
                conditional += if_equip($item[Congressional Medal of Insanity]);
            tempEquipment("item drop", swimmingTrunks() + "peridot of peril,"
                + bathysphere($item[none]) + baseball_equip() + freeKill() + conditional);
            adv($location[An octopus's garden]);
        }
        // Collect pellet while RWB is active
        while (item_amount($item[wriggling flytrap pellet]) == 0
            && to_int(get_property("rwbMonsterCount")) > 0) {
            if (!highShiny() && have_familiar($familiar[sword of s words]) && have_item($item[Archaeologist's Spade]) && to_int(get_property("_archSpadeDigs")) < 11){
                use_familiar($familiar[sword of s words]);
                if (get_property("swordOfSWordsMonster") != "740"){
                    tempEquipment("item drop", swimmingTrunks() + baseball_equip() + bathysphere($item[toy cupid bow]) + freeKill());
                    adv($location[An octopus's garden]);
                } else if (my_location() != $location[the skeleton store]){
                    if (get_property("skeletonStoreAvailable") == false)
                        visit_url("shop.php?whichshop=meatsmith&action=talk");
                    adv($location[The skeleton store]);
                } else {
                    maximize("item drop",false);
                    use($item[Archaeologist's Spade]);
                }
            } else {
                use_familiar("itdrop");
                if (to_int(get_property("rwbMonsterCount")) == 1) {
                    tempEquipment("item drop", swimmingTrunks() + if_equip($item[McHugeLarge left pole])
                        + bathysphere($item[toy cupid bow]) + freeKill());
                } else {
                    tempEquipment("item drop", swimmingTrunks() + baseball_equip() + bathysphere($item[toy cupid bow]) + freeKill());
                }
                adv($location[An octopus's garden]);
            }
        }
        // Banish fallback if pellet still didn't drop
        if (item_amount($item[wriggling flytrap pellet]) == 0) {
            print("Pellet failed to drop 3x, initiating banishes", "red");
            while (item_amount($item[wriggling flytrap pellet]) == 0) {
                use_familiar("itdrop");
                string conditional;
                if (highShiny())
                    conditional += "monodent of the sea,";
                conditional += cloakeEquip($location[An octopus's garden]);
                if (to_int(get_property("_assertYourAuthorityCast")) < 3) {
                    tempEquipment("item drop", swimmingTrunks()
                        + "Sheriff moustache,Sheriff badge,Sheriff pistol," + bathysphere($item[toy cupid bow]) + conditional);
                } else {
                    tempEquipment("item drop", swimmingTrunks() + if_equip(banishGear($location[An octopus's garden]))
                        + bathysphere($item[toy cupid bow]) + conditional + freeKill() );
                }
                // Reached only after the pellet has already failed to drop three
                // times, so the Peridot charge here is long gone and the flytrap
                // is 1 of 4. Worth a map charge to stop the bleeding.
                mapMonster($location[An octopus's garden]);
                adv($location[An octopus's garden]);
                timeSpinnerRefight($location[An octopus's garden]);
            }
        }
        if (item_amount($item[wriggling flytrap pellet]) > 0)
            use($item[wriggling flytrap pellet]);}

    if (get_property("questS02Monkees") == "started")
        visit_url("monkeycastle.php?who=1");

    // ── Step 1: Edgar Fitzsimmons wreck ──────────────────────────────────────
    step("phase: Wreck of the Edgar Fitzsimmons (step 1)");
    while (get_property("questS02Monkees") == "step1") {
        if (NCForceEstimate() >= 4){
            if (get_property("noncombatForcerActive") != "true")
                NCforce();
            tempEquipment("item drop, -equip peridot of peril", swimmingTrunks() + bathysphere($item[none]) + if_equip($item[M&ouml;bius ring]));
        } else {
            use_familiar("-combat");
            tempEquipment("-combat, -equip peridot of peril", "monodent of the sea," + swimmingTrunks() + if_equip($item[M&ouml;bius ring]) + bathysphere($item[toy cupid bow]));
            mood("-combat");
        }
        adv($location[The Wreck of the Edgar Fitzsimmons]);
    }

    if (get_property("questS02Monkees") == "step2") {
        visit_url("monkeycastle.php?who=2");
        visit_url("monkeycastle.php?who=1");
    }

    // ── Step 4: Unlocking Grandpa ──────────────────────────────────
    step("phase: Grandpa unlock (step 4)");
    if (get_property("questS02Monkees") == "step4") {
        use_familiar("-combat");
        if (have_effect($effect[Colorfully Concealed]) == 0 && lowShiny() == false) {
            // The Outpost burglar drops this anyway, so yield the slot if a
            // reserved item still needs it.
            if (pulls_remaining() > reservedPulls())
                pullSequence($item[mer-kin hidepaint]);
            if (item_amount($item[mer-kin hidepaint]) > 0)
                use($item[mer-kin hidepaint]);
        }
        while (get_property("questS02Monkees") == "step4") {
            string conditional;

            if (doSWord() == true){
                use_familiar($familiar[Sword of S Words]);
                mood("itdrop");
            } else {
                use_familiar("itdrop");
            }
            if (baseballPlayers() < 9 && available_amount($item[baseball diamond]) > 0) {
                conditional += baseball_equip();
            } else if ((my_primestat() == $stat[mysticality] && !contains_text(get_property("trackedMonsters"), "giant squid"))
                    || (my_primestat() == $stat[moxie] && !contains_text(get_property("trackedMonsters"), "Mer-kin tippler"))) {
                // if_equip() is the ownership check for the pole; both class
                // arms need it.
                conditional += if_equip($item[McHugeLarge left pole]);
            }
            if (baseballPlayers() >= 9 && to_int(get_property("_baseballInnings")) <= 2)
                baseballD();
            if (to_int(get_property("_bczSweatBulletsCasts")) < 9)
                conditional += if_equip($item[blood cubic zirconia]);
            mood(pearlRes[my_primestat()]);
            tempEquipment("item drop, -100 combat","monodent of the sea," + swimmingTrunks() + freeRun()
                + if_equip($item[M&ouml;bius ring]) + bathysphere($item[toy cupid bow]) + conditional);
            mood("-combat");
            adv(pearlLoc[my_primestat()]);
        }
    }

    if (get_property("questS02Monkees") == "step5")
        cli_execute("grandpa grandma");

    // ── Step 6: Black Crayon Golem recall ────────────────────────────────────
    step("phase: golem recall (step 6)");
    if (get_property("questS02Monkees") == "step6" && get_property("_monsterHabitatsMonster") == "" && my_path().id == 55 && !highShiny() && have_skill($skill[just the facts])) {
        if (have_familiar($familiar[red-nosed snapper]))
            use_familiar("itdrop");
        else
            use_familiar("-combat");
        if (my_familiar() == $familiar[red-nosed snapper])
            cli_execute("snapper construct");
        tempEquipment("item drop",if_equip($item[legendary seal-clubbing club]) + if_equip($item[McHugeLarge left pole]) + bathysphere($item[toy cupid bow]));
        summon($monster[black crayon golem]);
    }

    // ── Mer-kin Outpost stashbox hunt ─────────────────────────────────────────
    step("phase: Mer-kin Outpost (stashbox / lockkey)");
    // Fidoxene only when the forcer inventory means Sneakisol will not be
    // needed; otherwise the free pill stays banked for NCforce(), since a
    // forcer fires on the FIRST noncombat after it is taken.
    if (NCForceEstimate() >= 4)
        pillKeeper("free familiar");
    while ((item_amount($item[Mer-kin stashbox]) == 0  && get_property("corralUnlocked") == "false") || contains_text("step6,step7,step8",get_property("questS02Monkees"))) {
        if ($location[The Mer-Kin Outpost].turns_spent < 5)
            set_property("stashboxChecked", "0");
        // stashboxChecked accumulates in whatever order the lock monsters
        // appeared (e.g. "3,1,2"), so test membership, not the exact string.
        if (contains_text(get_property("stashboxChecked"), "1")
            && contains_text(get_property("stashboxChecked"), "2")
            && contains_text(get_property("stashboxChecked"), "3"))
            abort("All stashbox locations checked but no stashbox — something went wrong");

        // Familiar choice
        if (get_property("_monsterHabitatsFightsLeft") == "1" && to_int(get_property("_monsterHabitatsRecalled")) == 2 && have_familiar($familiar[patriotic eagle]))
            use_familiar($familiar[patriotic eagle]);
        else if (doSWord() == true && $location[The Mer-Kin Outpost].turns_spent < 26 && (get_property("_monsterHabitatsFightsLeft") == "0" || available_amount($item[crayon shavings]) > 9)){
            use_familiar($familiar[Sword of S Words]);
            mood("itdrop");
        } else if (((highShiny() || !have_item($item[closed-circuit pay phone]) || lowShiny()) && item_amount($item[pristine fish scale]) < 6) || have_familiar($familiar[red-nosed snapper]))
            use_familiar("itdrop");
        else
            use_familiar("-combat");

        // Conditional gear
            string conditional;
            if (get_property("_monsterHabitatsFightsLeft") == "1" && have_effect($effect[Everything Looks Purple]) == 0
                && to_int(get_property("_monsterHabitatsRecalled")) == 2 && have_item($item[roman candelabra]))
                conditional += "roman candelabra,";
            else if (my_path().id == 0 && to_int(get_property("lassoTrainingCount")) < 20)
                conditional += "sea cowboy hat,sea chaps,";
            else 
                conditional += baseball_equip();

            if (get_property("lastCopyableMonster") == "Black Crayon Golem" && to_int(get_property("_backUpUses")) < 7 && have_item($item[backup camera])
                && ($location[The Mer-Kin Outpost].turns_spent < 26 || get_property("merkinLockkeyMonster") != ""))
                conditional += "backup camera,";
            else if (to_int(get_property("_bczSweatBulletsCasts")) < 9)
                conditional += if_equip($item[blood cubic zirconia]);
            else
                conditional += if_equip($item[Congressional Medal of Insanity]);

            if ((get_property("_monsterHabitatsMonster") == "eye in the darkness" || get_property("_monsterHabitatsMonster") == "slithering thing") && get_property("_monsterHabitatsFightsLeft") > 0)
                conditional += "shark jumper," + underwaterPants() + "elf guard scuba,";
            else 
                conditional += swimmingTrunks();
        if ((highShiny() || !have_item($item[closed-circuit pay phone]) || lowShiny()) && item_amount($item[pristine fish scale]) < 6)
            mood("itdrop");
        if (get_property("merkinLockkeyMonster") != "") {
            mood("-combat");
            tempEquipment("-combat", "monodent of the sea," + bathysphere($item[none]) + freeRun() + conditional);
        } else {
            tempEquipment("item drop", "monodent of the sea," + bathysphere($item[toy cupid bow]) + conditional + freeKill());
        }
        adv($location[The Mer-Kin Outpost]);

        if (item_amount($item[Grandma's Note]) > 0
            && item_amount($item[Grandma's Fuchsia Yarn]) > 0
            && item_amount($item[Grandma's Chartreuse Yarn]) > 0){
            use_familiar("itdrop");
            equip($item[really, really nice swimming trunks]);
            cli_execute("grandpa note");
        }
        if (my_path().id == 55){
            if (!have_skill($skill[Steely-Eyed Squint]) && NCForceEstimate() < 4 && contains_text(get_property("baseballTeam"),"773") && baseballPlayers() == 9)
                baseballD();
            while (!MomNCyber() && lassoShadow() && to_int(get_property("_monsterHabitatsRecalled")) == 2 
                && get_property("_monsterHabitatsFightsLeft") == "0" && to_int(get_property("momSeaMonkeeProgress")) < 40
                && contains_text("step9,step10,step11,step12",get_property("questS02Monkees"))){
                if (available_amount($item[black glass]) == 0)
                    oldGuy();
                if (available_amount($item[Elf Guard SCUBA tank]) == 0)
                    pullSequence($item[Elf Guard SCUBA tank]);
                recallCaliginous();
            }
        }
    }
    refresh_status();

    // ── Stashbox use and trail unlock ─────────────────────────────────────────
    if (item_amount($item[Mer-kin stashbox]) == 1) {
        use($item[Mer-kin stashbox]);
        use($item[Mer-kin trailmap]);
        equipSwimTrunks();
        cli_execute("grandpa currents");
    }

    // Get 2 prayerbeads if tight on pulls. farmPrayerbeads() is the same trip
    // plus healerSaber(), so a healer that slips through the -combat stack is
    // Forced into a guaranteed bead instead of fought for a 4.8% roll.
    pullPrayerbead();
    while (NCForceEstimate() < 4 && available_amount($item[mer-kin prayerbeads]) < 2)
        farmPrayerbeads();

    if (get_property("questS01OldGuy") == "started") {
        oldGuy();
    }
    // ── Diving helmet acquisition for mid to high shiny ───────────────────────────────
    step("phase: diving helmet (rivet hunt)");
    if (item_amount($item[rusty rivet]) < 8 && to_slot(divingHelmet()) != $slot[hat]) {
        if (have_item($item[Cursed monkey's paw]) && count_summons() >= 1 && !highShiny()){
            mood("itdrop");
            if (have_effect($effect[shadow waters]) == 0)
                shadowRift();
            // Diver #1. Under the Force plan the fight's drops are forced, so
            // the familiar's job is the diver-#2 insurance egg, not +item, and
            // the mimic outranks the drop familiars.
            if (item_amount($item[rusty porthole]) == 0) {
                if (diverForceReady()){
                    if (!use_familiar($familiar[chest mimic]))
                        use_familiar("itdrop");
                } else if (baseballPlayers() >= 8){
                    if (!use_familiar($familiar[jill-of-all-trades]))
                        use_familiar("itdrop");
                } else {
                    if (!use_familiar($familiar[chest mimic]))
                        use_familiar("itdrop");
                }
                tempEquipment("item drop", diverSaber() + if_equip($item[blood cubic zirconia]) + if_equip($item[toy cupid bow]) + if_equip($item[baseball diamond]));
                print("Item drop rate is " + numeric_modifier("item drop"));
                // Forced and yellow-rayed drops ignore item bonuses, so the
                // once-a-day squint only fires when neither covers this
                // fight: saberless and rayless, the roll is probabilistic
                // and doubling the bonus pays most on this table.
                if (!diverForceReady()) {
                    yellowRayPrep();
                    if (have_effect($effect[everything looks yellow]) > 0
                        || (!have_item($item[jurassic parka])
                            && !have_item($item[April Shower Thoughts shield])))
                        mood("superitdrop");
                }
                summon($monster[unholy diver]);
            }

            if (baseballPlayers() >= 9)
                baseballD();

            // Divers #2..n, cheapest source first: the insurance egg is a free
            // fight, a Time-Spinner refight costs one turn but is guaranteed,
            // another summon costs whatever it costs. The CCS Forces or
            // yellow-rays each of these while charges last, so with a saber
            // this loop runs at most once. The tries cap keeps a misreporting
            // resource from spinning the ladder.
            int diverTries;
            while ((item_amount($item[rusty rivet]) < 8
                    || item_amount($item[rusty porthole]) == 0
                    || available_amount($item[rusty broken diving helmet]) == 0)
                && diverTries < 4) {
                diverTries += 1;
                if (diverForceReady() || item_amount($item[rusty rivet]) < 4){
                    if (!use_familiar($familiar[chest mimic]))
                        use_familiar("itdrop");
                } else {
                    if (!use_familiar($familiar[jill-of-all-trades]))
                        use_familiar("itdrop");
                }
                tempEquipment("item drop", diverSaber() + if_equip($item[blood cubic zirconia]) + if_equip($item[toy cupid bow]));
                if (!diverForceReady()){
                    // Probabilistic roll: now the squint and the ray earn
                    // their keep.
                    mood("superitdrop");
                    yellowRayPrep();
                }
                if (item_amount($item[mimic egg]) > 0
                    && contains_text(get_property("mimicEggMonsters"), "745")){
                    cli_execute("c2t_megg fight unholy diver");
                    run_combat();
                    // A Force cast during the egg fight can strand the
                    // session in choice 1387 if nothing auto-resolved it.
                    if (handling_choice() && last_choice() == 1387)
                        run_choice(3);
                } else if (timeSpinnerFight($monster[unholy diver])) {
                } else if (count_summons() >= 1) {
                    summon($monster[unholy diver]);
                    run_combat();
                } else {
                    break;
                }
            }
            if (item_amount($item[rusty rivet]) < 8
                && pulls_remaining() > reservedPulls()
                && !contains_text(get_property("_roninStoragePulls"), "3604"))
                pullSequence($item[rusty rivet]);
        } else {
            use_familiar("itdrop");
            if (NCForceEstimate() >= 7){
                NCforce();
                tempEquipment("-combat", swimmingTrunks() + bathysphere($item[toy cupid bow]));
                adv($location[The Wreck of the Edgar Fitzsimmons]);
            }
            while (item_amount($item[rusty rivet]) < 8 || available_amount($item[rusty broken diving helmet]) == 0 || item_amount($item[rusty porthole]) == 0){
                string conditional;
                    if ((get_property("_monsterHabitatsMonster") == "eye in the darkness" || get_property("_monsterHabitatsMonster") == "slithering thing") && get_property("_monsterHabitatsFightsLeft") > 0){
                        conditional += "shark jumper," + underwaterPants() + "elf guard scuba tank,";
                    } else {
                        conditional += swimmingTrunks();
                    }
                conditional += saberEquip($location[The Wreck of the Edgar Fitzsimmons]);
                conditional += cloakeEquip($location[The Wreck of the Edgar Fitzsimmons]);
                conditional += champagneEquip($location[The Wreck of the Edgar Fitzsimmons]);
                conditional += gloveEquip($location[The Wreck of the Edgar Fitzsimmons]);
                // Chained divers cost no adventure, which beats the drop
                // familiar we give up. Reverts itself once the rivets are in.
                professorFamiliar();
                if (total_turns_played( ) < to_int(get_property("_lastFitzsimmonsHatch")) + 20){
                    if (banishGear($location[The Wreck of the Edgar Fitzsimmons]) == $item[spring shoes] && available_amount($item[spring shoes]) > 0){
                        conditional += "spring shoes,";
                    } else if (get_property("heartstoneBanishUnlocked") == "true")
                        conditional += if_equip($item[heartstone]);
                    tempEquipment("item drop","monodent of the sea," + if_equip($item[Congressional Medal of Insanity]) + if_equip($item[peridot of peril]) + conditional + bathysphere($item[toy cupid bow]));
                    mood("itdrop");
                } else {
                    tempEquipment("-combat", "monodent of the sea," + conditional);
                    mood("-combat");
                }
                // Longest odds in the run: unholy diver is 1 of 5 here, and we
                // need 8 rivets plus a porthole plus a broken helmet.
                mapMonster($location[The Wreck of the Edgar Fitzsimmons]);
                adv($location[The Wreck of the Edgar Fitzsimmons]);
                // Just fought the diver, so it is queued and can be refought
                // for one turn instead of rolling 1-in-5 for it again.
                timeSpinnerRefight($location[The Wreck of the Edgar Fitzsimmons]);
            }
        }
        if (to_slot(divingHelmet()) != $slot[hat])
            retrieve_item($item[aerated diving helmet]);
    }

    // ── Construct banish + habitat recall for cyberzone ───────────────────────
    step("phase: Mom rescue (habitats / cyberzone)");
    if (my_path().id == 55){
        int initialMomProgress = 24;
        if (!have_item($item[backup camera]))
            initialMomProgress += 4;
        if (!have_item($item[2002 Mr. Store Catalog]))
            initialMomProgress += 12;
        if (available_amount($item[black glass]) == 0) 
            buy($coinmaster[Big Brother], 1, $item[black glass]);
        use_familiar("itdrop");
        if (my_familiar() == $familiar[red-nosed snapper])
            cli_execute("snapper horror");
        if (highShiny() && to_int(get_property("momSeaMonkeeProgress")) < 36){
            if (get_property("swordOfSWordsMonster") != "775"){
                use_familiar($familiar[sword of s words]);
                tempEquipment("item drop", if_equip($item[peridot of peril]) + swimmingTrunks() + bathysphere($item[toy cupid bow]));
                mood("itdrop");
                adv($location[The Coral Corral]);
            }
            while (to_int(get_property("momSeaMonkeeProgress")) < 40){
                if (available_amount($item[sea cowbell]) < 3)
                    use_familiar($familiar[sword of s words]);
                else 
                    use_familiar("itdrop");
                if (have_effect($effect[jelly combed]) == 0 && pullSequence($item[comb jelly])) {
                    use($item[comb jelly]);
                }
                if (available_amount($item[sea leather]) > 0 && available_amount($item[sea cowboy hat]) == 0)
                    create($item[sea cowboy hat]);
                string conditional;
                if (!contains_text(get_property("banishedMonsters"), "school of many"))
                    conditional += "monodent of the sea,";
                if (to_int(get_property("lassoTrainingCount")) < 20 && available_amount($item[sea cowboy hat]) > 0)
                    conditional += "sea cowboy hat,";
                if (have_effect($effect[driving waterproofly]) == 0){
                    pullSequence($item[elf guard scuba tank]);
                    conditional += "elf guard scuba tank,";
                }
                tempEquipment("item drop", "shark jumper," + underwaterPants() + "black glass," + conditional + bathysphere($item[toy cupid bow]));
                mood("itdrop");
                adv($location[The Caliginous Abyss]);
            }
        }
        if (to_int(get_property("momSeaMonkeeProgress")) < 24 && have_familiar($familiar[patriotic eagle]) && have_item($item[server room key])) {
            if (!contains_text(get_property("banishedPhyla"), "construct")) {
                if (get_property("madnessBakeryAvailable") == "false") {
                    visit_url("shop.php?whichshop=armory&action=talk");
                    run_choice(1);
                }
                while (!contains_text(get_property("banishedPhyla"), "construct")
                    && $location[madness bakery].turns_spent < 3) {
                    use_familiar($familiar[patriotic eagle]);
                    tempEquipment("item drop", "monodent of the sea");
                    adv($location[madness bakery]);
                }
            }
            while (get_property("_monsterHabitatsMonster") != "eye in the darkness" && get_property("_monsterHabitatsMonster") != "slithering thing" 
                && to_int(get_property("_monsterHabitatsRecalled")) < 3 && have_skill($skill[just the facts])) {
                recallCaliginous();
            }
            while (to_int(get_property("_monsterHabitatsFightsLeft")) > 0
                && to_int(get_property("_cyberFreeFights")) < 10
                && to_int(get_property("momSeaMonkeeProgress")) < 40) {
                use_familiar($familiar[glover]);
                tempEquipment("moxie", "shark jumper," + underwaterPants() + "monodent of the sea");
                if (my_buffedstat($stat[moxie]) < 500)
                    abort("Need 500 moxie here to be safe");
                adv($location[Cyberzone 1]);
            }
        }
        while (to_int(get_property("momSeaMonkeeProgress")) < initialMomProgress && (!have_familiar($familiar[patriotic eagle]) || !have_item($item[server room key]))){
            finishCaliginous();
        }
    }

    // ── Attempt at 1 turn coral corral
    if (get_property("corralUnlocked") == "true" && ($location[the coral corral].turns_spent == 0 || last_monster() == $monster[wild seahorse]) && get_property("seahorseName") == "" && my_path().id == 55 && highShiny() == false) {
        if (have_effect($effect[shadow waters]) == 0 && lowShiny() == false)
            shadowRift();
        use_familiar("itdrop");
        if (my_familiar() == $familiar[red-nosed snapper])
            cli_execute("snapper mer-kin");
        cli_execute("unequip blood cubic zirconia; unequip peridot of peril; unequip heartstone");
        codpiece("blood cubic zirconia, heartstone");
        if (get_property("_steelyEyedSquintUsed") == false)
            mood("superitdrop");
        if (available_amount($item[pro skateboard]) == 0)
            pullSequence($item[pro skateboard]);
        if (to_int(get_property("_backUpUses")) < 11 && have_item($item[backup camera]) 
          && (get_property("lastCopyableMonster") == "eye in the darkness" || get_property("lastCopyableMonster") == "slithering thing")){
            tempEquipment("item drop", "shark jumper," + underwaterPants() + if_equip(divingHelmet())
                + "pro skateboard," + if_equip($item[The Eternity Codpiece]) + "backup camera");
            mood("itdrop");
            adv($location[The Coral Corral]);
        } else if (have_skill($skill[steely-eyed squint]) && have_item($item[cursed monkey's paw])){
            pullSequence($item[software glitch]);
            tempEquipment("item drop", if_equip(divingHelmet()) + "pro skateboard," + if_equip($item[The Eternity Codpiece]));
            mood("itdrop");
            adv($location[The Coral Corral]);
        } else {
            pullSequence($item[pulled yellow taffy]);
            pullSequence($item[software glitch]);
            if (!have_item($item[spring shoes]) && !have_item($item[heartstone]) && available_amount($item[stuffed yam stinkbomb]) == 0 && available_amount($item[handful of split pea soup]) == 0 && !lowShiny())
                pullSequence($item[stuffed yam stinkbomb]);
            tempEquipment("item drop", if_equip(divingHelmet()) + "pro skateboard," + if_equip($item[The Eternity Codpiece]) + "monodent of the sea," + baseball_equip());
            mood("itdrop");
            adv($location[The Coral Corral]);
        }
    }
    if (item_amount($item[sea lasso]) < 5 && to_int(get_property("lassoTrainingCount")) < 20){
        while (!have_item($item[cursed monkey's paw]) && item_amount($item[sea lasso]) < 6){
            getMissingCorralItems();
            if (get_property("dolphinItem") == "sea lasso" && have_item($item[durable dolphin whistle]))
                use($item[durable dolphin whistle]);
        }
        codpiece("none");
    }

    // ── Diving helmet acquisition for non-monkey paw owners and shadow rift owners ───────────────────────────────

    // ── Craft sea cowboy hat and chaps ────────────────────────────────────────
    step("phase: corral (leather / cowbell)");
    if (my_path().id == 0){
        retrieve_item($item[sea chaps]);
        retrieve_item($item[sea cowboy hat]);
    } else {
        if (available_amount($item[sea chaps]) == 0 && tailpiece() == $item[none]) {
            while (item_amount($item[sea leather]) < 1){
                getMissingCorralItems();
                if (get_property("dolphinItem") == "sea leather" && have_item($item[durable dolphin whistle]))
                    use($item[durable dolphin whistle]);
            }
            create($item[sea chaps]);
        }
        if (available_amount($item[sea cowboy hat]) == 0) {
            while (item_amount($item[sea leather]) < 1){
                getMissingCorralItems();
                if (get_property("dolphinItem") == "sea leather" && have_item($item[durable dolphin whistle]))
                    use($item[durable dolphin whistle]);
            }
            create($item[sea cowboy hat]);
        }
    }
}
// ─── PEARL FARMING / EAGLE BANISH RE-AIM ─────────────────────────────────────
// One walker serves both postloop prefs. uts_postLoopRunOutEagleBanish
// (experimental): the Patriotic Eagle farms pearl zones until the screech
// recharges, spends it at once on the first monster at the Smut Orc
// Logging Camp -- the leftover construct banish moves onto the orc phylum
// -- and is done; a pearl the recharge started stays where it is.
// uts_postLoopFarmPearls: when a pearl's mall price
// beats the ten turns its farm costs at valueOfAdventure, keep walking
// until every open zone's daily pearl is claimed. Missing pieces abort
// loudly.
//
// Free kills, free runs and fight-enders advance neither a zone's pearl
// progress nor screechCombats -- only a combat fought to a plain win on a
// spent turn counts. _utsPearlFarm tells the CCS to fight that way while
// the walker below is running.

    string [location] pearlZoneRes = {
        $location[Anemone Mine]:          "spooky res",
        $location[The Dive Bar]:          "sleaze res",
        $location[Madness Reef]:          "stench res",
        $location[The Marinara Trench]:   "hot res",
        $location[The Briniest Deepests]: "cold res"
    };
    string [location] pearlClaimed = {
        $location[Anemone Mine]:          "_unblemishedPearlAnemoneMine",
        $location[The Dive Bar]:          "_unblemishedPearlDiveBar",
        $location[Madness Reef]:          "_unblemishedPearlMadnessReef",
        $location[The Marinara Trench]:   "_unblemishedPearlMarinaraTrench",
        $location[The Briniest Deepests]: "_unblemishedPearlTheBriniestDeepests"
    };

void pearlZonePrep(location zone) {
    string elem = substring(pearlZoneRes[zone], 0, index_of(pearlZoneRes[zone], " "));
    // Buffs up before the maximize: their res levels count toward the 18
    // and free gear slots for +combat.
    mood(elem + "res");
    mood("combat");
    // Res to the line, then combat with the change: the 200 weight means
    // no combat piece can outbid a needed res level, "18 max" stops the
    // maximizer crediting res past the line, and every slot left over
    // chases +combat -- each noncombat dodged is a turn the pearl doesn't
    // cost. No "18 min": a hard maximizer failure would abort as
    // "Maximizer failed" where pearlResCheck names the element and value.
    // Runs at zone entry AND as pearlResCheck's mid-zone recovery when a
    // lapsed buff leaves the outfit short -- so its generic "Missing"
    // abort can surface mid-zone where the res abort used to.
    tempEquipment("200 " + pearlZoneRes[zone] + " 18 max, combat",
        swimmingTrunks() + bathysphere($item[none]));
}

// Pearl progress pays its full 10% a combat only at 18+ of the zone's
// element; below that the game pays partial credit and the ten-combat
// pearl stretches. Checked every turn, not just at zone entry -- the res
// buffs run out mid-zone -- re-upping expired buffs and refusing to farm
// slower than the economics were priced at.
//
// The shortfall self-heals before aborting, because both failure modes
// are transient. The mood casts fail silently when the fights have
// drained MP -- and the pearl fights routinely end near zero -- so the
// top-up comes BEFORE the moods; after it, the res buffs land, and so
// do the +combat buffs that would otherwise stay silently down all
// zone whenever gear happens to carry the res. And the entry maximize
// ran under "18 max" while buffs were live, crediting them and putting
// zero res on the gear -- when they lapse the OUTFIT is the gap, so
// one pearlZonePrep re-dress with the true state visible fixes what a
// manual rerun used to.
void pearlResCheck(location zone) {
    string elem = substring(pearlZoneRes[zone], 0, index_of(pearlZoneRes[zone], " "));
    if (my_mp() < 30)
        topUpMp(30);
    mood(elem + "res");
    mood("combat");
    // Same lapsed-buff trap as the resistance below, one step nastier.
    // Driving Waterproofly is what lets swimmingTrunks() and
    // bathysphere() hand their slots to the maximizer, so a zone prepped
    // while it was up carries no breathing gear at all -- and when it
    // runs out mid-zone the next dive dies on "You can't breathe
    // underwater". Fishy does not cover this: it is what gets you into
    // the Sea, not what lets you breathe there. Re-dressing re-pins the
    // trunks and the bathysphere now that the effect is gone.
    if (!boolean_modifier("Adventure Underwater")
        || numeric_modifier(elem + " resistance") < 18)
        pearlZonePrep(zone);
    // Backstop only: when the trunks are simply absent, the re-dress
    // above already died inside tempEquipment with "Missing <item>".
    // This catches the quieter case -- a path where swimmingTrunks() has
    // nothing to offer at all -- rather than diving and failing.
    if (!boolean_modifier("Adventure Underwater"))
        abort("Pearl farming can't breathe in " + zone
            + ": Driving Waterproofly has lapsed and nothing in the outfit grants"
            + " underwater access. Re-drive Waterproofly or free up the pants"
            + " slot for the swimming trunks, then rerun.");
    if (numeric_modifier(elem + " resistance") < 18)
        abort("Pearl farming needs 18 " + elem + " resistance for full speed in "
            + zone + " and only " + to_int(numeric_modifier(elem + " resistance"))
            + " is up; add " + elem + " resistance gear or buffs and rerun.");
    // Last, once the gear above is settled: the walk's outfit carries no HP
    // weight, so max HP here is roughly half what it is in the run proper, and
    // a threshold computed back then leaves mafia waiting until a couple of
    // hundred HP to heal. These zones take 100-180 a fight and give back about
    // eight, so that is a slow slide into a lost combat rather than a fight
    // anyone could see coming.
    setRecoveryTargets();
}

// The walker's Beaten Up guard, called before each of its adventuring
// paths: lift the debuff, stop loudly if it will not lift. No zone
// re-prep -- nothing in the lift (rest, soda water, the Walrus cast)
// touches equipment, and the res moods are refreshed by pearlResCheck
// before every pearl turn anyway.
void pearlLiftOrAbort() {
    if (have_effect($effect[beaten up]) == 0)
        return;
    liftBeatenUp();
    if (have_effect($effect[beaten up]) > 0)
        abort("postloop pearls: Beaten Up won't lift; heal up and rerun.");
}

// mafia calls a combat filter every round until something ends the fight, so
// this has to stop offering the screech once it has been spent. The screech
// does NOT end the fight -- the foe "running off covering his ears" is
// flavour, and the monster keeps attacking -- it consumes itself, setting
// screechCombats to its 11-fight recharge, and KoL drops the skill from the
// fight's dropdown. Re-submitting a skill KoL no longer offers is rejected,
// so the round never advances while mafia's counter climbs ("thinks it is
// round 3 but KoL thinks it is round 2"), and nothing in mafia bounds that:
// the filter is retried until someone stops the script by hand. Testing the
// pref as well as the page keeps it bounded -- either the cast lands and
// screechCombats flips, or KoL stops offering the skill.
string screechFilter(int round, monster mob, string page_text) {
    if (to_int(get_property("screechCombats")) == 0
        && contains_text(page_text, "Release the Patriotic Screech"))
        return "skill 7451";   // %fn, Release the Patriotic Screech!
    return "attack";
}

// Both post-run preps start by emptying Hagnk's -- the run is over, so
// everything left in storage may as well be on hand for gearing and
// pearl-buying. Emptying is once per ascension; a repeat call is a no-op.
void pullEverything() {
    if (to_int(get_property("lastEmptiedStorage")) != my_ascensions())
        cli_execute("pull all");
}

// The postloop's adventure top-up: crack the six-pack if needed, Ode up,
// drink pilsners until the target is met. Returns whether it got there,
// so callers can tell "topped up" from "genuinely dry". Bails the moment
// a drink fails to add adventures rather than spinning on it.
boolean gainAdventures(int target) {
    while (my_adventures() < target) {
        int before = my_adventures();
        // Liver first: no point breaking the seal on a six-pack we could
        // not drink from anyway.
        if (my_inebriety() >= inebriety_limit())
            return false;
        if (item_amount($item[astral pilsner]) == 0
            && item_amount($item[astral six-pack]) > 0)
            use($item[astral six-pack]);
        if (item_amount($item[astral pilsner]) == 0)
            return false;
        cli_execute("shrug Donho's Bubbly Ballad");
        if (have_skill($skill[The Ode to Booze]))
            use_skill($skill[the ode to booze]);
        drink($item[astral pilsner]);
        if (my_adventures() <= before)
            return false;
    }
    return true;
}

// What the Lucky! dive costs. The Haggling grants its full 20 turns
// either way, but encountering it with no Fishy left costs two
// adventures instead of one -- so topping up on the LAST turn of Fishy
// is strictly cheaper, and keeps The Brinier Deepers reachable while we
// are still fishy rather than betting on gear for underwater access.
int cloverFishyCost() {
    return have_effect($effect[Fishy]) > 0 ? 1 : 2;
}

// Why a Lucky! Fishy top-up could not run, or "" when it can. Named
// rather than folded into cloverFishy's boolean so the caller's abort
// can say which precondition failed: "out of Fishy" while the pref is
// on and the real blocker was two adventures reads as the feature being
// broken.
string cloverFishyBlocker() {
    if (get_property("uts_postLoopCloverFishy") != "true")
        return "uts_postLoopCloverFishy is not set";
    // The dive itself, plus the pearl turn it exists to enable -- a top
    // up that leaves nothing to spend afterwards burns the clover for
    // no progress.
    int need = cloverFishyCost() + 1;
    if (my_adventures() < need
        && !(my_inebriety() < inebriety_limit()
            && (item_amount($item[astral pilsner]) > 0
                || item_amount($item[astral six-pack]) > 0)))
        return "needs " + need + " adventures, has " + my_adventures()
            + ", and no drinkable astral pilsner to cover the difference";
    if (!can_adventure($location[The Brinier Deepers]))
        return "The Brinier Deepers isn't reachable (underwater access -- check the swimming trunks)";
    if (have_effect($effect[Lucky!]) == 0
        && !(have_skill($skill[Aug. 2nd: Find an Eleven-Leaf Clover Day])
            && get_property("_aug2Cast") == "false"
            && to_int(get_property("_augSkillsCast")) < 5)
        && item_amount($item[11-leaf clover]) == 0
        && !(get_property("autoSatisfyWithCoinmasters") == "true"
            && to_int(get_property("_cloversPurchased")) < 3))
        return "no way to get Lucky! -- no free Aug. 2nd cast, no 11-leaf clover, no hermit clovers";
    return "";
}

// uts_postLoopCloverFishy: top Fishy up with a Lucky! visit to The
// Brinier Deepers -- The Haggling grants 20 turns, and works even at
// 0 Fishy for 2 adventures instead of 1 -- so the walk keeps going
// where it would otherwise stop. Aug 2nd casts are free Lucky!; after
// those, an 11-leaf clover from inventory or, when mafia may buy from
// the hermit, his daily three.
boolean cloverFishy(location zone) {
    if (cloverFishyBlocker() != "")
        return false;
    // Adventures are topped up rather than treated as a hard block: the
    // walker's own pilsner ladder sits further down the loop and only
    // fires at exactly zero, so a farm a turn or two short aborted "out
    // of Fishy" with pilsners still in the inventory. The Lucky! source
    // was already proved by the blocker above -- getLucky()'s clover
    // branch exits the script when none can be had, which is why that
    // check has to happen before we call it.
    if (!gainAdventures(cloverFishyCost() + 1))
        return false;
    getLucky();
    if (have_effect($effect[Lucky!]) == 0)
        return false;
    step("postloop pearls: Lucky! trip to The Brinier Deepers for 20 turns of Fishy");
    // The zone is underwater: gear the player's breathing and the
    // familiar's bathysphere before diving -- the walk may not have
    // prepped a zone yet when this fires.
    tempEquipment("combat", swimmingTrunks() + bathysphere($item[none]));
    adv1($location[The Brinier Deepers]);
    // A wanderer can spend the turn without spending the Lucky!; one
    // more visit collects The Haggling. Fund the retry the same way the
    // first dive was funded rather than testing the counter raw: the
    // Lucky! is already paid for, so giving up here with pilsners still
    // drinkable throws the clover away. cloverFishyCost() now reads 2 --
    // the first dive spent the last of the Fishy -- so this asks for the
    // retry plus the pearl turn it exists to enable.
    if (have_effect($effect[Fishy]) == 0
        && have_effect($effect[Lucky!]) > 0
        && gainAdventures(cloverFishyCost() + 1))
        adv1($location[The Brinier Deepers]);
    boolean fishy = have_effect($effect[Fishy]) > 0;
    // The dive's maximize stripped the pearl gear; a still-live zone gets
    // its 18-res outfit back before the walk's next turn there.
    if (zone != $location[none] && get_property(pearlClaimed[zone]) != "true")
        pearlZonePrep(zone);
    return fishy;
}

void pearlPostloop() {
    boolean rundown = get_property("uts_postLoopRunOutEagleBanish") == "true"
        && contains_text(get_property("banishedPhyla"), "construct");
    boolean farm;
    if (get_property("uts_postLoopFarmPearls") == "true") {
        int pearlPrice = mall_price($item[unblemished pearl]);
        int voa = to_int(get_property("valueOfAdventure"));
        if (pearlPrice > 0 && voa <= 0) {
            // garbo's own default; an unset zero would make farming always win.
            voa = 4000;
            print("uts_postLoopFarmPearls: valueOfAdventure isn't set, assuming " + voa + ".", "blue");
        }
        if (pearlPrice <= 0)
            print("uts_postLoopFarmPearls: couldn't get a mall price for the pearl; skipping the farm.", "red");
        else if (pearlPrice <= voa * 10)
            print("uts_postLoopFarmPearls: a pearl mall-buys at " + pearlPrice
                + " and ten farming turns are worth " + (voa * 10)
                + " -- buying beats farming today.", "blue");
        else {
            farm = true;
            step("postloop: pearls sell for " + pearlPrice + " against " + (voa * 10)
                + " for ten farming turns -- farming");
        }
    }
    if (!rundown && !farm)
        return;
    if (rundown) {
        step("postloop: re-aiming the Patriotic Screech off the construct phylum");
        if (!have_familiar($familiar[Patriotic Eagle]))
            abort("uts_postLoopRunOutEagleBanish: no Patriotic Eagle in the terrarium, so the screech can't be re-aimed.");
        if (!can_adventure($location[The Smut Orc Logging Camp]))
            abort("uts_postLoopRunOutEagleBanish: The Smut Orc Logging Camp isn't open, and the re-aim needs a place to screech.");
    }
    pullEverything();
    // The eagle's combats are what recharge the screech, so it stays out
    // until the re-aim; otherwise the Hound Dog's +combat means fewer
    // noncombats per pearl (picked directly, never via the "combat"
    // overload, which force-swaps Hound-Dog-less accounts; the maximizer
    // never recommends familiars). With no familiar out at all, bathysphere()'s
    // equip term has nowhere to land and tempEquipment aborts; beyond
    // that the familiar doesn't matter, pearls are counter claims, not
    // drops.
    if (rundown)
        use_familiar($familiar[Patriotic Eagle]);
    else if (have_familiar($familiar[Jumpsuited Hound Dog]))
        use_familiar($familiar[Jumpsuited Hound Dog]);
    if (my_familiar() == $familiar[none]) {
        foreach fam in $familiars[Patriotic Eagle, grouper groupie] {
            if (have_familiar(fam)) {
                use_familiar(fam);
                break;
            }
        }
        if (my_familiar() == $familiar[none])
            abort("postloop pearls: no familiar out; take out any familiar and rerun.");
    }
    set_property("_utsPearlFarm", "true");
    int spent;
    int claimed;
    location current = $location[none];
    try {
    while (true) {
        // The moment the screech is back, spend it: one fight at the Smut
        // Orc Logging Camp moves the banish onto the orc phylum, and the
        // rundown is done. Zone progress holds while stepping out, so a
        // continuing farm loses nothing to the detour.
        if (rundown && to_int(get_property("screechCombats")) == 0) {
            if (my_adventures() == 0)
                abort("uts_postLoopRunOutEagleBanish: out of adventures with the screech ready; get a turn and rerun to re-aim.");
            // A pearl loss last turn must not fight the orc at halved stats.
            pearlLiftOrAbort();
            adv1($location[The Smut Orc Logging Camp], -1, "screechFilter");
            if (contains_text(get_property("banishedPhyla"), "construct"))
                abort("uts_postLoopRunOutEagleBanish: the screech didn't re-aim; constructs are still banished.");
            print("Patriotic Screech re-aimed at smut orcs after " + spent + " pearl-farming turns; constructs are free.", "blue");
            rundown = false;
            // Only a continuing farm needs the handoff; the rundown alone
            // is done the moment the screech is spent.
            if (farm && have_familiar($familiar[Jumpsuited Hound Dog])) {
                use_familiar($familiar[Jumpsuited Hound Dog]);
                // The bathysphere is familiar equipment, so the new
                // familiar needs it maximized back on before the next
                // underwater turn; a claimed or unset zone gets its prep
                // from the selection block instead.
                if (current != $location[none]
                    && get_property(pearlClaimed[current]) != "true")
                    pearlZonePrep(current);
            }
        }
        if (!rundown && !farm)
            break;
        // Rundown-only: its message is rundown-specific, and hard-stopping
        // here made the farm's cloverFishy() fallback (at the mid-zone
        // check below) unreachable -- a farm-only run that exhausted Fishy
        // aborted instead of restocking via a Lucky! trip.
        if (rundown && have_effect($effect[Fishy]) == 0)
            abort("uts_runOutEagleBanish: out of Fishy after " + spent
                + " turns with the re-aim unfinished.");
        // Same pilsner ladder as the in-run diet, shared with cloverFishy().
        // Deliberately not fatal: a farm that spends its last adventure on
        // its last pearl arrives here dry with a liver full of the pilsners
        // that got it this far, and that is a finished farm, not a failure.
        // Zone selection below breaks cleanly when nothing is unclaimed, and
        // the mid-zone stop after it aborts if work really does remain.
        gainAdventures(1);
        // The rundown, unlike the farm, has nothing useful to break out
        // to: falling through with no adventures lands on the "no open
        // pearl zone" abort, which blames a missing zone for what is
        // really an empty turn budget.
        if (rundown && my_adventures() == 0)
            abort("uts_runOutEagleBanish: out of adventures with the re-aim"
                + " unfinished, and no astral pilsner could be drunk"
                + " (none left, or the liver is full).");
        // Rundown-only, like the Fishy stop above: a five-zone farm
        // legitimately needs ~50 turns, and the farm has its own 90-turn
        // guard at the mid-zone checks -- ungated, this cap strangled it.
        if (rundown && spent >= 40)
            abort("uts_runOutEagleBanish: the screech still isn't ready after 40 turns; something is wrong, bailing out.");
        // Lift here, after the rundown-done break and the pilsner ladder:
        // the day's last adventure may be exactly what the lift's rest
        // needs, so adventure manufacture must come first. Zone selection
        // below maximizes -- never through halved stats.
        pearlLiftOrAbort();
        if (current == $location[none] || get_property(pearlClaimed[current]) == "true") {
            current = $location[none];
            foreach loc in pearlZoneRes {
                if (get_property(pearlClaimed[loc]) != "true" && can_adventure(loc)) {
                    current = loc;
                    break;
                }
            }
            if (current == $location[none]) {
                if (rundown)
                    abort("uts_postLoopRunOutEagleBanish: no open pearl zone with today's pearl unclaimed to recharge the screech in.");
                break;
            }
            pearlZonePrep(current);
        }
        // Top up on the LAST turn of Fishy, not after it runs out: The
        // Haggling costs one adventure while fishy and two from zero.
        // Read the blocker first -- cloverFishy() spends the very things
        // it names (the clover, the pilsner), so asking afterwards
        // reports the aftermath instead of the cause.
        if (have_effect($effect[Fishy]) <= 1) {
            string fishyBlocker = cloverFishyBlocker();
            if (!cloverFishy(current) && have_effect($effect[Fishy]) == 0)
                abort("postloop pearls: out of Fishy mid-zone after " + spent + " turns with "
                    + claimed + " pearls claimed; today's zone progress won't survive rollover."
                    + (fishyBlocker == ""
                        ? " The Lucky! top-up cleared its preconditions but didn't land --"
                            + " the clover may not have been obtainable (the hermit wants"
                            + " worthless items), or wanderers ate the dive; check The"
                            + " Brinier Deepers by hand."
                        : " The Lucky! top-up couldn't run: " + fishyBlocker + "."));
        }
        if (my_adventures() == 0)
            abort("postloop pearls: out of adventures mid-zone after " + spent + " turns with "
                + claimed + " pearls claimed; today's zone progress won't survive rollover.");
        if (spent >= 90)
            abort("postloop pearls: 90 turns spent without finishing; something is wrong, bailing out.");
        // cloverFishy() above may have fought (and lost) a Lucky! dive --
        // never take the pearl turn with the debuff on.
        pearlLiftOrAbort();
        pearlResCheck(current);
        // Cleared just before the turn so the read below sees only THIS
        // fight's outcome: mafia rewrites the pref only when a fight ends,
        // so a stale "true" from a pre-loop loss, the screech fight or a
        // cloverFishy dive would otherwise book a phantom pearl loss.
        set_property("_lastCombatLost", "false");
        adv1(current);
        spent += 1;
        // Only a plain win ticks pearl progress, so a lost fight is pure
        // turn burn -- and a full-strength walker should essentially never
        // lose one, so a single loss is evidence enough. Stop immediately:
        // zone progress lives in daily prefs, and a rerun lifts Beaten Up
        // on entry and resumes exactly where this stopped.
        if (get_property("_lastCombatLost") == "true")
            abort("postloop pearls: lost a combat in " + current + " after "
                + spent + " turns with " + claimed + " pearls claimed; check"
                + " HP/MP recovery and gear, then rerun -- progress is saved.");
        // The claim flips the zone's daily pref; count it here (the only
        // place a pearl can land) so the progress and abort messages stop
        // reporting a permanent zero.
        if (current != $location[none]
            && get_property(pearlClaimed[current]) == "true")
            claimed += 1;
    }
    } finally {
        set_property("_utsPearlFarm", "false");
    }
    if (farm) {
        foreach loc in pearlZoneRes {
            if (get_property(pearlClaimed[loc]) != "true")
                print("uts_postLoopFarmPearls: " + loc + " left unclaimed.", "red");
        }
        print("uts_postLoopFarmPearls: " + claimed + " pearls claimed in " + spent + " turns.", "blue");
    }
}

// uts_postLoopPrepCodpiece: leave the run with the codpiece already loaded for the
// next ascension -- five unblemished pearls, mall-bought if the farm came
// up short. Runs after the banish rundown and the pearl farm so their
// pearls count.
void prepCodpiece() {
    if (get_property("uts_postLoopPrepCodpiece") != "true")
        return;
    step("postloop: loading the codpiece with unblemished pearls");
    if (!have_item($item[The Eternity Codpiece]))
        abort("uts_postLoopPrepCodpiece: you don't own The Eternity Codpiece.");
    pullEverything();
    codpiece("none");
    if (item_amount($item[unblemished pearl]) < 5)
        retrieve_item(5, $item[unblemished pearl]);
    if (item_amount($item[unblemished pearl]) < 5)
        abort("uts_postLoopPrepCodpiece: couldn't get to five unblemished pearls (have "
            + item_amount($item[unblemished pearl]) + ").");
    codpiece("unblemished pearl, unblemished pearl, unblemished pearl, unblemished pearl, unblemished pearl");
    print("Codpiece loaded: five unblemished pearls slotted for the next run.", "blue");
}

// ─── SORCERESS ────────────────────────────────────────────────────────────────

// One pass of the gladiator-gear grind: a gymnasium turn, then the Grandma
// trade once both raw drops are in hand. Split out of the loop in sorceress()
// so a caller waiting an effect out can take one step and re-check between.
void gladiatorGearStep() {
    gymnasium();
    if (item_amount($item[Mer-kin thighguard]) > 0
        && item_amount($item[Mer-kin headguard]) > 0) {
        equip($slot[hat], $item[none]);
        equip($slot[pants], $item[none]);
        equipSwimTrunks();
        if (item_amount($item[Mer-kin scholar mask]) > 0){
            visit_url("shop.php?whichshop=grandma&action=buyitem&quantity=1&whichrow=131");
        }
        if (item_amount($item[Mer-kin scholar tailpiece]) > 0){
            visit_url("shop.php?whichshop=grandma&action=buyitem&quantity=1&whichrow=1619");
        }
        foreach it in $items[Mer-kin gladiator mask,Mer-kin gladiator tailpiece]{
            if (available_amount(it) == 0)
                buy($coinmaster[Grandma Sea Monkey],1,it);
        }
    }
}

// One colosseum round. Gladiators are insta-kill immune (bricks and X-Rays
// glance, the Asdon missile reads UNTARGETABLE), so the club is the only free
// round in the building -- against immune monsters Club 'Em still deals 30% max
// HP and frees the fight. Past its five casts, only the bat wings proc can
// refund a round. Split out of the loop in sorceress() for the same reason as
// gladiatorGearStep().
void colosseumRound() {
    // Fund the bladeswitcher stall. Its reflect costs ten rounds of dealing no
    // damage, and the unguent is 30 meat over the counter in Market Square --
    // restockable, and clear of both the pulled scrolls and the sand-penny items
    // Yog-Urt is fought with. Eleven: ten to stall on, one left for her fight.
    //
    // Here rather than before the loop in sorceress() because that is not the
    // only way in: the Gummiheart wait reaches colosseum rounds through
    // burnTurnElsewhere(), which never passes that line. Restocking per round
    // also refills between fights, and costs an inventory check once the stock
    // is up.
    if (item_amount($item[Doc Galaktik's Pungent Unguent]) < 11)
        cli_execute("acquire 11 Doc Galaktik's Pungent Unguent");
    // The unguent only buys rounds; sea gel is what keeps us alive through them
    // at 500 HP a throw, against a stall costing 110-175 a round. Five: four to
    // spend, one left for Yog-Urt. Ten sand pennies each, and pennies drop from
    // every combat, but the buy still waits for a full price so a thin purse is
    // left for the ladder that spends it later.
    while (item_amount($item[sea gel]) < 5
        && item_amount($item[sand penny]) >= 10) {
        // Both conditions only move on a successful buy, so a refused one would
        // spin here -- and this runs every colosseum round, not once.
        if (!buy($coinmaster[Wet Crap For Sale], 1, $item[sea gel])) break;
    }
    string freeFight;
    if (to_int(get_property("_clubEmTimeUsed")) < 5 && !highShiny() && !lowShiny() && have_item($item[legendary seal-clubbing club]))
        freeFight = "legendary seal-clubbing club,";
    if (to_int(get_property("_batWingsFreeFights")) < 5 && !highShiny()
        && if_equip($item[bat wings]) != "")
        freeFight += if_equip($item[bat wings]);
    else if (have_item($item[Unwrapped knock-off retro superhero cape])){
        freeFight += "unwrapped knock-off retro superhero cape,";
        modes = "retrocape heck kill";
    }

    if (to_int(get_property("lastColosseumRoundWon")) >= 3
        && have_effect($effect[Up To 11]) == 0)
        cli_execute($effect[Up To 11].default);
    if (to_int(get_property("lastColosseumRoundWon")) >= 6) {
        if (item_amount($item[crayon shavings]) < 8
            && item_amount($item[null-day exploit]) > 0
            && have_effect($effect[null afternoon]) == 0)
            use($item[null-day exploit]);
        if (have_familiar($familiar[patriotic eagle]) && to_int(get_property("screechCombats")) > 0 && have_item($item[Congressional Medal of Insanity])) {
            use_familiar($familiar[patriotic eagle]);
        }
        else if (have_familiar($familiar[foul ball])) {
            use_familiar($familiar[foul ball]);
        }
        mood("colosseum");
    }
    float coeff = (60 + my_buffedstat($stat[mysticality])/2.5)/(numeric_modifier("spell damage percent") + 1);
    tempEquipment(coeff + " spell damage percent, mys", "Mer-kin gladiator tailpiece,Mer-kin gladiator mask,"
        + if_equip($item[Congressional Medal of Insanity]) + freeFight + bathysphere($item[none]));
    adv($location[Mer-kin Colosseum]);
    if (get_property("lastEncounter") == "Been There, Won That"){
        set_property("lastColosseumRoundWon","15");
        set_property("isMerkinGladiatorChampion","true");
    }
}

// The places the run can spend a turn it owed anyway, tried in the order
// sorceress() works them. A blocking effect only ticks down on turns actually
// spent, so this is how the script waits one out without wasting anything.
//
// Returns false only when every sink is finished. Whether a pass consumed a
// turn is a separate question, and the caller's to ask: underwater combats are
// routinely free (banishes, free fights, noncombat forcers), so a single
// turnless pass says nothing about whether work remains.
// TODO: the Deep-Tainted Mind loop still open-codes an older, shorter version
// of this ladder.
boolean burnTurnElsewhere() {
    if (get_property("skateParkStatus") == "war"
        && !contains_text($location[The Skate Park].noncombat_queue,
            "Holey Rollers")) {
        skatePark();
        return true;
    }
    if (my_path().id == 55 || boss == "Shub") {
        // The gear grind comes first and runs long enough to outlast any effect
        // worth waiting out, so the colosseum is the backstop for a run that
        // already holds its gear. Winning it early cannot strand a boss: this
        // path fights both elder gods, so the temple keeps a separate door per
        // boss (Right/Left/center for Yog-Urt/Shub/Dad) and the colosseum only
        // unlocks Shub's.
        if (available_amount($item[Mer-kin gladiator mask]) == 0
            || available_amount($item[Mer-kin gladiator tailpiece]) == 0) {
            gladiatorGearStep();
            if (get_property("_skateBuff1") == "false")
                visit_url("sea_skatepark.php?action=state2buff1");
            return true;
        }
        if (to_int(get_property("lastColosseumRoundWon")) < 15) {
            colosseumRound();
            return true;
        }
    }
    if (get_property("questS02Monkees") == "step12") {
        finishCaliginous();
        return true;
    }
    return false;
}

void sorceress() {

    // ── Shadow rift prep ─────────────────────────────────────────────────────
    step("phase: shadow rift prep");
    if (my_path().id == 55){
        if (to_int(get_property("encountersUntilSRChoice")) > 9
            && get_property("questRufus") == "unstarted"
            && item_amount($item[Closed-circuit pay phone]) > 0) {
            retrieve_item($item[oversized sparkler]);
            if (item_amount($item[lump of loyal latite]) > 0)
                use($item[lump of loyal latite]);
            tempEquipment("item drop", "Flash Liquidizer Ultra Dousing Accessory,monodent of the sea,"
                + if_equip($item[bat wings]) + if_equip($item[Everfull Dart Holster]) + if_equip($item[toy cupid bow]));
            mood("itdrop");
            if (!highShiny() && have_item($item[closed-circuit pay phone]))
                use($item[closed-circuit pay phone]);
        }

        if (get_property("_curveballFightsLeft").to_int() > 0 && get_property("_curveballMonster") == "some fish" && item_amount($item[mer-kin digpick]) == 0){
            curveballBurn();
        }
        while (get_property("_curveballFightsLeft").to_int() > 0 && get_property("_curveballMonster") == "some fish" && !have_item($item[platinum yendorian express card])){
            curveballBurn();
        }
    }

    // ── Teflon ore acquisition ────────────────────────────────────────────────
    step("phase: teflon ore");
    if (item_amount($item[teflon ore]) == 0 && tailpiece() == $item[none]) {
        if (available_amount($item[mer-kin digpick]) == 0 && lowShiny() == false
            && pulls_remaining() > reservedPulls()){
            pullSequence($item[mer-kin digpick]);
        } else if (available_amount($item[mer-kin digpick]) == 0){
            mood("itdrop");
            tempEquipment("item drop", "really nice swimming trunks," + if_equip($item[peridot of peril]) + bathysphere($item[none]));
            if (numeric_modifier($modifier[item drop]) > 250){
                adv($location[anemone mine]);
            } else if (have_item($item[bat wings])){
                equip($item[bat wings]);
                adv($location[anemone mine]);
            } 
            if (available_amount($item[mer-kin digpick]) == 0) {
                pullSequence($item[mer-kin digpick]);
            }
        }
        while (to_int(get_property("_unaccompaniedMinerUsed")) < 5
            && have_skill($skill[Unaccompanied Miner])
            && item_amount($item[teflon ore]) == 0)
            teflon();
        if (item_amount($item[teflon ore]) == 0
            && !contains_text(get_property("_roninStoragePulls"), "11103")) {
            pullSequence($item[lodestone]);
            use($item[lodestone]);
        }
    }
    if (my_path().id == 55){
        // ── Platinum Yendorian Express Card ───────────────────────────────────────
        if (get_property("expressCardUsed") == "false" && have_item($item[platinum yendorian express card]) && !highShiny()) {
            if (storage_amount($item[Platinum Yendorian Express Card]) > 0
                && item_amount($item[Platinum Yendorian Express Card]) == 0)
                take_storage(1, $item[Platinum Yendorian Express Card]);
            use($item[Platinum Yendorian Express Card]);
        }

        // ── Lasso training via shadow rift ────────────────────────────────────────
        step("phase: lasso training");
        while (to_int(get_property("lassoTrainingCount")) < 20 && !highShiny() && (have_effect($effect[shadow affinity]) > 0 || get_property("_shadowAffinityToday") == "false") && have_item($item[closed-circuit pay phone]))
            shadowRift();

        if ((my_turncount( ) > 25 || !have_item_anywhere($item[Miniature crystal ball])) && !highShiny() && have_item($item[closed-circuit pay phone])){
            while ((have_effect($effect[shadow affinity]) > 0 || get_property("_shadowAffinityToday") == "false"))
                shadowRift();
        }

        // ── Teflon ore second attempt (post-lodestone) ────────────────────────────
        if (item_amount($item[teflon ore]) == 0 && tailpiece() == $item[none]) {
            while (have_effect($effect[Loded]) > 0
                && item_amount($item[teflon ore]) == 0)
                teflon();
            if (item_amount($item[teflon ore]) == 0) {
                print("Failed to acquire teflon ore — can pull mining dynamite"
                    + " for one more try", "red");
                while (item_amount($item[teflon ore]) == 0)
                    teflon();
            }
        }
    }

    // ── Lasso training backup ─────────────────────────────────────────────────
    while (to_int(get_property("lassoTrainingCount")) < 20) {
        print("Lasso training didn't finish via shadow rift", "red");
        backupLasso();
    }

    int wantCowbell;
    if (available_amount($item[cursed monkey's paw]) == 0 || highShiny())
        wantCowbell = 2;
    else if (to_int(get_property("_monkeyPawWishesUsed")) > 3)
        wantCowbell = 2-(5 - to_int(get_property("_monkeyPawWishesUsed")));
    if (get_property("seahorseName") == "" && item_amount($item[sea cowbell]) < wantCowbell){
        while (item_amount($item[sea cowbell]) < wantCowbell){
            getMissingCorralItems();
            if (get_property("dolphinItem") == "sea cowbell" && have_item($item[durable dolphin whistle]))
                use($item[durable dolphin whistle]);
        }
    }
    if (get_property("seahorseName") == "" && item_amount($item[sea lasso]) == 0){
        while (item_amount($item[sea lasso]) == 0){
            getMissingCorralItems();
            if (get_property("dolphinItem") == "sea lasso" && have_item($item[durable dolphin whistle]))
                use($item[durable dolphin whistle]);
        }
    }

    // ── Seahorse taming ───────────────────────────────────────────────────────
    step("phase: seahorse taming");
    while (get_property("seahorseName") == "") {
        if (my_path().id == 0){
            retrieve_item(3, $item[sea cowbell]);
            retrieve_item($item[sea lasso]);
        }
        if (item_amount($item[sea cowbell]) < 3
            && !contains_text(get_property("_roninStoragePulls"), "4196"))
            pullSequence($item[sea cowbell]);

        use_familiar("itdrop");
        string conditional;
        if (!contains_text(get_property("_perilLocations"), "199"))
            conditional += if_equip($item[peridot of peril]);
        if (!have_item($item[august scepter])){
            pullSequence($item[waffle]);
            conditional += "monodent of the sea,";
            conditional += if_equip($item[heartstone]);
        } else if (have_item_anywhere($item[Miniature crystal ball])){
            conditional += "Miniature crystal ball,";
        }
        if (get_property("_curveballFightsLeft").to_int() > 0 && get_property("_curveballMonster") == "some fish")
            conditional += "monodent of the sea,";
        // All three non-seahorse monsters banished — equip tearaway pants
        if (contains_text(get_property("banishedMonsters"), "Mer-kin rustler")
            && contains_text(get_property("banishedMonsters"), "sea cowboy")
            && contains_text(get_property("banishedMonsters"), "sea cow:")
            && have_item($item[tearaway pants])) {
            conditional += "tearaway pants," + if_equip(divingHelmet());
        } else {
            conditional += swimmingTrunks();
        }
        tempEquipment("initiative",conditional);
        
        while (item_amount($item[sea lasso]) == 0)
            monkeypaw($item[sea lasso]);
        while (item_amount($item[sea cowbell]) < 3
            && to_int(get_property("_monkeyPawWishesUsed")) < 5)
            monkeypaw($item[sea cowbell]);
        if (item_amount($item[sea cowbell]) < 3)
            abort("need more cowbells");

        adv($location[The Coral Corral]);
        // Burn shadow affinity if crystal ball shows non-seahorse incoming
        if (contains_text(get_property("crystalBallPredictions"), "The Coral Corral")
            && !contains_text(get_property("crystalBallPredictions"), "The Coral Corral:Wild seahorse")
            && have_effect($effect[shadow affinity]) > 0 && have_item_anywhere($item[miniature crystal ball]))
            shadowRift();
        while (have_effect($effect[shadow affinity]) > 0 && item_amount($item[shadow brick]) == 0
            && !contains_text(get_property("crystalBallPredictions"), "The Coral Corral:Wild seahorse") && have_item_anywhere($item[miniature crystal ball]))
            shadowRift();
    }

    // ── Drain remaining shadow affinity ──────────────────────────────────────

    while (have_effect($effect[shadow affinity]) > 0){
        while (get_property("_curveballFightsLeft").to_int() > 0 && get_property("_curveballMonster") == "some fish"){
            curveballBurn();
        }
        shadowRift();
    }
    if (get_property("encountersUntilSRChoice") == "0")
        adv($location[Shadow Rift (The Misspelled Cemetary)]);
    if (get_property("questRufus") == "step1") {
        use($item[closed-circuit pay phone]);
        adv($location[Shadow Rift (The Misspelled Cemetary)]);
    }

    // ── Buy crappy disguise if no tailpiece ───────────────────────────────────
    if (tailpiece() == $item[none]) {
        equipSwimTrunks();
        while (item_amount($item[sand dollar]) < 10)
            getSandDollar();
        cli_execute("unequip sea chaps; unequip aerated diving helmet");
        if (available_amount($item[crappy Mer-kin mask]) == 0){
            while (available_amount($item[pristine fish scale]) < 3){
                if (to_int(get_property("_cloversPurchased")) < 3) {
                    getLucky();
                    equip ($slot[acc3],$item[black glass]);
                } else
                    abort("get a total of pristine fish scale, out of hermitage clovers");
                adv($location[the caliginous abyss]);
            }
            retrieve_item($item[crappy Mer-kin mask]);
        }
        if (available_amount($item[crappy Mer-kin tailpiece]) == 0){
            while (available_amount($item[pristine fish scale]) < 3){
                if (to_int(get_property("_cloversPurchased")) < 3){
                    getLucky();
                    equip ($slot[acc3],$item[black glass]);
                } else
                    abort("get a total of pristine fish scale, out of hermitage clovers");
                adv($location[the caliginous abyss]);
            }
            retrieve_item($item[crappy Mer-kin tailpiece]);
        }
    }

    if (my_path().id == 0){
        boss = user_prompt("Which boss?", $strings[Yogurt,Shub,Dad,Abort]);
        if (boss == "Abort" || boss == "")
            abort();
    }

    if (get_property("dreadScroll3") == "0") {
        maximize("50 spooky res, hp",false);
        while (get_property("dreadScroll3") == "0") {
            restore_hp(1000);
            topUpMp(150);
            use_skill($skill[deep dark visions]);
        }
    }

    // ── YogUrt preparation ────────────────────────────────────────────────────
    step("phase: Yog-Urt preparation");
    topUpMp(250);
    if ((get_property("yogUrtDefeated") == "false" && my_path().id == 55) || (my_path().id == 0 && boss == "Yogurt")) {
        if (get_property("isMerkinHighPriest") == "false") {
            if (isKBandSushiEnough() == false || my_path().id == 0){
                // Farm mer-kin cheatsheets and unlock teacher
                if (my_path().id == 0){
                    cli_execute("acquire 10 mer-kin cheatsheet, 10 mer-kin wordquiz, mer-kin killscroll, mer-kin healscroll, mer-kin knucklebone");
                }
                step("phase: elementary school (cheatsheets / vocabulary)");
                while (item_amount($item[mer-kin cheatsheet]) < 9 && get_property("merkinVocabularyMastery") == "0") {
                    getCheatsheet();
                }

                // Unlock teacher via NC if not yet done
                while (get_property("merkinElementaryTeacherUnlock") == "false" && !libraryReady()) {
                    put_closet(item_amount($item[mer-kin hallpass]),
                        $item[mer-kin hallpass]);
                    string conditional;
                    if (to_int(get_property("_backUpUses")) < 11 && have_item($item[backup camera]))
                        conditional += "backup camera,";
                    else if (have_skill($skill[Double-Fisted Skull Smashing]))
                        conditional += "monodent of the sea,";
                    if (to_int(get_property("_clubEmBattlefieldUsed")) < 5)
                        conditional += if_equip($item[legendary seal-clubbing club]);
                    else if (baseballPlayers() < 9 || !contains_text(get_property("baseballTeam"),"838"))
                        conditional += if_equip($item[baseball diamond]);
                    tempEquipment("-combat", "crappy Mer-kin tailpiece,crappy Mer-kin mask,"
                        + if_equip($item[blood cubic zirconia]) + bathysphere($item[toy cupid bow])
                        + if_equip($item[M&ouml;bius ring]) + conditional);
                    mood("-combat");
                    adv($location[mer-kin elementary school]);
                    put_closet(item_amount($item[mer-kin hallpass]),
                        $item[mer-kin hallpass]);
                }

                // Get mer-kin bunwig if missing
                while (available_amount($item[mer-kin bunwig]) == 0 && !libraryReady()) {
                    if (contains_text(get_property("baseballTeam"),"773") && baseballPlayers() == 9){
                        baseballD();
                        continue;
                    }
                    tempEquipment("item drop, hat drop","crappy Mer-kin tailpiece,crappy Mer-kin mask," + if_equip($item[legendary seal-clubbing club])
                        + if_equip($item[blood cubic zirconia]) + if_equip($item[M&ouml;bius ring]) + bathysphere($item[toy cupid bow]));
                    mood("itdrop");
                    if (get_property("merkinElementaryTeacherUnlock") == "false")
                        mood("-combat");
                    adv($location[mer-kin elementary school]);
                    put_closet(item_amount($item[mer-kin hallpass]),
                        $item[mer-kin hallpass]);
                }

                take_closet(closet_amount($item[mer-kin hallpass]),
                    $item[mer-kin hallpass]);

                // Vocabulary mastery grind
                while (to_int(get_property("merkinVocabularyMastery")) < 90) {
                    if (item_amount($item[mer-kin wordquiz]) > 0) {
                        if (item_amount($item[mer-kin cheatsheet]) == 0 && pulls_remaining() > 0){
                            pullSequence($item[mer-kin cheatsheet]);
                        } else if (item_amount($item[mer-kin cheatsheet]) == 0 && pulls_remaining() == 0){
                            while (item_amount($item[mer-kin cheatsheet]) == 0)
                                getCheatsheet();
                        }
                        use($item[mer-kin wordquiz]);
                    } else {
                        tempEquipment("item drop", if_equip(divingHelmet()) + if_equip(tailpiece()) + if_equip($item[M&ouml;bius ring]) + bathysphere($item[toy cupid bow]));
                        adv($location[mer-kin elementary school]);
                    }

                    // Library runs while Steely-Eyed Squint is active
                    if (item_amount($item[mer-kin facecowl]) > 0
                        && item_amount($item[mer-kin waistrope]) > 0
                        && have_effect($effect[Steely-Eyed Squint]) > 0) {
                        buyScholarGear();
                        while ($location[mer-kin library].turns_spent < 4 && have_effect($effect[Steely-Eyed Squint]) > 0) {
                            string conditional;
                            if (to_int(get_property("_backUpUses")) < 11 && have_item($item[backup camera]))
                                conditional += "backup camera,";
                            tempEquipment("item drop", "mer-kin scholar mask,mer-kin scholar tailpiece,monodent of the sea,"
                                + if_equip($item[blood cubic zirconia]) + conditional);
                            useMapIfAvailable();
                            adv($location[mer-kin library]);
                        }
                        print ("turns played? " + turns_played(), "orange");
                    }
                }
            } else if (available_amount($item[mer-kin dreadscroll]) == 0 && available_amount($item[Mer-kin scholar tailpiece]) == 0){
                while (get_property("merkinElementaryTeacherUnlock") == "false") {
                    put_closet(item_amount($item[mer-kin hallpass]), $item[mer-kin hallpass]);
                    string conditional;
                    if (baseballPlayers() < 9 || !contains_text(get_property("baseballTeam"),"838"))
                        conditional += if_equip($item[baseball diamond]);
                    use_familiar("-combat");
                    tempEquipment("-combat", "monodent of the sea,crappy Mer-kin tailpiece,crappy Mer-kin mask," + if_equip($item[blood cubic zirconia])
                        + bathysphere($item[toy cupid bow]) + if_equip($item[M&ouml;bius ring]) + conditional);
                    mood("-combat");
                    adv($location[mer-kin elementary school]);
                    put_closet(item_amount($item[mer-kin hallpass]),
                        $item[mer-kin hallpass]);
                    if ((available_amount($item[Mer-kin facecowl]) > 0 && available_amount($item[Mer-kin waistrope]) > 0))
                        break;
                }
                take_closet(closet_amount($item[mer-kin hallpass]), $item[mer-kin hallpass]);
                pullPrayerbead();
                if (3-available_amount($item[mer-kin prayerbeads]) > pulls_remaining( )){
                    while (available_amount($item[mer-kin prayerbeads]) < 3){
                    farmPrayerbeads();
                    }
                }
                cli_execute("uneffect the sonata of sneakiness");
                while (available_amount($item[Mer-kin facecowl]) == 0 || available_amount($item[Mer-kin waistrope]) == 0){
                    if ((available_amount($item[Mer-kin facecowl]) == 1 || available_amount($item[Mer-kin waistrope]) == 1) && available_amount($item[mer-kin hallpass]) == 0 && pulls_remaining( ) > reservedPulls())
                        pullSequence($item[mer-kin hallpass]);
                    use_familiar("itdrop");
                    mood("combat");
                    mood("itdrop");
                    tempEquipment("item drop", if_equip(divingHelmet()) + if_equip(tailpiece()) + "monodent of the sea,"
                        + if_equip($item[Blood Cubic Zirconia]) + if_equip($item[M&ouml;bius ring]) + bathysphere($item[toy cupid bow]));
                    adv($location[mer-kin elementary school]);
                }
            }

            buyScholarGear();

            if (available_amount($item[mer-kin dreadscroll]) > 0){
                dreadSeedCheck();
            }

            step("phase: library (dreadscroll)");
            // Dread scroll acquisition
            while (available_amount($item[mer-kin dreadscroll]) == 0 || get_property("dreadScroll1") == "0" || get_property("dreadScroll6") == "0" || get_property("dreadScroll8") == "0") {
                merkinLib();
                if (available_amount($item[mer-kin dreadscroll]) > 0){
                    // Knucklebone for scroll 4
                    if (get_property("dreadScroll4") == "0") {
                        if (item_amount($item[mer-kin knucklebone]) == 0)
                            pullSequence($item[mer-kin knucklebone]);
                        use($item[Mer-kin knucklebone]);
                        dreadSeedCheck();
                    }
                    if (get_property("dreadScroll7") == "0" && to_int(get_property("merkinVocabularyMastery")) < 90) {
                        if (available_amount($item[mer-kin worktea]) == 0)
                            pullSequence($item[mer-kin worktea]);
                        retrieve_item($item[white rice]);
                        eatSushi();
                    }
                    dreadSeedCheck();
                }
            }

            if (available_amount($item[mer-kin prayerbeads]) < 3 && (lowShiny() || pulls_remaining() == 0)){
                while (available_amount($item[mer-kin prayerbeads]) < 3){
                    farmPrayerbeads();
                }
            }

            // Verify all non-scroll-7 clues are found
            for x from 1 to 8 {
                if (x == 7) continue;
                if (get_property("dreadScroll" + x) == "0") {
                    if (x == 2) {
                        print("Missed the healscroll hint", "red");
                        combatScrollHint();
                    } else if (x == 5) {
                        print("Missed the killscroll hint", "red");
                        combatScrollHint();
                        continue;
                    } else {
                        abort("Missed dreadscroll " + x + " hint");
                    }
                }
            }

            if (3-available_amount($item[mer-kin prayerbeads]) > pulls_remaining( )){
                while (available_amount($item[mer-kin prayerbeads]) < 3){
                  farmPrayerbeads();
                }
            }  

            cli_execute("uneffect the sonata of sneakiness");
            if (contains_text(get_property("leprecondoInstalled"), "11") && item_amount($item[Leprecondo]) > 0){
                if (highShiny())
                    leprecondo("10,24,12,8,22,13,15,4,5,6");
                else 
                    leprecondo("22,24,12,8,13,15,10,4,5,6");
            }

            step("phase: becoming High Priest");
            while (get_property("isMerkinHighPriest") == "false") {
                if (turns_played() <= 17 && get_property("uts_godRunGuard") == "true" && get_property("dreadScroll7") == "0"){
                    if (item_amount($item[mer-kin worktea]) > 0){
                        retrieve_item($item[white rice]);
                        eatSushi();
                    }else{
                        abort("On track for a god run, eat a sushi for the dreadscroll clue");
                    }
                }
                if (my_path().id == 0){
                    if (get_property("hasSushiMat") == "false"){
                        use($item[sushi-rolling mat]);
                    }
                    retrieve_item($item[mer-kin worktea]);
                    retrieve_item($item[white rice]);
                    eatSushi();
                }
                if (have_effect($effect[Deep-Tainted Mind]) == 0) {
                    use($item[mer-kin dreadscroll]);
                    post_adv();
                } else {
                    while (have_effect($effect[Deep-Tainted Mind]) > 0) {
                        if (get_property("skateParkStatus") == "war"
                            && !contains_text(
                                $location[The Skate Park].noncombat_queue,
                                "Holey Rollers")) {
                            skatePark();
                        } else if (item_amount($item[Mer-kin thighguard]) == 0
                            || item_amount($item[Mer-kin headguard]) == 0) {
                            gymnasium();
                            if (get_property("_skateBuff1") == "false")
                                visit_url("sea_skatepark.php?action=state2buff1");
                        } else if (get_property("questS02Monkees") == "step12") {
                            finishCaliginous();
                        } else {
                            abort("Hit a 1-in-40 situation — spend 1 non-free"
                                + " turn somewhere and rerun script");
                        }
                    }
                }
            }
        }

        // Skate park war cleanup
        while (get_property("skateParkStatus") == "war"
            && !contains_text($location[The Skate Park].noncombat_queue, "Holey Rollers"))
            skatePark();
        if (get_property("_skateBuff1") == "false")
            visit_url("sea_skatepark.php?action=state2buff1");

        if (available_amount($item[mer-kin prayerbeads]) < 3 && (lowShiny() || pulls_remaining() == 0)){
            while (available_amount($item[mer-kin prayerbeads]) + item_amount($item[soggy used band-aid]) + item_amount($item[New Age healing crystal]) < 3){
                farmPrayerbeads();
            }
        }

        // Healscroll pull
        if (item_amount($item[mer-kin healscroll]) == 0
            && pulls_remaining() > reservedPulls())
            pullSequence($item[mer-kin healscroll]);

        // YogUrt fight
        if (get_property("yogUrtDefeated") == "false") {
            // Gummiheart's +100 Muscle inflates max HP, and Yog-Urt's debuff
            // scales with max HP while the healing items below heal fixed
            // amounts -- so it has to go before the cocoon is cast, not after.
            // Every source is short (the PYEC grants 5 turns, a gummi
            // trick-or-treat monster 10) while the gladiator-gear grind that
            // follows this fight runs far longer, so wait it out on work the run
            // already owes rather than spend a pull slot on an antidote. Path 55
            // is the gate: a path-0 Yog-Urt run never reaches that grind, so it
            // has nowhere to burn and the abort below is all we have for it.
            if (have_effect($effect[gummiheart]) > 0 && my_path().id == 55) {
                // Free combats spend no turn yet still make progress, so only a
                // run of turnless passes means genuinely stuck.
                int stalled = 0;
                while (have_effect($effect[gummiheart]) > 0
                    && my_adventures() > 0 && stalled < 8) {
                    int before = my_adventures();
                    if (!burnTurnElsewhere()) break;
                    if (my_adventures() < before) stalled = 0;
                    else stalled = stalled + 1;
                }
            }
            cli_execute("acquire waterlogged scroll of healing, sea gel, Doc Galaktik's Pungent Unguent, Doc Galaktik's Homeopathic Elixir; cast cannel");
            if (delevelers() < 2 && !contains_text(get_property("_roninStoragePulls"), "10641") && pulls_remaining() > 0){
                pullSequence($item[null-day exploit]);
                use($item[null-day exploit]);
            } else if (delevelers() < 2){
                while (delevelers() < 2)
                    getMissingCorralItems();
            }
            if (available_amount($item[mer-kin prayerbeads]) < 3
                && !contains_text(get_property("_roninStoragePulls"), "3806"))
                pullSequence($item[mer-kin prayerbeads]);

            // Equip as many prayerbeads as available, pull healing items for gaps
            if (3-available_amount($item[mer-kin prayerbeads]) > pulls_remaining( )){
                while (available_amount($item[mer-kin prayerbeads]) + item_amount($item[soggy used band-aid]) + item_amount($item[New Age healing crystal]) < 2){
                  farmPrayerbeads();
                }
            }  
            string conditional;
            if (!highShiny())
                conditional += if_equip($item[bat wings]);

            use_familiar($familiar[none]);
            tempEquipment("moxie, hot damage, cold damage, spooky damage, sleaze damage, stench damage, -equip tiny yam cannon",
                "Mer-kin scholar mask, Mer-kin scholar tailpiece," + conditional);
            equip($slot[acc1], $item[mer-kin prayerbeads]);

            if (available_amount($item[mer-kin prayerbeads]) >= 3) {
                equip($slot[acc2], $item[mer-kin prayerbeads]);
                equip($slot[acc3], $item[mer-kin prayerbeads]);
            } else {
                if (available_amount($item[mer-kin prayerbeads]) >= 2)
                    equip($slot[acc2], $item[mer-kin prayerbeads]);
                else {
                    if (item_amount($item[New Age healing crystal]) == 0 && contains_text(get_property("_roninStoragePulls"),"8425"))
                        pullSequence($item[New Age healing crystal]);
                    else if (item_amount($item[soggy used band-aid]) == 0 && contains_text(get_property("_roninStoragePulls"),"5678"))
                        pullSequence($item[soggy used band-aid]);
                    else {
                        while (available_amount($item[mer-kin prayerbeads]) + item_amount($item[soggy used band-aid]) + item_amount($item[New Age healing crystal]) < 3){
                            farmPrayerbeads();
                        }
                        equip($slot[acc1], $item[mer-kin prayerbeads]);
                        equip($slot[acc2], $item[mer-kin prayerbeads]);
                        equip($slot[acc3], $item[mer-kin prayerbeads]);
                    }
                }
            }
            // Yog-Urt's debuff deals ~90% of max HP per round and each
            // healing item works once, so max HP must stay low enough for
            // them to out-heal it. Gummiheart's +100 muscle inflates max HP
            // past that line: strip it, pulling the antidote if needed.
            if (have_effect($effect[gummiheart]) > 0) {
                // The antidote costs a pull slot, so keep hands off the
                // reserved ones -- the Shub deleveler slot is still live
                // here, and losing it costs far more than this saves.
                if (item_amount($item[soft green echo eyedrop antidote]) == 0
                    && pulls_remaining() > reservedPulls())
                    pullSequence($item[soft green echo eyedrop antidote]);
                if (item_amount($item[soft green echo eyedrop antidote]) > 0)
                    cli_execute("uneffect gummiheart");
            }
            if (have_effect($effect[gummiheart]) > 0)
                abort("Gummiheart is inflating max HP past what the healing items can out-heal, there was nowhere left to burn its remaining turns, and the pull budget is fully reserved. Spend them anywhere, or remove it (soft green echo eyedrop antidote), then rerun.");
            adv($location[Mer-kin Temple (Right Door)]);
        }
    }

    if (get_property("yogUrtDefeated") == "false" && my_path().id == 55)
        abort("Passing over yogUrt too early — rerun script");

    if (my_path().id == 55){
        // ── Post-YogUrt skate park / gladiator gear ───────────────────────────────
        while (get_property("skateParkStatus") == "war"
            && !contains_text($location[The Skate Park].noncombat_queue,
                "Holey Rollers"))
            skatePark();
        if (get_property("_skateBuff1") == "false")
            visit_url("sea_skatepark.php?action=state2buff1");

        // Late pulls. The comfort/cleanup items wait until Shub is dead:
        // they once ate the last pull slots right before a Shub retry needed
        // the null-day exploit.
        if (pulls_remaining() > 0) {
            if (item_amount($item[crayon shavings]) < 8)
                pullSequence($item[null-day exploit]);
            if (get_property("shubJigguwattDefeated") == "true")
            foreach num in $strings[5401, 3679, 3775, 11583, 7014, 11706] {
                if (!contains_text(get_property("_roninStoragePulls"), num)) {
                    pullSequence(to_item(num));
                }
                if (pulls_remaining() == 0) break;
            }
        }
    }

    if (my_path().id == 55 && get_property("spookyVHSTapeMonster") == ""){
        while (get_property("questS02Monkees") == "step12")
            finishCaliginous();
    }

    if (my_path().id == 55 || (my_path().id == 0 && boss == "Shub")){
        // ── Gladiator gear grind ──────────────────────────────────────────────────
        step("phase: gymnasium (gladiator gear)");
        // || not &&: the colosseum outfit needs BOTH pieces, so keep looping
        // while either is missing.
        while (available_amount($item[Mer-kin gladiator mask]) == 0
            || available_amount($item[Mer-kin gladiator tailpiece]) == 0) {
            gladiatorGearStep();
        }

        refresh_status();

        // ── Colosseum ─────────────────────────────────────────────────────────────
        step("phase: colosseum");
        while (to_int(get_property("lastColosseumRoundWon")) < 15) {
            colosseumRound();
        }

        if (to_int(get_property("lastColosseumRoundWon")) < 15)
            abort("Skipped over colosseum — rerun script");

        if (my_path().id == 55){
            while (get_property("questS02Monkees") == "step12")
                finishCaliginous();
        }

        // ── Shub-Jigguwatt ────────────────────────────────────────────────────────
        step("phase: Shub-Jigguwatt");
        if (get_property("shubJigguwattDefeated") == "false") {
            if (my_path().id == 0)
                retrieve_item(8,$item[crayon shavings]);
            if (shubPrepShort()){
                // shubPrepShort() mirrors shubDelevel()'s multiplicative
                // math (bootleg 0.5, shavings 0.7, rattle/kit 0.75, floor
                // 0.25), so the ladder and the null-day reservation agree
                // on what "prepped" means. (The insurance below keys on
                // account tier and stat margin instead -- the fight is
                // always prepped by this point; what varies is whether the
                // account clears a floored Shub's defense.) A refused paw
                // wish ("That wish is quite impossible") consumes nothing,
                // so testing wishes is free. Ladder: pull the exploit in
                // place, then free golem fights (they drop shavings), then
                // an abort naming every exit. Path 0 lands here too when
                // the retrieve above comes back short -- same ladder, same
                // exits.
                if (item_amount($item[null-day exploit]) == 0)
                    pullSequence($item[null-day exploit]);
                if (item_amount($item[null-day exploit]) > 0)
                    use($item[null-day exploit]);
                int golemTries;
                while (shubPrepShort()
                    && count_summons() >= 1 && golemTries < 6) {
                    golemTries += 1;
                    use_familiar("itdrop");
                    tempEquipment("item drop", if_equip($item[blood cubic zirconia]) + if_equip($item[toy cupid bow]));
                    mood("itdrop");
                    summon($monster[black crayon golem]);
                    run_combat();
                }
                if (shubPrepShort())
                    abort("Shub prep is short: need delevelers that floor his"
                        + " attack (two jam band bootlegs, four crayon"
                        + " shavings, or a mix -- bootlegs count double,"
                        + " rattler rattle / electronics kit slightly less"
                        + " than a shaving) or Null Afternoon. Paw wishes,"
                        + " golem fights and rollover pulls all work;"
                        + " acquire and rerun.");
            }
            foreach ef in $effects[scarysauce]{
                if (have_effect(ef) > 0)
                    cli_execute("uneffect " + ef);
            }
            // NO familiar against Shub: he retaliates against familiar
            // actions, escalating each time, and "itdrop" can resolve to a
            // familiar that acts.
            use_familiar($familiar[none]);
            // Fight rules: damage from any source other than a standard
            // attack draws 20% of max HP, DOUBLING each instance (hence no
            // familiar); damage past 500 is crushed to 500+(Z-500)^0.6, so
            // reliability beats big swings; maxed Damage Absorption still
            // helps; and the pre-fight bolt hits for half your CURRENT MP,
            // so walk in empty.
            tempEquipment("weapon damage, mus, moxie, damage absorption",
                "mer-kin gladiator mask,mer-kin gladiator tailpiece," + if_equip($item[legendary seal-clubbing club]));
            set_property("hpAutoRecoveryTarget", "1");
            set_property("mpAutoRecovery", "-0.05");
            set_property("mpAutoRecoveryTarget", "-0.05");
            // Miss/fumble insurance, both one-fight pulls. The ladder above
            // floors Shub or aborts, but a floored Shub still keeps ~1000
            // defense (0.25 of 4000): accounts that clear that by a wide
            // margin waste two pulls here, accounts that don't genuinely
            // need them. Insure the low-shelf tier (lowShiny) and anyone
            // whose post-maximize muscle is short of the floor plus margin;
            // everyone else skips both pulls. The maximize above has already
            // run, so buffed muscle here is what the fight will see.
            if (lowShiny() || my_buffedstat($stat[muscle]) < 1250) {
                if (item_amount($item[gremlin juice]) == 0)
                    pullSequence($item[gremlin juice]);
                if (item_amount($item[handful of hand chalk]) == 0)
                    pullSequence($item[handful of hand chalk]);
            }
            if (item_amount($item[gremlin juice]) > 0)
                use($item[gremlin juice]);
            if (item_amount($item[handful of hand chalk]) > 0)
                use($item[handful of hand chalk]);
            cli_execute("recover hp");
            // Ruthless Efficiency sharpens the shavings delevel. Cast before
            // the MP dump while there is still a pool to pay for it; a
            // redundant recast just feeds the dump.
            if (have_skill($skill[Ruthless Efficiency]))
                use_skill($skill[Ruthless Efficiency]);
            // The MP dump. Empathy is a cheap repeatable sink -- its buff is
            // irrelevant with no familiar, but emptying the pool blunts the
            // pre-fight bolt to nothing.
            cli_execute("cast * empathy");
            adv($location[Mer-kin Temple (Left Door)]);
        }
    }

    if (my_path().id == 55){
        // ── Naughty Sorceress intro ───────────────────────────────────────────────
        step("phase: Naughty Sorceress");
        if (get_property("questL13Final") == "unstarted") {
            if (to_int(get_property("_batWingsFreeFights")) < 5 && !highShiny()) {
                tempEquipment("spell damage percent, mys", "Mer-kin gladiator mask,Mer-kin gladiator tailpiece," + if_equip($item[bat wings])
                    + if_equip($item[Congressional Medal of Insanity]));
            } else {
                tempEquipment("spell damage percent, mys", "Mer-kin gladiator mask,Mer-kin gladiator tailpiece,"
                    + if_equip($item[Congressional Medal of Insanity]));
                if (have_item($item[Unwrapped knock-off retro superhero cape])){
                    cli_execute("retrocape heck kill; equip unwrapped knock-off retro superhero cape");
                }
            }
            adv($location[Mer-kin Temple (center Door)]);
            adv($location[Mer-kin Temple (center Door)]);
        }
    } else if (my_path().id == 0 && boss == "Dad"){
        use_familiar($familiar[Tiny Plastic Santa Claus Skeleton]);
        tempEquipment("spell damage percent", "goggles of loathing,stick-knife of loathing,scepter of loathing,jeans of loathing,treads of loathing,belt of loathing,little bitty bathy");
        set_property("mpAutoRecoveryTarget", "1");
        cli_execute("acquire 3 warbear whosit; acquire 3 volcanic ash; recover mp; tempura air");
        adv($location[Mer-kin Temple (center Door)]);
    }

    if (my_path().id == 55){
        // ── Post-quest cleanup and spending ──────────────────────────────────────
        if (get_property("questL13Final") == "finished") {
            while (item_amount($item[sand penny]) > 30)
                buy($coinmaster[Wet Crap For Sale], 1, $item[water-logged pill]);
            while (item_amount($item[sand penny]) > 10)
                buy($coinmaster[Wet Crap For Sale], 1,
                    $item[waterlogged scroll of healing]);
            council();
            council();
            pearlPostloop();
            prepCodpiece();
            if (get_property("uts_postloopCommand") != "")
                cli_execute(get_property("uts_postloopCommand"));
        }
    }
}

// ─── MAIN ─────────────────────────────────────────────────────────────────────

// Vararg rather than a plain string: mafia prompts for any missing typed
// parameter, but collects a vararg silently, so a bare "UnderTheSea" runs
// without a dialog.
void main(string... args) {
    string command = count(args) > 0 ? to_lower_case(args[0]) : "";
    if (command == "sim") {
        // Report-only mode: the same ownership checklists the run prints at
        // startup and nothing else -- no pulls, no turns, no combat.
        iotmChecklist();
        pullChecklist();
        return;
    }
    if (command == "postloop") {
        // Postloop-only mode: the finishing steps the run would have reached
        // on its own, without initialization() or any of the run itself. A
        // bare "UnderTheSea" on a finished account starts an aftercore Sea
        // run, which is not what you want when exercising these prefs.
        // Each step still self-gates on its own uts_postLoop* pref, so with
        // none of them set this does nothing but set up and tear down.
        try {
            set_property("choiceAdventureScript", "UnderTheSea_Choice.ash");
            // Same defensive clear initialization() does: a run killed
            // mid-walk can leave this set, which reduces the CCS to cleanUp().
            set_property("_utsPearlFarm", "false");
            // The pearl walk fights through the CCS, and pearlPostloop()
            // hands it _utsPearlFarm to reduce it to plain kills.
            write_ccs(to_buffer("consult UnderTheSeaCCS.ash \n abort"), "temp");
            set_ccs("temp");
            set_property("battleAction", "custom combat script");
            print("Starting UnderTheSea (postloop only)");
            pearlPostloop();
            prepCodpiece();
            if (get_property("uts_postloopCommand") != "")
                cli_execute(get_property("uts_postloopCommand"));
        } finally {
            set_property("choiceAdventureScript", choiceStorage);
            set_ccs(CCSStorage);
            print("Ending UnderTheSea");
        }
        return;
    }
    if (command != "")
        abort("Unknown command \"" + command + "\" -- plain \"UnderTheSea\" runs the loop, \"UnderTheSea sim\" prints the IOTM and pull checklists, \"UnderTheSea postloop\" runs only the postloop steps.");
    try {
        set_property("choiceAdventureScript", "UnderTheSea_Choice.ash");
        // c2t_megg clears choiceAdventureScript for the span of its egg
        // fights, so the Force's follow-up choice must also be answerable
        // from the property alone.
        set_property("choiceAdventure1387", "3");
        print("Starting UnderTheSea");
        initialization();
        seaMonkees();
        sorceress();
    } finally {
        set_property("choiceAdventureScript", choiceStorage);
        set_property("choiceAdventure1387", choice1387Storage);
        set_ccs(CCSStorage);
        print("Ending UnderTheSea");
    }
}
