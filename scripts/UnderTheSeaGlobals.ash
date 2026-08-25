import <seedfinder/seedfinder.ash>;
// ─── GLOBALS ──────────────────────────────────────────────────────────────────   
    int pearlsDoneToday;
    string boss,modes;
    string choiceStorage = get_property("choiceAdventureScript");
    string CCSStorage = get_property("customCombatScript");
    if (CCSStorage == "temp") CCSStorage = "default";
    string choice1387Storage = get_property("choiceAdventure1387");
    string [stat] pearlRes = {
        $stat[mysticality]: "hot res",
        $stat[moxie]:       "sleaze res",
        $stat[muscle]:      "spooky res"
    };
    location [stat] pearlLoc = {
        $stat[mysticality]: $location[The Marinara Trench],
        $stat[moxie]:       $location[The Dive Bar],
        $stat[muscle]:      $location[Anemone Mine]
    };
    string [stat] questProp = {
        $stat[mysticality]: "questG07Myst",
        $stat[moxie]:       "questG08Moxie",
        $stat[muscle]:      "questG09Muscle"
    };
    location [stat] questLoc = {
        $stat[mysticality]: $location[The Haunted Pantry],
        $stat[moxie]:       $location[The Sleazy Back Alley],
        $stat[muscle]:      $location[The Outskirts of Cobb's Knob]
    };
    stat ps = my_primestat();
    int [item] pasta_prices;
    foreach it in $items[Frutti di Scatoletta,Pesto alla Marziano,Arrattabbattabiata,Orzo di Riso,Pasta Grimavera,Linguini Ubriacapa,Gnocci Domani,Formica e Pepe,Tubetto Gelatto]{
        pasta_prices[it] = mall_price(it);
    }
// ─── UTILITY HELPERS ────────────────────────────────────────────────────────
    int count_substring(string text, string sub) {
        int count = 0;
        int pos = 0;
        while (true) {
            pos = index_of(text, sub, pos);
            if (pos == -1) break;
            count += 1;
            pos += length(sub);
        }
        return count;
    }

    boolean contains_text_in_array(string [int] map1, string str) {
        foreach num in map1 {
            if (contains_text(map1[num], str))
                return true;
        }
        return false;
    }

    
    void use_if_have_skill(string page_text, skill sk) {
        if (contains_text(page_text, to_string(sk)))
            use_skill(sk);
    }

    boolean have_item(item it) {
        if (available_amount(it) > 0 || storage_amount(it) > 0)
            return true;
        foreach fam in $familiars[] {
            if (have_familiar(fam) && familiar_equipped_equipment(fam) == it)
                return true;
        }
        return false;
    }

    // Returns true if this monster can prvoide a free fight
    boolean free_monster(monster mob) {
        return $monsters[black crayon golem, Black Crayon Beetle, Black Crayon Man, Black Crayon Goblin, Black Crayon Undead Thing, Black Crayon Slime, time cop, sausage goblin,
            kid who is too old to be Trick-or-Treating,
            suburban security civilian, vandal kid] contains mob;
    }

// Account states
    boolean highShiny() {
        return to_int(get_property("garbo_valueOfFreeFight")) > to_int(get_property("valueOfAdventure"));
    }

    boolean lowShiny() {
        return !have_item($item[2002 Mr. Store Catalog])
            && !have_item($item[cursed monkey's paw])
            && !have_item($item[august scepter]);
    }

    int count_summons(){
        int n;
        if (get_property("_photocopyUsed") == "false")
            n += 1;
        if (available_amount($item[combat lover's locket]) > 0){
            string [int] lockets = split_string(get_property("_locketMonstersFought"), ",");
            n += 3-count(lockets);
        }
        if (have_familiar($familiar[chest mimic]))
            n += floor($familiar[chest mimic].experience/200);
        return n;
    }

    boolean gotPeriled (location loc){
        string [int] perilLoc = split_string(get_property("_perilLocations"),",");
        foreach num in perilLoc{
            if (perilLoc[num].to_int().to_location() == loc)
                return true;
        }
        return false;
    }

    int seedPoss(){
        SeedData[int] possibleSeeds=find_seeds();
        return count(possibleSeeds);
    }

    boolean isKBandSushiEnough(){
        SeedData[int] possibleSeeds=find_seeds();
        boolean bool = true;
        string DS4to7poss;
        foreach idx, seed in possibleSeeds {
            if (!contains_text(DS4to7poss,possibleSeeds[idx].dreadscroll[4]+":"+possibleSeeds[idx].dreadscroll[7])){
                DS4to7poss += possibleSeeds[idx].dreadscroll[4]+":"+possibleSeeds[idx].dreadscroll[7];
            } else {
                bool = false;
            }
        }
        return bool;
    }

// Game Mechanics
    boolean pulledToday(item it) {
        string [int] pulledToday = split_string(get_property("_roninStoragePulls"), ",");
        if (contains_text_in_array(pulledToday, it.to_int().to_string()))
            return true;
        return false;
    }

    int reservedPulls(){
        int n;
        if (!lowShiny() && available_amount($item[peppermint parasol]) == 0 && available_amount($item[navel ring of navel gazing]) == 0 && available_amount($item[greatest american pants]) == 0)
            n += 1;
        if (available_amount($item[mer-kin prayerbeads]) < 3 && pulledToday($item[mer-kin prayerbeads]))
            n += 1;
        if (item_amount($item[sea cowbell]) < 3 && pulledToday($item[sea cowbell]))
            n += 1;
        if (!lowShiny() && have_effect($effect[Jelly Combed]) == 0 && available_amount($item[comb jelly]) == 0 && pulledToday($item[comb jelly]))
            n += 1;
        if (get_property("shubJigguwattDefeated") == "false" && item_amount($item[crayon shavings]) < 4
            && item_amount($item[null-day exploit]) == 0 && pulledToday($item[null-day exploit]))
            n += 1;
        return n;
    }

    boolean pullSequence(item it) {
        if (pulls_remaining() == 0)
            return false;
        if (!pulledToday(it)) {
            if (storage_amount(it) == 0){
                if (mall_price(it) > to_int(get_property("autoBuyPriceLimit"))){
                    if (!user_confirm("Price of " + it + " exeeds autoBuyPriceLimit, skip?"))
                        abort("Price of " + it + " exeeds autoBuyPriceLimit");
                }
                buy_using_storage(it);
            }
            return take_storage(1, it);
        }
        return false;
    }

    void getLucky() {
        if (have_effect($effect[Lucky!]) > 0)
            return;
        if (have_skill($skill[Aug. 2nd: Find an Eleven-Leaf Clover Day])
            && get_property("_aug2Cast") == "false"
            && to_int(get_property("_augSkillsCast")) < 5) {
            use_skill($skill[Aug. 2nd: Find an Eleven-Leaf Clover Day]);
            if (have_effect($effect[Lucky!]) > 0)
                return;
        }
        if (available_amount($item[heartstone]) > 0 && get_property("heartstoneLuckUnlocked") == true && get_property("_heartstoneLuckUsed") == false) {
            use_skill($skill[Heartstone: %luck]);
            if (have_effect($effect[Lucky!]) > 0)
                return;
        }
        use($item[11-leaf clover]);
    }

// Progress tracker
    void step(string msg) {
        print("UTS: " + msg, "blue");
    }

// ─── EQUIPMENT AND OUTFIT HELPERS ───────────────────────────────────────────
        void codpiece(string input) {
        if (!have_item($item[The Eternity Codpiece]))
            return;
        if (input == "none") {
            string verify = visit_url("inventory.php?action=docodpiece");
            if (!contains_text(verify, " mounted in slot #"))
                return;
            for slots from 1 to 5 {
                if (contains_text(verify," Empty slot #" + slots )){
                    continue;
                } else {
                    visit_url("choice.php?whichchoice=1588&option=2&which=" + slots);
                }
            }
        } else {
            string [int] slots = split_string(input, ",");
            foreach num in slots {
                if (have_equipped(slots[num].to_item()))
                    cli_execute("unequip " + slots[num].to_item());
                if (item_amount(to_item(slots[num])) == 0 ){
                    slots[num] = "";
                    continue;
                }
                print("Inserting "+ to_item(slots[num]) + " into Codpiece");
                visit_url("inventory.php?action=docodpiece");
                visit_url("choice.php?whichchoice=1588&option=1&which=" + (num + 1)
                    + "&iid=" + to_int(to_item(slots[num])));
                visit_url("main.php");
            }
            string verify = visit_url("inventory.php?action=docodpiece");
            foreach num in slots {
                if (slots[num] == "")
                    continue;
                if (!contains_text(verify, to_item(slots[num]) + " mounted in slot #" + (num + 1)))
                    abort("Codpiece slot incorrect");
            }
        }
        cli_execute("refresh inv");
    }

    // Return equip text or empty if unavailable.
    string if_equip(item it) {
        if ($items[baseball diamond, peridot of peril, heartstone, blood cubic zirconia] contains it)
            codpiece("none");
        if (it == $item[none] || available_amount(it) == 0)
            return "";
        else
            return it.to_string() + ",";
    }

    string bathysphere(item it) {
        if (!my_familiar().underwater && have_effect($effect[driving waterproofly]) == 0)
            return "little bitty bathysphere,";
        if (it != $item[none])
            return if_equip(it);
        return "";
    }

    boolean badMaxString(string str){
        foreach c in $strings[\,,0,1,2,3,4,5,6,7,8,9] {
            if (contains_text(str, c))
                return true;
        }
        return false;
    }

    string seaOutfit() {
        foreach str in $strings[Crappy Mer-kin Disguise,
            Mer-kin Gladiatorial Gear, Mer-kin Scholar's Vestments] {
            if (have_outfit(str))
                return str;
        }
        return "";
    }

    item divingHelmet() {
        foreach it in $items[Mer-kin gladiator mask,
            Mer-kin scholar mask, crappy Mer-kin mask, aerated diving helmet, Elf Guard SCUBA tank] {
            if (item_amount(it) > 0 || have_equipped(it))
                return it;
        }
        return $item[none];
    }

    item tailpiece() {
        item it;
        foreach ite in $items[Mer-kin gladiator tailpiece,
            Mer-kin scholar tailpiece, crappy Mer-kin tailpiece, teflon swim fins] {
            if (item_amount(ite) > 0 || have_equipped(ite)){
                it = ite;
                break;
            }
        }
        return it;
    }

    string swimmingTrunks(){
        string str;
        if (have_effect($effect[driving waterproofly]) > 0)
            return "";
        if (my_path().id == 55){
            str = "really nice swimming trunks,";
        } else if (my_path().id == 0){
            str = "Elf Guard SCUBA tank,";
        }
        return str;
    }
    void equipSwimTrunks(){
        if (have_effect($effect[driving waterproofly]) > 0)
            return;
        if (my_path().id == 55){
            equip($item[really, really nice swimming trunks]);
        } else if (my_path().id == 0){
            equip($item[Elf Guard SCUBA tank]);
        }
    }

    void buyScholarGear() {
        if (available_amount($item[Mer-kin scholar mask]) == 0
            && !have_equipped($item[Mer-kin scholar mask])) {
            equip($slot[hat], $item[none]);
            equipSwimTrunks();
            buy($coinmaster[Grandma Sea Monkey],1,$item[Mer-kin scholar mask]);
        }
        if (available_amount($item[Mer-kin scholar tailpiece]) == 0
            && !have_equipped($item[Mer-kin scholar tailpiece])) {
            equip($slot[pants], $item[none]);
            equipSwimTrunks();
            buy($coinmaster[Grandma Sea Monkey],1,$item[Mer-kin scholar tailpiece]);
        }
    }

    int baseballPlayers(){
        string [int] lineup = split_string(get_property("baseballTeam"), ",");
        int players;
        foreach num in lineup { players = num + 1; }
        return players;
    }
    string baseball_equip(){
        if (baseballPlayers() < 9 && !highShiny())
            return if_equip($item[baseball diamond]);
        return "";
    }

    void yellowRayPrep(){
        if (have_effect($effect[everything looks yellow]) == 0){
            if (have_item($item[jurassic parka]))
                cli_execute("parka dilophosaur; equip jurassic parka");
        else if (have_item($item[April Shower Thoughts shield]) && available_amount($item[spitball]) == 0 && item_amount($item[glob of wet paper]) > 0)
                create($item[spitball]);
        }
    }

    int BCZcost(string BCZskill) {
        int cast = to_int(get_property("_bcz" + BCZskill));
        if (cast == 12) return 420000;
        if (cast > 12) cast -= 1;
        int castMathFloor = floor(cast / 3);
        int castMathModulo = cast % 3;
        int substatBase;
        switch (castMathModulo) {
            case 0: substatBase = 11; break;
            case 1: substatBase = 23; break;
            case 2: substatBase = 37; break;
        }
        // Pattern: 11, 23, 37, 110, 230, 370, ... 13th cast handled separately but unreachable
        return substatBase * 10 ** ((cast < 12 || (cast > 12 && castMathModulo == 0))
            ? castMathFloor : castMathFloor + 1);
    }

    string freeKill() {
        if (have_effect($effect[everything looks red]) == 0 && available_amount($item[everfull dart holster]) > 0)
            return if_equip($item[everfull dart holster]);
        if (highShiny() && have_effect($effect[everything looks yellow]) == 0){
            modes = "parka dilophosaur";
            return if_equip($item[jurassic parka]);
        }
        if (highShiny())
            return "";
        if (to_int(get_property("_assertYourAuthorityCast")) < 3 && 
            (my_location() == $location[An octopus's garden] || my_location() == $location[mer-kin gymnasium] || my_location() == $location[the caliginous abyss]))
            return "Sheriff moustache,Sheriff badge,Sheriff pistol,";
        if (to_int(get_property("_chestXRayUsed")) < 3 && have_item($item[Lil' Doctor&trade; bag]))
            return "Lil' Doctor™ bag,";
        if ((my_basestat($stat[submoxie]) - 22500) > BCZcost("SweatBulletsCasts"))
            return if_equip($item[blood cubic zirconia]);
        return "";
    }

    string freeRun() {
        if (have_effect($effect[Everything Looks Green]) == 0)
            return if_equip($item[spring shoes]);
        if (available_amount($item[greatest american pants]) > 0 && to_int(get_property("_navelRunaways")) < 3 && have_effect($effect[driving waterproofly]) > 0)
            return if_equip($item[greatest american pants]);
        if (available_amount($item[V for vivala mask]) > 0 && get_property("_vmaskBanisherUsed") == false)
            return if_equip($item[V for vivala mask]);
        if (available_amount($item[latte lovers member's mug]) > 0 && get_property("_latteBanishUsed") == false)
            return if_equip($item[latte lovers member's mug]);
        if (have_familiar($familiar[Pair of Stomping Boots]) && round((familiar_weight($familiar[Pair of Stomping Boots]) + weight_adjustment()/5)) > get_property("_banderRunaways").to_int()){
            use_familiar($familiar[Pair of Stomping Boots]);
            return "";
        }
        return freeKill();
    }

    string delay(){
        if (have_item($item[Kramco Sausage-o-Matic&trade;]))
            return if_equip($item[latte lovers member's mug]) + freeRun();
        return freeRun();
    }

    void tempEquipment(string maximizerInput, string itemInput){
        string [int] itemMap = split_string(itemInput, ",");
        item [slot] equipmentSelection;
        //Assigning items to slots
        foreach str in itemMap{
            if (itemMap[str] == "")
                continue;
            if (to_item(itemMap[str]) == $item[none]){
                print("String to item mismatch, item is " + itemMap[str] + ", notify fart scauce","red");
                continue;
            }
            if (equipmentSelection[itemMap[str].to_item().to_slot()] == $item[none]){
                equipmentSelection[itemMap[str].to_item().to_slot()] = itemMap[str].to_item(); 
                continue;
            }
            if (to_slot(to_item(itemMap[str])) == $slot[weapon] && have_skill($skill[Double-Fisted Skull Smashing])){
                if (equipmentSelection[$slot[off-hand]] == $item[none]){
                    equipmentSelection[$slot[off-hand]] = itemMap[str].to_item(); 
                    continue;
                }
            }
            if (to_slot(to_item(itemMap[str])) == $slot[acc1]){
                foreach sl in $slots[acc2,acc3]{
                    if (equipmentSelection[sl] == $item[none]){
                        equipmentSelection[sl] = itemMap[str].to_item(); 
                        continue;
                    }
                }
            }
        }
        foreach slo in equipmentSelection{
            if (available_amount(equipmentSelection[slo]) == 0)
                abort("Missing " + equipmentSelection[slo]);
            if (badMaxString(to_string(equipmentSelection[slo])))
                maximizerInput += ", equip [" + to_int(equipmentSelection[slo]) + "]";
            else
                maximizerInput += ", equip " + equipmentSelection[slo];
        }
        if (!maximize(maximizerInput, false))
            abort("Maximizer failed");
        if (modes != "")
            cli_execute(modes);
    }

// Quest Related Functions
    string adjacentCaverns(int x_coor, int y_coor) {
        buffer buf;
        int [int] nums = {
            0: (8 * y_coor) + (x_coor - 1),
            1: (8 * y_coor) + (x_coor + 1),
            2: (8 * (y_coor - 1)) + x_coor,
            3: (8 * (y_coor + 1)) + x_coor
        };
        foreach i in nums {
            matcher m = create_matcher(
                "#" + nums[i] + "<img src=\"[^\"]*/([^\"]+)\\.gif\"",
                get_property("mineLayout3")
            );
            if (m.find())
                append(buf, to_string(m.group(1)));
        }
        return to_string(buf);
    }

    int mineNum(){
        int num, x_coor, y_coor;
        string itzmine = visit_url("mining.php?mine=3");
        matcher mining_spot = create_matcher(
            "Promising Chunk of Wall \\((\\d+),(\\d+)\\)", itzmine);

        // Try preferred spots first
        foreach str in $strings[(3\,6),(3\,5),(3\,4),(3\,3),(3\,2),(2\,2),(4\,2),(5\,2)] {
            if (!contains_text(itzmine, "Open Cavern " + str)) {
                matcher open_spot = create_matcher("(\\d),(\\d)", str);
                if (open_spot.find()) {
                    x_coor = to_int(open_spot.group(1));
                    y_coor = to_int(open_spot.group(2));
                    num = (8 * y_coor) + x_coor;
                    break;
                }
            }
        }

        // Fall back to promising chunks not near bad ore
        if (num == 0) {
            while (mining_spot.find()) {
                x_coor = to_int(mining_spot.group(1));
                y_coor = to_int(mining_spot.group(2));
                if (y_coor >= 4
                    || contains_text(adjacentCaverns(x_coor, y_coor), "velcroore")
                    || contains_text(adjacentCaverns(x_coor, y_coor), "vinylore"))
                    continue;
                num = (8 * y_coor) + x_coor;
                break;
            }
        }

        // Last resort: any promising chunk not too deep
        if (num == 0) {
            while (mining_spot.find()) {
                x_coor = to_int(mining_spot.group(1));
                y_coor = to_int(mining_spot.group(2));
                print(x_coor + ", " + y_coor);
                if (y_coor >= 4) continue;
                num = (8 * y_coor) + x_coor;
                break;
            }
        }
        if (num == 0)
            abort("Generic mining did not find teflon ore, mine manually. TIP: the ores show up in adjacent veins of 5.");
        return num;
    }

    int delevelers(){
        int n;
        foreach it in $items[Mer-kin mouthsoap,crayon shavings,table tennis ball,Mer-kin mouthsoap,sea cowbell]
            if (item_amount(it) > 0)
                n += 1;
        return n;
    }

    void eatSushi(){
        string [item] sushi_map = {
            $item[beefy fish meat]:	        "beefy nigiri",
            $item[glistening fish meat]:	"glistening nigiri",
            $item[slick fish meat]:	        "slick nigiri"
        };
        foreach it in sushi_map{
            if (item_amount(it) > 0) {
                cli_execute("make " + sushi_map[it]);
                return;
            }
        }
    }

    boolean doneWithCowboy(){
        boolean bool = true;
        if (to_int(get_property("lassoTrainingCount")) + (3*item_amount($item[sea lasso])) < 21)
            bool = false;
        return bool;
    }

    boolean doneWithSeaCow(){
        boolean bool = true;
        if (item_amount($item[sea leather]) + available_amount($item[sea chaps]) + available_amount($item[sea cowboy hat]) < 2)
            bool = false;
        if (item_amount($item[sea cowbell]) < 3)
            bool = false;
        return bool;
    }

    void dreadSeedCheck(){
        if (seedPoss() == 1){
            for x from 1 to 8{
                if (get_property("dreadScroll" + x) == 0){
                    SeedData[int] possibleSeeds=find_seeds();
                    foreach idx, seed in possibleSeeds 
                        set_property("dreadScroll" + x,possibleSeeds[idx].dreadscroll[x-1]);
                }
            }
        } else {
            print(seedPoss() + " possible seeds right now");
        }
    }

    boolean cheatsheetsNeeded() {
        return item_amount($item[mer-kin cheatsheet]) < 9
            && get_property("merkinVocabularyMastery") == "0";
    }

    int [item] HealingHP = {
        $item[sea gel]:500,
        $item[mer-kin healscroll]:300,
        $item[waterlogged scroll of healing]:250,
        $item[soggy used band-aid]:1000,
        $item[New Age healing crystal]:500
    };

    float trueHPPercent(){
        float n;
        n = round((my_maxhp() - numeric_modifier("maximum hp"))/(my_buffedstat($stat[muscle]) + 3)*100);
        n = n/100;
        return n;
    }

    int [int] YogHealingsNeeded = {
        0:21,
        1:5,
        2:3,
        3:2
    };

    int YogHealingsOwned(){
        int n;
        foreach it in $items[sea gel,mer-kin healscroll,waterlogged scroll of healing,soggy used band-aid,New Age healing crystal]{
            if (available_amount(it) > 0)
                n += 1;
        }
        return n;
    }

    void YogHpCheck(){
        int maxHeal = 1001;
        int n;
        foreach it in HealingHP {
            if (n >= (available_amount($item[mer-kin prayerbeads]) <= 3 ? YogHealingsNeeded[available_amount($item[mer-kin prayerbeads])] : 2))
                break;
            if (available_amount(it) > 0){
                if (HealingHP[it] < maxHeal)
                    maxHeal = HealingHP[it];
                n += 1;
            }
        }
        int predictedMus = round(30 * (1+(numeric_modifier("Muscle Percent")/100)))+numeric_modifier("Muscle");
        print ("Predicted Mus "+ predictedMus);
        int predictedHP = round((predictedMus+3)*trueHPPercent()) + numeric_modifier("maximum hp");
        print ("predicted HP " + predictedHP);
        if (predictedHP*0.9 > maxHeal)
            abort("Muscle/HP too high, see if there are any effects you can get rid of");
    }

//Non-equipment iotm related functions
    boolean parkaForceAvailable(){
        if (have_item($item[jurassic parka]) && to_int(get_property("_spikolodonSpikeUses")) < 5)
            return true;
        return false;
    }

    boolean leftSkiAvailable(){
        if (have_item($item[mchugelarge left ski]) && to_int(get_property("_mcHugeLargeAvalancheUses")) < 3)
            return true;
        return false;
    }

    boolean doSWord(){
        if (have_familiar($familiar[Sword of S Words]) && to_int(get_property("swordOfSWordsMonster")) == 776){
            if (highShiny() && item_amount($item[sea lasso]) < 7)
                return true;
            if (!have_item($item[closed-circuit pay phone]) && item_amount($item[sea lasso]) < 4)
                return true;
        }
        return false;
    }
    
    void useAutumnaton(){
        use($item[autumn-aton]);
        string [string] upgradeLocation = {
            "mid indoor":"rightleg1",
            "low underground":"leftleg1",
            "mid outdoor":"rightarm1",
            "low indoor":"leftarm1",
            "high underground":"collectionprow1"
        };
        string autumnOptions = visit_url("inv_use.php?" + my_hash() + "&which=3&whichitem=10954");
        int [int] locations;
        matcher m = create_matcher(
            "<option\\s+value=\"([0-9]+)\">\\s*([^<]+?)\\s*</option>",
            autumnOptions
        );

        int n;
        while (m.find()) {
            int id = to_int(m.group(1));
            string name = m.group(2);
            locations[n] = id;
            n += 1;
        }

        foreach key in locations {
            if (locations[key] == to_int($location[anemone mine]) && available_amount($item[mer-kin digpick]) == 0){
                cli_execute("autumnaton send anemone mine");
                return;
            }
        }
        foreach key in locations {
            if (locations[key] == to_int($location[Shadow Rift (The Misspelled Cemetary)])){
                cli_execute("autumnaton send Shadow Rift");
                return;
            }
        }
        foreach key in locations {
            string type = (to_location(locations[key]).difficulty_level + " " + to_location(locations[key]).environment);
            if (!contains_text(get_property("autumnatonUpgrades"),upgradeLocation[type]) && upgradeLocation[type] != ""){
                cli_execute("autumnaton send " + to_location(locations[key]));
                return;
            }
        }
        cli_execute("autumnaton send noob cave");
        return;
    }

    // Peridot monster for each zone.
    int [location] wantedMonster = {
        $location[An Octopus's Garden]:                 740,   // Neptune flytrap
        $location[The Wreck of the Edgar Fitzsimmons]:  745,   // unholy diver
        $location[The Sleazy Back Alley]:               159,
        $location[The Haunted Pantry]:                  145,
        $location[The Overgrown Lot]:                   1752,
        $location[The Coral Corral]:                    775,   // sea cow
        $location[The Marinara Trench]:                 762,
        $location[Anemone Mine]:                        765,
        $location[The Dive Bar]:                        768,
        $location[Cyberzone 1]:                         2458,
        $location[Mer-kin Library]:                     840,   // Mer-kin researcher
        $location[the mer-kin outpost]:                 773,
        $location[the caliginous abyss]:                1373,
        $location[mer-kin elementary school]:           838,   // Mer-kin teacher
        $location[The Outskirts of Cobb's Knob]:        152,
        $location[Madness Bakery]:                      1750
    };

// Something about cheatsheetsand peridot
int zoneTarget(location loc) {
    if (loc == $location[mer-kin elementary school] && cheatsheetsNeeded())
        return 852;   // Mer-kin monitor
    if (wantedMonster contains loc)
        return wantedMonster[loc];
    return 0;
}

boolean [monster] haveLocketMonster = get_locket_monsters();

// ─── FOURTH OF MAY COSPLAY SABER ──────────────────────────────────────────────
// Use the Force forfeits the win and burns no turn, so saberZone() only
// allows it where the loop is purely on an item count -- never where
// progress gates on wins or turns spent (the outpost lockkey).

boolean saberReady() {
    return have_item($item[Fourth of May Cosplay Saber])
        && get_property("_saberForceUses").to_int() < 5;
}

// False in zones that gate progress on turns spent rather than on drops.
boolean saberZone(location loc) {
    return !($locations[The Mer-Kin Outpost] contains loc);
}

// Equip the saber only where a turn-free exit actually buys us something.
// Takes the target location explicitly because callers set equipment up
// before adv(), so my_location() is still the previous zone here.
string saberEquip(location loc) {
    if (saberReady() && saberZone(loc))
        return if_equip($item[Fourth of May Cosplay Saber]);
        return "";
}

// ─── DETERMINISTIC DIVER PLAN ─────────────────────────────────────────────────
// One Forced diver is a guaranteed 4 rivets + porthole + helmet (its whole
// payload is non-conditional), independent of item bonus.

// The rivet hunt is live while nothing that fills the diving-helmet slot is
// owned. Mirrors divingHelmet() in UnderTheSea.ash, which parse order keeps
// out of reach of this file.
boolean diverHuntActive() {
    if (item_amount($item[rusty rivet]) >= 8)
        return false;
    foreach it in $items[Mer-kin gladiator mask, Mer-kin scholar mask,
        crappy Mer-kin mask, aerated diving helmet, Elf Guard SCUBA tank] {
        if (item_amount(it) > 0 || have_equipped(it))
            return false;
    }
    return true;
}

// Mirrors doneWithSeaCow() in UnderTheSea.ash, which parse order keeps out of
// reach of this file.
boolean seaCowNeeded() {
    if (item_amount($item[sea leather]) + available_amount($item[sea chaps])
        + available_amount($item[sea cowboy hat]) < 2)
        return true;
    if (item_amount($item[sea cowbell]) < 3)
        return true;
    return false;
}

boolean prayerbeadsShort() {
    return available_amount($item[mer-kin prayerbeads]) < 3;
}

// ─── THE FORCE BUDGET ─────────────────────────────────────────────────────────
// 5 saber forces, 2 alloted for unholy diver
int saberChargesLeft() {
    if (!have_item($item[Fourth of May Cosplay Saber]))
        return 0;
    return 5 - get_property("_saberForceUses").to_int();
}

boolean diverForceReady() {
    return diverHuntActive() && saberChargesLeft() > 0;
}

// Charges available to each claimant, after every higher-priority claim.
int forcesAfterDiver() {
    return saberChargesLeft() - (diverHuntActive() ? 2 : 0);
}
int forcesAfterHealer() {
    return forcesAfterDiver() - (prayerbeadsShort() ? 1 : 0);
}
int saberForcesFree() {
    return forcesAfterHealer() - (seaCowNeeded() ? 1 : 0);
}

// Weapon-slot pin for the summoned diver fights, so the Force is castable.
string diverSaber() {
    if (diverForceReady())
        return "Fourth of May Cosplay Saber,";
    return "";
}

// CCS entry. On the diver: lay the insurance egg for diver #2 while the fight
// is still open, then Force the drops. Returns true when it Forced -- the
// combat is over and the caller must end the consult pass.
boolean diverForce(monster mob, string page_text) {
    if (mob != $monster[unholy diver])
        return false;
    if (!diverForceReady())
        return false;
    if (!have_equipped($item[Fourth of May Cosplay Saber]))
        return false;
    if (!contains_text(page_text, "Use the Force"))
        return false;
    if (my_familiar() == $familiar[chest mimic])
        use_skill($skill[%fn, lay an egg]);
    step("Use the Force -> unholy diver (rivets " + item_amount($item[rusty rivet]) + "/8)");
    use_skill($skill[Use the Force]);
    return true;
}

// ─── SEA COW: THE SAME TRICK AT THE CORRAL ────────────────────────────────────
// One Forced cow is a guaranteed leather + cowbell (both non-conditional).

// CCS entry, same contract as diverForce(): true means the fight is over and
// the caller must end the consult pass.
boolean seaCowForce(monster mob, string page_text) {
    if (mob != $monster[sea cow])
        return false;
    if (!seaCowNeeded())
        return false;
    if (forcesAfterHealer() <= 0)
        return false;
    if (have_equipped($item[pro skateboard]) && get_property("_epicMcTwistUsed") == "false")
        return false;
    if ($location[the coral corral].turns_spent <= 1
        && item_amount($item[sea leather]) == 0
        && available_amount($item[sea cowboy hat]) == 0)
        return false;
    if (!have_equipped($item[Fourth of May Cosplay Saber]))
        return false;
    if (!contains_text(page_text, "Use the Force"))
        return false;
    step("Use the Force -> sea cow");
    use_skill($skill[Use the Force]);
    return true;
}

// ─── OUTPOST HEALER AND LIBRARY RESEARCHER ────────────────────────────────────
boolean healerForce(monster mob, string page_text) {
    if (mob != $monster[Mer-kin healer])
        return false;
    if (!prayerbeadsShort())
        return false;
    if (forcesAfterDiver() <= 0)
        return false;
    if (!have_equipped($item[Fourth of May Cosplay Saber]))
        return false;
    if (!contains_text(page_text, "Use the Force"))
        return false;
    step("Use the Force -> Mer-kin healer (prayerbeads)");
    use_skill($skill[Use the Force]);
    return true;
}

string healerSaber() {
    if (prayerbeadsShort()
        && forcesAfterDiver() > 0
        && have_item($item[Fourth of May Cosplay Saber]))
        return "Fourth of May Cosplay Saber,";
    return "";
}

boolean researcherForce(monster mob, string page_text) {
    if (mob != $monster[Mer-kin researcher])
        return false;
    if (item_amount($item[mer-kin killscroll]) > 0
        && item_amount($item[mer-kin healscroll]) > 0)
        return false;
    if (saberForcesFree() <= 0)
        return false;
    if (!have_equipped($item[Fourth of May Cosplay Saber]))
        return false;
    if (!contains_text(page_text, "Use the Force"))
        return false;
    step("Use the Force -> Mer-kin researcher (scrolls)");
    use_skill($skill[Use the Force]);
    return true;
}

// ─── ROUTE-SPECIFIC SHARED HELPERS ───────────────────────────────────────────

// Keep duplicate.edu in an educate slot so Duplicate is castable in combat;
// duplicateMonster() below spends the one daily cast.
boolean duplicateEducated() {
    return get_property("sourceTerminalEducate1") == "duplicate.edu"
        || get_property("sourceTerminalEducate2") == "duplicate.edu";
}

boolean duplicateReady() {
    if (get_campground()[$item[Source terminal]] == 0)
        return false;
    if (get_property("_sourceTerminalDuplicateUses").to_int() >= 1)
        return false;
    return contains_text(get_property("sourceTerminalEducateKnown"), "duplicate.edu");
}

void sourceEducate() {
    if (!duplicateReady() || duplicateEducated())
        return;
    cli_execute("terminal educate duplicate.edu");
}

// CCS entry, cast at the top of the fight so nothing ends it first.
void duplicateMonster(monster mob, string page_text) {
    if (!duplicateReady() || !duplicateEducated())
        return;
    // Doubling pays only on a WIN, so never spend the day's cast on a fight
    // the saber is about to Force.
    boolean aboutToForce = have_equipped($item[Fourth of May Cosplay Saber])
        && ((mob == $monster[unholy diver] && diverForceReady())
            || (mob == $monster[sea cow] && seaCowNeeded() && forcesAfterHealer() > 0));
    if (aboutToForce)
        return;
    // Best killed tables the route meets: the golem (free fight, flat 100%
    // crayon shavings -- the Shub deleveler), then the unForced sea cow, the
    // sheet-grind monitor, and the diver only on saberless kits, where a
    // doubled kill's 8 rivets end the hunt outright.
    boolean wanted = (mob == $monster[Black Crayon Golem] && item_amount($item[crayon shavings]) < 4)
        || (mob == $monster[sea cow] && seaCowNeeded() && !diverHuntActive())
        || (mob == $monster[Mer-kin monitor] && cheatsheetsNeeded())
        || (mob == $monster[unholy diver] && item_amount($item[rusty rivet]) < 8
            && !have_item($item[Fourth of May Cosplay Saber]));
    if (!wanted)
        return;
    if (!contains_text(page_text, "Duplicate"))
        return;
    step("Duplicate: " + mob);
    use_skill($skill[Duplicate]);
}

// ─── EIGHT DAYS A WEEK PILL KEEPER ────────────────────────────────────────────
// Take only the daily free pill -- the rest cost spleen the diet needs.
// `pill` is a mafia pillkeeper keyword, not a pill name.
void pillKeeper(string pill) {
    if (!have_item($item[Eight Days a Week Pill Keeper]))
        return;
    if (get_property("_freePillKeeperUsed") != "false")
        return;
    step("Pill keeper: " + pill);
    cli_execute("pillkeeper " + pill);
}

// ─── VAMPYRIC CLOAKE ──────────────────────────────────────────────────────────
// Pinned to the back slot so Become a Bat stays castable; all 10 daily form
// uses go to the bat.
boolean cloakeReady() {
    return have_item($item[vampyric cloake])
        && get_property("_vampyreCloakeFormUses").to_int() < 10;
}

// Only the zones we grind purely for a drop count. Anywhere gated on turns spent
// or on finding a noncombat, a bigger item bonus buys nothing, and there are
// only 10 charges to spread across the run.
boolean cloakeZone(location loc) {
    return $locations[The Wreck of the Edgar Fitzsimmons, An Octopus's Garden,
        The Coral Corral, Mer-kin Library, Mer-kin Elementary School] contains loc;
}

// Pins the cloake into the back slot so the skill is actually available in
// combat. Callers set gear up before adv(), so the target zone is passed in
// explicitly -- my_location() is still the previous zone at that point.
string cloakeEquip(location loc) {
    if (cloakeReady() && cloakeZone(loc))
        return "vampyric cloake,";
    return "";
}

// Cast from the CCS at the top of every round. Cheap to call repeatedly: once
// the form is up, have_effect() short-circuits it, which also enforces the
// one-form-per-combat rule for free.
void becomeBat(string page_text) {
    if (!cloakeReady() || !cloakeZone(my_location()))
        return;
    if (have_effect($effect[Bat-Adjacent Form]) > 0)
        return;
    if (!have_equipped($item[vampyric cloake]))
        return;
    if (!contains_text(page_text, "Become a Bat"))
        return;
    use_skill($skill[Become a Bat]);
}

// ─── MAP THE MONSTERS ─────────────────────────────────────────────────────────
// Comprehensive Cartography gives 3 casts a day. Each turns the next fight in a
// zone into a monster of your choosing -- the same job as the Peridot of Peril,
// answered in UnderTheSea_Choice.ash from the same wantedMonster table.
//
// The Peridot is once per zone per day; these are the extra charges once the
// Peridot's is spent, longest odds first. The outpost is excluded: its
// lockkey gates on turns spent, so a chosen encounter saves nothing there.

boolean mapReady() {
    return have_skill($skill[Map the Monsters])
        && get_property("_monstersMapped").to_int() < 3
        && get_property("mappingMonsters") == "false";
}

// Only cast once the Peridot's charge for this zone is gone, so the two do not
// both spend themselves picking the same monster.
void mapMonster(location loc) {
    if (!mapReady())
        return;
    if (available_amount($item[peridot of peril]) > 0
        && !gotPeriled(loc))
        return;
    step("Map the Monsters armed for " + loc);
    use_skill($skill[Map the Monsters]);
}

// ─── TIME-SPINNER ─────────────────────────────────────────────────────────────
// mafia's "timespinner" CLI covers only food and pranks, so Travel to a
// Recent Fight's choice chain (1195 -> 1196, monid submit) is walked by hand.

boolean timeSpinnerReady() {
    return have_item($item[Time-Spinner])
        && to_int(get_property("_timeSpinnerMinutesUsed")) <= 7
        && my_adventures() > 0;
}

// Re-fight `mon` for one turn, guaranteed. Only fires straight after fighting
// that monster (last_monster()), which keeps it inside the recent-fights
// window without guessing at the window's exact size -- and works after
// summoned or Forced fights too, since the list records encounters, not wins.
boolean timeSpinnerFight(monster mon) {
    if (!timeSpinnerReady())
        return false;
    if (last_monster() != mon)
        return false;

    step("Time-Spinner: refighting " + mon);
    visit_url("inv_use.php?whichitem=" + to_int($item[Time-Spinner]) + "&pwd=" + my_hash());
    // mafia auto-resolves choices it has handling for, even on visit_url; if
    // nothing is live any manual answer would abort with "Invalid choice".
    if (!handling_choice()) {
        step("Time-Spinner choice was auto-resolved or never opened; skipping");
        return false;
    }
    int travel;
    int backOut;
    foreach num, optionText in available_choice_options() {
        if (contains_text(optionText, "Travel to a Recent Fight"))
            travel = num;
        if (contains_text(optionText, "Maybe Later"))
            backOut = num;
    }
    // Never leave the run parked inside a choice we could not read.
    if (travel == 0) {
        if (backOut > 0)
            run_choice(backOut);
        return false;
    }
    run_choice(travel);
    run_choice(1, "monid=" + to_int(mon));
    // The monid submit drops us into the fight; without this the session is
    // left mid-combat and the next adv() errors out.
    run_combat();
    return true;
}

void timeSpinnerRefight(location loc) {
    int target = zoneTarget(loc);
    if (target == 0)
        return;
    // Only worth a turn where the target is genuinely rare; these are the same
    // zones Map the Monsters spends its charges on.
    if (my_location() != loc)
        return;
    timeSpinnerFight(to_monster(target));
}

// ─── POCKET PROFESSOR ─────────────────────────────────────────────────────────
// The next lecture needs buffed familiar weight of n^2 + 1 lbs.
int professorLectureLimit() {
    int w = familiar_weight($familiar[Pocket Professor]) + weight_adjustment();
    int n;
    while ((n * n + 1) <= w)
        n += 1;
    return n;
}

boolean professorReady() {
    return have_familiar($familiar[Pocket Professor])
        && get_property("_pocketProfessorLectures").to_int() < professorLectureLimit();
}

void professorFamiliar() {
    if (!professorReady())
        return;
    // Rivet hunt: under the Force plan a diver pays 4 guaranteed rivets and
    // the second one is a Time-Spinner refight away -- lecture copies add
    // nothing, so keep the better drop familiar out.
    if (diverHuntActive()) {
        if (!diverForceReady())
            use_familiar($familiar[Pocket Professor]);
        return;
    }
    // Corral: once the Force budget there is spent, lecture copies of the sea
    // cow are the next cheapest source of leather and cowbells.
    if (seaCowNeeded() && forcesAfterHealer() <= 0) {
        use_familiar($familiar[Pocket Professor]);
        return;
    }
    // Otherwise the route still wants a familiar with good item drop while the
    // professor's lecture copies are still free.
    if (!have_familiar($familiar[Chest Mimic]))
        use_familiar($familiar[Pocket Professor]);
}

void lectureOnRelativity(monster mob, string page_text) {
    if (!professorReady())
        return;
    if (my_familiar() != $familiar[Pocket Professor])
        return;
    // Same targets as professorFamiliar(): the diver while rivets are owed,
    // the sea cow while its drops are.
    boolean wanted = (mob == $monster[unholy diver] && item_amount($item[rusty rivet]) < 8)
        || (mob == $monster[sea cow] && seaCowNeeded());
    if (!wanted)
        return;
    // The skill refuses to fire below 2 adventures, even against a free fight.
    if (my_adventures() < 2)
        return;
    if (!contains_text(page_text, "lecture on relativity"))
        return;
    step("Lecture on Relativity: chaining a free " + mob);
    use_skill($skill[lecture on relativity]);
}

// ─── JANUARY'S GARBAGE TOTE: BROKEN CHAMPAGNE BOTTLE ──────────────────────────
// The bottle's ounces are spent only at the fattest rolled tables.
boolean champagneReady() {
    return have_item($item[broken champagne bottle])
        && get_property("garbageChampagneCharge").to_int() > 0;
}

// Only where a fat table is being ROLLED. Forced drops ignore item bonus, so
// while a Force plan covers the zone the ounces are banked instead.
string champagneEquip(location loc) {
    if (!champagneReady())
        return "";
    if (loc == $location[The Wreck of the Edgar Fitzsimmons] && !diverForceReady())
        return if_equip($item[broken champagne bottle]);
    // The corral inherits the bottle once the Force budget there is spent and
    // the cow's leather/cowbell rolls are back to probability.
    if (loc == $location[The Coral Corral] && seaCowNeeded() && forcesAfterHealer() <= 0)
        return if_equip($item[broken champagne bottle]);
    return "";
}

// Pull the bottle out of the tote once, if we own a tote and have not already
// spent its charges this ascension.
void garbageTote() {
    if (!have_item($item[January's Garbage Tote]))
        return;
    if (have_item($item[broken champagne bottle]))
        return;
    if (get_property("garbageChampagneCharge").to_int() <= 0)
        return;
    step("Garbage tote: fetching the broken champagne bottle");
    visit_url("inv_use.php?whichitem=" + $item[January's Garbage Tote].to_int() + "&pwd=" + my_hash());
    // Same auto-resolution caveat as everywhere: only answer a LIVE choice.
    if (!handling_choice()) {
        step("Tote choice was auto-resolved or never opened; skipping");
        return;
    }
    int grab;
    int leave;
    foreach num, optionText in available_choice_options() {
        if (contains_text(optionText, "champagne"))
            grab = num;
        if (contains_text(optionText, "Ignore the garbage"))
            leave = num;
    }
    // Never leave the run parked inside a choice we could not read.
    if (grab > 0)
        run_choice(grab);
    else if (leave > 0)
        run_choice(leave);
}

// ─── POWERFUL GLOVE ───────────────────────────────────────────────────────────
// Equipped only at re-roll sites, and only once Macrometeorite's casts are
// gone.
boolean gloveReady() {
    return have_item($item[Powerful Glove])
        && get_property("_powerfulGloveBatteryPowerUsed").to_int() <= 90;
}

// ─── METEOR LORE: MACROMETEORITE ──────────────────────────────────────────────
// Same re-roll as the glove's CHEAT CODE but from a skill; rerollEnemy()
// spends these casts first.
boolean macroReady() {
    return have_skill($skill[Macrometeorite])
        && get_property("_macrometeoriteUses").to_int() < 10;
}

string gloveEquip(location loc) {
    // Macrometeorite does the same job from a skill slot; while it has casts
    // left, the accessory slot goes back to the zirconia and backup camera.
    if (macroReady())
        return "";
    if (gloveReady() && loc == $location[The Wreck of the Edgar Fitzsimmons])
        return if_equip($item[Powerful Glove]);
    return "";
}

// ─── MUMMING TRUNK ────────────────────────────────────────────────────────────
// A second costume overwrites the first, so Prince George goes on whichever
// familiar the item setup actually picks -- hence called from
// use_familiar("itdrop") rather than at a fixed point in the run.
void mummery() {
    if (!have_item($item[mumming trunk]))
        return;
    // _mummeryMods records what has already been applied today; an Item Drop entry means Prince George is spent.
    if (contains_text(get_property("_mummeryMods"), "Item Drop"))
        return;
    if (my_familiar() == $familiar[none])
        return;
    cli_execute("mummery item");
}

// ─── REROLL / REPLACE / FEEL NOSTALGIC / OTOSCOPE ─────────────────────────
// These are called by UnderTheSeaCCS.ash directly.

// ─── SPACE JELLYFISH ──────────────────────────────────────────────────────────
// Extract stench jelly for NCforce(); jelly costs spleen the diet needs, so
// exactly one is taken.
boolean jellyfishReady() {
    return have_familiar($familiar[Space Jellyfish]);
}

void extractJelly(monster mob, string page_text) {
    if (my_familiar() != $familiar[Space Jellyfish])
        return;
    if (mob.attack_element != $element[stench] && mob.defense_element != $element[stench])
        return;
    // Spleen is contested; one forced noncombat is all we are after.
    if (item_amount($item[stench jelly]) > 0)
        return;
    if (!contains_text(page_text, "Extract Jelly"))
        return;
    use_skill($skill[Extract Jelly]);
}

// Casts whichever re-roller is available: Macrometeorite (Meteor Lore, 10 a
// day, no equipment slot) first, the glove's CHEAT CODE second. On true the
// fight holds a NEW monster and the caller MUST re-dispatch the CCS main()
// with last_monster() and a re-fetched fight page -- a bare return would fall
// through to the CCS's safety abort, since mafia does not re-invoke a consult
// script that returns mid-combat.
boolean rerollEnemy(string page_text) {
    if (macroReady() && contains_text(page_text, "Macrometeorite")) {
        step("Macrometeorite: re-rolling the monster");
        use_skill($skill[Macrometeorite]);
        return true;
    }
    if (gloveReady() && have_equipped($item[Powerful Glove])
        && contains_text(page_text, "CHEAT CODE: Replace Enemy")) {
        step("CHEAT CODE: re-rolling the monster");
        use_skill($skill[CHEAT CODE: Replace Enemy]);
        return true;
    }
    return false;
}

// Fitzsimmons policy: re-roll anything that is not the diver while rivets are
// still owed.
boolean replaceEnemy(monster mob, string page_text) {
    if (my_location() != $location[The Wreck of the Edgar Fitzsimmons])
        return false;
    // Never re-roll a free fight: it costs nothing, burns delay, and dies to
    // the location logic's fall-through kill.
    if (free_monster(mob))
        return false;
    // Never re-roll the monster we came for, and stop once its drops are in.
    if (mob == $monster[unholy diver])
        return false;
    if (item_amount($item[rusty rivet]) >= 8)
        return false;
    return rerollEnemy(page_text);
}

// ─── EMOTION CHIP: FEEL NOSTALGIC ─────────────────────────────────────────────
// Feel Nostalgic pays only on a WIN and does nothing cast on the monster
// being copied.
void feelNostalgic(monster mob, string page_text) {
    if (!have_skill($skill[Feel Nostalgic]))
        return;
    if (get_property("_feelNostalgicUsed").to_int() >= 3)
        return;
    // The appended drops only pay out if this fight is WON. When the saber
    // still has Force charges the rest of the script may spend, free_kill()
    // may Use the Force out of the combat, forfeiting the win and the charge
    // with it -- so never overlap the two.
    if (saberForcesFree() > 0 && have_equipped($item[Fourth of May Cosplay Saber]))
        return;
    // Worth a charge only while the copied table still owes us something:
    // the diver's rivets, the sea cow's leather and cowbells, or the
    // monitor's cheatsheet (~capped at itdrop bonuses) during the grind.
    string copied = get_property("lastCopyableMonster");
    boolean wanted = (copied == "unholy diver" && item_amount($item[rusty rivet]) < 8)
        || (copied == "sea cow" && seaCowNeeded())
        || (copied == "Mer-kin monitor" && cheatsheetsNeeded());
    if (!wanted)
        return;
    // Casting it on the monster we are nostalgic for does nothing.
    if (mob.to_string() == copied)
        return;
    if (!contains_text(page_text, "Feel Nostalgic"))
        return;
    step("Feel Nostalgic: re-rolling the " + copied + " table");
    use_skill($skill[Feel Nostalgic]);
}

// ─── LIL' DOCTOR BAG: OTOSCOPE ────────────────────────────────────────────────
// freeKill() equips the bag for Chest X-Ray; Otoscope rides along, cast
// early so free_kill() cannot end the fight first. Reflex Hammer is wired
// into free_run() with the other banishes.
void otoscope(monster mob, string page_text) {
    // A fight the saber is about to Force has its drops forced anyway; the
    // +200% would be a wasted charge.
    if (diverForceReady() && have_equipped($item[Fourth of May Cosplay Saber]))
        return;
    if (get_property("_otoscopeUsed").to_int() >= 3)
        return;
    if (!have_equipped($item[Lil' Doctor&trade; bag]))
        return;
    if (mob != $monster[unholy diver])
        return;
    if (item_amount($item[rusty rivet]) >= 8)
        return;
    if (!contains_text(page_text, "Otoscope"))
        return;
    step("Otoscope on " + mob);
    use_skill($skill[Otoscope]);
}

// Roughly how many noncombat forces this account can field. Deliberately does
// NOT count the Pill Keeper: this is the number we use to decide whether the
// free pill needs reserving for Sneakisol, so counting it would be circular.
int NCForceEstimate(){
    int force = 2;
    // Counts remaining CHARGES, not ownership.
    if (have_item($item[Apriling band tuba]))
        force += max(0, 3 - to_int(get_property("_aprilBandTubaUses")));
    if (have_item($item[McHugeLarge left ski]))
        force += max(0, 3 - to_int(get_property("_mcHugeLargeAvalancheUses")));
    if (have_item($item[Cincho de Mayo]))
        force += min(3, 1 + max(0, total_free_rests() - to_int(get_property("timesRested"))) / 2);
    if (have_item($item[Jurassic Parka]))
        force += max(0, 5 - to_int(get_property("_spikolodonSpikeUses")));
    return force;
}

// ─── SOURCE TERMINAL ──────────────────────────────────────────────────────────
// items.enh is re-upped wherever +item setup already happens.

void sourceEnhance() {
    if (get_campground()[$item[Source terminal]] == 0)
        return;
    if (have_effect($effect[items.enh]) > 0)
        return;
    if (get_property("_sourceTerminalEnhanceUses").to_int() >= 3)
        return;
    cli_execute("terminal enhance items.enh");
}

// ─── REMAINING SHARED HELPERS ───────────────────────────────────────────────
// These were previously split across iotm.ash and are now consolidated here so
// UnderTheSea.ash and UnderTheSeaCCS.ash can share a single helper module.

void cargoPocket() {
    if (get_property("cargoPocketsEmptied") == "")
        set_property("cargoPocketsEmptied", "");
    // Comma-delimited match so a pocket number cannot match inside another.
    if (contains_text("," + get_property("cargoPocketsEmptied") + ",", ",494,"))
        return;
    step("Cargo shorts: opening pocket 494");
    cli_execute("cargo pocket 494");
}

// ─── KREMLIN'S GREATEST BRIEFCASE ─────────────────────────────────────────────
// Driven through Ezandora's Briefcase script, which owns the dial, handle
// and tab state machine; "briefcase buff item" clicks until Items Are
// Forever lands.
void briefcase() {
    if (!have_item($item[Kremlin's Greatest Briefcase]))
        return;
    if (have_effect($effect[Items Are Forever]) > 0)
        return;
    // An unopened case has no tabs to read, so asking for a buff would only
    // burn clicks. Opening it is a two-day job and not something a run should
    // be spending its budget on.
    if (get_property("_kgbOpened") == "false")
        return;
    if (get_property("_kgbClicksUsed").to_int() >= 22)
        return;
    cli_execute("briefcase buff item");
}

// ─── NONCOMBAT FORCER ─────────────────────────────────────────────────────────
// Spend the cheapest available forcer charge; NCForceEstimate() counts what
// remains.

void NCforce() {
    if (get_property("noncombatForcerActive") != "true") {
        if (have_item($item[apriling band helmet]) && get_property("_aprilBandTubaUses").to_int() < 3 && have_item($item[Apriling band tuba])) {
            cli_execute("aprilband play tuba");
        // Enter the Cincho branch only if it can actually fire -- either
        // enough cinch already, or free rests left to restore it.
        } else if (have_item($item[Cincho de Mayo])
            && (get_property("_cinchUsed").to_int() <= 40
                || get_property("timesRested").to_int() < total_free_rests())){
            while (get_property("_cinchUsed").to_int() > 40
                && get_property("timesRested").to_int() < total_free_rests()) {
                // The helmet sweetens the rest but is optional; equipping it
                // unowned hard-errors.
                if (have_item($item[Apriling band helmet]))
                    cli_execute("unequip hat; equip apriling band helmet");
                cli_execute("camp rest free");
            }
            if (get_property("_cinchUsed").to_int() <= 40) {
                equip($slot[acc3], $item[cincho de mayo]);
                use_skill($skill[Cincho: Fiesta Exit]);
            }
        } else if (have_item($item[Eight Days a Week Pill Keeper])
            && get_property("_freePillKeeperUsed") == "false") {
            // Sneakisol has Clara's bell's noncombat-forcing behaviour and is
            // free, so it comes before anything that costs a pull. If the free
            // pill already went on Fidoxene this call is a no-op.
            pillKeeper("free noncombat");
        } else if (!have_item($item[mchugelarge duffel bag]) && !have_item($item[jurassic parka]) && !have_item($item[allied radio backpack])){
            foreach it in $items[Handheld Allied radio, Clara's bell, stench jelly]{
                if (!pulledToday(it)){
                    if (it == $item[Clara's Bell] && storage_amount(it) == 0)
                        continue;
                    if (pulls_remaining() == 0)
                        return;
                    pullSequence(it);
                    if (it == $item[Clara's bell])
                        use (it);
                    else if (it == $item[Handheld Allied radio])
                        cli_execute("alliedradio misc sniper");
                    else if (it == $item[stench jelly])
                        chew(it);
                    break;
                }
            }
        }
    }
}

// ─── TRICK OR TREAT ───────────────────────────────────────────────────────────

void candy(string action) {
    if (action == "fight"){
        int houseToVisit = index_of(get_property("_trickOrTreatBlock"), "D");
        visit_url("place.php?whichplace=town&action=town_trickortreat");
        visit_url("choice.php?whichchoice=804&pwd=" + my_hash() + "&option=3&whichhouse=" + houseToVisit);
        run_combat();
    } else if (action == "treat"){
        while(contains_text(get_property("_trickOrTreatBlock"),"L")){
            int houseToVisit = index_of(get_property("_trickOrTreatBlock"), "L");
            visit_url("place.php?whichplace=town&action=town_trickortreat");
            visit_url("choice.php?whichchoice=804&pwd=" + my_hash() + "&option=3&whichhouse=" + houseToVisit);
        }
    }
}

void useMapIfAvailable() {
    if (highShiny()) return;
    if (!have_equipped($item[backup camera])) return;
    if (free_monster(get_property("lastCopyableMonster").to_monster())) return;
    if (get_property("_mapToACandyRichBlockUsed") == "false" && item_amount($item[map to a candy-rich block]) > 0) 
        use($item[map to a candy-rich block]);
    if (get_property("_mapToACandyRichBlockUsed") == "true")
        candy("fight");
}

int [string] clan_to_ID {
    "Hyrule" : 72876,
    "Dread and Final" : 2047010985,
    "Dread Mart" : 2047010683,
    "Dread Outlet Bargain Market" : 2047010572,
    "Dreadleys" : 2047010988,
    "DreadNugget" : 2047010986,
    "Dreadway" : 2047010667,
    "Fart Sauce Annex" : 2047010939
};

void whitelist(string clan){
    visit_url("showclan.php?whichclan="+clan_to_ID[clan]+"&action=joinclan&confirm=on");
}

// ─── BANISH UTILITIES ─────────────────────────────────────────────────────────

record ban {
    string pref;
    skill banSkill;
};

ban [item] banMap = {
    // prefs are matched inside \Q..\E against banishedMonsters, so they must
    // be literal prefixes of the recorded banisher name -- no regex escaping.
    $item[spring shoes]:        new ban("Spring Kick",           $skill[spring kick]),
    $item[monodent of the sea]: new ban("Sea *dent",             $skill[Sea *dent: Throw a Lightning Bolt]),
    $item[Heartstone]:          new ban("Heartstone",            $skill[Heartstone: %banish]),
    $item[none]:                new ban("snokebomb",             $skill[snokebomb]),
};

// Returns all locations a given monster can appear in
location [int] monster_found_in(monster m) {
    location [int] output;
    foreach o in $locations[]
        if (o.get_location_monsters() contains m)
            output[count(output)] = o;
    return output;
}

// Returns the monster currently banished by a given banisher string
monster banished(string banisher) {
    matcher m = create_matcher("([^:]+):\\Q" + banisher,
        get_property("banishedMonsters")
    );
    return m.find() ? to_monster(m.group(1)) : $monster[none];
}

// Returns true if the given banisher has been used on a monster at your current location
boolean banishUsedAtYourLocation(string banisher) {
    foreach num in monster_found_in(banished(banisher)) {
        if (monster_found_in(banished(banisher))[num] == my_location())
            return true;
    }
    return false;
}

// Equips the appropriate banish gear for a location (that hasn't been used yet) and sets the slot override property.
// NOTE: has the side effect of setting an Override property — callers should be aware.
item banishGear(location loc) {
    item it;
    foreach ite in $items[spring shoes, monodent of the sea, Heartstone] {
        if (ite == $item[Heartstone] && get_property("heartstoneBanishUnlocked") == "false")
            continue;
        if (appearance_rates(loc)[banished(banMap[ite].pref)] == 0 && have_item(ite)) {
            it = ite;
            break;
        }
    }
    // No candidate leaves it at $item[none]; writing an override for it would
    // create a junk "noneOverride" property.
    if (it != $item[none]) {
        set_property(it.to_slot().to_string() + "Override", ", equip " + it);
        print(it.to_slot().to_string() + "Override");
    }
    return it;
}

// Returns the combat banish skill for the first equipped banish item
// whose target is no longer appearing at your location
skill combatBan() {
    foreach ite in $items[spring shoes, monodent of the sea, Heartstone] {
        if (ite == $item[Heartstone] && get_property("heartstoneBanishUnlocked") == "false")
            continue;
        if (have_equipped(ite)
            && appearance_rates(my_location())[banished(banMap[ite].pref)] == 0) {
            print("Banish item being considered " + ite + " parsed banished monster is " + banished(banMap[ite].pref) + " and the calculated appearance rate at current location is " + appearance_rates(my_location())[banished(banMap[ite].pref)]);
            cli_execute("get banishedMonsters");
            return banMap[ite].banSkill;
        }
    }
    return $skill[none];
}

// ─── EVERFULL DART ────────────────────────────────────────────────────────────
string perks = get_property("everfullDartPerks");
boolean bullseyeReady() {
    int n = count_substring(perks, "25% Better bullseye targeting") + count_substring(perks, "25% better chance to hit bullseyes") + count_substring(perks, "25% More Accurate bullseye targeting");
    return (n >= 2);
}

boolean everfullReady(){
    if (!bullseyeReady())
        return false;
    return (contains_text(perks, "You are less impressed by bullseyes")
            && contains_text(perks, "Bullseyes do not impress you much"))
        || count_substring(perks, "Bullseyes do not impress you much") >= 2
        || count_substring(perks, "You are less impressed by bullseyes") >= 2;
    return true;
}

void darts() {
    while (to_int(get_property("_dartsLeft")) > 0
        && have_equipped($item[everfull dart holster])
        && current_round() > 0) {
        if (contains_text(get_property("everfullDartPerks"), "Butt")) {
            matcher m = create_matcher("(\\d+):butt", get_property("_currentDartboard"));
            if (!m.find()) break;
            use_skill(to_skill(to_int(m.group(1))));
        } else {
            use_skill($skill[Darts: Throw at %part1]);
        }
    }
}

// ─── DARTS, BCZ, TRAINSET, AND LEPRECONDO ──────────────────────────────────

// ─── TRAINSET ─────────────────────────────────────────────────────────────────

void trainset() {
    int pos = to_int(get_property("trainsetPosition")) % 8;
    int [int] slots = {
        (pos)     % 8: 8,   // next station
        (pos + 1) % 8: 1,
        (pos + 2) % 8: 15,
        (pos + 3) % 8: 20,
        (pos + 4) % 8: 3,
        (pos + 5) % 8: 7,
        (pos + 6) % 8: 2,
        (pos + 7) % 8: 19
    };
    visit_url("choice.php?forceoption=0?whichchoice=1485&option=1"
        + "&slot%5B0%5D=" + slots[0]
        + "&slot%5B1%5D=" + slots[1]
        + "&slot%5B2%5D=" + slots[2]
        + "&slot%5B3%5D=" + slots[3]
        + "&slot%5B4%5D=" + slots[4]
        + "&slot%5B5%5D=" + slots[5]
        + "&slot%5B6%5D=" + slots[6]
        + "&slot%5B7%5D=" + slots[7]);
}

// ─── LEPRECONDO ───────────────────────────────────────────────────────────────

string [int] lepRoomToNum = {
    1:"buckets of concrete",        2:"thrift store oil painting",
    3:"boxes of old comic books",   4:"second-hand hot plate",
    5:"beer cooler",                6:"free mattress",
    7:"gigantic chess set",         8:"UltraDance karaoke machine",
    9:"cupcake treadmill",          10:"beer pong table",
    11:"padded weight bench",       12:"internet-connected laptop",
    13:"sous vide laboratory",      14:"programmable blender",
    15:"sensory deprivation tank",  16:"fruit-smashing robot",
    17:"ManCave™ sports bar set",   18:"couch and flatscreen",
    19:"kegerator",                 20:"fine upholstered dining table set",
    21:"whiskeybed",                22:"high-end home workout system",
    23:"complete classics library", 24:"ultimate retro game console",
    25:"Omnipot",                   26:"fully-stocked wet bar",
    27:"four-poster bed"
};

void leprecondo(string input) {
    string [int] rooms = split_string(input, ",");
    int [int] lepRoom;
    int count;
    foreach num in rooms {
        int val = to_int(rooms[num]);
        string discovered = get_property("leprecondoDiscovered");
        // Two-digit room numbers need a plain contains; single-digit need comma guards
        // to avoid matching "1" inside "10", "11", etc.
        boolean found = (val >= 10)
            ? contains_text(discovered, rooms[num])
            : contains_text(discovered, "," + rooms[num] + ",");
        if (found) {
            lepRoom[count] = val;
            count += 1;
        }
    }
    cli_execute("leprecondo furnish "
        + lepRoomToNum[lepRoom[3]] + ","
        + lepRoomToNum[lepRoom[2]] + ","
        + lepRoomToNum[lepRoom[1]] + ","
        + lepRoomToNum[lepRoom[0]]);
}

void fillPrereqs(int outcomeSlot, string pitchType) {
    int filled = 0;
    int before = outcomeSlot - 1;
    while (filled < 2 && before >= 1) {
        if (get_property("pitchNum" + before) == "") {
            set_property("pitchNum" + before, pitchType);
            filled += 1;
        }
        before -= 1;
    }
    if (filled < 2)
        abort("Not enough open slots to fill prereqs for outcome at slot " + outcomeSlot);
}
boolean canBaseballBanish(int p){
    if (get_property("pitchNum9") == "")
        return false;
    for x from 8 to 6 {
        if (get_property("pitchNum" + x) != "" || x == p)
            return true;
    }
    return false;
}
void baseballD() {
    string [int] lineup = split_string(get_property("baseballTeam"), ",");
    int players;
    foreach num in lineup { players = num + 1; }
    if (players != 9) return;

    try {
        int YRPitchNum;
        int FKPitchNum;
        int BanishPitchNum;

        // Scan 9→3, take the latest slot for each outcome type
        for x from 9 to 3 {
            if (YRPitchNum == 0 && $strings[745,838,775,773,765,768,762,763] contains lineup[x-1]) {
                YRPitchNum = x;
                set_property("pitchNum" + x, "1");
            }
            if (FKPitchNum == 0 && $strings[2499] contains lineup[x-1]) {
                FKPitchNum = x;
                set_property("pitchNum" + x, "3");
            }
            // Banish (third pitch) only activates if slot 9 is already claimed by another outcome
            if (BanishPitchNum == 0 && $strings[764] contains lineup[x-1]
                && canBaseballBanish(x)) {
                BanishPitchNum = x;
                set_property("pitchNum" + x, "2");
            }
        }

        if (YRPitchNum == 0 && FKPitchNum == 0) {
            print("No yellow ray or free kill pitchers in lineup, skipping.", "red");
            return;
        }

        // Assigning other pitches
        int [int] pitchOrder   = {1: YRPitchNum, 2: BanishPitchNum, 3: FKPitchNum};
        string [int] pitchChoice = {1: "1", 2: "2",        3: "3"};

        //Ordering pitches from latest to earliest
        for i from 1 to 3 {
            for j from 1 to (3 - i) {
                if (pitchOrder[j] < pitchOrder[j+1]) {
                    int tmpS = pitchOrder[j];   pitchOrder[j]   = pitchOrder[j+1]; pitchOrder[j+1]   = tmpS;
                    string tmpP = pitchChoice[j]; pitchChoice[j] = pitchChoice[j+1]; pitchChoice[j+1] = tmpP;
                }
            }
        }

        foreach i in pitchOrder {
            if (pitchOrder[i] > 0)
                fillPrereqs(pitchOrder[i], pitchChoice[i]);
        }

        visit_url("inventory.php?pwd&action=pball&pwd=" + my_hash() + "&action=pball", false);
        for x from 1 to 9 {
            string pitch = get_property("pitchNum" + x);
            run_choice(pitch == "" ? 4 : to_int(pitch));
        }
        run_choice(6);

    } finally {
        for x from 1 to 9 {
            set_property("pitchNum" + x, "");
        }
    }
}

// ─── SEPT-EMBER CENSER ────────────────────────────────────────────────────────
// Claim the day's embers, then spend them all on Septapus summoning charms
// for the CCS to throw at the shadow slab.
void censer() {
    if (!have_item($item[Sept-Ember Censer]))
        return;
    if (get_property("_septEmberBalanceChecked") == "false")
        visit_url("shop.php?whichshop=september");
    int wanted = 3 - item_amount($item[Septapus summoning charm]);
    int afford = to_int(get_property("availableSeptEmbers")) / 2;
    if (afford < wanted)
        wanted = afford;
    if (wanted > 0)
        buy($coinmaster[Sept-Ember Censer], wanted, $item[Septapus summoning charm]);
}

// ─── RUN-START CHECKLISTS ─────────────────────────────────────────────────────
// Logged once at initialization: every supported IOTM and every pull the
// route may ask for, one per line -- blue check for present, red cross for
// absent. Purely informational; every use in the script is ownership-guarded
// regardless.
void iotmChecklist() {
    boolean [item] iotmItems = $items[monodent of the sea,
        The Eternity Codpiece,
        closed-circuit pay phone, 2002 Mr. Store Catalog, cursed monkey's paw,
        august scepter, Fourth of May Cosplay Saber, Peridot of Peril,
        blood cubic zirconia, baseball diamond, Heartstone, backup camera,
        Jurassic Parka, spring shoes, Everfull Dart Holster, Mayam Calendar,
        Leprecondo, Cincho de Mayo, McHugeLarge duffel bag,
        Apriling band helmet, April Shower Thoughts shield, bat wings,
        server room key, Time-Spinner, January's Garbage Tote, Powerful Glove,
        combat lover's locket, Lil' Doctor&trade; bag, mumming trunk,
        Kremlin's Greatest Briefcase, Cargo Cultist Shorts,
        Eight Days a Week Pill Keeper, Sept-Ember Censer, vampyric cloake,
        Unwrapped knock-off retro superhero cape, roman candelabra,
        miniature crystal ball, latte lovers member's mug, V for Vivala mask,
        designer sweatpants, tearaway pants, autumn-aton, cosmic bowling ball];
    boolean [skill] iotmSkills = $skills[Just the Facts, Map the Monsters,
        Macrometeorite, Feel Nostalgic];
    boolean [familiar] iotmFamiliars = $familiars[Grouper Groupie,
        Red-Nosed Snapper, Jill-of-All-Trades, Chest Mimic, Patriotic Eagle,
        Sword of S Words, Peace Turkey, Disgeist, Jumpsuited Hound Dog,
        Glover, Foul Ball, Space Jellyfish, Pocket Professor,
        Tiny Plastic Santa Claus Skeleton];

    print("IOTM check — supported IOTMs:");
    int owned;
    int total;
    foreach it in iotmItems {
        total += 1;
        if (have_item(it)) { owned += 1; print("✓ " + it, "blue"); }
        else print("✗ " + it, "red");
    }
    foreach sk in iotmSkills {
        total += 1;
        // have_skill() can flicker at initialization; the owned guide is accepted as a second signal for Macrometeorite.
        boolean has = have_skill(sk)
            || (sk == $skill[Macrometeorite] && have_item($item[Pocket Meteor Guide]));
        if (has) { owned += 1; print("✓ " + sk, "blue"); }
        else print("✗ " + sk, "red");
    }
    foreach fam in iotmFamiliars {
        total += 1;
        if (have_familiar(fam)) { owned += 1; print("✓ " + fam, "blue"); }
        else print("✗ " + fam, "red");
    }
    total += 1;
    if (get_workshed() != $item[none]
        || have_item($item[Asdon Martin keyfob (on ring)])
        || have_item($item[model train set])
        || have_item($item[portable Mayo Clinic])
        || have_item($item[TakerSpace letter of Marque])) {
        owned += 1; print("✓ a workshed", "blue");
    } else
        print("✗ a workshed", "red");
    total += 1;
    if (get_campground() contains $item[Source terminal]) {
        owned += 1; print("✓ Source Terminal", "blue");
    } else
        print("✗ Source Terminal", "red");
    print("IOTM check: " + owned + " of " + total + " supported IOTMs owned.");
}

// Permable skills the route leans on. A skill that stops working the moment
// the IOTM granting it is gone belongs to iotmChecklist(); these survive a
// perm, so they are worth their own list. Informational -- nothing aborts.
record skillNeed {
    int tier;        // 2 required, 1 big turn saver, 0 optional
    string why;
};

skillNeed [skill] routeSkills = {
    // Required -- the run cannot finish without these.
    $skill[Saucegeyser]:            new skillNeed(2, "Kills most of what you fight. Without this or Saucestorm the run stops."),
    $skill[Cannelloni Cocoon]:      new skillNeed(2, "In-run healing."),
    $skill[Empathy of the Newt]:    new skillNeed(2, "Cast before fighting Shub-Jigguwatt."),
    $skill[Deep Dark Visions]:      new skillNeed(2, "The only way to learn the third dreadscroll answer."),

    // Big turn savers.
    $skill[Steely-Eyed Squint]:     new skillNeed(1, "A big once-a-day item drop boost, used to force the drops the run needs."),
    $skill[Unaccompanied Miner]:    new skillNeed(1, "Five free trips into the mine each day, so you need not pull a lodestone for the teflon ore."),
    $skill[Transcendent Olfaction]: new skillNeed(1, "Makes the Neptune flytrap, giant squid and Mer-kin tippler turn up far more often."),
    $skill[Holiday Multitasking]:   new skillNeed(1, "Three crafts a day that cost no adventure."),
    $skill[Tongue of the Walrus]:   new skillNeed(1, "Clears Beaten Up without spending turns resting."),
    $skill[Overclock(10)]:          new skillNeed(1, "Your first ten CyberRealm fights each day are free; used for the Mom quest and to recharge the eagle screech."),
    $skill[Garbage Nova]:           new skillNeed(1, "Extra damage against the school of many. Without it that fight just takes longer."),

    // Optional -- the run copes without any of these.
    $skill[Saucestorm]:             new skillNeed(0, "Backup finisher if you have no Saucegeyser. You need one of the two."),
    $skill[Snokebomb]:              new skillNeed(0, "Banishes a monster you would rather not fight."),
    $skill[Shattering Punch]:       new skillNeed(0, "Kills a monster for free, saving a turn."),
    $skill[Gingerbread Mob Hit]:    new skillNeed(0, "Kills a monster for free, saving a turn."),
    $skill[Perpetrate Mild Evil]:   new skillNeed(0, "Extra damage against the shadow slab."),
    $skill[Raise Backup Dancer]:    new skillNeed(0, "Extra damage in the Naughty Sorceress fight."),
    $skill[Summon Kokomo Resort Pass]: new skillNeed(0, "A free daily summon, picked up during daily setup."),
    $skill[The Ode to Booze]:       new skillNeed(0, "More adventures from every drink."),
    $skill[Ambidextrous Funkslinging]: new skillNeed(0, "Throws two potions at once, halving the fights spent identifying the murky potions."),
    $skill[Double-Fisted Skull Smashing]: new skillNeed(0, "Lets you wield a weapon in each hand, for better equipment."),
    $skill[Gallapagosian Mating Call]: new skillNeed(0, "Another way to make a monster reappear, and the only one that works on the black crayon golem."),
    $skill[Stuffed Mortar Shell]:   new skillNeed(0, "Extra damage while finishing fights without Saucegeyser."),
    $skill[Bind Spice Ghost]:       new skillNeed(0, "Pastamancer thrall for a little extra damage. Any one of the three is enough."),
    $skill[Bind Vermincelli]:       new skillNeed(0, "Pastamancer thrall for a little extra damage. Any one of the three is enough."),
    $skill[Bind Angel Hair Wisp]:   new skillNeed(0, "Pastamancer thrall for a little extra damage. Any one of the three is enough."),

    // Buffs the script puts up before the zones that need them.
    $skill[Fat Leon's Phat Loot Lyric]: new skillNeed(0, "Cast while the run is hunting a specific item drop."),
    $skill[The Ballad of Richie Thingfinder]: new skillNeed(0, "Cast while the run is hunting a specific item drop."),
    $skill[Singer's Faithful Ocelot]: new skillNeed(0, "Cast while the run is hunting a specific item drop."),
    $skill[Leash of Linguini]:      new skillNeed(0, "Cast while the run is hunting a specific item drop."),
    $skill[Who's Going to Pay This Drunken Sailor?]: new skillNeed(0, "Cast while the run is hunting a specific item drop."),
    $skill[Sauce Contemplation]:    new skillNeed(0, "Cast while the run is hunting a specific item drop."),
    $skill[Donho's Bubbly Ballad]:  new skillNeed(0, "Cast while the run is hunting a specific item drop."),
    $skill[The Sonata of Sneakiness]: new skillNeed(0, "Fewer combats, so the noncombats the run wants arrive sooner."),
    $skill[Hide From Seekers]:      new skillNeed(0, "Fewer combats, so the noncombats the run wants arrive sooner."),
    $skill[Smooth Movement]:        new skillNeed(0, "Fewer combats, so the noncombats the run wants arrive sooner."),
    $skill[Carlweather's Cantata of Confrontation]: new skillNeed(0, "More combats, for the zones the run needs to fight through."),
    $skill[Musk of the Moose]:      new skillNeed(0, "More combats, for the zones the run needs to fight through."),
    $skill[Attract Snakes]:         new skillNeed(0, "More combats, for the zones the run needs to fight through."),
    $skill[Astral Shell]:           new skillNeed(0, "Elemental resistance for the underwater boss fights."),
    $skill[Elemental Saucesphere]:  new skillNeed(0, "Elemental resistance for the underwater boss fights."),
    $skill[Scarysauce]:             new skillNeed(0, "Elemental resistance for the underwater boss fights."),
    $skill[Carol of the Hells]:     new skillNeed(0, "Buff for the Mer-kin Colosseum fights."),
    $skill[Elron's Explosive Etude]: new skillNeed(0, "Buff for the Mer-kin Colosseum fights."),
    $skill[Get Big]:                new skillNeed(0, "Buff for the Mer-kin Colosseum fights."),
    $skill[The Magical Mojomuscular Melody]: new skillNeed(0, "Buff for the Mer-kin Colosseum fights."),
    $skill[Manicotti Meditation]:   new skillNeed(0, "Buff for the Mer-kin Colosseum fights."),
    $skill[Moxie of the Mariachi]:  new skillNeed(0, "Buff for the Mer-kin Colosseum fights."),
};


// A skill you hold only because of your current class is gone next ascension,
// so an owned-but-unpermed skill is flagged. get_permed_skills() is empty
// until a charsheet parse fills it, and an empty map suppresses the note
// rather than marking everything unpermed.
void printSkillTier(int tier, string label) {
    boolean [skill] permed = get_permed_skills();
    print("Skill check — " + label + ":");
    foreach sk in routeSkills {
        if (routeSkills[sk].tier != tier)
            continue;
        if (!have_skill(sk))
            print("✗ " + sk + " — " + routeSkills[sk].why, "red");
        else if (count(permed) > 0 && !(permed contains sk))
            print("✓ " + sk + " (not permed) — " + routeSkills[sk].why, "blue");
        else
            print("✓ " + sk + " — " + routeSkills[sk].why, "blue");
    }
}

void skillChecklist() {
    int owned;
    int total;
    int missingRequired;
    foreach sk in routeSkills {
        total += 1;
        if (have_skill(sk))
            owned += 1;
        else if (routeSkills[sk].tier == 2)
            missingRequired += 1;
    }
    printSkillTier(2, "required");
    printSkillTier(1, "big turn savers");
    printSkillTier(0, "optional");
    print("Skill check: " + owned + " of " + total + " permable skills owned"
        + (missingRequired > 0 ? ", " + missingRequired + " REQUIRED missing" : "") + ".");
}

void pullChecklist() {
    boolean [item] pulls = $items[Mer-kin sneakmask, sea lasso, shark jumper,
        scale-mail underwear, Congressional Medal of Insanity,
        Flash Liquidizer Ultra Dousing Accessory, Mer-kin digpick, lodestone,
        comb jelly, Elf Guard SCUBA tank, rusty rivet, sea cowbell,
        Mer-kin prayerbeads, Mer-kin healscroll, Mer-kin killscroll,
        Mer-kin worktea, Mer-kin knucklebone, Mer-kin cheatsheet,
        Mer-kin hallpass, Mer-kin hidepaint, pro skateboard, software glitch,
        pulled yellow taffy, stuffed yam stinkbomb, waffle, skate blade,
        null-day exploit, New Age healing crystal, soggy used band-aid,
        damp old wallet, fish sauce, Aldebaran sardines,
        pie man was not meant to eat, Handheld Allied radio, Clara's bell,
        stench jelly, peppermint parasol, ink bladder, Mer-kin pinkslip,
        Louder Than Bomb, anchor bomb];

    print("Pull check — Hagnk's stock:");
    foreach it in pulls {
        // Catalog credits create these in-run; only worth stocking without it.
        if (have_item($item[2002 Mr. Store Catalog])
            && $items[pro skateboard, software glitch] contains it)
            continue;
        // Never auto-bought (see the pull loop) -- flag it as a nice-to-have.
        if (it == $item[Congressional Medal of Insanity] && storage_amount(it) == 0 && get_inventory()[it] == 0) {
            print("✗ " + it + " — Currently not optional, just too expensive to have the script buy on its own", "red");
            continue;
        }
        if (storage_amount(it) > 0 || get_inventory()[it] > 0)
            print("✓ " + it, "blue");
        else if (is_tradeable(it))
            print("✗ " + it + " — will be mall-bought if the route needs it", "red");
        else
            print("✗ " + it + " — NOT mall-buyable, acquire before it's needed", "red");
    }
}
