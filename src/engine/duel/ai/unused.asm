; ------------------------------------------------------------------------------
; Pokémon Powers
; ------------------------------------------------------------------------------

; checks whether AI uses Strange Behavior.
; input:
;	c = Play Area location (PLAY_AREA_*) of Slowbro.
HandleAIStrangeBehavior:
	ld a, c
	or a
	ret z ; return if Slowbro is Arena card

	ldh [hTemp_ffa0], a
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	or a
	ret z ; return if Arena card has no damage counters

	ld [wce06], a
	ldh a, [hTemp_ffa0]
	add DUELVARS_ARENA_CARD_HP
	call GetTurnDuelistVariable
	sub 10
	ret z ; return if Slowbro has only 10 HP remaining

; if Slowbro can't receive all damage counters,
; only transfer remaining HP - 10 damage
	ld hl, wce06
	cp [hl]
	jr c, .use_strange_behavior
	ld a, [hl] ; can receive all damage counters

.use_strange_behavior
	push af
	ld a, [wAITempVars]
	ldh [hTempCardIndex_ff9f], a
	ld a, OPPACTION_USE_PKMN_POWER
	bank1call AIMakeDecision
	xor a
	ldh [hAIPkmnPowerEffectParam], a
	ld a, OPPACTION_EXECUTE_PKMN_POWER_EFFECT
	bank1call AIMakeDecision
	pop af

; loop counters chosen to transfer and use Pkmn Power
	call ConvertHPToCounters
	ld e, a
.loop_counters
	ld d, 30
.small_delay_loop
	call DoFrame
	dec d
	jr nz, .small_delay_loop
	push de
	ld a, OPPACTION_6B15
	bank1call AIMakeDecision
	pop de
	dec e
	jr nz, .loop_counters

; return to main scene
	ld d, 60
.big_delay_loop
	call DoFrame
	dec d
	jr nz, .big_delay_loop
	ld a, OPPACTION_DUEL_MAIN_SCENE
	bank1call AIMakeDecision
	ret


; ------------------------------------------------------------------------------
; Trainer Cards
; ------------------------------------------------------------------------------

AIDecide_ComputerSearch_RockCrusher:
; if number of cards in hand is equal to 3,
; target Professor Oak in deck
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	call GetTurnDuelistVariable
	cp 3
	jr nz, .graveler

	ld e, PROFESSOR_OAK
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation
	jr c, .find_discard_cards_1
	; no Professor Oak in deck, fallthrough

.no_carry
	or a
	ret

.find_discard_cards_1
	ld [wce06], a
	ld a, $ff
	ld [wce1a], a
	ld [wce1b], a

	call CreateHandCardList
	ld hl, wDuelTempList
	ld de, wce1a
.loop_hand_1
	ld a, [hli]
	cp $ff
	jr z, .check_discard_cards

	ld c, a
	call LoadCardDataToBuffer1_FromDeckIndex

; if any of the following cards are in the hand,
; return no carry.
	cp PROFESSOR_OAK
	jr z, .no_carry
	cp FIGHTING_ENERGY
	jr z, .no_carry
	cp DOUBLE_COLORLESS_ENERGY
	jr z, .no_carry
	cp DIGLETT
	jr z, .no_carry
	cp GEODUDE
	jr z, .no_carry
	cp ONIX
	jr z, .no_carry
	cp RHYHORN
	jr z, .no_carry

; if it's same as wAITrainerCardToPlay, skip this card.
	ld a, [wAITrainerCardToPlay]
	ld b, a
	ld a, c
	cp b
	jr z, .loop_hand_1

; store this card index in memory
	ld [de], a
	inc de
	jr .loop_hand_1

.check_discard_cards
; check if two cards were found
; if so, output in a the deck index
; of Professor Oak card found in deck and set carry.
	ld a, [wce1b]
	cp $ff
	jr z, .no_carry
	ld a, [wce06]
	scf
	ret

; more than 3 cards in hand, so look for
; specific evolution cards.

