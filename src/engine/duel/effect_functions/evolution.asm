; ------------------------------------------------------------------------------
; Pokémon Evolution
; ------------------------------------------------------------------------------

AdaptiveEvolution_AllowEvolutionEffect:
	ldh a, [hTempPlayAreaLocation_ff9d]  ; triggering Pokémon
	add DUELVARS_ARENA_CARD_FLAGS
	call GetTurnDuelistVariable
	set CAN_EVOLVE_THIS_TURN_F, [hl]
	ret

; PoisonEvolution_PreconditionsCheck:
	; call CheckDeckIsNotEmpty
	; ret
	; ld a, DUELVARS_ARENA_CARD_FLAGS
	; call GetTurnDuelistVariable
	; ldtx hl, CannotBeUsedInTurnWhichWasPlayedText
	; and CAN_EVOLVE_THIS_TURN
	; scf
	; ret z ; return if was played this turn

; Ascension_PlayerSelectEffect:
; 	ld a, GYARADOS
; 	jr EvolutionFromDeck_PlayerSelectEffect
;
; Hatch_PlayerSelectEffect:
; 	ld a, BUTTERFREE
; 	jr EvolutionFromDeck_PlayerSelectEffect
;
; PoisonEvolution_PlayerSelectEffect:
; 	ld a, BEEDRILL
; 	; jr EvolutionFromDeck_PlayerSelectEffect
; 	; fallthrough

PokemonBreeder_PlayerSelectEffect:
	call HandlePlayerSelectionPokemonInPlayArea
	jr EvolutionFromDeck_PlayerSelectEffect


Ascension_PlayerSelectEffect:
Hatch_PlayerSelectEffect:
PoisonEvolution_PlayerSelectEffect:
	xor a  ; PLAY_AREA_ARENA
	; fallthrough

; Allows the Player to select an evolution card in the deck.
; input:
;   a: PLAY_AREA_* of the card to evolve
EvolutionFromDeck_PlayerSelectEffect:
; temporary storage for card location
	ldh [hTempPlayAreaLocation_ffa1], a

	call IsPrehistoricPowerActive
	; ldtx hl, UnableToEvolveDueToPrehistoricPowerText
	jr c, .none_in_deck

; search cards in Deck
	call CreateDeckCardList
	ldtx hl, ChooseEvolvedPokemonFromDeckText
	ldtx bc, EvolvedPokemonText
	ldh a, [hTempPlayAreaLocation_ffa1]
	; ld d, SEARCHEFFECT_CARD_ID
	ld d, SEARCHEFFECT_EVOLUTION_OF_PLAY_AREA
	ld e, a
	call LookForCardsInDeck
	jr c, .none_in_deck

	bank1call InitAndDrawCardListScreenLayout_MenuTypeSelectCheck
	ldtx hl, ChooseEvolvedPokemonText
	ldtx de, DuelistDeckText
	bank1call SetCardListHeaderText

.select_card
	bank1call DisplayCardList
	jr c, .try_cancel
	ldh [hTemp_ffa0], a
; d: deck index (0-59) of the card selected to be the evolution target
	ld d, a
	ldh a, [hTempPlayAreaLocation_ffa1]
	ld e, a
	call CheckIfCanEvolveInto
	jr nc, .got_card
	jr nz, .got_card  ; ignore first turn evolution
	jr .select_card ; not a valid Evolution card

; Evolution card selected
.got_card
	or a
	ret

.play_sfx
	call PlaySFX_InvalidChoice
	jr .select_card

.try_cancel
; Player tried exiting screen, if there are
; any Beedrill cards, Player is forced to select them.
; otherwise, they can safely exit.
	ld a, DUELVARS_CARD_LOCATIONS
	call GetTurnDuelistVariable
	ldh a, [hTempPlayAreaLocation_ffa1]
	ld e, a
.loop_deck
	ld a, [hl]
	cp CARD_LOCATION_DECK
	jr nz, .next_card
	ld a, l
; d: deck index (0-59) of the card selected to be the evolution target
	ld d, a
	push hl
	call CheckIfCanEvolveInto
	pop hl
	jr nc, .play_sfx
	jr nz, .play_sfx
.next_card
	inc l
	ld a, l
	cp DECK_SIZE
	jr c, .loop_deck
	; can exit
.none_in_deck
	ld a, $ff
	ldh [hTemp_ffa0], a
	or a
	ret


Ascension_AISelectEffect:
Hatch_AISelectEffect:
PoisonEvolution_AISelectEffect:
	xor a  ; PLAY_AREA_ARENA
	; jr EvolutionFromDeck_AISelectEffect
	; fallthrough

