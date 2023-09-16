; ------------------------------------------------------------------------------
; General
; ------------------------------------------------------------------------------

; return carry if Player is the Turn Duelist
IsPlayerTurn:
	ld a, DUELVARS_DUELIST_TYPE
	call GetTurnDuelistVariable
	cp DUELIST_TYPE_PLAYER
	jr z, .player
	or a
	ret
.player
	scf
	ret


; returns carry if Deck is empty
CheckDeckIsNotEmpty:
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	call GetTurnDuelistVariable
	ldtx hl, NoCardsLeftInTheDeckText
	cp DECK_SIZE
	ccf
	ret


; ------------------------------------------------------------------------------
; Prize Cards
; ------------------------------------------------------------------------------

; Returns carry if the opponent has less prize cards remaining.
; Alt: Returns carry if the opponent has taken more prize cards.
CheckOpponentHasMorePrizeCardsRemaining:
	call CountPrizes  ; turn holder's remaining Prizes
	ld c, a
	call SwapTurn
	call CountPrizes  ; opponent's remaining Prizes
	call SwapTurn
	cp c  ; carry <- (opponent's Prizes < turn holder's Prizes)
	ret


; ------------------------------------------------------------------------------
; Hand Cards
; ------------------------------------------------------------------------------


; returns carry if there are less than 4 cards in hand
CheckHandSizeGreaterThan3:
	ld c, 4
	jr CheckHandSizeIsAtLeastC

; returns carry if there are less than 3 cards in hand
CheckHandSizeGreaterThan2:
	ld c, 3
	jr CheckHandSizeIsAtLeastC

; returns carry if there are less than 2 cards in hand
CheckHandSizeGreaterThan1:
	ld c, 2
	jr CheckHandSizeIsAtLeastC

; returns carry if there are no cards in hand
CheckHandIsNotEmpty:
	ld c, 1
	; jr CheckHandSizeIsAtLeastC
	; fallthrough

; returns carry if there are less than c cards in hand
; input:
;   c: threshold number of cards
; output:
;   a: number of cards in hand
;   carry: set if the number of cards in hand is less than input c
;   hl: error text
CheckHandSizeIsAtLeastC:
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	call GetTurnDuelistVariable
	cp c
	ldtx hl, NotEnoughCardsInHandText
	ret

; returns carry if there are at least c cards in hand
; input:
;   c: threshold number of cards
; output:
;   a: number of cards in hand
;   carry: set if the number of cards in hand is more than (or equal to) input c
;   hl: error text
CheckHandSizeIsLessThanC:
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	call GetTurnDuelistVariable
	cp c
	ldtx hl, TooManyCardsInHandText
	ccf
	ret

; returns carry if the player does not have more cards in hand than the opponent
; output:
;   a: number of cards in hand
;   carry: set if the number of cards in hand <= opponent's
;   hl: error text
CheckHandSizeGreaterThanOpponents:
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	call GetNonTurnDuelistVariable
	ld c, a
	inc c
	jr CheckHandSizeIsAtLeastC

; returns carry if the player does not have less cards in hand than the opponent
; output:
;   a: number of cards in hand
;   carry: set if the number of cards in hand >= opponent's
;   hl: error text
CheckHandSizeLesserThanOpponents:
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	call GetNonTurnDuelistVariable
	ld c, a
	jr CheckHandSizeIsLessThanC


; ------------------------------------------------------------------------------
; Discard Pile
; ------------------------------------------------------------------------------


; return carry if no Basic Energy cards in Discard Pile
CheckDiscardPileHasBasicEnergyCards:
    call CreateEnergyCardListFromDiscardPile_OnlyBasic
    ; call CreateEnergyCardListFromDiscardPile_AllEnergy
    ldtx hl, ThereAreNoEnergyCardsInDiscardPileText
    ret


; return carry if no Fire Energy cards in Discard Pile
CheckDiscardPileHasFireEnergyCards:
    call CreateEnergyCardListFromDiscardPile_OnlyFire
    ldtx hl, ThereAreNoEnergyCardsInDiscardPileText
    ret


