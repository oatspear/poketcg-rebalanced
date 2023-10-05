; handle AI routines for Energy Trans.
; uses AI_ENERGY_TRANS_* constants as input (in a):
;	- AI_ENERGY_TRANS_RETREAT: transfers enough Grass Energy cards to
;	Arena Pokemon for it to be able to pay the Retreat Cost;
;	- AI_ENERGY_TRANS_ATTACK: transfers enough Grass Energy cards to
;	Arena Pokemon for it to be able to use its second attack;
;	- AI_ENERGY_TRANS_TO_BENCH: transfers all Grass Energy cards from
;	Arena Pokemon to Bench in case Arena card will be KO'd.
HandleAIEnergyTrans:
	ld [wAIEnergyTransRoutine], a

; choose to randomly return
	farcall AIChooseRandomlyNotToDoAction
	ret c

	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	dec a
	ret z ; return if no Bench cards

	ld a, IVYSAUR
	call CountPokemonIDInPlayArea
	ret nc ; return if no Ivysaur found in own Play Area

	call ArePokemonPowersDisabled
	ret c ; return if Weezing found in any Play Area

	ld a, [wAIEnergyTransRoutine]
	cp AI_ENERGY_TRANS_RETREAT
	jr z, .check_retreat

	cp AI_ENERGY_TRANS_TO_BENCH
	jp z, AIEnergyTransTransferEnergyToBench

	; AI_ENERGY_TRANS_ATTACK
	call .CheckEnoughGrassEnergyCardsForAttack
	ret nc
	jr .TransferEnergyToArena

.check_retreat
	call .CheckEnoughGrassEnergyCardsForRetreatCost
	ret nc

; use Energy Trans to transfer number of Grass energy cards
; equal to input a from the Bench to the Arena card.
.TransferEnergyToArena
	ld [wAINumberOfEnergyTransCards], a

; look for Ivysaur in Play Area
; so that its PKMN Power can be used.
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	dec a
	ld b, a
.loop_play_area
	ld a, DUELVARS_ARENA_CARD
	add b
	call GetTurnDuelistVariable
	ldh [hTempCardIndex_ff9f], a
	call GetCardIDFromDeckIndex
	ld a, e
	cp IVYSAUR
	jr z, .use_pkmn_power

	ld a, b
	or a
	ret z ; return when finished Play Area loop

	dec b
	jr .loop_play_area

; use Energy Trans Pkmn Power
.use_pkmn_power
	ld a, b
	ldh [hTemp_ffa0], a
	ld a, OPPACTION_USE_PKMN_POWER
	bank1call AIMakeDecision
	ld a, OPPACTION_EXECUTE_PKMN_POWER_EFFECT
	bank1call AIMakeDecision

	xor a ; PLAY_AREA_ARENA
	ldh [hAIEnergyTransPlayAreaLocation], a
	ld a, [wAINumberOfEnergyTransCards]
	ld d, a

; look for Grass energy cards that
; are currently attached to a Bench card.
	ld e, 0
.loop_deck_locations
	ld a, DUELVARS_CARD_LOCATIONS
	add e
	call GetTurnDuelistVariable
	and %00011111
	cp CARD_LOCATION_BENCH_1
	jr c, .next_card

	and %00001111
	ldh [hTempPlayAreaLocation_ffa1], a

	ld a, e
	push de
	call GetCardIDFromDeckIndex
	ld a, e
	pop de
	cp GRASS_ENERGY
	jr nz, .next_card

	; store the deck index of energy card
	ld a, e
	ldh [hAIEnergyTransEnergyCard], a

	push de
	ld d, 30
	call AIDelayFrames_D

	ld a, OPPACTION_6B15
	bank1call AIMakeDecision
	pop de
	dec d
	jr z, .done_transfer

.next_card
	inc e
	ld a, DECK_SIZE
	cp e
	jr nz, .loop_deck_locations

; transfer is done, perform delay
; and return to main scene.
.done_transfer
	ld d, 60
	call AIDelayFrames_D
	ld a, OPPACTION_DUEL_MAIN_SCENE
	bank1call AIMakeDecision
	ret

