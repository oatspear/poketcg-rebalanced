; ------------------------------------------------------------------------------
; Building Blocks
; ------------------------------------------------------------------------------


; overwrites in wDamage, wAIMinDamage and wAIMaxDamage with the value in a
; resets wDamageFlags
SetDefiniteDamage:
	ld [wDamage], a
	ld [wAIMinDamage], a
	ld [wAIMaxDamage], a
	xor a
	ld [wDamageFlags], a
	ret


; overwrites wAIMinDamage and wAIMaxDamage with value in wDamage
SetDefiniteAIDamage:
	ld a, [wDamage]
	ld [wAIMinDamage], a
	ld [wAIMaxDamage], a
	ret


; subtract the value in a from wDamage
SubtractFromDamageCapZero:
	call SubtractFromDamage
	rla
	ret nc
; cap it to 0 damage
	xor a
	jr SetDefiniteDamage


; doubles the damage output
DoubleDamage_DamageBoostEffect:
  ld a, [wDamage]
  add a
  jr nc, .got_damage
; cap damage at 250
	ld a, MAX_DAMAGE
.got_damage
  ld [wDamage], a
  ret


; just add 40 damage, precondition checks have already been made
PrimalScythe_DamageBoostEffect:
	ld a, 40
	call AddToDamage
	jp SetDefiniteAIDamage


; ------------------------------------------------------------------------------
; Based on Coin Flips
; ------------------------------------------------------------------------------

; outputs:
;   a: amount of damage added
;   [wCoinTossTotalNum]: number of flipped coins
;   [wCoinTossNumHeads]: number of flipped heads
;   [wCoinTossNumTails]: number of flipped tails
Plus10DamageIfHeads_DamageBoostEffect:
  ld a, 1  ; coin flips
  ; fallthrough


; input:
;   a: number of coins to flip
; outputs:
;   a: amount of damage added
;   [wCoinTossTotalNum]: number of flipped coins
;   [wCoinTossNumHeads]: number of flipped heads
;   [wCoinTossNumTails]: number of flipped tails
Plus10DamagePerHeads_DamageBoostEffect:
  ld hl, 10
  call Plus10DamagePerHeads_TossCoins
  jp AddToDamage


; input:
;   a: number of coins to flip
;   hl: amount of damage to add per heads (display)
; outputs:
;   a: amount of bonus damage to add (heads x 10)
;   [wCoinTossTotalNum]: number of flipped coins
;   [wCoinTossNumHeads]: number of flipped heads
;   [wCoinTossNumTails]: number of flipped tails
; preserves: hl
Plus10DamagePerHeads_TossCoins:
  ld e, a  ; store number of coins
  call LoadTxRam3  ; preserves hl, de
  ld a, e
  ldtx de, DamageCheckIfHeadsPlusDamageText
  call TossACoins
  jp ATimes10


; input:
;   a: number of coins to flip
; outputs:
;   a: amount of damage added
;   [wCoinTossTotalNum]: number of flipped coins
;   [wCoinTossNumHeads]: number of flipped heads
;   [wCoinTossNumTails]: number of flipped tails
X10DamagePerHeads_MultiplierEffect:
  ld hl, 10
  call X10DamagePerHeads_TossCoins
  jp SetDefiniteDamage


; input:
;   a: number of coins to flip
;   hl: amount of damage per heads
; outputs:
;   a: amount of damage to set (heads x 10)
;   [wCoinTossTotalNum]: number of flipped coins
;   [wCoinTossNumHeads]: number of flipped heads
;   [wCoinTossNumTails]: number of flipped tails
; preserves: hl
X10DamagePerHeads_TossCoins:
  ld e, a  ; store number of coins
  call LoadTxRam3  ; preserves hl, de
  ld a, e
  ldtx de, DamageCheckIfHeadsXDamageText
  call TossACoins
  jp ATimes10



;
DoubleAttackX20X10_AIEffect:
	ld a, (15 * 2)
	lb de, 20, 40
	jp SetExpectedAIDamage

DoubleAttackX20X10_MultiplierEffect:
  ld a, 2
  ld hl, 20
  call X10DamagePerHeads_TossCoins
; tails = 10, heads = 20
; result = (10 * tails) + (20 * heads)
; result = (10 * coins) + (10 * heads)
; a = 10 * heads
  add 20
  jp SetDefiniteDamage


