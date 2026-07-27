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

- **A Monodent of the Sea.** The underwater weapon the route lives in:
  lightning-bolt banishes shape the corral and outpost pools, and most
  farming outfits are hard-wired around it with no fallback — expect an
  abort mid-run if you start without one.
- **A Congressional Medal of Insanity** in storage. Worn through most of
  the route when present and skipped at real cost when absent; the script
  won't buy one for you.
- **The Eternity Codpiece**, loaded with unblemished pearls before
  ascending. The smuggled pearls keep the resistance phases cheap, and
  socketed gems keep their skills without spending accessory slots.

Everything else in the script is ownership-guarded: an IOTM you don't own is
skipped, and the route falls back to slower alternatives.

## Options

Two ways to run it, both typed into the gCLI:

| Command | What it does |
|---|---|
| `UnderTheSea` | Runs the loop: the full run, from initialization through the sorceress. |
| `UnderTheSea sim` | Checklist only — prints which supported IOTMs, skills and familiars you own and which pulls are stocked in Hagnk's, then exits. Nothing is pulled, fought or spent; use it before ascending to build a shopping list. |

Preferences, set once in the gCLI; both default to off:

| Preference | What it does |
|---|---|
| `set uts_godRunGuard = true` | Abort at ≤17 turns played if the dreadscroll 7 clue is still unknown, so you can eat a sushi for it instead of burning a record attempt. Only worth enabling if you are chasing a top turncount. |
| `set uts_postloopCommand = <command>` | CLI command to run once the loop finishes (e.g. a farming script). Leave empty to skip. |

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
with what you own. The full supported list lives in the script itself: run

    UnderTheSea sim

in the gCLI to print the ownership checklists without starting a run —
every supported IOTM, skill and familiar your account has or is missing,
plus the Hagnk's pull report: what is already stocked, what will be
mall-bought when the route needs it, and — in red — what cannot be bought
and should be acquired ahead of time. The same checklists print at the
start of every run.

### The most important ones

These carry the route; missing one changes how whole phases play out:

| IOTM | Why it matters |
|---|---|
| monodent of the sea | The underwater weapon the route lives in: lightning-bolt banishes shape the corral and outpost pools, and it anchors most farming outfits |
| closed-circuit pay phone | Eleven free shadow fights a day carry the whole lasso-training block; several route branches key on owning it |
| 2002 Mr. Store Catalog | Spooky VHS copies, the pro skateboard's McTwist, software glitch — the corral opener and Mom-rescue copies come from here |
| cursed monkey's paw | Wishes replace whole corral farming loops (lasso, cowbell); selects the summon-based diver plan |
| august scepter | Waffles re-roll monsters in place; Aug. 2nd is a free Lucky!; the script's resource tiering keys on the catalog/paw/scepter trio |
| Fourth of May Cosplay Saber | Use the Force: deterministic diver, sea cow, prayerbead and scroll drops via the Force budget ladder |
| book of facts | Just the Facts wishes and Monster Habitats copy chains for the Mom rescue |
| patriotic eagle (hatchling) | RWB blast forces the flytrap pellet; phylum screech banishes constructs; Cyberzone partner |

Useful skills and iotms and stuff: https://docs.google.com/spreadsheets/d/1bAZj17ZUb9cd4V1Nnda8--SiTlJvGQZWJvYz5CUA8G4/edit?usp=sharing

## Items to add support for

- Folder Holder
