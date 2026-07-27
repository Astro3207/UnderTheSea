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
- **A Congressional Medal of Insanity** in storage. The script refuses to buy
  one for you.
- **Aftercore mode (running the sea outside the path):** at least 4 fullness
  and 5 spleen free at start; the script prompts for which boss to fight.

Everything else in the script is ownership-guarded: an IOTM you don't own is
skipped, and the route falls back to slower alternatives.

## Options

Set once in the gCLI; both default to off:

| Preference | What it does |
|---|---|
| `set uts_godRunGuard = true` | Abort at ≤17 turns played if the dreadscroll 7 clue is still unknown, so you can eat a sushi for it instead of burning a record attempt. Only worth enabling if you are chasing a top turncount. |
| `set uts_postloopCommand = <command>` | CLI command to run once the loop finishes (e.g. a farming script). Leave empty to skip. |

## High shiny, low shiny

The script sorts your account into a resource tier and routes accordingly:

- **Low shiny** — you own none of the 2002 Mr. Store Catalog, cursed monkey's
  paw or august scepter. The script assumes pulls are precious and farms
  drops it would otherwise pull or wish for, and leans harder on the
  Congressional Medal of Insanity for +item.
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

## What the script pulls

Ronin allows 20 pulls a day and the script manages them itself, including
holding slots back for items it knows it will need later (`reservedPulls()`).
Mall purchases into storage respect `autoBuyPriceLimit` and confirm before
exceeding it.

### Pulled early, every run

| Item | Why |
|---|---|
| Mer-kin sneakmask | Underwater-legal −combat hat for every noncombat hunt (outpost, pearl zones) |
| sea lasso | Lasso training toward 20 and seahorse taming; skipped when the Sword of S Words plan or monkey's paw wishes will supply them |
| shark jumper | Underwater +item shirt for the Caliginous Abyss and copy fights |
| scale-mail underwear | Underwater +item pants, same fights |
| Congressional Medal of Insanity | Large +item accessory worn through most farming; must already be in storage — the script won't buy one |
| Flash Liquidizer Ultra Dousing Accessory | Douse Foe procs on the shadow slab during the pay-phone free fights |

### Pulled when the route needs them

| Item | Why |
|---|---|
| Mer-kin digpick | Mine teflon ore for the swim fins tailpiece; also flags miner fights as killable |
| lodestone | Loded effect: extra mining attempts after Unaccompanied Miner's five run out |
| comb jelly | Jelly Combed +item buff before Abyss and corral trips |
| Elf Guard SCUBA tank | Waterbreathing gear that frees the pants slot during habitat fights and the lasso backup plan |
| rusty rivet | Tops the diver hunt up to 8 when one short |
| sea cowbell | Seahorse taming needs three thrown |
| Mer-kin prayerbeads | Yog-Urt: three equipped means only two healing items to shed Suckrament |
| Mer-kin healscroll | Dreadscroll clue 2 (thrown in the library) and a Yog-Urt healing item |
| Mer-kin killscroll | Dreadscroll clue 5 (thrown at a mer-kin) |
| Mer-kin worktea | Dreadscroll clue 7 via the sushi meal |
| Mer-kin knucklebone | Dreadscroll clue 4 on use |
| Mer-kin cheatsheet | Tops up the 9-sheet vocabulary grind |
| Mer-kin hallpass | Steers the elementary school noncombat cycle |
| Mer-kin hidepaint | Colorfully Concealed −combat for the Grandpa noncombat hunt |
| pro skateboard | Do an epic McTwist forces the corral opener's drops |
| software glitch | Corral opener: swaps the fight for the Bugged bugbear |
| pulled yellow taffy | Yellow-ray combat item for the corral opener |
| waffle | Re-rolls a monster in place: seahorse phase and peanut fights |
| skate blade | Skate Park war gear for the Holey Rollers resolution |
| null-day exploit | Null afternoon replaces crayon shavings as the Shub/colosseum deleveler |
| New Age healing crystal / soggy used band-aid | Yog-Urt healing when prayerbeads are short |
| damp old wallet | Sand dollars for the Old Guy's boot without spending a clover adventure |
| fish sauce / Aldebaran sardines / cheapest pasta | Keeping Fishy up (diet path depends on gear owned) |
| pie man was not meant to eat | One-pull Asdon Martin fuel for Driving Waterproofly |
| Handheld Allied radio / Clara's bell / stench jelly | Noncombat forcer of last resort, only when no forcer IOTM is owned |

### End-of-run cleanup pulls (whatever slots remain)

| Item | Why |
|---|---|
| peppermint parasol | Three free runaways for the next day's farming |
| ink bladder | Underwater free-run combat item |
| Mer-kin pinkslip | Free-run item that works on any mer-kin |
| stuffed yam stinkbomb | Banishing free run |
| Louder Than Bomb | Banishing free run |
| anchor bomb | Banishing free run (TakerSpace) |

## IOTMs the script uses

None are strictly required — every use is guarded — but turn count scales
with what you own.

### The most important ones

