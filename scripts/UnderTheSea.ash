import globals.ash;

// ─── PER-ACCOUNT CONFIG ───────────────────────────────────────────────────────
// Set with the mafia CLI; all default to off.
// uts_godRunGuard, uts_postloopCommand, uts_postLoopRunOutEagleBanish, uts_postLoopFarmPearls, uts_postLoopCloverFishy and uts_postLoopPrepCodpiece
// see the README for what each does.
familiar chosenFamiliar = $familiar[none]; //For kidoblivious

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
            else if (jellyfishReady())
                fam = $familiar[Space Jellyfish];
        }
        if (fam == $familiar[none]){
            fam = $familiar[grouper groupie];
        }
        use_familiar(fam);
        // Prince George goes on whichever familiar the item setup just settled on, and only the first time, since the costume is once a day and lasts until rollover.
        if (mod == "itdrop")
            mummery();
        return;
    }

    void mood(string mod) {
        effect [int] itdrop;
        int i;
        switch (mod) {
            case "superitdrop":
                foreach ef in $effects[Hustlin',Steely-Eyed Squint,Party Soundtrack,Best Pals]{
                    itdrop[i] = ef;
                    i += 1;
                }
            case "itdrop":
                foreach ef in $effects[Who's Going to Pay This Drunken Sailor?,Fat Leon's Phat Loot Lyric,Lubricating Sauce,Thoughtful Empathy,Singer's Faithful Ocelot,
                    Leash of Linguini,Empathy,donho's bubbly ballad,the ballad of richie thingfinder]{
                    itdrop[i] = ef;
                    i += 1;
                }
                foreach i, ef in itdrop {
                    if (to_skill(ef) != $skill[none] && !have_skill(to_skill(ef)))
                        continue;
                    if (ef == $effect[Party Soundtrack] && !have_item($item[Cincho de Mayo]))
                        continue;
                    if (have_effect(ef) == 0)
                        cli_execute(ef.default);
                }
                // Free +item from the Source Terminal. Guarded internally, so
                // calling it on every itdrop setup just tops the buff back up
                // when it lapses and is a no-op the rest of the time.
                sourceEnhance();
                // Same idea for the briefcase's +50% item tab buff: internally
                // guarded, so this just re-acquires it when the 50 turns lapse.
                briefcase();
                print("Item drop is " + numeric_modifier("item drop"));
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
                        if (ef == $effect[Apriling Band Patrol Beat] && (!have_item($item[apriling band helmet]) || total_turns_played() < to_int(get_property("nextAprilBandTurn")))) continue;
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

// ─── POST ADVENTURE ───────────────────────────────────────────────────────────
    void blackGlass(){
        use_familiar("itdrop");
        equip($item[really, really nice swimming trunks]);
        visit_url("monkeycastle.php?who=1");
        if (available_amount($item[black glass]) == 0) 
            buy($coinmaster[Big Brother], 1, $item[black glass]);
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
        if (have_effect($effect[really quite poisoned]) > 0)
            cli_execute("uneffect really quite poisoned");

        modes = "";
        if (get_property("NCtoC") == "true")
            set_property("NCtoC", "false");

        if (get_property("isMerkinHighPriest") == "false" && get_property("seahorseName") != "")
            dreadSeedCheck();
        if (get_property("autumnatonQuestLocation") == "" && item_amount($item[autumn-aton]) > 0)
            useAutumnaton();
        if (to_int(get_property("_universeCalculated")) < min(2, to_int(get_property("skillLevel144"))) && (reverse_numberology() contains 69))
            cli_execute("numberology 69");
        if (to_int(get_property("trainsetPosition")) >= to_int(get_property("lastTrainsetConfiguration")) + 42) {
            visit_url("campground.php?action=workshed");
            trainset();
        }
        if (have_effect($effect[resined]) == 0 && item_amount($item[inflammable leaf]) > 50)
            use($item[distilled resin]);
        if (item_amount($item[whirled peas]) >= 2)
            retrieve_item($item[handful of split pea soup]);

        if (my_path().id == 55){
            if (my_adventures() == 0) {
                if (item_amount($item[astral six-pack]) > 0) 
                    use($item[astral six-pack]);
                if (item_amount($item[astral pilsner]) > 0) {
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
                    if (get_fuel() == 0 && !pulledToday($item[pie man was not meant to eat])){
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
                } else if (highShiny() || lowShiny() && !pulledToday($item[Aldebaran sardines])){
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
                } else if (!pulledToday($item[fish sauce])) {
                    pullSequence($item[fish sauce]);
                    chew($item[fish sauce]);
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
            if (have_effect($effect[fishy]) == 0) {
                if (have_item($item[fishy pipe]) && get_property("_fishyPipeUsed") == "false"){
                    use($item[fishy pipe]);
                } else if (my_spleen_use() < spleen_limit()) {
                    retrieve_item($item[fish sauce]);
                    chew($item[fish sauce]);
                } else {
                    abort("get fishy");
                }
            }
        }

        if (have_item($item[bat wings])
            && (my_mp() < (my_maxmp() - 1000) || my_mp() < 150)) {
            equip($item[bat wings]);
            use_skill($skill[rest upside down]);
        }

        if ((get_property("dolphinItem") == "Mer-kin prayerbeads" || get_property("dolphinItem") == "rusty rivet") && 
            have_item($item[durable dolphin whistle]) && lowShiny())
            use($item[durable dolphin whistle]);
        if (my_meat( ) < 300){
            foreach it in $items[dull fish scale, rough fish scale]{
                autosell(item_amount(it), it );
            }
        }

        // VHS tape monster follow-up
        if (total_turns_played() >= to_int(get_property("spookyVHSTapeMonsterTurn")) + 8
            && get_property("spookyVHSTapeMonster") != "") {
            if (doSWord())
                use_familiar($familiar[sword of s words]);
            else
                use_familiar("itdrop");
            tempEquipment(pearlRes[ps],if_equip(divingHelmet()) + if_equip($item[legendary seal-clubbing club]) + "shark jumper,scale-mail underwear," + bathysphere($item[none]));
            adv1(pearlLoc[ps]);
        }

        // VHS tape recording window
        if (item_amount($item[spooky VHS tape]) > 0 && get_property("spookyVHSTapeMonster") == ""
            && to_int(get_property("momSeaMonkeeProgress")) < 33 && to_int(get_property("momSeaMonkeeProgress")) > 22) {
            use_familiar("itdrop");
            string conditional;
            if (!contains_text(get_property("banishedMonsters"), "school of many"))
                conditional += "monodent of the sea,";
            tempEquipment("item drop",if_equip(divingHelmet()) + "shark jumper,scale-mail underwear,black glass,"+ if_equip($item[peridot of peril]) 
                + freeKill() + bathysphere($item[toy cupid bow]) + conditional);
            adv1($location[The Caliginous Abyss]);
        }

        // Club em next week monster follow-up
        if (total_turns_played() >= to_int(get_property("clubEmNextWeekMonsterTurn")) + 8
            && get_property("clubEmNextWeekMonster") != "") {
            if (my_location() != $location[mer-kin elementary school]
                && !(my_location() == $location[mer-kin library])) {
                use_familiar("itdrop");
                tempEquipment(pearlRes[ps],swimmingTrunks() + "legendary seal-clubbing club," + bathysphere($item[none]));
                adv1(pearlLoc[ps]);
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

        if (get_property("questS01OldGuy") == "unstarted")
            visit_url("place.php?whichplace=sea_oldman&action=oldman_oldman");
        if (available_amount($item[black glass]) == 0 && item_amount($item[sand dollar]) > 13)
            blackGlass();

        if (to_int(get_property("_photoBoothEquipment")) < 3)
            foreach it in $items[sheriff pistol, sheriff moustache, sheriff badge]
                if (available_amount(it) == 0)
                    cli_execute("photobooth item " + it);
        if (to_int(get_property("_photoBoothEquipment")) < 3)
            abort("It seems that your clan may have an incomplete photobooth, join BAFH and rerun");

        if (my_path().id == 55){
            if (get_property("questM05Toot") == "started") {
                council();
                visit_url("tutorial.php?action=toot");
                council();
            }

            // Use/open daily items
            foreach it in $items[letter from King Ralph XI, pork elf goodies sack,sushi-rolling mat, 2002 Mr. Store Catalog] {
                if (it == $item[2002 Mr. Store Catalog]
                    && get_property("_2002MrStoreCreditsCollected") == "true")
                    continue;
                if (item_amount(it) > 0)
                    use(it, item_amount(it));
            }

            if (have_item($item[wardrobe-o-matic]))
                use($item[wardrobe-o-matic]);

            // Daily skills
            foreach sk in $skills[Aug. 24th: Waffle Day!, Summon Kokomo Resort Pass] {
                if (have_skill(sk))
                    use_skill(sk);
            }
            if (my_class() == $class[pastamancer]){
                //Do not bind Lasagmbie, damage will screw up boss fights
                foreach sk in $skills[Bind Spice Ghost,Bind Vermincelli,Bind Angel Hair Wisp]{
                    if (have_skill(sk)){
                        use_skill(sk);
                        break;
                    }
                }
            }

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

            // Other iotm related daily setup
            if (item_amount($item[tiny stillsuit]) > 0 && have_familiar($familiar[tickle-me emilio])){
                use_familiar($familiar[tickle-me emilio]);
                equip($item[tiny stillsuit]);
            }
            step("initialization: Mayam rings");
            if (get_property("_mayamSymbolsUsed") == "" && have_item($item[Mayam Calendar])) {
                if (!use_familiar($familiar[chest mimic]))
                    use_familiar("itdrop");
                cli_execute("mayam rings vessel yam cheese explosion;"
                    + " mayam rings fur lightning eyepatch yam;"
                    + " mayam rings eye meat yam clock");
            }
            if (get_property("leprecondoInstalled") == "0,0,0,0" && item_amount($item[Leprecondo]) > 0){
                if (highShiny())
                    leprecondo("10,11,12,24,4,5,6");
                else
                    leprecondo("22,24,12,11,10,4,5,6");
            }
            visit_url("campground.php?preaction=leaves");
            if (item_amount($item[S.I.T. Course Completion Certificate]) > 0 && get_property("_sitCourseCompleted") == "false")
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
            if (get_property("_aprilShowerGlobsCollected") == "false" && have_item($item[April Shower Thoughts shield]))
                visit_url("inventory.php?action=shower");
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
            foreach it in $items[mer-kin sneakmask, sea lasso, shark jumper,ten-leaf clover,large box,
                scale-mail underwear, Congressional Medal of Insanity,Flash Liquidizer Ultra Dousing Accessory] {
                if (available_amount(it) == 0 && !pulledToday(it)) {
                    if (it == $item[Flash Liquidizer Ultra Dousing Accessory] && !have_item($item[closed-circuit pay phone]))
                        continue;
                    if (it == $item[sea lasso] && (lowShiny() == true || (have_familiar($familiar[Sword of S Words]) && count_summons() >= 3)))
                        continue;
                    if (storage_amount(it) == 0){
                        if (it == $item[Congressional Medal of Insanity])
                            abort("Get yer own CMOI, ya filthy animal!");
                        buy_using_storage(it);
                    }
                    take_storage(1, it);
                }
            }
            if (available_amount($item[large box]) > 0)
                create($item[blessed large box]);
            if (available_amount($item[blessed large box]) > 0)
                use($item[blessed large box]);
        }
        // Asdon martin refuel with soda bread only after prism break
        if (get_workshed() == $item[Asdon Martin keyfob (on ring)] && !highShiny()
            && my_path().id == 0 && get_property("_missileLauncherUsed") == "false"
            && get_property("_utsMissileFailed") != "true"
            && get_fuel() < 100 && retrieve_item(17, $item[loaf of soda bread]))
            cli_execute("asdonmartin fuel 17 loaf of soda bread");
    }

// ─── Questing ─────────────────────────────────────────────────────────────
    void mineAnemone(){
        equip($item[mer-kin digpick]);
        equipSwimTrunks();
        use_familiar("itdrop");
        visit_url("mining.php?mine=3&which=" + mineNum());
        if (my_hp() == 0)
            cli_execute("restore HP");
        if (item_amount($item[teflon ore]) > 0){
            if (have_effect($effect[beaten up]) > 0 && have_skill($skill[Tongue of the Walrus]))
                use_skill($skill[Tongue of the Walrus]);
            else if (have_effect($effect[beaten up]) > 0)
                cli_execute("rest");
        }
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
        tempEquipment("combat", if_equip(divingHelmet()) + if_equip(tailpiece()) + delay() + freeKill() + bathysphere($item[none]) + conditional);
        mood("combat");
        if (get_property("noncombatForcerActive") == "true")
            abort("Sneak active while trying to adventure in gymnasium, get rid of it");
        adv($location[Mer-kin Gymnasium]);
    }

    void skatePark() {
        visit_url("sea_skatepark.php");
        if (get_property("skateParkStatus") != "war")
            return;
        NCforce();
        if (get_property("noncombatForcerActive") != "true" && (parkaForceAvailable() || leftSkiAvailable()))
            gymnasium();
        else if (!parkaForceAvailable() && !leftSkiAvailable() && have_item($item[allied radio backpack]))
            cli_execute("alliedradio sniper");
        if (pulls_remaining( ) > reservedPulls() && item_amount($item[skate blade]) == 0)
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
        tempEquipment("mys","shark jumper,scale-mail underwear,black glass," + if_equip($item[Congressional Medal of Insanity])
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
            codpiece("blood cubic zirconia, peridot of peril");
            tempEquipment("spooky res", swimmingTrunks() + if_equip($item[The Eternity Codpiece]) + "monodent of the sea," + bathysphere($item[none]));
            adv1($location[Anemone Mine]);
        } else if (!contains_text(get_property("_perilLocations"), "195")){
            mood("hotres");
            use_familiar("itdrop");
            codpiece("blood cubic zirconia, peridot of peril");
            tempEquipment("hot res", swimmingTrunks() + if_equip($item[The Eternity Codpiece]) + "monodent of the sea," + bathysphere($item[none]));
            adv1($location[the marinara trench]);
        } else if (!contains_text(get_property("_perilLocations"), "197")){
            mood("sleazeres");
            use_familiar("itdrop");
            codpiece("blood cubic zirconia, peridot of peril");
            tempEquipment("sleaze res", swimmingTrunks() + if_equip($item[The Eternity Codpiece]) + "monodent of the sea," + bathysphere($item[none]));
            adv1($location[the dive bar]); 
        } else if (!contains_text(get_property("_perilLocations"), "196")){
            mood("spookyres");
            use_familiar("itdrop");
            codpiece("blood cubic zirconia, peridot of peril");
            tempEquipment("spooky res", swimmingTrunks() + if_equip($item[The Eternity Codpiece]) + "monodent of the sea," + bathysphere($item[none]));
            adv1($location[Anemone Mine]);
        } else {
            tempEquipment("item drop","monodent of the sea");
            adv1($location[The Outskirts of Cobb's Knob]);
        }
        codpiece("none");
    }

    boolean summon(monster mon){
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
                
            } else if (item_amount($item[pocket wish]) > 0) {
                    tempEquipment("item drop",if_equip($item[legendary seal-clubbing club]) + if_equip($item[McHugeLarge left pole]));
                    cli_execute("genie monster " + mon);
                    run_combat();
            } else {
                return false;
            }
        }
        return true;
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

// Quest Handling Part 2
    void SWordLasso(){
        if (have_familiar($familiar[Sword of S Words]) && count_summons() >= 3 && to_float(get_property("swordOfSWordsMonster")) < 10 && 
            (highShiny() || !have_item($item[closed-circuit pay phone]))){
            use_familiar($familiar[Sword of S Words]);
            tempEquipment("item drop", baseball_equip() + freeKill());
            mood("itdrop");
            cli_execute("recover hp");
            summon($monster[sea cowboy]);
        } 
    }

    void unlockGuild(){
        if (get_property("questG03Ego") == "unstarted" && item_amount($item[Closed-circuit pay phone]) > 0 && my_path().id == 55 && !highShiny()) {
            step("phase: guild unlock");
            if (get_property(questProp[ps]) != "finished") {
                // Moxie shortcut — tearaway pants skip the grind
                if (ps == $stat[moxie] && have_item($item[tearaway pants])) {
                    equip($item[tearaway pants]);
                    visit_url("guild.php?place=challenge");
                } else {
                    if (get_property(questProp[ps]) == "unstarted")
                        visit_url("guild.php?place=challenge");
                    if (doSWord() == true)
                        use_familiar($familiar[Sword of S Words]);
                    else if (have_familiar($familiar[red-nosed snapper]))
                        use_familiar("itdrop");
                    else
                        use_familiar("-combat");
                    if (my_familiar() == $familiar[red-nosed snapper])
                        cli_execute("snapper fish");
                    while (get_property(questProp[ps]) == "started") {
                        tempEquipment("item drop","monodent of the sea," + if_equip($item[M&ouml;bius ring]) + if_equip($item[everfull dart holster])
                            + if_equip($item[spring shoes]) + if_equip($item[toy cupid bow]) + if_equip($item[designer sweatpants]) + baseball_equip());
                        mood("itdrop");
                        adv1(questLoc[ps]);
                    }
                    visit_url("guild.php?place=challenge");
                }
            }
            if (get_property("questG03Ego") == "unstarted") {
                visit_url("guild.php?place=ocg");
                visit_url("guild.php?place=ocg");
            }
        }
    }

    void flytrap(){
        step("phase: flytrap pellet (Sea Monkees start)");
        if (get_property("questS02Monkees") == "unstarted") {
            //SWord --> skeleton store for flytrap
            if (!highShiny() && have_familiar($familiar[sword of s words]) && available_amount($item[archaeologist's spade]) > 0){
                while (get_property("swordOfSWordsMonster") != "740"){
                    use_familiar($familiar[sword of s words]);
                    tempEquipment("item drop", swimmingTrunks() + if_equip($item[peridot of peril]) + baseball_equip() + bathysphere($item[toy cupid bow]) + freeKill());
                    adv($location[An octopus's garden]);
                }
                while (my_location() != $location[the skeleton store] && item_amount($item[wriggling flytrap pellet]) == 0){
                    if (get_property("skeletonStoreAvailable") == false)
                        visit_url("shop.php?whichshop=meatsmith&action=talk");
                    adv($location[The skeleton store]);
                    while(to_int(get_property("_archSpadeDigs")) < 11 && item_amount($item[wriggling flytrap pellet]) == 0){
                        maximize("item drop",false);
                        use($item[Archaeologist's Spade]);
                        if (my_location() != $location[the skeleton store])
                        break;
                    }
                }
            }
            // Get citizen/RWB ray on neptune flytrap
            if (have_familiar($familiar[patriotic eagle]) && item_amount($item[wriggling flytrap pellet]) == 0){
                while (have_effect($effect[Citizen of a Zone]) == 0 && have_effect($effect[Everything Looks Red, White and Blue]) == 0) {
                    use_familiar($familiar[patriotic eagle]);
                    string conditional;
                    if (!gotPeriled($location[An octopus's garden]))
                        conditional += if_equip($item[peridot of peril]);
                    tempEquipment("item drop", swimmingTrunks() + baseball_equip() + bathysphere($item[toy cupid bow]) + freeKill() + conditional);
                    adv($location[An octopus's garden]);
                }
            }
            while (item_amount($item[wriggling flytrap pellet]) == 0) {
                use_familiar("itdrop");
                string conditional;
                if (to_int(get_property("rwbMonsterCount")) <= 1 && !get_property("trackedMonsters").contains_text("Neptune flytrap"))
                    conditional += if_equip($item[McHugeLarge left pole]);
                else 
                    conditional += baseball_equip();

                if (to_int(get_property("rwbMonsterCount")) == 0 && !mapReady()){
                    print("Initiating banishes in Octopus Garden", "red");
                    if (highShiny())
                        conditional += "monodent of the sea,";
                }

                if (get_property("_assertYourAuthorityCast").to_int() < 3) 
                    conditional += "Sheriff moustache,Sheriff badge,Sheriff pistol,";

                tempEquipment("item drop", swimmingTrunks() + bathysphere($item[toy cupid bow]) + conditional + freeKill());
                if (to_int(get_property("rwbMonsterCount")) == 0)
                    mapMonster($location[An octopus's garden]);
                adv($location[An octopus's garden]);
                timeSpinnerRefight($location[An octopus's garden]);
            }
            if (item_amount($item[wriggling flytrap pellet]) > 0)
                use($item[wriggling flytrap pellet]);}
    }

    void fitzsimmons(){
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
    }

    void grandpa(){
        step("phase: Grandpa unlock (step 4)");
        if (get_property("questS02Monkees") == "step4") {
            use_familiar("-combat");
            if (have_effect($effect[Colorfully Concealed]) == 0 && lowShiny() == false) {
                if (pullSequence($item[mer-kin hidepaint]));
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
                } else if ((ps == $stat[mysticality] && !contains_text(get_property("trackedMonsters"), "giant squid"))
                        || (ps == $stat[moxie] && !contains_text(get_property("trackedMonsters"), "Mer-kin tippler"))) {
                    conditional += if_equip($item[McHugeLarge left pole]);
                }
                if (baseballPlayers() >= 9 && to_int(get_property("_baseballInnings")) <= 2)
                    baseballD();
                if (to_int(get_property("_bczSweatBulletsCasts")) < 9)
                    conditional += if_equip($item[blood cubic zirconia]);
                mood(pearlRes[ps]);
                tempEquipment("item drop, -100 combat","monodent of the sea," + swimmingTrunks() + delay()
                    + if_equip($item[M&ouml;bius ring]) + bathysphere($item[toy cupid bow]) + conditional);
                mood("-combat");
                adv(pearlLoc[ps]);
            }
        }
    }

    void golemRecall(){
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
    }

    void outpost(){
        step("phase: Mer-kin Outpost (stashbox / lockkey)");
        if (NCForceEstimate() >= 5 && have_effect($effect[driving waterproofly]) > 0)
            pillKeeper("free familiar");
        while ((item_amount($item[Mer-kin stashbox]) == 0  && get_property("corralUnlocked") == "false") || 
            contains_text("step6,step7,step8",get_property("questS02Monkees"))){

            if (my_path().id == 55){
                //Waste baseball if you don't have steely eyed squint and not a lot of NCforces since you may need to save the pull for a pearl necklace
                if (!have_skill($skill[Steely-Eyed Squint]) && NCForceEstimate() < 4 && contains_text(get_property("baseballTeam"),"773") && baseballPlayers() == 9)
                    baseballD();
                
                //If you can't do caliginous abyss in cyberrealm, then BoFa them into outpost
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

            if ($location[The Mer-Kin Outpost].turns_spent < 5)
                set_property("stashboxChecked", "0");
            if (contains_text(get_property("stashboxChecked"), "1")
                && contains_text(get_property("stashboxChecked"), "2")
                && contains_text(get_property("stashboxChecked"), "3"))
                abort("All stashbox locations checked but no stashbox — something went wrong");
            
            // Familiar choice
            if (get_property("_monsterHabitatsFightsLeft") == "1" && to_int(get_property("_monsterHabitatsRecalled")) == 2 && have_familiar($familiar[patriotic eagle]))
                use_familiar($familiar[patriotic eagle]);
            else if (doSWord() == true && $location[The Mer-Kin Outpost].turns_spent < 26 && 
                (get_property("_monsterHabitatsFightsLeft") == "0" || available_amount($item[crayon shavings]) >= 9)){
                use_familiar($familiar[Sword of S Words]);
                mood("itdrop");
            } else if ((highShiny() || lowShiny() || !have_item($item[closed-circuit pay phone])) && item_amount($item[pristine fish scale]) < 6)
                use_familiar("itdrop");
            else
                use_familiar("-combat");

            // Conditional gear
            string conditional;
            if (get_property("_monsterHabitatsFightsLeft") == "1" && have_effect($effect[Everything Looks Purple]) == 0
                && to_int(get_property("_monsterHabitatsRecalled")) == 2 && have_item($item[roman candelabra]))
                conditional += "roman candelabra,";
            else 
                conditional += baseball_equip();
            if (my_path().id == 0 && to_int(get_property("lassoTrainingCount")) < 20)
                conditional += "sea cowboy hat,sea chaps,";

            if (get_property("lastCopyableMonster") == "Black Crayon Golem" && to_int(get_property("_backUpUses")) < 7 && have_item($item[backup camera])
                && ($location[The Mer-Kin Outpost].turns_spent < 26 || get_property("merkinLockkeyMonster") != ""))
                conditional += "backup camera,";
            else if (to_int(get_property("_bczSweatBulletsCasts")) < 9)
                conditional += if_equip($item[blood cubic zirconia]);
            else
                conditional += if_equip($item[Congressional Medal of Insanity]);

            if ((get_property("_monsterHabitatsMonster") == "eye in the darkness" || get_property("_monsterHabitatsMonster") == "slithering thing") && get_property("_monsterHabitatsFightsLeft") > 0)
                conditional += "shark jumper,scale-mail underwear,elf guard scuba,";
            else 
                conditional += swimmingTrunks();

            if ((highShiny() || !have_item($item[closed-circuit pay phone]) || lowShiny()) && item_amount($item[pristine fish scale]) < 6)
                mood("itdrop");
            if (get_property("merkinLockkeyMonster") != "") {
                mood("-combat");
                tempEquipment("-combat", "monodent of the sea," + bathysphere($item[none]) + delay() + conditional);
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
        }
        refresh_status();
    }

    void unholyDiver(string str){
        step("phase: rusty rivets");
        while (item_amount($item[rusty rivet]) < 8 && to_slot(divingHelmet()) != $slot[hat]) {
            switch (str) {
                case "summon":
                    if (count_summons() > 0){
                        if (have_effect($effect[shadow waters]) == 0){
                            shadowRift();
                        }

                        int diverTries;
                        while ((item_amount($item[rusty rivet]) < 8 || item_amount($item[rusty porthole]) == 0 || available_amount($item[rusty broken diving helmet]) == 0)
                            && diverTries < 4) {
                            diverTries += 1;
                            if (diverForceReady() || item_amount($item[rusty rivet]) < 4){
                                if (!use_familiar($familiar[chest mimic]))
                                    use_familiar("itdrop");
                            } else {
                                if (!use_familiar($familiar[jill-of-all-trades]))
                                    use_familiar("itdrop");
                            }
                            tempEquipment("item drop", diverSaber() + if_equip($item[blood cubic zirconia]) + if_equip($item[baseball diamond]) + if_equip($item[toy cupid bow]));
                            if (!diverForceReady()){
                                mood("superitdrop");
                                yellowRayPrep();
                            }
                            if (item_amount($item[mimic egg]) > 0
                                && contains_text(get_property("mimicEggMonsters"), "745")){
                                cli_execute("c2t_megg fight unholy diver");
                                run_combat();
                                if (handling_choice() && last_choice() == 1387)
                                    run_choice(3);
                            } else if (timeSpinnerFight($monster[unholy diver])) {
                            } else if (count_summons() >= 1) {
                                if (summon($monster[unholy diver]))
                                    run_combat();
                                else
                                    break;
                            } else {
                                break;
                            }
                            if (baseballPlayers() >= 9 && contains_text(get_property("baseballTeam"),"745"))
                                baseballD();
                        }
                        if (baseballPlayers() >= 9 && contains_text(get_property("baseballTeam"),"745"))
                            baseballD();
                        while (item_amount($item[rusty rivet]) > 5 && item_amount($item[rusty rivet]) < 8 && get_property("_monkeyPawWishesUsed").to_int() < 5 && have_item($item[cursed monkey's paw]))
                            cli_execute("monkeypaw wish rusty rivet");
                    }
                case "greg":
                case "direct":
                    //Resource saving, the basic adventure in the wreck until you get enough rivets

                    string conditional;
                    if (total_turns_played( ) > to_int(get_property("_lastFitzsimmonsHatch")) + 20){
                        use_familiar("-combat");
                        tempEquipment("-combat",  if_equip(divingHelmet()) + swimmingTrunks() + bathysphere($item[toy cupid bow]));
                        mood("-combat");
                        if (NCForceEstimate() > 4)
                            NCforce();
                        adv($location[The Wreck of the Edgar Fitzsimmons]);
                    } else if (total_turns_played( ) < to_int(get_property("_lastFitzsimmonsHatch")) + 20){
                        use_familiar("itdrop");
                        if ((get_property("_monsterHabitatsMonster") == "eye in the darkness" || get_property("_monsterHabitatsMonster") == "slithering thing") && get_property("_monsterHabitatsFightsLeft") > 0){
                            conditional += "shark jumper,scale-mail underwear,elf guard scuba tank,";
                        } else 
                            conditional += swimmingTrunks();
                        if (!gotPeriled($location[The Wreck of the Edgar Fitzsimmons]))
                            if_equip($item[peridot of peril]);
                        if (banishGear($location[The Wreck of the Edgar Fitzsimmons]) == $item[spring shoes] && available_amount($item[spring shoes]) > 0){
                            conditional += "spring shoes,";
                        } else if (get_property("heartstoneBanishUnlocked") == "true")
                            conditional += if_equip($item[heartstone]);
                        conditional += saberEquip($location[The Wreck of the Edgar Fitzsimmons]);
                        conditional += cloakeEquip($location[The Wreck of the Edgar Fitzsimmons]);
                        conditional += champagneEquip($location[The Wreck of the Edgar Fitzsimmons]);
                        conditional += gloveEquip($location[The Wreck of the Edgar Fitzsimmons]);
                        tempEquipment("item drop","monodent of the sea," + conditional + bathysphere($item[toy cupid bow]));
                        if (get_property("beGregariousCharges") == 0 && str == "greg"){
                            if (pullSequence($item[Extrovermectin&trade;]))
                                chew($item[Extrovermectin&trade;]);
                        }
                        mood("itdrop");
                        mapMonster($location[The Wreck of the Edgar Fitzsimmons]);
                        adv($location[The Wreck of the Edgar Fitzsimmons]);
                    }
                    if (str == "greg" && get_property("beGregariousMonster") == "745")
                        return;
                    break;
            }
        }
        if (to_slot(divingHelmet()) != $slot[hat])
            retrieve_item($item[aerated diving helmet]);
    }

    void caliginous(string str){
        step("phase: Mom rescue (habitats / cyberzone)");
        int initialMomProgress = 24;
        if (!have_item($item[backup camera]))
            initialMomProgress += 4;
        if (!have_item($item[2002 Mr. Store Catalog]))
            initialMomProgress += 12;
        if (str == "cheap"){
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
        }
        if (to_int(get_property("momSeaMonkeeProgress")) < 24 && str == "cyberrealm"){
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
            while (to_int(get_property("momSeaMonkeeProgress")) < initialMomProgress)
                finishCaliginous();
        }
    }

    void corral(string str){
        if (get_property("corralUnlocked") != "true")
            abort("corral not unlocked");
        while (str == "drop" && get_property("_epicMcTwistUsed") == "false"){
            string conditional;
            if (have_effect($effect[shadow waters]) == 0 && lowShiny() == false)
                shadowRift();
            use_familiar("itdrop");
            if (my_familiar() == $familiar[red-nosed snapper])
                cli_execute("snapper mer-kin");
            cli_execute("unequip peridot of peril");
            codpiece("blood cubic zirconia, heartstone");
            if (get_property("_steelyEyedSquintUsed") == false)
                mood("superitdrop");
            if (available_amount($item[pro skateboard]) == 0)
                pullSequence($item[pro skateboard]);
            pullSequence($item[pulled yellow taffy]);
            if (to_int(get_property("_backUpUses")) < 11 && have_item($item[backup camera]) 
            && (get_property("lastCopyableMonster") == "eye in the darkness" || get_property("lastCopyableMonster") == "slithering thing")){
                conditional += "backup camera,";
                tempEquipment("item drop", "shark jumper,scale-mail underwear," + if_equip(divingHelmet())
                    + "pro skateboard," + if_equip($item[The Eternity Codpiece]) + "backup camera");
            } else if (have_skill($skill[steely-eyed squint]) && have_item($item[cursed monkey's paw])){
                pullSequence($item[software glitch]);
                tempEquipment("item drop", if_equip(divingHelmet()) + "pro skateboard," + if_equip($item[The Eternity Codpiece]));
            }
            mood("itdrop");
            adv($location[The Coral Corral]);
        }
        if (str == "drop" && item_amount($item[sea lasso]) < 5 && to_int(get_property("lassoTrainingCount")) < 20){
            while (!have_item($item[cursed monkey's paw]) && item_amount($item[sea lasso]) < 6){
                getMissingCorralItems();
                if (get_property("dolphinItem") == "sea lasso" && have_item($item[durable dolphin whistle]))
                    use($item[durable dolphin whistle]);
            }
            codpiece("none");
        }
        if (str == "collect" || str == "drop"){
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

    void shadowTeflon(){
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
                mineAnemone();
            if (item_amount($item[teflon ore]) == 0 && !pulledToday($item[lodestone])) {
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

            if ((my_turncount( ) > 25 || !have_item($item[Miniature crystal ball])) && !highShiny() && have_item($item[closed-circuit pay phone])){
                while ((have_effect($effect[shadow affinity]) > 0 || get_property("_shadowAffinityToday") == "false"))
                    shadowRift();
            }

            // ── Teflon ore second attempt (post-lodestone) ────────────────────────────
            if (item_amount($item[teflon ore]) == 0 && tailpiece() == $item[none]) {
                while (have_effect($effect[Loded]) > 0
                    && item_amount($item[teflon ore]) == 0)
                    mineAnemone();
                if (item_amount($item[teflon ore]) == 0) {
                    print("Failed to acquire teflon ore — can pull mining dynamite"
                        + " for one more try", "red");
                    while (item_amount($item[teflon ore]) == 0)
                        mineAnemone();
                }
            }
        }
    }

    void backupLasso() {
        // ── Lasso training backup ─────────────────────────────────────────────────
        while (to_int(get_property("lassoTrainingCount")) < 20) {
            if (have_item($item[closed-circuit pay phone]));
                print("Lasso training didn't finish via shadow rift", "red");
            if (!pulledToday($item[Elf Guard SCUBA tank]))
                cli_execute("pull elf guard scuba");
            if (item_amount($item[sea lasso]) == 0){
                equip($item[really, really nice swimming trunks]);
                equip($item[little bitty bathysphere]);
                monkeypaw($item[sea lasso]);
            }
            use_familiar("itdrop");
            if (available_amount($item[pristine fish scale]) < 6)
                mood("itdrop");
            tempEquipment(pearlRes[ps],"elf guard scuba tank,monodent of the sea,sea cowboy hat,sea chaps" + bathysphere($item[none]));
            adv(pearlLoc[ps]);
        }
    }

    void seahorsePrep(){
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
    }

    void seahorseTaming(){
        step("phase: seahorse taming");
        while (get_property("seahorseName") == "") {
            if (my_path().id == 0){
                retrieve_item(3, $item[sea cowbell]);
                retrieve_item($item[sea lasso]);
            }
            if (item_amount($item[sea cowbell]) < 3 && !pulledToday($item[sea cowbell]))
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
    }

    void postSeahorse(){
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
                        abort("get a total of "+available_amount($item[pristine fish scale])+" pristine fish scale, out of hermitage clovers");
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
                        abort("get a total of "+available_amount($item[pristine fish scale])+" pristine fish scale, out of hermitage clovers");
                    adv($location[the caliginous abyss]);
                }
                retrieve_item($item[crappy Mer-kin tailpiece]);
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
        }
    }

    void YogUrt(){
        // ── YogUrt preparation ────────────────────────────────────────────────────
        step("phase: Yog-Urt preparation");
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
                            if (get_property("skateParkStatus") == "war") {
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
            while (get_property("skateParkStatus") == "war")
                skatePark();
            if (get_property("_skateBuff1") == "false")
                visit_url("sea_skatepark.php?action=state2buff1");

            if (available_amount($item[mer-kin prayerbeads]) < 3 && (lowShiny() || pulls_remaining() == 0)){
                while (available_amount($item[mer-kin prayerbeads]) + item_amount($item[soggy used band-aid]) + item_amount($item[New Age healing crystal]) < 3){
                    farmPrayerbeads();
                }
            }

            // Healscroll pull
            if (item_amount($item[mer-kin healscroll]) == 0)
                pullSequence($item[mer-kin healscroll]);

            // YogUrt fight
            if (get_property("yogUrtDefeated") == "false") {
                cli_execute("acquire waterlogged scroll of healing, sea gel, Doc Galaktik's Pungent Unguent, Doc Galaktik's Homeopathic Elixir; cast cannel");
                if (delevelers() < 2 && !pulledToday($item[null-day exploit]) && pulls_remaining() > 0){
                    pullSequence($item[null-day exploit]);
                    use($item[null-day exploit]);
                } else if (delevelers() < 2){
                    while (delevelers() < 2)
                        getMissingCorralItems();
                }
                if (available_amount($item[mer-kin prayerbeads]) < 3 && pulledToday($item[mer-kin prayerbeads]))
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
                tempEquipment("moxie, hot damage, cold damage, spooky damage, sleaze damage, stench damage, -hp, -equip tiny yam cannon",
                    "Mer-kin scholar mask, Mer-kin scholar tailpiece," + bathysphere($item[toy cupid bow]) + conditional);
                equip($slot[acc1], $item[mer-kin prayerbeads]);

                if (available_amount($item[mer-kin prayerbeads]) >= 3) {
                    equip($slot[acc2], $item[mer-kin prayerbeads]);
                    equip($slot[acc3], $item[mer-kin prayerbeads]);
                } else {
                    if (available_amount($item[mer-kin prayerbeads]) >= 2)
                        equip($slot[acc2], $item[mer-kin prayerbeads]);
                    else {
                        if (item_amount($item[New Age healing crystal]) == 0 && !pulledToday($item[New Age healing crystal]))
                            pullSequence($item[New Age healing crystal]);
                        else if (item_amount($item[soggy used band-aid]) == 0 && !pulledToday($item[soggy used band-aid]))
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
                YogHPCheck();
                adv($location[Mer-kin Temple (Right Door)]);
            }
        }
    }

    void postYogUrt(){
        if (get_property("yogUrtDefeated") == "false" && my_path().id == 55)
            abort("Passing over yogUrt too early — rerun script");
        if (my_path().id == 55){
            // ── Post-YogUrt skate park / gladiator gear ───────────────────────────────
            while (get_property("skateParkStatus") == "war")
                skatePark();
            if (get_property("_skateBuff1") == "false")
                visit_url("sea_skatepark.php?action=state2buff1");

            // Late pulls. The comfort/cleanup items wait until Shub is dead:
            // they once ate the last pull slots right before a Shub retry needed
            // the null-day exploit.
            if (pulls_remaining() > 0) {
                if (item_amount($item[crayon shavings]) < 8)
                    pullSequence($item[null-day exploit]);
                foreach it in $items[peppermint parasol, ink bladder, Mer-kin pinkslip, stuffed yam stinkbomb, Louder Than Bomb, anchor bomb] {
                    if (!pulledToday(it)) 
                        pullSequence(it);
                    if (pulls_remaining() == 0) break;
                }
            }
        }

        if (my_path().id == 55 && get_property("spookyVHSTapeMonster") == ""){
            while (get_property("questS02Monkees") == "step12")
                finishCaliginous();
        }
    }

    void Shub(){
        if (my_path().id == 55 || (my_path().id == 0 && boss == "Shub")){
            // ── Gladiator gear grind ──────────────────────────────────────────────────
            step("phase: gymnasium (gladiator gear)");
            // || not &&: the colosseum outfit needs BOTH pieces, so keep looping
            // while either is missing.
            while (available_amount($item[Mer-kin gladiator mask]) == 0
                || available_amount($item[Mer-kin gladiator tailpiece]) == 0) {
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

            refresh_status();
            // ── Colosseum ─────────────────────────────────────────────────────────────
            step("phase: colosseum");
            // Gladiators are insta-kill immune (bricks and X-Rays glance, the
            // Asdon missile reads UNTARGETABLE), so the club is the only free
            // round in the building -- against immune monsters Club 'Em still
            // deals 30% max HP and frees the fight. Past its five casts, only
            // the bat wings proc can refund a round.
            while (to_int(get_property("lastColosseumRoundWon")) < 15) {
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

                if (to_int(get_property("lastColosseumRoundWon")) >= 3 && have_effect($effect[Up To 11]) == 0 && have_skill($skill[BCZ: Dial it up to 11]))
                    cli_execute($effect[Up To 11].default);
                if (to_int(get_property("lastColosseumRoundWon")) >= 6) {
                    if (item_amount($item[crayon shavings]) < 8
                        && item_amount($item[null-day exploit]) > 0
                        && have_effect($effect[null afternoon]) == 0)
                        use($item[null-day exploit]);
                }
                if (have_familiar($familiar[patriotic eagle]) && to_int(get_property("screechCombats")) > 0 && have_item($item[Congressional Medal of Insanity])) {
                    use_familiar($familiar[patriotic eagle]);
                }
                else if (have_familiar($familiar[foul ball])) {
                    use_familiar($familiar[foul ball]);
                }
                mood("colosseum");
                float coeff = (60 + my_buffedstat($stat[mysticality])/2.5)/(numeric_modifier("spell damage percent") + 1);
                tempEquipment(coeff + " spell damage percent, mys", "Mer-kin gladiator tailpiece,Mer-kin gladiator mask,"
                    + if_equip($item[Congressional Medal of Insanity]) + freeFight + bathysphere($item[none]));
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
            step("phase: Shub-Jigguwatt");
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
    }
    
    void finalBoss(){
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

    // Pearl progress pays its full 10% a combat only at 18+ of the zone's
    // element; below that the game pays partial credit and the ten-combat
    // pearl stretches. Checked every turn, not just at zone entry -- the res
    // buffs run out mid-zone -- re-upping expired buffs and refusing to farm
    // slower than the economics were priced at.
    void pearlResCheck(location zone) {
        string elem = substring(pearlZoneRes[zone], 0, index_of(pearlZoneRes[zone], " "));
        mood(elem + "res");
        mood("combat");
        if (numeric_modifier(elem + " resistance") < 18)
            abort("Pearl farming needs 18 " + elem + " resistance for full speed in "
                + zone + " and only " + to_int(numeric_modifier(elem + " resistance"))
                + " is up; add " + elem + " resistance gear or buffs and rerun.");
    }

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
        // "Maximizer failed" where pearlResCheck names the element and value,
        // and it runs before the first adventure.
        tempEquipment("200 " + pearlZoneRes[zone] + " 18 max, combat",
            swimmingTrunks() + bathysphere($item[none]));
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

    // uts_postLoopCloverFishy: top Fishy up with a Lucky! visit to The
    // Brinier Deepers -- The Haggling grants 20 turns, and works even at
    // 0 Fishy for 2 adventures instead of 1 -- so the walk keeps going
    // where it would otherwise stop. Aug 2nd casts are free Lucky!; after
    // those, an 11-leaf clover from inventory or, when mafia may buy from
    // the hermit, his daily three.
    boolean cloverFishy(location zone) {
        if (get_property("uts_postLoopCloverFishy") != "true")
            return false;
        if (my_adventures() < 3)
            return false;
        if (!can_adventure($location[The Brinier Deepers]))
            return false;
        // getLucky()'s clover branch exits the script when no clover can be
        // had, so only enter it on a guaranteed path: Lucky! already up, a
        // free Aug. 2nd cast, a clover in inventory, or hermit stock that
        // mafia is permitted to buy (autoSatisfyWithCoinmasters).
        boolean aug2Free = have_skill($skill[Aug. 2nd: Find an Eleven-Leaf Clover Day])
            && get_property("_aug2Cast") == "false"
            && to_int(get_property("_augSkillsCast")) < 5;
        if (have_effect($effect[Lucky!]) == 0 && !aug2Free
            && item_amount($item[11-leaf clover]) == 0
            && !(get_property("autoSatisfyWithCoinmasters") == "true"
                && to_int(get_property("_cloversPurchased")) < 3))
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
        // more visit collects The Haggling. At 0 Fishy it costs 2 turns.
        if (have_effect($effect[Fishy]) == 0
            && have_effect($effect[Lucky!]) > 0 && my_adventures() > 1)
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
            if (have_effect($effect[Fishy]) == 0)
                abort("uts_runOutEagleBanish: out of Fishy after " + spent
                    + " turns with the re-aim unfinished.");
            if (my_adventures() == 0) {
                // Same pilsner ladder as the in-run diet: crack the six-pack if
                // needed, Ode up, drink one. No pilsner left is a hard stop.
                if (item_amount($item[astral pilsner]) == 0
                    && item_amount($item[astral six-pack]) > 0)
                    use($item[astral six-pack]);
                if (item_amount($item[astral pilsner]) > 0) {
                    cli_execute("shrug Donho's Bubbly Ballad");
                    if (have_skill($skill[The Ode to Booze]))
                        use_skill($skill[the ode to booze]);
                    drink($item[astral pilsner]);
                } else
                    abort("uts_runOutEagleBanish: out of adventures and no astral pilsner left to drink.");
            }
            if (spent >= 40)
                abort("uts_runOutEagleBanish: the screech still isn't ready after 40 turns; something is wrong, bailing out.");
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
            if (have_effect($effect[Fishy]) == 0 && !cloverFishy(current))
                abort("postloop pearls: out of Fishy mid-zone after " + spent + " turns with "
                    + claimed + " pearls claimed; today's zone progress won't survive rollover.");
            if (my_adventures() == 0)
                abort("postloop pearls: out of adventures mid-zone after " + spent + " turns with "
                    + claimed + " pearls claimed; today's zone progress won't survive rollover.");
            if (spent >= 90)
                abort("postloop pearls: 90 turns spent without finishing; something is wrong, bailing out.");
            pearlResCheck(current);
            adv1(current);
            spent += 1;
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

// ─── SEA MONKEES ──────────────────────────────────────────────────────────────
void seaMonkees() {
    //Use Sword of S Words to get sea lasso early if you can't use shadow rift to lasso train
    SWordLasso();
    //Unlock guild to gain access to shadow brick if you have payphone
    unlockGuild();
    //Priming with post_adv in case there was an abort in a combat
    post_adv();

    flytrap();

    if (get_property("questS02Monkees") == "started")
        visit_url("monkeycastle.php?who=1");

    fitzsimmons();

    if (get_property("questS02Monkees") == "step2") {
        visit_url("monkeycastle.php?who=2");
        visit_url("monkeycastle.php?who=1");
    }

    grandpa();
    if (get_property("questS02Monkees") == "step5")
        cli_execute("grandpa grandma");

    golemRecall();

    outpost();

    // ── Stashbox use and trail unlock ─────────────────────────────────────────
    if (item_amount($item[Mer-kin stashbox]) == 1) {
        use($item[Mer-kin stashbox]);
        use($item[Mer-kin trailmap]);
        equipSwimTrunks();
        cli_execute("grandpa currents");
    }

    //If you need to spend pulls on NCForces, save some pulls by getting prayerbeads now while you have -combat on
    pullPrayerbead();
    while (NCForceEstimate() < 4 && available_amount($item[mer-kin prayerbeads]) < 2)
        farmPrayerbeads();

    if (get_property("questS01OldGuy") == "started") 
        oldGuy();

    // If high shiny --> s word sea cow --> (scuba) caliginous --> max item mctwist unholy diver (or Feesh and refract merkin) and lasso as necessary --> finish corral
    // Mid shiny if has cyberrealm and shadow rift and bcz --> max item summon unholy diver --> cyberrealm caliginous --> backup/software glitch mctwist sea cow --> shadow rift lasso --> delay until seahorse
    // Mid shiny no cyberrealm, yes shadow rift and bcz --> greg unholy diver --> 1 turn in caliginous if has backup cam --> max item backp/software glitch taffy mctwist corral --> shadow rift lasso --> unholy diver --> delay until seahorse --> caliginous
    // Mid shiny yes cyberrealm, no shadow rift, yes bcz --> open unholy diver --> cyberrealm caliginous --> max item backp/software glitch mctwist corral --> unholy diver --> delay until seahorse
    // Mid shiny yes yes no --> mctwist taffy unholy diver --> cyberrealm caliginous --> max item corral until necessary items are collected --> lasso shadow rift --> finish corral
    // no no yes --> greg unholy diver --> 1 turn in caliginous if has backup cam --> max item backp/software glitch mctwist corral --> caliginous --> finish lasso --> finish corra
    // no no no --> sea cowboy  --> unholy diver mctwist taffy lasso --> caliginous abyss --> finish corral
    if (get_property("seahorseName") == ""){
        if (my_path().id == 0){
            retrieve_item($item[aerated diving helmet]);
        } else if (highShiny()){
            caliginous("cheap");
            unholyDiver("direct");
        } else if (MomNCyber() && lassoShadow() && available_amount($item[blood cubic zirconia]) > 0){
            unholyDiver("summon");
            caliginous("cyberrealm");
            corral("drop");
        } else if (available_amount($item[blood cubic zirconia]) > 0){
            unholyDiver("greg");
            corral("drop");
            if (MomNCyber())
                caliginous("cyberrealm");
            else
                caliginous("cheap");
        } else {
            corral("collect");
            unholyDiver("direct");
            if (MomNCyber())
                caliginous("cyberrealm");
            else
                caliginous("cheap");
        }
    }
    shadowTeflon();
    backupLasso();
    seahorsePrep();
    seahorseTaming();
    postSeahorse();
    YogUrt();
    postYogUrt();
    Shub();
    finalBoss();

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
    } finally {
        set_property("choiceAdventureScript", choiceStorage);
        set_property("choiceAdventure1387", choice1387Storage);
        set_ccs(CCSStorage);
        print("Ending UnderTheSea");
    }
}
