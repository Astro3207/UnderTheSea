import iotm.ash;
string choiceStorage = get_property("choiceAdventureScript");
string seaFit;
boolean seaOutfit(){
    boolean bool;
    foreach str in $strings[Crappy Mer-kin Disguise, Mer-kin Gladiatorial Gear, Mer-kin Scholar's Vestments]{
        if (have_outfit(str)){
            seaFit = str;
            bool = true;
            break;
        }
    }
    return bool;}
item divingHelmet(){
    cli_execute("refresh all");
    item it;
    foreach ite in $items[aerated diving helmet,crappy Mer-kin mask,Mer-kin gladiator mask,Mer-kin scholar mask]{
        if (item_amount(ite) > 0 || have_equipped(ite))
            it = ite;
    }
    return it;
}
boolean tailpiece(){
    boolean bool;
    foreach it in $items[teflon swim fins,crappy Mer-kin tailpiece,Mer-kin gladiator tailpiece,Mer-kin scholar tailpiece]{
        if (item_amount(it) > 0 || have_equipped(it))
            bool = true;
    }
    return bool;
}
int mineNum(){
    int num;
    int x_coor;
    int y_coor;
    string itzmine = visit_url("mining.php?mine=3");
    matcher mining_spot = create_matcher("Promising Chunk of Wall \\((\\d+),(\\d+)\\)", itzmine);
    foreach str in $strings[(3\,6),(3\,5),(3\,4),(3\,3),(3\,2),(2\,2),(4\,2),(5\,2)]{
        if (!contains_text(itzmine,"Open Cavern " + str)){
            matcher open_spot = create_matcher("(\\d),(\\d)",str);
            if (open_spot.find()){
                x_coor = to_int(open_spot.group(1));
                y_coor = to_int(open_spot.group(2));
                num = (8 * y_coor) + x_coor;
                break;
            }
        }
    }
    if (num == 0){
        abort("mine manually, still scripting out optimal strat");
    }
        //while (mining_spot.find()){
          //  x_coor = to_int(mining_spot.group(1));
          //  y_coor = to_int(mining_spot.group(2));
          //  print(x_coor+", "+y_coor);
          //  if (y_coor >= 4){
          //      continue;
          //  }
          //  num = (8 * y_coor) + x_coor;
          //  break;
        //}
    return num;}
void mood(string mod){
    switch (mod){
        case "itdrop":
            foreach ef in $effects[Who's Going to Pay This Drunken Sailor?,Fat Leon's Phat Loot Lyric,Lubricating Sauce,Thoughtful Empathy,Singer's Faithful Ocelot,Leash of Linguini,Empathy,Spice Haze, donho's bubbly ballad, the ballad of richie thingfinder]{
                if (have_effect(ef) == 0){
                    cli_execute(ef.default);
                }
            }
            break;
        case "noncom":
            foreach ef in $effects[the sonata of sneakiness, ultra-soft steps, Wild and Westy!, hiding from seekers,life goals, Smooth Movements,Apriling Band Patrol Beat,silent running]{
                if (have_effect(ef) == 0){
                    if (ef == $effect[ultra-soft steps] && item_amount($item[ultra-soft ferns]) == 0)
                        continue;
                    if (ef == $effect[life goals] && item_amount($item[Life Goals Pamphlet]) == 0)
                        continue;
                    cli_execute(ef.default);
                }
            }
            if (have_effect($effect[Apriling Band Patrol Beat]) == 0 && total_turns_played() >= to_int(get_property("nextAprilBandTurn"))){
                cli_execute("aprilband effect nc");
            }
            break;
        case "combat":
            foreach ef in $effects[Carlweather's Cantata of Confrontation,Fresh Breath,Musk of the Moose,Crunchy Steps,Towering Muscles,Attracting Snakes,Bloodbathed]{
                if (have_effect(ef) == 0){
                    if (ef == $effect[ultra-soft steps] && item_amount($item[ultra-soft ferns]) == 0)
                        break;
                    if (ef == $effect[Crunchy Steps] && item_amount($item[crunchy brush]) == 0)
                        break;
                    cli_execute(ef.default);
                }
            }
            if (have_effect($effect[Apriling Band Battle Cadence]) == 0 && total_turns_played() >= to_int(get_property("nextAprilBandTurn"))){
                cli_execute("aprilband effect c");
            }
            break;
        case "hotres":
            foreach ef in $effects[Astral Shell,Wildsun Boon,Minor Invulnerability,Elemental Saucesphere,materiel intel,There's No N in Love,Incredibly Well Lit,Who's Going to Pay This Drunken Sailor?,Fat Leon's Phat Loot Lyric,Lubricating Sauce,Thoughtful Empathy]{
                if (ef == $effect[Minor Invulnerability] && item_amount($item[scroll of minor invulnerability]) == 0)
                    continue;
                if (have_effect(ef) == 0)
                    cli_execute(ef.default);
            }
            break;
        case "sleazeres":
            foreach ef in $effects[Astral Shell,Wildsun Boon,Minor Invulnerability,Elemental Saucesphere, scarysauce]{
                if (ef == $effect[Minor Invulnerability] && item_amount($item[scroll of minor invulnerability]) == 0)
                    continue;
                if (have_effect(ef) == 0)
                    cli_execute(ef.default);
            }
            break;
        case "colosseum":
            foreach ef in $effects[Ultraheart,Carol of the Hells,Elron's Explosive Etude,Big,Favored by Lyle,The Magical Mojomuscular Melody,Tubes of Universal Meat,Mariachi Moisture]{
                if (have_effect(ef) == 0)
                    cli_execute(ef.default);
            }
            break;
    }
}
string freeRun(){
    string free;
    if (have_effect($effect[Everything Looks Green]) == 0){
        free = ", equip spring shoes";
    }
    return free;
}
string freeKill(){
    string free;
    if (have_effect($effect[Everything Looks Red]) == 0){
        free = ", equip everfull dart";
    } else if ((my_basestat( $stat[submoxie])-22500) > BCZcost("SweatBulletsCasts")){
        free = ", equip blood cubic zirconia";
    }
    return free;
}
string shrunkenHead(){
    string head;
    if (get_property("shrunkenHeadZombieMonster") == "")
        head = ", equip shrunken head";
    return head;}