These carry the route. Missing one of them doesn't stop the run, but it
changes how whole phases play out:

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

### Route drivers (each worth multiple turns)

| IOTM | Why it's used |
|---|---|
| CyberRealm keycode | Cyberzone 1 free fights drive Mom-rescue progress |
| Peridot of Peril | One forced encounter per zone per day, aimed by `zoneTarget()` |
| Comprehensive Cartography | Three more forced encounters (Map the Monsters), same targeting |
| blood cubic zirconia | Sweat Bullets free kills; Refracted Gaze substat farming on free fights |
| baseball diamond | Team pitches: yellow ray, free kill and banish outcomes |
| Heartstone | %banish skill plus the Ultraheart colosseum buff |
| backup camera | Copies: golem stat-chains and lockkey-monster repeats |
| Jurassic Parka | Dilophosaur yellow ray; spikolodon spikes force noncombats |
| spring shoes | Spring Kick banish and Spring Away free runs |
| Everfull Dart Holster | Bullseye free kills once the perk set supports them |
| Mayam Calendar | Daily ring resources claimed at initialization |
| Leprecondo | Passive furniture buffs, need-ordered install |
| Cincho de Mayo | Fiesta Exit noncombat forces, recharged through free rests |
| McHugeLarge duffel bag | Avalanche noncombat force; left pole tracks squid/tippler; slash olfaction |
| Apriling band helmet | Tuba noncombat forces; patrol beat −combat |
| April Shower Thoughts shield | Spitball yellow ray fallback; daily glob claim |
| bat wings | Five free fights, swoop, and upside-down free rests |

### Copy and free-turn engines

| IOTM | Why it's used |
|---|---|
| Source Terminal | items.enh +item buff; duplicate.edu doubles the diver's (or cow's) table |
| Time-Spinner | Guaranteed re-fight of a just-fought target for one turn |
| January's Garbage Tote | The champagne bottle doubles the item bonus at roll-heavy zones |
| Powerful Glove | Monster re-rolls when Macrometeorite casts run out |
| Meteor Lore (Macrometeorite) | Ten monster re-rolls a day from a skill, no gear slot |
| combat lover's locket | Diver and golem summons |
| emotion chip | Feel Hatred banish; Feel Nostalgic re-rolls a copied drop table |
| Lil' Doctor™ bag | Chest X-Ray free kills, Otoscope +200% item, Reflex Hammer banish |
| mumming trunk | Prince George: +item that lasts until rollover, not N turns |
| Kremlin's Greatest Briefcase | Items Are Forever +50% item for 50 turns (needs the case opened) |
| Cargo Cultist Shorts | Pocket 494: Vinegavotte, +20% item for 50 turns |
| Eight Days a Week Pill Keeper | Free pill: Fidoxene familiar-weight floor, or Sneakisol as a forcer |
| Sept-Ember Censer | Septapus charms: seven pickpockets against the shadow slab |
| vampyric cloake | Become a Bat: +50% item per farming fight, ten a day |
| knock-off retro superhero cape | Colosseum kill-mode fallback |
| roman candelabra | Purple candle copies of the habitat monsters |
| miniature crystal ball | Predicts the corral so seahorse attempts aren't wasted |
| latte lovers member's mug | Throw Latte banish |
| V for Vivala mask | Creepy grin banish |
| designer sweatpants | Sweat-powered free runs during the guild unlock |
| tearaway pants | Skips the moxie guild test; Tear Away banishes plants |
| autumn-aton | Background farming (digpick zone, shadow rift) while you adventure |
| S.I.T. Course | Daily certificate skill |
| a workshed | Asdon: Driving Waterproofly; train set: resources; TakerSpace: anchor bomb; Mayo Clinic |
| clan photobooth | Sheriff set: Assert Your Authority free kills |
| clan pool table | Hustlin' in the superitdrop mood |

### Familiars

| Familiar | Why it's used |
|---|---|
| Grouper Groupie | The underwater fairy the route leans on by default |
| Red-Nosed Snapper | Phylum tracking on top of a stronger underwater fairy |
| Jill-of-All-Trades | Best fairy once Driving Waterproofly is up |
| chest mimic | Diver insurance eggs and fight copies |
| patriotic eagle | RWB pellet forcing, zone citizenship, construct screech |
| Sword of S Words | Kill-a-lot chains for lasso and cowbell farming |
| peace turkey / disgeist | −combat for the noncombat hunts |
| Jumpsuited Hound Dog | +combat for the gymnasium |
| Glover | Cyberzone 1 fights |
| Foul Ball | Colosseum support |
| Space Jellyfish | Full fairy underwater, plus stench jelly as a free forcer |
| Pocket Professor | Lecture copy chains on the diver and the sea cow |
| Tiny Plastic Santa Claus Skeleton | Aftercore Dad Sea Monkee fight only |

Useful skills and iotms and stuff: https://docs.google.com/spreadsheets/d/1bAZj17ZUb9cd4V1Nnda8--SiTlJvGQZWJvYz5CUA8G4/edit?usp=sharing

## Items to add support for

- Folder Holder
