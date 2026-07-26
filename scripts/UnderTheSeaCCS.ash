import iotm.ash;
import underthesea.ash;

// Attempt a free kill using available skills/items.
// Pass drop=true to skip items that interfere with item drops.
void free_kill(string ptext, boolean drop) {
    if (highShiny()){
        if (contains_text(ptext, "Darts: Aim for the Bullseye"))
            use_skill($skill[Darts: Aim for the Bullseye]);
        return;
    }
    if (get_property("_curveballMonster") == last_monster()
        && to_int(get_property("_curveballFightsLeft")) > 0)
        return;

    foreach freeskill in $skills[Spit jurassic acid, Assert your Authority,
        Club 'Em Back in Time, Darts: Aim for the Bullseye,
        BCZ: Sweat Bullets, Chest X-Ray, Shattering Punch, Gingerbread Mob Hit] {
        if (freeskill == $skill[Club 'Em Back in Time]
            && (my_location() != $location[mer-kin colosseum] || lowShiny))
            continue;
        if (freeskill == $skill[BCZ: Sweat Bullets]
            && (my_basestat($stat[submoxie]) - 22500) < BCZcost("SweatBulletsCasts"))
            continue;
        if (contains_text(ptext, to_string(freeskill)))
            use_skill(freeskill);
    }

    foreach freecombat in $items[shadow brick, groveling gravel] {
        if (item_amount(freecombat) == 0) continue;
        if (freecombat == $item[groveling gravel] && drop) continue;
        if (freecombat == $item[shadow brick]
            && to_int(get_property("_shadowBricksUsed")) == 13) continue;
        throw_item(freecombat);
    }
}

// Attempt a free run using available skills/items.
// Pass banish=true to allow banishing skills/items.
void free_run(string ptext, boolean banish) {
    if (get_property("_curveballMonster") == last_monster()
        && to_int(get_property("_curveballFightsLeft")) > 0)
        return;

    if (have_equipped($item[greatest american pants]) && to_int(get_property("_navelRunaways")) < 3)
        runaway();

    foreach freeskill in $skills[spring away, Bowl a Curveball, creepy grin, Throw Latte on Opponent, Feel Hatred, snokebomb] {
        if (!contains_text(ptext, to_string(freeskill))) continue;
        if (!banish && $skills[snokebomb, Bowl a Curveball, Feel Hatred, Throw Latte on Opponent] contains freeskill) continue;
        if (banish && banishUsedAtYourLocation("snokebomb") && freeskill == $skill[snokebomb]) continue;
        if ($locations[The Outskirts of Cobb's Knob, The Sleazy Back Alley,
            The Haunted Pantry] contains my_location()
            && freeskill == $skill[snokebomb])
            return;
        if (banish && freeskill == $skill[spring away])
            use_skill($skill[spring kick]);
        use_skill(freeskill);
    }

    foreach freecombat in $items[glob of Blank-Out,peppermint parasol, anchor bomb,
        stuffed yam stinkbomb, handful of split pea soup,
        mer-kin pinkslip, ink bladder] {
        if (item_amount(freecombat) == 0) continue;
        if (!banish && $items[anchor bomb, stuffed yam stinkbomb,
            handful of split pea soup] contains freecombat) continue;
        if (freecombat == $item[peppermint parasol]
            && to_int(get_property("parasolUsed")) >= 3) continue;
        if (freecombat == $item[mer-kin pinkslip]
            && last_monster().phylum != $phylum[mer-kin]) continue;
        throw_item(freecombat);
    }
}

// Returns true if this monster provides a free fight
boolean free_monster(monster mob) {
    return $monsters[black crayon golem, time cop,sausage goblin,
        kid who is too old to be Trick-or-Treating,
        suburban security civilian, vandal kid] contains mob;
}

// BCZ refracted gaze helper — checks stat threshold before casting
boolean bcz_gaze_ready() {
    return (my_basestat($stat[submysticality]) - 40000) > BCZcost("RefractedGazeCasts");
}

// Finish off the enemy with saucegeyser, guarded against infinite loops
void cleanUp() {
    int loopCount = 0;  // declared outside loop so the guard actually works
    while (current_round() > 0) {
        int round = current_round();
        if (have_skill($skill[saucegeyser])){
            use_skill($skill[saucegeyser]);
        } else {
            if (have_skill($skill[Stuffed Mortar Shell]))
                use_skill($skill[Stuffed Mortar Shell]);
            use_skill($skill[saucestorm]);
        }
        if (round == current_round()) {
            loopCount += 1;
            if (loopCount > 3)
                abort("May be stuck in an infinite saucegeyser loop");
        }
        if (my_mp() < 24)
            break;
    }
}

void attackCleanUp() {
    int loopCount = 0;
    while (current_round() > 0) {
        int round = current_round();
        attack();
        if (round == current_round()) {
            loopCount += 1;
            if (loopCount > 3)
                abort("May be stuck in an infinite attack loop");
        }
    }
}

item yogDeleveler(){
    if (my_buffedstat($stat[moxie]) + 10 > monster_attack( ) )
        return $item[none];
    foreach it in $items[Mer-kin mouthsoap,crayon shavings,table tennis ball,Mer-kin mouthsoap,sea cowbell]{
        if (item_amount(it) > 0 && !contains_text(get_property("_lastCombatActions"),to_int(it)))
            return it;
    }
    abort("Missing delever... oops");
    return $item[none];
}

item yogHealing(){
    foreach it in $items[sea gel,waterlogged scroll of healing,mer-kin healscroll,soggy used band-aid,New Age healing crystal]{
        if (item_amount(it) > 0 && !contains_text(get_property("_lastCombatActions"),to_int(it)))
            return it;
    }
    abort("Missing healing... oops");
    return $item[none];
}

item bangA(){
    foreach it in $items[milky potion, swirly potion, bubbly potion, smoky potion, cloudy potion, effervescent potion, fizzy potion, dark potion, murky potion]{
        if (available_amount(it) > 0)
            return it;
    }
    return $item[none];
}

item bangB(){
    foreach it in $items[milky potion, swirly potion, bubbly potion, smoky potion, cloudy potion, effervescent potion, fizzy potion, dark potion, murky potion]{
        if (available_amount(it) > 0 && it != bangA())
            return it;
    }
    return $item[none];
}

// ─── MAIN CCS ─────────────────────────────────────────────────────────────────

void main(int round, monster mob, string page_text) {
    while (available_amount($item[murky potion]) > 0 && current_round() > 0 && current_round() < 5 && mob != $monster[sea cowboy]){
        if (have_skill($skill[Ambidextrous Funkslinging]))
            throw_items(bangA(),bangB());
        else
            throw_item(bangA());
    }
    if ((highShiny() || !have_item($item[closed-circuit pay phone])) && item_amount($item[sea lasso]) > 5 && my_location().environment == "underwater" && to_int(get_property("lassoTrainingCount")) < 6)
        throw_item($item[sea lasso]);
    // ── Location-based combat logic ───────────────────────────────────────────
    switch (my_location()) {
        case $location[The Skeleton Store]:
            cleanUp();
            break;
        case $location[The Outskirts of Cobb's Knob]:
        case $location[The Sleazy Back Alley]:
        case $location[The Haunted Pantry]:
            if (get_property("_curveballFightsLeft").to_int() > 0 && get_property("_curveballMonster") == "some fish"){
                use_if_have_skill(page_text, $skill[Sea *dent: Talk to Some Fish]);
                cleanUp();
            }
            if (!free_monster(mob))
                free_run(page_text, false);
            use_if_have_skill(page_text, $skill[Sea *dent: Talk to Some Fish]);
            use_if_have_skill(page_text, $skill[Prepare to reanimate your Foe]);
            darts();
            cleanUp();
            break;

        case $location[Madness Bakery]:
            if (!have_skill($skill[%fn, Release the Patriotic Screech!]))
                abort("Need patriotic eagle");
            use_skill($skill[%fn, Release the Patriotic Screech!]);
            use_if_have_skill(page_text, $skill[Sea *dent: Talk to Some Fish]);
            free_kill(page_text, false);
            cleanUp();
            break;

        case $location[Shadow Rift (The Misspelled Cemetary)]:
            if (my_primestat() == $stat[moxie]) steal();
            if (get_property("_seadentWaveUsed") == "true"
                && to_int(get_property("lassoTrainingCount")) < 20
                && item_amount($item[sea lasso]) > 0)
                throw_item($item[sea lasso]);
            if (mob == $monster[shadow slab]) {
                if (item_amount($item[Septapus summoning charm]) > 0)
                    throw_item($item[Septapus summoning charm]);
                use_if_have_skill(page_text, $skill[swoop like a bat]);
                use_if_have_skill(page_text, $skill[Perpetrate Mild Evil]);
                while (to_int(get_property("_douseFoeUses")) < 3
                    && get_property("_douseFoeSuccess") == "false"
                    && current_round() < 25)
                    use_skill($skill[douse foe]);
            }
            if (mob == $monster[tumbleweed])
                abort("Unexpected mob encountered in shadow rift");
            if (!can_still_steal() || available_amount($item[pristine fish scale]) < 6)
                use_if_have_skill(page_text, $skill[Sea *dent: Talk to Some Fish]);
            darts();
            cleanUp();
            break;

        case $location[an octopus's garden]:
            if (have_effect($effect[Citizen of a Zone]) == 0 && my_familiar() == $familiar[patriotic eagle])
                use_skill($skill[%fn, let's pledge allegiance to a Zone]);
            if (mob == $monster[neptune flytrap]) {
                if (have_effect($effect[Everything Looks Red, White and Blue]) == 0 && my_familiar() == $familiar[patriotic eagle])
                    use_skill($skill[%fn, fire a Red, White and Blue Blast]);
                if (my_familiar() == $familiar[sword of s words])
                    use_skill($skill[%fn, kill a lot of these guys]);
                darts();
                if ((have_equipped($item[McHugeLarge left pole]) || available_amount($item[mchugelarge left pole]) == 0)
                    && !contains_text(get_property("trackedMonsters"), "Neptune flytrap")) {
                    foreach sk in $skills[transcendent olfaction,
                        Gallapagosian Mating Call, MCHUGELARGE SLASH]
                        use_if_have_skill(page_text, sk);
                }
                free_kill(page_text, true);
                cleanUp();
            } else if (!free_monster(mob)) {
                if (have_equipped($item[spring shoes]) && !banishUsedAtYourLocation("Spring Kick") && highShiny()) {
                    use_skill($skill[spring kick]);
                    use_skill($skill[Sea *dent: Talk to Some Fish]);
                } else {
                    free_run(page_text, true);
                }
            }
            cleanUp();
            break;
        case $location[The Wreck of the Edgar Fitzsimmons]:
            if (mob != $monster[unholy diver]){
                free_run(page_text, true);
                if (mob == $monster[Mer-kin scavenger]){
                    if (have_equipped($item[spring shoes]))
                        use_skill($skill[spring kick]);
                    else 
                        use_if_have_skill(page_text,$skill[Sea *dent: Throw a Lightning Bolt]);
                    use_skill($skill[Sea *dent: Talk to Some Fish]);
                }
                if (mob == $monster[Mine crab]){
                    use_skill($skill[Heartstone: %banish]);
                    use_if_have_skill(page_text,$skill[Sea *dent: Throw a Lightning Bolt]);
                }
            }
            darts();
            free_kill(page_text, true);
            cleanUp();
            break;
        case $location[The Marinara Trench]:
        case $location[The Dive Bar]:
        case $location[Anemone Mine]:
            // Fixed: was checking sea cowboy hat twice, second should be sea chaps
            if (have_equipped($item[sea cowboy hat]) && have_equipped($item[sea chaps])) {
                throw_item($item[sea lasso]);
            }
            if (mob == $monster[mer-kin miner]){
                steal();
                use_if_have_skill(page_text,$skill[swoop like a bat]);
            }
            if ((mob == $monster[giant squid] && !contains_text(get_property("trackedMonsters"), "giant squid"))
                || (mob == $monster[Mer-kin tippler] && !contains_text(get_property("trackedMonsters"), "Mer-kin tippler")) 
                && $location[The coral corral].turns_spent == 0) {
                foreach sk in $skills[transcendent olfaction,
                    Gallapagosian Mating Call, MCHUGELARGE SLASH]
                    use_if_have_skill(page_text, sk);
            }
            if (free_monster(mob)) {
                use_if_have_skill(page_text, $skill[BCZ: Refracted Gaze]);
                cleanUp();
            }
            if (get_property("_curveballFightsLeft").to_int() > 0 && get_property("_curveballMonster") == "some fish"){
                use_if_have_skill(page_text, $skill[Sea *dent: Talk to Some Fish]);
                cleanUp();
            }
            if ((mob != $monster[giant squid] || item_amount($item[comb jelly]) > 0)
                && mob != $monster[Mer-kin tippler]
                && (mob != $monster[Mer-kin miner] || item_amount($item[mer-kin digpick]) > 0)) {
                if (have_item($item[cosmic bowling ball]))
                    free_run(page_text, true);
                use_if_have_skill(page_text, $skill[Sea *dent: Talk to Some Fish]);
                darts();
                free_run(page_text, true);
                cleanUp();
            } else {
                free_kill(page_text, true);
            }
            cleanUp();
            break;

        case $location[The Mer-Kin Outpost]:
            if (my_path().id == 0 && to_int(get_property("lassoTrainingCount")) < 20)
                throw_item($item[sea lasso]);
            if (mob == $monster[time cop]) {
                darts();
                cleanUp();
                break;
            }
            if (mob == $monster[black crayon golem]) {
                if (get_property("_monsterHabitatsFightsLeft") == "0"
                    && have_effect($effect[everything looks purple]) == 0
                    && to_int(get_property("_monsterHabitatsRecalled")) == 2)
                    use_skill($skill[Blow the Purple Candle!]);
                else if (get_property("_monsterHabitatsFightsLeft") == "0"
                    && to_int(get_property("_monsterHabitatsRecalled")) < 2)
                    use_skill($skill[RECALL FACTS: MONSTER HABITATS]);
                if (get_property("_monsterHabitatsFightsLeft") == "0"
                    && to_int(get_property("_monsterHabitatsRecalled")) >= 2
                    && my_familiar() == $familiar[Patriotic Eagle])
                    use_skill($skill[%fn, Release the Patriotic Screech!]);
                darts();
                cleanUp();
                break;
            }
            if ($location[The Mer-Kin Outpost].turns_spent < 24
                || get_property("merkinLockkeyMonster") != "") {
                // Back-up to Black Crayon Golem if available
                if (get_property("_monsterHabitatsFightsLeft") == "0"
                    && to_int(get_property("_monsterHabitatsRecalled")) >= 2
                    && to_int(get_property("_backUpUses")) < 7
                    && get_property("lastCopyableMonster") == "Black Crayon Golem"
                    && have_equipped($item[backup camera])) {
                    use_skill($skill[Back-Up to your Last Enemy]);
                    run_combat();
                }
                if (my_familiar() != $familiar[sword of s words] && (highShiny() || !have_item($item[closed-circuit pay phone]) || lowShiny) && available_amount($item[pristine fish scale]) < 6 && !free_monster(mob)){
                    use_skill($skill[Sea *dent: Talk to Some Fish]);
                    cleanUp();
                }
                if (mob == $monster[mer-kin healer]
                    && item_amount($item[mer-kin prayerbeads]) < 2) {
                    if (have_equipped($item[baseball diamond]) || (get_property("_curveballMonster") == "some fish"
                            && to_int(get_property("_curveballFightsLeft")) > 0))
                        use_skill($skill[Sea *dent: Talk to Some Fish]);
                    free_kill(page_text, true);
                    if (to_int(get_property("_backUpUses")) < 7 && have_equipped($item[backup camera])) {
                        use_skill($skill[Back-Up to your Last Enemy]);
                        run_combat();
                    }
                    free_run(page_text, false);
                    cleanUp();
                } else if (mob == $monster[Mer-kin burglar]
                    || mob == $monster[Mer-kin raider]) {
                    if ((highShiny() || !have_item($item[closed-circuit pay phone])) && my_familiar() == $familiar[sword of s words] && !banishUsedAtYourLocation("Sea *dent"))
                        use_skill($skill[sea *dent: throw a lightning bolt]);
                    free_run(page_text, true);
                }
                if (!free_monster(mob))
                    free_kill(page_text, false);
                cleanUp();
            } else {
                // turns_spent >= 24 and no lockkey monster
                if (mob == $monster[mer-kin burglar] || mob == $monster[mer-kin raider])
                    free_run(page_text, true);
                free_kill(page_text,
                    mob == $monster[mer-kin healer]
                    && item_amount($item[mer-kin prayerbeads]) < 2);
                cleanUp();
            }
            break;

        case $location[The skate park]:
            attack();
            attack();
            cleanUp();
            break;

        case $location[cyberzone 1]:
            if (mob == $monster[eye in the darkness] || mob == $monster[slithering thing]) {
                while (current_round() > 0)
                    use_skill($skill[Throw Cyber Rock]);
            } else {
                use_if_have_skill(page_text, $skill[Sea *dent: Throw a Lightning Bolt]);
            }
            break;

        case $location[The Coral Corral]:
            if (last_monster() == $monster[wild seahorse] && item_amount($item[sea cowbell]) >= 3 && item_amount($item[sea lasso]) >= 1 && to_int(get_property("lassoTrainingCount")) == 20){
                throw_items($item[sea cowbell], $item[sea cowbell]);
                throw_items($item[sea cowbell], $item[sea lasso]);
                if (current_round() != 0){
                    abort("For some reason seahorse wasn't tamed, check that out");
                }
            }
            if (($location[the coral corral].turns_spent <= 1 && item_amount($item[sea leather]) == 0 && available_amount($item[sea cowboy hat]) == 0) || get_property("_lastCombatWon") == false) {
                if (highShiny() && get_property("swordOfSWordsMonster") != "775"){
                    if (mob == $monster[sea cow]){
                        use_skill($skill[%fn, kill a lot of these guys]);
                        cleanUp();
                    }
                } else if (have_equipped($item[backup camera])) {
                    if (mob == $monster[mer-kin rustler])
                        use_skill($skill[spring kick]);
                    use_skill($skill[Back-Up to your Last Enemy]);
                    use_skill($skill[BCZ: Refracted Gaze]);
                    use_skill($skill[Do an epic McTwist!]);
                    free_kill(page_text, true);
                    cleanUp();
                } else {
                    if (mob == $monster[mer-kin rustler]){
                        use_if_have_skill(page_text, $skill[spring kick]);
                        use_if_have_skill(page_text, $skill[Sea *dent: Talk to some fish]);
                        use_skill($skill[BCZ: Refracted Gaze]);
                        use_if_have_skill(page_text, $skill[Do an epic McTwist!]);
                        if (item_amount($item[pulled yellow taffy]) > 0)
                            throw_item($item[pulled yellow taffy]);
                    } else if (last_monster() == $monster[wild seahorse]){
                        runaway( );
                    } else if (item_amount($item[software glitch]) > 0){
                        throw_item($item[software glitch]);
                        if (last_monster() == $monster[Bugged bugbear]){
                            use_skill($skill[BCZ: Refracted Gaze]);
                            use_if_have_skill(page_text, $skill[Do an epic McTwist!]);
                            if (item_amount($item[pulled yellow taffy]) > 0)
                                throw_item($item[pulled yellow taffy]);
                        } else {
                            abort("Software glitch failed");
                        }
                    }
                    free_kill(page_text, true);
                    cleanUp();
                }
            } else if (item_amount($item[sea cowbell]) >= 3 && item_amount($item[sea cowbell]) > 0 && to_int(get_property("lassoTrainingCount")) == 20) {
                if (mob.phylum == $phylum[plant])
                    use_skill($skill[Tear Away your Pants!]);
                if (get_property("seahorseName") == "") {
                    if ((!contains_text(get_property("banishedMonsters"), "sea cow:")
                        && !contains_text(get_property("banishedMonsters"), "sea cowboy"))
                        || (!contains_text(get_property("banishedMonsters"), "Mer-kin rustler")
                        && !contains_text(get_property("banishedMonsters"), "sea cowboy"))
                        || (!contains_text(get_property("banishedMonsters"), "sea cow:")
                        && !contains_text(get_property("banishedMonsters"), "Mer-kin rustler"))){
                            if (mob == $monster[Mer-kin rustler] && get_property("_curveballFightsLeft").to_int() > 0 && get_property("_curveballMonster") == "some fish"){
                                use_if_have_skill(page_text, $skill[Sea *dent: Talk to Some Fish]);
                                if (last_monster() == $monster[some fish])
                                    cleanUp();
                            }
                            free_run(page_text, true);
                            if (mob == $monster[mer-kin rustler]){
                                if (have_skill($skill[heartstone: %banish]) && get_property("heartstoneBanishUnlocked") == "true"){
                                    use_skill($skill[heartstone: %banish]);
                                } 
                            } else if (mob == $monster[sea cowboy]){
                                use_skill($skill[Sea *dent: Throw a Lightning Bolt]);
                            } else if (mob == $monster[sea cow]){
                                use_skill($skill[Sea *dent: Throw a Lightning Bolt]);
                            }
                        }
                }
                if (item_amount($item[waffle]) > 0
                    && !contains_text(get_property("_lastCombatActions"), "it11311")) {
                    throw_item($item[waffle]);
                    run_combat();
                }
                if (get_property("_curveballFightsLeft").to_int() > 0 && get_property("_curveballMonster") == "some fish"){
                    use_if_have_skill(page_text, $skill[Sea *dent: Talk to Some Fish]);
                    if (last_monster() == $monster[some fish])
                        cleanUp();
                }
                free_run(page_text, false);
                free_kill(page_text, false);
                cleanUp();
            } else {
                if (mob == $monster[wild seahorse]) {
                    runaway( );
                } else if (mob == $monster[mer-kin rustler]){
                    if (combatBan() != $skill[none]){
                        use_skill(combatBan());
                    } else {
                        free_run(page_text, true);
                    }
                } else if (mob == $monster[sea cow] && doneWithSeaCow()){
                    if (combatBan() != $skill[none]){
                        use_skill(combatBan());
                    } else {
                        free_run(page_text, true);
                    }
                } else if (mob == $monster[sea cowboy] && doneWithCowboy()){
                    if (combatBan() != $skill[none]){
                        use_skill(combatBan());
                    } else {
                        free_run(page_text, true);
                    }
                }
                if (have_equipped($item[legendary seal-clubbing club]))
                    use_skill($skill[Club 'Em Across the Battlefield]);
                cleanUp();
            }
            break;

        case $location[The Caliginous Abyss]:
            if ((highShiny() || !have_item($item[closed-circuit pay phone])) && item_amount($item[sea lasso]) > 1 && to_int(get_property("lassoTrainingCount")) < 20 && have_equipped($item[sea cowboy hat]))
                throw_item($item[sea lasso]);
            if (mob == $monster[peanut] && to_int(get_property("lastColosseumRoundWon")) < 15) {
                if (have_item($item[august scepter]) && have_item($item[2002 Mr. Store Catalog]) && have_skill($skill[just the facts]) && have_familiar($familiar[patriotic eagle]) && (available_amount($item[waffle]) > 1 || (available_amount($item[waffle]) == 1 && get_property("seahorseName") != "")))
                    throw_item($item[waffle]);
                else 
                    cleanUp();
                run_combat();
            } else if (free_monster(mob)) {
                cleanUp();
            } else {
                if (item_amount($item[spooky VHS tape]) > 0
                    && get_property("spookyVHSTapeMonster") == ""
                    && to_int(get_property("momSeaMonkeeProgress")) < 36
                    && $monsters[slithering thing, eye in the darkness,
                        school of many] contains mob)
                    throw_item($item[spooky VHS tape]);
                if (get_property("_monsterHabitatsRecalled") != "3" && get_property("_monsterHabitatsFightsLeft") == "0" && !highShiny() && (have_item($item[server room key]) || $location[The Mer-Kin Outpost].turns_spent < 29)) {
                    if ($monsters[slithering thing, eye in the darkness] contains mob)
                        use_skill($skill[RECALL FACTS: MONSTER HABITATS]);
                }
                if (mob == $monster[school of many]) {
                    use_if_have_skill(page_text, $skill[Sea *dent: Throw a Lightning Bolt]);
                    for i from 1 to 4
                        use_skill($skill[garbage nova]);
                }
                free_kill(page_text, false);
                cleanUp();
            }
            break;

        case $location[Mer-kin Elementary School]:
            if (free_monster(mob)) {
                use_if_have_skill(page_text, $skill[BCZ: Refracted Gaze]);
                if (to_int(get_property("_clubEmBattlefieldUsed")) < 5 && get_property("NCtoC") != "true"){
                    use_skill($skill[Club 'Em Across the Battlefield]);
                } else {
                    cleanUp();
                }
            } else if (mob == $monster[Mer-kin teacher]
                || mob == $monster[Mer-kin punisher]
                || mob == $monster[Mer-kin monitor]) {
                if (have_equipped($item[spring shoes])
                    && !banishUsedAtYourLocation("Spring Kick")) {
                    if ((mob == $monster[mer-kin teacher]
                        && item_amount($item[mer-kin bunwig]) > 0)
                        || (mob == $monster[mer-kin punisher]
                        && item_amount($item[mer-kin mouthsoap]) > 0))
                        use_skill($skill[spring kick]);
                }
                if (free_monster(to_monster(get_property("lastCopyableMonster")))
                    && to_int(get_property("_backUpUses")) < 11
                    && have_equipped($item[backup camera])) {
                    use_skill($skill[Back-Up to your Last Enemy]);
                    if (get_property("NCtoC") != "true")
                        use_if_have_skill(page_text, $skill[BCZ: Refracted Gaze]);
                    if (to_int(get_property("_clubEmBattlefieldUsed")) < 5 && get_property("NCtoC") != "true")
                        use_skill($skill[Club 'Em Across the Battlefield]);
                    if (free_monster(last_monster())) {
                        cleanUp();
                    } else {
                        abort("backed up to a nonfree monster?");
                    }
                }
            }
            if (bcz_gaze_ready() && get_property("NCtoC") != "true") {
                use_skill($skill[Sea *dent: Talk to Some Fish]);
                if (to_monster(get_property("lastEncounter")) != $monster[none] && item_amount($item[mer-kin cheatsheet]) < 10)
                    use_skill($skill[BCZ: Refracted Gaze]);
            }
            free_kill(page_text, true);
            cleanUp();
            break;

        case $location[Mer-kin Library]:
            if (free_monster(mob)) {
                if (bcz_gaze_ready())
                    use_skill($skill[BCZ: Refracted Gaze]);
                cleanUp();
            }
            if (to_int(get_property("merkinVocabularyMastery")) >= 90) {
                while (get_property("dreadScroll2") == "0"
                    && item_amount($item[mer-kin healscroll]) > 0
                    && current_round() > 0)
                    throw_item($item[mer-kin healscroll]);
                while (get_property("dreadScroll5") == "0"
                    && item_amount($item[mer-kin killscroll]) > 0
                    && current_round() > 0 && last_monster().phylum == $phylum[mer-kin])
                    throw_item($item[mer-kin killscroll]);
                if (free_monster(mob)) {
                    if (bcz_gaze_ready())
                        use_skill($skill[BCZ: Refracted Gaze]);
                } else {
                    if (item_amount($item[mer-kin knucklebone]) == 0) {
                        if (bcz_gaze_ready()) {
                            use_skill($skill[Sea *dent: Talk to Some Fish]);
                            use_skill($skill[BCZ: Refracted Gaze]);
                        }
                    } else if (mob == $monster[Mer-kin alphabetizer]) {
                        use_skill($skill[spring kick]);
                    } else if (mob == $monster[Mer-kin drifter]) {
                        free_run(page_text, true);
                    }
                    free_kill(page_text, true);
                    cleanUp();
                }
            } else {
                if (free_monster(to_monster(get_property("lastCopyableMonster")))
                    && to_int(get_property("_backUpUses")) < 11
                    && have_equipped($item[backup camera])) {
                    use_skill($skill[Back-Up to your Last Enemy]);
                    use_skill($skill[BCZ: Refracted Gaze]);
                } else {
                    if (bcz_gaze_ready() && (item_amount($item[mer-kin killscroll]) == 0 || item_amount($item[mer-kin healscroll]) == 0 || item_amount($item[mer-kin worktea]) == 0 || item_amount($item[mer-kin knucklebone]) == 0)) {
                        use_skill($skill[Sea *dent: Talk to Some Fish]);
                        use_skill($skill[BCZ: Refracted Gaze]);
                    }
                    free_kill(page_text, true);
                    cleanUp();
                }
            }
            cleanUp();
            break;

        case $location[Mer-kin Gymnasium]:
            while (get_property("dreadScroll2") == "0"
                && item_amount($item[mer-kin healscroll]) > 0
                && current_round() > 0)
                throw_item($item[mer-kin healscroll]);
            while (get_property("dreadScroll5") == "0"
                && item_amount($item[mer-kin killscroll]) > 0
                && current_round() > 0 && last_monster().phylum == $phylum[mer-kin])
                throw_item($item[mer-kin killscroll]);
            foreach sk in $skills[Launch spikolodon spikes, MCHUGELARGE avalanche]
                use_if_have_skill(page_text, sk);
            if (free_monster(mob)) {
                if (bcz_gaze_ready())
                    use_skill($skill[BCZ: Refracted Gaze]);
            } else {
                free_run(page_text, true);
                free_kill(page_text, false);
            }
            cleanUp();
            break;

        case $location[Mer-kin Colosseum]:
            if (have_skill($skill[Club 'Em Back in Time]))
                use_skill($skill[Club 'Em Back in Time]);
            if (to_int(get_property("lastColosseumRoundWon")) < 15)
                cleanUp();
            break;

        case $location[Mer-kin Temple (Right Door)]:
            if (my_maxhp() > 311)
                abort("Too much HP to beat Yogurt (need < 312 after debuff) — check what's granting HP");
            throw_items(yogDeleveler(),yogHealing());
            throw_items(yogDeleveler(),yogHealing());
            if (equipped_amount($item[mer-kin prayerbeads]) < 3)
                throw_item(yogHealing());
            if (equipped_amount($item[mer-kin prayerbeads]) < 2)
                throw_item(yogHealing());
            throw_items($item[Doc Galaktik's Homeopathic Elixir],$item[Doc Galaktik's Pungent Unguent]);
            cleanUp();
            attackCleanUp();
            break;

        case $location[Mer-kin Temple (Left Door)]:
            if (have_effect($effect[null afternoon]) == 0){
                for i from 1 to 4
                    throw_items($item[crayon shavings], $item[crayon shavings]);
            }
            while (current_round() > 0)
                attack();
            break;

        case $location[Mer-kin Temple (Center Door)]:
            use_skill($skill[raise backup dancer]);
            use_skill($skill[raise backup dancer]);
            cleanUp();
            break;

        case $location[Mer-kin Temple]:
            if (mob == $monster[Yog-Urt, Elder Goddess of Hatred]){
                if (my_maxhp() > 311)
                    abort("Too much HP to beat Yogurt (need < 312 after debuff) — check what's granting HP");
                if (available_amount($item[crayon shavings]) >= 9)
                    throw_items($item[crayon shavings], $item[mer-kin healscroll]);
                else 
                    throw_items($item[table tennis ball], $item[mer-kin healscroll]);
                throw_items($item[Mer-kin mouthsoap], $item[waterlogged scroll of healing]);
                throw_item($item[sea gel]);
                if (equipped_amount($item[mer-kin prayerbeads]) < 3)
                    throw_item($item[New Age healing crystal]);
                if (equipped_amount($item[mer-kin prayerbeads]) < 2)
                    throw_item($item[soggy used band-aid]);
                cleanUp();
                attack();
                attack();
                attack();
            }
            if (mob == $monster[Shub-Jigguwatt, Elder God of Violence]){
                for i from 1 to 4
                    throw_items($item[crayon shavings], $item[crayon shavings]);
                while (current_round() > 0)
                    attack();
            }
            if (mob == $monster[Dad Sea Monkee]){
                cli_execute("dad");
                abort("execute spells in the above order, can use shrap instead of toynado and volcanometeor instead of awesome balls of fire");
            }
            break;
    }

    // ── Monster-based logic (runs after location logic) ───────────────────────
    switch (mob) {
        case $monster[black crayon golem]:
            if (get_property("_monsterHabitatsFightsLeft") == "0"
                && to_int(get_property("_monsterHabitatsRecalled")) < 3)
                use_skill($skill[RECALL FACTS: MONSTER HABITATS]);
            if (!contains_text(get_property("trackedMonsters"),
                "black crayon golem:McHugeLarge Slash")) {
                foreach sk in $skills[Gallapagosian Mating Call, MCHUGELARGE SLASH]
                    use_if_have_skill(page_text, sk);
                use_skill($skill[Club 'Em Into Next Week]);
            }
            break;
        case $monster[unholy diver]:
            if (my_familiar() == $familiar[chest mimic])
                use_skill($skill[%fn, lay an egg]);
            if (item_amount($item[spitball]) > 0){
                throw_item($item[spitball]);
            }
            free_kill(page_text, true);
            cleanUp();
            break;
        case $monster[sea cowboy]:
            use_skill($skill[%fn, kill a lot of these guys]);
            free_kill(page_text, true);
            cleanUp();
            break;
        case $monster[rotten dolphin thief]:
            cleanUp();
            break;
        case $monster[kid who is too old to be Trick-or-Treating]:
        case $monster[suburban security civilian]:
        case $monster[vandal kid]:
            cleanUp();
            break;
    }
}
