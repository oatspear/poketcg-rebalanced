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

DEF ALL_ENERGY_ALLOWED EQU $ff

; makes a list in wDuelTempList with the deck indices
; of all Fire energy cards found in Turn Duelist's Discard Pile.
CreateEnergyCardListFromDiscardPile_OnlyFire:
	ld c, TYPE_ENERGY_FIRE
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
CreateEnergyCardListFromDiscardPile:
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
; if none were found, return carry.
	ld a, [wDuelTempList]
	cp $ff
	jr z, .set_carry
	or a
	ret

.set_carry
	scf
	ret


; makes list in wDuelTempList with all Basic Pokemon cards
; that are in Turn Duelist's Discard Pile.
; if list turns out empty, return carry.
; OATS additionally return
;   - c the total number of Basic Pokémon
CreateBasicPokemonCardListFromDiscardPile: ; 2fbd6 (b:7bd6)
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
  ; 413 555 01 93

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