Heads10BonusDamage_DamageBoostEffect:
	ld hl, 10
	call LoadTxRam3
	ldtx de, DamageCheckIfHeadsPlusDamageText
	call TossCoin_BankB
	ret nc ; return if tails
	ld a, 10
	jp AddToDamage


CometPunch_AIEffect:
	ld a, (30 + 40) / 2
	lb de, 30, 40
	jp SetExpectedAIDamage

Heads20Plus10Damage_AIEffect:
	ld a, (20 + 10) / 2
	lb de, 20, 30
	jp SetExpectedAIDamage


;
StoneBarrage_AIEffect: ; 2e04a (b:604a)
	ld a, 10
	lb de, 0, 100
	jp SetExpectedAIDamage

StoneBarrage_MultiplierEffect: ; 2e052 (b:6052)
	xor a
	ldh [hTemp_ffa0], a
.loop_coin_toss
	ldtx de, FlipUntilFailAppears10DamageForEachHeadsText
	xor a
	call TossCoinATimes_BankB
	jr nc, .tails
	ld hl, hTemp_ffa0
	inc [hl] ; increase heads count
	jr .loop_coin_toss

.tails
; store resulting damage
	ldh a, [hTemp_ffa0]
	ld l, a
	ld h, 10
	call HtimesL
; cap damage at 250
	; ld de, wDamage
	; ld a, l
	; ld [de], a
	; inc de
	; ld a, h
	; ld [de], a
	ld a, l
	ld [wDamage], a
	ld a, h
	or a
	ret z  ; no overflow
	ld a, MAX_DAMAGE
	ld [wDamage], a
	ret


; ------------------------------------------------------------------------------
; Based on Energy Cards
; ------------------------------------------------------------------------------


; 10 extra damage for each Water Energy
HydroPumpEffect:
  call GetNumAttachedWaterEnergy
	call ATimes10
	call AddToDamage ; add 10 * a to damage
; set attack damage
	jp SetDefiniteAIDamage


; 10 damage for each Water Energy
WaterGunEffect:
  call GetNumAttachedWaterEnergy
	call ATimes10
	call SetDefiniteDamage ; damage = 10 * Water Energy
; set attack damage
	jp SetDefiniteAIDamage


;
DragonRage_DamageBoostEffect:
	xor a  ; PLAY_AREA_ARENA
	ld e, a
	call GetPlayAreaCardAttachedEnergies
	call HandleEnergyBurn

; count how many types of Energy there are (colorless does not count)
	ld b, 0
	ld c, NUM_TYPES - 1
	ld hl, wAttachedEnergies
.loop
	ld a, [hli]
	or a
	jr z, .next
	inc b
.next
	dec c
	jr nz, .loop
	ld a, b
	call ATimes10
	jp AddToDamage

DragonRage_AIEffect:
	call DragonRage_DamageBoostEffect
	jp SetDefiniteAIDamage


SpeedImpact_DamageSubtractionEffect:
	xor a  ; PLAY_AREA_ARENA
	ld e, a
	call SwapTurn
	call GetPlayAreaCardAttachedEnergies
	call SwapTurn
	ld a, [wTotalAttachedEnergies]
	or a
	ret z
	call ATimes10
	add a  ; x20
	jp SubtractFromDamageCapZero

SpeedImpact_AIEffect:
	call SpeedImpact_DamageSubtractionEffect
	jp SetDefiniteAIDamage


SneakAttack_DamageBoostEffect:
	xor a  ; PLAY_AREA_ARENA
	call CheckIfCardHasDarknessEnergyAttached
	jr c, .done
	ld a, 10
	jp AddToDamage
.done
	or a
	ret

SneakAttack_AIEffect:
	call SneakAttack_DamageBoostEffect
	jp SetDefiniteAIDamage



; +10 damage if any Pokémon in opponent's Play Area has any
; Darkness Energy attached.
PunishingSlap_DamageBoostEffect:
	call SwapTurn
  ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
  call GetTurnDuelistVariable
  ld d, a
  ld e, PLAY_AREA_ARENA
.loop_play_area
  ld a, e
  push de
  call CheckIfCardHasDarknessEnergyAttached
  pop de
  jr nc, .bonus
  inc e
  dec d
  jr nz, .loop_play_area
	jp SwapTurn

.bonus
  call SwapTurn
  ld a, 10
  jp AddToDamage

PunishingSlap_AIEffect:
  call PunishingSlap_DamageBoostEffect
  jp SetDefiniteAIDamage


