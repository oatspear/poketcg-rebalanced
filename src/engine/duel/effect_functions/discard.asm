; ------------------------------------------------------------------------------
; Discard From Deck
; ------------------------------------------------------------------------------

; Discards N cards from the top of the turn holder's deck.
; input:
;   a: number of cards to discard
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
  jr .check_remaining

.loop
; discard top card from deck
  call DrawCardFromDeck
  call nc, PutCardInDiscardPile
.check_remaining
  dec c
  jr nz, .loop

  pop hl
  call LoadTxRam3
  ldtx hl, DiscardedCardsFromDeckText
  call DrawWideTextBox_PrintText
  ret


DiscardFromOpponentsDeckEffect:
  call SwapTurn
  call DiscardFromDeckEffect
  jp SwapTurn
