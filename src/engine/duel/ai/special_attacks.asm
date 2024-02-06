; this function handles attacks with the SPECIAL_AI_HANDLING set,
; and makes specific checks in each of these attacks
; to either return a positive score (value above $80)
; or a negative score (value below $80).
; input:
;	hTempPlayAreaLocation_ff9d = location of card with attack.
HandleSpecialAIAttacks:
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call GetCardIDFromDeckIndex
	ld a, e

	cp ABRA
	jp z, .Collect
	cp STARYU
	jp z, .Staryu
	cp SCYTHER
	jp z, .SwordsDanceAndFocusEnergy
	cp MAGNETON_LV28
	jp z, .ChainLightning
	cp MEW_LV23
	jp z, .DevolutionBeam
	; cp PORYGON
	; jp z, .Conversion
	cp GEODUDE
	jp z, .Mend
	cp MEWTWO_LV60
	jp z, .EnergyAbsorption
	cp BELLSPROUT
	jp z, .Growth
	cp ZAPDOS_LV68
	jp z, .BigThunder
	cp GROWLITHE
	jp z, .Collect
	cp PIKACHU_LV14
	jp z, .Collect
	cp MEOWTH_LV14
	jp z, .Collect
	cp PIDGEY
	jp z, .Collect
	cp DUGTRIO
	jp z, .Earthquake
	cp RHYDON
	jp z, .Earthquake
	cp MAGNETON_LV35
	jp z, .EnergySpike
	cp DRAGONITE_LV45
	jp z, .EnergySpike
	cp EXEGGCUTE
	jp z, .EnergySpike
	cp TANGELA_LV12
	jp z, .EnergySpike
	cp DRATINI
	jp z, .DragonDance
	cp HORSEA
	jp z, .DragonDance
	cp PARASECT
	jp z, .EnergySpores
	cp DRAGONAIR
	jp z, .HyperBeam
	cp WEEPINBELL
	jp z, .HyperBeam
	cp NINETALES_LV35
	jp z, .HyperBeam
	cp NIDORANF
	jr z, .CallForFamily
	cp KANGASKHAN
	jr z, .CallForFamily
	cp JIGGLYPUFF_LV13
	jr z, .CallForFamily
	cp ODDISH
	jr z, .Sprout
	cp MOLTRES_LV35
	jp z, .CollectFire
	cp JYNX
	jr z, .Mimic
	cp CLEFAIRY
	jr z, .Mimic
	cp CLEFABLE
	jr z, .LunarPower
	cp SPEAROW
	jr z, .DevastatingWind
	cp GASTLY_LV17
	jp z, .EnergyConversion
	cp DEWGONG
	jr z, .Teleport
	cp SANDSLASH
	jr z, .Teleport
	cp MACHOP
	jr z, .Teleport
	cp MANKEY
	jp z, .Prank
	cp PRIMEAPE
	jp z, .GetMad

; return zero score.
.zero_score
	xor a
	ret

.LunarPower
	farcall AIDecide_PokemonBreeder
	jr nc, .zero_score
	ld a, $83
	ret

.Mimic
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	call GetNonTurnDuelistVariable
	ld c, a
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	call GetTurnDuelistVariable
	cp c
	jr nc, .zero_score
	ld a, $82
	ret

.DevastatingWind
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	call GetNonTurnDuelistVariable
	sub 5
	jr c, .zero_score
	; +1 score for each card above 5
	add $80
	ret

.Staryu
	ld a, [wSelectedAttack]
	or a
	jp z, .Collect
	jr .Teleport

; if any basic cards are found in deck,
; return a score of $80 + slots available in bench.
.CallForFamily:
	call CheckIfAnyBasicPokemonInDeck
	jr nc, .zero_score
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	cp MAX_PLAY_AREA_POKEMON
	jr nc, .zero_score
	ld b, a
	ld a, MAX_PLAY_AREA_POKEMON
	sub b
	add $80
	ret

; if any Grass cards are found in deck,
; return a score of $80 + 2.
.Sprout:
	call CheckIfAnyGrassCardInDeck
	jr nc, .zero_score
	ld a, $82
	ret

; if AI decides to retreat, return a score of $80 + 10.
.Teleport:
	call AIDecideWhetherToRetreat
	jp nc, .zero_score
	ld a, $8a
	ret

; tests for the following conditions:
; - player is under No Damage substatus;
; - second attack is unusable;
; - second attack deals no damage;
; if any are true, returns score of $80 + 5.
.SwordsDanceAndFocusEnergy:
	ld a, [wAICannotDamage]
	or a
	jr nz, .swords_dance_focus_energy_success
	ld a, SECOND_ATTACK
	ld [wSelectedAttack], a
	call CheckIfSelectedAttackIsUnusable
	jr c, .swords_dance_focus_energy_success
	ld a, SECOND_ATTACK
	call EstimateDamage_VersusDefendingCard
	ld a, [wDamage]
	or a
	jp nz, .zero_score
.swords_dance_focus_energy_success
	ld a, $85
	ret

