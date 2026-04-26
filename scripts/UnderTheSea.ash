import iotm.ash;

// ─── GLOBALS ──────────────────────────────────────────────────────────────────
string choiceStorage = get_property("choiceAdventureScript");
string seaFit;

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
    foreach ite in $items[aerated diving helmet, crappy Mer-kin mask,
        Mer-kin scholar mask, Mer-kin gladiator mask] {
        if (item_amount(ite) > 0 || have_equipped(ite))
            it = ite;
    }
    return it;
}

item tailpiece() {
    item it;
    foreach ite in $items[teflon swim fins, crappy Mer-kin tailpiece,
        Mer-kin scholar tailpiece, Mer-kin gladiator tailpiece] {
        if (item_amount(ite) > 0 || have_equipped(ite))
            it = ite;
    }
    return it;
}

// ─── SCHOLAR GEAR BUYER ───────────────────────────────────────────────────────
// Buys Mer-kin scholar mask and tailpiece from Grandma if not already owned.

void buyScholarGear() {
    if (available_amount($item[Mer-kin scholar mask]) == 0
        && !have_equipped($item[Mer-kin scholar mask])) {
        equip($slot[hat], $item[none]);
        equip($item[really\, really nice swimming trunks]);
        buy($coinmaster[Grandma Sea Monkey],1,$item[Mer-kin scholar mask]);
    }
    if (available_amount($item[Mer-kin scholar tailpiece]) == 0
        && !have_equipped($item[Mer-kin scholar tailpiece])) {
        equip($slot[pants], $item[none]);
        equip($item[really\, really nice swimming trunks]);
        buy($coinmaster[Grandma Sea Monkey],1,$item[Mer-kin scholar tailpiece]);
    }
}

// ─── CANDY RICH BLOCK MAP ─────────────────────────────────────────────────────
// Uses map to a candy-rich block before fighting if backup camera is equipped
// and last copyable monster is not a free fight monster.

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
        else
            abort("not enough maps");
    }
    candy("fight");
}

// ─── PULL SEQUENCE ────────────────────────────────────────────────────────────

void pullSequence(item it) {
    if (pulls_remaining() == 0)
        abort("Not enough pulls to pull " + it);
    if (!contains_text(get_property("_roninStoragePulls"), to_int(it))) {
        if (storage_amount(it) == 0)
            buy_using_storage(it);
        take_storage(1, it);
    }
}

// ─── MOOD ─────────────────────────────────────────────────────────────────────

void mood(string mod) {
    void applyEffects(effect [int] effects) {
        foreach i, ef in effects {
            if (to_skill(ef) != $skill[none] && !have_skill(to_skill(ef)))
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
                $effect[Leash of Linguini], $effect[Empathy], $effect[Spice Haze],
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
                if (have_effect(ef) == 0) cli_execute(ef.default);
            }
            break;
    }
}

// ─── FREE RUN / FREE KILL GEAR STRINGS ────────────────────────────────────────

string freeRun() {
    return have_effect($effect[Everything Looks Green]) == 0
        ? ", equip spring shoes" : "";
}