; checks if the Arena card needs energy for its second attack,
; and if it does, return carry if transferring Grass energy from Bench
; would be enough to use it. Outputs number of energy cards needed in a.
.CheckEnoughGrassEnergyCardsForAttack ; 22246 (8:6246)
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call GetCardIDFromDeckIndex
	ld a, e
	cp EXEGGUTOR
	jr z, .is_exeggutor

	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ff9d], a
	ld a, SECOND_ATTACK
	ld [wSelectedAttack], a
	farcall CheckEnergyNeededForAttack
	jr nc, .attack_false ; return if no energy needed

; check if colorless energy is needed...
	ld a, c
	or a
	jr nz, .count_if_enough

; ...otherwise check if basic energy card is needed
; and it's grass energy.
	ld a, b
	or a
	jr z, .attack_false
	ld a, e
	cp GRASS_ENERGY
	jr nz, .attack_false
	ld c, b
	jr .count_if_enough

.attack_false
	or a
	ret

.count_if_enough
; if there's enough Grass energy cards in Bench
; to satisfy the attack energy cost, return carry.
	push bc
	ld e, GRASS_ENERGY
	call CountCardIDInBench
	pop bc
	cp c
	jr c, .attack_false
	ld a, c
	scf
	ret

.is_exeggutor
; in case it's Exeggutor in Arena, return carry
; if there are any Grass energy cards in Bench.
	ld e, GRASS_ENERGY
	call CountCardIDInBench
	or a
	jr z, .attack_false

	scf
	ret

; returns carry if there are enough Grass energy cards in Bench
; to satisfy the retreat cost of the Arena card.
; if so, output the number of energy cards still needed in a.
.CheckEnoughGrassEnergyCardsForRetreatCost ; 222a9 (8:62a9)
	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ff9d], a
	call GetPlayAreaCardRetreatCost
	ld b, a
	ld e, PLAY_AREA_ARENA
	farcall CountNumberOfEnergyCardsAttached
	cp b
	jr nc, .retreat_false ; return if enough to retreat

; see if there's enough Grass energy cards
; in the Bench to satisfy retreat cost
	ld c, a
	ld a, b
	sub c
	ld c, a
	push bc
	ld e, GRASS_ENERGY
	call CountCardIDInBench
	pop bc
	cp c
	jr c, .retreat_false ; return if less cards than needed

; output number of cards needed to retreat
	ld a, c
	scf
	ret
.retreat_false
	or a
	ret

; AI logic to determine whether to use Energy Trans Pkmn Power
; to transfer energy cards attached from the Arena Pokemon to
; some card in the Bench.
AIEnergyTransTransferEnergyToBench:
	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ff9d], a
	farcall CheckIfDefendingPokemonCanKnockOut
	ret nc ; return if Defending can't KO

; processes attacks and see if any attack would be used by AI.
; if so, return.
	farcall AIProcessButDontUseAttack
	ret c

; return if Arena card has no Grass energy cards attached.
	ld e, PLAY_AREA_ARENA
	call GetPlayAreaCardAttachedEnergies
	ld a, [wAttachedEnergies + GRASS]
	or a
	ret z

; if no energy card attachment is needed, return.
	farcall AIProcessButDontPlayEnergy_SkipEvolutionAndArena
	ret nc

; AI decided that an energy card is needed
; so look for Ivysaur in Play Area
; so that its PKMN Power can be used.
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	dec a
	ld b, a
.loop_play_area
	ld a, DUELVARS_ARENA_CARD
	add b
	call GetTurnDuelistVariable
	ldh [hTempCardIndex_ff9f], a
	ld [wAIPokemonPowerDeckIndex], a
	call GetCardIDFromDeckIndex
	ld a, e
	cp IVYSAUR
	jr z, .use_pkmn_power

	ld a, b
	or a
	ret z ; return when Play Area loop is ended

	dec b
	jr .loop_play_area

; use Energy Trans Pkmn Power
.use_pkmn_power
	ld a, b
	ldh [hTemp_ffa0], a
	ld [wAIPokemonPowerPlayAreaLocation], a
	ld a, OPPACTION_USE_PKMN_POWER
	bank1call AIMakeDecision
	ld a, OPPACTION_EXECUTE_PKMN_POWER_EFFECT
	bank1call AIMakeDecision

