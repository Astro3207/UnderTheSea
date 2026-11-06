# UnderTheSea
11,037 Leagues Under the Sea loop.

`git checkout Astro3207/UnderTheSea`

## Hard requirements

- **KoLmafia r29057 or newer.**
- **`autoSatisfyWithNPCs = true`** in mafia's preferences.
- **Aftercore mode (running the sea outside the path):** The script prompts for which boss to fight.
- **A Monodent of the Sea.**
- **The Eternity Codpiece**, loaded with unblemished pearls before
  ascending. 
- **A Congressional Medal of Insanity** 
- **3 Familiars** Grouper Groupie, Glover, Foul Ball

## Options

| Command | What it does |
|---|---|
| `UnderTheSea` | Runs the full loop. |
| `UnderTheSea sim` | Prints which IOTMs, skills, familiars and pulls you have. Spends nothing. |
| `UnderTheSea postloop` | Runs only the postloop steps, each gated by its own preference. |

Preferences, set once in the gCLI; all default to off:

| Preference | What it does |
|---|---|
| `set uts_godRunGuard = true` | At 17 or fewer turns with the dreadscroll 7 clue unknown, eats a sushi if you hold worktea, otherwise aborts so you can. For record attempts. |
| `set uts_postloopCommand = <command>` | CLI command to run after the loop, such as a farming script. |
| `set uts_usePilsners = true` | Drinks your astral pilsners after the run. Use this or `garbo_usePilsners`, not both. |
| `set uts_postLoopRunOutEagleBanish = true` | **Experimental.** Walks pearl zones until the Patriotic Screech recharges (up to 40 fights), then re-aims it at smut orcs, since a construct banish breaks ⭐garbo⭐. |
| `set uts_postLoopFarmPearls = true` | Farms today's profitable unblemished pearls with [pearlo](https://github.com/xn/pearlo), drinking your astral pilsners first. Skipped if pearlo is missing. An abort in pearlo stops UnderTheSea too. |
| `set uts_postLoopCloverFishy = true` | Gets 20 more turns of Fishy from a Lucky! adventure when it runs out. Needs the screech or pearl farm preference. |
| `set uts_postLoopPrepCodpiece = true` | Loads The Eternity Codpiece with five unblemished pearls for your next ascension, buying any you're short of if `autoSatisfyWithMall` and `autoBuyPriceLimit` allow. Aborts if it can't reach five. |
| `set uts_pearloArgs = <args>` | Extra arguments for the `pearlo` call, such as `airmode=gear`. See `pearlo help`. |
| `set uts_acornOutpost = true` | Uses the legendary acorndion in the Mer-kin Outpost to add sea cows and, when it can, banish the burglar and raider. |
| `set uts_saveSeadentWave = true` | Never floods the Shadow Rift, saving Summon a Wave for later. Costs extra turns. |

The postloop steps run in this order: pilsners, codpiece, screech, pearl farm, codpiece top-up, `uts_postloopCommand`. Most empty Hagnk's first.

## High shiny, low shiny

The script sorts your account into a resource tier and routes accordingly:

- **Low shiny:** you own none of the 2002 Mr. Store Catalog, cursed monkey's
  paw or august scepter. The script assumes pulls are precious and farms
  drops it would otherwise pull or wish for, and leans harder on the
  Congressional Medal of Insanity.
- **High shiny:** an Asdon Martin workshed plus
  `garbo_valueOfFreeFight > valueOfAdventure`: your free fights are worth
  more to aftercore meat farming than to the run, so the script *conserves*
  free kills, copies and maps for after the loop instead of spending them
  in-run, taking a slightly longer run for more profitable days.
- **Neither** (mid shiny): every daily resource gets spent on making the run
  as short as possible.

## Things to prepare BEFORE ascending

- Load up the codpiece with unblemished pearls
- Be in a clan with a stocked photobooth. The script claims the three sheriff
  props daily, and does without them and the booth's buffs if it can't.
- Have all of the underwater maps done
- Have a damp old wallet (not required but saves a turn)
- Have black crayon golem and unholy diver in the combat lover's locket
  (optional: the summon ladder uses fax, locket, mimic egg or genie,
  whichever is available otherwise)
- Familiars: Grouper groupie, glover, foul ball
- For a competitive turn count: push the noncombat A Mer-kin Graffiti out of
  the noncombat queue

## Important IOTMs

| IOTM | Why it matters |
|---|---|
| closed-circuit pay phone | With Monodent, free shadow-rift fights allow free sea lasso training. |
| CyberRealm keycode | Free Mom quest. |
| cursed monkey's paw | Free sea lassos and sea cowbells for the seahorse taming instead of farming them. |
| Book of Facts | Just the Facts wishes and Monster Habitats copy chains cut the adventures needed to find Mom in The Caliginous Abyss |
| patriotic eagle (hatchling) | Patriotic Screech in combation with Cyberrealm |

Useful but relatively strict on item requirement Ploop alternative for this script: https://github.com/UtoTurtMcGurt/LoopTheSea

If you are having the issue of it getting caught on the initial NC, there is nothing that can be done right now. You have to hit it manually or add ``visit_url("main.php"); run_choice(1);`` to the end of your preascension script.


Useful skills and iotms and stuff: https://docs.google.com/spreadsheets/d/1bAZj17ZUb9cd4V1Nnda8--SiTlJvGQZWJvYz5CUA8G4/edit?usp=sharing

## Items to add support for

- Folder Holder