Psychic_DamageBoostEffect:
	call GetEnergyAttachedMultiplierDamage
	ld hl, wDamage
	ld a, e
	add [hl]
; cap damage at 250
	; ld [hli], a
	; ld a, d
	; adc [hl]
	ld [hl], a
	ret nc  ; no overflow
	ld a, MAX_DAMAGE
	ld [hl], a
	ret
	
Psychic_AIEffect:
	call Psychic_DamageBoostEffect
	jp SetDefiniteAIDamage


; output in de the number of energy cards
; attached to the Defending Pokemon times 10.
; used for attacks that deal 10x number of energy
; cards attached to the Defending card.
GetEnergyAttachedMultiplierDamage:
	call SwapTurn
	ld a, DUELVARS_CARD_LOCATIONS
	call GetTurnDuelistVariable

	ld c, 0
.loop
	ld a, [hl]
	cp CARD_LOCATION_ARENA
	jr nz, .next
	; is in Arena
	ld a, l
	call GetCardIDFromDeckIndex
	call GetCardType
	and TYPE_ENERGY
	jr z, .next
	; is Energy attached to Arena card
	inc c
.next
	inc l
	ld a, l
	cp DECK_SIZE
	jr c, .loop

	call SwapTurn
	ld l, c
	ld h, $00
	ld b, $00
	add hl, hl ; hl =  2 * c
	add hl, hl ; hl =  4 * c
	add hl, bc ; hl =  5 * c
	add hl, hl ; hl = 10 * c
; cap damage at 250
	; ld d, h
	ld d, 0
	ld e, l
	ld a, h
	or a
	ret z
	ld e, MAX_DAMAGE
	ret


;
TropicalStorm_DamageBoostEffect:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld d, a
	ld e, PLAY_AREA_ARENA
	ld c, 0

; go through every Pokemon in the Play Area and boost damage based on energy
.loop_play_area
; check its attached energies
	call GetPlayAreaCardAttachedEnergies
	ld a, [wTotalAttachedEnergies]
	or a
	jr z, .next_pkmn
	inc c
.next_pkmn
	inc e
	dec d
	jr nz, .loop_play_area
	ld a, c
	or a
	ret z  ; done if zero
	rla            ; a = a * 2
	call ATimes10  ; a = a * 10
	jp SetDefiniteDamage  ; a == c * 20

TropicalStorm_AIEffect:
	call TropicalStorm_DamageBoostEffect
	jp SetDefiniteAIDamage



; Deal 10 damage for each energy attached to both Active Pokémon.
; cap at 200 damage
DamagePerEnergyAttachedToBothActive_MultiplierEffect:
; get energies attached to self
	ld e, PLAY_AREA_ARENA
	call GetPlayAreaCardAttachedEnergies
	ld a, [wTotalAttachedEnergies]
	ld d, a
; get energies attached to opponent
	call SwapTurn
	call GetPlayAreaCardAttachedEnergies
	call SwapTurn
	ld a, [wTotalAttachedEnergies]
; add both
	add d
	jr c, .cap  ; overflow
; cap if number of energies >= 20
	cp 21
	jr c, .got_energies
.cap
	ld a, 20
.got_energies
	call ATimes10
	jp SetDefiniteDamage

DamagePerEnergyAttachedToBothActive_AIEffect:
	call DamagePerEnergyAttachedToBothActive_MultiplierEffect
	jp SetDefiniteAIDamage


; +20 for each selected energy to retrieve from discard
Riptide_DamageBoostEffect:
	ld c, 0
	ld hl, hTempList
.loop_cards
	ld a, [hli]
	cp $ff
	jr z, .done
	ld a, 20
	add c
	ld c, a
	jr .loop_cards
.done
	ld a, c
	or a
	ret z
	jp AddToDamage

Riptide_AIEffect:
	call CreateEnergyCardListFromDiscardPile_OnlyBasic
	call CountCardsInDuelTempList
	cp 2
	jr c, .cap
	ld a, 2
.cap
	call ATimes10
	call AddToDamage
	jp SetDefiniteAIDamage


DoubleDamageIfAttachedEnergy_DamageBoostEffect:
	ld a, [wAlreadyPlayedEnergyOrSupporter]
	and PLAYED_ENERGY_THIS_TURN
	jp nz, DoubleDamage_DamageBoostEffect  ; played energy
	ld a, [wAlreadyPlayedEnergyOrSupporter]
	and USED_RAIN_DANCE_THIS_TURN
	ret z  ; did not play energy
	jp DoubleDamage_DamageBoostEffect

