import iotm;

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
        case 399:
        case 400:
        case 403:
        case 701:
        case 1556:
        case 1564:
        case 1565:
        case 1566:
            run_choice(1);
            break;

        // ── Stashbox searches (different priority orders per lock monster) ──
        case 313: int [int] burglar = {0:1, 1:3, 2:2}; stashboxCheck(burglar); break;  // burglar:  1→3→2
        case 314: int [int] raider = {0:1, 1:2, 2:3}; stashboxCheck(raider); break;  // raider:   1→2→3
        case 315: int [int] healer = {0:3, 1:1, 2:2}; stashboxCheck(healer); break;  // healer:   3→1→2

        // ── Mer-kin school ────────────────────────────────────────────────
        case 401:
            run_choice(have_equipped($item[mer-kin bunwig]) ? 2 : 1);
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
            foreach num, choice_text in available_choice_options() {
                set_property("cardChoice" + num, choice_text);
            }
            int dread = to_int(to_boolean(to_int(get_property("dreadScroll1"))))
                + to_int(to_boolean(to_int(get_property("dreadScroll6"))))
                + to_int(to_boolean(to_int(get_property("dreadScroll8"))))
                + 1;
            run_choice(dread);
            break;

        case 705:
            run_choice(4);
            break;

        // ── Underwater zone run_choice(2) cases ───────────────────────────
        case 1469:
        case 1470:
        case 1474:
        case 1494:
            run_choice(2);
            break;

        case 1467:
            run_choice(3);
            break;

        // ── Shadow rift ───────────────────────────────────────────────────
        case 1468:
        case 1471:
        case 1472:
        case 1473:
        case 1475:
            run_choice(1);
            break;

        case 1497:
            run_choice(2);
            break;

        case 1500:
            run_choice(have_effect($effect[Shadow Waters]) == 0 ? 2 : 3);
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
            break;

        // ── Peridot monsters ───────────────────────────────────────
        case 1557:
            int [location] banderMonster = {
                $location[An Octopus's Garden]:      740,
                $location[The Coral Corral]:         772,
                $location[The Marinara Trench]:      763,
                $location[The Dive Bar]:             768,
                $location[Cyberzone 1]:             2458,
                $location[the caliginous abyss]:    1373,
                $location[mer-kin elementary school]: 838
            };
            location here = my_location();
            if (banderMonster contains here) {
                run_choice(1, "bandersnatch=" + banderMonster[here]);
                if (here == $location[The Coral Corral]) run_choice(2);
            }
            break;

        // ── Jelly ─────────────────────────────────────────────────────────
        case 1589:
            if (my_location() == $location[The Marinara Trench]) {
                abort();
            } else {
                run_choice(1, "victim=852");
            }
            break;
    }
}