void spading(){
    buffer spading;
    spading = append(spading,today_to_string( ));
    spading = append(spading,","+to_string(my_id()));
    spading = append(spading,","+my_class());
    spading = append(spading,","+my_ascensions());
    for x from 1 to 8{
        spading = append(spading,","+get_property("dreadScroll"+x));
    }
    int [string] lockkey {
        "Mer-kin burglar":313,
        "Mer-kin raider":314,
        "Mer-kin healer":315
    };
    spading = append(spading,","+to_string(lockkey[get_property("merkinLockkeyMonster")]));
    spading = append(spading,","+get_property("stashboxFound"));
    if (my_id() == 2813285){
        print(spading);
        print(get_property("merkinCatalogChoices"));
        print(get_property("cardChoice1") + " and " + get_property("cardChoice2") + " and " + get_property("cardChoice3"));
    } else {
        if (user_confirm("Send spading into to Fart?"))
            cli_execute("Send to fart scauce " + spading + " " + get_property("merkinCatalogChoices") + " " + get_property("cardChoice1") + " and " + get_property("cardChoice2") + " and " + get_property("cardChoice3"));
    }
}
void shadowRift(){
    if (have_effect($effect[shadow waters]) == 0){
        if (get_property("questRufus") == "unstarted")
            use($item[closed-circuit pay phone]);
        if (get_property("questRufus") == "started"){
            NCforce();
            adv1($location[Shadow Rift (The Misspelled Cemetary)],0,"");
        }
        if (get_property("_seadentWaveUsed") == false){
            use_skill($skill[Sea *dent: Summon a Wave]);
        }
        use($item[closed-circuit pay phone]);
        adv1($location[Shadow Rift (The Misspelled Cemetary)],0,"");
    } else {
        if (to_int(get_property("encountersUntilSRChoice")) > 9 && get_property("questRufus") == "unstarted" && item_amount($item[Closed-circuit pay phone]) > 0){
            maximize("item drop, equip Flash Liquidizer Ultra Dousing Accessory, equip bat wings, equip everfull dart holster, equip monodent of the sea",false);
            use($item[closed-circuit pay phone]);
        }
        if (have_effect($effect[shadow affinity]) > 0){
            if (item_amount($item[sea lasso]) == 0 && item_amount($item[sea cowbell]) > 0){
                cli_execute("equip really nice swimming trunks; equip little bitty; monkeypaw item sea lasso");
            }
            if (item_amount($item[sea lasso]) == 0 && item_amount($item[sea cowbell]) > 0){
                abort("need more lassos somehow");
            }
            use_familiar($familiar[jill-of-all-trades]);
            if (to_int(get_property("lassoTrainingCount")) < 20 && item_amount($item[sea cowbell]) > 0){
                maximize("item drop, equip Flash Liquidizer Ultra Dousing Accessory, equip bat wings, equip everfull dart holster, equip monodent of the sea, equip sea cowboy hat, equip sea chaps, equip toy cupid bow",false);
            } else {
                maximize("item drop, equip Flash Liquidizer Ultra Dousing Accessory, equip bat wings, equip everfull dart holster, equip monodent of the sea, equip toy cupid bow",false);
            }
            adv1($location[Shadow Rift (The Misspelled Cemetary)],0,"");
            if (get_property("_seadentWaveUsed") == false && have_effect($effect[shadow affinity]) > 0){
                adv1($location[Shadow Rift (The Misspelled Cemetary)],0,"");
                use_skill($skill[Sea *dent: Summon a Wave]);
            }
            if (get_property("encountersUntilSRChoice") == "0")
                adv1($location[Shadow Rift (The Misspelled Cemetary)],0,"");
        }
    }
}
void post_adv(){
	if (get_property("_lastCombatLost") == "true")
		abort("It appears you lost the last combat, look into that");
    if (my_adventures() == 0){
        if (item_amount($item[astral pilsner]) == 0 && item_amount($item[astral six-pack]) > 0){
            use($item[astral six-pack]);
            use_skill($skill[the ode to booze]);
            drink($item[astral pilsner]);
        } else if (item_amount($item[astral pilsner]) > 0){
            use_skill($skill[the ode to booze]);
            drink($item[astral pilsner]);
        } else {
            abort("no more easy diet");
        }
    }
    if (get_property("autumnatonQuestLocation") == ""){
        if ($location[Shadow Rift (The Misspelled Cemetary)].turns_spent == 0){
            cli_execute("autumnaton send noob cave");
            //can optimize
        } else {
            cli_execute("autumnaton send Shadow Rift");
        }
    }
    if (have_effect($effect[fishy]) == 0){
        if (get_property("_fishyPipeUsed") == "false" && item_amount($item[closed-circuit pay phone]) > 0 && have_item($item[Monodent of the Sea]) && have_item($item[Platinum Yendorian Express Card])){
            cli_execute("pull fishy pipe");
            use($item[fishy pipe]);
        } else if (item_amount($item[closed-circuit pay phone]) > 0 && get_property("_shadowAffinityToday") == false || have_effect($effect[shadow affinity]) > 0){
            while(have_effect($effect[fishy]) == 0){
                shadowRift();
            }
        } else if (!contains_text(get_property("_roninStoragePulls"),"10360")){
            cli_execute("buy using storage fish sauce; pull fish sauce; chew fish sauce");
        } else {
            abort("Out of fishy");
        }
    }
    if (total_turns_played() >= to_int(get_property("spookyVHSTapeMonsterTurn")) + 8 && get_property("spookyVHSTapeMonster") != ""){
        if (my_primestat() == $stat[mysticality]){
            cli_execute("maximize hot res, equip " + divingHelmet() +", equip legendary seal clubbing, equip shark jumper, equip scale-mail underwear; familiar grouper group");
            adv1($location[The Marinara Trench],1,"");
        }
        if (my_primestat() == $stat[moxie]){
            cli_execute("maximize sleaze res, equip " + divingHelmet() +", equip legendary seal clubbing, equip shark jumper, equip scale-mail underwear; familiar grouper group");
            adv1($location[The Dive Bar],1,"");
        }
        if (item_amount($item[spooky VHS tape]) > 0){
            if (to_int(get_property("_assertYourAuthorityCast")) < 3){
                maximize("item drop, equip " + divingHelmet() +", equip shark jumper, equip scale-mail underwear, equip black glass, equip Sheriff moustache, equip Sheriff badge, equip Sheriff pistol, equip little bitty bathy", false);
            } else {
                maximize("item drop, equip shark jumper, equip scale-mail underwear, equip " + divingHelmet() +", equip black glass, equip blood cubic zirconia, equip peridot, equip little bitty",false);
            }
            adv1($location[The Caliginous Abyss],0,"");
        }
    }
    if (total_turns_played() >= to_int(get_property("clubEmNextWeekMonsterTurn")) + 8 && get_property("clubEmNextWeekMonster") != ""){
        if (my_location() == $location[mer-kin elementary school] || my_location() == $location[mer-kin library]){
        } else if (my_primestat() == $stat[mysticality]){
            cli_execute("maximize hot res, equip really nice swimming, equip legendary seal clubbing; familiar grouper group");
            adv1($location[The Marinara Trench],1,"");
        } else if (my_primestat() == $stat[moxie]){
            cli_execute("maximize sleaze res, equip really nice swimming, equip legendary seal clubbing; familiar grouper group");
            adv1($location[The Dive Bar],1,"");
        }
    }
    if (item_amount($item[whirled peas]) >=2 ){
        cli_execute("acquire handful of split pea soup");
    }}