; loop for each energy cards that are going to be transferred.
.loop_energy
	xor a
	ldh [hTempPlayAreaLocation_ffa1], a
	ld a, [wAIPokemonPowerPlayAreaLocation]
	ldh [hTemp_ffa0], a

	; returns when Arena card has no Grass energy cards attached.
	ld e, PLAY_AREA_ARENA
	call GetPlayAreaCardAttachedEnergies
	ld a, [wAttachedEnergies + GRASS]
	or a
	jr z, .done_transfer

; look for Grass energy cards that
; are currently attached to Arena card.
	ld e, 0
.loop_deck_locations
	ld a, DUELVARS_CARD_LOCATIONS
	add e
	call GetTurnDuelistVariable
	cp CARD_LOCATION_ARENA
	jr nz, .next_card

	ld a, e
	push de
	call GetCardIDFromDeckIndex
	ld a, e
	pop de
	cp GRASS_ENERGY
	jr nz, .next_card

	; store the deck index of energy card
	ld a, e
	ldh [hAIEnergyTransEnergyCard], a
	jr .transfer

.next_card
	inc e
	ld a, DECK_SIZE
	cp e
	jr nz, .loop_deck_locations
	jr .done_transfer

.transfer
; get the Bench card location to transfer Grass energy card to.
	farcall AIProcessButDontPlayEnergy_SkipEvolutionAndArena
	jr nc, .done_transfer
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hAIEnergyTransPlayAreaLocation], a

	ld d, 30
	call AIDelayFrames_D

	ld a, [wAIPokemonPowerDeckIndex]
	ldh [hTempCardIndex_ff9f], a
	ld d, a
	ld e, FIRST_ATTACK_OR_PKMN_POWER
	call CopyAttackDataAndDamage_FromDeckIndex
	ld a, OPPACTION_6B15
	bank1call AIMakeDecision
	jr .loop_energy

; transfer is done, perform delay
; and return to main scene.
.done_transfer
	ld d, 60
	call AIDelayFrames_D
	ld a, OPPACTION_DUEL_MAIN_SCENE
	bank1call AIMakeDecision
	ret

; handles AI logic for using some Pkmn Powers.
; Pkmn Powers handled here are:
;	- Heal;
;	- Shift;
;	- Trade;
;	- Strange Behavior;
;	- Curse.
; returns carry if turn ended.
HandleAIPkmnPowers:
	call ArePokemonPowersDisabled
	ccf
	ret nc ; return no carry if Weezing is in play

	farcall AIChooseRandomlyNotToDoAction
	ccf
	ret nc ; return no carry if AI randomly decides to

	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld b, a
	ld c, PLAY_AREA_ARENA
; OATS check status of benched Pokemon too
	; ld a, DUELVARS_ARENA_CARD_STATUS
	; call GetTurnDuelistVariable
	; and CNF_SLP_PRZ
	; jr nz, .next_2

.loop_play_area
; OATS check status of benched Pokemon too
	ld a, DUELVARS_ARENA_CARD_STATUS
	add c
	call GetTurnDuelistVariable
	and CNF_SLP_PRZ
	jp nz, .next_2

	ld a, DUELVARS_ARENA_CARD
	add c
	call GetTurnDuelistVariable
	ld [wAITempVars], a

	push af
	push bc
	ld d, a
	ld a, c
	ldh [hTempPlayAreaLocation_ff9d], a
	ld [wAIPokemonPowerPlayAreaLocation], a
	ld e, FIRST_ATTACK_OR_PKMN_POWER
	call CopyAttackDataAndDamage_FromDeckIndex
	ld a, [wLoadedAttackCategory]
	cp POKEMON_POWER
	jr z, .execute_effect
	pop bc
	jr .next_3

.execute_effect
	ld a, EFFECTCMDTYPE_INITIAL_EFFECT_2
	bank1call TryExecuteEffectCommandFunction
	pop bc
	jr c, .next_3

; TryExecuteEffectCommandFunction was successful,
; so check what Pkmn Power this is through card's ID.
	pop af
	ld [wAIPokemonPowerDeckIndex], a
	call GetCardIDFromDeckIndex
	ld a, e
	push bc

; check heal
	cp GLOOM
	jr nz, .check_strange_behavior
	call HandleAIHeal
	jr .next_1
