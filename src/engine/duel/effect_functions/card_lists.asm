; ------------------------------------------------------------------------------
; Card Lists and Filters
; ------------------------------------------------------------------------------

CreateSupporterCardListFromDiscardPile:
	ld c, TYPE_TRAINER_SUPPORTER
	jr CreateTrainerCardListFromDiscardPile_

CreateItemCardListFromDiscardPile:
	ld c, TYPE_TRAINER
	jr CreateTrainerCardListFromDiscardPile_

; makes a list in wDuelTempList with the deck indices
; of Trainer cards found in Turn Duelist's Discard Pile.
; returns carry set if no Trainer cards found, and loads
; corresponding text to notify this.
; input:
;    c - trainer card subtype to look for, or $ff for any trainer card
CreateTrainerCardListFromDiscardPile:
	ld c, $ff
	; fallthrough

CreateTrainerCardListFromDiscardPile_:
; get number of cards in Discard Pile
; and have hl point to the end of the
; Discard Pile list in wOpponentDeckCards.
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_DISCARD_PILE
	call GetTurnDuelistVariable
	ld b, a
	add DUELVARS_DECK_CARDS
	ld l, a

	ld de, wDuelTempList
	inc b
	jr .next_card

.check_trainer
	ld a, [hl]
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
; OATS begin support trainer subtypes
	cp TYPE_TRAINER
	jr c, .next_card  ; original: jr nz
; OATS end support trainer subtypes

	ld a, c
	cp $ff  ; anything goes
	jr z, .store
	ld a, [wLoadedCard2Type]
	cp c  ; apply filter
	jr nz, .next_card

.store
	ld a, [hl]
	ld [de], a
	inc de

.next_card
	dec l
	dec b
	jr nz, .check_trainer

	ld a, $ff ; terminating byte
	ld [de], a
	ld a, [wDuelTempList]
	cp $ff
	jr z, .no_trainers
	or a
	ret
.no_trainers
	ldtx hl, ThereAreNoTrainerCardsInDiscardPileText
	scf
	ret


; makes a list in wDuelTempList with the deck indices
; of all Water and Fighting energy cards found in Turn Duelist's Discard Pile.
CreateEnergyCardListFromDiscardPile_WaterFighting:
; start with list of Water Energy
	call CreateEnergyCardListFromDiscardPile_OnlyWater
; go to the end of the list
	ld hl, wDuelTempList
.loop
	ld a, [hli]
	cp $ff
	jr nz, .loop
; store position in de
	dec hl
	ld e, l
	ld d, h
; append list of Fighting Energy
	ld c, TYPE_ENERGY_FIGHTING
	jr CreateEnergyCardListFromDiscardPile_DE


DEF ALL_ENERGY_ALLOWED EQU $ff

; makes a list in wDuelTempList with the deck indices
; of all Fire energy cards found in Turn Duelist's Discard Pile.
CreateEnergyCardListFromDiscardPile_OnlyFire:
	ld c, TYPE_ENERGY_FIRE
	jr CreateEnergyCardListFromDiscardPile

; makes a list in wDuelTempList with the deck indices
; of all Water energy cards found in Turn Duelist's Discard Pile.
CreateEnergyCardListFromDiscardPile_OnlyWater:
	ld c, TYPE_ENERGY_WATER
	jr CreateEnergyCardListFromDiscardPile

; makes a list in wDuelTempList with the deck indices
; of all Lightning energy cards found in Turn Duelist's Discard Pile.
CreateEnergyCardListFromDiscardPile_OnlyLightning:
	ld c, TYPE_ENERGY_LIGHTNING
	jr CreateEnergyCardListFromDiscardPile

; makes a list in wDuelTempList with the deck indices
; of all basic energy cards found in Turn Duelist's Discard Pile.
CreateEnergyCardListFromDiscardPile_OnlyBasic:
	ld c, $00
	jr CreateEnergyCardListFromDiscardPile

; makes a list in wDuelTempList with the deck indices
; of all energy cards (including Double Colorless)
; found in Turn Duelist's Discard Pile.
CreateEnergyCardListFromDiscardPile_AllEnergy:
	ld c, ALL_ENERGY_ALLOWED
;	fallthrough

; makes a list in wDuelTempList with the deck indices
; of energy cards found in Turn Duelist's Discard Pile.
; if (c == ALL_ENERGY_ALLOWED), all energy cards are allowed;
; if (c == 0), double colorless energy cards are not included;
; otherwise, only energies of type c are allowed.
; returns carry if no energy cards were found.
; also sets error message in hl if carry is set.
CreateEnergyCardListFromDiscardPile:
	ld de, wDuelTempList
	; fallthrough

