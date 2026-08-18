import globals;

// The wantedMonster table used by the monster-pickers below now lives in
// iotm.ash, because the Time-Spinner needs it from the main script too.

// ─── HELPERS ──────────────────────────────────────────────────────────────────

// Try each stashbox option in the given priority order, skipping already-checked ones.
void stashboxCheck(int [int] priority) {
    foreach i, opt in priority {
        if (!contains_text(get_property("stashboxChecked"), to_string(opt))) {
            run_choice(opt);
            string checked = get_property("stashboxChecked");
            set_property("stashboxChecked", checked == "" ? to_string(opt) : checked + "," + to_string(opt));
            if (item_amount($item[mer-kin stashbox]) > 0)
                set_property("stashboxFound", to_string(opt));
            return;
        }
    }
}

// Search available choices for the first text match and pick it.
// Returns true if a match was found and chosen.
boolean pickChoice(string keyword) {
    string [int] choices = available_choice_options();
    foreach num, choice_text in choices {
        if (contains_text(choice_text, keyword)) {
            run_choice(num);
            return true;
        }
    }
    return false;
}

// ─── MAIN ─────────────────────────────────────────────────────────────────────

void main(int whichchoice, string page) {
    switch (whichchoice) {

        // ── Simple run_choice(1) cases ─────────────────────────────────────
        case 299:
        case 303:
        case 403:
        case 701:
        case 1059:
        case 1468:
        case 1471:
        case 1472:
        case 1473:
        case 1475:
        case 1556:
        case 1564:
        case 1565:
        case 1566:
            run_choice(1);
            break;

        // ── Simple run_choice(2) cases ─────────────────────────────────────
        case 804:
        case 1469:
        case 1470:
        case 1474:
        case 1494:
        case 1497:
            run_choice(2);
            break;

        // ── Simple run_choice(3) cases ─────────────────────────────────────
        case 1340:
        case 1387:
        case 1467:
        case 1596:
            run_choice(3);
            break;

        // ── Simple run_choice(4) cases ─────────────────────────────────────
        case 705:
            run_choice(4);
            break;

        // ── Simple run_choice(5) cases ─────────────────────────────────────
        case 1599:
            run_choice(5);
            break;

        // ── More complex cases ────────────────────────────────────────────
        case 312:
            if (get_property("intenseCurrents") == "true"){
                run_choice(3);
            }
            break;

        // ── Stashbox searches (different priority orders per lock monster) ──
        case 313: int [int] burglar = {0:1, 1:3, 2:2}; stashboxCheck(burglar); break;  // burglar:  1→3→2
        case 314: int [int] raider = {0:1, 1:2, 2:3}; stashboxCheck(raider); break;  // raider:   1→2→3
        case 315:
            if (get_property("intenseCurrents") == "true"){
                if (available_amount($item[mer-kin prayerbeads]) < 3) {
                    run_choice(3);
                } else if (available_amount($item[mer-kin killscroll]) == 0 && get_property("dreadScroll5") == "0"){
                    run_choice(1);
                } else if (available_amount($item[mer-kin healscroll]) == 0 && get_property("dreadScroll2") == "0") {
                    run_choice(2);
                } else {
                    // Nothing needed -- still answer the choice, or mafia drops
                    // to manual control mid-automation. Beads never hurt.
                    run_choice(3);
                }
            } else {
                int [int] healer = {0:3, 1:1, 2:2}; stashboxCheck(healer);
            }
            break;  // healer:   3→1→2

        // ── Mer-kin school ────────────────────────────────────────────────
        case 396:
        case 397:
        case 398:
            if (get_property("elementaryQueue") == "")
                set_property("elementaryQueue","000, 000, 000, 000, 000");
            buffer elementaryQueue = to_buffer(get_property("elementaryQueue"));
            append(elementaryQueue, ", " + last_choice());
            delete(elementaryQueue,0,5);
            set_property("elementaryQueue",to_string(elementaryQueue));
            break;
        case 399:
        case 400:
            elementaryQueue = to_buffer(get_property("elementaryQueue"));
            append(elementaryQueue, ", " + last_choice());
            delete(elementaryQueue,0,5);
            set_property("elementaryQueue",to_string(elementaryQueue));
            set_property("NCtoC","true");
            run_choice(1);
            break;
        case 401:
            elementaryQueue = to_buffer(get_property("elementaryQueue"));
            append(elementaryQueue, ", " + last_choice());
            delete(elementaryQueue,0,5);
            set_property("elementaryQueue",to_string(elementaryQueue));
            run_choice(2);
            break;

        // ── Dread scroll puzzle ───────────────────────────────────────────
        case 703:
            int Scroll7;
            string knownScroll7 = get_property("dreadScroll7");
            string scrollPrefix = get_property("dreadScroll1") + get_property("dreadScroll2")
                + get_property("dreadScroll3") + get_property("dreadScroll4")
                + get_property("dreadScroll5") + get_property("dreadScroll6");
            string scrollSuffix = get_property("dreadScroll8");
            string guesses = get_property("dreadScrollGuesses");

            if (to_int(knownScroll7) != 0) {
                Scroll7 = to_int(knownScroll7);
            } else {
                foreach candidate in $ints[4, 3, 2, 1] {
                    if (!contains_text(guesses, scrollPrefix + candidate + scrollSuffix)) {
                        Scroll7 = candidate;
                        break;
                    }
                }
            }
            run_choice(1, "pro1=" + get_property("dreadScroll1")
                + "&pro2=" + get_property("dreadScroll2")
                + "&pro3=" + get_property("dreadScroll3")
                + "&pro4=" + get_property("dreadScroll4")
                + "&pro5=" + get_property("dreadScroll5")
                + "&pro6=" + get_property("dreadScroll6")
                + "&pro7=" + Scroll7
                + "&pro8=" + get_property("dreadScroll8"));
            waitq(3);
            if (have_effect($effect[Deep-Tainted Mind]) == 0)
                set_property("dreadScroll7", Scroll7);
            break;

        // ── Dread card ────────────────────────────────────────────────────
        case 704:
            if (get_property("catalogChecked") == "false"){
                set_property("catalogChecked","true");
                foreach num, choice_text in available_choice_options() {
                    set_property("cardChoice" + num, choice_text);
                }
            }
            int dread;
            foreach num, choice_text in available_choice_options() {
                string code = choice_text.substring(0, choice_text.index_of(":"));
                if (contains_text(get_property("merkinCatalogChoices"), code + ":" + num + ":unknown")) {
                    dread = num;
                    break;
                }
            }
            // No unknown card left to spade: pick the first option rather than
            // calling run_choice(0), which errors out of the choice handler.
            if (dread == 0)
                dread = 1;
            string choice = available_choice_options()[dread];
            run_choice(dread);
            if (get_property("DS1") == false && get_property("dreadScroll1") != 0){
                set_property("DS1","true");
                for x from 1 to 10{
                    if (get_property("cardChoice" + x) == choice)
                        set_property("cardChoice" + x, insert(to_buffer(get_property("cardChoice" + x)),0,"1:"));
                }
            } else if (get_property("DS6") == false && get_property("dreadScroll6") != 0){
                set_property("DS6","true");
                for x from 1 to 10{
                    if (get_property("cardChoice" + x) == choice)
                        set_property("cardChoice" + x, insert(to_buffer(get_property("cardChoice" + x)),0,"6:"));
                }
            } else if (get_property("DS8") == false && get_property("dreadScroll8") != 0){
                set_property("DS8","true");
                for x from 1 to 10{
                    if (get_property("cardChoice" + x) == choice)
                        set_property("cardChoice" + x, insert(to_buffer(get_property("cardChoice" + x)),0,"8:"));
                }
            }
            break;

        // ── Map the Monsters ───────────────────────────────────────
        // "Leading Yourself Right to Them". Same intent as the Peridot, but a
        // different parameter name. Only cast in zones we have a preference
        // for, so the lookup should always hit; if it somehow does not, fall
        // through and let mafia resolve rather than pick a monster at random.
        case 1435:
            location mapHere = my_location();
            int mapTarget = zoneTarget(mapHere);
            if (mapTarget > 0)
                run_choice(1, "heyscriptswhatsupwinkwink=" + mapTarget);
            break;

        case 1483:
            run_choice(1);
            run_choice(3);
            break;

        case 1500:
            if (have_effect($effect[Shadow Waters]) == 0){
                run_choice(2);
            } else if (get_property("_shadowForestLooted") == "false"){
                run_choice(3);
            } else {
                run_choice(2);
            }
            break;

        // ── Everfull dart perk picker ─────────────────────────────────────
        case 1525:
            foreach num, choice_text in available_choice_options() {
                print(`{num}: {choice_text}`);
            }
            foreach perk in $strings[impress, better, targeting, Butt] {
                if (pickChoice(perk)) exit;
            }
            run_choice(1);
            break;

        // ── Peridot monsters ───────────────────────────────────────
        // The same table drives Map the Monsters (1435) below, so the two
        // monster-pickers can never disagree about what we want in a zone.
        case 1557:
            set_property("NCtoC","true");
            location here = my_location();
            int target = zoneTarget(here);
            if (target > 0) {
                run_choice(1, "bandersnatch=" + target);
                if (here == $location[The Coral Corral]) run_choice(2);
            }
            break;

        // ── Mobius strip ──────────────────────────────────────────────────
        case 1562:
            string [int] mobiusKeywords = {
                1: "arch-nemesis",
                2: "trifecta",
                3: "Go back and write a best-seller",
                4: "Replace your novel with AI drivel"
            };
            int encounter = to_int(get_property("_mobiusStripEncounters"));
            if (mobiusKeywords contains encounter)
                pickChoice(mobiusKeywords[encounter]);
            else{
                if (!pickChoice("investment tips"))
                    pickChoice("from your future self");
            }
            break;
    }
}