.check_strange_behavior
	cp SLOWBRO
	jr nz, .check_synthesis
	call HandleAIStrangeBehavior
	jr .next_1
.check_synthesis
	cp EXEGGUTOR
	jr nz, .check_shift
	call HandleAISynthesis
	jr .next_1
.check_shift
	cp PORYGON
	jr nz, .check_mud_sport
	call HandleAIShift
	jr .next_1
.check_mud_sport
	cp POLIWHIRL
	jr nz, .check_dual_type_fighting
	call HandleAIMudSport
	jr .next_1
.check_dual_type_fighting
	cp POLIWRATH
	jr nz, .check_prophecy
	call HandleAIDualTypeFighting
	jr .next_1
.check_prophecy
	cp KADABRA
	jr nz, .check_trade
	call HandleAIProphecy
	jr .next_1
.check_trade
	cp PERSIAN
	jr nz, .check_curse
	call HandleAITrade
	jr .next_1
.check_curse
	cp HAUNTER_LV17
	jr nz, .next_1
	call z, HandleAICurse
	jr c, .done

.next_1
	pop bc
.next_2
	inc c
	ld a, c
	cp b
	jp nz, .loop_play_area
	ret

.next_3
	pop af
	jr .next_2

.done
	pop bc
	ret

; checks whether AI uses Heal on Pokemon in Play Area.
; input:
;	c = Play Area location (PLAY_AREA_*) of Gloom.
HandleAIHeal:
	ld a, c
	ldh [hTemp_ffa0], a
	call .CheckHealTarget
	ret nc ; return if no target to heal
	push af
	ld a, [wAITempVars]
	ldh [hTempCardIndex_ff9f], a
	ld a, OPPACTION_USE_PKMN_POWER
	bank1call AIMakeDecision
	pop af
	ldh [hPlayAreaEffectTarget], a
	ld a, OPPACTION_EXECUTE_PKMN_POWER_EFFECT
	bank1call AIMakeDecision
	ld a, OPPACTION_DUEL_MAIN_SCENE
	bank1call AIMakeDecision
	ret

; finds a target suitable for AI to use Heal on.
; only heals Arena card if the Defending Pokemon
; cannot KO it after Heal is used.
; returns carry if target was found and outputs
; in a the Play Area location of that card.
.CheckHealTarget ; 22422 (8:6422)
; check if Arena card has any damage counters,
; if not, check Bench instead.
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	or a
	jr z, .check_bench

	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ff9d], a
	farcall CheckIfDefendingPokemonCanKnockOut
	jr nc, .set_carry ; return carry if can't KO
	ld d, a
	ld a, DUELVARS_ARENA_CARD_HP
	call GetTurnDuelistVariable
	ld h, a
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	; this seems useless since it was already
	; checked that Arena card has damage,
	; so card damage is at least 10.
	cp 10 + 1
	jr c, .check_remaining
	ld a, 10
	; a = min(10, CardDamage)

; checks if Defending Pokemon can still KO
; if Heal is used on this card.
; if Heal prevents KO, return carry.
.check_remaining
	ld l, a
	ld a, h ; load remaining HP
	add l ; add 1 counter to account for heal
	sub d ; subtract damage of strongest opponent attack
	jr c, .check_bench
	jr z, .check_bench

.set_carry
	xor a ; PLAY_AREA_ARENA
	scf
	ret

; check Bench for Pokemon with damage counters
; and find the one with the most damage.
.check_bench
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld d, a
	lb bc, 0, 0
	ld e, PLAY_AREA_BENCH_1
.loop_bench
	ld a, e
	cp d
	jr z, .done
	push bc
	call GetCardDamageAndMaxHP
	pop bc
	cp b
	jr c, .next_bench
	jr z, .next_bench
	ld b, a ; store this damage
	ld c, e ; store this Play Area location
.next_bench
	inc e
	jr .loop_bench

; check if a Pokemon with damage counters was found
; in the Bench and, if so, return carry.
.done
	ld a, c
	or a
	jr z, .not_found
; found
	scf
	ret
.not_found
	or a
	ret


