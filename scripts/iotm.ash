int uniInt, uniAdv, pearlsDoneToday;
string clan = get_clan_name();
int estimatedTurns;
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
boolean [monster] haveLocketMonster = get_locket_monsters();
boolean have_item(item it){
    boolean bool;
    if (item_amount(it) > 0)
        bool = true;
    if (have_equipped(it))
        bool = true;
    if (storage_amount(it) > 0)
        bool = true;
    if (closet_amount(it) > 0)
        bool = true;
    return bool;
}
int chamoixAmount(){
    string chamoix = visit_url("clan_slimetube.php?action=bucket");
    int chamois_count = 0;
    matcher chamoix_left = create_matcher("There are (\\d+) chamoi", chamoix);
    if (chamoix_left.find()){
        chamois_count += to_int(chamoix_left.group(1));
    }
    return chamois_count;
}
string LastAdvTxt() {
    string lastlog = session_logs(1)[0];
    int nowmark = max(last_index_of(lastlog,"["+my_turncount()+"]"),last_index_of(lastlog,"["+(my_turncount()+1)+"]"));
    return substring(lastlog,nowmark);
}
void NCforce(){
    if (get_property("noncombatForcerActive") == "false"){
        if (to_int(get_property("_aprilBandTubaUses")) < 3){
            cli_execute("aprilband play tuba");
        } else {
            while (to_int(get_property("_cinchUsed")) > 40 && to_int(get_property("timesRested")) < total_free_rests()){
                cli_execute("unequip hat; equip apriling band helmet;camp rest free");
            }
            if (to_int(get_property("_cinchUsed")) <= 40){
                equip($slot[acc3],$item[cincho de mayo]);
                use_skill($skill[Cincho: Fiesta Exit]);
            }
        }
    }
}
void candy(string action){
    int houseToVisit = index_of(get_property("_trickOrTreatBlock"),"D");
    visit_url("place.php?whichplace=town&action=town_trickortreat");
    visit_url("choice.php?whichchoice=804&option=3&whichhouse=" + houseToVisit);
    run_combat();
}
void cyberzone(){
    while (to_int(get_property("_cyberFreeFights")) < 10){
        maximize("item drop",false);
        if (contains_text(get_property("banishedPhyla"),"construct")){
            if (get_property("_cyberZone1Hacker") == ""){
                adv1($location[cyberzone 1],0,"");
                set_property("_cyberZone1Hacker",last_monster());
                continue;
            } else if (get_property("_cyberZone2Hacker") == "" && get_property("_cyberZone1Hacker") != "greyhat hacker"){
                adv1($location[cyberzone 2],0,"");
                set_property("_cyberZone2Hacker",last_monster());
                continue;
            } else if (get_property("_cyberZone3Hacker") == "" && get_property("_cyberZone1Hacker") != "greyhat hacker" && get_property("_cyberZone2Hacker") != "greyhat hacker"){
                adv1($location[cyberzone 3],0,"");
                set_property("_cyberZone3Hacker",last_monster());
                continue;
            }
            foreach mon in $monsters[greyhat hacker,bluehat hacker,greenhat hacker,redhat hacker,purplehat hacker]{
                if (mon == to_monster(get_property("_cyberZone1Hacker"))){
                    adv1($location[cyberzone 1],0,"");
                    break;
                } else if (mon == to_monster(get_property("_cyberZone2Hacker"))){
                    adv1($location[cyberzone 2],0,"");
                    break;
                } else if (mon == to_monster(get_property("_cyberZone3Hacker"))){
                    adv1($location[cyberzone 3],0,"");
                    break;
                }
            }
        } else {
            adv1($location[cyberzone 1],0,"");
        }
    }
}
record ban {
	string pref;
	skill banSkill;
};
ban[item] banMap = {
    $item[spring shoes]:    new ban("Spring Kick",  $skill[spring kick]),
    $item[monodent of the sea]:    new ban("Sea \\*dent",  $skill[Sea *dent: Throw a Lightning Bolt]),
    $item[Heartstone]:    new ban("Heartstone %banish",  $skill[Heartstone: %banish]),
    $item[none]:    new ban("snokebomb", $skill[snokebomb]),
};
location[int] monster_found_in(monster m) {
  location[int] output;
  foreach o in $locations[]
    if (o.get_location_monsters() contains m)
      output[count(output)] = o;
  return output;
}
monster banished(string banisher){
    monster mon;
    matcher monster_matcher = create_matcher (":([A-Za-z'-]+(?: [A-Za-z'-]+){0,3}):"+banisher,get_property("banishedMonsters"));
    if (monster_matcher.find()){
        mon += to_monster(monster_matcher.group(1));
    }
    return mon;
}
boolean banishUsedAtYourLocation(string banisher){
    boolean bool;
    foreach num in monster_found_in(banished(banisher)){
        if (monster_found_in(banished(banisher))[num] == my_location()){
            bool = true;
        }
    }
    return bool;
}
item banishGear(location loc){
    item it;
    foreach ite in $items[spring shoes,monodent of the sea,Heartstone]{
        if (appearance_rates(loc)[banished(banMap[ite].pref)] > 0){
            it = ite;
            break;
        }
    }
    set_property(to_string(to_slot(it))+"Override", ", equip "+it);
    return it;
}
skill combatBan(){
    skill sk;
    foreach ite in $items[spring shoes,monodent of the sea,Heartstone]{
        if (have_equipped(ite)){
            if (appearance_rates(my_location())[banished(banMap[ite].pref)] > 0){
                continue;
            } else {
                sk = banMap[ite].banSkill;
            }
        }
    }
    return sk;
}
boolean bullseyeReady() {
    boolean bool;
    if ((contains_text(get_property("everfullDartPerks"),"You are less impressed by bullseyes") && contains_text(get_property("everfullDartPerks"),"Bullseyes do not impress you much")) || count_substring(get_property("everfullDartPerks"),"Bullseyes do not impress you much") >= 2 || count_substring(get_property("everfullDartPerks"),"You are less impressed by bullseyes") >= 2){
        bool = true;
    } else {
        bool = false;
    }
    if (my_adventures() < 20)
        bool = true;
    return bool;
}
int BCZcost(string BCZskill){ 
    int cast = to_int(get_property("_bcz" + BCZskill));
    if (cast == 12)
        return 420000;
    else if (cast > 12)
        cast -= 1;
    int castMathFloor = floor(cast/3);
    int castMathModulo = (cast % 3);
    int substatBase = 0;
    switch(castMathModulo)
    {
        case 0:
            substatBase = 11;
            break;
        case 1:
            substatBase = 23;
            break;
        case 2:
            substatBase = 37;
            break;
    }
    int cost = substatBase * 10 ** ((cast < 12 || (cast > 12 && castMathModulo == 0)) ? castMathFloor : castMathFloor + 1);
    return cost; //11, 23, 37, 110, 230, 370, etc. 13th cast follows a different pattern but we will never get there
}
void trainset(){
    int pos = to_int(get_property("trainsetPosition"))%8;
    int [int] trainset = {
        (pos)%8:8, //next station
        (pos + 1)%8:1,
        (pos + 2)%8:15,
        (pos + 3)%8:20,
        (pos + 4)%8:3,
        (pos + 5)%8:7,
        (pos + 6)%8:2,
        (pos + 7)%8:19
    };
    visit_url("choice.php?forceoption=0?whichchoice=1485&option=1&slot%5B0%5D=" + trainset[0] + "&slot%5B1%5D=" + trainset[1] + "&slot%5B2%5D=" + trainset[2] + "&slot%5B3%5D=" + trainset[3] + "&slot%5B4%5D=" + trainset[4] + "&slot%5B5%5D=" + trainset[5] + "&slot%5B6%5D=" + trainset[6] + "&slot%5B7%5D=" + trainset[7]);
}
void codpiece(string input){
    string[int] slots = split_string(input, ",");
    visit_url("inventory.php?action=docodpiece");
    if (input == "none"){
        visit_url("choice.php?whichchoice=1588&option=2&which=5");
        visit_url("choice.php?whichchoice=1588&option=2&which=4");
        visit_url("choice.php?whichchoice=1588&option=2&which=3");
        visit_url("choice.php?whichchoice=1588&option=2&which=2");
        visit_url("choice.php?whichchoice=1588&option=2&which=1");
    } else {
        foreach num in slots{
            int a = num+1;
            visit_url("choice.php?whichchoice=1588&option=1&which="+a+"&iid="+to_int(to_item(slots[num])));
        }
        foreach num in slots{
            int a = num+1;
            if (!contains_text(visit_url("inventory.php?action=docodpiece"),to_item(slots[num]) + " mounted in slot #" + a))
                abort("Codpiece slot incorrect");
        }
    }
    cli_execute("refresh all");
}
string[int] lepRoomToNum = {
    1:"buckets of concrete",
    2:"thrift store oil painting",
    3:"boxes of old comic books",
    4:"second-hand hot plate",
    5:"beer cooler",
    6:"free mattress",
    7:"gigantic chess set",
    8:"UltraDance karaoke machine",
    9:"cupcake treadmill",
    10:"beer pong table",
    11:"padded weight bench",
    12:"internet-connected laptop",
    13:"sous vide laboratory",
    14:"programmable blender",
    15:"sensory deprivation tank",
    16:"fruit-smashing robot",
    17:"ManCave™ sports bar set",
    18:"couch and flatscreen",
    19:"kegerator",
    20:"fine upholstered dining table set",
    21:"whiskeybed",
    22:"high-end home workout system",
    23:"complete classics library",
    24:"ultimate retro game console",
    25:"Omnipot",
    26:"fully-stocked wet bar",
    27:"four-poster bed"
};
void leprecondo(string input){
    string[int] rooms = split_string(input, ",");
    int[int] lepRoom;
    int count;
    foreach num in rooms{
        if (to_int(rooms[num]) >= 10 && contains_text(get_property("leprecondoDiscovered"),rooms[num])){
            lepRoom[count] = to_int(rooms[num]);
            count += 1;
        }
        if (to_int(rooms[num]) < 10 && contains_text(get_property("leprecondoDiscovered"),","+rooms[num] +",")){
            lepRoom[count] = to_int(rooms[num]);
            count += 1;
        }
    }
    cli_execute ("leprecondo furnish "+ lepRoomToNum[lepRoom[0]] + "," + lepRoomToNum[lepRoom[1]] + ","+ lepRoomToNum[lepRoom[2]] + ","+ lepRoomToNum[lepRoom[3]]);
}
int universe(){
    int [string] sign {
        "Mongoose":1,
        "Wallaby":2,
        "Vole":3,
        "Platypus":4,
        "Opossum":5,
        "Marmot":6,
        "Wombat":7,
        "Blender":8,
        "Packrat":9,
        "Bad Moon":10
    };
    for y from 0 to my_adventures(){
        for x from 1 to 99{
            if (((x+my_ascensions()+sign[my_sign()])*(my_spleen_use()+my_level())+(my_adventures()-y))%100 == 69){
                uniInt = x;
                uniAdv = my_adventures()-y;
                break;
            }
        }
        if (uniInt > 0){
            break;
        }
    }
    return uniAdv;
}
boolean delay(){
    boolean bool;
    if (to_int(get_property("_snokebombUsed")) < 3 )
        bool = true;
    if (have_effect($effect[everything looks green]) == 0 )
        bool = true;
    if (item_amount($item[&quot;I Voted!&quot; sticker]) > 0 && total_turns_played()%11 == 1 && to_int(get_property("_voteFreeFights")) < 3)
        bool = true;
    if (total_turns_played() >= to_int(get_property("clubEmNextWeekMonsterTurn")) + 8 && get_property("clubEmNextWeekMonster") != "")
        bool = true;
    if (total_turns_played() >= to_int(get_property("spookyVHSTapeMonsterTurn")) + 8 && get_property("clubEmNextWeekMonster") != "")
        bool = true;
    return bool;
}
void camo(){
    if (chamoixAmount() < 1 ){
        string current_clan = get_clan_id();
        try{
            visit_url("showclan.php?whichclan=2046992052&action=joinclan&confirm=on");
            if (chamoixAmount() < 10 ){
                abort("low on chamois");
            }
            visit_url( "clan_slimetube.php?action=chamois" );
        } finally {
            visit_url("showclan.php?whichclan="+current_clan+"&action=joinclan&confirm=on");
        }
    } else {
        visit_url( "clan_slimetube.php?action=chamois" );
    }
}
void darts(){
    int n = to_int(get_property("_dartsLeft"));
    while(n > 0 && have_equipped($item[everfull dart holster])){
        if (contains_text(get_property("everfullDartPerks"),"Butt")){
            int butts_int;
            matcher butts_matcher = create_matcher("(\\d+):butt", get_property("_currentDartboard")); 
            if (butts_matcher.find()){
                butts_int = butts_matcher.group(1).to_int();
            } else {
                break;
            }
            use_skill(to_skill(butts_int));
        } else {
            use_skill($skill[Darts: Throw at %part1]);
        }
        n -= 1;
    }
}
string [int] baseballLineup = split_string(get_property("baseballTeam"), ",");

int baseballPlayers(){
    int players;
    foreach num in baseballLineup{
        players = (num+1);
    }
    return players;
}

void baseballD(){
    if (baseballPlayers() == 9){
        visit_url("inventory.php?action=pball",false);
    }
}
void finisher(){
    set_property("script","");
    set_property("subscript","");
    set_property("afterAdventureScript","");
    set_property("choiceAdventureScript","garbo_choice.js");
    set_property("betweenBattleScript","");
    set_property("maxOverride", "");
    set_property("famOverride", "");
    set_property("hatOverride", "");
    set_property("mainOverride", "");
    set_property("offOverride", "");
    set_property("backOverride", "");
    set_property("shirtOverride", "");
    set_property("pantsOverride", "");
    set_property("acc1Override", "");
    set_property("acc2Override", "");
    set_property("acc3Override", "");
}