; return carry if no Pokémon cards in Discard Pile
CheckDiscardPileHasPokemonCards:
    call CreatePokemonCardListFromDiscardPile
    ldtx hl, ThereAreNoPokemonInDiscardPileText
    ret


; return carry if no Basic Pokémon cards in Discard Pile
CheckDiscardPileHasBasicPokemonCards:
    call CreateBasicPokemonCardListFromDiscardPile
    ldtx hl, ThereAreNoPokemonInDiscardPileText
    ret



; ------------------------------------------------------------------------------
; Play Area
; ------------------------------------------------------------------------------

; return carry if no cards in the Bench.
CheckBenchIsNotEmpty:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ldtx hl, EffectNoPokemonOnTheBenchText
	cp 2
	ret


; ------------------------------------------------------------------------------
; Damage
; ------------------------------------------------------------------------------

; returns carry if the Active Pokémon has no damage counters.
CheckArenaPokemonHasAnyDamage:
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	ldtx hl, NoDamageCountersText
	cp 10
	ret


; returns carry if the opponent's Active Pokémon has no damage counters.
CheckOpponentArenaPokemonHasAnyDamage:
	call SwapTurn
	call CheckArenaPokemonHasAnyDamage
	jp SwapTurn


; Returns carry if the Pokémon at location
; in [hTempPlayAreaLocation_ff9d] has no damage counters.
; Useful for Pokémon Powers.
CheckTempLocationPokemonHasAnyDamage:
  ldh a, [hTempPlayAreaLocation_ff9d]
	ld e, a
	call GetCardDamageAndMaxHP
	ldtx hl, NoDamageCountersText
	cp 10
	ret


; returns carry if Play Area has no damage counters
; and sets the error message in hl
CheckIfPlayAreaHasAnyDamage:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld d, a
	ld e, PLAY_AREA_ARENA
.loop_play_area
	call GetCardDamageAndMaxHP
	or a
	ret nz ; found damage
	inc e
	dec d
	jr nz, .loop_play_area
	; no damage found
	ldtx hl, NoPokemonWithDamageCountersText
	scf
	ret


; returns carry if Play Area has no damage counters
; and sets the error message in hl
; excludes the location in [hTempPlayAreaLocation_ff9d]
CheckIfPlayAreaHasAnyDamage_ExcludeTempLocation:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld d, a
	ld e, PLAY_AREA_ARENA
.loop_play_area
	ldh a, [hTempPlayAreaLocation_ff9d]
	cp e
	jr z, .next
	call GetCardDamageAndMaxHP
	or a
	ret nz ; found damage
.next
	inc e
	dec d
	jr nz, .loop_play_area
	; no damage found
	ldtx hl, NoPokemonWithDamageCountersText
	scf
	ret


; returns carry if Strange Behavior cannot be used
StrangeBehavior_CheckDamage:
; can Pkmn Power be used?
    ldh a, [hTempPlayAreaLocation_ff9d]
    call CheckCannotUseDueToStatus_Anywhere
    ret c
; does Play Area have any damage counters?
    ldh a, [hTempPlayAreaLocation_ff9d]
    ldh [hTemp_ffa0], a
    call CheckIfPlayAreaHasAnyDamage
    ret c
; can this Pokémon receive any damage counters without KO-ing?
    ldh a, [hTempPlayAreaLocation_ff9d]
    add DUELVARS_ARENA_CARD_HP
    call GetTurnDuelistVariable
    ldtx hl, CannotUseBecauseItWillBeKnockedOutText
    cp 10 + 10
    ret


; ------------------------------------------------------------------------------
; Status and Effects
; ------------------------------------------------------------------------------


; returns carry if the Pokémon Power has already been used in this turn.
; inputs:
;   [hTempPlayAreaLocation_ff9d]: PLAY_AREA_* of the Pokémon using the Power
CheckPokemonPowerCanBeUsed:
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD_FLAGS
	call GetTurnDuelistVariable
	and USED_PKMN_POWER_THIS_TURN
	jr nz, .already_used

	ldh a, [hTempPlayAreaLocation_ff9d]
	jp CheckCannotUseDueToStatus_Anywhere

