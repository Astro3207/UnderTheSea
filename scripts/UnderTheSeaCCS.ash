import iotm.ash;

// ─── COMBAT HELPERS ───────────────────────────────────────────────────────────

// Attempt a free kill using available skills/items.
// Pass drop=true to skip items that interfere with item drops.
void free_kill(string ptext, boolean drop) {
    if (get_property("_curveballMonster") == last_monster()
        && to_int(get_property("_curveballFightsLeft")) > 0)
        return;

    foreach freeskill in $skills[Spit jurassic acid, Assert your Authority,
        Club 'Em Back in Time, Darts: Aim for the Bullseye,
        BCZ: Sweat Bullets, Chest X-Ray, Shattering Punch, Gingerbread Mob Hit] {
        if (freeskill == $skill[Club 'Em Back in Time]
            && my_location() != $location[mer-kin colosseum])
            continue;
        if (freeskill == $skill[BCZ: Sweat Bullets]
            && to_int(get_property("_bczSweatBulletsCasts")) >= 9
            && my_location() == $location[The Mer-Kin Outpost])
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

    foreach freeskill in $skills[spring away, Bowl a Curveball, snokebomb] {
        if (!contains_text(ptext, to_string(freeskill))) continue;
        if (!banish && $skills[snokebomb, Bowl a Curveball] contains freeskill) continue;
        if (banish && banishUsedAtYourLocation("snokebomb")
            && freeskill == $skill[snokebomb]) continue;
        if ($locations[The Outskirts of Cobb's Knob, The Sleazy Back Alley,
            The Haunted Pantry] contains my_location()
            && freeskill == $skill[snokebomb])
            return;
        if (banish && freeskill == $skill[spring away])
            use_skill($skill[spring kick]);
        use_skill(freeskill);
    }

    foreach freecombat in $items[peppermint parasol, anchor bomb,
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
    return $monsters[black crayon golem, time cop,
        kid who is too old to be Trick-or-Treating,
        suburban security civilian, vandal kid] contains mob;
}

// Use a skill if it appears as an option on the current page
void use_if_have_skill(string page_text, skill sk) {
    if (contains_text(page_text, to_string(sk)))
        use_skill(sk);
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
        use_skill($skill[saucegeyser]);
        if (round == current_round()) {
            loopCount += 1;
            if (loopCount > 3)
                abort("May be stuck in an infinite saucegeyser loop");
        }
    }
}

// ─── MAIN CCS ─────────────────────────────────────────────────────────────────

void main(int round, monster mob, string page_text) {

    // ── Location-based combat logic ───────────────────────────────────────────
    switch (my_location()) {

        case $location[The Outskirts of Cobb's Knob]:
        case $location[The Sleazy Back Alley]:
        case $location[The Haunted Pantry]:
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
                && item_amount($item[sea cowbell]) > 0)
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
            use_if_have_skill(page_text, $skill[Sea *dent: Talk to Some Fish]);
            darts();
            cleanUp();
            break;

        case $location[an octopus's garden]:
            if (have_effect($effect[Citizen of a Zone]) == 0)
                use_skill($skill[%fn, let's pledge allegiance to a Zone]);
            if (mob == $monster[neptune flytrap]) {
                if (have_effect($effect[Everything Looks Red, White and Blue]) == 0)
                    use_skill($skill[%fn, fire a Red, White and Blue Blast]);
                darts();
                if (have_equipped($item[McHugeLarge left pole])
                    && !contains_text(get_property("trackedMonsters"), "Neptune flytrap")) {
                    foreach sk in $skills[transcendent olfaction,
                        Gallapagosian Mating Call, MCHUGELARGE SLASH]
                        use_if_have_skill(page_text, sk);
                }
                free_kill(page_text, true);
            } else if (!free_monster(mob)) {
                free_run(page_text, true);
            }
            cleanUp();
            break;

        case $location[The Marinara Trench]:
        case $location[The Dive Bar]:
        case $location[Anemone Mine]:
            // Fixed: was checking sea cowboy hat twice, second should be sea chaps
            if (have_equipped($item[sea cowboy hat]) && have_equipped($item[sea chaps])) {
                throw_item($item[sea lasso]);
                if (!free_monster(mob)) {
                    if (item_amount($item[pristine fish scale]) < 6)
                        use_skill($skill[Sea *dent: Talk to Some Fish]);
                    free_kill(page_text, true);
                }
                cleanUp();
            }
            if ((mob == $monster[giant squid]
                && !contains_text(get_property("trackedMonsters"), "giant squid"))
                || (mob == $monster[Mer-kin tippler]
                && !contains_text(get_property("trackedMonsters"), "Mer-kin tippler"))) {
                foreach sk in $skills[transcendent olfaction,
                    Gallapagosian Mating Call, MCHUGELARGE SLASH]
                    use_if_have_skill(page_text, sk);
            }
            if (free_monster(mob)) {
                use_if_have_skill(page_text, $skill[BCZ: Refracted Gaze]);
                cleanUp();
            }
            if ((mob != $monster[giant squid] || item_amount($item[comb jelly]) == 0)
                && mob != $monster[Mer-kin tippler]
                && (mob != $monster[Mer-kin miner]
                    || item_amount($item[mer-kin digpick]) == 0)) {
                use_if_have_skill(page_text, $skill[Sea *dent: Talk to Some Fish]);
                use_if_have_skill(page_text, $skill[BCZ: Refracted Gaze]);
            }
            darts();
            if (have_equipped($item[baseball diamond])
                || (get_property("_curveballMonster") == "some fish"
                    && to_int(get_property("_curveballFightsLeft")) > 0))
                use_skill($skill[Sea *dent: Talk to Some Fish]);
            free_kill(page_text, true);
            cleanUp();
            break;

        case $location[The Mer-Kin Outpost]:
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
                    && get_property("lastCopyableMonster") == "Black Crayon Golem") {
                    use_skill($skill[Back-Up to your Last Enemy]);
                    run_combat();
                }
                if (mob == $monster[mer-kin healer]
                    && item_amount($item[mer-kin prayerbeads]) < 2) {
                    if (have_equipped($item[baseball diamond])
                        || (get_property("_curveballMonster") == "some fish"
                            && to_int(get_property("_curveballFightsLeft")) > 0))
                        use_skill($skill[Sea *dent: Talk to Some Fish]);
                    free_kill(page_text, true);
                    if (to_int(get_property("_backUpUses")) < 7
                        && have_equipped($item[backup camera])) {
                        use_skill($skill[Back-Up to your Last Enemy]);
                        run_combat();
                    }
                    free_run(page_text, false);
                    cleanUp();
                } else if (mob == $monster[Mer-kin burglar]
                    || mob == $monster[Mer-kin raider]) {
                    free_run(page_text, true);
                }
                if (!free_monster(mob))
                    free_kill(page_text, false);
                cleanUp();
            } else {
                // turns_spent >= 24 and no lockkey monster
                free_kill(page_text,
                    mob == $monster[mer-kin healer]
                    && item_amount($item[mer-kin prayerbeads]) < 2);
                cleanUp();
            }
            break;

        case $location[The skate park]:
            abort("Hit a combat in skate park — that isn't supposed to happen");
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
            if (item_amount($item[sea cowbell]) == 0) {
                if (have_equipped($item[backup camera])) {
                    if (mob == $monster[mer-kin rustler])
                        use_skill($skill[spring kick]);
                    use_skill($skill[Back-Up to your Last Enemy]);
                    use_skill($skill[BCZ: Refracted Gaze]);
                    use_skill($skill[Do an epic McTwist!]);
                    free_kill(page_text, true);
                    cleanUp();
                }
            } else if (item_amount($item[sea cowbell]) >= 2) {
                if (mob.phylum == $phylum[plant])
                    use_skill($skill[Tear Away your Pants!]);
                if (mob == $monster[wild seahorse]) {
                    throw_items($item[sea cowbell], $item[sea cowbell]);
                    throw_items($item[sea cowbell], $item[sea lasso]);
                } else {
                    if (get_property("seahorseName") == "") {
                        if ((!contains_text(get_property("banishedMonsters"), "sea cow:")
                            && !contains_text(get_property("banishedMonsters"), "sea cowboy"))
                            || (!contains_text(get_property("banishedMonsters"), "mer-kin rustler")
                            && !contains_text(get_property("banishedMonsters"), "sea cowboy"))
                            || (!contains_text(get_property("banishedMonsters"), "sea cow:")
                            && !contains_text(get_property("banishedMonsters"), "mer-kin rustler")))
                            free_run(page_text, true);
                    }
                    if (item_amount($item[waffle]) > 0
                        && !contains_text(get_property("_lastCombatActions"), "it11311")) {
                        throw_item($item[waffle]);
                        run_combat();
                    } else if (item_amount($item[waffle]) == 0) {
                        abort("Ran out of waffles — banish 2 of 3 coral corral monsters, pull a waffle, and rerun");
                    }
                    free_kill(page_text, false);
                    free_run(page_text, false);
                    cleanUp();
                }
            }
            break;

        case $location[The Caliginous Abyss]:
            if (mob == $monster[peanut]
                && to_int(get_property("lastColosseumRoundWon")) < 15) {
                throw_item($item[waffle]);
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
                if (get_property("_monsterHabitatsRecalled") != "3"
                    && get_property("_monsterHabitatsFightsLeft") == "0"
                    && get_property("corralUnlocked") == "true") {
                    if ($monsters[slithering thing, eye in the darkness] contains mob)
                        use_skill($skill[RECALL FACTS: MONSTER HABITATS]);
                    else
                        abort("Hit an odd mob at caliginous abyss — should not have happened with peridot");
                }
                free_kill(page_text, false);
                if (mob == $monster[school of many]) {
                    for i from 1 to 4
                        use_skill($skill[garbage nova]);
                }
                cleanUp();
            }
            break;

        case $location[Mer-kin Elementary School]:
            if (free_monster(mob)) {
                use_if_have_skill(page_text, $skill[BCZ: Refracted Gaze]);
                if (to_int(get_property("_clubEmBattlefieldUsed")) < 5)
                    use_skill($skill[Club 'Em Across the Battlefield]);
            } else if (mob == $monster[Mer-kin teacher]
                || mob == $monster[Mer-kin punisher]
                || mob == $monster[Mer-kin monitor]) {
                steal();
                if (mob == $monster[Mer-kin monitor]) {
                    if (have_equipped($item[bat wings])
                        && to_int(get_property("_batWingsSwoopUsed")) < 11)
                        use_skill($skill[swoop like a bat]);
                    if (item_amount($item[Septapus summoning charm]) > 0)
                        throw_item($item[Septapus summoning charm]);
                } else if (have_equipped($item[spring shoes])
                    && !banishUsedAtYourLocation("Spring Kick")) {
                    if ((mob == $monster[mer-kin teacher]
                        && item_amount($item[mer-kin bunwig]) > 0)
                        || (mob == $monster[mer-kin punisher]
                        && item_amount($item[mer-kin mouthsoap]) > 0))
                        use_skill($skill[spring kick]);
                }
                if (free_monster(to_monster(get_property("lastCopyableMonster")))
                    && to_int(get_property("_backUpUses")) < 11) {
                    use_skill($skill[Back-Up to your Last Enemy]);
                    use_if_have_skill(page_text, $skill[BCZ: Refracted Gaze]);
                    if (to_int(get_property("_clubEmBattlefieldUsed")) < 5)
                        use_skill($skill[Club 'Em Across the Battlefield]);
                }
            }
            if (bcz_gaze_ready()) {
                use_skill($skill[Sea *dent: Talk to Some Fish]);
                use_skill($skill[BCZ: Refracted Gaze]);
            }
            free_kill(page_text, true);
            cleanUp();
            break;

        case $location[Mer-kin Library]:
            if (to_int(get_property("merkinVocabularyMastery")) == 100) {
                while (get_property("dreadScroll5") == "0"
                    && item_amount($item[mer-kin killscroll]) > 0
                    && current_round() > 0)
                    throw_item($item[mer-kin killscroll]);
                if (get_property("dreadScroll2") == "0"
                    && item_amount($item[mer-kin healscroll]) > 0
                    && current_round() > 0)
                    throw_item($item[mer-kin healscroll]);
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
                }
            } else {
                if (free_monster(to_monster(get_property("lastCopyableMonster")))
                    && to_int(get_property("_backUpUses")) < 11) {
                    use_skill($skill[Back-Up to your Last Enemy]);
                    use_skill($skill[BCZ: Refracted Gaze]);
                } else if (free_monster(mob)) {
                    if (bcz_gaze_ready())
                        use_skill($skill[BCZ: Refracted Gaze]);
                } else {
                    if (bcz_gaze_ready()) {
                        use_skill($skill[Sea *dent: Talk to Some Fish]);
                        use_skill($skill[BCZ: Refracted Gaze]);
                    }
                    free_kill(page_text, true);
                }
            }
            cleanUp();
            break;

        case $location[Mer-kin Gymnasium]:
            if (free_monster(mob)) {
                if (bcz_gaze_ready())
                    use_skill($skill[BCZ: Refracted Gaze]);
            } else {
                free_run(page_text, false);
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
            throw_items($item[crayon shavings], $item[mer-kin healscroll]);
            throw_items($item[Mer-kin mouthsoap], $item[waterlogged scroll of healing]);
            throw_item($item[sea gel]);
            if (equipped_amount($item[mer-kin prayerbeads]) < 3)
                throw_item($item[New Age healing crystal]);
            if (equipped_amount($item[mer-kin prayerbeads]) < 2)
                throw_item($item[soggy used band-aid]);
            cleanUp();
            break;

        case $location[Mer-kin Temple (Left Door)]:
            for i from 1 to 4
                throw_items($item[crayon shavings], $item[crayon shavings]);
            while (current_round() > 0)
                attack();
            break;

        case $location[Mer-kin Temple (Center Door)]:
            use_skill($skill[raise backup dancer]);
            use_skill($skill[raise backup dancer]);
            cleanUp();
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
            free_kill(page_text, true);
            cleanUp();
            break;
        case $monster[kid who is too old to be Trick-or-Treating]:
        case $monster[suburban security civilian]:
        case $monster[vandal kid]:
            cleanUp();
            break;
    }
}