; checks whether AI uses Strange Behavior.
; input:
;	c = Play Area location (PLAY_AREA_*) of Slowbro.
HandleAIStrangeBehavior:
	ld a, c
	or a
	ret z ; return if Slowbro is Arena card

	ldh [hTemp_ffa0], a
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	or a
	ret z ; return if Arena card has no damage counters

	ld [wce06], a
	ldh a, [hTemp_ffa0]
	add DUELVARS_ARENA_CARD_HP
	call GetTurnDuelistVariable
	sub 10
	ret z ; return if Slowbro has only 10 HP remaining

; if Slowbro can't receive all damage counters,
; only transfer remaining HP - 10 damage
	ld hl, wce06
	cp [hl]
	jr c, .use_strange_behavior
	ld a, [hl] ; can receive all damage counters

.use_strange_behavior
	push af
	ld a, [wAITempVars]
	ldh [hTempCardIndex_ff9f], a
	ld a, OPPACTION_USE_PKMN_POWER
	bank1call AIMakeDecision
	xor a
	ldh [hAIPkmnPowerEffectParam], a
	ld a, OPPACTION_EXECUTE_PKMN_POWER_EFFECT
	bank1call AIMakeDecision
	pop af

; loop counters chosen to transfer and use Pkmn Power
	call ConvertHPToCounters
	ld e, a
.loop_counters
	ld d, 30
.small_delay_loop
	call DoFrame
	dec d
	jr nz, .small_delay_loop
	push de
	ld a, OPPACTION_6B15
	bank1call AIMakeDecision
	pop de
	dec e
	jr nz, .loop_counters

; return to main scene
	ld d, 60
.big_delay_loop
	call DoFrame
	dec d
	jr nz, .big_delay_loop
	ld a, OPPACTION_DUEL_MAIN_SCENE
	bank1call AIMakeDecision
	ret



; similar to the logic of Energy Search, but this is more eager
HandleAISynthesis:
	ld a, CARD_LOCATION_DECK
	call FindBasicEnergyCardsInLocation
	ret c  ; no energy cards in deck

; if any of the energy cards in deck is useful store it and use power
	call AIDecide_EnergySearch.CheckForUsefulEnergyCards
	ldh [hAIEnergyTransEnergyCard], a
	jp nc, HandleAIDecideToUsePokemonPower

; otherwise pick the first energy in the list
	ld a, [wDuelTempList]
	ldh [hAIEnergyTransEnergyCard], a
	jp HandleAIDecideToUsePokemonPower


HandleAIMudSport:
	farcall CreateEnergyCardListFromDiscardPile_WaterFighting
	ret c  ; no energy cards

; if any of the energy cards in deck is useful store it and use power
	call AIDecide_EnergySearch.CheckForUsefulEnergyCards
	ldh [hAIEnergyTransEnergyCard], a
	jp nc, HandleAIDecideToUsePokemonPower

; otherwise pick the first energy in the list
	ld a, [wDuelTempList]
	ldh [hAIEnergyTransEnergyCard], a
	jp HandleAIDecideToUsePokemonPower


; checks whether AI uses Shift.
; input:
;	c = Play Area location (PLAY_AREA_*) of Venomoth
HandleAIShift:
	ld a, c
	or a
	ret nz ; return if Venomoth is not Arena card

	ldh [hTemp_ffa0], a
	call GetArenaCardColor
	call TranslateColorToWR
	ld b, a
	call SwapTurn
	call GetArenaCardWeakness
	ld [wAIDefendingPokemonWeakness], a
	call SwapTurn
	or a
	ret z ; return if Defending Pokemon has no weakness
	and b
	ret nz ; return if Venomoth is already Defending card's weakness type

; check whether there's a card in play with
; the same color as the Player's card weakness
	call .CheckWhetherTurnDuelistHasColor
	jr c, .found
	call SwapTurn
	call .CheckWhetherTurnDuelistHasColor
	call SwapTurn
	ret nc ; return if no color found

.found
	ld a, [wAITempVars]
	ldh [hTempCardIndex_ff9f], a
	ld a, OPPACTION_USE_PKMN_POWER
	bank1call AIMakeDecision

; converts WR_* to appropriate color
	ld a, [wAIDefendingPokemonWeakness]
	ld b, 0
.loop_color
	bit 7, a
	jr nz, .done
	inc b
	rlca
	jr .loop_color

