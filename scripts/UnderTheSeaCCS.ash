import globals.ash;
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
        if (contains_text(ptext, to_string(freeskill)))
            use_skill(freeskill);
    }

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

// BCZ refracted gaze helper — checks stat threshold before casting
boolean bcz_gaze_ready() {
    return (my_basestat($stat[submysticality]) - 40000) > BCZcost("RefractedGazeCasts");
}

// Free-ish delevel openers before the damage loop: Micrometeorite costs
// 0 MP, the Time-Spinner's combat toss is free (its minutes only gate
// the travel menu), and Curse of Weaksauce is 8 MP. Each fires only
// while the monster can still hurt us -- the same moxie-vs-attack test
// yogDeleveler() uses -- so trivial fights skip straight to damage and
// already-deleveled bosses (Yog after her own CCS phase) are left
// alone. monster_attack() tracks in-fight delevels, so each landed
// opener re-tightens the gate for the next. Re-entry safety comes from
// the current_round() guards (a finished fight casts nothing), NOT
// from the attack gate -- a caller that re-enters mid-fight before the
// delevel lands would re-cast Weaksauce, so keep cleanUp() the only
// caller and keep it finishing its fights.
// Only the Mer-kin bladeswitcher reflects, and scoping on that one monster
// rather than on the zone or the name matters twice over.
//
// The netdragger's runner special deals half your max HP in one round, a bigger
// single hit than the health threshold below, and stalling ten rounds against
// something that heals ~1000 a round loses a fight that otherwise ends in four.
//
// The championship bladeswitcher is the subtler trap. It shares the name and the
// switchblade but has no special moves of any kind -- no wind-up, no twirl, no
// reflection -- so nothing here can ever arm legitimately against it, while its
// attack is high enough that ordinary hits and crits clear the health threshold
// routinely. Counting it in would spend ten stalled rounds per big hit against a
// boss taking full damage throughout, inside a fight with a round limit.
boolean isBladeswitcher() {
    return last_monster() == $monster[Mer-kin bladeswitcher];
}

// How many opening rounds of this fight no special can reach.
//
// Every colosseum special needs a wind-up: the monster spends one action
// setting it up and a later one resolving it. Its first action of the fight can
// therefore only ever be the wind-up, never the payoff -- which makes the
// opening round free of specials, and a nuke thrown into it lands before the
// monster has shown what it was going to do.
//
// One round, not more, and deliberately so. The player does NOT reliably act
// first here: these monsters carry an initiative that is supposed to hand the
// jump over every time, and a small share of fights still open on a lost one,
// giving the monster an action before the first submitted round. That is enough
// to move every subsequent special a round earlier, so anything past the first
// round is only conditionally free and is left to the reflect read and the
// stall rather than assumed.
//
// The championship monsters count too. Two of the three have no specials at all
// and the third telegraphs nothing that is written down, so there is no wind-up
// to outrun in the first place; what makes the opening nuke right for them is
// the arithmetic. Their health is within reach of one cast, while the openers
// take perhaps a tenth off attack power in the low thousands at a cost of two
// rounds in the hundreds -- a trade that does not pay even when it works.
int freeRounds() {
    if (last_monster() == $monster[Mer-kin balldodger]
        || last_monster() == $monster[Mer-kin netdragger]
        || last_monster() == $monster[Mer-kin bladeswitcher]
        || last_monster() == $monster[Georgepaul, the Balldodger]
        || last_monster() == $monster[Johnringo, the Netdragger]
        || last_monster() == $monster[Ringogeorge, the Bladeswitcher])
        return 1;
    return 0;
}

// The bladeswitcher's "bust" makes it take 1 damage from all sources and returns
// the full amount the attack would have dealt to the caster, for ten rounds.
// Countering it needs Ball Bust, which unlocks on the fifth underwater critical
// hit with a Mer-kin dodgeball equipped and so is out of reach here, and going
// physical does not help: the reflect covers every damage source. The answer is
// to stop dealing damage until it lapses.
//
// Both tells are carried by the response to a submitted action. A monster's
// messages are written in its half of a round, so the page returned for that
// round's action is what holds them; a later request for the fight page is a
// different response, and does not carry them -- a read taken between actions
// comes back clean however live the reflect is.
//
// So the tell is read from the action itself. Every combat function hands its
// response back: attack(), use_skill() and throw_item() all return the round's
// page. No extra request, and nothing that can go stale between the two.
//
// The page main() is handed covers the one round this cannot: whatever resolved
// before the consult was given the fight. It is stamped with the round it
// describes, because main() can spend rounds of its own before reaching the
// point where it is read.
string entryPage;
int entryRound;

