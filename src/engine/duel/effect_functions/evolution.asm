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
	; call CheckIfDeckIsEmpty
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

	bank1call IsPrehistoricPowerActive
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
	call CheckIfCanEvolveInto
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

	bank1call IsPrehistoricPowerActive
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
	call CheckIfCanEvolveInto
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
	ldh a, [hTempPlayAreaLocation_ffa1]
	call ClearStatusFromTarget_NoAnim
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
	jr z, .done ; skip if no evolution card was chosen

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

.done
	call SyncShuffleDeck
	ret
