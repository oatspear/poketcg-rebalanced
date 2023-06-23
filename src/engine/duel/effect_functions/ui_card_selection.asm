; ------------------------------------------------------------------------------
; Choose Cards to Discard
; ------------------------------------------------------------------------------

; prompts the player to select a card from the hand to discard
; output:
;   a: deck index of the selected card
;   [hTempCardIndex_ff98]: deck index of the selected card
;   carry: set if the selection was cancelled
HandlePlayerSelection1HandCardToDiscard:
	ldtx hl, ChooseCardToDiscardFromHandText
	call DrawWideTextBox_WaitForInput
	call CreateHandCardList
	bank1call InitAndDrawCardListScreenLayout_MenuTypeSelectCheck
	bank1call DisplayCardList
	ldh a, [hTempCardIndex_ff98]
	ret

; prompts the player to select a card from the hand to discard,
; excluding the card that is currently being used.
; output:
;   a: deck index of the selected card
;   [hTempCardIndex_ff98]: deck index of the selected card
;   carry: set if the selection was cancelled
HandlePlayerSelection1HandCardToDiscardExcludeSelf:
	ldtx hl, ChooseCardToDiscardFromHandText
	call DrawWideTextBox_WaitForInput
	call CreateHandCardListExcludeSelf
	bank1call InitAndDrawCardListScreenLayout_MenuTypeSelectCheck
	bank1call DisplayCardList
	ldh a, [hTempCardIndex_ff98]
	ret


; handles screen for Player to select 2 cards from the hand to discard.
; first prints text informing Player to choose cards to discard
; then runs HandlePlayerSelection2HandCardsExcludeSelf routine.
HandlePlayerSelection2HandCardsToDiscardExcludeSelf:
	ldtx hl, Choose2CardsFromHandToDiscardText
	ldtx de, ChooseTheCardToDiscardText
;	fallthrough

; handles screen for Player to select 2 cards from the hand
; to activate some Trainer card effect.
; assumes Trainer card index being used is in [hTempCardIndex_ff9f].
; stores selection of cards in hTempList.
; returns carry if Player cancels operation.
; input:
;	hl = text to print in text box;
;	de = text to print in screen header.
HandlePlayerSelection2HandCardsExcludeSelf:
	push de
	call DrawWideTextBox_WaitForInput

; remove the Trainer card being used from list
; of cards to select from hand.
	call CreateHandCardListExcludeSelf

	xor a
	ldh [hCurSelectionItem], a
	pop hl
.loop
	push hl
	bank1call InitAndDrawCardListScreenLayout_MenuTypeSelectCheck
	pop hl
	bank1call SetCardListInfoBoxText
	push hl
	bank1call DisplayCardList
	pop hl
	jr c, .set_carry ; was B pressed?
	push hl
	call GetNextPositionInTempList
	ldh a, [hTempCardIndex_ff98]
	ld [hl], a
	call RemoveCardFromDuelTempList
	pop hl
	ldh a, [hCurSelectionItem]
	cp 2
	jr c, .loop ; is selection over?
	or a
	ret
.set_carry
	scf
	ret


; ------------------------------------------------------------------------------
; Choose Cards From Discard Pile
; ------------------------------------------------------------------------------

; Handles screen for the Player to choose an Item Trainer card
; from the Discard Pile.
; output:
;   a: deck index of the selected card
;   [hTempCardIndex_ff98]: deck index of the selected card
HandlePlayerSelectionItemTrainerFromDiscardPile:
	call CreateItemCardListFromDiscardPile
	bank1call InitAndDrawCardListScreenLayout_MenuTypeSelectCheck
	ldtx hl, PleaseSelectCardText
	ldtx de, PlayerDiscardPileText
	bank1call SetCardListHeaderText
.loop_input
	bank1call DisplayCardList
	jr c, .loop_input
	ldh a, [hTempCardIndex_ff98]
	ret

PlayerSelectAndStoreItemCardFromDiscardPile:
	call HandlePlayerSelectionItemTrainerFromDiscardPile
	ldh [hTempPlayAreaLocation_ffa1], a
	ret


; ------------------------------------------------------------------------------
; Choose Cards From Deck
; ------------------------------------------------------------------------------

; Handles screen for the Player to choose an Item Trainer card
; from the Deck.
; output:
;   a: deck index of the selected card
;   [hTempCardIndex_ff98]: deck index of the selected card
HandlePlayerSelectionItemTrainerFromDeck:
	call CreateItemCardListFromDeck
	bank1call InitAndDrawCardListScreenLayout_MenuTypeSelectCheck
	ldtx hl, ChooseCardToPlaceInHandText
	ldtx de, DuelistDeckText
	bank1call SetCardListHeaderText
.loop_input
	bank1call DisplayCardList
	jr c, .loop_input
	ldh a, [hTempCardIndex_ff98]
	ret


HandlePlayerSelectionPokemonFromTop5InDeck:
; create the list of the top 5 cards in deck
	ld b, 5
	call CreateDeckCardListTopNCards
	jr HandlePlayerSelectionPokemonFromDeck_

HandlePlayerSelectionPokemonFromDeck:
; create the list of cards in deck
	call CreateDeckCardList
	; fallthrough

HandlePlayerSelectionPokemonFromDeck_:
; handle input
	bank1call InitAndDrawCardListScreenLayout_MenuTypeSelectCheck
	ldtx hl, ChoosePokemonCardText
	ldtx de, DuelistDeckText
	bank1call SetCardListHeaderText