; selects the first suitable card in the Deck
; input:
;  a: PLAY_AREA_* of the card to evolve
EvolutionFromDeck_AISelectEffect:
; temporary storage of card location
	ldh [hTempPlayAreaLocation_ffa1], a

	call IsPrehistoricPowerActive
	jr nc, .search
	ld a, $ff
	ldh [hTemp_ffa0], a
	ret

.search
	call CreateDeckCardList
	ld hl, wDuelTempList
	ldh a, [hTempPlayAreaLocation_ffa1]
	ld e, a
.loop_deck
	ld a, [hli]
	ldh [hTemp_ffa0], a
	cp $ff
	ret z ; none found
; d: deck index (0-59) of the card selected to be the evolution target
	ld d, a
	push hl
	call CheckIfCanEvolveInto
	pop hl
	jr nc, .got_card
	jr nz, .got_card  ; ignore first turn evolution
	jr .loop_deck ; not a valid Evolution card
.got_card
	ldh a, [hTemp_ffa0]
	or a
	ret


; Evolves and heals the user.
Hatch_EvolveEffect:
	ld e, 30
	call HealUserHP_NoAnimation
	; fallthrough

PokemonBreeder_EvolveEffect:
	; ldh a, [hTempPlayAreaLocation_ffa1]
	; call ClearStatusFromTarget_NoAnim
	; jr EvolutionFromDeck_EvolveEffect
	; fallthrough

Ascension_EvolveEffect:
PoisonEvolution_EvolveEffect:
	; fallthrough

; Adds the selected card to the turn holder's Hand (temporarily)
; and then evolves the Active Pokémon using the selected card.
EvolutionFromDeck_EvolveEffect:
; check if a card was chosen from the deck
	ldh a, [hTemp_ffa0]
	cp $ff
	jp z, SyncShuffleDeck ; skip if no evolution card was chosen

; add evolution card to the hand and skip showing it on screen
	call SearchCardInDeckAndSetToJustDrawn
	call AddCardToHand

; proceed into Breeder-like evolution code
	ldh a, [hTempCardIndex_ff9f]
	push af
; store deck index of evolution card in [hTempCardIndex_ff98]
	ldh a, [hTemp_ffa0]
	ldh [hTempCardIndex_ff98], a
; store play area slot of the evolving card in [hTempPlayAreaLocation_ff9d]
	ldh a, [hTempPlayAreaLocation_ffa1]
	ldh [hTempPlayAreaLocation_ff9d], a

; load the evolving Pokémon card name to RAM
	add DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer1_FromDeckIndex
	ld hl, wLoadedCard1Name
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call LoadTxRam2

	call EvolvePokemonCard

; load evolved Pokémon card name to RAM
; TODO FIXME optimize: maybe unnecessary to load card again from EvolvePokemonCard
	ldh a, [hTempCardIndex_ff98]
	call LoadCardDataToBuffer1_FromDeckIndex
	ld a, 18
	call CopyCardNameAndLevel
	xor a
	ld [hl], a ; $0 character
	ld hl, wTxRam2_b
	ld [hli], a
	ld [hl], a

; display Pokemon picture and play sfx,
; print the corresponding card names.
	bank1call DrawLargePictureOfCard
	ld a, $5e
	call PlaySFX
	ldtx hl, PokemonEvolvedIntoPokemonText
	call DrawWideTextBox_WaitForInput
; FIXME this is harmless, but probably turn off Pokémon Powers in general code
; this is the one that changes hTempCardIndex_ff9f
	bank1call OnPokemonPlayedInitVariablesAndPowers
	pop af
	ldh [hTempCardIndex_ff9f], a
	jp SyncShuffleDeck


; ------------------------------------------------------------------------------
; Pokémon Devolution
; ------------------------------------------------------------------------------


TryDevolvePokemon:
	; load selected card's data
	ldh a, [hTempPlayAreaLocation_ffa1]
	ldh [hTempPlayAreaLocation_ff9d], a
	ld [wTempPlayAreaLocation_cceb], a
	add DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer1_FromDeckIndex

; check if card is affected
	ld a, [wLoadedCard1ID]
	ld [wTempNonTurnDuelistCardID], a
	ld de, $0
	ldh a, [hTempPlayAreaLocation_ff9d]
	or a
	jr nz, .skip_substatus_check
	call HandleNoDamageOrEffectSubstatus
	jr c, .check_no_damage_effect