string freeKill() {
    if (have_effect($effect[Everything Looks Red]) == 0)
        return ", equip everfull dart";
    if (to_int(get_property("_chestXRayUsed")) < 3
        && have_item($item[Lil' Doctor&trade; bag]))
        return ", equip Lil' Doctor™ bag";
    if ((my_basestat($stat[submoxie]) - 22500) > BCZcost("SweatBulletsCasts"))
        return ", equip blood cubic zirconia";
    return "";
}

string if_equip(item it) {
    return available_amount(it) > 0 ? ", equip " + it : "";
}

// ─── SPADING ──────────────────────────────────────────────────────────────────

void spading() {
    int [string] lockkey = {
        "Mer-kin burglar": 313,
        "Mer-kin raider":  314,
        "Mer-kin healer":  315
    };
    buffer out;
    append(out, today_to_string());
    append(out, "," + to_string(my_id()));
    append(out, "," + my_class());
    append(out, "," + my_ascensions());
    for x from 1 to 8 {
        append(out, "," + get_property("dreadScroll" + x));
    }
    append(out, "," + to_string(lockkey[get_property("merkinLockkeyMonster")]));
    append(out, "," + get_property("stashboxFound"));

    if (my_id() == 2813285) {
        print(out);
        print(get_property("merkinCatalogChoices"));
        print(get_property("cardChoice1") + " and "
            + get_property("cardChoice2") + " and "
            + get_property("cardChoice3"));
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
    return num;
}

void teflon() {
    equip($item[mer-kin digpick]);
    equip($item[really\, really nice swimming trunks]);
    use_familiar($familiar[grouper groupie]);
    visit_url("mining.php?mine=3&which=" + mineNum());
    if (my_hp() == 0)
        cli_execute("restore HP");
    if (have_effect($effect[beaten up]) > 0)
        use_skill($skill[Tongue of the Walrus]);
}

// ─── SHADOW RIFT ──────────────────────────────────────────────────────────────

void shadowRift() {
    if (have_effect($effect[shadow waters]) == 0) {
        if (get_property("questRufus") == "unstarted")
            use($item[closed-circuit pay phone]);
        if (get_property("questRufus") == "started") {
            NCforce();
            adv1($location[Shadow Rift (The Misspelled Cemetary)], 0, "");
        }
        // Fixed: was comparing string property to boolean
        if (get_property("_seadentWaveUsed") == "false")
            use_skill($skill[Sea *dent: Summon a Wave]);
        use($item[closed-circuit pay phone]);
        adv1($location[Shadow Rift (The Misspelled Cemetary)], 0, "");
    } else {
        if (to_int(get_property("encountersUntilSRChoice")) > 9
            && get_property("questRufus") == "unstarted"
            && item_amount($item[Closed-circuit pay phone]) > 0) {
            cli_execute("maximize item drop, equip Flash Liquidizer Ultra Dousing Accessory,"
                + " equip bat wings, equip everfull dart holster, equip monodent of the sea");
            use($item[closed-circuit pay phone]);
        }
        if (get_property("questRufus") == "unstarted")
            use($item[closed-circuit pay phone]);
        if (have_effect($effect[shadow affinity]) > 0) {
            if (item_amount($item[sea lasso]) == 0
                && item_amount($item[sea cowbell]) > 0) {
                cli_execute("equip really nice swimming trunks; equip little bitty;"
                    + " monkeypaw item sea lasso");
            }
            if (item_amount($item[sea lasso]) == 0
                && item_amount($item[sea cowbell]) > 0)
                abort("need more lassos somehow");
            use_familiar($familiar[jill-of-all-trades]);
            if (to_int(get_property("lassoTrainingCount")) < 20
                && item_amount($item[sea cowbell]) > 0) {
                cli_execute("maximize item drop, equip Flash Liquidizer Ultra Dousing Accessory,"
                    + " equip bat wings, equip everfull dart holster, equip monodent of the sea,"
                    + " equip sea cowboy hat, equip sea chaps, equip toy cupid bow");
            } else {
                cli_execute("maximize item drop, equip Flash Liquidizer Ultra Dousing Accessory,"
                    + " equip bat wings, equip everfull dart holster, equip monodent of the sea,"
                    + " equip toy cupid bow");
            }
            adv1($location[Shadow Rift (The Misspelled Cemetary)], 0, "");
            if (get_property("_seadentWaveUsed") == "false"
                && have_effect($effect[shadow affinity]) > 0) {
                adv1($location[Shadow Rift (The Misspelled Cemetary)], 0, "");
                use_skill($skill[Sea *dent: Summon a Wave]);
            }
            if (get_property("encountersUntilSRChoice") == "0")
                adv1($location[Shadow Rift (The Misspelled Cemetary)], 0, "");
        }
    }
}

// ─── POST ADVENTURE ───────────────────────────────────────────────────────────

void post_adv() {
    if (get_property("_lastCombatLost") == "true"){
        use_skill($skill[Tongue of the Walrus]);
        set_property("_lastCombatLost","false");
        abort("It appears you lost the last combat, look into that");
    }

    if (my_adventures() == 0) {
        if (item_amount($item[astral pilsner]) == 0
            && item_amount($item[astral six-pack]) > 0) {
            use($item[astral six-pack]);
            use_skill($skill[the ode to booze]);
            drink($item[astral pilsner]);
        } else if (item_amount($item[astral pilsner]) > 0) {
            use_skill($skill[the ode to booze]);
            drink($item[astral pilsner]);
        } else {
            abort("no more easy diet");
        }
    }

    if (get_property("autumnatonQuestLocation") == "") {
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

    if (have_effect($effect[fishy]) == 0) {
        if (have_item($item[fishy pipe])
            && item_amount($item[closed-circuit pay phone]) > 0
            && have_item($item[Monodent of the Sea])
            && have_item($item[Platinum Yendorian Express Card])
            && (get_property("_shadowAffinityToday") == "false"
                || have_effect($effect[shadow affinity]) > 0)
            && (to_int(get_property("_bczSweatBulletsCasts")) < 7 || item_amount($item[mer-kin stashbox]) > 0)) {
            if (get_property("_fishyPipeUsed") == "false") {
                if (item_amount($item[fishy pipe]) == 0)
                    cli_execute("pull fishy pipe");
                use($item[fishy pipe]);
            } else if (get_property("_shadowAffinityToday") == "false"
                || have_effect($effect[shadow affinity]) > 0) {
                while (have_effect($effect[fishy]) == 0
                    && have_effect($effect[shadow affinity]) > 0)
                    shadowRift();
            }
        } else if (!contains_text(get_property("_roninStoragePulls"), "10360")) {
            pullSequence($item[fish sauce]);
            chew($item[fish sauce]);
        } else if (get_property("dreadScroll7") == "0"
            && item_amount($item[mer-kin worktea]) > 0
            && item_amount($item[mer-kin dreadscroll]) > 0) {
            cli_execute("buy white rice; create 1 beefy nigiri");
        } else {
            abort("Out of fishy");
        }
    }
    if (have_effect($effect[fishy]) == 0)
        abort("YOLO");
    if (have_item($item[bat wings])
        && (my_mp() < (my_maxmp() - 1000) || my_mp() < 150)) {
        equip($item[bat wings]);
        use_skill($skill[rest upside down]);
    }

    // VHS tape monster follow-up
    if (total_turns_played()
        >= to_int(get_property("spookyVHSTapeMonsterTurn")) + 8
        && get_property("spookyVHSTapeMonster") != "") {
        string resType = my_primestat() == $stat[mysticality] ? "hot" : "sleaze";
        location vhsLoc = my_primestat() == $stat[mysticality]
            ? $location[The Marinara Trench]
            : $location[The Dive Bar];
        cli_execute("maximize " + resType + " res, equip " + divingHelmet()
            + ", equip legendary seal clubbing, equip shark jumper,"
            + " equip scale-mail underwear; familiar grouper group");
        adv1(vhsLoc, 1, "");
    }

    // VHS tape recording window
    if (item_amount($item[spooky VHS tape]) > 0
        && get_property("spookyVHSTapeMonster") == ""
        && to_int(get_property("momSeaMonkeeProgress")) < 33
        && to_int(get_property("momSeaMonkeeProgress")) > 22) {
        if (to_int(get_property("_assertYourAuthorityCast")) < 3) {
            cli_execute("maximize item drop, equip " + divingHelmet()
                + ", equip shark jumper, equip scale-mail underwear, equip black glass,"
                + " equip Sheriff moustache, equip Sheriff badge, equip Sheriff pistol,"
                + " equip little bitty bathy");
        } else {
            cli_execute("maximize item drop, equip shark jumper, equip scale-mail underwear,"
                + " equip " + divingHelmet()
                + ", equip black glass, equip blood cubic zirconia,"
                + " equip peridot, equip little bitty");
        }
        adv1($location[The Caliginous Abyss], 0, "");
    }

    // Club em next week monster follow-up
    if (total_turns_played()
        >= to_int(get_property("clubEmNextWeekMonsterTurn")) + 8
        && get_property("clubEmNextWeekMonster") != "") {
        if (my_location() != $location[mer-kin elementary school]
            && !(my_location() == $location[mer-kin library]
                && have_effect($effect[Deep-Tainted Mind]) == 0)) {
            string [stat] clubRes = {
                $stat[mysticality]: "hot res",
                $stat[moxie]:       "sleaze res",
                $stat[muscle]:      "spooky res"
            };
            location [stat] clubLoc = {
                $stat[mysticality]: $location[The Marinara Trench],
                $stat[moxie]:       $location[The Dive Bar],
                $stat[muscle]:      $location[Anemone Mine]
            };
            stat ps = my_primestat();
            cli_execute("maximize " + clubRes[ps]
                + ", equip really nice swimming, equip legendary seal clubbing;"
                + " familiar grouper group");
            adv1(clubLoc[ps], 1, "");
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

// ─── ADVENTURE WRAPPER ────────────────────────────────────────────────────────
// Combines adv1() and post_adv() so call sites don't have to repeat both.

void adv(location loc, int turns, string spec) {
    adv1(loc, turns, spec);
    post_adv();
}

void adv(location loc) {
    adv(loc, 0, "");
}

// ─── INITIALIZATION ───────────────────────────────────────────────────────────

void initialization() {
    write_ccs(to_buffer("consult UnderTheSeaCCS.ash \n abort"), "temp");
    set_ccs("temp");
    set_property("battleAction", "custom combat script");

    // Tutorial completion
    if (get_property("questM05Toot") == "started") {
        council();
        visit_url("tutorial.php?action=toot");
        council();
        visit_url("place.php?whichplace=sea_oldman&action=oldman_oldman");
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
        autosell(item_amount(it), it);
    }

    // MAYAM rings
    if (get_property("_mayamSymbolsUsed") == "") {
        use_familiar($familiar[chest mimic]);
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

    if (get_property("_aprilBandInstruments") == "0")
        cli_execute("aprilband item tuba; aprilband item piccolo;"
            + " aprilband play piccolo; aprilband play piccolo;"
            + " aprilband play piccolo");

    if (get_property("_photoBoothEquipment") == "0")
        cli_execute("photobooth item sheriff pistol;"
            + " photobooth item sheriff moustache;"
            + " photobooth item sheriff badge");

    visit_url("inventory.php?action=skiduffel");

    if (get_property("_aprilShowerGlobsCollected") == "false")
        visit_url("inventory.php?action=shower");

    // First ascension of the day setup
    if (get_property("ascensionsToday") == "1") {
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

    // Gear and consumables
    equip($item[designer sweatpants]);

    if (item_amount($item[antique accordion]) == 0)
        buy($item[antique accordion]);

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
        if (item_amount(it) == 0
            && !contains_text(get_property("_roninStoragePulls"), to_int(it))) {
            if (storage_amount(it) == 0)
                buy_using_storage(it);
            take_storage(1, it);
        }
    }
}
// ─── GUILD UNLOCK ─────────────────────────────────────────────────────────────

void unlockGuild() {
    string conditional = baseballPlayers() < 9
        && available_amount($item[baseball diamond]) > 0
        ? if_equip($item[baseball diamond]) : "";

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
        // Muscle gets MP topped up first
        if (ps == $stat[muscle] && have_item($item[bat wings])) {
            equip($item[bat wings]);
            use_skill($skill[rest upside down]);
        }
        if (get_property(qprop) == "unstarted")
            visit_url("guild.php?place=challenge");
        use_familiar($familiar[Peace Turkey]);
        mood("itdrop");
        while (get_property(qprop) == "started") {
            cli_execute("maximize item drop, equip monodent of the sea,"
                + " equip mobius, equip everfull dart, equip spring shoes,"
                + " equip toy cupid bow, equip designer sweatpants"
                + freeRun() + conditional);
            adv1(questLoc[ps], 0, "");
        }
        visit_url("guild.php?place=challenge");
    }
}

// ─── BACKUP LASSO ─────────────────────────────────────────────────────────────
// Contingency if lasso training didn't finish via shadow rift

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
        + ", equip elf guard scuba, equip monodent of the sea,"
        + " equip sea cowboy hat, equip sea chaps; familiar grouper group");
    adv(lassoLoc[ps], 1, "");
}

// ─── SKATE PARK ───────────────────────────────────────────────────────────────

void skatePark() {
    NCforce();
    equip($item[really\, really nice swimming trunks]);
    if (item_amount($item[skate blade]) > 0)
        equip($item[skate blade]);
    adv($location[The Skate Park], 0, "");
}

// ─── SEA MONKEES ──────────────────────────────────────────────────────────────

void seaMonkees() {
    // ── Guild unlock prerequisite ─────────────────────────────────────────────
    if (get_property("questG03Ego") == "unstarted"
        && item_amount($item[Closed-circuit pay phone]) > 0) {
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
        while (have_effect($effect[Citizen of a Zone]) == 0
            && have_effect($effect[Everything Looks Red, White and Blue]) == 0) {
            use_familiar($familiar[patriotic eagle]);
            cli_execute("maximize item drop, equip really nice swimming trunks,"
                + " equip peridot of peril, equip Sheriff moustache,"
                + " equip Sheriff badge, equip Sheriff pistol,"
                + " equip Little bitty bathysphere"
                + if_equip($item[baseball diamond]));
            adv($location[An octopus's garden], 1, "");
        }
        // Collect pellet while RWB is active
        while (item_amount($item[wriggling flytrap pellet]) == 0
            && to_int(get_property("rwbMonsterCount")) > 0) {
            use_familiar($familiar[grouper groupie]);
            if (to_int(get_property("rwbMonsterCount")) == 1) {
                cli_execute("maximize item drop, equip really nice swimming trunks,"
                    + " equip McHugeLarge left pole, equip toy cupid bow"
                    + freeKill());
            } else {
                cli_execute("maximize item drop, equip really nice swimming trunks,"
                    + " equip Sheriff moustache, equip Sheriff badge,"
                    + " equip Sheriff pistol, equip toy cupid bow");
            }
            adv($location[An octopus's garden], 1, "");
        }
        // Banish fallback if pellet still didn't drop
        if (item_amount($item[wriggling flytrap pellet]) == 0) {
            print("Pellet failed to drop 3x, initiating banishes", "red");
            while (item_amount($item[wriggling flytrap pellet]) == 0) {
                use_familiar($familiar[grouper groupie]);
                if (to_int(get_property("_assertYourAuthorityCast")) < 3) {
                    cli_execute("maximize item drop, equip really nice swimming trunks,"
                        + " equip Sheriff moustache, equip Sheriff badge,"
                        + " equip Sheriff pistol, equip toy cupid bow");
                } else {
                    cli_execute("maximize item drop, equip really nice swimming trunks,"
                        + " equip toy cupid bow, equip "
                        + banishGear($location[An octopus's garden])
                        + freeKill());
                }
                adv($location[An octopus's garden], 1, "");
            }
        }
        if (item_amount($item[wriggling flytrap pellet]) > 0)
            use($item[wriggling flytrap pellet]);
    }

    if (get_property("questS02Monkees") == "started")
        visit_url("monkeycastle.php?who=1");

    // ── Step 1: Edgar Fitzsimmons wreck ──────────────────────────────────────
    while (get_property("questS02Monkees") == "step1") {
        if (get_property("noncombatForcerActive") != "true")
            NCforce();
        use_familiar($familiar[Patriotic eagle]);
        cli_execute("maximize item drop, equip really nice swimming,"
            + " equip mobius, equip little bitty bathy");
        adv($location[The Wreck of the Edgar Fitzsimmons], 0, "");
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
        if (have_effect($effect[Colorfully Concealed]) == 0) {
            pullSequence($item[mer-kin hidepaint]);
            use($item[mer-kin hidepaint]);
        }
        while (get_property("questS02Monkees") == "step4") {
            string conditional;
            if (baseballPlayers() < 9
                && available_amount($item[baseball diamond]) > 0) {
                conditional += if_equip($item[baseball diamond]);
            } else if ((my_primestat() == $stat[mysticality]
                && !contains_text(get_property("trackedMonsters"), "giant squid"))
                || (my_primestat() == $stat[moxie]
                && !contains_text(get_property("trackedMonsters"), "Mer-kin tippler"))) {
                conditional += ", equip McHugeLarge left pole";
            }
            if (baseballPlayers() >= 9)
                baseballD();
            conditional += ", equip mobius";

            string [stat] step4Res = {
                $stat[moxie]:       "sleaze res",
                $stat[mysticality]: "hot res",
                $stat[muscle]:      "spooky res"
            };
            location [stat] step4Loc = {
                $stat[moxie]:       $location[The Dive Bar],
                $stat[mysticality]: $location[The Marinara Trench],
                $stat[muscle]:      $location[Anemone Mine]
            };
            stat ps = my_primestat();
            mood(step4Res[ps]);
            cli_execute("maximize item drop, -100 combat, equip really nice swimming,"
                + " equip everfull dart, equip monodent of the sea,"
                + " equip toy cupid, equip blood cubic zirc" + conditional);
            adv(step4Loc[ps], 1, "");
        }
        pullSequence($item[mer-kin digpick]);
    }

    if (get_property("questS02Monkees") == "step5")
        cli_execute("grandpa grandma");

    // ── Step 6: Black Crayon Golem recall ────────────────────────────────────
    if (get_property("questS02Monkees") == "step6"
        && get_property("_monsterHabitatsMonster") == "") {
        use_familiar($familiar[peace turkey]);
        string locketEquip = have_item($item[Combat lover's locket])
            ? ", equip combat lovers" : "";
        if (haveLocketMonster[$monster[black crayon golem]]) {
            cli_execute("maximize item drop, equip legendary seal clubbing club,"
                + " equip mchugelarge left pole");
            cli_execute("reminisce black crayon golem");
        } else {
            cli_execute("maximize item drop, equip legendary seal clubbing club,"
                + " equip mchugelarge left pole" + locketEquip);
            cli_execute("c2t_megg extract black crayon golem");
            cli_execute("c2t_megg fight black crayon golem");
            run_combat();
        }
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
            && to_int(get_property("_monsterHabitatsRecalled")) == 2)
            use_familiar($familiar[patriotic eagle]);
        else
            use_familiar($familiar[Peace Turkey]);

        // Conditional gear
        string conditional;
        if (get_property("_monsterHabitatsFightsLeft") == "1"
            && have_effect($effect[Everything Looks Purple]) == 0
            && to_int(get_property("_monsterHabitatsRecalled")) == 2
            && have_item($item[roman candelabra]))
            conditional += ", equip roman candelabra";
        else if (baseballPlayers() < 8
            && available_amount($item[baseball diamond]) > 0)
            conditional += if_equip($item[baseball diamond]);

        if (get_property("lastCopyableMonster") == "Black Crayon Golem"
            && to_int(get_property("_backUpUses")) < 7
            && ($location[The Mer-Kin Outpost].turns_spent < 24
                || get_property("merkinLockkeyMonster") != ""))
            conditional += ", equip backup camera";
        else if (to_int(get_property("_bczSweatBulletsCasts")) < 9)
            conditional += ", equip blood cubic zirconia";
        else
            conditional += ", equip congressional medal of insanity";

        if (get_property("merkinLockkeyMonster") != "") {
            mood("noncom");
            cli_execute("maximize -combat, equip really nice swimming, equip monodent,"
                + " equip little bitty" + freeKill() + conditional);
        } else {
            cli_execute("maximize -combat, equip really nice swimming, equip monodent,"
                + " equip little bitty" + freeRun() + freeKill() + conditional);
        }
        adv($location[The Mer-Kin Outpost], 0, "");

        if (item_amount($item[Grandma's Note]) > 0
            && item_amount($item[Grandma's Fuchsia Yarn]) > 0
            && item_amount($item[Grandma's Chartreuse Yarn]) > 0)
            cli_execute("grandpa note");
    }

    refresh_status();

    // ── Stashbox use and trail unlock ─────────────────────────────────────────
    if (item_amount($item[Mer-kin stashbox]) == 1) {
        use($item[Mer-kin stashbox]);
        use($item[Mer-kin trailmap]);
        equip($item[really\, really nice swimming trunks]);
        cli_execute("grandpa currents");
    }

    // ── Old Guy quest ─────────────────────────────────────────────────────────
    if (get_property("questS01OldGuy") == "started") {
        use(item_amount($item[mer-kin thingpouch]), $item[mer-kin thingpouch]);
        if (item_amount($item[sand dollar]) < 50) {
            if (storage_amount($item[damp old wallet]) > 0) {
                take_storage(1, $item[damp old wallet]);
                use($item[damp old wallet]);
            } else {
                use($item[11-leaf clover]);
                adv($location[The Mer-Kin Outpost], 0, "");
            }
        }
        visit_url("monkeycastle.php?who=1");
        buy($coinmaster[Big Brother], 1, $item[black glass]);
        buy($coinmaster[Big Brother], 1, $item[damp old boot]);
        visit_url("place.php?whichplace=sea_oldman&action=oldman_oldman"
            + "&preaction=pickreward&whichreward=6313");
    }

    // ── Rusty rivet / diving helmet acquisition ───────────────────────────────
    if (item_amount($item[rusty rivet]) < 8 && divingHelmet() == $item[none]) {
        mood("itdrop");
        if (have_effect($effect[shadow waters]) == 0)
            shadowRift();

        // Get rusty porthole first via unholy diver
        if (item_amount($item[rusty porthole]) == 0) {
            if (baseballPlayers() >= 8)
                use_familiar($familiar[jill-of-all-trades]);
            else
                use_familiar($familiar[chest mimic]);
            cli_execute("maximize item, equip blood cubic zirconia,"
                + " equip toy cupid bow" + if_equip($item[baseball diamond]));
            print("Item drop rate is " + numeric_modifier("item drop"));
            mood("superitdrop");
            if (have_effect($effect[everything looks yellow]) == 0)
                cli_execute("parka dilophosaur; equip jurassic parka");

            // Fight unholy diver — locket first, then fax, then c2t
            if (haveLocketMonster[$monster[unholy diver]]) {
                cli_execute("reminisce unholy diver");
            } else {
                if (have_item($item[Combat lover's locket]))
                    equip($slot[acc3], $item[Combat lover's locket]);
                if (faxbot($monster[unholy diver])) {
                    use($item[photocopied monster]);
                    run_combat();
                } else if ($familiar[chest mimic].experience > 200) {
                    cli_execute("c2t_megg extract unholy diver");
                    cli_execute("c2t_megg fight unholy diver");
                    run_combat();
                } else {
                    abort("Need a method to find unholy diver");
                }
            }
        }

        if (baseballPlayers() >= 9)
            baseballD();

        use_familiar(item_amount($item[rusty rivet]) < 4
            ? $familiar[chest mimic]
            : $familiar[Jill-of-all-trades]);
        cli_execute("maximize item, equip blood cubic zirconia, equip toy cupid bow");
        if (have_effect($effect[everything looks yellow]) == 0)
            cli_execute("parka dilophosaur; equip jurassic parka");
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
    }
    if (divingHelmet() == $item[none])
        cli_execute("acquire aerated diving helmet");

    // ── Construct banish + habitat recall for cyberzone ───────────────────────
    if (to_int(get_property("momSeaMonkeeProgress")) < 24) {
        if (!contains_text(get_property("banishedPhyla"), "construct")) {
            if (get_property("madnessBakeryAvailable") == "false") {
                visit_url("shop.php?whichshop=armory&action=talk");
                run_choice(1);
            }
            while (!contains_text(get_property("banishedPhyla"), "construct")
                && $location[madness bakery].turns_spent < 3) {
                use_familiar($familiar[patriotic eagle]);
                cli_execute("maximize item drop, equip monodent of the sea");
                adv($location[madness bakery], 0, "");
            }
        }
        while (get_property("_monsterHabitatsMonster") != "eye in the darkness"
            && get_property("_monsterHabitatsMonster") != "slithering thing") {
            if (to_int(get_property("_monsterHabitatsFightsLeft")) > 0)
                abort("Need at least 1 free habitat recall"
                    + " and not currently occupied");
            use_familiar($familiar[peace turkey]);
            cli_execute("maximize item drop, equip " + divingHelmet()
                + ", equip shark jumper, equip scale-mail underwear,"
                + " equip black glass, equip peridot of peril,"
                + " equip little bitty bath" + freeKill());
            if (have_effect($effect[jelly combed]) == 0) {
                pullSequence($item[comb jelly]);
                use($item[comb jelly]);
            }
            adv($location[The Caliginous Abyss], 0, "");
        }
        while (to_int(get_property("_monsterHabitatsFightsLeft")) > 0
            && to_int(get_property("_cyberFreeFights")) < 10
            && to_int(get_property("momSeaMonkeeProgress")) < 40) {
            use_familiar($familiar[glover]);
            cli_execute("maximize moxie, equip shark jumper,"
                + " equip scale-mail underwear, equip monodent");
            if (my_buffedstat($stat[moxie]) < 500)
                abort("Need 500 moxie here to be safe");
            adv($location[Cyberzone 1], 0, "");
        }
    }

    // ── Coral Corral unlock — get sea cowbell ─────────────────────────────────
    if (get_property("corralUnlocked") == "true"
        && item_amount($item[sea cowbell]) == 0
        && get_property("seahorseName") == "") {
        if (have_effect($effect[shadow waters]) == 0)
            shadowRift();
        use_familiar($familiar[grouper groupie]);
        cli_execute("unequip blood cubic zirconia;"
            + " unequip peridot of peril; unequip heartstone");
        codpiece("blood cubic zirconia, heartstone");
        cli_execute("maximize item drop, equip shark jumper,"
            + " equip scale-mail underwear, equip " + divingHelmet()
            + ", equip backup camera, equip pro skateboard,"
            + " equip The Eternity Codpiece");
        mood("itdrop");
        adv($location[The Coral Corral], 0, "");
        codpiece("none");
    }

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
    if (to_int(get_property("encountersUntilSRChoice")) > 9
        && get_property("questRufus") == "unstarted"
        && item_amount($item[Closed-circuit pay phone]) > 0) {
        mood("itdrop");
        cli_execute("acquire oversized sparkler");
        cli_execute("maximize item drop, equip jurassic, equip toy cupid bow");
        if (item_amount($item[lump of loyal latite]) > 0)
            use($item[lump of loyal latite]);
        cli_execute("maximize item drop, equip Flash Liquidizer Ultra Dousing Accessory,"
            + " equip bat wings, equip everfull dart holster,"
            + " equip monodent of the sea");
        use($item[closed-circuit pay phone]);
    }

    // ── Teflon ore acquisition ────────────────────────────────────────────────
    if (item_amount($item[teflon ore]) == 0 && tailpiece() == $item[none]) {
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

    // ── Lasso training backup ─────────────────────────────────────────────────
    while (to_int(get_property("lassoTrainingCount")) < 20) {
        print("Lasso training didn't finish via shadow rift", "red");
        backupLasso();
    }

    // ── Seahorse taming ───────────────────────────────────────────────────────
    while (get_property("seahorseName") == "") {
        if (item_amount($item[sea cowbell]) < 3
            && !contains_text(get_property("_roninStoragePulls"), "4196"))
            pullSequence($item[sea cowbell]);

        use_familiar($familiar[grouper groupie]);
        string conditional;
        if (!contains_text(get_property("_perilLocations"), "199"))
            conditional += ", equip peridot of peril";
        if (have_item($item[Miniature crystal ball]))
            conditional += ", equip Miniature crystal ball";
        cli_execute("maximize item drop, equip really nice swimming" + conditional);

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

        adv($location[The Coral Corral], 0, "");

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
    while (have_effect($effect[shadow affinity]) > 0)
        shadowRift();
    if (get_property("encountersUntilSRChoice") == "0")
        adv($location[Shadow Rift (The Misspelled Cemetary)], 0, "");
    if (get_property("questRufus") == "step1") {
        use($item[closed-circuit pay phone]);
        adv($location[Shadow Rift (The Misspelled Cemetary)], 0, "");
    }

    // ── Buy crappy disguise if no tailpiece ───────────────────────────────────
    if (tailpiece() == $item[none]) {
        use(item_amount($item[mer-kin thingpouch]), $item[mer-kin thingpouch]);
        if (item_amount($item[sand dollar]) < 9) {
            if (item_amount($item[damp old wallet]) > 0)
                use($item[damp old wallet]);
            else {
                use($item[11-leaf clover]);
                adv($location[The Mer-Kin Outpost], 0, "");
            }
        }
        cli_execute("unequip sea chaps; unequip aerated diving helmet;"
            + " equip really nice swimming;"
            + " acquire crappy Mer-kin mask, crappy Mer-kin tailpiece");
    }

    // ── YogUrt preparation ────────────────────────────────────────────────────
    if (get_property("yogUrtDefeated") == "false") {
        if (get_property("isMerkinHighPriest") == "false") {
            // Farm mer-kin cheatsheets and unlock teacher
            while (item_amount($item[mer-kin cheatsheet]) < 9
                && get_property("merkinVocabularyMastery") == "0") {
                put_closet(item_amount($item[mer-kin hallpass]),
                    $item[mer-kin hallpass]);
                use_familiar($familiar[grouper groupie]);
                string conditional;
                conditional += to_int(get_property("_backUpUses")) < 11
                    ? ", equip backup camera"
                    : ", equip monodent of the sea";
                if (item_amount($item[mer-kin bunwig]) == 0
                    && !have_equipped($item[mer-kin bunwig]))
                    conditional += ", hat drop";
                string squintEquip = have_effect($effect[Steely-Eyed Squint]) > 0
                    ? "blood cubic zirc" : "blood cubic zirconia";
                cli_execute("maximize item drop, equip " + divingHelmet()
                    + ", equip " + tailpiece()
                    + ", equip legendary seal-clubbing club,"
                    + " equip " + squintEquip
                    + ", equip mobius, equip toy cupid" + conditional);
                if (get_property("merkinElementaryTeacherUnlock") == "false")
                    mood("noncom");
                mood("itdrop");
                useMapIfAvailable();
                adv($location[mer-kin elementary school], 0, "");
                put_closet(item_amount($item[mer-kin hallpass]),
                    $item[mer-kin hallpass]);
            }

            // Unlock teacher via NC if not yet done
            while (get_property("merkinElementaryTeacherUnlock") == "false") {
                cli_execute("maximize -combat, equip crappy Mer-kin tailpiece,"
                    + " equip crappy Mer-kin mask,"
                    + " equip legendary seal-clubbing club,"
                    + " equip blood cubic zirconia, equip mobius,"
                    + " equip toy cupid bow");
                mood("noncom");
                adv($location[mer-kin elementary school], 0, "");
                put_closet(item_amount($item[mer-kin hallpass]),
                    $item[mer-kin hallpass]);
            }

            // Get mer-kin bunwig if missing
            if (available_amount($item[mer-kin bunwig]) == 0) {
                cli_execute("maximize item drop, hat drop,"
                    + " equip crappy Mer-kin tailpiece, equip crappy Mer-kin mask,"
                    + " equip legendary seal-clubbing club,"
                    + " equip blood cubic zirconia, equip mobius,"
                    + " equip toy cupid bow");
                mood("itdrop");
                if (get_property("merkinElementaryTeacherUnlock") == "false")
                    mood("noncom");
                adv($location[mer-kin elementary school], 0, "");
                put_closet(item_amount($item[mer-kin hallpass]),
                    $item[mer-kin hallpass]);
            }

            take_closet(closet_amount($item[mer-kin hallpass]),
                $item[mer-kin hallpass]);

            // Vocabulary mastery grind
            while (to_int(get_property("merkinVocabularyMastery")) < 100) {
                if (item_amount($item[mer-kin wordquiz]) > 0) {
                    if (item_amount($item[mer-kin cheatsheet]) == 0)
                        pullSequence($item[mer-kin cheatsheet]);
                    use($item[mer-kin wordquiz]);
                } else if (to_int(get_property("merkinVocabularyMastery")) == 90
                    && item_amount($item[mer-kin wordquiz]) == 0) {
                    pullSequence($item[mer-kin wordquiz]);
                } else {
                    cli_execute("maximize item drop, equip " + divingHelmet()
                        + ", equip " + tailpiece() + ", equip mobius");
                    adv($location[mer-kin elementary school], 0, "");
                }

                // Library runs while Steely-Eyed Squint is active
                if (item_amount($item[mer-kin facecowl]) > 0
                    && item_amount($item[mer-kin waistrope]) > 0
                    && have_effect($effect[Steely-Eyed Squint]) > 0) {
                    buyScholarGear();
                    while ($location[mer-kin library].turns_spent < 4 && have_effect($effect[Steely-Eyed Squint]) > 0) {
                        string conditional;
                        if (to_int(get_property("_backUpUses")) < 11)
                            conditional += ", equip backup camera";
                        if (to_int(get_property("_batWingsSwoopUsed")) < 11)
                            conditional += ", equip bat wings";
                        if (!banishUsedAtYourLocation("Spring Kick"))
                            conditional += ", equip spring shoes";
                        cli_execute("maximize item drop, equip mer-kin scholar mask,"
                            + " equip mer-kin scholar tailpiece,"
                            + " equip monodent of the sea,"
                            + " equip blood cubic zirconia" + conditional);
                        useMapIfAvailable();
                        adv($location[mer-kin library], 0, "");
                    }
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
                    ? ", equip spring shoes" : "";
                if (item_amount($item[mer-kin dreadscroll]) == 0) {
                    cli_execute("maximize item drop, equip mer-kin scholar mask,"
                        + " equip mer-kin scholar tailpiece,"
                        + " equip monodent of the sea,"
                        + " equip blood cubic zirconia" + conditional);
                } else {
                    cli_execute("maximize -combat, equip mer-kin scholar mask,"
                        + " equip mer-kin scholar tailpiece,"
                        + " equip monodent of the sea" + conditional);
                    mood("noncom");
                    if (get_property("dreadScroll3") == "0")
                        pullSequence($item[mer-kin dreadscroll]);
                }
                mood("itdrop");
                adv($location[mer-kin library], 0, "");
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

            // Verify all non-scroll-7 clues are found
            for x from 1 to 8 {
                if (x == 7) continue;
                // Fixed: was comparing string to int, and had capital X bug on x==5
                if (get_property("dreadScroll" + x) == "0") {
                    if (x == 2) print("Missed the healscroll hint", "red");
                    if (x == 5) print("Missed the killscroll hint", "red");
                    abort("Somehow missed dreadScroll" + x + " clue");
                }
            }

            cli_execute("uneffect the sonata of sneakiness");
            if (contains_text(get_property("leprecondoInstalled"), "11")
                && item_amount($item[Leprecondo]) > 0)
                leprecondo("22,24,12,8,13,15,10,4,5,6");

            while (get_property("isMerkinHighPriest") == "false") {
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
                            cli_execute("maximize combat,"
                                + " equip Mer-kin scholar mask,"
                                + " equip Mer-kin scholar tailpiece"
                                + freeRun() + freeKill());
                            mood("combat");
                            print(numeric_modifier("combat rate"));
                            adv($location[Mer-kin Gymnasium], 0, "");
                            if (get_property("_skateBuff1") == "false")
                                visit_url("sea_skatepark.php?action=state2buff1");
                        } else if (get_property("questS02Monkees") == "step12") {
                            cli_execute("maximize item drop,"
                                + " equip shark jumper,"
                                + " equip scale-mail underwear, equip "
                                + divingHelmet()
                                + ", equip black glass,"
                                + " equip blood cubic zirconia,"
                                + " equip mobius, equip little bitty");
                            adv($location[The Caliginous Abyss], 0, "");
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
            && !contains_text($location[The Skate Park].noncombat_queue,
                "Holey Rollers"))
            skatePark();
        if (get_property("_skateBuff1") == "false")
            visit_url("sea_skatepark.php?action=state2buff1");

        // Healscroll pull
        if (item_amount($item[mer-kin healscroll]) == 0)
            pullSequence($item[mer-kin healscroll]);

        // YogUrt fight
        if (get_property("yogUrtDefeated") == "false") {
            cli_execute("acquire mer-kin mouthsoap,"
                + " waterlogged scroll of healing, sea gel; cast cannel");
            if (item_amount($item[mer-kin prayerbeads]) < 3
                && !contains_text(get_property("_roninStoragePulls"), "3806"))
                pullSequence($item[mer-kin prayerbeads]);
            cli_execute("maximize spell damage percent, hot damage, cold damage,"
                + " spooky damage, sleaze damage, stench damage,"
                + " equip Mer-kin scholar mask, equip Mer-kin scholar tailpiece,"
                + " equip bat wings, equip toy cupid");
            equip($slot[acc1], $item[mer-kin prayerbeads]);

            // Equip as many prayerbeads as available, pull healing items for gaps
            int beads = item_amount($item[mer-kin prayerbeads]);
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
            adv($location[Mer-kin Temple (Right Door)], 0, "");
        }
    }

    if (get_property("yogUrtDefeated") == "false")
        abort("Passing over yogUrt too early — rerun script");

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

    // ── Gladiator gear grind ──────────────────────────────────────────────────
    while (item_amount($item[Mer-kin gladiator mask]) == 0
        && item_amount($item[Mer-kin gladiator tailpiece]) == 0) {
        cli_execute("maximize combat, equip " + divingHelmet()
            + ", equip " + tailpiece() + freeRun() + freeKill());
        mood("combat");
        if (item_amount($item[Mer-kin thighguard]) == 0
            || item_amount($item[Mer-kin headguard]) == 0) {
            print(numeric_modifier("combat rate"));
            adv($location[Mer-kin Gymnasium], 0, "");
        }
        if (item_amount($item[Mer-kin thighguard]) > 0
            && item_amount($item[Mer-kin headguard]) > 0) {
            equip($slot[hat], $item[none]);
            equip($slot[pants], $item[none]);
            equip($item[really\, really nice swimming trunks]);
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
            freeFight = ", equip bat wings";
        cli_execute("maximize spell damage percent, mys,"
            + " equip Mer-kin gladiator tailpiece,"
            + " equip Mer-kin gladiator mask,"
            + " equip congressional medal of insanity" + freeFight);
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
                cli_execute("equip little bitty bathy; equip bat wings");
            } else {
                cli_execute("retrocape heck kill;"
                    + " equip unwrapped knock-off retro superhero cape");
            }
            mood("colosseum");
        }
        adv($location[Mer-kin Colosseum], 0, "");
    }

    if (to_int(get_property("lastColosseumRoundWon")) < 15)
        abort("Skipped over colosseum — rerun script");

    // ── Step 12: Caliginous Abyss ─────────────────────────────────────────────
    while (get_property("questS02Monkees") == "step12") {
        cli_execute("maximize item drop, equip shark jumper,"
            + " equip scale-mail underwear, equip " + divingHelmet()
            + ", equip black glass, equip blood cubic zirconia,"
            + " equip mobius, equip little bitty");
        adv($location[The Caliginous Abyss], 0, "");
    }

    // ── Shub-Jigguwatt ────────────────────────────────────────────────────────
    if (get_property("shubJigguwattDefeated") == "false") {
        use_familiar($familiar[grouper groupie]);
        cli_execute("maximize damage absorption, mus, equip bat wings, equip mer-kin gladiator mask, equip mer-kin gladiator tailpiece; recover hp");
        set_property("hpAutoRecoveryTarget", "1");
        set_property("mpAutoRecovery", "-0.05");
        set_property("mpAutoRecoveryTarget", "-0.05");
        cli_execute("recover hp; cast * empathy");
        adv($location[Mer-kin Temple (Left Door)], 0, "");
    }

    // ── Naughty Sorceress intro ───────────────────────────────────────────────
    if (get_property("questL13Final") == "unstarted") {
        if (to_int(get_property("batWingsFreeFights")) < 5) {
            cli_execute("maximize spell damage percent, mys;"
                + " outfit mer-kin gladiator;"
                + " equip acc3 congressional medal of insanity;"
                + " equip bat wings");
        } else {
            cli_execute("maximize spell damage percent, mys;"
                + " outfit mer-kin gladiator;"
                + " equip acc3 congressional medal of insanity;"
                + " equip unwrapped knock-off retro;"
                + " retrocape heck kill");
        }
        codpiece("none");
        adv($location[Mer-kin Temple (center Door)], 0, "");
        adv($location[Mer-kin Temple (center Door)], 0, "");
    }

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

// ─── MAIN ─────────────────────────────────────────────────────────────────────

void main() {
    try {
        set_property("choiceAdventureScript", "UnderTheSea_Choice.ash");
        initialization();
        seaMonkees();
        sorceress();
    } finally {
        set_property("choiceAdventureScript", choiceStorage);
    }
}
