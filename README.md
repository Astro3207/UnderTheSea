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
  props daily and aborts if the booth is empty (it will suggest one).
- **Aftercore mode (running the sea outside the path):** at least 4 fullness
  and 5 spleen free at start; the script prompts for which boss to fight.

Three more are "optional" in name only — the script will start without
them, but the route is built around them and you should treat them as part
of this list:

- **A Monodent of the Sea.** The underwater weapon most farming outfits
  are hard-wired around, with no fallback — expect an abort mid-run if you
  start without one. Its banishes keep the seahorse and lockkey hunts
  short.
- **A Congressional Medal of Insanity** in storage. Worn through most of
  the route when present and skipped at real cost when absent; the script
  won't buy one for you.
- **The Eternity Codpiece**, loaded with unblemished pearls before
  ascending. The Nautical Seaceress demands five unblemished pearls and
  the path makes them unpullable — pearls carried across ascension in the
  codpiece skip most of that farming, and socketed gems keep their skills
  without spending accessory slots.

Everything else in the script is ownership-guarded: an IOTM you don't own is
skipped, and the route falls back to slower alternatives.

## Options

Two ways to run it, both typed into the gCLI:

| Command | What it does |
|---|---|
| `UnderTheSea` | Runs the loop: the full run, from initialization through the sorceress. |
| `UnderTheSea sim` | Checklist only — prints which supported IOTMs, skills and familiars you own and which pulls are stocked in Hagnk's, then a modeled run length for your kit (with the biggest missing savings called out), and exits. Nothing is pulled, fought or spent; use it before ascending to build a shopping list. |

Preferences, set once in the gCLI; all default to off:

| Preference | What it does |
|---|---|
| `set uts_godRunGuard = true` | Abort at ≤17 turns played if the dreadscroll 7 clue is still unknown, so you can eat a sushi for it instead of burning a record attempt. Only worth enabling if you are chasing a top turncount. |
| `set uts_postloopCommand = <command>` | CLI command to run once the loop finishes (e.g. a farming script). Leave empty to skip. |
| `set uts_prepCodpiece = true` | After the run (and after the banish rundown, if that's enabled, so its farmed pearls count), load The Eternity Codpiece for your next ascension: buys unblemished pearls from the mall if you're short, then slots five of them. |
| `set uts_runOutEagleBanish = true` | **Experimental.** After the run finishes, keep adventuring until the patriotic eagle's Patriotic Screech stops banishing the construct phylum — a leftover phylum banish can make other scripts misbehave. The burned turns farm unblemished pearls (which ride to your next ascension in the codpiece), rotating through whichever of the five pearl zones are open with today's pearl unclaimed, wearing that zone's elemental resistance — at 18+ resistance a pearl is ten combats. Needs such a zone and turns of Fishy, and aborts loudly the moment it can't continue. Likely to burn a lot of turns post-run unless you have a lot of free kills. |

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
  whichever is available)
- Familiars: Grouper Groupie, Glover, Foul Ball
- For a competitive turn count: push the noncombat A Mer-kin Graffiti out of
  the noncombat queue

## IOTMs the script uses

None are strictly required — every use is guarded — but turn count scales
with what you own.

### The most important ones

These carry the route; missing one changes how whole phases play out:

| IOTM | Why it matters |
|---|---|
| monodent of the sea | The underwater weapon most outfits are built around; its banishes clear unwanted monsters out of The Coral Corral and The Mer-kin Outpost, keeping the sea-cow, seahorse and lockkey hunts short |
| closed-circuit pay phone | Free shadow-rift fights each day carry the sea lasso training you need before you can tame the seahorse into the Mer-kin Deepcity — skill progress without spending underwater turns |
| Fourth of May Cosplay Saber | Use the Force turns hunted monsters into guaranteed drops: the unholy diver, the sea cow's cowbells for taming the seahorse, and Mer-kin prayerbeads (each one equipped is one fewer healing item needed against Yog-Urt) |
| cursed monkey's paw | Wishes materialize scarce quest items — sea lassos and sea cowbells for the seahorse taming — instead of farming sea cowboys and sea cows for them |
| 2002 Mr. Store Catalog | Its store credits buy copy and drop-forcing tools mid-run that shortcut opening The Coral Corral and finding Mom in The Caliginous Abyss |
| book of facts | Just the Facts wishes and Monster Habitats copy chains cut the adventures needed to find Mom in The Caliginous Abyss |
| august scepter | Waffles swap a fight for a fresh monster — another shot at the sea cow or seahorse you actually need; Aug. 2 grants a free Lucky! adventure |
| patriotic eagle (hatchling) | Its red-white-and-blue blast guarantees the wriggling flytrap pellet that frees Little Brother from An Octopus's Garden |

Useful skills and iotms and stuff: https://docs.google.com/spreadsheets/d/1bAZj17ZUb9cd4V1Nnda8--SiTlJvGQZWJvYz5CUA8G4/edit?usp=sharing

## Items to add support for

- Folder Holder