DoubleDamageIfAttachedEnergy_AIEffect:
	call DoubleDamageIfAttachedEnergy_DamageBoostEffect
	jp SetDefiniteAIDamage


; ------------------------------------------------------------------------------
; Based on Hand Cards
; ------------------------------------------------------------------------------


; +20 damage if the player has at least 5 cards in hand
Meditate_DamageBoostEffect:
  ld c, 5
	call CheckHandSizeIsLessThanC
	ret nc  ; hand size < 5
	ld a, 20
	jp AddToDamage

Meditate_AIEffect:
  call Meditate_DamageBoostEffect
  jp SetDefiniteAIDamage


; +20 damage if the opponent has at least 5 cards in hand
Psyshock_DamageBoostEffect:
  ld c, 5
  call SwapTurn
	call CheckHandSizeIsLessThanC
  call SwapTurn
	ret nc  ; hand size < 5
	ld a, 20
	jp AddToDamage

Psyshock_AIEffect:
  call Psyshock_DamageBoostEffect
  jp SetDefiniteAIDamage


; +10 damage for each card in turn holder's hand
MegaMind_DamageBoostEffect:
  ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	call GetTurnDuelistVariable
	call ATimes10
	jp AddToDamage

MegaMind_AIEffect:
  call MegaMind_DamageBoostEffect
  jp SetDefiniteAIDamage


; 20 damage for each card in opponent's hand
MindBlast_DamageBoostEffect:
  ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	call GetNonTurnDuelistVariable
	call ATimes10
  add a  ; double
	jp SetDefiniteDamage

MindBlast_AIEffect:
  call MindBlast_DamageBoostEffect
  jp SetDefiniteAIDamage


; +damage if player's hand is greater than opponent's
HandPress_DamageBoostEffect:
  call CheckHandSizeGreaterThanOpponents
  ret c
	ld a, 20
	jp AddToDamage

HandPress_AIEffect:
  call HandPress_DamageBoostEffect
  jp SetDefiniteAIDamage


; +10 damage for each Trainer card in opponent's hand
InvadeMind_DamageBoostEffect:
  call SwapTurn
  call CreateHandCardList
  jp c, SwapTurn  ; no cards, early return

  ld c, 0
  ld hl, wDuelTempList
.loop
  ld a, [hli]
  cp $ff  ; terminating byte
  jr z, .tally
  call GetCardIDFromDeckIndex
  call GetCardType
; only count Trainer cards
  cp TYPE_TRAINER
  jr c, .loop
  inc c
  jr .loop

.tally
  call SwapTurn  ; restore turn order
	ld a, c
  call ATimes10
	jp AddToDamage

InvadeMind_AIEffect:
  call InvadeMind_DamageBoostEffect
  jp SetDefiniteAIDamage


; ------------------------------------------------------------------------------
; Based on Prize Cards
; ------------------------------------------------------------------------------


; double damage if the opponent has less Prize cards than the user
RagingStorm_DamageBoostEffect:
	call CheckOpponentHasMorePrizeCardsRemaining
	ret nc  ; opponent Prizes >= user Prizes
	jp DoubleDamage_DamageBoostEffect

RagingStorm_AIEffect:
  call RagingStorm_DamageBoostEffect
  jp SetDefiniteAIDamage


; ------------------------------------------------------------------------------
; Based on Discard Pile
; ------------------------------------------------------------------------------

; +10 damage per Pokémon in discard pile (up to 5)
Vengeance_DamageBoostEffect:
	call CreatePokemonCardListFromDiscardPile
	ret c  ; return if there are no Pokémon in discard pile
  ld a, c
  cp 5
  jr c, .cap
  ld a, 5
.cap
	call ATimes10
	jp AddToDamage

Vengeance_AIEffect:
	call Vengeance_DamageBoostEffect
	jp SetDefiniteAIDamage


; ------------------------------------------------------------------------------
; Based on Play Area
; ------------------------------------------------------------------------------


DoTheWave_DamageBoostEffect:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	dec a ; don't count arena card
	call ATimes10
	jp AddToDamage

DoTheWave_AIEffect:
  call DoTheWave_DamageBoostEffect
  jp SetDefiniteAIDamage


Swarm_DamageBoostEffect:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
  cp 5
	ret c  ; nothing to do
  ld a, 20
	jp AddToDamage