.skip_substatus_check
	call HandleDamageReductionOrNoDamageFromPkmnPowerEffects
.check_no_damage_effect
	call CheckNoDamageOrEffect
	jp c, DrawWideTextBox_WaitForInput

	ldh a, [hTempPlayAreaLocation_ffa1]
	call DevolvePokemon

; add the evolved card to the hand
	ld a, e
	call AddCardToHand  ; preserves af, hl, de
	call PrintDevolvedCardNameAndLevelText

; check if this devolution KO's card
	ldh a, [hTempPlayAreaLocation_ffa1]
	call PrintPlayAreaCardKnockedOutIfNoHP
	ret


; maybe unreferenced
; input:
;   a: PLAY_AREA_* of the target Pokémon
; output:
;   d: deck index of the lower stage Pokémon (after devolving)
;   e: deck index of the higher stage Pokémon (before devolving)
DevolvePokemon_PreserveTempPlayArea:
	ld l, a
; preserve [hTempPlayAreaLocation_ff9d]
	ldh a, [hTempPlayAreaLocation_ff9d]
	push af
	ld a, l
	call DevolvePokemon
; restore [hTempPlayAreaLocation_ff9d]
	pop af
	ldh [hTempPlayAreaLocation_ff9d], a
	ret


; input:
;   a: PLAY_AREA_* of the target Pokémon
; output:
;   d: deck index of the lower stage Pokémon (after devolving)
;   e: deck index of the higher stage Pokémon (before devolving)
DevolvePokemon:
	ldh [hTempPlayAreaLocation_ff9d], a
	add DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	bank1call GetCardOneStageBelow
	; d: deck index of the lower stage card
	; e: deck index of the higher stage card

	ld a, d
	call UpdateDevolvedCardHPAndStage  ; preserves bc, de
	; jr ResetDevolvedCardStatus       ; preserves bc, de
	; fallthrough

; OATS possibly unreferenced after all changes.
; Reset status and effects after devolving card.
; preserves: bc, de
ResetDevolvedCardStatus:
; clear status conditions
	ldh a, [hTempPlayAreaLocation_ff9d]
	call ClearStatusFromTarget  ; preserves bc, de
; if it's Arena card, clear other effects
	ldh a, [hTempPlayAreaLocation_ff9d]
	or a  ; cp PLAY_AREA_ARENA
	call z, ClearAllArenaEffectsAndSubstatus  ; preserves hl, bc, de
; reset changed color status
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD_CHANGED_TYPE
	call GetTurnDuelistVariable
	ld [hl], $00
; reset C2 flags
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD_FLAGS
	ld l, a
	ld [hl], $00
	ret


; Overwrites HP and Stage data of the card that was devolved
; in the Play Area to the values of new card.
; If the damage exceeds HP of pre-evolution, then HP is set to zero.
; input:
;	  a: deck index of pre-evolved card
; preserves: bc, de
UpdateDevolvedCardHPAndStage:
	push bc
	push de
	push af
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld e, a
	call GetCardDamageAndMaxHP
	ld b, a ; store damage
	ld a, e
	add DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	pop af

	ld [hl], a
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, e
	add DUELVARS_ARENA_CARD_HP
	ld l, a
	ld a, [wLoadedCard2HP]
	sub b ; subtract damage from new HP
	jr nc, .got_hp
	; damage exceeds HP
	xor a ; 0 HP
.got_hp
	ld [hl], a
	ld a, e
; overwrite card stage
	add DUELVARS_ARENA_CARD_STAGE
	ld l, a
	ld a, [wLoadedCard2Stage]
	ld [hl], a
	pop de
	pop bc
	ret


; prints the text "<X> devolved to <Y>!" with
; the proper card names and levels.
; input:
;	  d: deck index of the lower stage card
;	  e: deck index of card that was devolved
PrintDevolvedCardNameAndLevelText:
	; push de
	ld a, e
	call LoadCardDataToBuffer1_FromDeckIndex
	ld bc, wTxRam2
	ld hl, wLoadedCard1Name
	ld a, [hli]
	ld [bc], a
	inc bc
	ld a, [hl]
	ld [bc], a

	inc bc ; wTxRam2_b
	xor a
	ld [bc], a
	inc bc
	ld [bc], a

	ld a, d
	call LoadCardDataToBuffer1_FromDeckIndex
	ld a, 18
	call CopyCardNameAndLevel
	ld [hl], $00
	ldtx hl, PokemonDevolvedToText
	call DrawWideTextBox_WaitForInput
	; pop de
	ret