; input: pointer to the start of the list at de
CreateEnergyCardListFromDiscardPile_DE:
; get number of cards in Discard Pile
; and have hl point to the end of the
; Discard Pile list in wOpponentDeckCards.
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_DISCARD_PILE
	call GetTurnDuelistVariable
	ld b, a
	add DUELVARS_DECK_CARDS
	ld l, a
	inc b
	jr .next_card

.check_energy
	ld a, [hl]
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	and TYPE_ENERGY
	jr z, .next_card

; if (c == $ff), then we include all energy cards.
; if (c == $00), then we dismiss Double Colorless energy cards found.
	ld a, c
	cp ALL_ENERGY_ALLOWED
	jr z, .copy
	or a
	ld a, [wLoadedCard2Type]
	jr z, .only_basic_allowed
	cp c  ; only type c allowed
	jr z, .copy
	jr .next_card

.only_basic_allowed
	cp TYPE_ENERGY_DOUBLE_COLORLESS
	jr nc, .next_card

.copy
	ld a, [hl]
	ld [de], a
	inc de

; goes through Discard Pile list
; in wOpponentDeckCards in descending order.
.next_card
	dec l
	dec b
	jr nz, .check_energy

; terminating byte on wDuelTempList
	ld a, $ff
	ld [de], a

; check if any energy card was found
; by checking whether the first byte
; in wDuelTempList is $ff.
; if none were found, return carry and set error message.
	ld a, [wDuelTempList]
	cp $ff
	jr z, .set_carry
	or a
	ret

.set_carry
	ldtx hl, ThereAreNoEnergyCardsInDiscardPileText
	scf
	ret


; makes list in wDuelTempList with all Basic Pokemon cards
; that are in Turn Duelist's Discard Pile.
; if list turns out empty, return carry.
; OATS additionally return
;   - c the total number of Basic Pokémon
CreateBasicPokemonCardListFromDiscardPile:
; gets hl to point at end of Discard Pile cards
; and iterates the cards in reverse order.
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_DISCARD_PILE
	call GetTurnDuelistVariable
	ld b, a
	add DUELVARS_DECK_CARDS
	ld l, a
	ld de, wDuelTempList
	inc b
	ld c, 0
	jr .next_discard_pile_card

.check_card
	ld a, [hl]
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_ENERGY
	jr nc, .next_discard_pile_card ; if not Pokemon card, skip
	ld a, [wLoadedCard2Stage]
	or a
	jr nz, .next_discard_pile_card ; if not Basic stage, skip

; write this card's index to wDuelTempList
	inc c
	ld a, [hl]
	ld [de], a
	inc de
.next_discard_pile_card
	dec l
	dec b
	jr nz, .check_card

; done with the loop.
	ld a, $ff ; terminating byte
	ld [de], a
	ld a, [wDuelTempList]
	cp $ff
	jr z, .set_carry
	or a
	ret
.set_carry
	scf
	ret


; makes list in wDuelTempList with all Pokémon cards
; that are in Turn Duelist's Discard Pile.
; if list turns out empty, return carry.
; additionally return
;   - c the total number of Pokémon
CreatePokemonCardListFromDiscardPile:
; gets hl to point at end of Discard Pile cards
; and iterates the cards in reverse order.
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_DISCARD_PILE
	call GetTurnDuelistVariable
	ld b, a
	add DUELVARS_DECK_CARDS
	ld l, a
	ld de, wDuelTempList
	inc b
	ld c, 0
	jr .next_discard_pile_card

.check_card
	ld a, [hl]
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_ENERGY
	jr nc, .next_discard_pile_card ; if not Pokémon card, skip
; write this card's index to wDuelTempList
	inc c
	ld a, [hl]
	ld [de], a
	inc de
.next_discard_pile_card
	dec l
	dec b
	jr nz, .check_card

; done with the loop.
	ld a, $ff ; terminating byte
	ld [de], a
	ld a, [wDuelTempList]
	cp $ff
	jr z, .set_carry
	or a
	ret
.set_carry
	scf
	ret


; creates in wDuelTempList list of attached Fire Energy cards
; that are attached to the Turn Duelist's Arena card.
CreateListOfFireEnergyAttachedToArena: ; 2c197 (b:4197)
	ld a, TYPE_ENERGY_FIRE
	; fallthrough