; use Pkmn Power effect
.done
	ld a, b
	ldh [hAIPkmnPowerEffectParam], a
	ld a, OPPACTION_EXECUTE_PKMN_POWER_EFFECT
	bank1call AIMakeDecision
	ld a, OPPACTION_DUEL_MAIN_SCENE
	bank1call AIMakeDecision
	ret

; returns carry if turn Duelist has a Pokemon
; with same color as wAIDefendingPokemonWeakness.
.CheckWhetherTurnDuelistHasColor ; 224c6 (8:64c6)
	ld a, [wAIDefendingPokemonWeakness]
	ld b, a
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
.loop_play_area
	ld a, [hli]
	cp $ff
	jr z, .false
	push bc
	call GetCardIDFromDeckIndex
	call GetCardType
; OATS begin support trainer subtypes
	cp TYPE_TRAINER
	jr c, .not_trainer  ; original: jr nz
; OATS end support trainer subtypes
	pop bc
	jr .loop_play_area
.not_trainer
	call TranslateColorToWR
	pop bc
	and b
	jr z, .loop_play_area
; true
	scf
	ret
.false
	or a
	ret


; checks whether AI uses Curse.
HandleAICurse:
	farcall DamageTargetPokemon_AISelectEffect
; card in Play Area with lowest HP remaining was found.
	jp HandleAIDecideToUsePokemonPower


; EFFECTCMDTYPE_INITIAL_EFFECT_2 has already been executed, so the AI knows
; that there are cards in the deck.
HandleAITrade:
; do not use if there are only a few cards in deck
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	call GetNonTurnDuelistVariable
	cp DECK_SIZE - 5
	ret nc

	call CreateHandCardList
	ld hl, wDuelTempList
.loop_hand
	ld a, [hli]
	ldh [hAIPkmnPowerEffectParam], a
	cp $ff
	ret z
	call GetCardIDFromDeckIndex
	call GetCardType
	cp TYPE_ENERGY
	jr c, .loop_hand  ; skip Pokémon cards
	cp TYPE_ENERGY_DOUBLE_COLORLESS
	jr nc, .loop_hand  ; skip Special Energy and Trainer cards
; use power
	jp HandleAIDecideToUsePokemonPower


; EFFECTCMDTYPE_INITIAL_EFFECT_2 has already been executed, so the AI knows
; that there are Water Energies to retrieve.
HandleAIAbsorbWater:
	jp HandleAIDecideToUsePokemonPower


HandleAIDualTypeFighting:
	ld a, c
	or a
	ret nz ; return if this is not Arena card

	ldh [hTemp_ffa0], a
	call GetArenaCardColor
	call TranslateColorToWR
	ld b, a
	call SwapTurn
	call GetArenaCardWeakness
	ld [wAIDefendingPokemonWeakness], a
	call SwapTurn
	or a
	ret z ; return if Defending Pokemon has no weakness
	and b
	ret nz ; return if this is already Defending card's weakness type

	ld a, b
	cp WR_FIGHTING
	jr nz, .other_color

; already fighting type
	call SwapTurn
	call GetArenaCardResistance
	call SwapTurn
	cp WR_FIGHTING
	ret nz
	jp HandleAIDecideToUsePokemonPower  ; change type if resistant to Fighting

.other_color
	ld a, [wAIDefendingPokemonWeakness]
	cp WR_FIGHTING
	ret nz
; change type if weak to Fighting
	jp HandleAIDecideToUsePokemonPower


; handles AI logic for Cowardice
HandleAICowardice:
	call ArePokemonPowersDisabled
	ret c  ; return if there's Weezing in play

	farcall AIChooseRandomlyNotToDoAction
	ret c  ; randomly return

	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	cp 1
	ret z  ; return if only one Pokemon in Play Area

	ld b, a
	ld c, PLAY_AREA_ARENA
; OATS check status of benched Pokemon too
	; ld a, DUELVARS_ARENA_CARD_STATUS
	; call GetTurnDuelistVariable
	; and CNF_SLP_PRZ
	; jr nz, .next