void postAscend(){
    write_ccs(to_buffer("consult undertheseaccs.ash \n abort"),"temp");
    set_ccs("temp");
    set_property("battleAction","custom combat script");
    set_property("hpAutoRecovery","0.5");
    set_property("hpAutoRecoveryTarget","0.7");
    set_property("mpAutoRecovery","0.3");
    set_property("mpAutoRecoveryTarget","0.6");
    set_property("stashboxChecked","0");
    if (get_property("questM05Toot") == "started"){
        council();
        visit_url("tutorial.php?action=toot");
        council();
        visit_url("place.php?whichplace=sea_oldman&action=oldman_oldman");
    }
    foreach it in $items[letter from King Ralph XI,pork elf goodies sack,sushi-rolling mat,2002 Mr. Store Catalog,TakerSpace letter of Marque]{
        if (item_amount(it) > 0)
            use(it, item_amount(it));
    }
    foreach sk in $skills[Aug. 24th: Waffle Day!,Summon Kokomo Resort Pass]{
        if (have_skill(sk))
            use_skill(sk);
    }
    foreach it in $items[hamethyst,baconstone,porquoise,kokomo resort pass]{
        autosell(item_amount(it),it);
    }
    if (get_property("_mayamSymbolsUsed") == ""){
        use_familiar($familiar[chest mimic]);
        cli_execute("mayam rings vessel yam cheese explosion; mayam rings fur lightning eyepatch yam; mayam rings eye meat yam clock");
    }
    if (to_int(get_property("availableSeptEmbers")) > 1){
    //    create(floor(to_float(get_property("availableSeptEmbers"))/2),$item[Septapus summoning charm]);
    }
    if (get_property("leprecondoInstalled") == "0,0,0,0" && item_amount($item[Leprecondo]) > 0){
        leprecondo("22,24,12,11,10,4,5,6");
    }
    visit_url("campground.php?preaction=leaves");
    if (item_amount($item[S.I.T. Course Completion Certificate]) > 0 && get_property("_sitCourseCompleted") == "false")
        use($item[S.I.T. Course Completion Certificate]);
    if (get_property("_aprilBandInstruments") == 0)
        cli_execute("aprilband item tuba; aprilband item piccolo; aprilband play piccolo; aprilband play piccolo; aprilband play piccolo");
    if (get_property("_photoBoothEquipment") == 0)
        cli_execute("photobooth item sheriff pistol; photobooth item sheriff moustache; photobooth item sheriff badge");
        visit_url("inventory.php?action=skiduffel");
    if (get_property(" _aprilShowerGlobsCollected") == false)
        visit_url("inventory.php?action=shower");
    if (get_property("_takerSpaceSuppliesDelivered") == "false"){
        foreach it in $items[anchor bomb,Flash Liquidizer Ultra Dousing Accessory,pro skateboard,Spooky VHS Tape]{
            if (it == $item[anchor bomb] && to_int(get_property("takerSpaceAnchor")) < 3)
                continue;
            create(1,it);
        }
    }
    equip($item[designer sweatpants]);
    cli_execute("garden pick");
    if (item_amount($item[antique accordion]) == 0)
        buy($item[antique accordion]);
    if (item_amount($item[model train set]) == 1)
        use($item[model train set]);
    foreach it in $items[mer-kin sneakmask, sea lasso, comb jelly, shark jumper,scale-mail underwear,Mer-kin digpick,Congressional Medal of Insanity, spooky VHS tape]{
        if (storage_amount( it ) == 0){
            buy_using_storage(it);
        }
        take_storage(1,it);
    }
    set_property("UnderTheSeaStage","stage1");}
