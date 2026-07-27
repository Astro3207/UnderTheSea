# UnderTheSea
11,037 Leagues Under the Sea loop. Fork of [Astro3207/UnderTheSea](https://github.com/Astro3207/UnderTheSea).

`git checkout tottington/UnderTheSea`

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
- **A Congressional Medal of Insanity** in storage. The script refuses to buy
  one for you.
- **Aftercore mode (running the sea outside the path):** at least 4 fullness
  and 5 spleen free at start; the script prompts for which boss to fight.

Everything else in the script is ownership-guarded: an IOTM you don't own is
skipped, and the route falls back to slower alternatives.

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

## What the script pulls

Ronin allows 20 pulls a day and the script manages them itself, including
holding slots back for items it knows it will need later (`reservedPulls()`).
Mall purchases into storage respect `autoBuyPriceLimit` and confirm before
exceeding it.

**Pulled early, every run:** Mer-kin sneakmask, sea lasso, shark jumper,
scale-mail underwear, Congressional Medal of Insanity, Flash Liquidizer Ultra
Dousing Accessory, Pocket Meteor Guide (if owned and unread).

**Pulled when the route needs them:** Mer-kin digpick, lodestone, comb jelly,
Elf Guard SCUBA tank, rusty rivet, sea cowbell, Mer-kin prayerbeads, Mer-kin
healscroll / killscroll / worktea / knucklebone / cheatsheet / hallpass /
hidepaint, pro skateboard, software glitch, pulled yellow taffy, stuffed yam
stinkbomb, waffle, skate blade, null-day exploit, New Age healing crystal,
soggy used band-aid, damp old wallet, fish sauce / Aldebaran sardines / cheap
pasta + pie man was not meant to eat (diet and Asdon fuel), Handheld Allied
radio / Clara's bell / stench jelly (only when no noncombat-forcing IOTM is
owned).

**End-of-run cleanup pulls** (whatever slots remain): peppermint parasol, ink
bladder, Mer-kin pinkslip, stuffed yam stinkbomb, Louder Than Bomb, anchor
bomb.

**Reserved slots** are held for the items that cost real turns to farm if the
pull is spent elsewhere: a free-runaway source (parasol / navel ring / GAPs),
Mer-kin pinkslip, Mer-kin prayerbeads, sea cowbell, ink bladder, comb jelly,
and a null-day exploit while crayon shavings are short.

## IOTMs the script uses

None are strictly required — every use is guarded — but turn count scales
with what you own. Roughly by impact:

**Route drivers** (each worth multiple turns): closed-circuit pay phone,
cursed monkey's paw, 2002 Mr. Store Catalog (Spooky VHS / pro skateboard /
software glitch), august scepter, book of facts (Just the Facts, Monster
Habitats), patriotic eagle + CyberRealm keycode, Peridot of Peril,
Comprehensive Cartography (Map the Monsters), blood cubic zirconia, baseball
diamond, Heartstone, backup camera, Jurassic Parka, Fourth of May Cosplay
Saber (Use the Force drives the deterministic diver, sea cow and prayerbead
plans), spring shoes, monodent of the sea, Everfull Dart Holster, Mayam
Calendar, Leprecondo, Cincho de Mayo, McHugeLarge duffel bag, Apriling band
helmet, April Shower Thoughts shield, bat wings.

**Copy and free-turn engines:** Source Terminal (items.enh, duplicate.edu),
Time-Spinner, January's Garbage Tote (broken champagne bottle), Powerful
Glove, Pocket Meteor Guide (Macrometeorite), combat lover's locket, emotion
chip (Feel Hatred / Feel Nostalgic), Lil' Doctor™ bag (Chest X-Ray, Otoscope,
Reflex Hammer), mumming trunk, Kremlin's Greatest Briefcase, Cargo Cultist
Shorts, Eight Days a Week Pill Keeper, Sept-Ember Censer, vampyric cloake,
knock-off retro superhero cape, roman candelabra, miniature crystal ball,
latte lovers member's mug, V for Vivala mask, designer sweatpants, tearaway
pants, autumn-aton, S.I.T. Course, a workshed (Asdon Martin, model train set,
TakerSpace or Mayo Clinic), clan photobooth, clan pool table (Hustlin').

**Familiars:** Grouper Groupie (the underwater fairy the route leans on),
Red-Nosed Snapper, Jill-of-All-Trades, chest mimic, patriotic eagle, Sword of
S Words, peace turkey or disgeist, Jumpsuited Hound Dog, Glover, Foul Ball,
Space Jellyfish, Pocket Professor, Tiny Plastic Santa Claus Skeleton
(aftercore Dad fight only).

## Does class matter?

Any class can complete the run, but the script is tuned on **Sauceror**, and
the polish drops off the further you get from it:

- **Prime stat picks your zones.** The guild-unlock quest, the pearl /
  Grandpa noncombat hunt, and the backup lasso zone are all selected by
  `my_primestat()` (Mysticality → Marinara Trench, Moxie → Dive Bar, Muscle →
  Anemone Mine), with matching resistance moods. All three are mapped; none
  of them breaks.
- **Moxie classes get shortcuts** the others don't: pickpocketing pristine
  fish scales, and tearaway pants skipping the guild test.
- **The combat finisher casts Saucegeyser / Saucestorm.** Other classes lean
  on free kills and plain attacks instead; fights that fall through to the
  spell finisher will error without those skills, so expect rough edges.
- **The Colosseum plan builds spell damage for Saucegeyser.** The gear
  maximizer targets `spell damage percent, mys` — on a non-Mysticality class
  the fifteen rounds will be slower and may need attention.
- **The aftercore Dad Sea Monkee fight** uses the Mysticality spell rotation.
- Skills from other classes are cast only if known (Cannelloni Cocoon, The
  Ode to Booze, Tongue of the Walrus, Raise Backup Dancer, Double-Fisted
  Skull Smashing for dual-wield equipping).

Ascending as a different class mostly means different zones for the early
quests and losing whichever of the shortcuts above belonged to your old
class. The turn estimates in the commit history assume Sauceror.

Useful skills and iotms and stuff: https://docs.google.com/spreadsheets/d/1bAZj17ZUb9cd4V1Nnda8--SiTlJvGQZWJvYz5CUA8G4/edit?usp=sharing

## Items to add support for

- Folder Holder
