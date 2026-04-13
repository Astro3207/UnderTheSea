import iotm.ash;
void free_kill(string ptext, boolean drop){
    foreach freeskill in $skills[Spit jurassic acid,Assert your Authority,Club 'Em Back in Time,Darts: Aim for the Bullseye,BCZ: Sweat Bullets,Shattering Punch,Gingerbread Mob Hit]{
        if (freeskill == $skill[Club 'Em Back in Time] && my_location() != $location[mer-kin colosseum]){
            continue;
        }
        if (contains_text(ptext, to_string(freeskill)))
            use_skill(freeskill);
    }
    foreach freecombat in $items[shadow brick,groveling gravel]{
        if (item_amount(freecombat) > 0){
            if (freecombat == $item[groveling gravel] && drop == true)
                continue;
            if (freecombat == $item[shadow brick] && to_int(get_property("_shadowBricksUsed")) == 13)
                continue;
            throw_item(freecombat);
        }
    }
}
void free_run(string ptext, boolean banish){
    foreach freeskill in $skills[spring away,snokebomb]{
        if (contains_text(ptext, to_string(freeskill))){
            if (banish == false && freeskill == $skill[snokebomb]){
                continue;
            } else if (banish == true && banishUsedAtYourLocation("snokebomb") && freeskill == $skill[snokebomb]){
                continue;
            }
            if (banish == true && freeskill == $skill[spring away]){
                use_skill($skill[spring kick]);
            }
            use_skill(freeskill);
        }
    }
    foreach freecombat in $items[peppermint parasol,anchor bomb,stuffed yam stinkbomb,handful of split pea soup,mer-kin pinkslip,ink bladder]{
        if (item_amount(freecombat) > 0){
            if (banish == false && (freecombat == $item[anchor bomb] || freecombat == $item[stuffed yam stinkbomb] || freecombat == $item[handful of split pea soup])){
                continue;
            }
            if (freecombat == $item[peppermint parasol] && to_int(get_property("parasolUsed")) > 3){
                continue;
            }
            if (freecombat == $item[mer-kin pinkslip] && last_monster().phylum != $phylum[mer-kin]){
                continue;
            }
            throw_item(freecombat);
        }
    }
}
void main(int round, monster mob, string page_text){
    switch (my_location()){
        case $location[The Outskirts of Cobb's Knob]:
        case $location[The Sleazy Back Alley]:
        case $location[The Haunted Pantry]:
            if(have_equipped($item[monodent of the sea])){
                use_skill($skill[Sea *dent: Talk to Some Fish]);
            }
            if (have_skill($skill[Prepare to reanimate your Foe])){
                use_skill($skill[Prepare to reanimate your Foe]);
            }
            darts();
            use_skill($skill[saucegeyser]);
            use_skill($skill[saucegeyser]);
            break;
        case $location[Shadow Rift (The Misspelled Cemetary)]:
            if (my_primestat() == $stat[moxie])
                steal();
            if (get_property("_seadentWaveUsed") == true && to_int(get_property("lassoTrainingCount")) < 20 && item_amount($item[sea cowbell]) > 0)
                throw_item($item[sea lasso]);
            if (mob == $monster[shadow slab]){
                if (item_amount($item[Septapus summoning charm]) > 0)
                    throw_item($item[Septapus summoning charm]);
                if (to_int(get_property("_batWingsSwoopUsed")) < 11)
                    use_skill($skill[swoop like a bat]);
                while(to_int(get_property("_mildEvilPerpetrated")) < 3)
                    use_skill($skill[Perpetrate Mild Evil]);
                int n = 0;
                while (to_int(get_property("_douseFoeUses")) < 3 && get_property("_douseFoeSuccess") == false && n < 23){
                    use_skill($skill[douse foe]);
                    n += 1;
                }
            }
            if (have_equipped($item[monodent of the sea])){
                use_skill($skill[Sea *dent: Talk to Some Fish]);
            }
            darts();
            use_skill($skill[Saucegeyser]);
            use_skill($skill[Saucegeyser]);
            break;
        case $location[an octopus's garden]:
            if (have_effect($effect[Citizen of a Zone]) == 0){
                use_skill($skill[%fn, let's pledge allegiance to a Zone]);
            }
            if (have_effect($effect[Everything Looks Red, White and Blue]) == 0){
                use_skill($skill[%fn, fire a Red, White and Blue Blast]);
            }
            if (mob == $monster[neptune flytrap]){
                darts();
                if (have_equipped($item[McHugeLarge left pole]) && !contains_text(get_property("trackedMonsters"),"Neptune flytrap")){
                    use_skill($skill[transcendent olfaction]);
                    use_skill($skill[MCHUGELARGE SLASH]);
                }
                free_kill(page_text,true);
            } else if (mob == $monster[time cop]){
                attack();
            } else {
                free_run(page_text,true);
            }
            break;
        case $location[The Marinara Trench]:
            if (mob == $monster[giant squid] && !contains_text(get_property("trackedMonsters"),"giant squid")){
                use_skill($skill[transcendent olfaction]);
                use_skill($skill[MCHUGELARGE SLASH]);
            }
            if (mob == $monster[black crayon golem] || mob == $monster[time cop]){
                use_skill($skill[BCZ: Refracted Gaze]);
                use_skill($skill[Saucegeyser]);
                use_skill($skill[Saucegeyser]);
            }
            if(have_equipped($item[monodent of the sea]) && mob != $monster[giant squid]){
                use_skill($skill[Sea *dent: Talk to Some Fish]);
                use_skill($skill[BCZ: Refracted Gaze]);
            }
            if (to_int(get_property("_dartsLeft")) > 1)
                darts();
            free_kill(page_text,true);
            break;
        case $location[The Dive Bar]:
            if (mob == $monster[Mer-kin tippler] && !contains_text(get_property("trackedMonsters"),"Mer-kin tippler")){
                use_skill($skill[transcendent olfaction]);
                use_skill($skill[MCHUGELARGE SLASH]);
            }
            if (mob == $monster[black crayon golem] || mob == $monster[time cop]){
                use_skill($skill[BCZ: Refracted Gaze]);
                use_skill($skill[Saucegeyser]);
                use_skill($skill[Saucegeyser]);
            }
            if(have_equipped($item[monodent of the sea]) && mob != $monster[Mer-kin tippler]){
                use_skill($skill[Sea *dent: Talk to Some Fish]);
                use_skill($skill[BCZ: Refracted Gaze]);
            }
            if (to_int(get_property("_dartsLeft")) > 1)
                darts();
            free_kill(page_text,true);
            break;
        case $location[The Mer-Kin Outpost]:
            if (mob == $monster[time cop]){
                darts();
                use_skill($skill[saucegeyser]);
                use_skill($skill[saucegeyser]);
            }
            if (mob == $monster[black crayon golem]){
                if (get_property("_monsterHabitatsFightsLeft") == "0" && have_effect($effect[everything looks purple]) == 0 && to_int(get_property("_monsterHabitatsRecalled")) == 2){
                    use_skill($skill[Blow the Purple Candle!]);
                } else if (get_property("_monsterHabitatsFightsLeft") == "0" && to_int(get_property("_monsterHabitatsRecalled")) < 2){
                    use_skill($skill[RECALL FACTS: MONSTER HABITATS]);
                }
                if (get_property("_monsterHabitatsFightsLeft") == "0" && to_int(get_property("_monsterHabitatsRecalled")) >= 2 && my_familiar() == $familiar[Patriotic Eagle]){
                    use_skill($skill[%fn, Release the Patriotic Screech!]);
                }
                darts();
                use_skill($skill[saucegeyser]);
                use_skill($skill[saucegeyser]);
            }
            if ($location[The Mer-Kin Outpost].turns_spent < 24 || get_property("merkinLockkeyMonster") != ""){
                if (get_property("_monsterHabitatsFightsLeft") == "0" && to_int(get_property("_monsterHabitatsRecalled")) >= 2 && to_int(get_property("_backUpUses")) < 7){
                    if (get_property("lastCopyableMonster") != "Black Crayon Golem"){
                        abort("Last copyable monster is supposed to be Black Crayon Golem, but it is " + get_property("lastCopyableMonster"));
                    } else {
                        use_skill($skill[Back-Up to your Last Enemy]);
                        run_combat();
                    }
                }
                if (mob == $monster[mer-kin healer] && item_amount($item[mer-kin prayerbeads]) < 2){
                    free_kill(page_text,true);
                    if (to_int(get_property("_backUpUses")) < 7 && have_equipped($item[backup camera])){
                        use_skill($skill[Back-Up to your Last Enemy]);
                        run_combat();
                    }
                    free_run(page_text,false);
                    use_skill($skill[saucegeyser]);
                    use_skill($skill[saucegeyser]);
                }
                free_run(page_text,true);
                free_kill(page_text,false);
                use_skill($skill[saucegeyser]);
                use_skill($skill[saucegeyser]);
                use_skill($skill[saucegeyser]);
            } else if ($location[The Mer-Kin Outpost].turns_spent >= 24 && get_property("merkinLockkeyMonster") == ""){
                if (mob == $monster[mer-kin healer] && item_amount($item[mer-kin prayerbeads]) < 2){
                    free_kill(page_text,true);
                } else {
                    free_run(page_text,true);
                    free_kill(page_text,false);
                }
                use_skill($skill[saucegeyser]);
                use_skill($skill[saucegeyser]);
                use_skill($skill[saucegeyser]);
            }
            break;
        case $location[The skate park]:
            abort("You hit a combat in skate park, that isn't supposed to happen...");
            break;
        case $location[cyberzone 1]:
            if (mob == $monster[eye in the darkness] || mob == $monster[slithering thing]){
                int n;
                while (n < 25){
                    use_skill($skill[Throw Cyber Rock]);
                    n += 1;
                }
            } else {
                use_skill($skill[Sea *dent: Throw a Lightning Bolt]);
            }
            break;
        case $location[The Coral Corral]:
            if (item_amount($item[sea cowbell]) == 0){
                if (mob == $monster[wild seahorse]){
                    if (item_amount($item[waffle]) > 1){
                        throw_item($item[waffle]);
                        run_combat();
                    } else {
                        abort("Hit seahorse too early and have no waffles for some reason");
                    }
                }
                if (have_equipped($item[backup camera])){
                    if (mob == $monster[mer-kin rustler])
                        use_skill($skill[spring kick]);
                    use_skill($skill[Back-Up to your Last Enemy]);
                    use_skill($skill[BCZ: Refracted Gaze]);
                    use_skill($skill[Do an epic McTwist!]);
                    use_skill($skill[BCZ: Sweat Bullets]);
                }
            } else if (item_amount($item[sea cowbell]) >= 2){
                if (mob.phylum == $phylum[plant])
                    use_skill($skill[Tear Away your Pants!]);
                if (mob != $monster[wild seahorse]){
                    if (get_property("seahorseName") == ""){
                        if ((!contains_text(get_property("banishedMonsters"),"sea cow:") && !contains_text(get_property("banishedMonsters"),"sea cowboy")) || (!contains_text(get_property("banishedMonsters"),"mer-kin rustler") && !contains_text(get_property("banishedMonsters"),"sea cowboy")) || (!contains_text(get_property("banishedMonsters"),"sea cow:") && !contains_text(get_property("banishedMonsters"),"mer-kin rustler")))
                            free_run(page_text,true);
                    }
                    if (item_amount($item[waffle]) > 0 && !contains_text(get_property("_lastCombatActions"),"it11311")){
                        throw_item($item[waffle]);
                        run_combat();
                    } else if (item_amount($item[waffle]) == 0){
                        abort("Ran out of waffles, oops");
                    }
                    free_kill(page_text,false);
                    free_run(page_text,false);
                    attack();
                    attack();
                }
                if (mob == $monster[wild seahorse]){
                    throw_items($item[sea cowbell],$item[sea cowbell]);
                    throw_items($item[sea cowbell],$item[sea lasso]);
                }
            }
            break;
        case $location[The Caliginous Abyss]:
            if (mob == $monster[peanut]){
                throw_item($item[waffle]);
                run_combat();
            } else if(mob == $monster[time cop]) {
                use_skill($skill[saucegeyser]);
            } else {
                if (item_amount($item[spooky VHS tape]) > 0 && get_property("spookyVHSTapeMonster") == "")
                    throw_item($item[spooky VHS tape]);
                if (get_property("_monsterHabitatsRecalled") != "3" && get_property("_monsterHabitatsFightsLeft") == "0" && (mob == $monster[slithering thing] || mob == $monster[eye in the darkness]) && get_property("corralUnlocked") == "true") {
                    use_skill($skill[RECALL FACTS: MONSTER HABITATS]);
                } else if (get_property("_monsterHabitatsRecalled") != "3" && get_property("_monsterHabitatsFightsLeft") == "0" && get_property("corralUnlocked") == "true"){
                    abort("Hit an odd mob at caliginous abyss, should not have happened with peridot");
                }
                free_kill(page_text,false);
                use_skill($skill[saucegeyser]);
                use_skill($skill[saucegeyser]);
            }
            break;
        case $location[Mer-kin Elementary School]:
            if (mob.phylum == $phylum[dude] || mob == $monster[black crayon golem]){
                use_skill($skill[BCZ: Refracted Gaze]);
                if (to_int(get_property("_clubEmBattlefieldUsed")) < 5)
                    use_skill($skill[Club 'Em Across the Battlefield]);
            } else if (mob == $monster[Mer-kin teacher] || mob == $monster[Mer-kin punisher] || mob == $monster[Mer-kin monitor]){
                steal();
      
                if (mob == $monster[Mer-kin monitor]){
                    if (have_equipped($item[bat wings]) && to_int(get_property("_batWingsSwoopUsed")) < 11)
                        use_skill($skill[swoop like a bat]);
                    if (item_amount($item[Septapus summoning charm]) > 0)
                        throw_item($item[Septapus summoning charm]);
                } else if (have_equipped($item[spring shoes]) && !banishUsedAtYourLocation("Spring Kick")){
                    if ((mob == $monster[mer-kin teacher] && item_amount($item[mer-kin bunwig]) > 0) || (mob == $monster[mer-kin punisher] && item_amount($item[mer-kin mouthsoap]) > 0))
                        use_skill($skill[spring kick]);
                }
                if ((get_property("lastCopyableMonster") == "kid who is too old to be Trick-or-Treating" || get_property("lastCopyableMonster") == "suburban security civilian" || get_property("lastCopyableMonster") == "vandal kid" || get_property("lastCopyableMonster") == "Black Crayon Golem") && to_int(get_property("_backUpUses")) < 11){
                    use_skill($skill[Back-Up to your Last Enemy]);
                    use_skill($skill[BCZ: Refracted Gaze]);
                    use_skill($skill[Club 'Em Across the Battlefield]);
                }
            }
            if (my_basestat($stat[mysticality]) > 200){
                use_skill($skill[Sea *dent: Talk to Some Fish]);
                use_skill($skill[BCZ: Refracted Gaze]);
            }
            free_kill(page_text,true);
            use_skill($skill[saucegeyser]);
            use_skill($skill[saucegeyser]);
            use_skill($skill[saucegeyser]);
            use_skill($skill[saucegeyser]);
            break;
        case $location[Mer-kin Library]:
            if (to_int(get_property("merkinVocabularyMastery")) == 100){
                int n;
                while (get_property("dreadScroll5") == "0" && item_amount($item[mer-kin killscroll]) > 0 && n < 5){
                    throw_item($item[mer-kin killscroll]);
                    n+=1;
                }
                n=0;
                if (get_property("dreadScroll2") == "0" && item_amount($item[mer-kin healscroll]) > 0 && n < 5){
                    throw_item($item[mer-kin healscroll]);
                    n+=1;
                }
                if (mob.phylum == $phylum[dude] || mob == $monster[black crayon golem]){
                    use_skill($skill[BCZ: Refracted Gaze]);
                } else {
                    if (item_amount($item[mer-kin knucklebone]) == 0){
                        if (my_basestat($stat[mysticality]) > 200){
                            use_skill($skill[Sea *dent: Talk to Some Fish]);
                            use_skill($skill[BCZ: Refracted Gaze]);
                        }
                    } else if (mob == $monster[Mer-kin alphabetizer]){
                        use_skill($skill[spring kick]);
                    } else if (item_amount($item[mer-kin knucklebone]) > 0 && mob == $monster[Mer-kin drifter]){
                        free_run(page_text,true);
                    }
                    free_kill(page_text,true);
                }
                use_skill($skill[saucegeyser]);
                use_skill($skill[saucegeyser]);
            } else {
                if ((get_property("lastCopyableMonster") == "kid who is too old to be Trick-or-Treating" || get_property("lastCopyableMonster") == "suburban security civilian" || get_property("lastCopyableMonster") == "vandal kid" || get_property("lastCopyableMonster") == "Black Crayon Golem") && to_int(get_property("_backUpUses")) < 11){
                    use_skill($skill[Back-Up to your Last Enemy]);
                    use_skill($skill[BCZ: Refracted Gaze]);
                } else if (mob == $monster[black crayon golem]){
                    use_skill($skill[BCZ: Refracted Gaze]);
                } else {
                    if (my_basestat($stat[mysticality]) > 200){
                        use_skill($skill[Sea *dent: Talk to Some Fish]);
                        use_skill($skill[BCZ: Refracted Gaze]);
                    }
                    free_kill(page_text,true);
                }
            }
            use_skill($skill[saucegeyser]);
            use_skill($skill[saucegeyser]);
            break;
        case $location[Mer-kin Gymnasium]:
            if (mob.phylum == $phylum[dude]){
                use_skill($skill[BCZ: Refracted Gaze]);
            } else {
                free_run(page_text,false);
                free_kill(page_text,false);
            }
            use_skill($skill[saucegeyser]);
            use_skill($skill[saucegeyser]);
            use_skill($skill[saucegeyser]);
            break;
        case $location[Mer-kin Colosseum]:
            if (have_skill($skill[Club 'Em Back in Time]))
                use_skill($skill[Club 'Em Back in Time]);
            if (to_int(get_property("lastColosseumRoundWon")) < 15){
                use_skill($skill[saucegeyser]);
                use_skill($skill[saucegeyser]);
                use_skill($skill[saucegeyser]);
            }
            break;
        case $location[Mer-kin Temple (Right Door)]:
            if (my_maxhp() > 311)
                abort("You have too much HP to beat Yogurt, there is a high likelihood you will lose, figure out what is giving you HP rn, you need less than 312 after being debuffed");
            throw_items($item[crayon shavings],$item[mer-kin healscroll]);
            throw_items($item[Mer-kin mouthsoap],$item[waterlogged scroll of healing]);
            throw_item($item[sea gel]);
            if (equipped_amount($item[mer-kin prayerbeads]) < 3){
                throw_item($item[New Age healing crystal]);
            }
            if (equipped_amount($item[mer-kin prayerbeads]) < 2){
                throw_item($item[soggy used band-aid]);
            }
            use_skill($skill[saucegeyser]);
            use_skill($skill[saucegeyser]);
            use_skill($skill[saucegeyser]);
            use_skill($skill[saucegeyser]);
            use_skill($skill[saucegeyser]);
            use_skill($skill[saucegeyser]);
            break;
        case $location[Mer-kin Temple (Left Door)]:
            throw_items($item[crayon shavings],$item[crayon shavings]);
            throw_items($item[crayon shavings],$item[crayon shavings]);
            throw_items($item[crayon shavings],$item[crayon shavings]);
            throw_items($item[crayon shavings],$item[crayon shavings]);
            attack();
            attack();
            attack();
            attack();
            attack();
            attack();
            attack();
            attack();
            break;
        case $location[Mer-kin Temple (Center Door)]:
            use_skill($skill[raise backup dancer]);
            use_skill($skill[raise backup dancer]);
    }
    switch (mob){
        case $monster[black crayon golem]:
            if (get_property("_monsterHabitatsFightsLeft") == "0" && to_int(get_property("_monsterHabitatsRecalled")) < 3){
                use_skill($skill[RECALL FACTS: MONSTER HABITATS]);
            }
            if (!contains_text(get_property("trackedMonsters"),"black crayon golem:McHugeLarge Slash")){
                use_skill($skill[MCHUGELARGE SLASH]);
                use_skill($skill[transcendent olfaction]);
                use_skill($skill[Club 'Em Into Next Week]);
            }
            break;
        case $monster[unholy diver]:
            if (my_familiar() == $familiar[chest mimic]){
                use_skill($skill[%fn, lay an egg]);
            }
            free_kill(page_text,true);
            break;
        case $monster[kid who is too old to be Trick-or-Treating]:
            use_skill($skill[CLUB 'EM INTO NEXT WEEK]);
            use_skill($skill[Saucegeyser]);
            use_skill($skill[Saucegeyser]);
            break;
        case $monster[suburban security civilian]:
            use_skill($skill[CLUB 'EM INTO NEXT WEEK]);
            use_skill($skill[Saucegeyser]);
            use_skill($skill[Saucegeyser]);
            break;
        case $monster[vandal kid]:
            use_skill($skill[CLUB 'EM INTO NEXT WEEK]);
            use_skill($skill[Saucegeyser]);
            use_skill($skill[Saucegeyser]);
            break;
    }

}
