; ------------------------------------------------------------------------------
; Discard From Deck
; ------------------------------------------------------------------------------

; Discards N cards from the top of the turn holder's deck.
; input:
;   a: number of cards to discard
; output:
;   a: number of discarded cards
;   wDuelTempList: $ff-terminated list of discarded cards (by deck index)
; preserves: nothing
;   - push/pop de around DrawWideTextBox_PrintText to preserve it
DiscardFromDeckEffect:
  ld c, a
  ld b, $00
  ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
  call GetTurnDuelistVariable
  ld a, DECK_SIZE
  sub [hl]
  cp c
  jr nc, .start_discard
; only discard number of cards that are left in deck
  ld c, a

.start_discard
  push bc
  inc c
  ld hl, wDuelTempList
  jr .check_remaining

.loop
; discard top card from deck
; assume: deck size is already handled, this never returns carry
  call DrawCardFromDeck  ; preserves hl
  ; <- jr c would be done here
  ld [hli], a  ; deck index
  call nc, PutCardInDiscardPile  ; preserves hl, de
.check_remaining
  dec c
  jr nz, .loop

; terminate wDuelTempList before using hl
  ld a, $ff
  ld [hl], a
; retrieve number of discarded cards and print text
  pop hl
  ld a, l
  or a
  push af
  call LoadTxRam3
  ldtx hl, DiscardedCardsFromDeckText
  call DrawWideTextBox_PrintText
  pop af
  ret


DiscardFromOpponentsDeckEffect:
  call SwapTurn
  call DiscardFromDeckEffect
  jp SwapTurn


; ------------------------------------------------------------------------------
; Discard From Hand
; ------------------------------------------------------------------------------

; chooses a card at random from the opponents hand
; and moves it to the discard pile
; return carry if there are no cards to discard
; shows details of the card if it is not the Player's turn
Discard1RandomCardFromOpponentsHand:
  call Discard1RandomCardFromOpponentsHandEffect
  ret c  ; unable to discard
  ; fallthrough

ShowOpponentDiscardedCardDetails:
; deck index is already in a
; show respective card from the opposing player's deck
  call SwapTurn
	ldtx hl, DiscardedFromHandText
	bank1call DisplayCardDetailScreen
  call SwapTurn
  or a
  ret


; input:
;    a: deck index
ShowDiscardedCardDetails:
  ldtx hl, DiscardedFromHandText
  bank1call DisplayCardDetailScreen
  or a
  ret


; chooses a card at random from the opponents hand
; and moves it to the discard pile
; return carry if there are no cards to discard
; returns deck index of discarded card in a
Discard1RandomCardFromOpponentsHandEffect:
  call ExchangeRNG
  call SwapTurn
  call CreateHandCardList
  jp c, SwapTurn  ; no cards in hand

; got number of cards in a
  ld hl, wDuelTempList
  cp 1
  jr z, .get_deck_index  ; there is only one card

; get random number between 0 and a (exclusive)
  call Random
; get a-th card from hand list
  ld c, a
  ld b, 0
  add hl, bc

.get_deck_index
  ld a, [hl]
; could use MoveHandCardToDiscardPile here, but the check to avoid
; anything other than CARD_LOCATION_HAND is redundant;
; it is already done in CreateHandCardList
  call RemoveCardFromHand
  call PutCardInDiscardPile
  call SwapTurn
  or a
  ret