; creates in wDuelTempList a list of cards that
; are in the Arena of the same type as input a.
; this is called to list Energy cards of a specific type
; that are attached to the Arena Pokemon.
; input:
;	a = TYPE_ENERGY_* constant
; output:
;	a = number of cards in list;
;	wDuelTempList filled with cards, terminated by $ff
CreateListOfEnergyAttachedToArena: ; 2c199 (b:4199)
	ld b, a
	ld c, 0
	ld de, wDuelTempList
	ld a, DUELVARS_CARD_LOCATIONS
	call GetTurnDuelistVariable
.loop
	ld a, [hl]
	cp CARD_LOCATION_ARENA
	jr nz, .next
	push de
	ld a, l
	call GetCardIDFromDeckIndex
	call GetCardType
	pop de
	cp b
	jr nz, .next ; is same as input type?
	ld a, l
	ld [de], a
	inc de
	inc c
.next
	inc l
	ld a, l
	cp DECK_SIZE
	jr c, .loop

	ld a, $ff
	ld [de], a
	ld a, c
	ret


; ------------------------------------------------------------------------------
; Deck Lists
; ------------------------------------------------------------------------------

CreateItemCardListFromDeck:
	ld c, TYPE_TRAINER
	jr CreateTrainerCardListFromDeck_

; makes a list in wDuelTempList with the deck indices
; of Trainer cards found in Turn Duelist's Deck.
; returns carry set if no Trainer cards found, and loads
; corresponding text to notify this.
; input:
;    c - trainer card subtype to look for, or $ff for any trainer card
CreateTrainerCardListFromDeck:
	ld c, $ff
	; fallthrough

CreateTrainerCardListFromDeck_:
; get number of cards in Deck
; and have hl point to the top of the
; Deck list in wOpponentDeckCards.
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	call GetTurnDuelistVariable
	ld a, DECK_SIZE
	sub [hl]
	ld b, a  ; number of cards in deck
	ld a, [hl]
	add DUELVARS_DECK_CARDS
	ld l, a  ; top of deck
	dec hl

	ld de, wDuelTempList
	inc b
	jr .next_card

.check_trainer
	ld a, [hl]
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
; OATS begin support trainer subtypes
	cp TYPE_TRAINER
	jr c, .next_card
; OATS end support trainer subtypes

	ld a, c
	cp $ff  ; anything goes
	jr z, .store
	ld a, [wLoadedCard2Type]
	cp c  ; apply filter
	jr nz, .next_card

.store
	ld a, [hl]
	ld [de], a
	inc de

.next_card
	inc hl
	dec b
	jr nz, .check_trainer

	ld a, $ff ; terminating byte
	ld [de], a
	ld a, [wDuelTempList]
	cp $ff
	jr z, .no_trainers
	or a
	ret
.no_trainers
	ldtx hl, ThereAreNoTrainerCardsInDeckText
	scf
	ret


; ------------------------------------------------------------------------------
; Hand Lists
; ------------------------------------------------------------------------------

; Creates in wDuelTempList a list of the cards in hand except for the
; Trainer card currently in use, which should be at [hTempCardIndex_ff9f].
; Just like CreateHandCardList, returns carry if there are no cards in hand,
; and returns in a the number of cards in wDuelTempList.
CreateHandCardListExcludeSelf:
	call CreateHandCardList
	ret c
	push af  ; save the number of cards in hand
	ldh a, [hTempCardIndex_ff9f]
	call RemoveCardFromDuelTempList
	jr c, .no_match
	pop af
	dec a  ; discount the removed card
	ret
.no_match
	pop af
	ret


; Just like CreateHandCardList, returns carry if there are no cards in hand,
; and returns in a the number of cards in wDuelTempList.
CreateHandCardList_OnlyWaterEnergy:
	call CreateHandCardList
	ret c  ; no cards
	ld c, TYPE_ENERGY_WATER
	call KeepOnlyCardTypeInCardList
	call CountCardsInDuelTempList
	cp 1
	ret


; ------------------------------------------------------------------------------
; Play Area Lists
; ------------------------------------------------------------------------------


; Return in a the amount of times that the Pokemon card with a given ID
; is found in the turn holder's play area.
; If the Pokemon is asleep, confused, or paralyzed (Pkmn Power-incapable),
; it does not count.
; Also fills hTempList with the PLAY_AREA_* offsets of each occurrence.
; Set carry if the Pokemon card is at least found once.
; This is almost a duplicate of CountPokemonIDInPlayArea.
; preserves: bc, de, hl
; input: a: Pokemon card ID to search
ListPowerCapablePokemonIDInPlayArea:
	push hl
	push de
	push bc
	ld [wTempPokemonID_ce7c], a
	call ClearTempList
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld b, a
	ld c, 0
	or a
	jr z, .found
	ld hl, hTempList
	push hl