.already_used
	ldtx hl, OnlyOncePerTurnText
	scf
	ret


; return carry if opponent's Arena card has no status conditions
CheckOpponentHasStatus:
	ld a, DUELVARS_ARENA_CARD_STATUS
	call GetNonTurnDuelistVariable
	or a
	ret nz
	ldtx hl, NotAffectedByPoisonSleepParalysisOrConfusionText
	scf
	ret


; Loop over turn holder's Pokemon and return whether any have status conditions.
; Returns:
;    a: first status condition found or zero if none found
;    hl: first Pokémon status variable with status conditions or error text
;    carry: set if no Pokémon have status conditions
CheckIfPlayAreaHasAnyStatus:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	or a
	jr z, .set_carry  ; no Pokémon in play area

	ld b, a  ; loop counter
	ld l, DUELVARS_ARENA_CARD_STATUS
.loop_play_area
	ld a, [hl]
	or a
	ret nz  ; found status
	inc hl
	dec b
	jr nz, .loop_play_area
.set_carry
	ldtx hl, NotAffectedByPoisonSleepParalysisOrConfusionText
	scf
	ret


FullHeal_CheckPlayAreaStatus:
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS2
	call GetTurnDuelistVariable
	or a
	ret nz  ; substatus found
	jr CheckIfPlayAreaHasAnyStatus


; ------------------------------------------------------------------------------
; Energy
; ------------------------------------------------------------------------------

CheckArenaPokemonHasAnyEnergiesAttached:
	ld e, PLAY_AREA_ARENA
	call GetPlayAreaCardAttachedEnergies
	ld a, [wTotalAttachedEnergies]
	ldtx hl, NoEnergyCardsText
	cp 1
	ret ; return carry if not enough energy


;
CheckIfPlayAreaHasAnyEnergies:
	call CheckIfThereAreAnyEnergyCardsAttached
	ldtx hl, NoEnergyCardsAttachedToPokemonInYourPlayAreaText
	ret


; return carry if has less than 2 Energy cards
Check2EnergiesAttached:
	ld a, 2
	ldtx hl, NotEnoughEnergyCardsText
	jr GetNumAttachedEnergiesAtMostA_Arena


; return carry if less than a Energy cards
GetNumAttachedEnergiesAtMostA_Arena:
	ld e, PLAY_AREA_ARENA

; input:
;   a: max number of energy cards to test against
;   e: PLAY_AREA_* of target
; output:
;   a: total number of attached energy cards, capped at input a
;   carry: set if attached Energy cards < cap
GetNumAttachedEnergiesAtMostA:
	ld d, a
	call GetPlayAreaCardAttachedEnergies
	ld a, [wTotalAttachedEnergies]
	cp d
	ret c
	ld a, d
	ret



CheckIfCardHasGrassEnergyAttached:
	ld c, TYPE_ENERGY_GRASS
	jr CheckIfCardHasSpecificEnergyAttached

CheckIfCardHasDarknessEnergyAttached:
	ld c, TYPE_ENERGY_DARKNESS
	; jr CheckIfCardHasSpecificEnergyAttached
	; fallthrough

; returns carry if no Energy cards of the given type in c
; are attached to card in Play Area location of a.
; input:
;	a = PLAY_AREA_* of location to check
; c = TYPE_ENERGY_* constant
CheckIfCardHasSpecificEnergyAttached:
	or CARD_LOCATION_PLAY_AREA
	ld e, a

	ld a, DUELVARS_CARD_LOCATIONS
	call GetTurnDuelistVariable
.loop
	ld a, [hl]
	cp e
	jr nz, .next
	push de
	push hl
	ld a, l
	call GetCardIDFromDeckIndex
	call GetCardType
	pop hl
	pop de
	cp c
	jr z, .no_carry
.next
	inc l
	ld a, l
	cp DECK_SIZE
	jr c, .loop
	scf
	ret
.no_carry
	ld a, l
	or a
	ret
