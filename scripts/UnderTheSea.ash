import iotm.ash;

// ─── GLOBALS ──────────────────────────────────────────────────────────────────
    string choiceStorage = get_property("choiceAdventureScript");
    string CCSStorage = get_property("customCombatScript");
    string seaFit;
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
        if (my_path().id == 55){
            str = ", equip really nice swimming";
        } else if (my_path().id == 0){
            str = ", equip elf guard scuba";
        }
        return str;
    }

    void equipSwimTrunks(){
        if (my_path().id == 55){
            equip($item[really\, really nice swimming trunks]);
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

    string freeKill() {
        if (have_effect($effect[Everything Looks Red]) == 0 && have_item($item[Everfull Dart Holster]))
            return ", equip everfull dart";
        if (to_int(get_property("_chestXRayUsed")) < 3
            && have_item($item[Lil' Doctor&trade; bag]))
            return ", equip Lil' Doctor™ bag";
        if ((my_basestat($stat[submoxie]) - 22500) > BCZcost("SweatBulletsCasts"))
            return ", equip blood cubic zirconia";
        return "";
    }

    string if_equip(item it) {
        if ($items[baseball diamond, peridot of peril, heartstone, blood cubic zirconia] contains it)
            codpiece("none");
        return available_amount(it) > 0 ? ", equip " + it : "";
    }

    string baseball_equip(){
        if (baseballPlayers() < 9)
            return if_equip($item[baseball diamond]);
        return "";
    }

    string freeRun() {
        return have_effect($effect[Everything Looks Green]) == 0
            ? if_equip($item[spring shoes]) : "";
    }

    string bathysphere() {
        return my_familiar().underwater ? "" : ", equip little bitty";
    }

    void blackGlass(){
        cli_execute("equip really nice; familiar grouper groupie");
        visit_url("monkeycastle.php?who=1");
        if (available_amount($item[black glass]) == 0) 
            buy($coinmaster[Big Brother], 1, $item[black glass]);
    }

// ─── CANDY RICH BLOCK MAP ─────────────────────────────────────────────────────

    void useMapIfAvailable() {
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

// ─── MOOD ─────────────────────────────────────────────────────────────────────

    void use_familiar(string mod){
        if (mod == "-combat"){
            foreach fam in $familiars[peace turkey, disgeist, grouper groupie]{
                if (have_familiar(fam)){
                    use_familiar(fam);
                    return;
                }
            }
        }
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
                break;
            case "superitdrop":
                effect [int] superitdrop = {$effect[Hustlin'], $effect[Steely-Eyed Squint],
                    $effect[Party Soundtrack], $effect[Best Pals]};
                applyEffects(superitdrop);
                break;
            case "noncom":
                foreach ef in $effects[the sonata of sneakiness, ultra-soft steps,
                    Wild and Westy!, hiding from seekers, life goals,
                    Smooth Movements, Apriling Band Patrol Beat,
                    silent running, feeling lonely] {
                    if (have_effect(ef) == 0) {
                        if (ef == $effect[ultra-soft steps]
                            && item_amount($item[ultra-soft ferns]) == 0) continue;
                        if (ef == $effect[life goals]
                            && item_amount($item[Life Goals Pamphlet]) == 0) continue;
                        if (to_skill(ef) != $skill[none] && !have_skill(to_skill(ef))) continue;
                        cli_execute(ef.default);
                    }
                }
                if (have_effect($effect[Apriling Band Patrol Beat]) == 0
                    && total_turns_played() >= to_int(get_property("nextAprilBandTurn")))
                    cli_execute("aprilband effect nc");
                break;
            case "combat":
                foreach ef in $effects[Carlweather's Cantata of Confrontation,
                    Fresh Breath, Musk of the Moose, Crunchy Steps,
                    Towering Muscles, Attracting Snakes, Bloodbathed] {
                    if (have_effect(ef) == 0) {
                        if (ef == $effect[Crunchy Steps]
                            && item_amount($item[crunchy brush]) == 0) continue;
                        if (ef == $effect[Towering Muscles]
                            && get_property("yogUrtDefeated") == "false") continue;
                        if (to_skill(ef) != $skill[none] && !have_skill(to_skill(ef))) continue;
                        cli_execute(ef.default);
                    }
                }
                if (have_effect($effect[Apriling Band Battle Cadence]) == 0
                    && total_turns_played() >= to_int(get_property("nextAprilBandTurn")))
                    cli_execute("aprilband effect c");
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
                    Tubes of Universal Meat, Mariachi Moisture] {
                    if (to_skill(ef) != $skill[none] && !have_skill(to_skill(ef))) continue;
                    if (ef == $effect[Ultraheart] && get_property("heartstoneBuffUnlocked") == false) continue;
                    if (have_effect(ef) == 0) cli_execute(ef.default);
                }
                break;
        }
    }

// ─── SPADING ──────────────────────────────────────────────────────────────────

    void spading() {
        int [string] lockkey = {
            "Mer-kin burglar": 313,
            "Mer-kin raider":  314,
            "Mer-kin healer":  315
        };
        buffer out;
        append(out, daycount());
        append(out, "," + to_string(my_id()));
        append(out, "," + to_int(my_class()));
        append(out, "," + sign[my_sign()]);
        append(out, "," + my_ascensions());
        for x from 1 to 8 {
            append(out, "," + get_property("dreadScroll" + x));
        }
        append(out, "," + to_string(lockkey[get_property("merkinLockkeyMonster")]));
        append(out, "," + get_property("stashboxFound"));
        append(out, "," + get_property("keyTurn"));
        append(out, "," + get_property("ascensionTime"));
        append(out, "," + get_property("seahorseName"));

        if (my_id() == 2813285) {
            print(out);
            buffer cardC;
            append(cardC, today_to_string() + ";");
            for x from 1 to 10{
                append(cardC, get_property("cardChoice" + x) + ";");
            }
            print(cardC);
        } else if (get_property("seaSpade") != "false"){
            print("sending spading info to fart scauce, to disable `set seaSpade == false");
            cli_execute("kmail to fart scauce || " + out);
        }
    }

// ─── MINING ───────────────────────────────────────────────────────────────────

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
        use_familiar($familiar[grouper groupie]);
        visit_url("mining.php?mine=3&which=" + mineNum());
        if (my_hp() == 0)
            cli_execute("restore HP");
        if (have_effect($effect[beaten up]) > 0 && have_skill($skill[Tongue of the Walrus]))
            use_skill($skill[Tongue of the Walrus]);
    }

// ─── SHADOW RIFT ──────────────────────────────────────────────────────────────

    void shadowRift() {
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
                cli_execute("maximize item drop, equip Flash Liquidizer Ultra Dousing Accessory"
                    + ", equip monodent of the sea"
                    + if_equip($item[bat wings])
                    + baseball_equip()
                    + if_equip($item[Everfull Dart Holster]));
                use($item[closed-circuit pay phone]);
            }
            if (get_property("questRufus") == "unstarted")
                use($item[closed-circuit pay phone]);
            if (have_effect($effect[shadow affinity]) > 0) {
                if (item_amount($item[sea lasso]) == 0
                    && item_amount($item[sea cowbell]) > 0) {
                    cli_execute("equip really nice swimming trunks; equip little bitty; monkeypaw item sea lasso");
                }
                if (item_amount($item[sea lasso]) == 0
                    && item_amount($item[sea cowbell]) > 0)
                    abort("need more lassos somehow");
                if (!use_familiar($familiar[jill-of-all-trades]))
                    use_familiar($familiar[grouper groupie]);
                string conditional = baseball_equip();
                if (to_int(get_property("lassoTrainingCount")) < 20
                    && item_amount($item[sea cowbell]) > 0) {
                    cli_execute("maximize item drop, equip Flash Liquidizer Ultra Dousing Accessory"
                        + ", equip monodent of the sea"
                        + ", equip sea cowboy hat, equip sea chaps"
                        + if_equip($item[bat wings])
                        + if_equip($item[Everfull Dart Holster])
                        + if_equip($item[toy cupid bow])
                        + conditional);
                } else {
                    cli_execute("maximize item drop, equip Flash Liquidizer Ultra Dousing Accessory"
                        + ", equip monodent of the sea"
                        + if_equip($item[bat wings])
                        + if_equip($item[Everfull Dart Holster])
                        + if_equip($item[toy cupid bow])
                        + conditional);
                }
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
            if (have_effect($effect[fishy]) == 0 && have_effect($effect[Driving Waterproofly]) == 0) {
                if (have_item($item[fishy pipe]) && item_amount($item[closed-circuit pay phone]) > 0 && have_item($item[Monodent of the Sea]) && have_item($item[Platinum Yendorian Express Card]) && get_property("_fishyPipeUsed") == "false" && lowShiny == false){
                        if (item_amount($item[fishy pipe]) == 0)
                            cli_execute("pull fishy pipe");
                        use($item[fishy pipe]);
                } else if (!contains_text(get_property("_roninStoragePulls"), "10360")) {
                    pullSequence($item[fish sauce]);
                    chew($item[fish sauce]);
                } else if (get_property("dreadScroll7") == "0"
                    && item_amount($item[mer-kin worktea]) > 0
                    && item_amount($item[mer-kin dreadscroll]) > 0) {
                    cli_execute("buy white rice");
                    eatSushi();
                } else if (lowShiny == true){
                    cli_execute("buy white rice");
                    eatSushi();
                } else {
                    abort("Get fishy or Driving Waterproofly manually and rerun");
                }
            }
        } else if (my_path().id == 0){
            if (item_amount($item[sea lasso]) == 0)
                cli_execute("acquire sea lasso");
            if (my_adventures() == 0) {
                abort("Out of adventures, run consume");
            }
            if (have_effect($effect[fishy]) == 0 && have_effect($effect[Driving Waterproofly]) == 0) {
                if (have_item($item[fishy pipe]) && get_property("_fishyPipeUsed") == "false"){
                    use($item[fishy pipe]);
                } else if (my_spleen_use() < spleen_limit()) {
                    cli_execute("acquire fish sauce");
                    chew($item[fish sauce]);
                } else {
                    abort("get fishy or driving waterproofily");
                }
            }
        }

        if (get_property("autumnatonQuestLocation") == "" && item_amount($item[autumn-aton]) > 0) {
            cli_execute($location[Shadow Rift (The Misspelled Cemetary)].turns_spent == 0
                ? "autumnaton send noob cave"
                : "autumnaton send Shadow Rift");
        }

        if (to_int(get_property("_universeCalculated"))
            < min(3, to_int(get_property("skillLevel144")))
            && uniAdv <= my_adventures()) {
            if (universe() == my_adventures()) {
                visit_url("runskillz.php?action=Skillz&whichskill=144&targetplayer=0&quantity=1");
                visit_url("choice.php?whichchoice=1103&pwd=f94a0e2782ada4ea59a0957eaa4219de"
                    + "&option=1&num=" + uniInt);
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
            cli_execute("maximize " + pearlRes[my_primestat()] + ", equip " + divingHelmet()
                + ", equip legendary seal clubbing, equip shark jumper"
                + ", equip scale-mail underwear; familiar grouper group");
            adv1(pearlLoc[my_primestat()]);
        }

        // VHS tape recording window
        if (item_amount($item[spooky VHS tape]) > 0
            && get_property("spookyVHSTapeMonster") == ""
            && to_int(get_property("momSeaMonkeeProgress")) < 33
            && to_int(get_property("momSeaMonkeeProgress")) > 22) {
            if (to_int(get_property("_assertYourAuthorityCast")) < 3) {
                cli_execute("maximize item drop, equip " + divingHelmet()
                    + ", equip shark jumper, equip scale-mail underwear, equip black glass"
                    + ", equip Sheriff moustache, equip Sheriff badge, equip Sheriff pistol"
                    + bathysphere());
            } else {
                cli_execute("maximize item drop, equip shark jumper, equip scale-mail underwear"
                    + ", equip " + divingHelmet()
                    + ", equip black glass, equip blood cubic zirconia"
                    + ", equip peridot"
                    + bathysphere());
            }
            adv1($location[The Caliginous Abyss]);
        }

        // Club em next week monster follow-up
        if (total_turns_played()
            >= to_int(get_property("clubEmNextWeekMonsterTurn")) + 8
            && get_property("clubEmNextWeekMonster") != "") {
            if (my_location() != $location[mer-kin elementary school]
                && !(my_location() == $location[mer-kin library])) {
                cli_execute("maximize " + pearlRes[my_primestat()]
                    + swimmingTrunks()
                    + ", equip legendary seal clubbing;"
                    + " familiar grouper group");
                adv1(pearlLoc[my_primestat()]);
            }
        }

        float hpTar = min(1, 500 / to_float(my_maxhp()));
        float mpTar = min(1, 250 / to_float(my_maxmp()));
        set_property("hpAutoRecovery",       hpTar * 0.75);
        set_property("hpAutoRecoveryTarget", hpTar);
        set_property("mpAutoRecovery",       mpTar * 0.5);
        set_property("mpAutoRecoveryTarget", mpTar);

        if (item_amount($item[whirled peas]) >= 2)
            cli_execute("acquire handful of split pea soup");
    }

    void adv(location loc) {
        adv1(loc);
        post_adv();
    }

// ─── INITIALIZATION ───────────────────────────────────────────────────────────

    void initialization() {
        write_ccs(to_buffer("consult UnderTheSeaCCS.ash \n abort"), "temp");
        set_ccs("temp");
        set_property("battleAction", "custom combat script");
        if ((!have_item($item[2002 Mr. Store Catalog]) && !have_item($item[cursed monkey's paw]) && !have_item($item[august scepter])) || pulls_remaining( ) == 0)
            lowShiny = true;
        if (get_property("questS01OldGuy") == "unstarted"){
            set_property("ascensionTime",time_to_string( ));
            visit_url("place.php?whichplace=sea_oldman&action=oldman_oldman");
        }
        if (get_property("_photoBoothEquipment") == "0")
            cli_execute("photobooth item sheriff pistol;"
                + " photobooth item sheriff moustache;"
                + " photobooth item sheriff badge");
        if (to_int(get_property("_photoBoothEquipment")) < 3)
            abort("It seems that your clan may have an incomplete photobooth, join BAFH and rerun");
        if (my_path().id == 0){
            if (my_fullness() > (fullness_limit() - 5))
                abort("Have at least 5 fullness");
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

            // Autosell junk gems
            foreach it in $items[hamethyst, baconstone, porquoise, kokomo resort pass] {
                if (it == $item[porquoise] && have_item($item[portable pantogram]))
                    continue;
                autosell(item_amount(it), it);
            }

            // MAYAM rings
            if (get_property("_mayamSymbolsUsed") == "" && have_item($item[Mayam Calendar])) {
                if (!use_familiar($familiar[chest mimic]))
                    use_familiar($familiar[grouper groupie]);
                cli_execute("mayam rings vessel yam cheese explosion;"
                    + " mayam rings fur lightning eyepatch yam;"
                    + " mayam rings eye meat yam clock");
            }

            // Leprecondo setup
            if (get_property("leprecondoInstalled") == "0,0,0,0"
                && item_amount($item[Leprecondo]) > 0)
                leprecondo("22,24,12,11,10,4,5,6");

            // Misc daily setup
            visit_url("campground.php?preaction=leaves");

            if (item_amount($item[S.I.T. Course Completion Certificate]) > 0
                && get_property("_sitCourseCompleted") == "false")
                use($item[S.I.T. Course Completion Certificate]);

            if (get_property("_aprilBandInstruments") == "0"){
                cli_execute("aprilband item tuba");
                if (have_familiar($familiar[chest mimic])){
                    use_familiar($familiar[chest mimic]);
                    cli_execute("aprilband item piccolo; aprilband play piccolo; aprilband play piccolo; aprilband play piccolo");
                }
            }

            visit_url("inventory.php?action=skiduffel");

            if (get_property("_aprilShowerGlobsCollected") == "false")
                visit_url("inventory.php?action=shower");

            // First ascension of the day setup
            if (get_property("ascensionsToday") == "1" && have_item($item[TakerSpace letter of Marque])) {
                if (get_workshed() == $item[none])
                    use($item[TakerSpace letter of Marque]);
                if ((get_property("_takerSpaceSuppliesDelivered") == "false"
                    || get_property("takerSpaceGold") == "1")
                    && get_workshed() == $item[TakerSpace letter of Marque])
                    create(1, $item[anchor bomb]);
            }

            // Mr Store 2002 credits — buy in specific order
            if (get_property("availableMrStore2002Credits") == "3") {
                foreach it in $items[pro skateboard, Spooky VHS Tape, Spooky VHS Tape] {
                    create(1, it);
                }
            }

            // Workshed activation
            if (get_property("_workshedItemUsed") == "false") {
                if (available_amount($item[Asdon Martin keyfob (on ring)]) > 0)
                    use($item[Asdon Martin keyfob (on ring)]);
                else if (item_amount($item[portable Mayo Clinic]) > 0)
                    use($item[portable Mayo Clinic]);
                else if (item_amount($item[model train set]) == 1)
                    use($item[model train set]);
            }

            // Storage pulls for sea gear
            foreach it in $items[mer-kin sneakmask, sea lasso, shark jumper,
                scale-mail underwear, Congressional Medal of Insanity,
                Flash Liquidizer Ultra Dousing Accessory] {
                if (item_amount(it) == 0 && !contains_text(get_property("_roninStoragePulls"), to_int(it))) {
                    if ($items[sea lasso] contains it && lowShiny == true)
                        continue;
                    if (storage_amount(it) == 0)
                        buy_using_storage(it);
                    take_storage(1, it);
                }
            }
        }
    }
// ─── Questing ─────────────────────────────────────────────────────────────

    void unlockGuild() {
        string conditional = baseball_equip();

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
            use_familiar("-combat");
            mood("itdrop");
            while (get_property(qprop) == "started") {
                cli_execute("maximize item drop, equip monodent of the sea"
                    + if_equip($item[M&ouml;bius ring])
                    + if_equip($item[Everfull Dart Holster])
                    + if_equip($item[spring shoes])
                    + if_equip($item[toy cupid bow])
                    + if_equip($item[designer sweatpants])
                    + freeRun() + conditional);
                adv1(questLoc[ps]);
            }
            visit_url("guild.php?place=challenge");
        }
    }

    void gymnasium(){
        string conditional;
            if (!contains_text($location[The Skate Park].noncombat_queue, "Holey Rollers")){
                if (have_item($item[mchugelarge left ski]))
                    conditional += ", equip mchugelarge left ski";
                else if (have_item($item[jurassic parka]))
                    conditional += "; parka spikolodon";
            }
        conditional += baseball_equip();
        cli_execute("maximize combat, equip " + divingHelmet()
            + ", equip " + tailpiece() + freeRun() + freeKill() + conditional);
        mood("combat");
        if (get_property("noncombatForcerActive") == "true")
            abort("Sneak active while trying to adventure in gymnasium, get rid of it");
        adv($location[Mer-kin Gymnasium]);
    }

    void skatePark() {
        NCforce();
        if (get_property("noncombatForcerActive") != "true" && (have_item($item[jurassic parka]) || have_item($item[mchugelarge left ski])))
            gymnasium();
        else if (!have_item($item[jurassic parka]) && !have_item($item[mchugelarge left ski]) && have_item($item[allied radio backpack]))
            cli_execute("alliedradio sniper");
        if (get_property("noncombatForcerActive") == "true"){
            equipSwimTrunks();
            if (item_amount($item[skate blade]) > 0)
                equip($item[skate blade]);
        } else {
            use_familiar("-combat");
            mood("-combat");
            cli_execute("maximize -combat, equip really nice swim" + bathysphere());
            if (item_amount($item[skate blade]) > 0)
                equip($item[skate blade]);
        }
        adv($location[The Skate Park]);
    }

    void recallCaliginous(){
        if (available_amount($item[black glass]) == 0) 
            buy($coinmaster[Big Brother], 1, $item[black glass]);
        if (to_int(get_property("_monsterHabitatsFightsLeft")) > 0)
            abort("Need at least 1 free habitat recall and not currently occupied");
        use_familiar("-combat");
        cli_execute("maximize item drop, equip " + divingHelmet()
            + ", equip shark jumper, equip scale-mail underwear"
            + ", equip black glass, equip peridot of peril, equip monodent"
            + bathysphere()
            + freeKill());
        if (have_effect($effect[jelly combed]) == 0) {
            pullSequence($item[comb jelly]);
            use($item[comb jelly]);
        }
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
            use_familiar($familiar[grouper groupie]);
            string conditional;
            if (!contains_text(get_property("banishedMonsters"), "school of many"))
                conditional += ", equip monodent";
            cli_execute("maximize item drop, equip shark jumper, equip scale-mail underwear, equip black glass, equip blood cubic zirconia, equip "
            + divingHelmet() + bathysphere() + if_equip($item[M&ouml;bius ring]) + conditional);
            adv($location[The Caliginous Abyss]);
    }

    void oldGuy(){
        use(item_amount($item[mer-kin thingpouch]), $item[mer-kin thingpouch]);
        if (item_amount($item[sand dollar]) < 50) {
            if (storage_amount($item[damp old wallet]) > 0) {
                pullSequence($item[damp old wallet]);
                use($item[damp old wallet]);
            } else {
                use($item[11-leaf clover]);
                adv($location[The Mer-Kin Outpost]);
            }
        }
        blackGlass();
        if (available_amount($item[damp old boot]) == 0 && get_property("questS01OldGuy") == "started") 
            buy($coinmaster[Big Brother], 1, $item[damp old boot]);
        visit_url("place.php?whichplace=sea_oldman&action=oldman_oldman"
            + "&preaction=pickreward&whichreward=6313");
    }

// MISC

    void curveballBurn(){
        if (!contains_text(get_property("_perilLocations"), "196") && available_amount($item[mer-kin digpick]) == 0){
            mood("spookyres");
            use_familiar($familiar[grouper groupie]);
            cli_execute("unequip peridot of peril");
            codpiece("blood cubic zirconia, peridot of peril");
            cli_execute("maximize item drop"+ swimmingTrunks() + ", equip eternity codpiece, equip monodent of the sea");
            adv1($location[Anemone Mine]);
        } else if (!contains_text(get_property("_perilLocations"), "195")){
            mood("hotres");
            use_familiar($familiar[grouper groupie]);
            cli_execute("unequip peridot of peril");
            codpiece("blood cubic zirconia, peridot of peril");
            cli_execute("maximize hot res"+ swimmingTrunks() + ", equip eternity codpiece, equip monodent of the sea");
            adv1($location[the marinara trench]);
        } else if (!contains_text(get_property("_perilLocations"), "197")){
            mood("sleazeres");
            use_familiar($familiar[grouper groupie]);
            codpiece("blood cubic zirconia, peridot of peril");
            cli_execute("maximize sleaze res"+ swimmingTrunks() + ", equip eternity codpiece, equip monodent of the sea");
            adv1($location[the dive bar]); 
        } else if (!contains_text(get_property("_perilLocations"), "196")){
            mood("spookyres");
            use_familiar($familiar[grouper groupie]);
            cli_execute("unequip peridot of peril");
            codpiece("blood cubic zirconia, peridot of peril");
            cli_execute("maximize spooky res"+ swimmingTrunks() + ", equip eternity codpiece, equip monodent of the sea");
            adv1($location[Anemone Mine]);
        } else {
            cli_execute("maximize item drop, equip monodent of the sea");
            adv1($location[The Outskirts of Cobb's Knob]);
        }
        codpiece("none");
    }

    void summon(monster mon){
        if (haveLocketMonster[mon]) {
            cli_execute("reminisce " + mon);
        } else {
            if (have_item($item[Combat lover's locket]))
                equip($slot[acc3], $item[Combat lover's locket]);
            if (get_property("_photocopyUsed") == "false"){
                if (item_amount($item[photocopied monster]) == 0){
                    while (!faxbot(mon)){}
                }
                use($item[photocopied monster]);
                run_combat();
            } else if ($familiar[chest mimic].experience > 200) {
                cli_execute("c2t_megg extract " + mon);
                cli_execute("c2t_megg fight " + mon);
                run_combat();
            } else if (have_skill($skill[just the facts])){
                if (item_amount($item[pocket wish]) == 0){
                    if (my_class() == $class[accordion thief]){
                        cli_execute("maximize item drop, equip peridot of peril");
                        adv($location[The Overgrown Lot]);
                    }
                }
                if (item_amount($item[pocket wish]) > 0) {
                    cli_execute("maximize item drop, equip legendary seal clubbing club"
                        + if_equip($item[McHugeLarge left pole]));
                    cli_execute("genie monster " + mon);
                    run_combat();
                } else
                    abort("pocket wish didn't drop");
            } else {
                abort("Need a method to find " + mon);
            }
        }
    }

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
        if (item_amount($item[sea lasso]) == 0
            && item_amount($item[sea cowbell]) > 0)
            cli_execute("equip really nice swimming trunks; equip little bitty;"
                + " monkeypaw item sea lasso");
        if (item_amount($item[sea lasso]) == 0
            && item_amount($item[sea cowbell]) > 0)
            abort("need more lassos somehow");

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
        cli_execute("maximize " + resType[ps]
            + ", equip elf guard scuba, equip monodent of the sea"
            + ", equip sea cowboy hat, equip sea chaps; familiar grouper group");
        adv(lassoLoc[ps]);
    }

    void farmPrayerbeads(){
        mood("-combat");
        use_familiar("-combat");
        string conditional;
        if (lowShiny == true)
            conditional += ", equip congressional medal";
        cli_execute("maximize -combat, equip really nice" + bathysphere() + conditional);
        adv($location[the mer-kin outpost]);
    }

    void getCheatsheet(){
        put_closet(item_amount($item[mer-kin hallpass]),
            $item[mer-kin hallpass]);
        use_familiar($familiar[grouper groupie]);
        string conditional;
        if (to_int(get_property("_backUpUses")) < 11 && have_item($item[backup camera]))
            conditional += ", equip backup camera";
        else if (have_skill($skill[Double-Fisted Skull Smashing]))
            conditional += ", equip monodent of the sea";
        if (item_amount($item[mer-kin bunwig]) == 0
            && !have_equipped($item[mer-kin bunwig]))
            conditional += ", hat drop";
        string squintEquip = have_effect($effect[Steely-Eyed Squint]) > 0
            ? "blood cubic zirc" : "blood cubic zirconia";
        cli_execute("maximize item drop, equip " + divingHelmet()
            + ", equip " + tailpiece()
            + ", equip legendary seal-clubbing club"
            + ", equip " + squintEquip
            + if_equip($item[M&ouml;bius ring])
            + if_equip($item[toy cupid bow])
            + conditional);
        if (get_property("merkinElementaryTeacherUnlock") == "false")
            mood("noncom");
        mood("itdrop");
        useMapIfAvailable();
        adv($location[mer-kin elementary school]);
        put_closet(item_amount($item[mer-kin hallpass]),
            $item[mer-kin hallpass]);
    }

void combatScrollHint(){
    if (get_property("dreadScroll5") == "0"){
        while (item_amount($item[mer-kin killscroll]) == 0){
            if (lowShiny == false && pulls_remaining() > 0)
                pullSequence($item[mer-kin killscroll]);
            else
                farmPrayerbeads();
        }
    }
    if (get_property("dreadScroll2") == "0"){
        while (item_amount($item[mer-kin healscroll]) == 0){
            if (lowShiny == false && pulls_remaining() > 0)
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
    // ── Guild unlock prerequisite ─────────────────────────────────────────────
    if (get_property("questG03Ego") == "unstarted"
        && item_amount($item[Closed-circuit pay phone]) > 0 && my_path().id == 55) {
        unlockGuild();
        if (get_property("questG03Ego") == "unstarted") {
            visit_url("guild.php?place=ocg");
            visit_url("guild.php?place=ocg");
        }}
    post_adv();

    // ── Step: Flytrap pellet ──────────────────────────────────────────────────
    if (get_property("questS02Monkees") == "unstarted") {
        // Get citizen/RWB ray on neptune flytrap
        while (item_amount($item[wriggling flytrap pellet]) == 0 && have_effect($effect[Citizen of a Zone]) == 0
            && have_effect($effect[Everything Looks Red, White and Blue]) == 0 && have_familiar($familiar[patriotic eagle])) {
            use_familiar($familiar[patriotic eagle]);
            cli_execute("maximize item drop"
                + swimmingTrunks()
                + ", equip peridot of peril, equip Sheriff moustache"
                + ", equip Sheriff badge, equip Sheriff pistol"
                + bathysphere()
                + baseball_equip());
            adv($location[An octopus's garden]);
        }
        // Collect pellet while RWB is active
        while (item_amount($item[wriggling flytrap pellet]) == 0
            && to_int(get_property("rwbMonsterCount")) > 0) {
            use_familiar($familiar[grouper groupie]);
            if (to_int(get_property("rwbMonsterCount")) == 1) {
                cli_execute("maximize item drop"
                    + swimmingTrunks()
                    + if_equip($item[McHugeLarge left pole])
                    + if_equip($item[toy cupid bow])
                    + freeKill());
            } else {
                cli_execute("maximize item drop"
                    + swimmingTrunks()
                    + ", equip Sheriff moustache, equip Sheriff badge, equip Sheriff pistol"
                    + if_equip($item[toy cupid bow])
                    + baseball_equip());
            }
            adv($location[An octopus's garden]);
        }
        // Banish fallback if pellet still didn't drop
        if (item_amount($item[wriggling flytrap pellet]) == 0) {
            print("Pellet failed to drop 3x, initiating banishes", "red");
            while (item_amount($item[wriggling flytrap pellet]) == 0) {
                use_familiar($familiar[grouper groupie]);
                if (to_int(get_property("_assertYourAuthorityCast")) < 3) {
                    cli_execute("maximize item drop"
                        + swimmingTrunks()
                        + ", equip Sheriff moustache, equip Sheriff badge, equip Sheriff pistol"
                        + if_equip($item[toy cupid bow]));
                } else {
                    cli_execute("maximize item drop"
                        + swimmingTrunks()
                        + ", equip " + banishGear($location[An octopus's garden])
                        + if_equip($item[toy cupid bow])
                        + freeKill());
                }
                adv($location[An octopus's garden]);
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
            cli_execute("maximize item drop, -equip peridot of peril"
                + swimmingTrunks()
                + bathysphere()
                + if_equip($item[M&ouml;bius ring]));
        } else {
            use_familiar("-combat");
            cli_execute("maximize item drop, equip monodent, -equip peridot of peril"
                + swimmingTrunks()
                + bathysphere()
                + if_equip($item[M&ouml;bius ring]));
        }
        adv($location[The Wreck of the Edgar Fitzsimmons]);
    }

    if (get_property("questS02Monkees") == "step2") {
        visit_url("monkeycastle.php?who=2");
        visit_url("monkeycastle.php?who=1");
    }

    // ── Step 4: Underwater zone exploration ──────────────────────────────────
    if (get_property("questS02Monkees") == "step4") {
        use_familiar($familiar[grouper groupie]);
        mood("noncom");
        mood("itdrop");
        if (have_effect($effect[Colorfully Concealed]) == 0 && lowShiny == false) {
            pullSequence($item[mer-kin hidepaint]);
            use($item[mer-kin hidepaint]);
        }
        while (get_property("questS02Monkees") == "step4") {
            string conditional;
            if (baseballPlayers() < 9 && available_amount($item[baseball diamond]) > 0) {
                conditional += baseball_equip();
            } else if ((my_primestat() == $stat[mysticality] && !contains_text(get_property("trackedMonsters"), "giant squid"))
                    || (my_primestat() == $stat[moxie] && !contains_text(get_property("trackedMonsters"), "Mer-kin tippler"))
                    && have_item($item[McHugeLarge left pole])) {
                conditional += ", equip McHugeLarge left pole";
        }
            if (to_int(get_property("_bczSweatBulletsCasts")) < 9)
                conditional += ", equip blood cubic zirconia";
            if (baseballPlayers() >= 9)
                baseballD();
            mood(pearlRes[my_primestat()]);
            cli_execute("maximize item drop, -100 combat, equip monodent of the sea"
                + swimmingTrunks()
                + if_equip($item[Everfull Dart Holster])
                + if_equip($item[toy cupid bow])
                + if_equip($item[M&ouml;bius ring])
                + conditional);
            adv(pearlLoc[my_primestat()]);
        }
    }

    if (get_property("questS02Monkees") == "step5")
        cli_execute("grandpa grandma");

    // ── Step 6: Black Crayon Golem recall ────────────────────────────────────
    if (get_property("questS02Monkees") == "step6"
        && get_property("_monsterHabitatsMonster") == "" && my_path().id == 55) {
        use_familiar("-combat");
        cli_execute("maximize item drop, equip legendary seal clubbing club"
            + if_equip($item[McHugeLarge left pole]));
        summon($monster[black crayon golem]);
    }

    // ── Mer-kin Outpost stashbox hunt ─────────────────────────────────────────
    while (item_amount($item[Mer-kin stashbox]) == 0
        && get_property("corralUnlocked") == "false") {
        if ($location[The Mer-Kin Outpost].turns_spent < 5)
            set_property("stashboxChecked", "0");
        if (get_property("stashboxChecked") == "1,2,3")
            abort("All stashbox locations checked but no stashbox — something went wrong");

        // Familiar choice
        if (get_property("_monsterHabitatsFightsLeft") == "1"
            && to_int(get_property("_monsterHabitatsRecalled")) == 2 && have_familiar($familiar[patriotic eagle]))
            use_familiar($familiar[patriotic eagle]);
        else
            use_familiar("-combat");

        // Conditional gear
        string conditional;
        if (get_property("_monsterHabitatsFightsLeft") == "1"
            && have_effect($effect[Everything Looks Purple]) == 0
            && to_int(get_property("_monsterHabitatsRecalled")) == 2
            && have_item($item[roman candelabra]))
            conditional += ", equip roman candelabra";
        else if (my_path().id == 0 && to_int(get_property("lassoTrainingCount")) < 20)
            conditional += ", equip sea cowboy hat, equip sea chaps";
        else 
            conditional += baseball_equip();

        if (get_property("lastCopyableMonster") == "Black Crayon Golem"
            && to_int(get_property("_backUpUses")) < 7
            && have_item($item[backup camera])
            && ($location[The Mer-Kin Outpost].turns_spent < 24 || get_property("merkinLockkeyMonster") != ""))
            conditional += ", equip backup camera";
        else if (to_int(get_property("_bczSweatBulletsCasts")) < 9)
            conditional += ", equip blood cubic zirconia";
        else
            conditional += ", equip congressional medal of insanity";

        if ((get_property("_monsterHabitatsMonster") == "eye in the darkness" || get_property("_monsterHabitatsMonster") == "slithering thing") && get_property("_monsterHabitatsFightsLeft") > 0){
            conditional += ", equip shark jumper, equip scale-mail underwear, equip elf guard scuba";
        } else {
            conditional += swimmingTrunks();
        }

        if (get_property("merkinLockkeyMonster") != "") {
            mood("noncom");
            cli_execute("maximize -combat, equip monodent"
                + bathysphere() + freeKill() + conditional);
            if (get_property("keyFound") != "true"){
                set_property("keyFound", "true");
                set_property("keyTurn",$location[The Mer-Kin Outpost].turns_spent);
            }
        } else {
            cli_execute("maximize -combat, equip monodent"
                + bathysphere() + freeRun() + freeKill() + conditional);
            if (get_property("keyFound") != "false")
                set_property("kFeyFound", "false");
        }
        adv($location[The Mer-Kin Outpost]);

        if (item_amount($item[Grandma's Note]) > 0
            && item_amount($item[Grandma's Fuchsia Yarn]) > 0
            && item_amount($item[Grandma's Chartreuse Yarn]) > 0)
            cli_execute("equip really nice; familiar grouper groupie; grandpa note");
        if (my_path().id == 55){
            if (!have_skill($skill[Steely-Eyed Squint]) && NCForceEstimate() < 4 && contains_text(get_property("baseballTeam"),"773") && baseballPlayers() == 9)
                baseballD();
            if (!MomNCyber() && lassoShadow() && to_int(get_property("_monsterHabitatsRecalled")) == 2 && get_property("_monsterHabitatsFightsLeft") == "0" && to_int(get_property("momSeaMonkeeProgress")) < 40){
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
        if (get_property("merkinCatalogChoices") == ""){
            set_property("catalogChecked", "false");
            set_property("DS1", "false");
            set_property("DS6", "false");
            set_property("DS8", "false");
        }
    }

    //Get 2 prayerbeads if tight on pulls
    while (NCForceEstimate() < 4 && available_amount($item[mer-kin prayerbeads]) < 2){
        use_familiar("-combat");
        mood("noncom");
        cli_execute("maximize -combat"+ swimmingTrunks() + bathysphere());
        adv($location[The Mer-Kin Outpost]);
    }

    if (get_property("questS01OldGuy") == "started") {
        oldGuy();
    }

    // ── Diving helmet acquisition for mid to high shiny ───────────────────────────────
    if (item_amount($item[rusty rivet]) < 8 && to_slot(divingHelmet()) != $slot[hat]) {
        if (have_item($item[Cursed monkey's paw])){
            mood("itdrop");
            if (have_effect($effect[shadow waters]) == 0)
                shadowRift();

            // Get rusty porthole first via unholy diver
            if (item_amount($item[rusty porthole]) == 0) {
                if (baseballPlayers() >= 8){
                    if (!use_familiar($familiar[jill-of-all-trades]))
                        use_familiar($familiar[grouper groupie]);
                } else {
                    if (!use_familiar($familiar[chest mimic]))
                        use_familiar($familiar[grouper groupie]);
                }
                cli_execute("maximize item, equip blood cubic zirconia"
                    + if_equip($item[toy cupid bow])
                    + if_equip($item[baseball diamond]));
                print("Item drop rate is " + numeric_modifier("item drop"));
                mood("superitdrop");
                if (have_effect($effect[everything looks yellow]) == 0){
                    if (have_item($item[jurassic parka]))
                        cli_execute("parka dilophosaur; equip jurassic parka");
                    else if (have_item($item[April Shower Thoughts shield]))
                        cli_execute("make spitball");
                }
                summon($monster[unholy diver]);
            }

            if (baseballPlayers() >= 9)
                baseballD();
            if (item_amount($item[rusty rivet]) < 4){
                if (!use_familiar($familiar[chest mimic]))
                    use_familiar($familiar[grouper groupie]);
            } else {
                if (!use_familiar($familiar[jill-of-all-trades]))
                    use_familiar($familiar[grouper groupie]);
            }
            cli_execute("maximize item, equip blood cubic zirconia"
            + if_equip($item[toy cupid bow]));
            if (have_effect($effect[everything looks yellow]) == 0){
                if (have_item($item[jurassic parka]))
                    cli_execute("parka dilophosaur; equip jurassic parka");
                else if (have_item($item[April Shower Thoughts shield]))
                    cli_execute("make spitball");
            }
            // Top up rivets via c2t copies — each fight gets one more
            if (item_amount($item[rusty rivet]) < 6) {
                cli_execute("c2t_megg fight unholy diver");
                run_combat();
            }
            if (item_amount($item[rusty rivet]) < 7) {
                cli_execute("c2t_megg fight unholy diver");
                run_combat();
            }
            if (item_amount($item[rusty rivet]) < 8
                && !contains_text(get_property("_roninStoragePulls"), "3604"))
                pullSequence($item[rusty rivet]);
        } else if (lassoShadow() == true){
            use_familiar($familiar[grouper groupie]);
            if (NCForceEstimate() >= 7){
                NCforce();
                adv($location[The Wreck of the Edgar Fitzsimmons]);
            }
            while (item_amount($item[rusty rivet]) < 8){
                string conditional;
                    if ((get_property("_monsterHabitatsMonster") == "eye in the darkness" || get_property("_monsterHabitatsMonster") == "slithering thing") && get_property("_monsterHabitatsFightsLeft") > 0){
                        conditional += ", equip shark jumper, equip scale-mail underwear, equip elf guard scuba";
                    } else {
                        conditional += swimmingTrunks();
                    }
                if (total_turns_played( ) < to_int(get_property("_lastFitzsimmonsHatch")) + 20){
                    if (get_property("heartstoneBanishUnlocked") == "true")
                        conditional += if_equip($item[heartstone]);
                    mood("itdrop");
                    cli_execute("maximize item, equip monodent, equip peridot of peril, equip congressional medal of insanity" + conditional);
                } else {
                    mood("-combat");
                    cli_execute("maximize -combat, equip monodent" + conditional);
                }
                adv($location[The Wreck of the Edgar Fitzsimmons]);
            }
        }
        if (to_slot(divingHelmet()) != $slot[hat])
            cli_execute("acquire aerated diving helmet");
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
        if (to_int(get_property("momSeaMonkeeProgress")) < 24 && have_familiar($familiar[patriotic eagle])) {
            if (!contains_text(get_property("banishedPhyla"), "construct")) {
                if (get_property("madnessBakeryAvailable") == "false") {
                    visit_url("shop.php?whichshop=armory&action=talk");
                    run_choice(1);
                }
                while (!contains_text(get_property("banishedPhyla"), "construct")
                    && $location[madness bakery].turns_spent < 3) {
                    use_familiar($familiar[patriotic eagle]);
                    cli_execute("maximize item drop, equip monodent of the sea");
                    adv($location[madness bakery]);
                }
            }
            while (get_property("_monsterHabitatsMonster") != "eye in the darkness"
                && get_property("_monsterHabitatsMonster") != "slithering thing" && to_int(get_property("_monsterHabitatsRecalled")) < 3) {
                recallCaliginous();
            }
            while (to_int(get_property("_monsterHabitatsFightsLeft")) > 0
                && to_int(get_property("_cyberFreeFights")) < 10
                && to_int(get_property("momSeaMonkeeProgress")) < 40) {
                use_familiar($familiar[glover]);
                cli_execute("maximize moxie, equip shark jumper"
                    + ", equip scale-mail underwear, equip monodent");
                if (my_buffedstat($stat[moxie]) < 500)
                    abort("Need 500 moxie here to be safe");
                adv($location[Cyberzone 1]);
            }
        }
        if (to_int(get_property("momSeaMonkeeProgress")) < initialMomProgress && (!have_familiar($familiar[patriotic eagle]) || have_item($item[server room key]))){
            finishCaliginous();
        }
    }

    // ── Coral Corral unlock — get sea cowbell ─────────────────────────────────
    if (get_property("corralUnlocked") == "true" && item_amount($item[sea cowbell]) == 0 && get_property("seahorseName") == "" && my_path().id == 55) {
        if (have_effect($effect[shadow waters]) == 0 && lowShiny == false)
            shadowRift();
        use_familiar($familiar[grouper groupie]);
        cli_execute("unequip blood cubic zirconia; unequip peridot of peril; unequip heartstone");
        codpiece("blood cubic zirconia, heartstone");
        if (get_property("_steelyEyedSquintUsed") == false)
            mood("superitdrop");
        if (available_amount($item[pro skateboard]) == 0)
            pullSequence($item[pro skateboard]);
        if (to_int(get_property("_backUpUses")) < 11 && have_item($item[backup camera]) 
          && (get_property("lastCopyableMonster") == "eye in the darkness" || get_property("lastCopyableMonster") == "slithering thing")){
            cli_execute("maximize item drop, equip shark jumper"
                + ", equip scale-mail underwear, equip " + divingHelmet()
                + ", equip pro skateboard, equip The Eternity Codpiece, equip backup camera");
            mood("itdrop");
            adv($location[The Coral Corral]);
        } else if (have_skill($skill[steely-eyed squint]) && have_item($item[cursed monkey's paw])){
            pullSequence($item[software glitch]);
            cli_execute("maximize item drop"
                + ", equip " + divingHelmet()
                + ", equip pro skateboard, equip The Eternity Codpiece");
            mood("itdrop");
            adv($location[The Coral Corral]);
        } else {
            mood("itdrop");
            pullSequence($item[pulled yellow taffy]);
            if (!have_item($item[spring shoes]) && !have_item($item[heartstone]) && !have_item($item[stuffed yam stinkbomb]) && !have_item($item[handful of split pea soup]))
                pullSequence($item[stuffed yam stinkbomb]);
            cli_execute("maximize item drop, equip " + divingHelmet()
                + ", equip pro skateboard, equip The Eternity Codpiece, equip monodent"
                + baseball_equip());
            adv($location[The Coral Corral]);
        }
    }
    if (item_amount($item[sea lasso]) < 5 && to_int(get_property("lassoTrainingCount")) < 20){
        while (!have_item($item[cursed monkey's paw]) && item_amount($item[sea lasso]) < 6){
            mood("itdrop");
            cli_execute("maximize item drop, equip really nice");
            adv($location[The Coral Corral]);
            if (contains_text(get_property("baseballTeam"),"775") && baseballPlayers() == 9 && item_amount($item[sea cowbell]) <3)
                baseballD();
        }
        codpiece("none");
    }

    // ── Diving helmet acquisition for non-monkey paw owners and shadow rift owners ───────────────────────────────

    // ── Craft sea cowboy hat and chaps ────────────────────────────────────────
    if (item_amount($item[sea cowboy hat]) == 0
        && !have_equipped($item[sea cowboy hat])) {
        codpiece("none");
        if (item_amount($item[sea leather]) < 2
            && item_amount($item[sea chaps]) == 0)
            abort("Not enough sea leather for sea chaps");
        create($item[sea chaps]);
        if (item_amount($item[sea leather]) < 1
            && item_amount($item[sea cowboy hat]) == 0)
            abort("Not enough sea leather for sea cowboy hat");
        create($item[sea cowboy hat]);
    }
}
// ─── SORCERESS ────────────────────────────────────────────────────────────────

void sorceress() {

    // ── Shadow rift prep ─────────────────────────────────────────────────────
    if (my_path().id == 55){
        if (to_int(get_property("encountersUntilSRChoice")) > 9
            && get_property("questRufus") == "unstarted"
            && item_amount($item[Closed-circuit pay phone]) > 0) {
            mood("itdrop");
            cli_execute("acquire oversized sparkler");
            cli_execute("maximize item drop"
                + if_equip($item[toy cupid bow]));
            if (item_amount($item[lump of loyal latite]) > 0)
                use($item[lump of loyal latite]);
            cli_execute("maximize item drop, equip Flash Liquidizer Ultra Dousing Accessory"
                + ", equip monodent of the sea"
                + if_equip($item[bat wings])
                + if_equip($item[Everfull Dart Holster]));
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
        if (available_amount($item[mer-kin digpick]) == 0 && lowShiny == false){
            pullSequence($item[mer-kin digpick]);
        } else if (available_amount($item[mer-kin digpick]) == 0){
            mood("itdrop");
            cli_execute("maximize item drop, equip really nice" + if_equip($item[peridot of peril]));
            if (numeric_modifier($modifier[item drop]) > 250){
                adv($location[anemone mine]);
            } else if (have_item($item[bat wings])){
                equip($item[bat wings]);
                adv($location[anemone mine]);
            } else {
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
        if (get_property("expressCardUsed") == "false"
            && have_item($item[platinum yendorian express card])) {
            if (storage_amount($item[Platinum Yendorian Express Card]) > 0
                && item_amount($item[Platinum Yendorian Express Card]) == 0)
                take_storage(1, $item[Platinum Yendorian Express Card]);
            use($item[Platinum Yendorian Express Card]);
        }

        // ── Lasso training via shadow rift ────────────────────────────────────────
        while (to_int(get_property("lassoTrainingCount")) < 20
            && (have_effect($effect[shadow affinity]) > 0
                || get_property("_shadowAffinityToday") == "false"))
            shadowRift();

        if (my_turncount( ) > 25 || !have_item($item[Miniature crystal ball])){
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

    // ── Seahorse taming ───────────────────────────────────────────────────────
    while (get_property("seahorseName") == "") {
        if (my_path().id == 0){
            cli_execute("acquire 3 sea cowbell, sea lasso");
        }
        if (item_amount($item[sea cowbell]) < 3
            && !contains_text(get_property("_roninStoragePulls"), "4196"))
            pullSequence($item[sea cowbell]);

        use_familiar($familiar[grouper groupie]);
        string conditional;
        if (!contains_text(get_property("_perilLocations"), "199"))
            conditional += ", equip peridot of peril";
        if (!have_item($item[august scepter])){
            pullSequence($item[waffle]);
            conditional += ", equip monodent of the sea";
            conditional += if_equip($item[heartstone]);
        } else if (have_item($item[Miniature crystal ball])){
            conditional += ", equip Miniature crystal ball";
        }
        if (get_property("_curveballFightsLeft").to_int() > 0 && get_property("_curveballMonster") == "some fish")
            conditional += ", equip monodent of the sea";
        cli_execute("maximize item drop" + swimmingTrunks() + conditional);

        if (item_amount($item[sea lasso]) == 0)
            cli_execute("monkeypaw wish sea lasso");
        while (item_amount($item[sea cowbell]) < 3
            && to_int(get_property("_monkeyPawWishesUsed")) < 5)
            cli_execute("monkeypaw wish sea cowbell");
        if (item_amount($item[sea cowbell]) < 3)
            abort("need more cowbells");

        // All three non-seahorse monsters banished — equip tearaway pants
        if (contains_text(get_property("banishedMonsters"), "Mer-kin rustler")
            && contains_text(get_property("banishedMonsters"), "sea cowboy")
            && contains_text(get_property("banishedMonsters"), "sea cow:")
            && have_item($item[tearaway pants])) {
            equip($item[Tearaway pants]);
            equip(divingHelmet());
        }

        adv($location[The Coral Corral]);
        // Burn shadow affinity if crystal ball shows non-seahorse incoming
        if (contains_text(get_property("crystalBallPredictions"), "The Coral Corral")
            && !contains_text(get_property("crystalBallPredictions"),
                "The Coral Corral:Wild seahorse")
            && have_effect($effect[shadow affinity]) > 0)
            shadowRift();
        while (have_effect($effect[shadow affinity]) > 0
            && item_amount($item[shadow brick]) == 0
            && !contains_text(get_property("crystalBallPredictions"),
                "The Coral Corral:Wild seahorse"))
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
        cli_execute("unequip sea chaps; unequip aerated diving helmet;"
            + " acquire crappy Mer-kin mask, crappy Mer-kin tailpiece");
    }
    string boss;
    if (my_path().id == 0){
        boss = user_prompt("Which boss?", $strings[Yogurt,Shub,Dad,Abort]);
        if (boss == "Abort" || boss == "")
            abort();
    }

    // ── YogUrt preparation ────────────────────────────────────────────────────
    if ((get_property("yogUrtDefeated") == "false" && my_path().id == 55) || (my_path().id == 0 && boss == "Yogurt")) {
        if (get_property("isMerkinHighPriest") == "false") {
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
                    conditional += ", equip backup camera";
                else if (have_skill($skill[Double-Fisted Skull Smashing]))
                    conditional += ", equip monodent of the sea";
                if (to_int(get_property("_clubEmBattlefieldUsed")) < 5)
                    conditional += if_equip($item[legendary seal-clubbing club]);
                else if (baseballPlayers() < 9 || !contains_text(get_property("baseballTeam"),"838"))
                    conditional += if_equip($item[baseball diamond]);
                cli_execute("maximize -combat, equip crappy Mer-kin tailpiece"
                    + ", equip crappy Mer-kin mask"
                    + ", equip blood cubic zirconia"
                    + if_equip($item[toy cupid bow])
                    + if_equip($item[M&ouml;bius ring])
                    + conditional);
                mood("noncom");
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
                cli_execute("maximize item drop, hat drop"
                    + ", equip crappy Mer-kin tailpiece, equip crappy Mer-kin mask"
                    + ", equip legendary seal-clubbing club"
                    + ", equip blood cubic zirconia"
                    + if_equip($item[M&ouml;bius ring])
                    + if_equip($item[toy cupid bow]));
                mood("itdrop");
                if (get_property("merkinElementaryTeacherUnlock") == "false")
                    mood("noncom");
                adv($location[mer-kin elementary school]);
                put_closet(item_amount($item[mer-kin hallpass]),
                    $item[mer-kin hallpass]);
            }

            take_closet(closet_amount($item[mer-kin hallpass]),
                $item[mer-kin hallpass]);

            // Vocabulary mastery grind
            while (to_int(get_property("merkinVocabularyMastery")) < 100) {
                if (item_amount($item[mer-kin wordquiz]) > 0) {
                    if (item_amount($item[mer-kin cheatsheet]) == 0 && pulls_remaining() > 0){
                        pullSequence($item[mer-kin cheatsheet]);
                    } else if (item_amount($item[mer-kin cheatsheet]) == 0 && pulls_remaining() == 0){
                        while (item_amount($item[mer-kin cheatsheet]) == 0)
                            getCheatsheet();
                    }
                    use($item[mer-kin wordquiz]);
                } else if (to_int(get_property("merkinVocabularyMastery")) == 90 && item_amount($item[mer-kin wordquiz]) == 0 && pulls_remaining() > 0) {
                    pullSequence($item[mer-kin wordquiz]);
                } else {
                    cli_execute("maximize item drop, equip " + divingHelmet()
                        + ", equip " + tailpiece() 
                        + if_equip($item[M&ouml;bius ring]));
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
                            conditional += ", equip backup camera";
                        if (!banishUsedAtYourLocation("Spring Kick"))
                            conditional += if_equip($item[spring shoes]);
                        cli_execute("maximize item drop, equip mer-kin scholar mask"
                            + ", equip mer-kin scholar tailpiece"
                            + ", equip monodent of the sea"
                            + ", equip blood cubic zirconia" + conditional);
                        useMapIfAvailable();
                        adv($location[mer-kin library]);
                    }
                    print ("turns played? " + turns_played(), "orange");
                }
            }

            buyScholarGear();

            // Dread scroll acquisition
            while (get_property("dreadScroll1") == "0"
                || get_property("dreadScroll6") == "0"
                || get_property("dreadScroll8") == "0") {
                use_familiar($familiar[grouper groupie]);
                string conditional = !contains_text(
                    get_property("banishedMonsters"),
                    "Mer-kin alphabetizer:Spring Kick")
                    ? if_equip($item[spring shoes]) : "";
                if (lowShiny == true)
                    conditional += ", equip congressional medal of insanity";
                if (item_amount($item[mer-kin dreadscroll]) == 0) {
                    cli_execute("maximize item drop, equip mer-kin scholar mask"
                        + ", equip mer-kin scholar tailpiece"
                        + ", equip monodent of the sea"
                        + ", equip blood cubic zirconia" + conditional);
                } else {
                    cli_execute("maximize -combat, equip mer-kin scholar mask"
                        + ", equip mer-kin scholar tailpiece"
                        + ", equip monodent of the sea" + conditional);
                    mood("noncom");
                }
                mood("itdrop");
                adv($location[mer-kin library]);
            }

            // Knucklebone for scroll 4
            if (get_property("dreadScroll4") == "0") {
                if (item_amount($item[mer-kin knucklebone]) == 0)
                    pullSequence($item[mer-kin knucklebone]);
                use($item[Mer-kin knucklebone]);
            }

            // Scroll 3 via deep dark visions
            // Fixed: was comparing string to int with == 0
            if (get_property("dreadScroll3") == "0") {
                cli_execute("maximize 50 spooky res, hp");
                while (get_property("dreadScroll3") == "0") {
                    restore_hp(1000);
                    use_skill($skill[deep dark visions]);
                }
            }
            if (available_amount($item[mer-kin prayerbeads]) < 3 && lowShiny == true){
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

            cli_execute("uneffect the sonata of sneakiness");
            if (contains_text(get_property("leprecondoInstalled"), "11")
                && item_amount($item[Leprecondo]) > 0)
                leprecondo("22,24,12,8,13,15,10,4,5,6");

            while (get_property("isMerkinHighPriest") == "false") {
                if (turns_played() <= 17 && my_id() == 2813285 && get_property("dreadScroll7") == "0"){
                    if (item_amount($item[mer-kin worktea]) > 0){
                        cli_execute("buy white rice");
                        eatSushi();
                    }else{
                        abort("On track for a god run, eat a sushi for the dreadscroll clue");
                    }
                }
                if (my_path().id == 0){
                    if (get_property("hasSushiMat") == "false"){
                        use($item[sushi-rolling mat]);
                    }
                    cli_execute("acquire mer-kin worktea;acquire white rice");
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
                            cli_execute("maximize item drop"
                                + ", equip shark jumper"
                                + ", equip scale-mail underwear, equip "
                                + divingHelmet()
                                + ", equip black glass"
                                + ", equip blood cubic zirconia"
                                + bathysphere()
                                + if_equip($item[M&ouml;bius ring]));
                            adv($location[The Caliginous Abyss]);
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

        // Healscroll pull
        if (item_amount($item[mer-kin healscroll]) == 0)
            pullSequence($item[mer-kin healscroll]);

        // YogUrt fight
        if (get_property("yogUrtDefeated") == "false") {
            cli_execute("acquire mer-kin mouthsoap, waterlogged scroll of healing, sea gel; cast cannel");
            if (available_amount($item[mer-kin prayerbeads]) < 3
                && !contains_text(get_property("_roninStoragePulls"), "3806"))
                pullSequence($item[mer-kin prayerbeads]);
            use_familiar($familiar[grouper groupie]);
            cli_execute("maximize spell damage percent, hot damage, cold damage"
                + ", spooky damage, sleaze damage, stench damage"
                + ", equip Mer-kin scholar mask, equip Mer-kin scholar tailpiece, -equip tiny yam cannon"
                + if_equip($item[bat wings])
                + if_equip($item[toy cupid bow]));
            equip($slot[acc1], $item[mer-kin prayerbeads]);

            // Equip as many prayerbeads as available, pull healing items for gaps
            int beads = available_amount($item[mer-kin prayerbeads]);
            if (beads >= 3) {
                equip($slot[acc2], $item[mer-kin prayerbeads]);
                equip($slot[acc3], $item[mer-kin prayerbeads]);
            } else {
                if (beads >= 2)
                    equip($slot[acc2], $item[mer-kin prayerbeads]);
                else {
                    if (item_amount($item[soggy used band-aid]) == 0)
                        pullSequence($item[soggy used band-aid]);
                }
                if (item_amount($item[New Age healing crystal]) == 0)
                    pullSequence($item[New Age healing crystal]);
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
                    buy_using_storage(to_item(to_int(num)));
                    take_storage(1, to_item(to_int(num)));
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
            if (to_int(get_property("_clubEmTimeUsed")) < 5)
                freeFight = ", equip legendary seal clubbing club";
            else if (to_int(get_property("_batWingsFreeFights")) < 5)
                freeFight = if_equip($item[bat wings]);
            cli_execute("maximize spell damage percent, mys, equip Mer-kin gladiator tailpiece, equip Mer-kin gladiator mask"
                + ", equip congressional medal of insanity" + freeFight);
            if (to_int(get_property("lastColosseumRoundWon")) >= 3
                && have_effect($effect[Up To 11]) == 0)
                cli_execute($effect[Up To 11].default);
            if (to_int(get_property("lastColosseumRoundWon")) >= 12) {
                if (item_amount($item[crayon shavings]) < 8
                    && item_amount($item[null-day exploit]) > 0
                    && have_effect($effect[null afternoon]) == 0)
                    use($item[null-day exploit]);
                if (have_familiar($familiar[foul ball])) {
                    use_familiar($familiar[foul ball]);
                    equip($item[little bitty bathysphere]);
                    if (have_item($item[bat wings]))
                        equip($item[bat wings]);
                } else if (have_item($item[Unwrapped knock-off retro superhero cape])){
                    cli_execute("retrocape heck kill;"
                        + " equip unwrapped knock-off retro superhero cape");
                }
                mood("colosseum");
            }
            adv($location[Mer-kin Colosseum]);
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
                cli_execute("acquire 8 crayon shaving");
            use_familiar($familiar[grouper groupie]);
            cli_execute("maximize damage absorption, mus, equip mer-kin gladiator mask, equip mer-kin gladiator tailpiece; recover hp"
                + if_equip($item[bat wings]));
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
            if (to_int(get_property("_batWingsFreeFights")) < 5) {
                cli_execute("maximize spell damage percent, mys" + if_equip($item[bat wings]) +";"
                    + " outfit mer-kin gladiator;"
                    + " equip acc3 congressional medal of insanity;");
            } else {
                cli_execute("maximize spell damage percent, mys;"
                    + " outfit mer-kin gladiator;"
                    + " equip acc3 congressional medal of insanity;"
                    + if_equip($item[unwrapped knock-off retro superhero cape])
                    + " retrocape heck kill");
            }
            codpiece("none");
            adv($location[Mer-kin Temple (center Door)]);
            adv($location[Mer-kin Temple (center Door)]);
        }
    } else if (my_path().id == 0 && boss == "Dad"){
        use_familiar($familiar[Tiny Plastic Santa Claus Skeleton]);
        cli_execute("maximize spell damage percent, equip goggles of loathing, equip stick-knife of loathing, equip scepter of loathing, equip jeans of loathing, equip treads of loathing, equip belt of loathing, equip little bitty bathy");
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
            if (my_id() == 2813285)
                cli_execute("postloop");
            spading();
        }
    }
}

// ─── MAIN ─────────────────────────────────────────────────────────────────────

void main() {
    try {
        set_property("choiceAdventureScript", "UnderTheSea_Choice.ash");
        initialization();
        seaMonkees();
        sorceress();
    } finally {
        set_property("choiceAdventureScript", choiceStorage);
        set_ccs("CCSStorage");
    }
}
