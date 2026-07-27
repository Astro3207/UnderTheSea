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

### Pulled early, every run

| Item | Why |
|---|---|
| Mer-kin sneakmask | Underwater-legal −combat hat for every noncombat hunt (outpost, pearl zones) |
| sea lasso | Lasso training toward 20 and seahorse taming; skipped when the Sword of S Words plan or monkey's paw wishes will supply them |
| shark jumper | Underwater +item shirt for the Caliginous Abyss and copy fights |
| scale-mail underwear | Underwater +item pants, same fights |
| Congressional Medal of Insanity | Large +item accessory worn through most farming; must already be in storage — the script won't buy one |
| Flash Liquidizer Ultra Dousing Accessory | Douse Foe procs on the shadow slab during the pay-phone free fights |
| Pocket Meteor Guide | Read once so Meteor Lore exists in-run; Macrometeorite is the slot-free monster re-roller |

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

### Reserved slots

`reservedPulls()` holds a slot for each item that costs real turns to farm if
the pull gets spent elsewhere first: a free-runaway source (parasol / navel
ring / GAPs), Mer-kin pinkslip (~15 turns, the Dive Bar is never visited
otherwise), Mer-kin prayerbeads (~15 turns of outpost), sea cowbell (~10
turns of corral), ink bladder and comb jelly (~4 turns of Marinara Trench
each), and a null-day exploit while crayon shavings are short.

## IOTMs the script uses

None are strictly required — every use is guarded — but turn count scales
with what you own.

### Route drivers (each worth multiple turns)

| IOTM | Why it's used |
|---|---|
| closed-circuit pay phone | Eleven free shadow fights a day carry lasso training; Shadow Waters buff |
| cursed monkey's paw | Wishes replace whole corral farming loops (lasso, cowbell) |
| 2002 Mr. Store Catalog | Spooky VHS copies, the pro skateboard's McTwist, software glitch |
| august scepter | Waffles re-roll monsters in place; Aug. 2nd is a free Lucky!; Aug. 24th waffle stock |
| book of facts | Just the Facts wishes and Monster Habitats copy chains for the Mom rescue |
| patriotic eagle (hatchling) | RWB blast forces the flytrap pellet; phylum screech banishes constructs |
| CyberRealm keycode | Cyberzone 1 free fights drive Mom-rescue progress |
| Peridot of Peril | One forced encounter per zone per day, aimed by `zoneTarget()` |
| Comprehensive Cartography | Three more forced encounters (Map the Monsters), same targeting |
| Fourth of May Cosplay Saber | Use the Force: deterministic diver, sea cow, prayerbead and scroll drops via the Force budget ladder |
| blood cubic zirconia | Sweat Bullets free kills; Refracted Gaze substat farming on free fights |
| baseball diamond | Team pitches: yellow ray, free kill and banish outcomes |
| Heartstone | %banish skill plus the Ultraheart colosseum buff |
| backup camera | Copies: golem stat-chains and lockkey-monster repeats |
| Jurassic Parka | Dilophosaur yellow ray; spikolodon spikes force noncombats |
| spring shoes | Spring Kick banish and Spring Away free runs |
| monodent of the sea | Lightning-bolt banish in an underwater-legal weapon |
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
| Pocket Meteor Guide | Macrometeorite: ten re-rolls a day from a skill, no gear slot |
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
