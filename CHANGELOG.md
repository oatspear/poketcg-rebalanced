# Pokémon TCG Rebalanced

## Version 0.1

### Added
- Darkness type.
- Card: Darkness Basic Energy.

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
