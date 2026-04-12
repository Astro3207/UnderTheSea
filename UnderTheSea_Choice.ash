import iotm;
void main(int whichchoice, string page) {
    switch (whichchoice){
        case 299:
            run_choice(1);
            break;
        case 303:
            run_choice(1);
            break;
        case 313:
            if (!contains_text(get_property("stashboxChecked"),"1")){
                run_choice(1);
                set_property("stashboxChecked","1");
                if (item_amount($item[mer-kin stashbox]) > 0)
                    set_property("stashboxFound", "1");
            } else if (!contains_text(get_property("stashboxChecked"),"3")){
                run_choice(3);
                set_property("stashboxChecked","1,3");
                if (item_amount($item[mer-kin stashbox]) > 0)
                    set_property("stashboxFound", "3");
            } else if (!contains_text(get_property("stashboxChecked"),"2")){
                run_choice(2);
                set_property("stashboxChecked","1,2,3");
                if (item_amount($item[mer-kin stashbox]) > 0)
                    set_property("stashboxFound", "2");
            }
            break;
        case 314:
            if (!contains_text(get_property("stashboxChecked"),"1")){
                run_choice(1);
                set_property("stashboxChecked","1");
                if (item_amount($item[mer-kin stashbox]) > 0)
                    set_property("stashboxFound", "1");
            } else if (!contains_text(get_property("stashboxChecked"),"2")){
                run_choice(2);
                set_property("stashboxChecked","1,2");
                if (item_amount($item[mer-kin stashbox]) > 0)
                    set_property("stashboxFound", "2");
            } else {
                run_choice(3);
                if (item_amount($item[mer-kin stashbox]) > 0)
                    set_property("stashboxFound", "3");
            }
            break;
        case 315:
            if (!contains_text(get_property("stashboxChecked"),"3")){
                run_choice(3);
                set_property("stashboxChecked","3");
                if (item_amount($item[mer-kin stashbox]) > 0)
                    set_property("stashboxFound", "3");
            } else if (!contains_text(get_property("stashboxChecked"),"1")){
                run_choice(1);
                set_property("stashboxChecked","1,3");
                if (item_amount($item[mer-kin stashbox]) > 0)
                    set_property("stashboxFound", "1");
            } else {
                run_choice(2);
                if (item_amount($item[mer-kin stashbox]) > 0)
                    set_property("stashboxFound", "2");
            }
            break;
        case 399:
            run_choice(1);
            break;
        case 400:
            run_choice(1);
            break;
        case 401:
            if (have_equipped($item[mer-kin bunwig])){
                run_choice(2);
            } else {
                run_choice(1);
            }
            break;
        case 403:
            run_choice(1);
            break;
        case 701:
            run_choice(1);
            break;
        case 703:
            int Scroll7;
            if (get_property("dreadScroll7") != 0){
                Scroll7 = to_int(get_property("dreadScroll7"));
            } else if (!contains_text(get_property("dreadScrollGuesses"),get_property("dreadScroll1")+""+get_property("dreadScroll2")+""+get_property("dreadScroll3")+""+get_property("dreadScroll4")+""+get_property("dreadScroll5")+""+get_property("dreadScroll6")+"4"+get_property("dreadScroll8"))){
                Scroll7 = 4;
            } else if (!contains_text(get_property("dreadScrollGuesses"),get_property("dreadScroll1")+""+get_property("dreadScroll2")+""+get_property("dreadScroll3")+""+get_property("dreadScroll4")+""+get_property("dreadScroll5")+""+get_property("dreadScroll6")+"3"+get_property("dreadScroll8"))){
                Scroll7 = 3;
            } else if (!contains_text(get_property("dreadScrollGuesses"),get_property("dreadScroll1")+""+get_property("dreadScroll2")+""+get_property("dreadScroll3")+""+get_property("dreadScroll4")+""+get_property("dreadScroll5")+""+get_property("dreadScroll6")+"2"+get_property("dreadScroll8"))){
                Scroll7 = 2;
            } else {
                Scroll7 = 1;
            }
            run_choice(1,"pro1="+get_property("dreadScroll1")+"&pro2="+get_property("dreadScroll2")+"&pro3="+get_property("dreadScroll3")+"&pro4="+get_property("dreadScroll4")+"&pro5="+get_property("dreadScroll5")+"&pro6="+get_property("dreadScroll6")+"&pro7="+Scroll7+"&pro8="+get_property("dreadScroll8"));
            waitq(3);
            if (have_effect($effect[Deep-Tainted Mind]) == 0){
                set_property("dreadScroll7",Scroll7);
            }
            break;
        case 704:
            string [int] choices1 = available_choice_options();
            foreach num, choice_text in choices1 {
                set_property("cardChoice"+num,choice_text);
            }
            int dread = to_int(to_boolean(to_int(get_property("dreadScroll1")))) + to_int(to_boolean(to_int(get_property("dreadScroll6")))) + to_int(to_boolean(to_int(get_property("dreadScroll8")))) + 1;
            run_choice(dread);
            break;
        case 705:
            run_choice(4);
            break;
        case 1475:
            run_choice(1);
            break;
        case 1564:
            run_choice(1);
            break;
        case 1565:
            run_choice(1);
            break;
        case 1473:
            run_choice(1);
            break;
        case 1494:
            run_choice(1);
            break;
        case 1497:
            if (have_effect($effect[Shadow Waters]) == 0){
                run_choice(2);
            } else {
                run_choice(2);
            }
            break;
        case 1500:
            if (have_effect($effect[shadow waters]) == 0){
                run_choice(2);
            } else {
                run_choice(3);
            }
            break;
        case 1556:
            run_choice(1);
            break;
        case 1566:
            run_choice(1);
            break;
        case 1557:
            switch (my_location()){
                case $location[An Octopus's Garden]:
                    run_choice(1,"bandersnatch=740");
                    break;
                case $location[The Coral Corral]:
                    run_choice(1,"bandersnatch=772");
                    run_choice(2);
                    break;
                case $location[The Marinara Trench]:
                    run_choice(1,"bandersnatch=763");
                    break;
                case $location[The Dive Bar]:
                    run_choice(1,"bandersnatch=768");
                    break;
                case $location[Cyberzone 1]:
                    run_choice(1,"bandersnatch=2458");
                    break;
                case $location[the caliginous abyss]:
                    run_choice(1,"bandersnatch=1373");
                    break;
                case $location[mer-kin elementary school]:
                    run_choice(1,"bandersnatch=838");
                    break;
            }
            break;
        case 1525:
            string [int] choices = available_choice_options();
            foreach num, choice_text in choices {
                print(`{num}: {choice_text}`);
            }
            foreach perk in $strings[impress,better,targeting,Butt]{
                foreach num, choice_text in choices {
                    if (contains_text(choice_text,perk)){
                        run_choice(num);
                        exit;
                    }
                }
            }
            run_choice(1);
            break;
        case 1562:
            if (get_property("_mobiusStripEncounters") == "1"){
                string [int] choices = available_choice_options();
                foreach num, choice_text in choices {
                    if (contains_text(choice_text,"arch-nemesis")){
                        run_choice(num);
                        exit;
                    }
                }
            }
            if (get_property("_mobiusStripEncounters") == "2"){
                string [int] choices = available_choice_options();
                foreach num, choice_text in choices {
                    if (contains_text(choice_text,"trifecta")){
                        run_choice(num);
                        exit;
                    }
                }
            }
            if (get_property("_mobiusStripEncounters") == "3"){
                string [int] choices = available_choice_options();
                foreach num, choice_text in choices {
                    if (contains_text(choice_text,"Go back and write a best-seller")){
                        run_choice(num);
                        exit;
                    }
                }
            }
            if (get_property("_mobiusStripEncounters") == "4"){
                string [int] choices = available_choice_options();
                foreach num, choice_text in choices {
                    if (contains_text(choice_text,"Replace your novel with AI drivel")){
                        run_choice(num);
                        exit;
                    }
                }
            }
            break;
        case 1589:
            if (my_location() == $location[The Marinara Trench]){
                abort();
            } else {
                run_choice(1,"victim=852");
            }
            break;
    }
}
