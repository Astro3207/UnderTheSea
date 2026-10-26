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
| `UnderTheSea postloop` | Runs only the postloop steps — the pilsner drain, the codpiece prep, the screech rundown, the pearl farm, the codpiece top-up and `uts_postloopCommand` — and none of the run. Use it to exercise the `uts_postLoop*` preferences on a finished account, where a bare `UnderTheSea` would start an aftercore Sea run instead. Each step still self-gates on its own preference. |

Preferences, set once in the gCLI; all default to off:

| Preference | What it does |
|---|---|
| `set uts_godRunGuard = true` | Abort at ≤17 turns played if the dreadscroll 7 clue is still unknown, so you can eat a sushi for it instead of burning a record attempt. Only worth enabling if you are chasing a top turncount. |
| `set uts_postloopCommand = <command>` | CLI command to run once the loop finishes (e.g. a farming script). Leave empty to skip. |
| `set uts_usePilsners = true` | After the run, drink out your astral pilsners — cracking six-packs as it goes, under Ode to Booze — so the supply turns into adventures for whatever you run next instead of sitting in the bag. Empties Hagnk's first when the supply is sitting there, and runs first, before the codpiece prep, the screech rundown and the pearl farm, so an abort in any of them still leaves the supply drunk. Without it, the screech rundown drinks a pilsner whenever it runs out of adventures, and the pearl farm drinks every pilsner you hold before handing off to pearlo; both stay within your own liver, and adventures pearlo leaves unspent go to `uts_postloopCommand`. Leaves out any liver capacity that equipment or the familiar is lending, so the next script's re-dress can't leave you falling-down drunk. It does spend liver: a pilsner is at most 11 adventures, 12 under Ode, for one drunkenness — worse than most aftercore booze — and ⭐garbo⭐ has its own `garbo_usePilsners`, so you want one or the other, not both. |
| `set uts_postLoopRunOutEagleBanish = true` | **Experimental.** After the run finishes, keep adventuring until the patriotic eagle's Patriotic Screech stops banishing the construct phylum, which can make other scripts (⭐garbo⭐) misbehave. Empties Hagnk's first, then burns the turns in the unblemished pearl zones before we screech in the Smut Orc Logging Camp. Runs after the codpiece prep and before the pearl farm, which picks up the zone progress those turns made. |
| `set uts_postLoopFarmPearls = true` | After the run (and loading the codpiece and removing screech, if enabled), farm today's unblemished pearls with [pearlo](https://github.com/xn/pearlo), which installs as a dependency of this script (`git checkout xn/pearlo release` if it is missing; without it the farm is skipped). pearlo prices each zone against your `valueOfAdventure` (mafia preference; UnderTheSea passes 4000 when it is 0 or less) and farms only the profitable ones. Your own `pearlo_*` preferences apply. Empties Hagnk's first, then drinks every astral pilsner you hold within your own liver, since pearlo never drinks; adventures it leaves unspent go to `uts_postloopCommand`. Runs after the screech rundown and before the codpiece top-up: an abort inside pearlo stops UnderTheSea too, so the top-up and `uts_postloopCommand` are skipped. If `pearlo` reports too many matches, keep only the `xn-pearlo-release` copy of the script. |
| `set uts_postLoopCloverFishy = true` | When Fishy runs out, get 20 more turns of it with a Lucky! adventure in The Brinier Deepers. In the screech rundown, UnderTheSea does this itself: free Aug. 2nd casts first, then an 11-leaf clover from inventory or, with `autoSatisfyWithCoinmasters` enabled, the hermit's three a day; when none of those can be used, the rundown stops. For the pearl farm it passes `luckyfishy` to pearlo, which has more Lucky! sources (Apriling band saxophone, Heartstone LUCK, Aug. 2nd, owned clovers, the free pill keeper use, hermit clovers, and mall clovers under its `cloverprice`; see pearlo's README). Only used together with `uts_postLoopRunOutEagleBanish` or `uts_postLoopFarmPearls`. |
| `set uts_postLoopPrepCodpiece = true` | After the run, load The Eternity Codpiece with five unblemished pearls for your next ascension, in two passes. Each pass does nothing if the codpiece already holds five pearls; otherwise it empties Hagnk's (`pull all`), buys the missing pearls from the mall, and once five are on hand slots all five. The first pass runs before the screech rundown and the pearl farm, so an abort later still leaves the codpiece loaded, and coming up short there only prints a note. The second runs after the pearl farm, so farmed pearls count, and aborts if it still can't reach five. Mall buys only happen with `autoSatisfyWithMall` enabled and `autoBuyPriceLimit` at or above the pearl's mall price. |
| `set uts_pearloArgs = <args>` | Extra arguments appended to the pearl farm's `pearlo` call, e.g. `airmode=gear potionprice=5000` (`pearlo help` lists them). A `voa` or `luckyfishy` given here replaces the one UnderTheSea would add. A typo shows up as pearlo's "Unknown argument" or "Duplicate key" error. |

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