.read_input
	bank1call DisplayCardList
; if B was pressed, either there are no Pokémon or Player does not want any
	jr c, .no_cards
	ldh a, [hTempCardIndex_ff98]
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_PKMN + 1
	jr nc, .play_sfx ; can't select non-Pokémon card
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	or a
	ret

.no_cards
	ld a, $ff
	ldh [hTemp_ffa0], a
	or a
	ret

.play_sfx
	call PlaySFX_InvalidChoice
	jr .read_input


; ------------------------------------------------------------------------------
; Choose Pokémon In Play Area
; ------------------------------------------------------------------------------

HandlePlayerSelectionPokemonInPlayArea:
	bank1call HasAlivePokemonInPlayArea
.loop_input
	bank1call OpenPlayAreaScreenForSelection
	jr c, .loop_input
	ldh a, [hTempPlayAreaLocation_ff9d]
	ret

HandlePlayerSelectionPokemonInBench:
	bank1call HasAlivePokemonInBench
	jr HandlePlayerSelectionPokemonInPlayArea.loop_input


; uses de and bc
HandlePlayerSelectionDamagedPokemonInPlayArea:
	bank1call HasAlivePokemonInPlayArea
.loop_input
	bank1call OpenPlayAreaScreenForSelection
	jr c, .loop_input
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld e, a
	call GetCardDamageAndMaxHP
	or a
	jr z, .loop_input ; has no damage counters
	ldh a, [hTempPlayAreaLocation_ff9d]
	ret


HandlePlayerSelectionOpponentPokemonInPlayArea:
	call SwapTurn
	call HandlePlayerSelectionPokemonInPlayArea
	jp SwapTurn

HandlePlayerSelectionOpponentPokemonInBench:
	call SwapTurn
	call HandlePlayerSelectionPokemonInBench
	jp SwapTurn


PlayerSelectAndStorePokemonInPlayArea:
	call HandlePlayerSelectionPokemonInPlayArea
	ldh [hTemp_ffa0], a
	ret

PlayerSelectAndStorePokemonInBench:
	call HandlePlayerSelectionPokemonInBench
	ldh [hTemp_ffa0], a
	ret

PlayerSelectAndStoreOpponentPokemonInPlayArea:
	call HandlePlayerSelectionOpponentPokemonInPlayArea
	ldh [hTemp_ffa0], a
	ret

PlayerSelectAndStoreOpponentPokemonInBench:
	call HandlePlayerSelectionOpponentPokemonInBench
	ldh [hTemp_ffa0], a
	ret


; ------------------------------------------------------------------------------
; Choose Cards in Play Area
; ------------------------------------------------------------------------------

; handles Player selection for Pokemon in Play Area,
; then opens screen to choose one of the energy cards
; attached to that selected Pokemon.
; outputs the selection in:
;	[hTemp_ffa0] = play area location
;	[hTempPlayAreaLocation_ffa1] = index of energy card
HandlePokemonAndEnergySelectionScreen:
	bank1call HasAlivePokemonInPlayArea
	bank1call OpenPlayAreaScreenForSelection
	ret c ; exit if B is pressed
	ld e, a
	call GetPlayAreaCardAttachedEnergies
	ld a, [wTotalAttachedEnergies]
	or a
	jr nz, .has_energy
	ldtx hl, NoEnergyCardsText
	call DrawWideTextBox_WaitForInput
	jr HandlePokemonAndEnergySelectionScreen ; loop back to start

.has_energy
	ldh a, [hCurMenuItem]
	bank1call CreateArenaOrBenchEnergyCardList
	ldh a, [hCurMenuItem]
	bank1call DisplayEnergyDiscardScreen
	bank1call HandleEnergyDiscardMenuInput
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	ldh a, [hTempCardIndex_ff98]
	ldh [hTempPlayAreaLocation_ffa1], a
	ret

; handles Player selection for Pokemon in Play Area,
; then opens screen to choose one of the Basic energy cards
; attached to that selected Pokemon.
; outputs the selection in:
;	[hTemp_ffa0] = play area location
;	[hTempPlayAreaLocation_ffa1] = index of energy card
HandlePokemonAndBasicEnergySelectionScreen:
	bank1call HasAlivePokemonInPlayArea
	bank1call OpenPlayAreaScreenForSelection
	ret c ; exit if B is pressed
	ld e, a
	call GetPlayAreaCardAttachedEnergies
	ld a, [wTotalAttachedEnergies]
	or a
	jr z, .no_energy
	ld e, a
	ld a, [wAttachedEnergies + COLORLESS]
	cp e
	jr z, .no_energy  ; only has colorless energy

	ldh a, [hCurMenuItem]
	bank1call CreateArenaOrBenchEnergyCardList
	ld c, DOUBLE_COLORLESS_ENERGY
	call RemoveCardIDFromCardList
	ldh a, [hCurMenuItem]
	bank1call DisplayEnergyDiscardScreen
	bank1call HandleEnergyDiscardMenuInput
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	ldh a, [hTempCardIndex_ff98]
	ldh [hTempPlayAreaLocation_ffa1], a
	ret

.no_energy
	ldtx hl, NoEnergyCardsText
	call DrawWideTextBox_WaitForInput
	jr HandlePokemonAndBasicEnergySelectionScreen ; loop back to start
