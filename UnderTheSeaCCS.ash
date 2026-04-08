import iotm.ash;
void free_kill(string ptext, boolean drop){
    foreach freeskill in $skills[Assert your Authority,Club 'Em Back in Time,BCZ: Sweat Bullets,Shattering Punch,Gingerbread Mob Hit,Darts: Aim for the Bullseye]{
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
            }
            if (banish == true && freeskill == $skill[spring away]){
                use_skill($skill[spring kick]);
            }
            use_skill(freeskill);
        }
    }
    foreach freecombat in $items[anchor bomb,stuffed yam stinkbomb,handful of split pea soup,mer-kin pinkslip,ink bladder]{
        if (item_amount(freecombat) > 0){
            if (banish == false && (freecombat == $item[anchor bomb] || freecombat == $item[stuffed yam stinkbomb] || freecombat == $item[handful of split pea soup])){
                continue;
            }
            if (freecombat == $item[mer-kin pinkslip]){
                print(last_monster());
                abort();
            }
            throw_item(freecombat);
        }
    }
}

void main(int round, monster mob, string page_text){
    switch (my_location()){
        case $location[The Haunted Pantry]:
            if(have_equipped($item[monodent of the sea])){
                use_skill($skill[Sea *dent: Talk to Some Fish]);
            }
            if (have_skill($skill[Prepare to reanimate your Foe])){
                use_skill($skill[Prepare to reanimate your Foe]);
            }
            use_skill($skill[Darts: Throw at %part1]);
            use_skill($skill[saucegeyser]);
            use_skill($skill[saucegeyser]);
            break;
        case $location[Shadow Rift (The Misspelled Cemetary)]:
            if (mob.boss == true){
                if (mob == $monster[shadow orrery]){
                    attack();
                    attack();
                    attack();
                    attack();
                    attack();
                    attack();
                    attack();
                    attack();
                    attack();
                }
                if (mob == $monster[shadow spire]){
                    use_skill($skill[raise backup dancer]);
                    use_skill($skill[raise backup dancer]);
                }
                use_skill($skill[Darts: Throw at %part1]);
                use_skill($skill[Saucegeyser]);
                use_skill($skill[Saucegeyser]);
                use_skill($skill[Saucegeyser]);
            }
            if (get_property("_seadentWaveUsed") == true && to_int(get_property("lassoTrainingCount")) < 20){
                throw_item($item[sea lasso]);
            }
            if (mob == $monster[shadow slab] && item_amount($item[Septapus summoning charm]) > 0){
               throw_item($item[Septapus summoning charm]);
            }
            if (to_int(get_property("_batWingsSwoopUsed")) < 11)
                use_skill($skill[swoop like a bat]);
            if (mob == $monster[shadow slab]){
                while(to_int(get_property("_mildEvilPerpetrated")) < 3)
                    use_skill($skill[Perpetrate Mild Evil]);
                int n = 0;
                while (to_int(get_property("_douseFoeUses")) < 3 && get_property("_douseFoeSuccess") == false && n < 23){
                    use_skill($skill[douse foe]);
                    n += 1;
                }
            }
            if(have_equipped($item[monodent of the sea])){
                use_skill($skill[Sea *dent: Talk to Some Fish]);
            }
            use_skill($skill[Darts: Throw at %part1]);
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
            use_skill($skill[Darts: Throw at %part1]);
            free_kill(page_text,true);
            break;
        case $location[The Marinara Trench]:
            if (mob == $monster[giant squid] && !contains_text(get_property("trackedMonsters"),"giant squid")){
                use_skill($skill[transcendent olfaction]);
                use_skill($skill[MCHUGELARGE SLASH]);
            }
            if (mob == $monster[black crayon golem]){
                if (to_int(get_property("_clubEmNextWeekUsed")) < 5){
                    use_skill($skill[Club 'Em Into Next Week]);
                } else if (to_int(get_property("clubEmBattlefieldUsed")) < 5){
                    use_skill($skill[Club 'Em across the battlefield]);
                }
                use_skill($skill[Saucegeyser]);
                use_skill($skill[Saucegeyser]);
            }
            if(have_equipped($item[monodent of the sea]) && mob != $monster[giant squid] && mob != $monster[time cop]){
                use_skill($skill[Sea *dent: Talk to Some Fish]);
                use_skill($skill[BCZ: Refracted Gaze]);
            }
            if (to_int(get_property("_dartsLeft")) > 1)
                use_skill($skill[Darts: Throw at %part1]);
            free_kill(page_text,true);
            break;
        case $location[The Dive Bar]:
            if (mob == $monster[Mer-kin tippler] && !contains_text(get_property("trackedMonsters"),"Mer-kin tippler")){
                use_skill($skill[transcendent olfaction]);
                use_skill($skill[MCHUGELARGE SLASH]);
            }
            if (mob == $monster[black crayon golem]){
                if (to_int(get_property("_clubEmNextWeekUsed")) < 5){
                    use_skill($skill[Club 'Em Into Next Week]);
                } else if (to_int(get_property("clubEmBattlefieldUsed")) < 5){
                    use_skill($skill[Club 'Em across the battlefield]);
                }
                use_skill($skill[Saucegeyser]);
                use_skill($skill[Saucegeyser]);
            }
            if(have_equipped($item[monodent of the sea]) && mob != $monster[Mer-kin tippler] && mob != $monster[time cop]){
                use_skill($skill[Sea *dent: Talk to Some Fish]);
            }
            if( mob != $monster[Mer-kin tippler]){
                use_skill($skill[BCZ: Refracted Gaze]);
            }
            if (to_int(get_property("_dartsLeft")) > 1)
                use_skill($skill[Darts: Throw at %part1]);
            free_kill(page_text,true);
            break;
        case $location[The Mer-Kin Outpost]:
            if (mob == $monster[time cop]){
                    use_skill($skill[Darts: Throw at %part1]);
                    use_skill($skill[saucegeyser]);
                    use_skill($skill[saucegeyser]);
            }
            if (mob == $monster[black crayon golem]){
                if (get_property("_monsterHabitatsFightsLeft") == "0" && have_effect($effect[everything looks purple]) == 0 && to_int(get_property("_monsterHabitatsRecalled")) == 2){
                    use_skill($skill[blow the purple candle]);
                } else if (get_property("_monsterHabitatsFightsLeft") == "0" && to_int(get_property("_monsterHabitatsRecalled")) < 2){
                    use_skill($skill[RECALL FACTS: MONSTER HABITATS]);
                } else if (get_property("_monsterHabitatsFightsLeft") == "0" && have_effect($effect[everything looks purple]) == 0){
                    abort();
                }
                if (get_property("_monsterHabitatsFightsLeft") == "0" && to_int(get_property("_monsterHabitatsRecalled")) >= 2 && my_familiar() == $familiar[Patriotic Eagle]){
                    use_skill($skill[%fn, Release the Patriotic Screech!]);
                }
                use_skill($skill[Darts: Throw at %part1]);
                use_skill($skill[saucegeyser]);
                use_skill($skill[saucegeyser]);
            }
            if ($location[The Mer-Kin Outpost].turns_spent < 24 || get_property("merkinLockkeyMonster") != ""){
                if (get_property("_monsterHabitatsFightsLeft") == "0" && to_int(get_property("_monsterHabitatsRecalled")) >= 2 && to_int(get_property("_backUpUses")) < 11){
                    if (get_property("lastCopyableMonster") != "Black Crayon Golem"){
                    //    abort();
                    } else {
                        use_skill($skill[Back-Up to your Last Enemy]);
                        run_combat();
                    }
                }
                if (mob == $monster[mer-kin healer] && item_amount($item[mer-kin prayerbeads]) < 2){
                    free_kill(page_text,true);
                    free_run(page_text,false);
                    use_skill($skill[saucegeyser]);
                    use_skill($skill[saucegeyser]);
                }
                if (have_skill($skill[spring kick]) && have_effect($effect[Everything Looks Green]) == 0){
                    use_skill($skill[spring kick]);
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
            } else {
                abort();
            }
            break;
        case $location[The skate park]:
            abort();
            break;
        case $location[cyberzone 1]:
            if (mob == $monster[eye in the darkness] || mob == $monster[slithering thing]){
                int n;
                while (n < 20){
                    use_skill($skill[Throw Cyber Rock]);
                    n += 1;
                }
                use_skill($skill[Throw Cyber Rock]);
                use_skill($skill[Throw Cyber Rock]);
                use_skill($skill[Throw Cyber Rock]);
                use_skill($skill[Throw Cyber Rock]);
            } else {
                use_skill($skill[Sea *dent: Throw a Lightning Bolt]);
            }
            use_skill($skill[saucegeyser]);
            use_skill($skill[saucegeyser]);
            use_skill($skill[saucegeyser]);
            break;
        case $location[cyberzone 2]:
            use_skill($skill[saucegeyser]);
            use_skill($skill[saucegeyser]);
            use_skill($skill[saucegeyser]);
            break;
        case $location[cyberzone 3]:
            use_skill($skill[saucegeyser]);
            use_skill($skill[saucegeyser]);
            use_skill($skill[saucegeyser]);
            break;
        case $location[An Unusually Quiet Barroom Brawl]:
            if (get_property("lastCopyableMonster") == "eye in the darkness"){
                use_skill($skill[Back-Up to your Last Enemy]);
                use_skill($skill[RECALL FACTS: MONSTER HABITATS]);
                use_skill($skill[saucegeyser]);
                use_skill($skill[saucegeyser]);
                use_skill($skill[saucegeyser]);
            } else {
                abort("Can't copy eye in darkness");
            }
            break;
        case $location[The Coral Corral]:
            if (item_amount($item[sea cowbell]) == 0){
                if (mob == $monster[wild seahorse]){
                    if (item_amount($item[waffle]) > 1){
                        throw_item($item[waffle]);
                        run_combat();
                    } else {
                        abort();
                    }
                    free_run(page_text,false);
                    runaway();
                }
                if (mob == $monster[mer-kin rustler] || mob == $monster[Bugged bugbear]){
                    if (mob == $monster[mer-kin rustler])
                        use_skill($skill[spring kick]);
                    use_skill($skill[BCZ: Refracted Gaze]);
                    use_skill($skill[Do an epic McTwist!]);
                    use_skill($skill[BCZ: Sweat Bullets]);
                }
                if (mob != $monster[mer-kin rustler]){
                    if (item_amount($item[waffle]) <= 1){
                        throw_item($item[software glitch]);
                        run_combat();
                    } else {
                        throw_item($item[waffle]);
                        run_combat();
                    }
                }
            } else if (item_amount($item[sea cowbell]) >= 2){
                if (mob != $monster[wild seahorse]){
                    if (get_property("seahorseName") == ""){
                        if ((!contains_text(get_property("banishedMonsters"),"sea cow:") && !contains_text(get_property("banishedMonsters"),"sea cowboy")) || (!contains_text(get_property("banishedMonsters"),"mer-kin rustler") && !contains_text(get_property("banishedMonsters"),"sea cowboy")) || (!contains_text(get_property("banishedMonsters"),"sea cow:") && !contains_text(get_property("banishedMonsters"),"mer-kin rustler")))
                            free_run(page_text,true);
                    }
                    if (item_amount($item[waffle]) > 0 && !contains_text(get_property("_lastCombatActions"),"it11311")){
                        throw_item($item[waffle]);
                        run_combat();
                    } else if (item_amount($item[waffle]) == 0){
                        abort();
                    }
                    if (mob == $monster[wild seahorse]){
                        throw_items($item[sea cowbell],$item[sea cowbell]);
                        throw_items($item[sea cowbell],$item[sea lasso]);
                    }
                    free_kill(page_text,false);
                    free_run(page_text,true);
                    attack();
                    attack();
                }
                if (mob == $monster[wild seahorse]){
                    throw_items($item[sea cowbell],$item[sea cowbell]);
                    throw_items($item[sea cowbell],$item[sea lasso]);
                } else {
                    if (mob.phylum == $phylum[plant]){
                        use_skill($skill[Tear Away your Pants!]);
                    } else {
                        free_run(page_text,false);
                    }
                    free_kill(page_text,false);
                }
            } else {
                abort();
            }
            break;
        case $location[The Caliginous Abyss]:
            if (mob == $monster[peanut]){
                throw_item($item[sea lasso]);
                use_skill($skill[eggsplosion]);
                use_skill($skill[eggsplosion]);
                use_skill($skill[eggsplosion]);
            } else if(mob == $monster[time cop]) {
                use_skill($skill[saucegeyser]);
            } else {
                if (item_amount($item[spooky VHS tape]) > 0 && get_property("spookyVHSTapeMonster") == "")
                    throw_item($item[spooky VHS tape]);
                if (get_property("_monsterHabitatsRecalled") != "3" && get_property("_monsterHabitatsFightsLeft") == "0" && (mob == $monster[slithering thing] || mob == $monster[eye in the darkness]) && get_property("corralUnlocked") == "true") {
                    use_skill($skill[RECALL FACTS: MONSTER HABITATS]);
                } else if (get_property("_monsterHabitatsRecalled") != "3" && get_property("_monsterHabitatsFightsLeft") == "0" && get_property("corralUnlocked") == "true"){
                    abort("Use waffle");
                }
                free_kill(page_text,false);
                use_skill($skill[saucegeyser]);
                use_skill($skill[saucegeyser]);
            }
            break;
        case $location[Mer-kin Elementary School]:
            if (mob.phylum == $phylum[dude]){
                use_skill($skill[BCZ: Refracted Gaze]);
                if (to_int(get_property("_clubEmBattlefieldUsed")) < 5)
                    use_skill($skill[Club 'Em Across the Battlefield]);
            } else if (mob == $monster[Mer-kin teacher] || mob == $monster[Mer-kin punisher] || mob == $monster[Mer-kin monitor]){
                if ((get_property("lastCopyableMonster") == "kid who is too old to be Trick-or-Treating" || get_property("lastCopyableMonster") == "suburban security civilian" || get_property("lastCopyableMonster") == "vandal kid" || get_property("lastCopyableMonster") == "Black Crayon Golem") && to_int(get_property("_backUpUses")) < 11){
                    use_skill($skill[Back-Up to your Last Enemy]);
                    use_skill($skill[BCZ: Refracted Gaze]);
                    use_skill($skill[Club 'Em Across the Battlefield]);
                }
//                if ((mob == $monster[Mer-kin teacher] && item_amount($item[mer-kin bunwig]) > 0) || (mob == $monster[Mer-kin punisher] && item_amount($item[Mer-kin mouthsoap]) > 0))
            } else if (mob == $monster[Mer-kin monitor] && item_amount($item[mer-kin bunwig]) > 0){
                if (to_int(get_property("_clubEmBattlefieldUsed")) < 5)
                    use_skill($skill[Club 'Em Across the Battlefield]);
            }
            use_skill($skill[Sea *dent: Talk to Some Fish]);
            use_skill($skill[BCZ: Refracted Gaze]);
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
                if (mob.phylum == $phylum[dude]){
                    use_skill($skill[BCZ: Refracted Gaze]);
                } else {
                    if (item_amount($item[mer-kin knucklebone]) == 0){
                        use_skill($skill[Sea *dent: Talk to Some Fish]);
                        use_skill($skill[BCZ: Refracted Gaze]);
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
                } else {
                    use_skill($skill[Sea *dent: Talk to Some Fish]);
                    use_skill($skill[BCZ: Refracted Gaze]);
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
            print("Monster hp is " + monster_hp())
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
                abort();
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
        case $monster[time cop]:
            use_skill($skill[Darts: Throw at %part1]);
            use_skill($skill[saucegeyser]);
            use_skill($skill[saucegeyser]);
            break;
        case $monster[black crayon golem]:
            if (get_property("_monsterHabitatsFightsLeft") == "0" && to_int(get_property("_monsterHabitatsRecalled")) < 3){
                use_skill($skill[RECALL FACTS: MONSTER HABITATS]);
            }
            if (!contains_text(get_property("trackedMonsters"),"black crayon golem:McHugeLarge Slash")){
                use_skill($skill[MCHUGELARGE SLASH]);
                use_skill($skill[transcendent olfaction]);
                use_skill($skill[Club 'Em Into Next Week]);
            }
            use_skill($skill[Darts: Throw at %part1]);
            break;
        case $monster[unholy diver]:
            if (my_familiar() == $familiar[chest mimic]){
                use_skill($skill[%fn, lay an egg]);
                use_skill($skill[%fn, lay an egg]);
            }
            if (have_effect($effect[Everything Looks yellow]) == 0){
                use_skill($skill[Spit jurassic acid]);
            } else {
                free_kill(page_text,true);
            }
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