void unlockGuild(){
    if (my_primestat() == $stat[mysticality]){
        if (get_property("questG07Myst") != "finished"){
            if (get_property("questG07Myst") == "unstarted")
                visit_url("guild.php?place=challenge");
            use_familiar($familiar[Peace Turkey]);
            mood("itdrop");
            while ((get_property("questG07Myst"))== "started"){
                maximize("item drop, equip monodent of the sea, equip mobius, equip everfull dart, equip toy cupid bow, equip designer sweatpants" + shrunkenHead() + "" + freeRun(),false);
                adv1($location[The Haunted Pantry],0,"");
            }
            visit_url("guild.php?place=challenge");
        }
    }
    if (my_primestat() == $stat[moxie]){
        if (get_property("questG08Moxie") != "finished"){
            if (get_property("questG08Moxie") == "unstarted")
                visit_url("guild.php?place=challenge");
            if (have_item($item[tearaway pants])){
                equip($item[tearaway pants]);
            } else {
                use_familiar($familiar[Peace Turkey]);
                mood("itdrop");
                while ((get_property("questG08Moxie"))== "started"){
                    maximize("item drop, equip monodent of the sea, equip mobius, equip everfull dart, equip toy cupid bow, equip designer sweatpants" + shrunkenHead() + "" + freeRun(),false);
                    adv1($location[The Sleazy Back Alley],0,"");
                }
            }
            visit_url("guild.php?place=challenge");
        }
    }
    if (my_primestat() == $stat[muscle]){
        if (get_property("questG09Muscle") != "finished"){
            if (get_property("questG09Muscle") == "unstarted")
                visit_url("guild.php?place=challenge");
            use_familiar($familiar[Peace Turkey]);
            mood("itdrop");
            while ((get_property("questG09Muscle"))== "started"){
                maximize("item drop, equip monodent of the sea, equip mobius, equip everfull dart, equip toy cupid bow, equip designer sweatpants" + shrunkenHead() + "" + freeRun(),false);
                adv1($location[The Outskirts of Cobb's Knob],0,"");
            }
            visit_url("guild.php?place=challenge");
        }
    }
}
void skatePark(){
    NCforce();
    equip($item[really\, really nice swimming trunks]);
    if (item_amount($item[skate blade]) > 0)
        equip($item[skate blade]);
    adv1($location[The Skate Park],0,"");
    post_adv();
}
void seaMonkees(){
    if (get_property("questG03Ego") == "unstarted" && item_amount($item[Closed-circuit pay phone]) > 0){
        unlockGuild();
        if (get_property("questG03Ego") == "unstarted"){
            visit_url("guild.php?place=ocg");
            visit_url("guild.php?place=ocg");
        }
    }
    post_adv();
    if (get_property("questS02Monkees") == "unstarted"){
        if (have_effect($effect[Citizen of a Zone]) == 0){ //Peridot neptune flytrap, RWB ray to guarantee 2 more in case it doesn't drop the first time
            use_familiar($familiar[patriotic eagle]);
            maximize("item drop, equip really nice swimming trunks, equip peridot of peril, equip Sheriff moustache, equip Sheriff badge, equip Sheriff pistol,equip Little bitty bathysphere", false);
            adv1($location[An octopus's garden],1,"");
            post_adv();
        }
        while (item_amount($item[wriggling flytrap pellet]) == 0 && to_int(get_property("rwbMonsterCount")) > 0){ //if it doesn't drop and RWB is active
            use_familiar($familiar[grouper groupie]);
            if (to_int(get_property("rwbMonsterCount")) == 1){
                maximize("item drop, equip really nice swimming trunks, equip McHugeLarge left pole,equip toy cupid bow", false);
            } else {
                maximize("item drop, equip really nice swimming trunks, equip Sheriff moustache, equip Sheriff badge, equip Sheriff pistol,equip toy cupid bow", false);
            }
            adv1($location[An octopus's garden],1,"");
            post_adv();
        }
        if (item_amount($item[wriggling flytrap pellet]) > 0){
            use($item[wriggling flytrap pellet]);
        } else if (get_property("questS02Monkees") == "unstarted"){ //need to add contingencies if it still doesn't drop after that
            print("Pellet failed to drop 3x, initiating banishes","red");
            while (item_amount($item[wriggling flytrap pellet]) == 0){
                use_familiar($familiar[grouper groupie]);
                string conditional;
                if (to_int(get_property("_assertYourAuthorityCast")) <= 3){
                    maximize("item drop, equip really nice swimming trunks, equip Sheriff moustache, equip Sheriff badge, equip Sheriff pistol,equip toy cupid bow", false);
                } else {
                    maximize("item drop, equip really nice swimming trunks,equip toy cupid bow , equip " + banishGear($location[An octopus's garden]), false);
                }
                adv1($location[An octopus's garden],1,"");
                post_adv();
            }
        }
        if (item_amount($item[wriggling flytrap pellet]) > 0){
            use($item[wriggling flytrap pellet]);
        }
    }
    if (get_property("questS02Monkees") == "started"){
        visit_url("monkeycastle.php?who=1");
    }
    while (get_property("questS02Monkees") == "step1"){ //Can NC force wreck of edgar fitzsimmons
        if (get_property("noncombatForcerActive") == "false")
            NCforce();
        use_familiar($familiar[Patriotic eagle]);
        maximize("item drop, equip really nice swimming, equip mobius, equip little bitty bathy",false);
        adv1($location[The Wreck of the Edgar Fitzsimmons],0,"");
        post_adv();
    }
    if (get_property("questS02Monkees") == "step2"){
        visit_url("monkeycastle.php?who=2");
        visit_url("monkeycastle.php?who=1");
    }
    if (get_property("questS02Monkees") == "step4"){ //still need to guarantee 10% exploration
        use_familiar($familiar[grouper groupie]);
        mood("noncom");
        mood("item drop");
        if (have_effect($effect[ Colorfully Concealed]) == 0){
            cli_execute("buy using storage mer-kin hidepaint; pull mer-kin hidepaint");
            use($item[mer-kin hidepaint]);
        }
        while(get_property("questS02Monkees") == "step4"){
            if(!contains_text(get_property("trackedMonsters"),"Mer-kin tippler") && !contains_text(get_property("trackedMonsters"),"giant squid")){
                maximize("item drop, -100 combat, equip really nice swimming, equip everfull dart, equip monodent of the sea, equip toy cupid, equip peridot of peril, equip McHugeLarge left pole, equip blood cubic zirc",false);
            } else {
                maximize("item drop, -100 combat, equip really nice swimming, equip mobius, equip everfull dart, equip monodent of the sea, equip toy cupid, equip blood cubic zirc",false);
            }
            if (my_primestat() == $stat[moxie]){
                mood("sleazeres");
                adv1($location[The dive bar],1,"");
            } else if (my_primestat() == $stat[mysticality]){
                mood("hotres");
                adv1($location[The Marinara Trench],1,"");
            } else { //need to add mus
                abort();
            }
            post_adv();
        }
    }
    if (get_property("questS02Monkees") == "step5"){
        cli_execute("grandpa grandma");
    }
    if (get_property("questS02Monkees") == "step6" && get_property("_monsterHabitatsMonster") == ""){//Club em into next week and habitat recall crayon golem
        use_familiar($familiar[peace turkey]);
        if (haveLocketMonster[$monster[black crayon golem]]){
            maximize("item drop, equip legendary seal clubbing club, equip mchugelarge left pole",false);
            cli_execute("reminisce black crayon golem");
        } else {
            maximize("item drop, equip legendary seal clubbing club, equip mchugelarge left pole" + (have_item($item[Combat lover's locket]) ? ", equip combat lovers":""),false);
            cli_execute("c2t_megg extract black crayon golem");
            cli_execute("c2t_megg fight black crayon golem");
            run_combat();
        }
    }
    while (item_amount($item[Mer-kin stashbox]) == 0 && get_property("corralUnlocked") == "false"){
        if (get_property("_monsterHabitatsFightsLeft") == "1" && to_int(get_property("_monsterHabitatsRecalled")) == 2){ //Once habitat recall is done, banishing constructs for cyberzone free fights
            use_familiar($familiar[patriotic eagle]);
        } else { //else try to get whirled peas
            use_familiar($familiar[Peace Turkey]);
        }
        buffer conditional;
        if (get_property("_monsterHabitatsFightsLeft") == 1 && have_effect($effect[Everything Looks Purple]) == 0 && to_int(get_property("_monsterHabitatsRecalled")) == 2 && have_item($item[roman candelabra]))
            conditional = append(conditional,", equip roman candelabra"); //trying to use purple ray
        if (get_property("lastCopyableMonster") == "Black Crayon Golem" && to_int(get_property("_backUpUses")) < 7 && ($location[The Mer-Kin Outpost].turns_spent <= 24 || get_property("merkinLockkeyMonster") != "")){
            conditional = append(conditional,", equip backup camera"); //using back ups for free fights
        } else {
            conditional = append(conditional,", equip blood cubic zirconia"); //free kills needed
        }
        if (get_property("merkinLockkeyMonster") != ""){
            mood("noncom");
            maximize("-combat, equip really nice swimming, equip little bitty" + freeKill() + "" + conditional,false);
        } else if (get_property("merkinLockkeyMonster") == "") {
            maximize("-combat, equip really nice swimming, equip little bitty" + freeRun() + "" + freeKill() + "" + conditional,false);
        }
        adv1($location[The Mer-Kin Outpost],0,"");
        post_adv();
        if (item_amount($item[Grandma's Note]) > 0 && item_amount($item[Grandma's Fuchsia Yarn]) > 0 && item_amount($item[Grandma's Chartreuse Yarn]) > 0){
            cli_execute("grandpa note");
        }
    }
    refresh_status();
    if (item_amount($item[Mer-kin stashbox]) == 1){
        use($item[Mer-kin stashbox]);
        use($item[Mer-kin trailmap]);
        equip($item[really\, really nice swimming trunks]);
        cli_execute("grandpa currents");
    }
    if (get_property("questS01OldGuy") == "started"){
        use(item_amount($item[mer-kin thingpouch]),$item[mer-kin thingpouch]);
        if (item_amount($item[sand dollar]) < 50 && storage_amount($item[damp old wallet]) > 0){ //if necesary pull and use the old wallet
            take_storage(1,$item[damp old wallet]);
            use($item[damp old wallet]);
        } else if (item_amount($item[sand dollar]) < 50){
            use($item[11-leaf clover]);
            adv1($location[The Mer-Kin Outpost]);
        }
        visit_url("monkeycastle.php?who=1");
        buy($coinmaster[Big Brother],1,$item[black glass]);
        buy($coinmaster[Big Brother],1,$item[damp old boot]);
        visit_url("place.php?whichplace=sea_oldman&action=oldman_oldman&preaction=pickreward&whichreward=6313");
        if (item_amount($item[rusty rivet]) < 8){
            mood("itdrop");
            if (have_effect($effect[shadow waters]) == 0){
                shadowRift();
            }
            if (item_amount($item[rusty porthole]) == 0){
                use_familiar($familiar[chest mimic]);
                maximize("item, equip blood cubic zirconia, equip toy cupid bow",false);
                print("Item drop rate is " + numeric_modifier("item drop"));
                cli_execute("pool 3; cast steely-eyed squint, cincho: Party Soundtrack, Heartstone: %pals");
                if (have_effect($effect[everything looks yellow]) == 0)
                    cli_execute("parka dilophosaur; equip jurassic parka");
                if (haveLocketMonster[$monster[unholy diver]]){
                    cli_execute("reminisce unholy diver");
                } else {
                    if (have_item($item[Combat lover's locket])){
                        equip($slot[acc3],$item[Combat lover's locket]);
                    }
                    if (faxbot ($monster[unholy diver])){
                        use($item[photocopied monster]);
                        run_combat();
                    } else {
                        abort("Need a method to find unholy diver");
                    }
                }
            }
            if (item_amount($item[rusty rivet]) < 4){
                use_familiar($familiar[chest mimic]);
            } else {
                use_familiar($familiar[Jill-of-all-trades]);
            }
            maximize("item, equip blood cubic zirconia, equip toy cupid bow",false);
            if (have_effect($effect[everything looks yellow]) == 0)
                cli_execute("parka dilophosaur; equip jurassic parka");
            cli_execute("c2t_megg fight unholy diver");
            run_combat();
            if (item_amount($item[rusty rivet]) < 8){
                if (item_amount($item[rusty rivet]) < 7){
                    cli_execute("c2t_megg fight unholy diver");
                    run_combat();
                } else {
                    if (!contains_text(get_property("_roninStoragePulls"),"3604")){
                        cli_execute("buy using storage rusty rivet; pull rusty rivet");
                    }
                }
            }
        }
        cli_execute("acquire aerated diving helmet");
    }
    if (to_int(get_property("momSeaMonkeeProgress")) < 24){
        while (get_property("_monsterHabitatsMonster") != "eye in the darkness" && get_property("_monsterHabitatsMonster") != "slithering thing"){
            use_familiar($familiar[peace turkey]);
            maximize("item drop, equip " + divingHelmet() +", equip shark jumper, equip scale-mail underwear, equip black glass, equip peridot of peril, equip little bitty bath", false);
            if (have_effect($effect[jelly combed]) == 0){ //need to add that mys classes may get the comb easily
                use($item[comb jelly]);
            }
            adv1($location[The Caliginous Abyss],0,"");
            post_adv();
        }
        while (to_int(get_property("_monsterHabitatsFightsLeft")) > 0 && to_int(get_property("_cyberFreeFights")) < 10 && to_int(get_property("momSeaMonkeeProgress")) < 32){
            use_familiar($familiar[glover]); // fight 5 recalled mobs for free in cyberzone
            string conditional;
            if (!contains_text(get_property("banishedMonsters"),"Sea *dent")){
                conditional = ", equip monodent";
            }
            maximize("item drop, equip shark jumper, equip scale-mail underwear, equip allied radio backpack, equip sheriff moustache" + conditional, false);
            adv1($location[Cyberzone 1],0,"");
            post_adv();
        }
    }
    if (get_property("corralUnlocked") == "true" && item_amount($item[sea cowbell]) == 0 && get_property("seahorseName") == ""){
        if (have_effect($effect[shadow waters]) == 0){
            shadowRift();
        }
        use_familiar($familiar[grouper groupie]);
        cli_execute("unequip blood cubic zirconia; unequip peridot of peril");
        codpiece("blood cubic zirconia, heartstone");
        maximize("item drop, equip shark jumper, equip scale-mail underwear, equip "+ divingHelmet()+", equip backup camera, equip pro skateboard, equip The Eternity Codpiece", false);
        mood("itdrop");
        adv1($location[The Coral Corral]);
        post_adv();
    }
    if (item_amount($item[sea cowboy hat]) == 0 && !have_equipped($item[sea cowboy hat])){
        if (item_amount($item[sea leather]) < 2 && item_amount($item[sea chaps]) == 0){
            abort("Not enough sea leather for some reason??");
        } else{
            create($item[sea chaps]);
        }
        if (item_amount($item[sea leather]) < 1 && item_amount($item[sea cowboy hat]) == 0){
            abort("Not enough sea leather for some reason??");
        } else{
            create($item[sea cowboy hat]);
        }
        set_property("UnderTheSeaStage","stage2");
        codpiece("none");
    }
}
void sorceress(){
    if (to_int(get_property("encountersUntilSRChoice")) > 9 && get_property("questRufus") == "unstarted" && item_amount($item[Closed-circuit pay phone]) > 0){
        mood("itdrop");
        cli_execute("acquire oversized sparkler");
        maximize("item drop, equip jurassic, equip toy cupid bow",false);
        if (item_amount($item[lump of loyal latite]) > 0){
            use($item[lump of loyal latite]);
        }
        maximize("item drop, equip Flash Liquidizer Ultra Dousing Accessory, equip bat wings, equip everfull dart holster, equip monodent of the sea",false);
        use($item[closed-circuit pay phone]);
    }
    if (get_property("expressCardUsed") == false){
        if (storage_amount($item[Platinum Yendorian Express Card]) > 0){
            take_storage(1,$item[Platinum Yendorian Express Card]);
            use($item[Platinum Yendorian Express Card]);
        } else {
            abort("Hagnk does not have a PYEC, see if you can borrow one?");
        }
    }
    while (have_effect($effect[shadow affinity]) > 0){
        shadowRift();
    }
    if (get_property("encountersUntilSRChoice") == "0")
        adv1($location[Shadow Rift (The Misspelled Cemetary)],0,"");
    if (get_property("questRufus") == "step1"){
        use($item[closed-circuit pay phone]);
        adv1($location[Shadow Rift (The Misspelled Cemetary)],0,"");
    }
    while (to_int(get_property("lassoTrainingCount")) < 20){
        abort("Your lasso training didn't finish somehow");
    }
    while (get_property("seahorseName") == ""){
        if (item_amount($item[sea cowbell]) < 3 && !contains_text(get_property("_roninStoragePulls"),"4196")){
            cli_execute("buy using storage sea cowbell; pull sea cowbell");
        }
        use_familiar($familiar[peace turkey]);
        string conditional;
        if (!contains_text(get_property("_perilLocations"),"199"))
            conditional = ", equip peridot of peril";
        maximize("item drop, equip really nice swimming, equip little bitty bath" + conditional,false);
        if (item_amount($item[sea lasso]) == 0){
            cli_execute("monkeypaw wish sea lasso");
        }
        if (item_amount($item[sea cowbell]) < 3){
            cli_execute("monkeypaw wish sea cowbell");
        }
        if (item_amount($item[sea cowbell]) < 3){
            abort("need more cowbells");
        }
        if (contains_text(get_property("banishedMonsters"),"Mer-kin rustler") && contains_text(get_property("banishedMonsters"),"sea cowboy") && contains_text(get_property("banishedMonsters"),"sea cow") && have_item($item[tearaway pants]))
            equip($item[Tearaway pants]);
        adv1($location[The Coral Corral]);
        post_adv();
    }
    if (item_amount($item[teflon ore]) == 0 && !tailpiece()){
        equip($item[mer-kin digpick]);
        equip($item[really\, really nice swimming trunks]);
        use_familiar($familiar[grouper groupie]);
        boolean exposed = false;
        while ((to_int(get_property("_unaccompaniedMinerUsed")) < 5 || have_effect($effect[Loded]) > 0) && item_amount($item[teflon ore]) == 0){
            visit_url("mining.php?mine=3&which="+ mineNum());
            if( my_hp() == 0){
                cli_execute("restore HP");
            }
            if (to_int(get_property("_unaccompaniedMinerUsed")) == 5 && !contains_text(get_property("_roninStoragePulls"),"11103") && item_amount($item[teflon ore]) == 0){
                cli_execute("buy using storage lodestone; pull lodestone; use lodestone");
            }
            if ((to_int(get_property("_unaccompaniedMinerUsed")) >= 5 && have_effect($effect[Loded]) == 0) || item_amount($item[teflon ore]) > 0)
                break;
        }
        if (have_effect($effect[beaten up]) > 0){
            use_skill($skill[Tongue of the Walrus]);
        }
        if (item_amount($item[teflon ore]) == 0){
            abort("failed to acquire teflon ore, pull minin dynamite for one more try");
        }
    }
    if (!tailpiece()){
        if (item_amount($item[sand dollar]) < 10 && item_amount($item[damp old wallet]) > 0){ //if necesary pull and use the old wallet
            use($item[damp old wallet]);
        } else if (item_amount($item[sand dollar]) < 10){
            use($item[11-leaf clover]);
            adv1($location[The Mer-Kin Outpost]);
        }
        cli_execute("unequip sea chaps; acquire crappy Mer-kin tailpiece, crappy Mer-kin mask");
    }
    if (get_property("yogUrtDefeated") == "false"){
        while (item_amount($item[mer-kin cheatsheet]) < 9 && get_property("merkinVocabularyMastery") == "0"){
            put_closet(item_amount($item[mer-kin hallpass]),$item[mer-kin hallpass]);
            use_familiar($familiar[grouper groupie]);
            string conditional;
            if (to_int(get_property("_backUpUses")) < 11){
                conditional = ", equip backup camera";
            } else {
                conditional = ", equip monodent of the sea";
            }
            if (have_effect($effect[Steely-Eyed Squint]) > 0){
                maximize("item drop, equip crappy Mer-kin tailpiece, equip crappy Mer-kin mask, equip legendary seal-clubbing club, equip blood cubic zirc, equip mobius" + conditional,false);
            } else {
                if (get_property("merkinElementaryTeacherUnlock") == "false")
                    mood("noncom");
                maximize("item drop, equip crappy Mer-kin tailpiece, equip crappy Mer-kin mask, equip legendary seal-clubbing club, equip blood cubic zirconia, equip mobius" + conditional,false);
            }
            mood("itdrop");
            if (have_equipped($item[backup camera]) && get_property("lastCopyableMonster") != "kid who is too old to be Trick-or-Treating" && get_property("lastCopyableMonster") != "suburban security civilian" && get_property("lastCopyableMonster") != "vandal kid" && get_property("lastCopyableMonster") != "Black Crayon Golem" ){
                if (get_property("_mapToACandyRichBlockUsed") == "false" && item_amount($item[map to a candy-rich block]) > 0){
                    use($item[map to a candy-rich block]);
                } else if (get_property("_mapToACandyRichBlockUsed") == "false" && item_amount($item[map to a candy-rich block]) == 0) {
                    abort("not enough maps");
                }
                candy("fight");
            }
            adv1($location[mer-kin elementary school]);
            put_closet(item_amount($item[mer-kin hallpass]),$item[mer-kin hallpass]);
            post_adv();
        }
        while (get_property("merkinElementaryTeacherUnlock") == "false"){
            maximize("-combat, equip crappy Mer-kin tailpiece, equip crappy Mer-kin mask, equip legendary seal-clubbing club, equip blood cubic zirconia, equip mobius, toy cupid bow",false);
            mood("noncom");
            NCforce();
            adv1($location[mer-kin elementary school]);
            put_closet(item_amount($item[mer-kin hallpass]),$item[mer-kin hallpass]);
            post_adv();
        }
        if (item_amount($item[mer-kin bunwig]) == 0){
            maximize("item drop, equip crappy Mer-kin tailpiece, equip crappy Mer-kin mask, equip legendary seal-clubbing club, equip blood cubic zirconia, equip mobius, equip toy cupid bow",false);
            mood("itdrop");
            if (get_property("merkinElementaryTeacherUnlock") == "false")
                mood("noncom");
            adv1($location[mer-kin elementary school]);
            put_closet(item_amount($item[mer-kin hallpass]),$item[mer-kin hallpass]);
            post_adv();
        }
        take_closet(closet_amount($item[mer-kin hallpass]),$item[mer-kin hallpass]);
        while (to_int(get_property("merkinVocabularyMastery")) < 100){
            if (item_amount($item[mer-kin wordquiz]) > 0){
                if (item_amount($item[mer-kin cheatsheet]) == 0){
                    cli_execute("buy using storage mer-kin cheatsheet; pull mer-kin cheatsheet");
                }
                use($item[mer-kin wordquiz]);
            } else if (to_int(get_property("merkinVocabularyMastery")) == 90 && item_amount($item[mer-kin wordquiz]) == 0){
                cli_execute("buy using storage mer-kin wordquiz; pull mer-kin wordquiz");
            } else {
                maximize("item drop, equip crappy Mer-kin tailpiece, equip crappy Mer-kin mask, equip mobius",false);
                adv1($location[mer-kin elementary school]);
            }
            if (item_amount($item[mer-kin facecowl]) > 0 && item_amount($item[mer-kin waistrope]) > 0 && have_effect($effect[Steely-Eyed Squint]) > 0){
                while ($location[mer-kin library].turns_spent < 4 && have_effect($effect[Steely-Eyed Squint]) > 0){
                    if (item_amount($item[Mer-kin scholar mask]) == 0 && !have_equipped($item[Mer-kin scholar mask])){
                        equip($slot[hat],$item[none]);
                        equip($item[really\, really nice swimming trunks]);
                        visit_url("shop.php?whichshop=grandma&action=buyitem&quantity=1&whichrow=129");
                    }
                    if (item_amount($item[Mer-kin scholar tailpiece]) == 0 && !have_equipped($item[Mer-kin scholar tailpiece])){
                        equip($slot[pants],$item[none]);
                        equip($item[really\, really nice swimming trunks]);
                        visit_url("shop.php?whichshop=grandma&action=buyitem&quantity=1&whichrow=130");
                    }
                    buffer conditional;
                    if (to_int(get_property("_backUpUses")) < 11){
                        conditional = append(conditional, ", equip backup camera");
                    }
                    if (to_int(get_property("_batWingsSwoopUsed")) < 11)
                        conditional = append(conditional, ", equip bat wings");
                    if (!banishUsedAtYourLocation("Spring Kick"))
                        conditional = append(conditional, ", equip spring shoes");
                    maximize("item drop, equip mer-kin scholar mask, equip mer-kin scholar tailpiece, equip monodent of the sea, equip blood cubic zirconia" + conditional,false);
                    if (have_equipped($item[backup camera]) && get_property("lastCopyableMonster") != "kid who is too old to be Trick-or-Treating" && get_property("lastCopyableMonster") != "suburban security civilian" && get_property("lastCopyableMonster") != "vandal kid" && get_property("lastCopyableMonster") != "Black Crayon Golem" ){
                        if (get_property("_mapToACandyRichBlockUsed") == "false" && item_amount($item[map to a candy-rich block]) > 0){
                            use($item[map to a candy-rich block]);
                        } else if (get_property("_mapToACandyRichBlockUsed") == "false" && item_amount($item[map to a candy-rich block]) == 0) {
                            abort("not enough maps");
                        }
                        candy("fight");
                    }
                    adv1($location[mer-kin library]);
                    post_adv();
                }
            }
            post_adv();
        }
        if (to_int(get_property("merkinVocabularyMastery")) == 100 && get_property("UnderTheSeaStage") == "stage2"){
            if (item_amount($item[Mer-kin scholar mask]) == 0 && !have_equipped($item[Mer-kin scholar mask])){
                equip($slot[hat],$item[none]);
                equip($item[really\, really nice swimming trunks]);
                visit_url("shop.php?whichshop=grandma&action=buyitem&quantity=1&whichrow=129");
            }
            if (item_amount($item[Mer-kin scholar tailpiece]) == 0 && !have_equipped($item[Mer-kin scholar tailpiece])){
                equip($slot[pants],$item[none]);
                equip($item[really\, really nice swimming trunks]);
                visit_url("shop.php?whichshop=grandma&action=buyitem&quantity=1&whichrow=130");
            }
            equip($item[Mer-kin scholar mask]);
            equip($item[Mer-kin scholar tailpiece]);
            set_property("UnderTheSeaStage","stage3");
        }
        while (get_property("dreadScroll1") == "0" || get_property("dreadScroll6") == "0" || get_property("dreadScroll8") == "0"){
            use_familiar($familiar[grouper groupie]);
            string conditional;
            if (!contains_text(get_property("banishedMonsters"),"Mer-kin alphabetizer:Spring Kick")){
                conditional = ", equip spring shoes";
            }
            if (item_amount($item[mer-kin dreadscroll]) == 0){
                maximize("item drop, equip mer-kin scholar mask, equip mer-kin scholar tailpiece, equip monodent of the sea, equip blood cubic zirconia" + conditional,false);
            } else {
                maximize("-combat, equip mer-kin scholar mask, equip mer-kin scholar tailpiece, equip monodent of the sea"+ conditional, false);
            }
            if (item_amount($item[mer-kin dreadscroll]) > 0)
                mood("noncom");
            mood("itdrop");
            adv1($location[mer-kin library]);
            post_adv();
        }
        if (get_property("dreadScroll4") == "0" && item_amount($item[mer-kin knucklebone]) > 0){
            use($item[Mer-kin knucklebone]);
        } else if (get_property("dreadScroll4") == "0"){
            cli_execute("buy using storage mer-kin knucklebone; pull mer-kin knucklebone");
            use($item[Mer-kin knucklebone]);
        }
        if (get_property("dreadScroll3") == 0)
            maximize("50 spooky res, hp",false);
        while (get_property("dreadScroll3") == 0){
            restore_hp(1000);
            use_skill($skill[deep dark visions]);
        }
        if (get_property("dreadScroll5") == 0){
            abort("Need mer-kin killscroll code");
        }
        //if (get_property("dreadScroll7") == "0" && item_amount($item[mer-kin worktea]) > 0){
        //    abort("do dreadscroll without eating");
        //    cli_execute("buy white rice; create 1 beefy nigiri");
        //} else if (get_property("dreadScroll7") == "0"){
        //    abort();
        //}
        if (get_property("isMerkinHighPriest") == "false"){
            cli_execute("uneffect the sonata of sneakiness");
            if (contains_text(get_property("leprecondoInstalled"),"11") && item_amount($item[Leprecondo]) > 0){
                leprecondo("22,24,12,8,13,15,10,4,5,6");
            }
            while (get_property("isMerkinHighPriest") == "false"){
                if (have_effect($effect[Deep-Tainted Mind]) == 0){
                    use ($item[mer-kin dreadscroll]);
                    post_adv();
                } else {
                    while (have_effect($effect[Deep-Tainted Mind]) > 0){
                        if (get_property("skateParkStatus") == "war" && !contains_text($location[The Skate Park].noncombat_queue,"Holey Rollers")){
                            skatePark();
                        } else if (item_amount($item[Mer-kin thighguard]) == 0 || item_amount($item[Mer-kin headguard]) == 0){
                            maximize("combat,equip Mer-kin scholar mask, equip Mer-kin scholar tailpiece" + freeRun() + "" + freeKill(),false);
                            mood("combat");
                            print(numeric_modifier("combat rate"));
                            adv1($location[Mer-kin Gymnasium],0,"");
                            post_adv();
                        } else if (get_property("questS02Monkees") == "step12") {
                            maximize("item drop, equip shark jumper, equip scale-mail underwear, equip "+ divingHelmet() + ", equip black glass, equip blood cubic zirconia, equip mobius, equip little bitty",false);
                            adv1($location[The Caliginous Abyss],0,"");
                            post_adv();
                        } else {
                            abort ("You hit a 1 in 40 situation, you need to spend 1 turn (not free) somewhere and rerun script");
                        }
                    }
                }
            }
        }
        while (get_property("skateParkStatus") == "war" && !contains_text($location[The Skate Park].noncombat_queue,"Holey Rollers")){
            skatePark();
        }
        if (get_property("_skateBuff1") == "false"){
            visit_url("sea_skatepark.php?action=state2buff1");
        }
        if (get_property("yogUrtDefeated") == "false"){
            cli_execute("acquire mer-kin mouthsoap,waterlogged scroll of healing,sea gel;cast cannel");
            if (item_amount($item[mer-kin prayerbeads]) < 3 && !contains_text(get_property("_roninStoragePulls"),"3806")){
                cli_execute("buy using storage mer-kin prayerbeads; pull mer-kin prayerbeads");
            }
            maximize("spell damage percent, hot damage, cold damage, spooky damage, sleaze damage, stench damage,equip Mer-kin scholar mask, equip Mer-kin scholar tailpiece, equip bat wings, equip toy cupid",false);
            equip($slot[acc1],$item[mer-kin prayerbeads]);
            if (item_amount($item[mer-kin prayerbeads]) < 3){
                if (item_amount($item[mer-kin prayerbeads]) < 2){
                    if (item_amount($item[soggy used band-aid]) == 0)
                        cli_execute("buy using storage soggy used band-aid; pull soggy used band-aid");
                } else {
                    equip($slot[acc2],$item[mer-kin prayerbeads]);
                }
                if (item_amount($item[New Age healing crystal]) == 0)
                    cli_execute("buy using storage New Age healing crystal; pull New Age healing crystal");
            } else {
                equip($slot[acc3],$item[mer-kin prayerbeads]);
                equip($slot[acc2],$item[mer-kin prayerbeads]);
            }
            if (have_effect($effect[gummiheart]) > 0)
                abort("Have gummiheart effect, which is bad, compensate by dropping hp somehow");
            adv1($location[Mer-kin Temple (Right Door)],0,"");
            post_adv();
        }
    }
    if (get_property("yogUrtDefeated") == "false"){
        abort("passing over yogurt too early, rerun script");
    }
    if (get_property("UnderTheSeaStage") == "stage3"){
        equip($slot[hat],$item[none]);
        equip($slot[pants],$item[none]);
        equip($item[really\, really nice swimming trunks]);
        visit_url("shop.php?whichshop=grandma&action=buyitem&quantity=1&whichrow=131");
        visit_url("shop.php?whichshop=grandma&action=buyitem&quantity=1&whichrow=1619");
        set_property("UnderTheSeaStage","stage4");
    }
    if (pulls_remaining() > 0){
        foreach num in $strings[5401,3679,3775,11583,7014,11706]{
            if (!contains_text(get_property("_roninStoragePulls"),num)){
                buy_using_storage(to_item(to_int(num)));
                take_storage(1 ,to_item(to_int(num)));
            }
            if (pulls_remaining() == 0)
                break;
        }
    }
    while (get_property("UnderTheSeaStage") == "stage4"){
        if (to_int(get_property("_assertYourAuthorityCast")) < 3){
            abort("equip assert");
        }
        maximize("combat,equip crappy mer-kin mask,equip crappy mer-kin tailpiece" + freeRun() + "" + freeKill(),false);
        mood("combat");
        if (item_amount($item[Mer-kin thighguard]) == 0 || item_amount($item[Mer-kin headguard]) == 0){
            print(numeric_modifier("combat rate"));
            adv1($location[Mer-kin Gymnasium],0,"");
        }
        post_adv();
        if (item_amount($item[Mer-kin thighguard]) > 0 && item_amount($item[Mer-kin headguard]) > 0){
            equip($slot[hat],$item[none]);
            equip($slot[pants],$item[none]);
            equip($item[really\, really nice swimming trunks]);
            visit_url("shop.php?whichshop=grandma&action=buyitem&quantity=1&whichrow=126");
            visit_url("shop.php?whichshop=grandma&action=buyitem&quantity=1&whichrow=127");
            set_property("UnderTheSeaStage","stage5");
        }
    }
    refresh_status();
    set_property("hpAutoRecovery","0.7");
    set_property("hpAutoRecoveryTarget","1");
    set_property("mpAutoRecovery","0.75");
    set_property("mpAutoRecoveryTarget","0.9");
    while (to_int(get_property("lastColosseumRoundWon")) < 15){
        string freeFight;
        if (to_int(get_property("_clubEmTimeUsed")) < 5){
            freeFight = ", equip legendary seal clubbing club";
        } else if (to_int(get_property("_batWingsFreeFights")) < 5){
            freeFight = ", equip bat wings";
        }
        maximize("spell damage percent, mys, equip Mer-kin gladiator tailpiece, equip Mer-kin gladiator mask, equip congressional medal of insanity" + freeFight, false);
        if (to_int(get_property("lastColosseumRoundWon")) >= 3 && have_effect($effect[Up To 11]) == 0){
            cli_execute($effect[Up To 11].default);
        }
        if (to_int(get_property("lastColosseumRoundWon")) >= 12){
            use_familiar($familiar[foul ball]);
            cli_execute("equip little bitty bathy; equip bat wings");
            mood ("colosseum");
        }
        adv1($location[Mer-kin Colosseum],0,"");
        post_adv();
    }
    if (to_int(get_property("lastColosseumRoundWon")) < 15){
        abort("skipped over colosseum, rerun script");
    }
    if (get_property("questS02Monkees") == "step12") {
        maximize("item drop, equip shark jumper, equip scale-mail underwear, equip "+divingHelmet()+", equip black glass, equip blood cubic zirconia, equip mobius, equip little bitty",false);
        adv1($location[The Caliginous Abyss],0,"");
        post_adv();
    }
    if (get_property("shubJigguwattDefeated") == "false"){
        use_familiar($familiar[grouper groupie]); // foul ball will kill you bc of passive damage
        cli_execute("maximize damage absorption, mus; outfit mer-kin gladiator; equip bat wings; recover hp");
        set_property("hpAutoRecoveryTarget","1");
        set_property("mpAutoRecoveryTarget","0");
        cli_execute("recover hp");
        adv1($location[Mer-kin Temple (Left Door)],0,"");
        post_adv();
    }
    if (get_property("questL13Final") == "unstarted"){
        if (to_int(get_property("batWingsFreeFights")) < 5){
            cli_execute("maximize spell damage percent, mys; outfit mer-kin gladiator; equip acc3 congressional medal of insanity; equip bat wings");
        } else {
            cli_execute("maximize spell damage percent, mys; outfit mer-kin gladiator; equip acc3 congressional medal of insanity; equip unwrapped knock-off retro; retrocape heck kill");
        }
        codpiece("none");
        set_property("hpAutoRecovery","0.6");
        set_property("hpAutoRecoveryTarget","0.7");
        set_property("mpAutoRecovery","0.3");
        set_property("mpAutoRecoveryTarget","0.6");
        adv1($location[Mer-kin Temple (center Door)],0,"");
        adv1($location[Mer-kin Temple (center Door)],0,"");
        post_adv();
    }
    if (get_property("questL13Final") == "finished"){
        while (item_amount($item[sand penny]) > 30){
            buy($coinmaster[Wet Crap For Sale],1,$item[water-logged pill]);
        }
        while (item_amount($item[sand penny]) > 10){
            buy($coinmaster[Wet Crap For Sale],1,$item[waterlogged scroll of healing]);
        }
        council();
        council();
        set_property("UnderTheSeaStage","stage0");
        if (my_id() == 2813285){
            cli_execute("postloop");
        }
        spading();
    }
}

void main(){
    try{
        set_property("choiceAdventureScript","UnderTheSea_Choice.ash");
        if (get_property("UnderTheSeaStage") == "stage0" || get_property("UnderTheSeaStage") == ""){
            postAscend();
        }
        seaMonkees();
        sorceress();
    } finally {
        set_property("choiceAdventureScript",choiceStorage);
    }
}