Swarm_AIEffect:
  call Swarm_DamageBoostEffect
  jp SetDefiniteAIDamage


; 10 damage for each (C) in the retreat costs of the turn holder's Pokémon
Avalanche_DamageBoostEffect:
  ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
  call GetTurnDuelistVariable
  ld d, a
  ld e, PLAY_AREA_ARENA
  ld c, 0
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld b, a

; go through every Pokémon in the Play Area and boost damage based on retreat cost
.loop_play_area
; check its retreat cost
	ld a, e
	ldh [hTempPlayAreaLocation_ff9d], a
	push bc
	push de
	call GetPlayAreaCardRetreatCost
	pop de
	pop bc
; add to total and store
	add c
	ld c, a
; next Pokémon
  inc e
  dec d
  jr nz, .loop_play_area
; restore backed up variables
	ld a, b
	ldh [hTempPlayAreaLocation_ff9d], a
; tally damage boost
  ld a, c
  or a
  ret z  ; done if zero
  call ATimes10
  jp SetDefiniteDamage

Avalanche_AIEffect:
  call Avalanche_DamageBoostEffect
  jp SetDefiniteAIDamage


; +20 damage for each Evolved Pokémon in Bench
PowerLariat_DamageBoostEffect:
  ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
  call GetTurnDuelistVariable
  dec a
  ret z  ; no Benched Pokémon
  ld d, a
  ld e, PLAY_AREA_BENCH_1
  ld c, 0

; go through every Pokemon in the Play Area and boost damage based on Stage
.loop_play_area
; check its Stage
  ld a, DUELVARS_ARENA_CARD_STAGE
  add e
  call GetTurnDuelistVariable
  or a
  jr z, .next_pkmn  ; it's a BASIC Pokémon
  inc c
.next_pkmn
  inc e
  dec d
  jr nz, .loop_play_area
; tally damage boost
  ld a, c
  or a
  ret z  ; done if zero
  rla            ; a = a * 2
  call ATimes10  ; a = a * 10
  jp SetDefiniteDamage  ; a == c * 20

PowerLariat_AIEffect:
  call PowerLariat_DamageBoostEffect
  jp SetDefiniteAIDamage


; +10 damage for each Nidoran on Bench
; +20 damage for each Nidorina or Nidorino on Bench
; +30 damage for each Nidoqueen or Nidoking on Bench
FamilyPower_DamageBoostEffect:
	ld a, DUELVARS_BENCH
	call GetTurnDuelistVariable
	ld c, 0
.loop
	ld a, [hli]
	cp $ff
	jr z, .done
	call GetCardIDFromDeckIndex
	ld a, e
  cp NIDORANF
	jr z, .plus_10
  cp NIDORANM
	jr z, .plus_10
	cp NIDORINA
	jr z, .plus_20
	cp NIDORINO
	jr z, .plus_20
	cp NIDOQUEEN
	jr z, .plus_30
	cp NIDOKING
	jr nz, .loop  ; not a Nidoran family card
.plus_30
  inc c
.plus_20
  inc c
.plus_10
	inc c
	jr .loop
.done
; c holds number of Nidoran family bonus found in Play Area
	ld a, c
	call ATimes10
	jp AddToDamage

FamilyPower_AIEffect:
  call FamilyPower_DamageBoostEffect
  jp SetDefiniteAIDamage


; +10 damage for each of the opponent's Benched Pokémon
Rout_DamageBoostEffect:
  ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
  call GetNonTurnDuelistVariable
  dec a  ; don't count arena card
  call ATimes10
  jp AddToDamage

Rout_AIEffect:
  call Rout_DamageBoostEffect
  jp SetDefiniteAIDamage


; +20 damage for each of the opponent's Pokémon with a Pokémon Power
TerrorStrike_DamageBoostEffect:
  call SwapTurn
  ld a, DUELVARS_ARENA_CARD
  call GetTurnDuelistVariable
  ld c, 0
.loop_play_area
  ld a, [hli]
  cp $ff
  jr z, .done
  call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Atk1Category]
	cp POKEMON_POWER
  jr nz, .loop_play_area
  inc c
  jr .loop_play_area
.done
  call SwapTurn
  ld a, c
  add a  ; x20
  call ATimes10
  jp AddToDamage

TerrorStrike_AIEffect:
  call TerrorStrike_DamageBoostEffect
  jp SetDefiniteAIDamage


