; ------------------------------------------------------------------------------
; Card Search
; ------------------------------------------------------------------------------

; searches through Deck in wDuelTempList looking for
; a certain card or cards, and prints text depending
; on whether at least one was found.
; if none were found, asks the Player whether to look
; in the Deck anyway, and returns carry if No is selected.
; uses SEARCHEFFECT_* as input which determines what to search for:
;	SEARCHEFFECT_CARD_ID = search for card ID in e
;	SEARCHEFFECT_POKEMON_OR_BASIC_ENERGY = search for either a Pokémon or a Basic Energy
;	SEARCHEFFECT_BASIC_POKEMON = search for any Basic Pokemon
;	SEARCHEFFECT_BASIC_ENERGY = search for any Basic Energy
;	SEARCHEFFECT_POKEMON = search for any Pokemon card
;	SEARCHEFFECT_GRASS_CARD = search for any Grass card
; input:
;	  d = SEARCHEFFECT_* constant
;	  e = (optional) card ID, play area location or other search parameters
;	  hl = text to print if Deck has card(s)
;	  bc = variable text to fill <RAMTEXT> in hl
; output:
;	  carry set if refused to look at deck
LookForCardsInDeck:
	push hl
	push bc
	ld a, [wDuelTempList]
	cp $ff
	jr z, .none_in_deck
	ld a, d
	ld hl, CardSearch_FunctionTable
	call JumpToFunctionInTable
	jr c, .none_in_deck
	pop bc
	pop hl
	call DrawWideTextBox_WaitForInput
	or a
	ret

.none_in_deck
	pop hl
	call LoadTxRam2
	pop hl
	ldtx hl, ThereIsNoInTheDeckText
	call DrawWideTextBox_WaitForInput
	ldtx hl, WouldYouLikeToCheckTheDeckText
	call YesOrNoMenuWithText_SetCursorToYes
	ret

; searches through the Discard Pile in wDuelTempList looking for
; a certain card or cards, and prints text depending
; on whether at least one was found.
; if none were found, returns carry.
; uses SEARCHEFFECT_* as input which determines what to search for:
;	SEARCHEFFECT_CARD_ID = search for card ID in e
;	SEARCHEFFECT_POKEMON_OR_BASIC_ENERGY = search for either a Pokémon or a Basic Energy
;	SEARCHEFFECT_BASIC_POKEMON = search for any Basic Pokemon
;	SEARCHEFFECT_BASIC_ENERGY = search for any Basic Energy
;	SEARCHEFFECT_POKEMON = search for any Pokemon card
;	SEARCHEFFECT_GRASS_CARD = search for any Grass card
; input:
;	  d = SEARCHEFFECT_* constant
;	  e = (optional) card ID or Type to search for
;	  hl = text to print if Discard Pile has card(s)
; output:
;	  carry set if there are no eligible cards
LookForCardsInDiscardPile:
	push hl
	ld a, [wDuelTempList]
	cp $ff
	jr z, .none_in_deck
	ld a, d
	ld hl, CardSearch_FunctionTable
	call JumpToFunctionInTable
	jr c, .none_in_deck
	pop hl
	call DrawWideTextBox_WaitForInput
	or a
	ret

.none_in_deck
	pop hl
	ldtx hl, ThereAreNoEligibleCardsInTheDiscardPileText
	call DrawWideTextBox_WaitForInput
	scf
	ret


CardSearch_FunctionTable:
	dw .SearchDuelTempListForCardID
	dw .SearchDuelTempListForPokemonOrBasicEnergy
	dw .SearchDuelTempListForBasicPokemon
	dw .SearchDuelTempListForBasicEnergy
	dw .SearchDuelTempListForPokemon
	dw .SearchDuelTempListForCardType
	dw .SearchDuelTempListForGrassCard
	dw .SearchDuelTempListForEvolutionOfPlayAreaLocation

.set_carry
	scf
	ret

; returns carry if no card with same card ID as e is found
.SearchDuelTempListForCardID
	ld hl, wDuelTempList
