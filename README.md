# UnderTheSea
11,037 Leagues Under the Sea loop.

`git checkout Astro3207/UnderTheSea`

## Hard requirements

- **KoLmafia r29057 or newer.**
- **`autoSatisfyWithNPCs = true`** in mafia's preferences.
- **A clan with a stocked photobooth** — the script claims the three sheriff
  props daily and aborts if the booth is empty.
- **Aftercore mode (running the sea outside the path):** The script prompts for which boss to fight.
- **A Monodent of the Sea.**
- **The Eternity Codpiece**, loaded with unblemished pearls before
  ascending. 
- **A Congressional Medal of Insanity** 
- **3 Familiars** Grouper Groupie, Glover, Foul Ball

## Options

| Command | What it does |
|---|---|
| `UnderTheSea` | Runs the loop: the full run, from initialization through the sorceress. |
| `UnderTheSea sim` | Checklist only: prints which supported IOTMs, skills and familiars you own and which pulls are stocked in Hagnk's. Nothing is pulled, fought or spent; use it before ascending to build a shopping list. |
| `UnderTheSea postloop` | Runs only the postloop steps — the pearl walk, the codpiece prep, the pilsner drain and `uts_postloopCommand` — and none of the run. Use it to exercise the `uts_postLoop*` preferences on a finished account, where a bare `UnderTheSea` would start an aftercore Sea run instead. Each step still self-gates on its own preference. |

Preferences, set once in the gCLI; all default to off:

| Preference | What it does |
|---|---|
| `set uts_godRunGuard = true` | Abort at ≤17 turns played if the dreadscroll 7 clue is still unknown, so you can eat a sushi for it instead of burning a record attempt. Only worth enabling if you are chasing a top turncount. |
| `set uts_postloopCommand = <command>` | CLI command to run once the loop finishes (e.g. a farming script). Leave empty to skip. |
| `set uts_usePilsners = true` | After the run, drink out your astral pilsners — cracking six-packs as it goes, under Ode to Booze — so the supply turns into adventures for whatever you run next instead of sitting in the bag. Empties Hagnk's first when the supply is sitting there, and runs last, after the screech rundown and the codpiece prep — the pearl walk drinks its own pilsners on demand, so it loses nothing by going first. Leaves out any liver capacity that equipment or the familiar is lending, so the next script's re-dress can't leave you falling-down drunk. It does spend liver: a pilsner is at most 11 adventures, 12 under Ode, for one drunkenness — worse than most aftercore booze — and ⭐garbo⭐ has its own `garbo_usePilsners`, so you want one or the other, not both. |
| `set uts_postLoopRunOutEagleBanish = true` | **Experimental.** After the run finishes, keep adventuring until the patriotic eagle's Patriotic Screech stops banishing the construct phylum, which can make other scripts (⭐garbo⭐) misbehave. Empties Hagnk's first, then burns the turns farming unblemished pearls before we screech in the Smut Orc Logging Camp. |
| `set uts_postLoopFarmPearls = true` | After the run (and removing screech, if enabled), compare the mall price of an unblemished pearl against ten farming turns at your `valueOfAdventure` (mafia preference; assumed 4000 if unset). When the pearl is worth more, farm the remaining pearl zones with your best elemental res up to 18 (max farm speed) then +combat. Farms as many zones as your Fishy and adventure supply allow. Aborts if you run out of Fishy. |
| `set uts_postLoopCloverFishy = true` | When farming pearls and short on Fishy, get 20 turns of Fishy with a clover adventure. Uses free Aug. 2nd casts first, then an 11-leaf clover from inventory or — with `autoSatisfyWithCoinmasters` enabled — the hermit's three a day. When none of those can be used, abort. |
| `set uts_postLoopPrepCodpiece = true` | After the run (and after removing screech and pearl farming, if enabled), load The Eternity Codpiece for your next ascension: Empties Hagnk's first (`pull all`), buys unblemished pearls from the mall if you're still short, then slots five of them. |

## High shiny, low shiny

The script sorts your account into a resource tier and routes accordingly:

- **Low shiny** — you own none of the 2002 Mr. Store Catalog, cursed monkey's
  paw or august scepter. The script assumes pulls are precious and farms
  drops it would otherwise pull or wish for, and leans harder on the
  Congressional Medal of Insanity.
- **High shiny** — an Asdon Martin workshed plus
  `garbo_valueOfFreeFight > valueOfAdventure`: your free fights are worth
  more to aftercore meat farming than to the run, so the script *conserves*
  free kills, copies and maps for after the loop instead of spending them
  in-run, taking a slightly longer run for more profitable days.
- **Neither** (mid shiny) — every daily resource gets spent on making the run
  as short as possible.

## Things to prepare BEFORE ascending

- Load up the codpiece with unblemished pearls
- Have all of the underwater maps done
- Have a damp old wallet (not required but saves a turn)
- Have black crayon golem and unholy diver in the combat lover's locket
  (optional — the summon ladder uses fax, locket, mimic egg or genie,
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