; ------------------------------------------------------------------------------
; Based on Defending Pokémon
; ------------------------------------------------------------------------------


; +40 damage versus Basic Pokémon
Crabhammer_DamageBoostEffect:
	ld a, DUELVARS_ARENA_CARD_STAGE
	call GetNonTurnDuelistVariable
	and a
	ret nz  ; not a BASIC Pokémon
	ld a, 40
	jp AddToDamage

Crabhammer_AIEffect:
  call Crabhammer_DamageBoostEffect
  jp SetDefiniteAIDamage


; +30 damage versus Evolved Pokémon
SharpSickle_DamageBoostEffect:
	ld a, DUELVARS_ARENA_CARD_STAGE
	call GetNonTurnDuelistVariable
	and a
	ret z  ; BASIC Pokémon
	ld a, 30
	jp AddToDamage

SharpSickle_AIEffect:
  call SharpSickle_DamageBoostEffect
  jp SetDefiniteAIDamage


;
Peck_DamageBoostEffect:
	ld a, 10
	call SetDefiniteDamage
	call SwapTurn
	call GetArenaCardColor
	call SwapTurn
	cp GRASS
	ret nz ; no extra damage if not Grass
	ld a, 10
	call AddToDamage
	ret

Peck_AIEffect:
	call Peck_DamageBoostEffect
	jp SetDefiniteAIDamage


; return in a 10x damage per Energy in the Opponent's Retreat Cost.
_DamagePerOpponentRetreatCost:
	call SwapTurn
	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ff9d], a
	call GetPlayAreaCardRetreatCost  ; retreat cost in a
	call SwapTurn
	jp ATimes10


; +10 damage per retreat cost of opponent
Constrict_DamageBoostEffect:
	call _DamagePerOpponentRetreatCost
	jp AddToDamage

; this runs before applying the retreat cost increase, so add 10
Constrict_AIEffect:
	call _DamagePerOpponentRetreatCost
	add 10
	call AddToDamage
	jp SetDefiniteAIDamage


; +20 damage per retreat cost of opponent
GrassKnot_DamageBoostEffect:
	call SwapTurn
	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ff9d], a
	call GetPlayAreaCardRetreatCost  ; retreat cost in a
	call SwapTurn
	add a  ; x20 per retreat cost
	call ATimes10
	jp AddToDamage

GrassKnot_AIEffect:
	call GrassKnot_DamageBoostEffect
	jp SetDefiniteAIDamage


; ------------------------------------------------------------------------------
; Based on Status Conditions
; ------------------------------------------------------------------------------

; double damage if the Defending Pokémon has a status condition
Pester_DamageBoostEffect:
  call CheckOpponentHasStatus
  ret c
  jp DoubleDamage_DamageBoostEffect

Pester_AIEffect:
  call Pester_DamageBoostEffect
  jp SetDefiniteAIDamage


; +20 damage if the Defending Pokémon is Poisoned
DeadlyPoison_DamageBoostEffect:
  ld a, DUELVARS_ARENA_CARD_STATUS
  call GetNonTurnDuelistVariable
  and PSN_DBLPSN
  ret z  ; not Poisoned
  ld a, 20
  jp AddToDamage

DeadlyPoison_AIEffect:
  call DeadlyPoison_DamageBoostEffect
  jp SetDefiniteAIDamage


; ------------------------------------------------------------------------------
; Based on Damage Counters
; ------------------------------------------------------------------------------

ChopDown_DamageBoostEffect:
	ld a, DUELVARS_ARENA_CARD_HP
	call GetNonTurnDuelistVariable
	ld e, a
	ld a, DUELVARS_ARENA_CARD_HP
	call GetTurnDuelistVariable
	cp e
	jp c, DoubleDamage_DamageBoostEffect
	ret

ChopDown_AIEffect:
	call ChopDown_DamageBoostEffect
	jp SetDefiniteAIDamage


KarateChop_DamageSubtractionEffect:
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	jp SubtractFromDamageCapZero

KarateChop_AIEffect:
	call KarateChop_DamageSubtractionEffect
	jp SetDefiniteAIDamage


; double damage if user is damaged
DoubleDamageIfUserIsDamaged_DamageBoostEffect:
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
  or a
  ret z  ; not damaged
	jp DoubleDamage_DamageBoostEffect

DoubleDamageIfUserIsDamaged_AIEffect:
  call DoubleDamageIfUserIsDamaged_DamageBoostEffect
  jp SetDefiniteAIDamage