.loop
; OATS check status of benched Pokemon too
	ld a, DUELVARS_ARENA_CARD_STATUS
	add c
	call GetTurnDuelistVariable
	and CNF_SLP_PRZ
	jr nz, .next

	ld a, DUELVARS_ARENA_CARD
	add c
	call GetTurnDuelistVariable
	ld [wAITempVars], a
	call GetCardIDFromDeckIndex
	ld a, e
	push bc
	cp FARFETCHD
	call z, .CheckWhetherToUseCowardice
	pop bc
	jr nc, .next

	dec b ; subtract 1 from number of Pokemon in Play Area
	ld a, 1
	cp b
	ret z ; return if no longer has Bench Pokemon
	ld c, PLAY_AREA_ARENA ; reset back to Arena
	jr .loop

.next
	inc c
	ld a, c
	cp b
	jr nz, .loop
	ret

; checks whether AI uses Cowardice.
; return carry if Pkmn Power was used.
; input:
;	c = Play Area location (PLAY_AREA_*) of Farfetch'd.
.CheckWhetherToUseCowardice
	ld a, c
	ldh [hTemp_ffa0], a
	ld e, a
	call GetCardDamageAndMaxHP
	or a
	ret z ; return if has no damage counters

	ldh a, [hTemp_ffa0]
	or a
	jr nz, .is_benched

	farcall AIDecideBenchPokemonToSwitchTo
	; assert nc
	jr .use_cowardice
.is_benched
	ld a, $ff
.use_cowardice
	push af
	ld a, [wAITempVars]
	ldh [hTempCardIndex_ff9f], a
	ld a, OPPACTION_USE_PKMN_POWER
	bank1call AIMakeDecision
	pop af
	ldh [hAIPkmnPowerEffectParam], a
	ld a, OPPACTION_EXECUTE_PKMN_POWER_EFFECT
	bank1call AIMakeDecision
	ld a, OPPACTION_DUEL_MAIN_SCENE
	bank1call AIMakeDecision
	scf
	ret


;
HandleAIProphecy:
; return no carry if number of cards in deck <= 2
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	call GetTurnDuelistVariable
	cp DECK_SIZE - 2
	ret nc

; use Pokémon Power
	ld a, [wAITempVars]
	ldh [hTempCardIndex_ff9f], a

; prioritizes Trainer cards, then energy cards, then Pokémon cards.
; stores the resulting order in wce1a.
	xor a
	ld [wAIPokedexCounter], a ; reset counter
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	call GetTurnDuelistVariable
	add DUELVARS_DECK_CARDS
	ld l, a
	ld de, 0

; run through 3 of the remaining cards in deck
	ld b, 3
.next_card
	ld a, [hli]
	ld c, a
	call .GetCardType

; load this card's deck index and type in memory
; wAITempVars = card types
; wce0f = card deck indices
	push hl
	ld hl, wAITempVars
	add hl, de
	ld [hl], a
	ld hl, wce0f
	add hl, de
	ld [hl], c
	pop hl
	inc e
	dec b
	jr nz, .next_card

; terminate the wAITempVars list
	ld a, $ff
	ld [wAITempVars + 3], a
	ld de, wce1a

; find Trainers
	ld hl, wAITempVars
	ld c, -1
	ld b, $00

; run through the stored cards and look for any Trainer cards
.loop_trainers
	inc c
	ld a, [hli]
	cp $ff
	jr z, .find_energy
	cp TYPE_TRAINER
	jr c, .loop_trainers
; found a Trainer card, store it in wce1a list
	push hl
	ld hl, wce0f
	add hl, bc
	ld a, [hl]
	pop hl
	ld [de], a
	inc de
	jr .loop_trainers

; run through the stored cards and look for any energy cards
.find_energy
	ld hl, wAITempVars
	ld c, -1
	ld b, $00

.loop_energy
	inc c
	ld a, [hli]
	cp $ff
	jr z, .find_pokemon
	and TYPE_ENERGY
	jr z, .loop_energy
; found an energy card, store it in wce1a list
	push hl
	ld hl, wce0f
	add hl, bc
	ld a, [hl]
	pop hl
	ld [de], a
	inc de
	jr .loop_energy

; run through the stored cards and look for any Pokemon cards
.find_pokemon
	ld hl, wAITempVars
	ld c, -1
	ld b, $00

.loop_pokemon
	inc c
	ld a, [hli]
	cp $ff
	jr z, .use_pkmn_power
	cp TYPE_ENERGY
	jr nc, .loop_pokemon