.loop_play_area
	ld a, DUELVARS_ARENA_CARD - 1
	add b  ; b starts at 1, we want a 0-based index
	call GetTurnDuelistVariable
	cp $ff
	jr z, .done
; check if it is the right Pokémon
	call GetCardIDFromDeckIndex
	ld a, [wTempPokemonID_ce7c]
	cp e
	jr nz, .skip
; check if the Pokémon is affected with a status condition
	ld a, DUELVARS_ARENA_CARD_STATUS - 1
	add b  ; b starts at 1, we want a 0-based index
	call GetTurnDuelistVariable
	and CNF_SLP_PRZ
	jr nz, .skip
; increment counter and add to the list
	inc c
	ld a, b
	dec a  ; b starts at 1, we want a 0-based index
	pop hl
	ld [hli], a
	push hl
.skip
	dec b
	jr nz, .loop_play_area
.done
	pop hl
	ld a, $ff
	ld [hl], a  ; terminator
	ld a, c
	cp 1
	ccf
.found
	pop bc
	pop de
	pop hl
	ret


; ------------------------------------------------------------------------------
; List Filters
; ------------------------------------------------------------------------------

; removes cards with ID given in bc from wDuelTempList
; input:
;   wDuelTempList: must be built
;   c: ID of card to remove
;   b: ID of card to remove (2-byte ID)
RemoveCardIDFromCardList:
  ld b, $0  ; FIXME for 2-byte ID
  ld hl, wDuelTempList
  ld de, wDuelTempList
.loop
  ld a, [hli]
  ld [de], a
  cp $ff  ; terminating byte
  ret z
  push de
  call GetCardIDFromDeckIndex
; only advance de if the current card is not the given ID
  ld a, e
  cp c  ; same as input?
  jr nz, .next
  ld a, d
  cp b  ; same as input?
  jr nz, .next
  pop de
  jr .loop
.next
  pop de
  inc de
  jr .loop


RemovePokemonCardsFromCardList:
	ld hl, wDuelTempList
	ld de, wDuelTempList
.loop
	ld a, [hli]
	ld [de], a
	cp $ff  ; terminating byte
	ret z
	push de
	call GetCardIDFromDeckIndex
	call GetCardType
	pop de
; only advance de if the current card is not a Pokémon
	cp TYPE_ENERGY
	jr c, .loop
	inc de
	jr .loop


RemoveTrainerCardsFromCardList:
  ld hl, wDuelTempList
  ld de, wDuelTempList
.loop
  ld a, [hli]
  ld [de], a
  cp $ff  ; terminating byte
  ret z
  push de
  call GetCardIDFromDeckIndex
  call GetCardType
  pop de
; only advance de if the current card is not the given type
  cp TYPE_TRAINER
  jr nc, .loop
  inc de
  jr .loop

; removes cards with type given in c from wDuelTempList
; input:
;   wDuelTempList: must be built
;   c: TYPE_* constant
RemoveCardTypeFromCardList:
  ld hl, wDuelTempList
  ld de, wDuelTempList
.loop
  ld a, [hli]
  ld [de], a
  cp $ff  ; terminating byte
  ret z
  push de
	call GetCardIDFromDeckIndex
	call GetCardType
	pop de
; only advance de if the current card is not the given type
  cp c
  jr z, .loop
  inc de
  jr .loop


; removes cards from wDuelTempList with types other than the type given in c
; input:
;   wDuelTempList: must be built
;   c: TYPE_* constant
KeepOnlyCardTypeInCardList:
  ld hl, wDuelTempList
  ld de, wDuelTempList
.loop
  ld a, [hli]
  ld [de], a
  cp $ff  ; terminating byte
  ret z
  push de
	call GetCardIDFromDeckIndex
	call GetCardType
	pop de
; only advance de if the current card is of the given type
  cp c
  jr nz, .loop
  inc de
  jr .loop


; ------------------------------------------------------------------------------
; hTempList Manipulation
; ------------------------------------------------------------------------------

ClearTempList:
	xor a
	ldh [hCurSelectionItem], a
	ld a, $ff
	ldh [hTempList], a
	ret


; outputs in hl the next position
; in hTempList to place a new card,
; and increments hCurSelectionItem.
GetNextPositionInTempList:
	push de
	ld hl, hCurSelectionItem
	ld a, [hl]
	inc [hl]
	ld e, a
	ld d, $00
	ld hl, hTempList
	add hl, de
	pop de
	ret