; add damage taken to damage output
FlamesOfRage_DamageBoostEffect:
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	jp AddToDamage

FlamesOfRage_AIEffect:
  call FlamesOfRage_DamageBoostEffect
  jp SetDefiniteAIDamage


; set damage output equal to damage taken
Flail_HPCheck:
  ld e, PLAY_AREA_ARENA
  call GetCardDamageAndMaxHP
  jp SetDefiniteDamage

Flail_AIEffect:
	call Flail_HPCheck
	jp SetDefiniteAIDamage


; add damage of Defending card to damage output
PsychicAssault_DamageBoostEffect:
	call SwapTurn
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	call SwapTurn
	jp AddToDamage

PsychicAssault_AIEffect:
  call PsychicAssault_DamageBoostEffect
  jp SetDefiniteAIDamage


; +10 damage for each damaged Pokémon on turn holder's play area
VengefulHorn_DamageBoostEffect:
  ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
  call GetTurnDuelistVariable
  ld d, a
  ld e, PLAY_AREA_ARENA
  ld c, 0
.loop_play_area
  ; input in e
  push bc
  call GetCardDamageAndMaxHP
  pop bc
  or a
  jr z, .next_pkmn  ; no damage
  inc c
.next_pkmn
  inc e
  dec d
  jr nz, .loop_play_area
; tally damage boost
  ld a, c
  call ATimes10
  jp AddToDamage

VengefulHorn_AIEffect:
  call VengefulHorn_DamageBoostEffect
  jp SetDefiniteAIDamage

; ------------------------------------------------------------------------------
; Miscellaneous
; ------------------------------------------------------------------------------


; double damage if some stored value is true
DoubleDamageIfCondition_DamageBoostEffect:
	ldh a, [hTemp_ffa0]
	or a
	ret z
	jp DoubleDamage_DamageBoostEffect

DoubleDamageIfCondition_AIEffect:
	ld a, [wDamage]
	ld d, a  ; min damage
	add a
	ld e, a  ; max damage
	ld a, d
	; srl a
	; add d    ; avg damage
	jp SetExpectedAIDamage


; bonus damage if the Pokémon became Active this turn
IfActiveThisTurn20BonusDamage_DamageBoostEffect:
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS3
	call GetTurnDuelistVariable
	bit SUBSTATUS3_THIS_TURN_ACTIVE, a
	ret z  ; did not move to active spot this turn
	ld a, 20
	jp AddToDamage

IfActiveThisTurn20BonusDamage_AIEffect:
  call IfActiveThisTurn20BonusDamage_DamageBoostEffect
  jp SetDefiniteAIDamage


; bonus damage if the Pokémon became Active this turn
IfActiveThisTurnDoubleDamage_DamageBoostEffect:
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS3
	call GetTurnDuelistVariable
	bit SUBSTATUS3_THIS_TURN_ACTIVE, a
	ret z  ; did not move to active spot this turn
	jp DoubleDamage_DamageBoostEffect

IfActiveThisTurnDoubleDamage_AIEffect:
  call IfActiveThisTurnDoubleDamage_DamageBoostEffect
  jp SetDefiniteAIDamage


Rototiller_DamageBoostEffect:
	xor a
	call SetDefiniteDamage
	ld hl, hTempList
.loop
	ld a, [hli]
	cp $ff
	jr z, .check_damage
	call .BoostIfPokemonOrEnergy
	jr .loop
; switch animation if this attack deals damage
.check_damage
	ld a, [wDamage]
	or a
	ret z
	ld a, ATK_ANIM_HIT
	ld [wLoadedAttackAnimation], a
	ret

; input:
;   a: deck index of selected card
.BoostIfPokemonOrEnergy:
	call GetCardIDFromDeckIndex  ; preserves af, hl, bc
	call GetCardType  ; preserves hl, bc
	cp TYPE_TRAINER
	ret nc
; Pokémon or Energy card
	ld a, 10
	jp AddToDamage  ; preserves hl


Rototiller_AIEffect:
	call CreateEnergyCardListFromDiscardPile_AllEnergy
	jr nc, .damage
	call CreatePokemonCardListFromDiscardPile
	jr nc, .damage
; no damage
	xor a
	lb de, 0, 0
	jp SetExpectedAIDamage
.damage
	ld a, 20
	lb de, 10, 30
	jp SetExpectedAIDamage