; found a Pokemon card, store it in wce1a list
	push hl
	ld hl, wce0f
	add hl, bc
	ld a, [hl]
	pop hl
	ld [de], a
	inc de
	jr .loop_pokemon

.use_pkmn_power
	ld a, $ff
	ldh [hTempRetreatCostCards + 3], a
	ld a, [wce1a]
	ldh [hTempRetreatCostCards], a
	ld a, [wce1b]
	ldh [hTempRetreatCostCards + 1], a
	ld a, [wce1c]
	ldh [hTempRetreatCostCards + 2], a
	jp HandleAIDecideToUsePokemonPower

.GetCardType
	push bc
	push de
	call GetCardIDFromDeckIndex
	call GetCardType
	pop de
	pop bc
	ret


; handles AI logic for attaching energy cards
HandleAIRainDanceEnergy:
	call ArePokemonPowersDisabled
	ret c  ; Pokémon Powers are disabled

	; ld a, [wAlreadyPlayedEnergyOrSupporter]
	; and USED_RAIN_DANCE_THIS_TURN
	; ret nz  ; Rain Dance was used this turn

	ld a, WARTORTLE
	call GetFirstPokemonWithAvailablePower
	ret nc  ; no Power-capable Pokémon

; store the Pokémon's Play Area location and deck index
	ld [wAIPokemonPowerPlayAreaLocation], a
	add DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	ld [wAIPokemonPowerDeckIndex], a

	farcall CreateHandCardList_OnlyWaterEnergy
	ret c  ; no Energy

	farcall AIProcessButDontPlayEnergy_SkipEvolution
	ret nc  ; no energy card attachment is needed

; use Pokémon Power
; got the target card location in [hTempPlayAreaLocation_ff9d]
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTempPlayAreaLocation_ffa1], a
	jr HandleAIDecideToUsePokemonPower


; handles AI logic for attaching energy cards
; with the Firestarter Pokémon Power.
HandleAIFirestarterEnergy:
	call ArePokemonPowersDisabled
	ret c  ; Pokémon Powers are disabled

	; ld a, [wAlreadyPlayedEnergyOrSupporter]
	; and USED_FIRESTARTER_THIS_TURN
	; ret nz  ; Firestarter was used this turn

	ld a, CHARMELEON
	call GetFirstPokemonWithAvailablePower
	ret nc  ; no Power-capable Pokémon

; store the Pokémon's Play Area location and deck index
	ld [wAIPokemonPowerPlayAreaLocation], a
	add DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	ld [wAIPokemonPowerDeckIndex], a

	farcall CreateEnergyCardListFromDiscardPile_OnlyFire
	ret c  ; no Energy

	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	cp 2
	ret c  ; no Bench

	farcall AIProcessButDontPlayEnergy_SkipEvolutionAndArena
	ret nc  ; no energy card attachment is needed

; use Pokémon Power
; got the Bench card location in [hTempPlayAreaLocation_ff9d]
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTempPlayAreaLocation_ffa1], a

	; jr HandleAIDecideToUsePokemonPower
	; fallthrough


; this should only be called after all necessary parameters are set
; this sets [hTempCardIndex_ff9f] and [hTemp_ffa0]
; other parameters should be initialized elsewhere
; input:
;   [wAIPokemonPowerDeckIndex]: deck index of the Pokémon using the Power
;   [wAIPokemonPowerPlayAreaLocation]: PLAY_AREA_* of the Pokémon using the Power
HandleAIDecideToUsePokemonPower:
	ld a, [wAIPokemonPowerDeckIndex]
	ldh [hTempCardIndex_ff9f], a
	ld a, [wAIPokemonPowerPlayAreaLocation]
	ldh [hTemp_ffa0], a
	ld a, OPPACTION_USE_PKMN_POWER
	bank1call AIMakeDecision
; execute the EFFECTCMDTYPE_BEFORE_DAMAGE command of the used Pokemon Power
	ld a, OPPACTION_EXECUTE_PKMN_POWER_EFFECT
	bank1call AIMakeDecision
	ld a, OPPACTION_DUEL_MAIN_SCENE
	bank1call AIMakeDecision
	ret
