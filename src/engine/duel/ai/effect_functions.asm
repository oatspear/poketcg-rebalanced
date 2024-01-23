; ------------------------------------------------------------------------------
; Card Lists and Filters
; ------------------------------------------------------------------------------


; FIXME: could use RemoveCardFromDuelTempList instead of this
; removes the card pointed at in hl from wDuelTempList
; input:
;   wDuelTempList: must be built
;   hl: pointer to a position in wDuelTempList
RemoveCurrentPositionFromCardList:
  ld e, l
	ld d, h
	inc hl
.loop
  ld a, [hli]
  ld [de], a
  cp $ff  ; terminating byte
  ret z
  inc de
  jr .loop


LoopCardList_GetFirstTrainer:
	ld b, TYPE_TRAINER
	ld c, $ff
	jr LoopCardList_GetFirstOfCardType

LoopCardList_GetFirstPokemon:
	ld b, TYPE_PKMN_FIRE
	ld c, TYPE_ENERGY
	jr LoopCardList_GetFirstOfCardType

LoopCardList_GetFirstEnergy:
	ld b, TYPE_ENERGY
	ld c, TYPE_TRAINER
	; jr LoopCardList_GetFirstOfCardType
	; fallthrough

; return in a deck index of card or $ff
; input:
;   b: min. TYPE_* constant to search for (e.g. TYPE_ENERGY)
;   c: max. TYPE_* constant to search for (e.g. TYPE_TRAINER)
LoopCardList_GetFirstOfCardType:
	ld hl, wDuelTempList
.loop_cards
	ld a, [hl]
	cp $ff
	jr z, .none_found
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp b
	jr c, .next
	cp c
	jr nc, .next
; found
	ld a, [hl]
	or a
	ret
.next
	inc hl
	jr .loop_cards
.none_found
	scf
	ret


; ------------------------------------------------------------------------------
; AI Card Selection Effects
; ------------------------------------------------------------------------------


; assume:
;   - the opponent has basic energy cards in discard pile (from Special Attack AI)
AISelect_Prank:
	ld a, $ff
	ldh [hTempList], a
	ldh [hTempList + 1], a
	call SwapTurn
	call CreateEnergyCardListFromDiscardPile_OnlyBasic
	jr c, .done
; get the first energy
	ld a, [wDuelTempList]
	ldh [hTempList], a
.done
	or a
	jp SwapTurn


AISelect_Rototiller:
	ld a, $ff
	ldh [hTempList], a
	ldh [hTempList + 1], a
	ldh [hTempList + 2], a
	call CreateDiscardPileCardList
	jr c, .done
; try to get energy
	call LoopCardList_GetFirstEnergy
	jr c, .pokemon1
	ldh [hTempList], a
	call RemoveCurrentPositionFromCardList
; try to get energy
	call LoopCardList_GetFirstEnergy
	jr c, .pokemon2
	ldh [hTempList + 1], a
	; call RemoveCurrentPositionFromCardList
	jr .done  ; got 2 cards
; try to get Pokémon
.pokemon1
	call LoopCardList_GetFirstPokemon
	jr c, .trainer1
	ldh [hTempList], a
	call RemoveCurrentPositionFromCardList
; try to get Pokémon
.pokemon2
	call LoopCardList_GetFirstPokemon
	jr c, .trainer2
	ldh [hTempList + 1], a
	; call RemoveCurrentPositionFromCardList
	jr .done  ; got 2 cards
; try to get Trainer
.trainer1
	call LoopCardList_GetFirstTrainer
	jr c, .done
	ldh [hTempList], a
	call RemoveCurrentPositionFromCardList
; try to get Trainer
.trainer2
	call LoopCardList_GetFirstTrainer
	jr c, .done
	ldh [hTempList + 1], a
	; call RemoveCurrentPositionFromCardList
.done
	or a
	ret


; assume card list is already initialized from precondition check
; FIXME improve
AISelect_AquaticRescue:
	ld a, $ff
	ldh [hTempList], a
	ldh [hTempList + 1], a
	ldh [hTempList + 2], a
	ldh [hTempList + 3], a
; try to get energy
	call LoopCardList_GetFirstEnergy
	jr c, .done
	ldh [hTempList], a
	call RemoveCurrentPositionFromCardList
; try to get energy
	call LoopCardList_GetFirstEnergy
	jr c, .done
	ldh [hTempList + 1], a
	call RemoveCurrentPositionFromCardList
; try to get energy
	call LoopCardList_GetFirstEnergy
	jr c, .done
	ldh [hTempList + 2], a
	; call RemoveCurrentPositionFromCardList
.done
	or a
	ret