; checks if there is a Graveler card in the deck to target.
; if so, check if there's Geodude in hand or Play Area,
; and if there's no Graveler card in hand, proceed.
; also removes Geodude from hand list so that it is not discarded.
.graveler
	ld e, GRAVELER
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation
	jr nc, .golem
	ld [wce06], a
	ld a, GEODUDE
	call LookForCardIDInHandAndPlayArea
	jr nc, .golem
	ld a, GRAVELER
	call LookForCardIDInHandList_Bank8
	jr c, .golem
	call CreateHandCardList
	ld hl, wDuelTempList
	ld e, GEODUDE
	farcall RemoveCardIDInList
	jr .find_discard_cards_2

; checks if there is a Golem card in the deck to target.
; if so, check if there's Graveler in Play Area,
; and if there's no Golem card in hand, proceed.
.golem
	ld e, GOLEM
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation
	jr nc, .dugtrio
	ld [wce06], a
	ld a, GRAVELER
	call LookForCardIDInPlayArea_Bank8
	jr nc, .dugtrio
	ld a, GOLEM
	call LookForCardIDInHandList_Bank8
	jr c, .dugtrio
	call CreateHandCardList
	ld hl, wDuelTempList
	jr .find_discard_cards_2

; checks if there is a Dugtrio card in the deck to target.
; if so, check if there's Diglett in Play Area,
; and if there's no Dugtrio card in hand, proceed.
.dugtrio
	ld e, DUGTRIO
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation
	jp nc, .no_carry
	ld [wce06], a
	ld a, DIGLETT
	call LookForCardIDInPlayArea_Bank8
	jp nc, .no_carry
	ld a, DUGTRIO
	call LookForCardIDInHandList_Bank8
	jp c, .no_carry
	call CreateHandCardList
	ld hl, wDuelTempList
	jr .find_discard_cards_2

.find_discard_cards_2
	ld a, $ff
	ld [wce1a], a
	ld [wce1b], a

	ld bc, wce1a
	ld d, $00 ; start considering Trainer cards only

; stores wAITrainerCardToPlay in e so that
; all routines ignore it for the discard effects.
	ld a, [wAITrainerCardToPlay]
	ld e, a

; this loop will store in wce1a cards to discard from hand.
; at the start it will only consider Trainer cards,
; then if there are still needed to discard,
; move on to Pokemon cards, and finally to Energy cards.
.loop_hand_2
	call RemoveFromListDifferentCardOfGivenType
	jr c, .found
	inc d ; move on to next type (Pokemon, then Energy)
	ld a, $03
	cp d
	jp z, .no_carry ; no more types to look
	jr .loop_hand_2
.found
; store this card in memory,
; and if there's still one more card to search for,
; jump back into the loop.
	ld [bc], a
	inc bc
	ld a, [wce1b]
	cp $ff
	jr z, .loop_hand_2

; output in a Computer Search target and set carry.
	ld a, [wce06]
	scf
	ret

AIDecide_ComputerSearch_WondersOfScience:
; if number of cards in hand < 5, target Professor Oak in deck
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	call GetTurnDuelistVariable
	cp 5
	jr nc, .look_in_hand

; target Professor Oak for Computer Search
	ld e, PROFESSOR_OAK
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation
	jp nc, .look_in_hand ; can be a jr
	ld [wce06], a
	jr .find_discard_cards

; Professor Oak not in deck, move on to
; look for other cards instead.
; if Grimer or Muk are not in hand,
; check whether to use Computer Search on them.
.look_in_hand
	ld a, GRIMER
	call LookForCardIDInHandList_Bank8
	jr nc, .target_grimer
	ld a, MUK
	call LookForCardIDInHandList_Bank8
	jr nc, .target_muk

.no_carry
	or a
	ret

; first check Grimer
; if in deck, check cards to discard.
.target_grimer
	ld e, GRIMER
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation
	jp nc, .no_carry ; can be a jr
	ld [wce06], a
	jr .find_discard_cards

; first check Muk
; if in deck, check cards to discard.
.target_muk
	ld e, MUK
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation
	jp nc, .no_carry ; can be a jr
	ld [wce06], a