; checks player's active card color, then
; loops through bench looking for a Pokémon
; with that same color.
; if none are found, returns score of $80 + 2.
.ChainLightning:
	call SwapTurn
	call GetArenaCardColor
	call SwapTurn
	ld b, a
	ld a, DUELVARS_BENCH
	call GetTurnDuelistVariable
.loop_chain_lightning_bench
	ld a, [hli]
	cp $ff
	jr z, .chain_lightning_success
	push bc
	call GetCardIDFromDeckIndex
	call GetCardType
	pop bc
	cp b
	jr nz, .loop_chain_lightning_bench
	jp .zero_score
.chain_lightning_success
	ld a, $82
	ret

.DevolutionBeam:
	call LookForCardThatIsKnockedOutOnDevolution
	jp nc, .zero_score
	ld a, $85
	ret

; first checks if card is confused, and if so return 0.
; then checks number of Pokémon in bench that are viable to use:
; - if that number is < 2  and this attack is Conversion 1 OR
; - if that number is >= 2 and this attack is Conversion 2
; then return score of $80 + 2.
; otherwise return score of $80 + 1.
.Conversion:
	ld a, DUELVARS_ARENA_CARD_STATUS
	call GetTurnDuelistVariable
	and CNF_SLP_PRZ
	cp CONFUSED
	jp z, .zero_score

	ld a, [wSelectedAttack]
	or a
	jr nz, .conversion_2

; conversion 1
	call CountNumberOfSetUpBenchPokemon
	cp 2
	jr c, .low_conversion_score
	ld a, $82
	ret

.conversion_2
	call CountNumberOfSetUpBenchPokemon
	cp 2
	jr nc, .low_conversion_score
	ld a, $82
	ret

.low_conversion_score
	ld a, $81
	ret

; if any Psychic Energy is found in the Discard Pile,
; return a score of $80 + 2.
.EnergyAbsorption:
	ld e, PSYCHIC_ENERGY
	ld a, CARD_LOCATION_DISCARD_PILE
	call CheckIfAnyCardIDinLocation
	jp nc, .zero_score
	ld a, $82
	ret

.Mend:
	call GetPlayAreaCardAttachedEnergies
	ld a, [wTotalAttachedEnergies]
	cp 3
	jp nc, .zero_score
	ld e, FIGHTING_ENERGY
	ld a, CARD_LOCATION_DISCARD_PILE
	call CheckIfAnyCardIDinLocation
	ret nc
	ld a, $82
	ret

.CollectFire:
	ld e, FIRE_ENERGY
	ld a, CARD_LOCATION_DISCARD_PILE
	call CheckIfAnyCardIDinLocation
	jp nc, .zero_score
	call GetPlayAreaCardAttachedEnergies
	ld a, [wTotalAttachedEnergies]
	cp 3
	jp nc, .zero_score
	ld a, $83
	ret

.EnergyConversion:
	ld a, CARD_LOCATION_DISCARD_PILE
	call CheckIfAnyBasicEnergyInLocation
	jp nc, .zero_score
	ld a, $82
	ret

; if the Pokémon has less than 2 Energies attached to it,
; return a score of $80 + 3.
.Growth:
	call CreateEnergyCardListFromHand
	jp c, .zero_score
	call GetPlayAreaCardAttachedEnergies
	ld a, [wTotalAttachedEnergies]
	cp 2
	jp nc, .zero_score
	ld a, $83
	ret

; return score of $80 + 3.
.BigThunder:
	ld a, $83
	ret

; dismiss attack if cards in deck <= 15.
; otherwise return a score of $80 + 2 if number of cards in hand is less than 4.
.Collect:
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	call GetTurnDuelistVariable
	cp 46
	jp nc, .zero_score
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	call GetTurnDuelistVariable
	cp 4
	ld a, $82
	ret c
	ld a, $80
	ret

; dismiss attack if number of own benched cards which would
; be KOd is greater than or equal to the number
; of prize cards left for player.
.Earthquake:
	ld a, DUELVARS_BENCH
	call GetTurnDuelistVariable

	lb de, 0, 0
.loop_earthquake
	inc e
	ld a, [hli]
	cp $ff
	jr z, .count_prizes
	ld a, e
	add DUELVARS_ARENA_CARD_HP
	call GetTurnDuelistVariable
	cp 20
	jr nc, .loop_earthquake
	inc d
	jr .loop_earthquake

.count_prizes
	push de
	call CountPrizes
	pop de
	cp d
	jp c, .zero_score
	jp z, .zero_score
	ld a, $80
	ret

; if there's any lightning energy cards in deck,
; return a score of $80 + 3.
.EnergySpike:
	ld a, CARD_LOCATION_DECK
	call CheckIfAnyBasicEnergyInLocation
	jp nc, .zero_score
	call AIProcessButDontPlayEnergy_SkipEvolution
	jp nc, .zero_score
; preserve selected Pokémon card for the effect logic
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTempPlayAreaLocation_ffa1], a
	ld a, $83
	ret

