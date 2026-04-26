import iotm;
string workshed(){
    string work = visit_url("campground.php?action=workshed");
	string works;
	matcher matcher_shed = create_matcher("You swagger into your workshed and survey your (\\w+)", work); 
	if (matcher_shed.find())
		works += matcher_shed.group(1).to_string();
	return works;
}

if (get_property("_gitUpdated") == "false"){
    cli_execute("git update; stock_market");
}
if (mall_price($item[Frosty\'s frosty mug]) < 350000 && item_amount($item[Frosty\'s frosty mug]) > 0){
    print("Frosty price below acceptable limit, start closeting", "red");
    wait(10);
}
if (mall_price($item[vintage smart drink]) < 100000 || mall_price($item[Emergency margarita]) < 100000){
    print("Buy CS drinks","red");
    print(mall_price($item[vintage smart drink]));
    print(mall_price($item[Emergency margarita]));
    wait(10);
}
if (get_property("_workshedItemUsed") == false && workshed() == "TakerSpace") {
    if (to_int(get_property("takerSpaceGold")) >= 1 && to_int(get_property("takerSpaceMast")) >= 1 && to_int(get_property("takerSpaceAnchor")) >= 3 && to_int(get_property("takerSpaceRum")) >= 1)
        cli_execute("make anchor bomb");
    if (to_int(get_property("takerSpaceSpice")) >= 1 && to_int(get_property("takerSpaceRum")) >= 2)
        cli_execute("make tankard of spiced rum");
    while (to_int(get_property("takerSpaceMast")) >= 2){
        cli_execute("make harpoon");
    }
    while (to_int(get_property("takerSpaceSpice")) >= 1){
        cli_execute("make spices");
    }
	cli_execute ("use model train set");
}
int current_clan = get_clan_id();
visit_url("showclan.php?whichclan=90485&action=joinclan&confirm=on");
cli_execute("breakfast; chips radium; chips wintergreen; chips ennui");
visit_url("clan_rumpus.php?action=click&spot=5&furni=1");
visit_url("showclan.php?whichclan=2047010939&action=joinclan&confirm=on");
cli_execute("breakfast");

if (get_property("_chronerTriggerUsed") == false){
    visit_url("showclan.php?whichclan=2047009940&action=joinclan&confirm=on");
    cli_execute("stash take chroner trigger; use chroner trigger; stash put chroner trigger");
}
visit_url("showclan.php?whichclan=72876&action=joinclan&confirm=on");
use_familiar($familiar[Chest Mimic]);
if (to_int(get_property("_mimicEggsObtained")) < 11){
#    cli_execute ("equip acc1 everfull dart; c2t_megg fight flatusaurus");
 #       use_skill( 11, to_skill(7494) );
  #      set_auto_attack(1);
   #     run_combat();
    #    set_auto_attack(0);
}
cli_execute( "garden pick");
if (get_property("_photoBoothEquipment") == 0){
    cli_execute( "photobooth item Sheriff badge" );
    cli_execute( "photobooth item Sheriff pistol" );
    cli_execute( "photobooth item Sheriff moustache" );
}
if (get_property("_perilsForeseen") == 0){
    visit_url("inventory.php?action=foresee");
	visit_url("choice.php?whichchoice=1558&option=1&who=2463557");
	visit_url("choice.php?whichchoice=1558&option=1&who=1197090");
	visit_url("choice.php?whichchoice=1558&option=1&who=4409");
    visit_url("choice.php?whichchoice=1558&option=1&who=2456712");
}
if (get_property("_alliedRadioDropsUsed") < 3){
    visit_url("inventory.php?action=requestdrop");
    while(get_property("_alliedRadioDropsUsed") < 3){
        visit_url("choice.php?request=radio&whichchoice=1561&option=1");
    }
}
if (get_property("skateParkStatus") == "ice" && pearlsDoneToday < 3){
    //cli_execute("unblemishedPearl.ash");
   // cli_execute("friarTemple.ash");
}
while (to_int(get_property("_unaccompaniedMinerUsed")) < 5){
    cli_execute("acquire miner's helmet; acquire 7-Foot Dwarven mattock; acquire miner's pants");
    cli_execute("outfit mining gear");
    int x_coor = 0;
    int y_coor = 0;
    string itzmine = visit_url("mining.php?intro=1&mine=1");
    matcher mining_spot = create_matcher("Promising Chunk of Wall \\((\\d+),(\\d+)\\)", itzmine);
    if( my_hp() == 0){
        cli_execute("restore HP");
    }
    if (mining_spot.find()){
        x_coor = to_int(mining_spot.group(1));
        y_coor = to_int(mining_spot.group(2));
        int to_mine = (8 * y_coor) + x_coor;
        visit_url("mining.php?mine=1&which="+ to_mine);
    } else {
        visit_url("mining.php?mine=1&reset=1");
    }
}
    if (have_effect($effect[Beaten Up]) > 0){
        cli_execute("cast tongue; cast cannel");
    }
cli_execute("acquire mother's necklace");
visit_url("showclan.php?whichclan="+current_clan+"&action=joinclan&confirm=on");
if (item_amount($item[synthetic dog hair pill]) == 0 || item_amount($item[distention pill]) == 0)
    cli_execute("emergency1fulldrunk");
if (get_property("seaAftercore")=="lllll"){
    cli_execute("use fancy chess set");
    cli_execute("unblemishedpearl");
    cli_execute("nemesis.ash");
    if (item_amount($item[sprinkles]) < 100000){
        cli_execute("gingerbread city");
    }
    //use memory disk alpha;farfuture mall
    if (item_amount($item[FunFunds]) < 5000)
        cli_execute("piraterealm");
    print("cooking");
}
