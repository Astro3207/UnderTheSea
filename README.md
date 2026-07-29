# UnderTheSea
11,037 Leagues Under the Sea loop.

`git checkout Astro3207/UnderTheSea`

Installing through mafia's `git checkout` also installs
[seedfinder](https://github.com/VeeArrKoL/seedfinder) from `dependencies.txt`.
Run `verify UnderTheSea.ash` in the gCLI after installing — a clean verify
means every dependency landed.

## Hard requirements

The script aborts early and loudly when one of these is missing, so check the
list before starting a run:

- **KoLmafia r29057 or newer.**
- **seedfinder** installed (see above). It solves the dreadscroll from the
  clues instead of guessing.
- **`autoSatisfyWithNPCs = true`** in mafia's preferences.
- **A clan with a stocked photobooth** — the script claims the three sheriff
  props daily and aborts if the booth is empty.
- **Aftercore mode (running the sea outside the path):** at least 4 fullness
  and 5 spleen free at start; the script prompts for which boss to fight.

Three more are "optional" in name only — the script will start without
them, but the route is built around them and you should treat them as part
of this list:

- **A Monodent of the Sea.** This makes the whole run possible.
- **A Congressional Medal of Insanity** Worn through most of
  the route when present and skipped at real cost when absent; the script
  won't buy one for you. Can't guarantee runs will finish without one. 
- **The Eternity Codpiece**, loaded with unblemished pearls before
  ascending. The Nautical Seaceress demands five unblemished pearls and
  the path makes them unpullable.
- **3 Familiars** Grouper Groupie, Glover, Foul Ball

## Options

| Command | What it does |
|---|---|
| `UnderTheSea` | Runs the loop: the full run, from initialization through the sorceress. |
| `UnderTheSea sim` | Checklist only: prints which supported IOTMs, skills and familiars you own and which pulls are stocked in Hagnk's, then a modeled run length for your kit. Forecast run length is experimental, no guarantees of accuracy. |

Preferences, set once in the gCLI; all default to off:

| Preference | What it does |
|---|---|
| `set uts_godRunGuard = true` | Abort at ≤17 turns played if the dreadscroll 7 clue is still unknown, so you can eat a sushi for it instead of burning a record attempt. Only worth enabling if you are chasing a top turncount. |
| `set uts_postloopCommand = <command>` | CLI command to run once the loop finishes (e.g. a farming script). Leave empty to skip. |
| `set uts_runOutEagleBanish = true` | **Experimental.** After the run finishes, keep adventuring until the patriotic eagle's Patriotic Screech stops banishing the construct phylum — a leftover phylum banish can make other scripts (⭐garbo⭐) misbehave. Empties Hagnk's first (`pull all`) so all your gear is on hand, then burns the turns farming unblemished pearls (which ride to your next ascension in the codpiece). Costs ~15-25 plain turns post-run (the recharge plus finishing the pearl it started): free kills and free runs advance neither the pearl counter nor the screech recharge, so the script fights every combat out. The moment the screech is back it's spent at the Smut Orc Logging Camp, and any pearl still in progress is finished behind the Jumpsuited Hound Dog's +combat instead of the eagle. With `uts_farmPearls` also set, the recharge combats double as the farm's first pearls and the walk simply continues. |
| `set uts_farmPearls = true` | After the run (and the banish rundown, if enabled), compare the mall price of an unblemished pearl against ten farming turns at your `valueOfAdventure` (mafia preference; assumed 4000 if unset). When the pearl is worth more, farm the remaining pearl zones — up to five pearls a day at roughly ten combats each, plain-fought for the same reason as the rundown, geared and buffed to the 18 elemental resistance that full-speed progress demands and to as much +combat as the leftover slots carry. Farms as many zones as your Fishy and adventure supply allow, skipping a fresh zone when fewer than 15 of either remain (a part-farmed zone does not survive rollover) — except while the eagle rundown's recharge is live, which farms on any supply — and aborts loudly if it runs dry mid-zone. Bring your own Fishy. |
| `set uts_prepCodpiece = true` | After the run (and after the banish rundown and pearl farm, if enabled, so their pearls count), load The Eternity Codpiece for your next ascension: Empties Hagnk's first (`pull all`), buys unblemished pearls from the mall if you're still short, then slots five of them. |

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
- For a competitive turn count: push the noncombat A Mer-kin Graffiti out of
  the noncombat queue

## Important IOTMs

| IOTM | Why it matters |
|---|---|
| monodent of the sea | The underwater weapon most outfits are built around; its banishes clear unwanted monsters out of The Coral Corral and The Mer-kin Outpost, keeping the sea-cow, seahorse and lockkey hunts short. |
| closed-circuit pay phone | Free shadow-rift fights each day carry the sea lasso training you need before you can tame the seahorse into the Mer-kin Deepcity — skill progress without spending underwater turns. |
| Fourth of May Cosplay Saber | Use the Force guaranteed drops: the unholy diver, the sea cow's cowbells for taming the seahorse, and Mer-kin prayerbeads. |
| cursed monkey's paw | Wishes materialize scarce quest items like sea lassos and sea cowbells for the seahorse taming instead of farming sea cowboys and sea cows for them. |
| 2002 Mr. Store Catalog | Store credits buy copy and drop-forcing tools mid-run that shortcut opening The Coral Corral and finding Mom in The Caliginous Abyss. |
| book of facts | Just the Facts wishes and Monster Habitats copy chains cut the adventures needed to find Mom in The Caliginous Abyss |
| patriotic eagle (hatchling) | Patriotic Screech can save a good amount of turns, and is irreplaceable. |

Useful skills and iotms and stuff: https://docs.google.com/spreadsheets/d/1bAZj17ZUb9cd4V1Nnda8--SiTlJvGQZWJvYz5CUA8G4/edit?usp=sharing

## Items to add support for

- Folder Holder
