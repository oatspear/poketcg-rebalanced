# Pokémon TCG Rebalanced

## Version 0.2

### Pokémon Cards

#### Bulbasaur
- Added attack: **(C) Growl** - reduces damage taken by 10.

#### Ivysaur
- **Poison Powder**: reduced cost from (GGG) to (GG).
- **Vine Whip**: increased damage from 30 to 40.

#### Venusaur Lv64
- **Mega Drain**: reduced cost from (GGGG) to (GGG).

#### Venusaur Lv67
- **Solar Beam**: reduced cost from (GGGG) to (GGG).

#### Butterfree
- **Mega Drain**: reduced cost from (GGGG) to (GGG).

#### Kakuna
- Reduced HP from 80 to 70.

#### Beedrill
- **Twineedle**: reduced cost from (CCC) to (CC) and damage from 30x to 20x.

#### Ekans
- **Spit Poison**: added 10 direct damage.

#### Arbok
- **Poison Fang**: reduced cost from (DDC) to (DC).

#### Nidoran (F)
- Reduced HP from 60 to 50.

#### Nidorina
- **Supersonic**: reduced cost from (D) to (C).

#### Nidoqueen
- **Mega Punch**: reduced cost from (DDCC) to (DCC).

#### Nidorino
- **Double Kick**: reduced cost from (DCC) to (DC) and damage from 30x to 20x.
- **Horn Drill**: reduced cost from (DDCC) to (DDC).

#### Nidoking
- **Thrash**: reduced cost from (DCC) to (DC).
- **Toxic**: increased damage from 20 to 30.

#### Zubat
- **Supersonic**: reduced cost from (CC) to (C).

#### Golbat
- **Leech Life**: reduced cost from (DDC) to (DC).

#### Oddish
- **Sprout**: reduced cost from (GG) to (G).

#### Gloom
- **Poison Powder**: added 10 direct damage.
- **Foul Odor**: reduced cost from (GG) to (GC).

#### Vileplume
- **Heal**: no longer requires a coin flip.
- **Petal Dance**: reduced cost from (GGG) to (GGC) and damage from 40x to 30x.

#### Parasect
- **Spore**: reduced cost from (GG) to (G).

#### Bellsprout
- **Vine Whip**: increased damage from 10 to 20.

#### Victreebel
- **Lure**: reduced cost from (G) to (C).
- **Acid**: increased damage from 20 to 30.

#### Grimer
- **Nasty Goo**: increased cost from (C) to (D).
- **Minimize**: reduced cost from (D) to (C).

#### Muk
- **Sludge**: reduced cost from (DDD) to (DDC).

#### Koffing
- **Foul Gas**: reduced cost from (DD) to (DC).

#### Weezing
- **Smog**: reduced cost from (DD) to (DC).
- **Self-destruct**: reduced cost from (DDC) to (DCC).

#### Tangela Lv8
- Increased HP from 50 to 60.
- **Bind**: reduced cost from (GC) to (CC).
- **Poison Powder**: reduced cost from (GGG) to (GG) and damage from 20 to 10.

#### Tangela Lv12
- Increased HP from 50 to 60.
- **Poison Whip**: reduced cost from (GGC) to (GG).

#### Pinsir
- **Iron Grip**: reduced cost from (GG) to (GC).
- **Guillotine**: reduced cost from (GGCC) to (GCC).

#### Charmeleon
- **Flamethrower**: increased damage from 50 to 60.

#### Vulpix
- **Confuse Ray**: reduced cost from (FF) to (F).
- Added attack: **Flare** (FC) - 20 damage.

#### Ninetales Lv32
- **Lure**: reduced cost from (CC) to (C).
- **Fire Blast**: reduced cost from (FFFF) to (FFF).

#### Ninetales Lv35
- **Mix Up**: replaced with **Quick Attack** (CC) - 20 damage +10 if heads.
- **Dancing Embers**: replaced with **Flamethrower** (FFC): 60 damage, discard 1 (F).

#### Arcanine Lv34
- **Quick Attack**: increased damage from 10 (+20) to 20 (+10).

#### Arcanine Lv45
- Reduced HP from 100 to 90.
- **Flamethrower**: increased damage from 50 to 60.
- **Take Down**: reduced cost from (FFCC) to (CC), damage from 80 to 50 and recoil from 30 to 20.