; if there's any energy cards in hand,
; return a score of $80 + 3.
.DragonDance:
	call CreateEnergyCardListFromHand
	jp c, .zero_score
	call AIProcessButDontPlayEnergy_SkipEvolution
	jp nc, .zero_score
	ld a, $83
	ret

.EnergySpores:
	ld a, CARD_LOCATION_DISCARD_PILE
	ld e, GRASS_ENERGY
	call CheckIfAnyCardIDinLocation
	jp nc, .zero_score
	call AIProcessButDontPlayEnergy_SkipEvolution
	jp nc, .zero_score
	ld a, $83
	ret

; only incentivize attack if player's active card,
; has any energy cards attached, and if so,
; return a score of $80 + 3.
.HyperBeam:
	call SwapTurn
	ld e, PLAY_AREA_ARENA
	call CountNumberOfEnergyCardsAttached
	call SwapTurn
	or a
	jr z, .hyper_beam_neutral
	ld a, $83
	ret
.hyper_beam_neutral
	ld a, $80
	ret

.Prank:
	call SwapTurn
	call CreateEnergyCardListFromDiscardPile_OnlyBasic
	call SwapTurn
	jp c, .zero_score
	ld a, $82
	ret

.GetMad:
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	or a
	jp nz, .zero_score  ; return if Arena card has damage counters
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	cp 2
	jp c, .zero_score  ; return if no Benched Pokémon
	dec a
	ld d, a
	ld e, PLAY_AREA_BENCH_1
.get_mad_loop
	call GetCardDamageAndMaxHP
	cp 40
	ld a, $83
	ret nc  ; at least 40 damage
	inc e
	dec d
	jr nz, .get_mad_loop
	jp .zero_score  ; no Benched Pokémon with at least 40 damage


; called when second attack is determined by AI to have
; more AI score than the first attack, so that it checks
; whether the first attack is a better alternative.
CheckWhetherToSwitchToFirstAttack:
; this checks whether the first attack is also viable
; (has more than minimum score to be used)
	ld a, [wFirstAttackAIScore]
	cp $50
	jr c, .keep_second_attack

; first attack has more than minimum score to be used.
; check if second attack can KO.
; in case it can't, the AI keeps it as the attack to be used.
; (possibly due to the assumption that if the
; second attack cannot KO, the first attack can't KO as well.)
	xor a
	ldh [hTempPlayAreaLocation_ff9d], a
	call EstimateDamage_VersusDefendingCard
	ld a, DUELVARS_ARENA_CARD_HP
	call GetNonTurnDuelistVariable
	ld hl, wDamage
	sub [hl]
	jr z, .check_flag
	jr nc, .keep_second_attack

; second attack can ko, check its flag.
; in case its effect is to heal user or nullify/weaken damage
; next turn, keep second attack as the option.
; otherwise switch to the first attack.
.check_flag
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	ld d, a
	ld e, SECOND_ATTACK
	call CopyAttackDataAndDamage_FromDeckIndex
	ld a, ATTACK_FLAG2_ADDRESS | HEAL_USER_F
	call CheckLoadedAttackFlag
	jr c, .keep_second_attack
	ld a, ATTACK_FLAG2_ADDRESS | NULLIFY_OR_WEAKEN_ATTACK_F
	call CheckLoadedAttackFlag
	jr c, .keep_second_attack
; switch to first attack
	xor a
	ld [wSelectedAttack], a
	ret
.keep_second_attack
	ld a, $01
	ld [wSelectedAttack], a
	ret

; returns carry if there are
; any basic Pokémon cards in deck.
CheckIfAnyBasicPokemonInDeck:
	ld e, 0
.loop
	ld a, DUELVARS_CARD_LOCATIONS
	add e
	call GetTurnDuelistVariable
	cp CARD_LOCATION_DECK
	jr nz, .next
	push de
	ld a, e
	call LoadCardDataToBuffer2_FromDeckIndex
	pop de
	ld a, [wLoadedCard2Type]
	cp TYPE_ENERGY
	jr nc, .next
	ld a, [wLoadedCard2Stage]
	or a
	jr z, .set_carry
.next
	inc e
	ld a, DECK_SIZE
	cp e
	jr nz, .loop
	or a
	ret
.set_carry
	scf
	ret

; returns carry if there are any Grass-type cards in deck.
CheckIfAnyGrassCardInDeck:
	ld e, 0
.loop
	ld a, DUELVARS_CARD_LOCATIONS
	add e
	call GetTurnDuelistVariable
	cp CARD_LOCATION_DECK
	jr nz, .next
	push de
	ld a, e
	call LoadCardDataToBuffer2_FromDeckIndex
	pop de
	ld a, [wLoadedCard2Type]
	cp TYPE_ENERGY_GRASS
	jr z, .set_carry
	cp TYPE_PKMN_GRASS
	jr z, .set_carry
.next
	inc e
	ld a, DECK_SIZE
	cp e
	jr nz, .loop
	or a
	ret
.set_carry
	scf
	ret
