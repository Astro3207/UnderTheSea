import iotm.ash;
import <seedfinder/seedfinder.ash>;

// ─── PER-ACCOUNT CONFIG ───────────────────────────────────────────────────────
// These replace what used to be hardcoded checks against the original author's
// character id. Set them once with the mafia CLI; both default to off.
//
//   set uts_godRunGuard = true
//       Abort at <=17 turns played if the dreadscroll 7 clue is still unknown,
//       so you can eat a sushi for it instead of burning the record attempt.
//       Only worth enabling if you are actually chasing a top turncount.
//
//   set uts_postloopCommand = postloop
//       CLI command to run once the loop finishes. Leave empty to skip.
//
// ─── GLOBALS ──────────────────────────────────────────────────────────────────
    familiar chosenFamiliar = $familiar[none]; //For kidoblivious
    string choiceStorage = get_property("choiceAdventureScript");
    string CCSStorage = get_property("customCombatScript");
    string seaFit,boss,modes;
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
    boolean lowShiny;

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

    string if_equip(item it) {
        if ($items[baseball diamond, peridot of peril, heartstone, blood cubic zirconia] contains it)
            codpiece("none");
        if (it == $item[none] || available_amount(it) == 0)
            return "";
        else
            return to_string(it) + ",";
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
    // whatever asks first.
    //
    // Only one of each unique item may be pulled per day, so every entry here
    // reserves at most ONE slot no matter how many the route still needs. The
    // old version reserved 3 - prayerbeads owned, which looked prudent but could
    // not be spent: a second prayerbead is simply not pullable the same day, so
    // those extra slots were held back and then wasted.
    //
    // The five protected items are the ones that cost real turns to farm once
    // the zones the route already camps in have been accounted for:
    //
    //   Mer-kin pinkslip    ~15 turns  the Dive Bar is not otherwise visited
    //   Mer-kin prayerbeads ~15 turns  Outpost yields ~1.7 of 3 during the lockkey block
    //   sea cowbell         ~10 turns  the Coral Corral block length IS this hunt
    //   ink bladder          ~4 turns  Marinara Trench, 1 in 4 at 30%
    //   comb jelly           ~4 turns  Marinara Trench, 1 in 4 at 40%
    //
    // Everything else the script pulls is either unfarmable -- in which case a
    // reservation cannot help, it simply has to be bought -- or comes free from a
    // block the route runs anyway, in which case it is worth about nothing.
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
                        if (ef == $effect[Apriling Band Patrol Beat] && total_turns_played() < to_int(get_property("nextAprilBandTurn"))) continue;
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
                            && get_property("yogUrtDefeated") == "false") continue;
                        if (ef == $effect[Bloodbathed]
                            && lowShiny == true) continue;
                        if (ef == $effect[Apriling Band Battle Cadence] && total_turns_played() < to_int(get_property("nextAprilBandTurn"))) continue;
                        if (to_skill(ef) != $skill[none] && !have_skill(to_skill(ef))) continue;
                        cli_execute(ef.default);
                    }
                }
                print("Combat rate is " + numeric_modifier("Combat Rate"));
                break;
            case "hotres":
            case "spookyres":
                foreach ef in $effects[Astral Shell, Minor Invulnerability,
                    Elemental Saucesphere] {
                    if (ef == $effect[Minor Invulnerability]
                        && item_amount($item[scroll of minor invulnerability]) == 0) continue;
                    if (to_skill(ef) != $skill[none] && !have_skill(to_skill(ef))) continue;
                    if (have_effect(ef) == 0) cli_execute(ef.default);
                }
                break;
            case "sleazeres":
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
                    if (ef == $effect[Everybody Calls Him Gorgon] && !lowShiny) continue;
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
            n += count(lockets);
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

    void post_adv() {
        if (get_property("_lastCombatLost") == "true"){
            if (have_effect($effect[beaten up]) > 0){
                if (have_skill($skill[Tongue of the Walrus]))
                    use_skill($skill[Tongue of the Walrus]);
                else
                    cli_execute("campground rest");
            }
            set_property("_lastCombatLost", "false");
            abort("It appears you lost the last combat, look into that");
        }
        modes = "";
        if ((get_property("dolphinItem") == "Mer-kin prayerbeads" || get_property("dolphinItem") == "rusty rivet") && have_item($item[durable dolphin whistle]) && lowShiny)
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
                    use_skill($skill[the ode to booze]);
                    drink($item[astral pilsner]);
                } else if (item_amount($item[astral pilsner]) > 0) {
                    cli_execute("shrug Donho's Bubbly Ballad");            
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
                if (have_item($item[fishy pipe]) && item_amount($item[closed-circuit pay phone]) > 0 && have_item($item[Monodent of the Sea]) && have_item($item[Platinum Yendorian Express Card]) && get_property("_fishyPipeUsed") == "false" && lowShiny == false){
                        if (item_amount($item[fishy pipe]) == 0)
                            cli_execute("pull fishy pipe");
                        use($item[fishy pipe]);
                } else if (highShiny() || lowShiny && !contains_text(get_property("_roninStoragePulls"), "9466")){
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
        if (to_int(get_property("_universeCalculated"))
            < min(3, to_int(get_property("skillLevel144")))
            && uniAdv <= my_adventures()) {
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
            tempEquipment(pearlRes[my_primestat()],if_equip(divingHelmet()) + if_equip($item[legendary seal-clubbing club]) + "shark jumper,scale-mail underwear," + bathysphere($item[none]));
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
            tempEquipment("item drop",if_equip(divingHelmet()) + "shark jumper,scale-mail underwear,black glass,"+ if_equip($item[peridot of peril]) 
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
        write_ccs(to_buffer("consult UnderTheSeaCCS.ash \n abort"), "temp");
        set_ccs("temp");
        set_property("battleAction", "custom combat script");
        if ((!have_item($item[2002 Mr. Store Catalog]) && !have_item($item[cursed monkey's paw]) && !have_item($item[august scepter])))
            lowShiny = true;
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

            // Slot duplicate.edu now so the skill is in hand by the time we
            // reach Fitzsimmons, and claim the day's embers.
            sourceEducate();
            cargoPocket();
            garbageTote();
            censer();

            // The one free pill of the day. Fidoxene lasts 30 turns, which is
            // most of a run, and every farming familiar the script reaches for
            // is weight-scaled, so it is the default. If we are actually short
            // of noncombat forces, leave the pill unspent so NCforce() can take
            // Sneakisol instead when it needs it.
            if (NCForceEstimate() >= 4)
                pillKeeper("fidoxene");

            // One free saber upgrade per day. Choice 1386 is answered in
            // UnderTheSea_Choice.ash; we take the familiar weight option, since
            // the elemental resistance one only matters for farming unblemished
            // pearls and those are smuggled in via the codpiece.
            if (have_item($item[Fourth of May Cosplay Saber])
                && get_property("_saberMod") == "0")
                visit_url("main.php?action=may4");

            // Autosell junk gems
            foreach it in $items[hamethyst, baconstone, porquoise, kokomo resort pass] {
                if (it == $item[porquoise] && have_item($item[portable pantogram]))
                    continue;
                autosell(item_amount(it), it);
            }

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
                if (have_familiar($familiar[chest mimic])){
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

            // Storage pulls for sea gear
            foreach it in $items[mer-kin sneakmask, sea lasso, shark jumper,
                scale-mail underwear, Congressional Medal of Insanity,
                Flash Liquidizer Ultra Dousing Accessory] {
                if (available_amount(it) == 0 && !contains_text(get_property("_roninStoragePulls"), to_int(it))) {
                    if (it == $item[sea lasso] && (lowShiny == true || (have_familiar($familiar[Sword of S Words]) && count_summons() >= 3)))
                        continue;
                    if (storage_amount(it) == 0){
                        if (it == $item[Congressional Medal of Insanity])
                            abort("Get yer own CMOI, ya filthy animal!");
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
        if (have_effect($effect[beaten up]) > 0 && have_skill($skill[Tongue of the Walrus]))
            use_skill($skill[Tongue of the Walrus]);
        else if (have_effect($effect[beaten up]) > 0)
            cli_execute("rest");
        post_adv();
    }

    void gymnasium(){
        use_familiar("combat");
        string conditional;
            if (!contains_text($location[The Skate Park].noncombat_queue, "Holey Rollers")){
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
        if (pulls_remaining( ) > reservedPulls())
            pullSequence($item[skate blade]);
        if (get_property("noncombatForcerActive") == "true"){
            equipSwimTrunks();
            cli_execute("unequip peridot");
            if (item_amount($item[skate blade]) > 0)
                equip($item[skate blade]);
        } else {
            use_familiar("-combat");
            tempEquipment("-combat","really nice swimming trunks," + bathysphere($item[toy cupid bow]) + if_equip($item[skate blade]));
            mood("-combat");
        }
        adv($location[The Skate Park]);
    }

    void recallCaliginous(){
        if (available_amount($item[black glass]) == 0) 
            buy($coinmaster[Big Brother], 1, $item[black glass]);
        use_familiar("-combat");
        tempEquipment("item drop", if_equip(divingHelmet()) + "shark jumper,scale-mail underwear,black glass,peridot of peril,monodent of the sea,"
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
        tempEquipment("mys","shark jumper,scale-mail underwear,black glass,congressional medal of insanity,"
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
        if (lowShiny == true)
            conditional += "congressional medal of insanity,";
        if (to_int(get_property("_backUpUses")) < 11 && have_item($item[backup camera]) && !highShiny())
            conditional += "backup camera,";
        if (item_amount($item[mer-kin killscroll]) == 0 || item_amount($item[mer-kin healscroll]) == 0 || item_amount($item[mer-kin worktea]) == 0 || item_amount($item[mer-kin knucklebone]) == 0)
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
        if (!contains_text(get_property("banishedMonsters"),"Mer-kin rustler")
            || (doneWithCowboy() && !contains_text(get_property("banishedMonsters"),"sea cowboy"))
            || (doneWithSeaCow() && !contains_text(get_property("banishedMonsters"),"sea cow:")))
            conditional += if_equip(banishGear($location[The Coral Corral]));
        if (lowShiny)
            conditional += "congressional medal of insanity,";
        conditional += saberEquip($location[The Coral Corral]);
        conditional += cloakeEquip($location[The Coral Corral]);
        tempEquipment("item drop", "really nice swimming trunks," + if_equip($item[legendary seal-clubbing club]) + bathysphere($item[toy cupid bow]) + conditional);
        if (!doneWithSeaCow())
            set_property("choiceAdventure1589","1&victim=775");
        else if (!doneWithCowboy())
            set_property("choiceAdventure1589","1&victim=776");
        else

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
            tempEquipment("spooky res", swimmingTrunks() + "the eternity codpiece,monodent of the sea" + bathysphere($item[none]));
            adv1($location[Anemone Mine]);
        } else if (!contains_text(get_property("_perilLocations"), "195")){
            mood("hotres");
            use_familiar("itdrop");
            cli_execute("unequip peridot of peril");
            codpiece("blood cubic zirconia, peridot of peril");
            tempEquipment("hot res", swimmingTrunks() + "the eternity codpiece,monodent of the sea" + bathysphere($item[none]));
            adv1($location[the marinara trench]);
        } else if (!contains_text(get_property("_perilLocations"), "197")){
            mood("sleazeres");
            use_familiar("itdrop");
            codpiece("blood cubic zirconia, peridot of peril");
            tempEquipment("sleaze res", swimmingTrunks() + "the eternity codpiece,monodent of the sea" + bathysphere($item[none]));
            adv1($location[the dive bar]); 
        } else if (!contains_text(get_property("_perilLocations"), "196")){
            mood("spookyres");
            use_familiar("itdrop");
            cli_execute("unequip peridot of peril");
            codpiece("blood cubic zirconia, peridot of peril");
            tempEquipment("spooky res", swimmingTrunks() + "the eternity codpiece,monodent of the sea" + bathysphere($item[none]));
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

    void farmPrayerbeads(){
        use_familiar("-combat");
        string conditional;
        if (lowShiny == true)
            conditional += "congressional medal of insanity,";
        tempEquipment("-combat","really nice swimming trunks," + bathysphere($item[none]) + conditional);
        
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
        adv($location[mer-kin elementary school]);
        put_closet(item_amount($item[mer-kin hallpass]),
            $item[mer-kin hallpass]);
    }

    void combatScrollHint(){
        if (get_property("dreadScroll5") == "0"){
            while (item_amount($item[mer-kin killscroll]) == 0){
                if (item_amount($item[mer-kin thingpouch]) > 0)
                    use(item_amount($item[mer-kin thingpouch]), $item[mer-kin thingpouch]);
                else if (lowShiny == false && pulls_remaining() > reservedPulls())
                    pullSequence($item[mer-kin killscroll]);
                else
                    farmPrayerbeads();
            }
        }
        if (get_property("dreadScroll2") == "0"){
            while (item_amount($item[mer-kin healscroll]) == 0){
                if (lowShiny == false && pulls_remaining() > reservedPulls())
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
    if (get_property("questG03Ego") == "unstarted" && item_amount($item[Closed-circuit pay phone]) > 0 && my_path().id == 55 && !highShiny()) {
        unlockGuild();
        if (get_property("questG03Ego") == "unstarted") {
            visit_url("guild.php?place=ocg");
            visit_url("guild.php?place=ocg");
        }
    }
    post_adv();
    // ── Step: Flytrap pellet ──────────────────────────────────────────────────
    if (get_property("questS02Monkees") == "unstarted") {
        // Get citizen/RWB ray on neptune flytrap
        while (item_amount($item[wriggling flytrap pellet]) == 0 && have_effect($effect[Citizen of a Zone]) == 0
            && have_effect($effect[Everything Looks Red, White and Blue]) == 0 && have_familiar($familiar[patriotic eagle])) {
            use_familiar($familiar[patriotic eagle]);
            string conditional;
            if (lowShiny)
                conditional += "congressional medal of insanity,";
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
    while (get_property("questS02Monkees") == "step1") {
        if (NCForceEstimate() >= 4){
            if (get_property("noncombatForcerActive") != "true")
                NCforce();
            tempEquipment("item drop, -equip peridot of peril", swimmingTrunks() + bathysphere($item[none]) + if_equip($item[M&ouml;bius ring]));
        } else {
            use_familiar("-combat");
            tempEquipment("item drop, -equip peridot of peril", "monodent of the sea," + swimmingTrunks() + if_equip($item[M&ouml;bius ring]) + bathysphere($item[toy cupid bow]));
        }
        adv($location[The Wreck of the Edgar Fitzsimmons]);
    }

    if (get_property("questS02Monkees") == "step2") {
        visit_url("monkeycastle.php?who=2");
        visit_url("monkeycastle.php?who=1");
    }

    // ── Step 4: Unlocking Grandpa ──────────────────────────────────
    if (get_property("questS02Monkees") == "step4") {
        use_familiar("-combat");
        if (have_effect($effect[Colorfully Concealed]) == 0 && lowShiny == false) {
            // The Outpost burglar drops this anyway, so yield the slot if a
            // reserved item still needs it. (The old stray semicolon meant the
            // use() below ran whether or not the pull actually happened.)
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
                    || (my_primestat() == $stat[moxie] && !contains_text(get_property("trackedMonsters"), "Mer-kin tippler"))
                    && have_item($item[McHugeLarge left pole])) {
                conditional += "McHugeLarge left pole,";
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
    while ((item_amount($item[Mer-kin stashbox]) == 0  && get_property("corralUnlocked") == "false") || contains_text("step6,step7,step8",get_property("questS02Monkees"))) {
        if ($location[The Mer-Kin Outpost].turns_spent < 5)
            set_property("stashboxChecked", "0");
        if (get_property("stashboxChecked") == "1,2,3")
            abort("All stashbox locations checked but no stashbox — something went wrong");

        // Familiar choice
        if (get_property("_monsterHabitatsFightsLeft") == "1" && to_int(get_property("_monsterHabitatsRecalled")) == 2 && have_familiar($familiar[patriotic eagle]))
            use_familiar($familiar[patriotic eagle]);
        else if (doSWord() == true && $location[The Mer-Kin Outpost].turns_spent < 26 && (get_property("_monsterHabitatsFightsLeft") == "0" || available_amount($item[crayon shavings]) > 9)){
            use_familiar($familiar[Sword of S Words]);
            mood("itdrop");
        } else if (((highShiny() || !have_item($item[closed-circuit pay phone]) || lowShiny) && item_amount($item[pristine fish scale]) < 6) || have_familiar($familiar[red-nosed snapper]))
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
                conditional += "congressional medal of insanity,";

            if ((get_property("_monsterHabitatsMonster") == "eye in the darkness" || get_property("_monsterHabitatsMonster") == "slithering thing") && get_property("_monsterHabitatsFightsLeft") > 0)
                conditional += "shark jumper,scale-mail underwear,elf guard scuba,";
            else 
                conditional += swimmingTrunks();
        if ((highShiny() || !have_item($item[closed-circuit pay phone]) || lowShiny) && item_amount($item[pristine fish scale]) < 6)
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

    //Get 2 prayerbeads if tight on pulls
    while (NCForceEstimate() < 4 && available_amount($item[mer-kin prayerbeads]) < 2){
        use_familiar("-combat");
        tempEquipment("-combat", swimmingTrunks() + bathysphere($item[toy cupid bow]));
        mood("-combat");
        adv($location[The Mer-Kin Outpost]);
    }

    if (get_property("questS01OldGuy") == "started") {
        oldGuy();
    }
    // ── Diving helmet acquisition for mid to high shiny ───────────────────────────────
    if (item_amount($item[rusty rivet]) < 8 && to_slot(divingHelmet()) != $slot[hat]) {
        if (have_item($item[Cursed monkey's paw]) && count_summons() >= 1 && !highShiny()){
            mood("itdrop");
            if (have_effect($effect[shadow waters]) == 0)
                shadowRift();
            // Get rusty porthole first via unholy diver
            if (item_amount($item[rusty porthole]) == 0) {
                if (baseballPlayers() >= 8){
                    if (!use_familiar($familiar[jill-of-all-trades]))
                        use_familiar("itdrop");
                } else {
                    if (!use_familiar($familiar[chest mimic]))
                        use_familiar("itdrop");
                }
                tempEquipment("item drop", if_equip($item[blood cubic zirconia]) + if_equip($item[toy cupid bow]) + if_equip($item[baseball diamond]));
                print("Item drop rate is " + numeric_modifier("item drop"));
                mood("superitdrop");
                if (have_effect($effect[everything looks yellow]) == 0){
                    if (have_item($item[jurassic parka]))
                        cli_execute("parka dilophosaur; equip jurassic parka");
                    else if (have_item($item[April Shower Thoughts shield]))
                        create($item[spitball]);
                }
                summon($monster[unholy diver]);
            }

            if (baseballPlayers() >= 9)
                baseballD();
            if (item_amount($item[rusty rivet]) < 4){
                if (!use_familiar($familiar[chest mimic]))
                    use_familiar("itdrop");
            } else {
                if (!use_familiar($familiar[jill-of-all-trades]))
                    use_familiar("itdrop");
            }
            tempEquipment("item drop", if_equip($item[blood cubic zirconia]) + if_equip($item[toy cupid bow]));
            if (have_effect($effect[everything looks yellow]) == 0){
                if (have_item($item[jurassic parka]))
                    cli_execute("parka dilophosaur; equip jurassic parka");
                else if (have_item($item[April Shower Thoughts shield]))
                    create($item[spitball]);
            }

            if (item_amount($item[rusty rivet]) < 7) {
                summon($monster[unholy diver]);
                run_combat();
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
                        conditional += "shark jumper,scale-mail underwear,elf guard scuba tank,";
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
                    tempEquipment("item drop","monodent of the sea,congressional medal of insanity," + if_equip($item[peridot of peril]) + conditional + bathysphere($item[toy cupid bow]));
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
                tempEquipment("item drop", "shark jumper,scale-mail underwear,black glass," + conditional + bathysphere($item[toy cupid bow]));
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
                tempEquipment("moxie", "shark jumper,scale-mail underwear,monodent of the sea");
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
        if (have_effect($effect[shadow waters]) == 0 && lowShiny == false)
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
            tempEquipment("item drop", "shark jumper,scale-mail underwear," + if_equip(divingHelmet())
                + "pro skateboard,The Eternity Codpiece,backup camera");
            mood("itdrop");
            adv($location[The Coral Corral]);
        } else if (have_skill($skill[steely-eyed squint]) && have_item($item[cursed monkey's paw])){
            pullSequence($item[software glitch]);
            tempEquipment("item drop", if_equip(divingHelmet()) + "pro skateboard,The Eternity Codpiece");
            mood("itdrop");
            adv($location[The Coral Corral]);
        } else {
            pullSequence($item[pulled yellow taffy]);
            pullSequence($item[software glitch]);
            if (!have_item($item[spring shoes]) && !have_item($item[heartstone]) && available_amount($item[stuffed yam stinkbomb]) == 0 && available_amount($item[handful of split pea soup]) == 0 && !lowShiny)
                pullSequence($item[stuffed yam stinkbomb]);
            tempEquipment("item drop", if_equip(divingHelmet()) + "pro skateboard,The Eternity Codpiece,monodent of the sea," + baseball_equip());
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
// ─── SORCERESS ────────────────────────────────────────────────────────────────

void sorceress() {

    // ── Shadow rift prep ─────────────────────────────────────────────────────
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
    if (item_amount($item[teflon ore]) == 0 && tailpiece() == $item[none]) {
        if (available_amount($item[mer-kin digpick]) == 0 && lowShiny == false
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
        while (to_int(get_property("lassoTrainingCount")) < 20 && !highShiny() && (have_effect($effect[shadow affinity]) > 0 || get_property("_shadowAffinityToday") == "false") && have_item($item[closed-circuit pay phone]))
            shadowRift();

        if ((my_turncount( ) > 25 || !have_item($item[Miniature crystal ball])) && !highShiny() && have_item($item[closed-circuit pay phone])){
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
        } else if (have_item($item[Miniature crystal ball])){
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
            && have_effect($effect[shadow affinity]) > 0 && available_amount($item[miniature crystal ball]) > 0)
            shadowRift();
        while (have_effect($effect[shadow affinity]) > 0 && item_amount($item[shadow brick]) == 0
            && !contains_text(get_property("crystalBallPredictions"), "The Coral Corral:Wild seahorse") && available_amount($item[miniature crystal ball]) > 0)
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
            if (available_amount($item[pristine fish scale]) < 3){
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
            if (available_amount($item[pristine fish scale]) < 3){
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
            use_skill($skill[deep dark visions]);
        }
    }

    // ── YogUrt preparation ────────────────────────────────────────────────────
    if ((get_property("yogUrtDefeated") == "false" && my_path().id == 55) || (my_path().id == 0 && boss == "Yogurt")) {
        if (get_property("isMerkinHighPriest") == "false") {
            if (isKBandSushiEnough() == false || my_path().id == 0){
                // Farm mer-kin cheatsheets and unlock teacher
                if (my_path().id == 0){
                    cli_execute("acquire 10 mer-kin cheatsheet, 10 mer-kin wordquiz, mer-kin killscroll, mer-kin healscroll, mer-kin knucklebone");
                }
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

            if (available_amount($item[mer-kin prayerbeads]) < 3 && (lowShiny || pulls_remaining() == 0)){
                while (available_amount($item[mer-kin prayerbeads]) < 3){
                    farmPrayerbeads();
                }
            }

            // Verify all non-scroll-7 clues are found
            for x from 1 to 8 {
                if (x == 7) continue;
                // Fixed: was comparing string to int, and had capital X bug on x==5
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

        if (available_amount($item[mer-kin prayerbeads]) < 3 && (lowShiny || pulls_remaining() == 0)){
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

            use_familiar("itdrop");
            tempEquipment("moxie, hot damage, cold damage, spooky damage, sleaze damage, stench damage, -equip tiny yam cannon",
                "Mer-kin scholar mask, Mer-kin scholar tailpiece," + bathysphere($item[toy cupid bow]) + conditional);
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
            if (have_effect($effect[gummiheart]) > 0)
                abort("Have gummiheart effect — drop HP somehow before fighting");
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

        // Late pulls
        if (pulls_remaining() > 0) {
            if (item_amount($item[crayon shavings]) < 8)
                pullSequence($item[null-day exploit]);
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
        while (available_amount($item[Mer-kin gladiator mask]) == 0
            && available_amount($item[Mer-kin gladiator tailpiece]) == 0) {
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
                    buy($coinmaster[Grandma Sea Monkey],1,it);
                }
            }
        }

        refresh_status();

        // ── Colosseum ─────────────────────────────────────────────────────────────
        while (to_int(get_property("lastColosseumRoundWon")) < 15) {
            string freeFight;
            if (to_int(get_property("_clubEmTimeUsed")) < 5 && !highShiny() && !lowShiny && have_item($item[legendary seal-clubbing club]))
                freeFight = "legendary seal-clubbing club,";
            else if (to_int(get_property("_batWingsFreeFights")) < 5 && have_item($item[bat wings]) && !highShiny())
                freeFight = if_equip($item[bat wings]);
            else if (have_item($item[Unwrapped knock-off retro superhero cape])){
                freeFight = "unwrapped knock-off retro superhero cape,";
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
                if (have_familiar($familiar[foul ball])) {
                    use_familiar($familiar[foul ball]);
                }
                mood("colosseum");
            }
            float coeff = (60 + my_buffedstat($stat[mysticality])/2.5)/(numeric_modifier("spell damage percent") + 1);
            tempEquipment(coeff + " spell damage percent, mys", "Mer-kin gladiator tailpiece,Mer-kin gladiator mask,"
                + "congressional medal of insanity," + freeFight + bathysphere($item[none]));
            adv($location[Mer-kin Colosseum]);
            if (get_property("lastEncounter") == "Been There, Won That"){
                set_property("lastColosseumRoundWon","15");
                set_property("isMerkinGladiatorChampion","true");
            }
        }

        if (to_int(get_property("lastColosseumRoundWon")) < 15)
            abort("Skipped over colosseum — rerun script");

        if (my_path().id == 55){
            while (get_property("questS02Monkees") == "step12")
                finishCaliginous();
        }

        // ── Shub-Jigguwatt ────────────────────────────────────────────────────────
        if (get_property("shubJigguwattDefeated") == "false") {
            if (my_path().id == 0)
                retrieve_item(8,$item[crayon shavings]);
            else if (item_amount($item[crayon shavings]) < 8 && have_effect($effect[null afternoon]) == 0){
                if (item_amount($item[null-day exploit]) > 0)
                    use($item[null-day exploit]);
            }
            foreach ef in $effects[scarysauce]{
                if (have_effect(ef) > 0)
                    cli_execute("uneffect" + ef);
            }
            use_familiar("itdrop");
            tempEquipment("damage absorption, mus", "mer-kin gladiator mask,mer-kin gladiator tailpiece,");
            set_property("hpAutoRecoveryTarget", "1");
            set_property("mpAutoRecovery", "-0.05");
            set_property("mpAutoRecoveryTarget", "-0.05");
            cli_execute("recover hp; cast * empathy");
            adv($location[Mer-kin Temple (Left Door)]);
        }
    }

    if (my_path().id == 55){
        // ── Naughty Sorceress intro ───────────────────────────────────────────────
        if (get_property("questL13Final") == "unstarted") {
            if (to_int(get_property("_batWingsFreeFights")) < 5 && !highShiny()) {
                tempEquipment("spell damage percent, mys", "Mer-kin gladiator mask,Mer-kin gladiator tailpiece," + if_equip($item[bat wings])
                    + "congressional medal of insanity");
            } else {
                tempEquipment("spell damage percent, mys", "Mer-kin gladiator mask,Mer-kin gladiator tailpiece,"
                    + "congressional medal of insanity");
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
            if (get_property("uts_postloopCommand") != "")
                cli_execute(get_property("uts_postloopCommand"));
        }
    }
}

// ─── MAIN ─────────────────────────────────────────────────────────────────────

void main() {
    try {
        set_property("choiceAdventureScript", "UnderTheSea_Choice.ash");
        print("Starting UnderTheSea");
        initialization();
        seaMonkees();
        sorceress();
    } finally {
        set_property("choiceAdventureScript", choiceStorage);
        set_ccs(CCSStorage);
        print("Ending UnderTheSea");
    }
}