.loop_list_e
	ld a, [hli]
	cp $ff
	jr z, .set_carry
	push de
	call GetCardIDFromDeckIndex
	ld a, e
	pop de
	cp e
	jr nz, .loop_list_e
	or a
	ret

; returns carry if no Pokémon or Basic Energy card is found
.SearchDuelTempListForPokemonOrBasicEnergy
	ld hl, wDuelTempList
.loop_list_pkmn_or_basic_energy
	ld a, [hli]
	cp $ff
	jr z, .set_carry
	call GetCardIDFromDeckIndex
	call GetCardType
	cp TYPE_ENERGY_DOUBLE_COLORLESS
	jr .loop_list_pkmn_or_basic_energy
.found_pkmn_or_basic_energy
	or a
	ret

; returns carry if no Basic Pokemon is found
.SearchDuelTempListForBasicPokemon
	ld hl, wDuelTempList
.loop_list_basic_pkmn
	ld a, [hli]
	cp $ff
	jr z, .set_carry
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_PKMN + 1
	jr nc, .loop_list_basic_pkmn  ; not a Pokemon
	ld a, [wLoadedCard2Stage]
	or a  ; BASIC
	jr nz, .loop_list_basic_pkmn
	ret

; returns carry if no Basic Energy cards are found
.SearchDuelTempListForBasicEnergy
	ld hl, wDuelTempList
.loop_list_energy
	ld a, [hli]
	cp $ff
	jr z, .set_carry
	call GetCardIDFromDeckIndex
	call GetCardType
	cp TYPE_ENERGY_DOUBLE_COLORLESS
	jr z, .loop_list_energy
	and TYPE_ENERGY
	jr z, .loop_list_energy
	or a
	ret

; returns carry if no Pokemon cards are found
.SearchDuelTempListForPokemon
	ld hl, wDuelTempList
.loop_list_pkmn
	ld a, [hli]
	cp $ff
	jr z, .set_carry
	call GetCardIDFromDeckIndex
	call GetCardType
	cp TYPE_ENERGY
	jr nc, .loop_list_pkmn
	or a
	ret

; returns carry if no Trainer Item cards are found
.SearchDuelTempListForCardType
	ld hl, wDuelTempList
.loop_list_card_type
	ld a, [hli]
	cp $ff
	jr z, .set_carry
	push de
	call GetCardIDFromDeckIndex
	call GetCardType
	pop de
	cp e
	jr nz, .loop_list_card_type
	or a
	ret

; returns carry if no Grass cards are found
.SearchDuelTempListForGrassCard
	ld hl, wDuelTempList
.loop_list_grass
	ld a, [hli]
	cp $ff
	jp z, .set_carry
	call GetCardIDFromDeckIndex
	call GetCardType
	cp TYPE_ENERGY_GRASS
	jr z, .found_grass_card
	cp TYPE_PKMN_GRASS
	jr nz, .loop_list_grass
.found_grass_card
	or a
	ret

; returns carry if no card that evolves from e is found
; e: PLAY_AREA_* of the Pokemon trying to evolve
; returns in d the deck index of the evolution card found if any
.SearchDuelTempListForEvolutionOfPlayAreaLocation
	ld hl, wDuelTempList
.loop_list_evolution_e
	ld a, [hli]
; d: deck index (0-59) of the card selected to be the evolution target
	ld d, a
	cp $ff
	jp z, .set_carry
	push hl
	call CheckIfCanEvolveInto
	pop hl
	jr nc, .can_evolve
	jr nz, .can_evolve  ; ignore "card was played this turn"
	jr .loop_list_evolution_e
.can_evolve
	or a
	ret




; Displays a list of all cards currently in the Player's deck.
; Expects the Player to choose one card.
; Meant to be called right after LookForCardsInDeck.
; input:
;   hl: pointer to a "Choose X card text"
; example:
;   ldtx hl, ChooseBasicEnergyCardText
; DisplayPlayerDeckForSearch:
; 	bank1call InitAndDrawCardListScreenLayout_MenuTypeSelectCheck
; 	ldtx hl, ChooseBasicEnergyCardText
; 	ldtx de, DuelistDeckText
; 	bank1call SetCardListHeaderText
; 	ret
