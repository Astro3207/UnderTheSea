import iotm.ash;
import UnderTheSea.ash;

// Attempt a free kill using available skills/items.
// Pass drop=true to skip items that interfere with item drops.
void free_kill(string ptext, boolean drop) {
    if (highShiny()){
        // Darts are an instakill too, so they only glance at the colosseum
        // (see the club-only rule below) -- don't waste one there.
        if (contains_text(ptext, "Darts: Aim for the Bullseye")
            && my_location() != $location[mer-kin colosseum])
            use_skill($skill[Darts: Aim for the Bullseye]);
        return;
    }
    if (get_property("_curveballMonster") == last_monster()
        && to_int(get_property("_curveballFightsLeft")) > 0)
        return;

    // One freeing resource per fight: once Club 'Em Back in Time lands, the
    // fight is already turn-free, and ptext is stale for the rest of this
    // consult pass -- without the flag, the item loop below reads the
    // pre-club page and spends a banked brick on a fight that costs nothing.
    boolean clubbed;
    foreach freeskill in $skills[Spit jurassic acid, Assert your Authority,
        Club 'Em Back in Time, Darts: Aim for the Bullseye,
        BCZ: Sweat Bullets, Chest X-Ray, Shattering Punch, Gingerbread Mob Hit] {
        // Colosseum gladiators are insta-kill immune: damage-based
        // instakills only glance (observed for shadow bricks; the wiki
        // gives X-Ray and Shattering Punch the same immune-monster damage
        // branch and has the missile read UNTARGETABLE), wasting their
        // daily casts. Club 'Em is the exception -- against immune
        // monsters it still deals 30% max HP and makes the fight free.
        if (my_location() == $location[mer-kin colosseum]
            && freeskill != $skill[Club 'Em Back in Time])
            continue;
        if (freeskill == $skill[Club 'Em Back in Time]
            && (my_location() != $location[mer-kin colosseum] || lowShiny()
                || to_int(get_property("_clubEmTimeUsed")) >= 5))
            continue;
        if (freeskill == $skill[BCZ: Sweat Bullets]
            && (my_basestat($stat[submoxie]) - 22500) < BCZcost("SweatBulletsCasts"))
            continue;
        // A missile that fails to kill is not recorded by mafia (neither
        // the daily pref nor the fuel), so track failure ourselves or it
        // re-fires every fight for the rest of the day.
        if (freeskill == $skill[Asdon Martin: Missile Launcher]
            && (get_fuel() < 100
                || get_property("_missileLauncherUsed") == "true"
                || get_property("_utsMissileFailed") == "true"))
            continue;
        if (contains_text(ptext, to_string(freeskill))) {
            use_skill(freeskill);
            if (freeskill == $skill[Club 'Em Back in Time]) {
                clubbed = true;
                break;
            }
            // Fight already over: the kill landed, and any further cast
            // would fire into a finished fight and error out.
            if (current_round() == 0)
                break;
            if (freeskill == $skill[Asdon Martin: Missile Launcher])
                set_property("_utsMissileFailed", "true");
        }
    }

    if (!clubbed && current_round() > 0) {
        foreach freecombat in $items[shadow brick, groveling gravel] {
            if (item_amount(freecombat) == 0) continue;
            if (freecombat == $item[groveling gravel] && drop) continue;
            if (freecombat == $item[shadow brick]
                && to_int(get_property("_shadowBricksUsed")) == 13) continue;
            // Gladiators sit in these items' "unkillable" class: a brick
            // glances for 400-600 (halved underwater) instead of killing,
            // wasting both the item and the combat round.
            if (my_location() == $location[Mer-kin Colosseum]) continue;
            throw_item(freecombat);
        }
    }

    // Last resort: Use the Force forfeits the win and any conditional drops,
    // so it runs only after every real free kill above, and only where
    // saberEquip() put the saber on. saberForcesFree() keeps two charges
    // reserved for the diver plan.
    if (current_round() > 0
        && saberForcesFree() > 0
        && have_equipped($item[Fourth of May Cosplay Saber])
        && contains_text(ptext, "Use the Force")) {
        step("Use the Force: free-run of last resort");
        use_skill($skill[Use the Force]);
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

    foreach freeskill in $skills[spring away, Bowl a Curveball, creepy grin, Throw Latte on Opponent, Feel Hatred, Reflex Hammer, snokebomb] {
        if (!contains_text(ptext, to_string(freeskill))) continue;
        if (!banish && $skills[snokebomb, Bowl a Curveball, Feel Hatred, Throw Latte on Opponent, Reflex Hammer] contains freeskill) continue;
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
    foreach it in $items[sea gel,mer-kin healscroll,waterlogged scroll of healing,soggy used band-aid,New Age healing crystal]{
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

// Shub's percentage delevelers, strongest first: jam band bootleg 50%,
// crayon shavings 30%, rattler rattle and electronics kit 25%.
// All multiplicative, none deal damage (which would trigger his doubling
// 20%-max-HP retaliation).
item shubDeleveler() {
    foreach it in $items[jam band bootleg, crayon shavings, rattler rattle,
        electronics kit] {
        if (item_amount(it) > 0)
            return it;
    }
    return $item[none];
}

// Throw delevelers until his attack multiplier is floored (~x0.25),
// funkslinging same-item pairs while worthwhile. Two bootlegs, four
// shavings, or a mix all land in 2-4 rounds.
void shubDelevel() {
    float remaining = 1.0;
    while (remaining > 0.05 && current_round() > 0) {
        item d = shubDeleveler();
        if (d == $item[none])
            break;
        float f = (d == $item[jam band bootleg]) ? 0.5
            : (d == $item[crayon shavings]) ? 0.7 : 0.75;
        if (item_amount(d) >= 2 && (remaining * f * f) >= 0.2
            && have_skill($skill[Ambidextrous Funkslinging])) {
            throw_items(d, d);
            remaining = remaining * f * f;
        } else {
            throw_item(d);
            remaining = remaining * f;
        }
    }
}

// ─── MAIN CCS ─────────────────────────────────────────────────────────────────

void main(int round, monster mob, string page_text) {
    // Pearl farming spends plain turns: free kills, free runs, Forces and
    // copies advance neither a zone's pearl progress nor screechCombats,
    // so every trick below would burn a charge for zero progress.
    if (get_property("_utsPearlFarm") == "true") {
        cleanUp();
        return;
    }
    // Re-roll dispatch loop. A monster swap restarts this pass with the new
    // monster and a re-fetched page. ASH cannot call main() from inside its
    // own definition (the name is not bound until the definition completes),
    // so the loop, not recursion, is the dispatch mechanism.
    while (true) {
    // One extra roll of a fat drop table, once a day, on fights that will be
    // WON; duplicateMonster() refuses fights the saber is about to Force.
    duplicateMonster(mob, page_text);
    // Deterministic diver: insurance egg, then Use the Force hands over every
    // non-conditional drop and ends the fight -- nothing below applies.
    if (diverForce(mob, page_text))
        return;
    // Same trick down the Force priority ladder: the outpost healer's
    // prayerbeads, the sea cow's leather and cowbells, the researcher's
    // scrolls -- each from its own tier of the budget.
    if (healerForce(mob, page_text))
        return;
    if (seaCowForce(mob, page_text))
        return;
    if (researcherForce(mob, page_text))
        return;
    // +50% item drops for this fight, before anything has a chance to end it.
    becomeBat(page_text);
    // +200% item on the diver itself, three a day, before free_kill can end it.
    otoscope(mob, page_text);
    // Free stench jelly off any stench monster; NCforce() spends it as a sneak.
    extractJelly(mob, page_text);
    // Re-roll a wrong monster at Fitzsimmons rather than spending a turn on it.
    // On a re-roll the fight holds a NEW monster. Returning would fall through
    // to the CCS's safety abort line -- mafia does NOT re-invoke a consult
    // script that returns mid-combat -- so restart the dispatch loop with the
    // new monster and a re-fetched page, which also resyncs mafia's round
    // counter after the swap.
    if (replaceEnemy(mob, page_text)) {
        mob = last_monster();
        page_text = to_string(visit_url("fight.php"));
        continue;
    }
    // Chain another free diver off this one.
    lectureOnRelativity(mob, page_text);
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
            // Slab hunting: bricks are ordinary free kills (they only
            // glance at the colosseum), so a snake or stalk draw is worth
            // a spare Macrometeorite while bricks are short. The diver
            // hunt keeps first claim on the casts (at least four held
            // back while it is live).
            if ($monsters[shadow snake, shadow stalk] contains mob
                && item_amount($item[shadow brick]) < 6
                && (!diverHuntActive() || to_int(get_property("_macrometeoriteUses")) < 6)
                && macroReady() && contains_text(page_text, "Macrometeorite")) {
                step("Macrometeorite: re-rolling for a shadow slab");
                use_skill($skill[Macrometeorite]);
                mob = last_monster();
                page_text = to_string(visit_url("fight.php"));
                continue;
            }
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
            // Free wanderers burn delay -- they advance the zone's turns_spent
            // for free -- and their fight costs nothing, so they are killed by
            // the fall-through below, never run from or re-rolled.
            if (mob != $monster[unholy diver] && !free_monster(mob)){
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
            // Still in combat here means the free runs above didn't fire, so
            // this fight is getting killed -- the one moment a Feel Nostalgic
            // charge on the diver's drop table is guaranteed to pay out.
            if (current_round() > 0)
                feelNostalgic(mob, page_text);
            darts();
            free_kill(page_text, true);
            cleanUp();
            break;
        case $location[The Marinara Trench]:
        case $location[The Dive Bar]:
        case $location[Anemone Mine]:
            // Lasso training only counts with both trainer pieces worn.
            if (have_equipped($item[sea cowboy hat]) && have_equipped($item[sea chaps])) {
                throw_item($item[sea lasso]);
            }
            if (mob == $monster[mer-kin miner]){
                steal();
                use_if_have_skill(page_text,$skill[swoop like a bat]);
            }
            // The corral gate applies to both targets: sniffing feeds the
            // step4 pearl hunt, which is over once the corral has started.
            if (((mob == $monster[giant squid] && !contains_text(get_property("trackedMonsters"), "giant squid"))
                || (mob == $monster[Mer-kin tippler] && !contains_text(get_property("trackedMonsters"), "Mer-kin tippler")))
                && $location[The coral corral].turns_spent == 0) {
                foreach sk in $skills[transcendent olfaction,
                    Gallapagosian Mating Call, MCHUGELARGE SLASH]
                    use_if_have_skill(page_text, sk);
            }
            if (free_monster(mob)) {
                use_if_have_skill(page_text, $skill[BCZ: Refracted Gaze]);
                cleanUp();
            }
            if (highShiny() && last_monster() == $monster[anemone combatant]){
                use_if_have_skill(page_text, $skill[Sea *dent: Throw a Lightning Bolt]);
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
                // Back-up to Black Crayon Golem if available. Back-Up
                // rewrites the CURRENT fight into the last copyable monster,
                // so it silently eats a healer standing in front of it --
                // and the healer is the only prayerbead source.
                if (get_property("_monsterHabitatsFightsLeft") == "0"
                    && to_int(get_property("_monsterHabitatsRecalled")) >= 2
                    && to_int(get_property("_backUpUses")) < 7
                    && get_property("lastCopyableMonster") == "Black Crayon Golem"
                    && !(mob == $monster[mer-kin healer] && prayerbeadsShort())
                    && have_equipped($item[backup camera])) {
                    use_skill($skill[Back-Up to your Last Enemy]);
                    run_combat();
                }
                // Talk to Some Fish is a CLEESH: it replaces the monster, so
                // a healer caught by the scale grind never rolls its bead.
                // Scales come from any Outpost monster; beads only from healers.
                if (my_familiar() != $familiar[sword of s words] && (highShiny() || !have_item($item[closed-circuit pay phone]) || lowShiny()) && available_amount($item[pristine fish scale]) < 6 && !free_monster(mob)
                    && !(mob == $monster[mer-kin healer] && prayerbeadsShort())){
                    use_skill($skill[Sea *dent: Talk to Some Fish]);
                    cleanUp();
                }
                if (mob == $monster[mer-kin healer] && prayerbeadsShort()) {
                    // This branch exists to WIN the fight for its 4.8%
                    // prayerbead, so nothing in it may swap the monster out.
                    // Both Talk to Some Fish and Back-Up did exactly that,
                    // spending the free kill on whatever replaced the healer.
                    free_kill(page_text, true);
                    // Only run once the lockkey is in hand (the pref is set on
                    // the drop). Before that the healer is one of the three
                    // carriers, so a free run forfeits the key along with the
                    // bead; after it, the zone is a noncombat hunt and the
                    // refunded adventure beats a 4.8% roll.
                    if (get_property("merkinLockkeyMonster") != "")
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
                    mob == $monster[mer-kin healer] && prayerbeadsShort());
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
                        // Runs exhausted: re-roll the fight into a fresh draw
                        // rather than killing a monster that owes us nothing.
                        if (current_round() > 0 && rerollEnemy(page_text)) {
                            // Re-dispatch: see the replaceEnemy note up top.
                            mob = last_monster();
                            page_text = to_string(visit_url("fight.php"));
                            continue;
                        }
                    }
                } else if (mob == $monster[sea cow] && doneWithSeaCow()){
                    if (combatBan() != $skill[none]){
                        use_skill(combatBan());
                    } else {
                        free_run(page_text, true);
                        if (current_round() > 0 && rerollEnemy(page_text)) {
                            // Re-dispatch: see the replaceEnemy note up top.
                            mob = last_monster();
                            page_text = to_string(visit_url("fight.php"));
                            continue;
                        }
                    }
                } else if (mob == $monster[sea cowboy] && doneWithCowboy()){
                    if (combatBan() != $skill[none]){
                        use_skill(combatBan());
                    } else {
                        free_run(page_text, true);
                        if (current_round() > 0 && rerollEnemy(page_text)) {
                            // Re-dispatch: see the replaceEnemy note up top.
                            mob = last_monster();
                            page_text = to_string(visit_url("fight.php"));
                            continue;
                        }
                    }
                }
                // Fight being killed from here on -- the one safe moment for a
                // Feel Nostalgic charge on the cow's table.
                if (current_round() > 0)
                    feelNostalgic(mob, page_text);
                // Club 'Em Across the Battlefield is 5/day and does nothing
                // once a noncombat has already been forced into a combat.
                if (have_equipped($item[legendary seal-clubbing club])
                    && to_int(get_property("_clubEmBattlefieldUsed")) < 5
                    && get_property("NCtoC") != "true")
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
            // A pickpocket is an extra roll OUTSIDE the drop system, immune
            // to the per-slot cap, and this whole table is plain-flagged
            // (stealable).
            if (my_primestat() == $stat[moxie] && can_still_steal())
                steal();
            if (free_monster(mob)) {
                use_if_have_skill(page_text, $skill[BCZ: Refracted Gaze]);
                if (have_equipped($item[legendary seal-clubbing club]) && to_int(get_property("_clubEmBattlefieldUsed")) < 5 && get_property("NCtoC") != "true"){
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
                    if (have_equipped($item[legendary seal-clubbing club]) && to_int(get_property("_clubEmBattlefieldUsed")) < 5 && get_property("NCtoC") != "true")
                        use_skill($skill[Club 'Em Across the Battlefield]);
                    if (free_monster(last_monster())) {
                        cleanUp();
                    } else {
                        abort("backed up to a nonfree monster?");
                    }
                }
            }
            // During the sheet grind, a teacher or punisher that survived its
            // banish attempt is worth re-rolling into a fresh 1-in-3 draw at
            // the monitor rather than killing for nothing. Never the golem
            // stat-fights, and forced-victim fights are already monitors.
            if (cheatsheetsNeeded() && mob != $monster[Mer-kin monitor]
                && !free_monster(mob) && current_round() > 0
                && rerollEnemy(page_text)) {
                // Re-dispatch: see the replaceEnemy note up top.
                mob = last_monster();
                page_text = to_string(visit_url("fight.php"));
                continue;
            }
            // Kill path from here on -- the safe spot for a Feel Nostalgic
            // charge on the monitor's cheatsheet table.
            if (current_round() > 0)
                feelNostalgic(mob, page_text);
            if (bcz_gaze_ready() && get_property("NCtoC") != "true") {
                use_skill($skill[Sea *dent: Talk to Some Fish]);
                if (to_monster(get_property("lastEncounter")) != $monster[none] && item_amount($item[mer-kin cheatsheet]) < 10)
                    use_skill($skill[BCZ: Refracted Gaze]);
            }
            free_kill(page_text, true);
            cleanUp();
            break;

        case $location[Mer-kin Library]:
            // Same as the school: healscroll/killscroll (10), worktea (10),
            // knucklebone (10) are all stealable.
            if (my_primestat() == $stat[moxie] && can_still_steal())
                steal();
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
            // Colosseum rounds need WINS, so this drains free kills and never
            // Use the Force (which forfeits the win); the saber is not
            // equipped here, so its last-resort clause stays dead.
            if (current_round() > 0)
                free_kill(page_text, false);
            if (to_int(get_property("lastColosseumRoundWon")) < 15)
                cleanUp();
            break;

        case $location[Mer-kin Temple (Right Door)]:
            if (my_maxhp() > 311)
                abort("Too much HP to beat Yogurt (need < 312 after debuff) — check what's granting HP");
            // yogDeleveler() returns $item[none] when moxie already outpaces
            // her attack; funkslinging none errors out, so heal solo then.
            for i from 1 to 2 {
                item dlv = yogDeleveler();
                if (dlv == $item[none])
                    throw_item(yogHealing());
                else
                    throw_items(dlv, yogHealing());
            }
            if (equipped_amount($item[mer-kin prayerbeads]) < 3)
                throw_item(yogHealing());
            if (equipped_amount($item[mer-kin prayerbeads]) < 2)
                throw_item(yogHealing());
            throw_items($item[Doc Galaktik's Homeopathic Elixir],$item[Doc Galaktik's Pungent Unguent]);
            cleanUp();
            attackCleanUp();
            break;

        case $location[Mer-kin Temple (Left Door)]:
            if (have_effect($effect[null afternoon]) == 0)
                shubDelevel();
            while (current_round() > 0)
                attack();
            break;

        case $location[Mer-kin Temple (Center Door)]:
            // Raise Backup Dancer is a Pastamancer skill; it is only a damage boost
            // here, so skip it rather than erroring out on accounts without it.
            if (have_skill($skill[raise backup dancer])) {
                use_skill($skill[raise backup dancer]);
                use_skill($skill[raise backup dancer]);
            }
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
                if (have_effect($effect[null afternoon]) == 0)
                    shubDelevel();
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
            // In-place summons (the Shub shavings fallback) reach this case
            // with no location logic to finish the fight; a no-op when a
            // location case already resolved it.
            cleanUp();
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
    return;
    } // dispatch loop
}