#### Magmar Lv24
- Increased HP from 50 to 60.

#### Magmar Lv31
- **Smog**: reduced cost from (FF) to (FC).


## Version 0.1

### Added
- Darkness type.
- Card: Darkness Basic Energy.
- Implemented Supporter Trainer cards.

### Changed
- Changed Pokémon types, weaknesses and resistances to accommodate the new Darkness type and to better distribute weakness and resistance ratios per type.
- **Ekans** and **Arbok**: changed type to Darkness and weakness to Fighting.
- **Nidoran (F)**, **Nidorina**, **Nidoran (M)** and **Nidorino**: changed type to Darkness and weakness to Fighting.
- **Nidoqueen** and **Nidoking**: changed type to Darkness, weakness to Fighting and resistance to Lightning.
- **Zubat** and **Golbat**: changed type to Darkness and weakness to Lightning.
- **Grimer** and **Muk**: changed type to Darkness and weakness to Fighting.
- **Koffing** and **Weezing**: changed type to Darkness and weakness to Fighting.
- **Gastly**, **Haunter** and **Gengar**: changed type to Darkness.
- **Clefairy** and **Clefable**: changed type to Psychic, weakness to Darkness and removed resistance to Psychic.
- **Jigglypuff** and **Wigglytuff**: changed type to Psychic, weakness to Darkness and removed resistance to Psychic.
- **Rattata**, **Raticate**, **Meowth**, **Persian**, **Lickitung**, **Chansey**, **Kangaskhan**, **Tauros**, **Ditto**, **Eevee**, **Porygon**, **Snorlax**, **Dratini** and **Dragonair**: removed resistance to Psychic.
- **Poliwag**, **Poliwhirl** and **Poliwrath**: changed weakness to Lightning.
- **Gyarados**: changed weakness to Lightning.
- **Geodude**, **Graveler** and **Golem**: added resistance to Lightning.
- **Onix**: added resistance to Lightning.
- **Aerodactyl**: changed weakness to Water.
- Updated AI decks to include appropriate energy cards.
- Evolving Pokémon no longer clears status conditions.
- Retreating no longer clears status conditions.
- Paralysis, Sleep and Confusion allow for a normal retreat.
- Poison and Sleep remain on benched Pokémon, but no damage is taken from Poison, and Pokémon do not wake up on the Bench.
- Sleep works similarly to Confusion; a coin is flipped before attacking in order to determine whether the Pokémon wakes up.
- Poison only deals damage on the Pokémon owner's turn.
- Confusion only deals 10 damage to self on tails.
- A player can only retreat once per turn.
- In the first turn of the game, a player can only either Attack or use a Supporter card.
- Changed the following cards to be Trainer Supporter cards: **Professor Oak**, **Imposter Professor Oak**, **Bill**, **Mr. Fuji**, **Lass**, **Pokémon Trader**, **Energy Retrieval**, **Super Energy Retrieval**, **Energy Removal**, **Super Energy Removal**, **Switch**, **Pokémon Center**, **Scoop Up**, **Computer Search**, **Item Finder**, **Gust of Wind**.
- **Bill**: draws 3 cards.
- **Potion**: heals 30 HP.
- **Super Potion**: heals 60 HP.
- **Revive**: revives a Pokémon with full HP.
- Adjusted the retreat costs of many Pokémon to keep most Basic Pokémon at 0 cost, most Stage 1 at 1 COLORLESS and some Stage 2 or other heavy attackers at 2 COLORLESS.

### Fixed
- AI wrongfully adds score twice for attaching energy to Arena card.
- Cards in AI decks that are not supposed to be placed as Prize cards are ignored.
- AI score modifiers for retreating are never used.
- AI handles Basic Pokémon cards in hand wrong when scoring the use of Professor Oak.
- Rick never plays Energy Search.
- Rick uses wrong Pokédex AI subroutine.
- Chris never uses Revive on Kangaskhan.
- AI Pokemon Trader may result in unintended effects.
- Sam's practice deck does wrong card ID check.
- AI does not account for Mysterious Fossil or Clefairy Doll when using Shift Pkmn Power.
- Challenge host uses wrong name for the first rival.

### To Do
- Simplify custom logic (`OATS`) for card filters in `deck_configuration.asm`. Trainer filter already handles Trainer cards, no need to check for Trainer in Pokémon/Energy filters.