// How many rounds of stalling a round's response calls for, 0 for none.
//
// Two messages, not one, and they mean different things. The twirl is the
// reflect going live, and it runs ten rounds from there. The dope move is the
// wind-up one round earlier: the twirl lands at the end of the round after it,
// so the reflect covers the ten rounds after that -- eleven from here. Arming on
// the wind-up gives up the one round the wind-up still allows, which is the
// price of not having to trust that allowance; the twirl re-arms the full ten
// when it lands, so the count corrects itself either way.
int reflectStall(string page) {
    if (!isBladeswitcher())
        return 0;
    if (contains_text(page, "twirling his blade around himself"))
        return 10;
    if (contains_text(page, "an especially dope move"))
        return 11;
    return 0;
}

// Hands a round's response to whatever reads it later. main() spends rounds of
// its own before the fight reaches cleanUp(), and the tell can land in any of
// them; without this the entry page is the round the consult opened on, which
// by construction predates every special the monster could have used.
void noteRound(string page) {
    entryPage = page;
    entryRound = current_round();
}

// Returns the rounds of stall the openers uncovered, 0 if they saw nothing.
// Each opener is read as it is thrown and stops the rest when it finds a tell:
// the meteorite and the Time-Spinner both deal damage, which a live reflect
// would hand straight back.
int develOpeners() {
    int stall = 0;
    // No daily cap on this one. _micrometeoriteUses models potency, not a
    // ration: the delevel opens at 25% and loses a point per use down to a floor
    // of 10%. Mafia's daily-limit table carries a row for Macrometeorite and no
    // row for this -- that ten-a-day limit belongs to the other skill, counted
    // by a preference one letter away, and wearing it here switched the opener
    // off partway through the run. At ten uses the delevel is still 15%, three
    // times what the Time-Spinner takes and the largest single step of the
    // three.
    //
    // It does not stagger, so unlike the Time-Spinner its round is one the
    // monster attacks in. That is the same price the first ten casts already
    // paid; whether it is worth paying belongs to the gate below, which asks
    // whether the monster can still land a hit, and not to a use count.
    if (have_skill($skill[Micrometeorite])
        && current_round() > 0
        && my_buffedstat($stat[moxie]) + 10 < monster_attack()) {
        stall = reflectStall(to_string(use_skill($skill[Micrometeorite])));
        if (stall > 0) return stall;
    }
    if (item_amount($item[Time-Spinner]) > 0
        && current_round() > 0
        && my_buffedstat($stat[moxie]) + 10 < monster_attack()) {
        stall = reflectStall(to_string(throw_item($item[Time-Spinner])));
        if (stall > 0) return stall;
    }
    if (have_skill($skill[Curse of Weaksauce])
        && my_mp() >= mp_cost($skill[Curse of Weaksauce])
        && current_round() > 0
        && my_buffedstat($stat[moxie]) + 10 < monster_attack())
        stall = reflectStall(to_string(use_skill($skill[Curse of Weaksauce])));
    return stall;
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

// Finish off the enemy with saucegeyser, guarded against infinite loops.
// Every cast is affordability-checked in place: mafia skips an
// unaffordable in-combat cast WITHOUT advancing the round, so a fixed
// MP floor that disagrees with the effective cost turns the stall guard
// into a mid-fight abort. When no cast is affordable the fight finishes
// on plain attacks INSIDE this function: most callers sit in a
// generated CCS whose next line is a hard abort, so handing back an
// open fight would kill the run mid-combat.
// Is there one of these to spare? Yog-Urt's fight throws a sea gel and a
// Pungent Unguent among others, and the colosseum does not reliably come after
// her -- the Gummiheart wait can reach a colosseum round while she is pending --
// so one of each is held back while she is still ahead. Her pulled items (the
// healscroll, the New Age healing crystal, the soggy used band-aid) are never
// touched at all.
//
// No once-per-combat filter, unlike yogHealing(): an ordinary fight takes a
// second unguent quite happily, so stock is the only limit. item_amount() is
// read straight -- combat items are deducted as the fight page is parsed, which
// shubDelevel() below already relies on when it re-checks its stock between
// funkslings.
boolean stallSpare(item it) {
    int reserved = get_property("yogUrtDefeated") == "false" ? 1 : 0;
    return item_amount(it) > reserved;
}

// One round of dealing no damage. Every branch here MUST advance the round: a
// stall round that does not is indistinguishable from a hung fight, and the
// guard that catches it aborts while the fight is still open -- the one thing
// cleanUp() promises never to do.
//
// That rules out the free delevelers, tempting as they look. Micrometeorite and
// the Time-Spinner are once per combat and develOpeners() may already have
// thrown both at the top of this same cleanUp(), so a second submission risks
// being refused by KoL without the round moving. (Their daily counters say nothing about it --
// _micrometeoriteUses tracks potency decay across fights, not use within one.)
//
// What is left always advances: throwing an item, and a plain attack. Both
// thrown items are chosen because a thrown item deals no damage and so reflects
// none; the difference between them is what they give back.
//
// Sea gel restores 500 HP, which is the only thing here that outpaces a stall
// costing 110-175 a round over ten rounds -- so it leads once the damage has
// bitten. The unguent heals 3-5, beneath notice, and is simply the cheap way to
// spend a round; at 30 meat it is the one to burn while HP holds. Gel again
// when the unguent runs out, since even a wasted heal beats a swing that comes
// straight back. A plain attack pays its own weapon damage into us, which is
// why it is the floor rather than a choice.
// Returns the round's response, so the caller can see a reflect renewed under a
// stall that was already running.
string stallRound() {
    if (my_hp() * 2 < my_maxhp() && stallSpare($item[sea gel]))
        return to_string(throw_item($item[sea gel]));
    if (stallSpare($item[Doc Galaktik's Pungent Unguent]))
        return to_string(throw_item($item[Doc Galaktik's Pungent Unguent]));
    if (stallSpare($item[sea gel]))
        return to_string(throw_item($item[sea gel]));
    return to_string(attack());
}

void cleanUp() {
    int loopCount = 0;  // declared outside loop so the guard actually works
    int stalled = 0;    // stall rounds spent in total, across re-arms
    boolean opened = false;  // the openers get one pass, on a clear round
    // Whatever resolved before the consult was handed the fight: an autoattack,
    // a free kill, a delevel step. Every round from here on is read off the
    // action that produced it, but that one is only in the entry page.
    //
    // Aged by the rounds that have passed since. main() routinely spends its
    // own before reaching here -- bang potions to the fifth round, then a free
    // kill -- and a countdown started back then has that much less of it left.
    // Taking the full ten regardless would stall well past the reflect, in the
    // one zone whose fights are long enough for the round limit to matter.
    int elapsed = current_round() - entryRound;
    // Clamped, not trusted. Mafia resyncs its round counter to KoL's when the
    // two disagree, and a monster swap restarts the fight's numbering, either
    // of which can leave the stamp ahead of the current round -- and a negative
    // elapsed would read as a stall to serve against a monster that never had
    // a reflect, spending healing items reserved elsewhere.
    if (elapsed < 0)
        elapsed = 0;
    int stallLeft = reflectStall(entryPage) - elapsed;
    if (stallLeft < 0)
        stallLeft = 0;
    while (current_round() > 0) {
        int round = current_round();
        if (stallLeft > 0) {
            string stallPage = stallRound();
            // Only a round that actually happened burns the countdown, and the
            // special can land again mid-stall -- a blind ten would resume
            // casting into a reflect that had been renewed under it. A fight
            // won on a stall round leaves current_round() at 0, which is
            // progress, not a stuck round: scoring it as one would abort a
            // fight we just finished.
            if (current_round() != round) {
                stallLeft -= 1;
                stalled += 1;
                // Bounded, because a fight has a round limit and idling into
                // it is a loss of its own. A monster renewing the special
                // faster than it can be waited out is not a fight that stalling
                // wins, so past this many stalled rounds the fight is taken
                // back and allowed to end one way or the other.
                if (current_round() > 0 && stalled < 14) {
                    int renewed = reflectStall(stallPage);
                    if (renewed > stallLeft)
                        stallLeft = renewed;
                }
            } else {
                loopCount += 1;
                if (loopCount > 3)
                    abort("May be stuck in an infinite saucegeyser loop");
            }
            continue;
        }
        // In a monster's free opening rounds the nuke leads and the openers
        // wait behind it. Deleveling there spends the rounds no special can
        // reach on buying a lower attack for rounds that a finished fight then
        // never has, and it pushes the cast out of those rounds and into the
        // first one the monster can answer.
        //
        // Note the test is on the fight's own round, not on rounds spent since
        // this loop started. Anything that acted earlier in the fight -- a free
        // kill, a thrown item -- has already given the monster an action to wind
        // up in, so the opening is spent whether or not this loop spent it.
        //
        // Conditional on there being a nuke to lead with. Once the mana is gone
        // the ladder is plain attacks, and then the openers are worth more than
        // the damage they delay: they cost nothing, and they are the only thing
        // that reads a reflect before any damage is dealt.
        //
        // Afterwards they go first as usual, and wait for a clear round rather
        // than being skipped for the fight. A fight handed over mid-reflect
        // still wants the monster delevelled once that reflect lapses, and it
        // would otherwise go the whole way undelevelled while being stalled
        // against. They report a reflect that went up while they were being
        // thrown, which is the case that loses the fight: the ladder's first
        // cast would go into it.
        boolean leadWithNuke = current_round() <= freeRounds()
            && ((have_skill($skill[saucegeyser]) && my_mp() >= mp_cost($skill[saucegeyser]))
                || (have_skill($skill[saucestorm]) && my_mp() >= mp_cost($skill[saucestorm])));
        if (!opened && !leadWithNuke) {
            opened = true;
            stallLeft = develOpeners();
            // They deal damage, so they can also end the fight outright; go
            // back to the loop test rather than casting into a finished one.
            if (stallLeft > 0 || current_round() == 0)
                continue;
        }
        // Recaptured here rather than at the top of the pass, because the
        // openers above spend up to three rounds of their own. Measured from
        // before them, the health test would charge one cast with four rounds
        // of ordinary hits and stall on the total, and the stuck-round test
        // would compare against a round that had already moved.
        round = current_round();
        int hpBefore = my_hp();
        // Affordability ladder, not a skill-ownership fork: a geyser-knower
        // whose MP has dropped into saucestorm range still storms instead
        // of handing the fight to plain attacks. A Seal Clubber smacks
        // with muscle instead of casting off a dump stat -- Lunging
        // Thrust-Smack hits harder and more often -- EXCEPT when the
        // current outfit was built as a spell nuke (the Sorceress phase
        // maximizes "spell damage percent, mys"): buffed mys above buffed
        // muscle means the geyser is the prepared weapon, keep it.
        string actionPage;
        if (my_class() == $class[seal clubber]
            && have_skill($skill[Lunging Thrust-Smack])
            && my_buffedstat($stat[muscle]) >= my_buffedstat($stat[mysticality])
            // The colosseum phase maximizes spell damage, but on a Seal
            // Clubber whose muscle still leads -- so the stat test above
            // cannot see that build and has to be told. Measured in the
            // same trip: a geyser hit a gladiator for 1880 where the smack
            // did 480, and a netdragger heals ~1000 a round, which is the
            // difference between killing it and never touching it.
            && my_location() != $location[Mer-kin Colosseum]
            // Physical-resistant monsters (shadow rift creatures are 100%,
            // vs a 90% elemental cap) turn LTS into a ~1-damage grind to
            // the 30-round loss; leave them to the spells.
            && last_monster().physical_resistance < 50
            && my_mp() >= mp_cost($skill[Lunging Thrust-Smack])) {
            actionPage = to_string(use_skill($skill[Lunging Thrust-Smack]));
        } else if (have_skill($skill[saucegeyser])
            && my_mp() >= mp_cost($skill[saucegeyser])) {
            actionPage = to_string(use_skill($skill[saucegeyser]));
        } else if (have_skill($skill[saucestorm])
            && my_mp() >= mp_cost($skill[saucestorm])) {
            // The shell's damage lands a round after it is cast, which is a
            // round no read can protect: a reflect going up in between catches
            // the payload with the caster already committed. Against the one
            // monster that reflects, a slightly bigger storm is not worth a
            // self-hit that arrives after the decision is made.
            if (have_skill($skill[Stuffed Mortar Shell])
                && !isBladeswitcher()
                && my_mp() >= mp_cost($skill[Stuffed Mortar Shell]) + mp_cost($skill[saucestorm]))
                use_skill($skill[Stuffed Mortar Shell]);
            actionPage = to_string(use_skill($skill[saucestorm]));
        } else {
            attackCleanUp();
            break;
        }
        // The response to the cast just made, which is where the wind-up and
        // the twirl are written. Reading it here is what stops the NEXT cast
        // going into the reflect, and the wind-up half of it means that next
        // cast is usually one that was never going to be allowed anyway.
        stallLeft = reflectStall(actionPage);
        // The health test is not redundant with the message read. It costs
        // nothing, assumes nothing about the wording, and catches the reflect
        // from its signature alone: a single round that takes a large bite out
        // of us is one we just paid for ourselves.
        if (stallLeft == 0 && isBladeswitcher() && hpBefore - my_hp() > 400)
            stallLeft = 10;
        if (round == current_round()) {
            loopCount += 1;
            if (loopCount > 3)
                abort("May be stuck in an infinite saucegeyser loop");
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
        // Factor table lives in globals.ash, shared with the prep projection.
        float f = shubDelevelFactor(d);
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
    entryPage = page_text;
    entryRound = round;
    // Pearl farming spends plain turns: free kills, free runs, Forces and
    // copies advance neither a zone's pearl progress nor screechCombats,
    // so every trick below would burn a charge for zero progress.
    if (get_property("_utsPearlFarm") == "true") {
        // cleanUp() finishes MP-dry fights on plain attacks itself now;
        // these are fights the walker already priced as winnable at full
        // strength, and only a plain win ticks pearl progress.
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
    duplicateMonster(last_monster(), page_text);
    // Deterministic diver: insurance egg, then Use the Force hands over every
    // non-conditional drop and ends the fight -- nothing below applies.
    if (diverForce(last_monster(), page_text))
        return;
    // Same trick down the Force priority ladder: the outpost healer's
    // prayerbeads, the sea cow's leather and cowbells, the researcher's
    // scrolls -- each from its own tier of the budget.
    if (healerForce(last_monster(), page_text))
        return;
    if (seaCowForce(last_monster(), page_text))
        return;
    if (researcherForce(last_monster(), page_text))
        return;
    // +50% item drops for this fight, before anything has a chance to end it.
    becomeBat(page_text);
    // +200% item on the diver itself, three a day, before free_kill can end it.
    otoscope(last_monster(), page_text);
    // Free stench jelly off any stench monster; NCforce() spends it as a sneak.
    extractJelly(last_monster(), page_text);
    // Re-roll a wrong monster at Fitzsimmons rather than spending a turn on it.
    // On a re-roll the fight holds a NEW monster. Returning would fall through
    // to the CCS's safety abort line -- mafia does NOT re-invoke a consult
    // script that returns mid-combat -- so restart the dispatch loop with the
    // new monster and a re-fetched page, which also resyncs mafia's round
    // counter after the swap.
    if (replaceEnemy(last_monster(), page_text)) {
        mob = last_monster();
        page_text = to_string(visit_url("fight.php"));
        continue;
    }
    // Chain another free diver off this one.
    lectureOnRelativity(mob, page_text);
    while (available_amount($item[murky potion]) > 0 && current_round() > 0 && current_round() < 5 && mob != $monster[sea cowboy]){
        string bangPage;
        if (have_skill($skill[Ambidextrous Funkslinging]))
            bangPage = to_string(throw_items(bangA(),bangB()));
        else
            bangPage = to_string(throw_item(bangA()));
        // These are rounds like any other: a special can resolve in one of
        // them, and the response is the only place it is written. Hand it on,
        // and stop throwing once one turns up -- some of these deal damage.
        noteRound(bangPage);
        if (reflectStall(bangPage) > 0)
            break;
    }
    if ((highShiny() || !have_item($item[closed-circuit pay phone])) && item_amount($item[sea lasso]) > 5 && my_location().environment == "underwater" && to_int(get_property("lassoTrainingCount")) < 6)
        noteRound(to_string(throw_item($item[sea lasso])));
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
            if (!free_monster(last_monster()))
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
            if (last_monster() == $monster[shadow slab]) {
                if (item_amount($item[Septapus summoning charm]) > 0)
                    throw_item($item[Septapus summoning charm]);
                use_if_have_skill(page_text, $skill[swoop like a bat]);
                use_if_have_skill(page_text, $skill[Perpetrate Mild Evil]);
                while (to_int(get_property("_douseFoeUses")) < 3
                    && get_property("_douseFoeSuccess") == "false"
                    && current_round() < 25)
                    use_skill($skill[douse foe]);
            }
            if (last_monster() == $monster[tumbleweed])
                abort("Unexpected mob encountered in shadow rift");
            if (!can_still_steal() || available_amount($item[pristine fish scale]) < 6)
                use_if_have_skill(page_text, $skill[Sea *dent: Talk to Some Fish]);
            darts();
            cleanUp();
            break;

        case $location[an octopus's garden]:
            if (have_effect($effect[Citizen of a Zone]) == 0 && my_familiar() == $familiar[patriotic eagle])
                use_skill($skill[%fn, let's pledge allegiance to a Zone]);
            if (last_monster() == $monster[neptune flytrap]) {
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
            } else if (!free_monster(last_monster())) {
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
            if (last_monster() != $monster[unholy diver] && !free_monster(last_monster())){
                free_run(page_text, true);
                if (last_monster() == $monster[Mer-kin scavenger]){
                    if (have_equipped($item[spring shoes]))
                        use_skill($skill[spring kick]);
                    else 
                        use_if_have_skill(page_text,$skill[Sea *dent: Throw a Lightning Bolt]);
                    use_skill($skill[Sea *dent: Talk to Some Fish]);
                }
                if (last_monster() == $monster[Mine crab]){
                    use_skill($skill[Heartstone: %banish]);
                    use_if_have_skill(page_text,$skill[Sea *dent: Throw a Lightning Bolt]);
                }
            }
            if (last_monster() == $monster[unholy diver]){
                if (my_familiar() == $familiar[Melodramedary]){
                    use_skill($skill[%fn, spit on them!]);
                }
                if (have_equipped($item[Fourth of May Cosplay Saber]));
                    use_skill($skill[Use the Force]);
            }
            if (current_round() > 0)
                feelNostalgic(last_monster(), page_text);
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
            if (last_monster() == $monster[mer-kin miner]){
                steal();
                use_if_have_skill(page_text,$skill[swoop like a bat]);
            }
            // The corral gate applies to both targets: sniffing feeds the
            // step4 pearl hunt, which is over once the corral has started.
            if (((last_monster() == $monster[giant squid] && !contains_text(get_property("trackedMonsters"), "giant squid"))
                || (last_monster() == $monster[Mer-kin tippler] && !contains_text(get_property("trackedMonsters"), "Mer-kin tippler")))
                && $location[The coral corral].turns_spent == 0) {
                foreach sk in $skills[transcendent olfaction,
                    Gallapagosian Mating Call, MCHUGELARGE SLASH]
                    use_if_have_skill(page_text, sk);
            }
            if (free_monster(last_monster())) {
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
            if ((last_monster() != $monster[giant squid] || item_amount($item[comb jelly]) > 0)
                && last_monster() != $monster[Mer-kin tippler]
                && (last_monster() != $monster[Mer-kin miner] || item_amount($item[mer-kin digpick]) > 0)) {
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
            if (last_monster() == $monster[time cop]) {
                darts();
                cleanUp();
                break;
            }
            if (last_monster() == $monster[black crayon golem]) {
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
                if (my_familiar() != $familiar[sword of s words] && (highShiny() || !have_item($item[closed-circuit pay phone]) || lowShiny()) && available_amount($item[pristine fish scale]) < 6 && !free_monster(mob)){
                    use_skill($skill[Sea *dent: Talk to Some Fish]);
                    cleanUp();
                }
                if (last_monster() == $monster[mer-kin healer]
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
                } else if (last_monster() == $monster[Mer-kin burglar]
                    || last_monster() == $monster[Mer-kin raider]) {
                    if ((highShiny() || !have_item($item[closed-circuit pay phone])) && my_familiar() == $familiar[sword of s words] && !banishUsedAtYourLocation("Sea *dent"))
                        use_skill($skill[sea *dent: throw a lightning bolt]);
                    free_run(page_text, true);
                }
                if (!free_monster(last_monster()))
                    free_kill(page_text, false);
                cleanUp();
            } else {
                // turns_spent >= 24 and no lockkey monster
                if (last_monster() == $monster[mer-kin burglar] || last_monster() == $monster[mer-kin raider])
                    free_run(page_text, true);
                free_kill(page_text,
                    last_monster() == $monster[mer-kin healer]
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
            if (last_monster() == $monster[eye in the darkness] || last_monster() == $monster[slithering thing]) {
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
                    if (last_monster() == $monster[sea cow]){
                        use_skill($skill[%fn, kill a lot of these guys]);
                        cleanUp();
                    }
                } else if (have_equipped($item[backup camera])) {
                    if (last_monster() == $monster[mer-kin rustler])
                        use_skill($skill[spring kick]);
                    use_skill($skill[Back-Up to your Last Enemy]);
                    use_skill($skill[BCZ: Refracted Gaze]);
                    use_skill($skill[Do an epic McTwist!]);
                    free_kill(page_text, true);
                    cleanUp();
                } else {
                    if (last_monster() == $monster[mer-kin rustler]){
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
                if (last_monster().phylum == $phylum[plant])
                    use_skill($skill[Tear Away your Pants!]);
                if (get_property("seahorseName") == "") {
                    if ((!contains_text(get_property("banishedMonsters"), "sea cow:")
                        && !contains_text(get_property("banishedMonsters"), "sea cowboy"))
                        || (!contains_text(get_property("banishedMonsters"), "Mer-kin rustler")
                        && !contains_text(get_property("banishedMonsters"), "sea cowboy"))
                        || (!contains_text(get_property("banishedMonsters"), "sea cow:")
                        && !contains_text(get_property("banishedMonsters"), "Mer-kin rustler"))){
                            if (last_monster() == $monster[Mer-kin rustler] && get_property("_curveballFightsLeft").to_int() > 0 && get_property("_curveballMonster") == "some fish"){
                                use_if_have_skill(page_text, $skill[Sea *dent: Talk to Some Fish]);
                                if (last_monster() == $monster[some fish])
                                    cleanUp();
                            }
                            free_run(page_text, true);
                            if (last_monster() == $monster[mer-kin rustler]){
                                if (have_skill($skill[heartstone: %banish]) && get_property("heartstoneBanishUnlocked") == "true"){
                                    use_skill($skill[heartstone: %banish]);
                                } 
                            } else if (last_monster() == $monster[sea cowboy]){
                                use_skill($skill[Sea *dent: Throw a Lightning Bolt]);
                            } else if (last_monster() == $monster[sea cow]){
                                use_skill($skill[Sea *dent: Throw a Lightning Bolt]);
                            }
                        }
                }
                // The waffle is a monster changer, and in this zone that makes
                // it the thing that summons a wild seahorse. A seahorse has no
                // exit but the tamer above: it is BOSS, so runs, banishes and
                // copies do not touch it, and it carries defence and health in
                // the hundreds of thousands behind full physical and elemental
                // resistance, so every hit lands for 1. Summoned without the
                // three cowbells and the lasso that tame it, the fight can only
                // end on the round limit, and the corral draws the monster on
                // its own often enough that arriving short of the pair is not
                // hypothetical. So the summon carries the tamer's own item test.
                //
                // Only the summon. A seahorse already in front of us has come
                // past the tamer, which declined it, and this throw is the last
                // thing left to try -- narrowing that would take away an exit
                // rather than an entrance.
                //
                // The name test is the same idea once removed: with the prize
                // already collected there is nothing to summon one for, and the
                // items are worth more spent elsewhere. It bounds what this
                // throw creates and nothing else -- the tamer above carries no
                // such test, so a seahorse the corral deals out on its own is
                // still handled the way it always was.
                if (item_amount($item[waffle]) > 0
                    && !contains_text(get_property("_lastCombatActions"), "it11311")
                    && (last_monster() == $monster[wild seahorse]
                        || (get_property("seahorseName") == ""
                            && item_amount($item[sea lasso]) > 0
                            && item_amount($item[sea cowbell]) >= 3))) {
                    throw_item($item[waffle]);
                    run_combat();
                }
                if (get_property("_curveballFightsLeft").to_int() > 0 && get_property("_curveballMonster") == "some fish"){
                    use_if_have_skill(page_text, $skill[Sea *dent: Talk to Some Fish]);
                    if (last_monster() == $monster[some fish])
                        cleanUp();
                }
                // The sea cowboy is the only monster here that drops a sea
                // lasso, so running from one while short of a lasso keeps the
                // shortage running too -- and the shortage is exactly what turns
                // a seahorse into a fight with no ending. Kill it instead and
                // take the drop chance.
                if (last_monster() != $monster[sea cowboy]
                    || item_amount($item[sea lasso]) > 0)
                    free_run(page_text, false);
                free_kill(page_text, false);
                cleanUp();
            } else {
                if (last_monster() == $monster[wild seahorse]) {
                    runaway( );
                } else if (last_monster() == $monster[mer-kin rustler]){
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
                } else if (last_monster() == $monster[sea cow] && doneWithSeaCow()){
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
                } else if (last_monster() == $monster[sea cowboy] && doneWithCowboy()){
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
                    feelNostalgic(last_monster(), page_text);
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
            if (last_monster() == $monster[peanut] && to_int(get_property("lastColosseumRoundWon")) < 15) {
                if (have_item($item[august scepter]) && have_item($item[2002 Mr. Store Catalog]) && have_skill($skill[just the facts]) && have_familiar($familiar[patriotic eagle]) && (available_amount($item[waffle]) > 1 || (available_amount($item[waffle]) == 1 && get_property("seahorseName") != "")))
                    throw_item($item[waffle]);
                else 
                    cleanUp();
                run_combat();
            } else if (free_monster(last_monster())) {
                cleanUp();
            } else {
                if (item_amount($item[spooky VHS tape]) > 0
                    && get_property("spookyVHSTapeMonster") == ""
                    && to_int(get_property("momSeaMonkeeProgress")) < 36
                    && $monsters[slithering thing, eye in the darkness,
                        school of many] contains last_monster())
                    throw_item($item[spooky VHS tape]);
                if (get_property("_monsterHabitatsRecalled") != "3" && get_property("_monsterHabitatsFightsLeft") == "0" && !highShiny() && (have_item($item[server room key]) || $location[The Mer-Kin Outpost].turns_spent < 29)) {
                    if ($monsters[slithering thing, eye in the darkness] contains last_monster())
                        use_skill($skill[RECALL FACTS: MONSTER HABITATS]);
                }
                if (last_monster() == $monster[school of many]) {
                    use_if_have_skill(page_text, $skill[Sea *dent: Throw a Lightning Bolt]);
                    for i from 1 to 4
                        use_skill($skill[garbage nova]);
                }
                free_kill(page_text, false);
                cleanUp();
            }
            break;

        case $location[Mer-kin Elementary School]:
            if (free_monster(last_monster())) {
                use_if_have_skill(page_text, $skill[BCZ: Refracted Gaze]);
                if (have_equipped($item[legendary seal-clubbing club]) && to_int(get_property("_clubEmBattlefieldUsed")) < 5 && get_property("NCtoC") != "true"){
                    use_skill($skill[Club 'Em Across the Battlefield]);
                } else {
                    cleanUp();
                }
            } else if (last_monster() == $monster[Mer-kin teacher]
                || last_monster() == $monster[Mer-kin punisher]
                || last_monster() == $monster[Mer-kin monitor]) {
                if (have_equipped($item[spring shoes])
                    && !banishUsedAtYourLocation("Spring Kick")) {
                    if ((last_monster() == $monster[mer-kin teacher]
                        && item_amount($item[mer-kin bunwig]) > 0)
                        || (last_monster() == $monster[mer-kin punisher]
                        && item_amount($item[mer-kin mouthsoap]) > 0))
                        use_skill($skill[spring kick]);
                }
                if (free_monster(to_monster(get_property("lastCopyableMonster")))
                    && to_int(get_property("_backUpUses")) < 11
                    && have_equipped($item[backup camera])) {
                    use_skill($skill[Back-Up to your Last Enemy]);
                    if (get_property("NCtoC") != "true")
                        use_if_have_skill(page_text, $skill[BCZ: Refracted Gaze]);
                if (have_equipped($item[legendary seal-clubbing club]) && get_property("NCtoC") == "false" && to_int(get_property("_clubEmBattlefieldUsed")) < 5)
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
            if (cheatsheetsNeeded() && last_monster() != $monster[Mer-kin monitor]
                && !free_monster(last_monster()) && current_round() > 0
                && rerollEnemy(page_text)) {
                // Re-dispatch: see the replaceEnemy note up top.
                mob = last_monster();
                page_text = to_string(visit_url("fight.php"));
                continue;
            }
            // Kill path from here on -- the safe spot for a Feel Nostalgic
            // charge on the monitor's cheatsheet table.
            if (current_round() > 0)
                feelNostalgic(last_monster(), page_text);
            if (bcz_gaze_ready() && get_property("NCtoC") != "true") {
                use_skill($skill[Sea *dent: Talk to Some Fish]);
                if (to_monster(get_property("lastEncounter")) != $monster[none] && item_amount($item[mer-kin cheatsheet]) < 10)
                    use_skill($skill[BCZ: Refracted Gaze]);
            }
            free_kill(page_text, true);
            cleanUp();
            break;

        case $location[Mer-kin Library]:
            if (free_monster(last_monster())) {
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
                if (free_monster(last_monster())) {
                    if (bcz_gaze_ready())
                        use_skill($skill[BCZ: Refracted Gaze]);
                } else {
                    if (item_amount($item[mer-kin knucklebone]) == 0) {
                        if (bcz_gaze_ready()) {
                            use_skill($skill[Sea *dent: Talk to Some Fish]);
                            use_skill($skill[BCZ: Refracted Gaze]);
                        }
                    } else if (last_monster() == $monster[Mer-kin alphabetizer]) {
                        use_skill($skill[spring kick]);
                    } else if (last_monster() == $monster[Mer-kin drifter]) {
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
            if (free_monster(last_monster())) {
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
            if (last_monster() == $monster[Yog-Urt, Elder Goddess of Hatred]){
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
            if (last_monster() == $monster[Dad Sea Monkee]){
                cli_execute("dad");
                abort("execute spells in the above order, can use shrap instead of toynado and volcanometeor instead of awesome balls of fire");
            }
            break;
    }

    // ── Monster-based logic (runs after location logic) ───────────────────────
    switch (last_monster()) {
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