; only discard Trainer cards from hand.
; if there are less than 2 Trainer cards to discard,
; then return with no carry.
; else, store the cards to discard and the
; target card deck index, and return carry.
.find_discard_cards
	call CreateHandCardList
	ld hl, wDuelTempList
	ld d, $00 ; first consider Trainer cards

; ignore wAITrainerCardToPlay for the discard effects.
	ld a, [wAITrainerCardToPlay]
	ld e, a
	call RemoveFromListDifferentCardOfGivenType
	jr nc, .no_carry
	ld [wce1a], a
	call RemoveFromListDifferentCardOfGivenType
	jr nc, .no_carry
	ld [wce1b], a
	ld a, [wce06]
	scf
	ret

AIDecide_ComputerSearch_FireCharge:
; pick target card in deck from highest to lowest priority.
; if not found in hand, go to corresponding branch.
	ld a, CHANSEY
	call LookForCardIDInHandList_Bank8
	jr nc, .chansey
	ld a, TAUROS
	call LookForCardIDInHandList_Bank8
	jr nc, .tauros
	ld a, JIGGLYPUFF_LV12
	call LookForCardIDInHandList_Bank8
	jr nc, .jigglypuff
	; fallthrough

.no_carry
	or a
	ret

; for each card targeted, check if it's in deck and,
; if not, then return no carry.
; else, look for cards to discard.
.chansey
	ld e, CHANSEY
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation
	jp nc, .no_carry
	ld [wce06], a
	jr .find_discard_cards
.tauros
	ld e, TAUROS
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation
	jp nc, .no_carry
	ld [wce06], a
	jr .find_discard_cards
.jigglypuff
	ld e, JIGGLYPUFF_LV12
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation
	jp nc, .no_carry
	ld [wce06], a

; only discard Trainer cards from hand.
; if there are less than 2 Trainer cards to discard,
; then return with no carry.
; else, store the cards to discard and the
; target card deck index, and return carry.
.find_discard_cards
	call CreateHandCardList
	ld hl, wDuelTempList
	ld d, $00 ; first consider Trainer cards

; ignore wAITrainerCardToPlay for the discard effects.
	ld a, [wAITrainerCardToPlay]
	ld e, a
	call RemoveFromListDifferentCardOfGivenType
	jr nc, .no_carry
	ld [wce1a], a
	call RemoveFromListDifferentCardOfGivenType
	jr nc, .no_carry
	ld [wce1b], a
	ld a, [wce06]
	scf
	ret

AIDecide_ComputerSearch_Anger:
; for each of the following cards,
; first run a check if there's a pre-evolution in
; Play Area or in the hand. If there is, choose it as target.
; otherwise, check if the evolution card is in
; hand and if so, choose it as target instead.
	ld b, RATTATA
	ld a, RATICATE
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_discard_cards
	ld a, RATTATA
	ld b, RATICATE
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .find_discard_cards
	ld b, GROWLITHE
	ld a, ARCANINE_LV34
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_discard_cards
	ld a, GROWLITHE
	ld b, ARCANINE_LV34
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .find_discard_cards
	ld b, DODUO
	ld a, DODRIO
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_discard_cards
	ld a, DODUO
	ld b, DODRIO
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .find_discard_cards
	; fallthrough

.no_carry
	or a
	ret

; only discard Trainer cards from hand.
; if there are less than 2 Trainer cards to discard,
; then return with no carry.
; else, store the cards to discard and the
; target card deck index, and return carry.
.find_discard_cards
	ld [wce06], a
	call CreateHandCardList
	ld hl, wDuelTempList
	ld d, $00 ; first consider Trainer cards

; ignore wAITrainerCardToPlay for the discard effects.
	ld a, [wAITrainerCardToPlay]
	ld e, a
	call RemoveFromListDifferentCardOfGivenType
	jr nc, .no_carry
	ld [wce1a], a
	call RemoveFromListDifferentCardOfGivenType
	jr nc, .no_carry
	ld [wce1b], a
	ld a, [wce06]
	scf
	ret
