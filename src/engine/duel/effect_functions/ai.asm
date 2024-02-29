; ------------------------------------------------------------------------------
; AI Selection
; ------------------------------------------------------------------------------


NaturalRemedy_AISelectEffect:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld c, a   ; loop counter
	ld d, 30  ; current max damage (heal at least 30)
	ld e, PLAY_AREA_ARENA  ; location iterator
	ld b, $ff  ; location of max damage
	ld l, DUELVARS_ARENA_CARD_STATUS
; find Play Area location with most amount of damage
.loop
	push bc
	ld b, 0  ; score
; status conditions are worth 20 damage
	ld a, [hli]
	or a
	jr z, .get_damage
	ld b, 20
.get_damage
; e already has the current PLAY_AREA_* offset
	call GetCardDamageAndMaxHP
; add score from status conditions
	add b
	pop bc
	or a
	jr z, .next ; skip if nothing to heal (redundant)
; compare to current max damage
	cp d
	jr c, .next ; skip if stored damage is higher
; store new target Pokémon
	ld d, a
	ld b, e
.next
	inc e  ; next location
	dec c  ; decrement counter
	jr nz, .loop
; return selected location (or $ff) in a and [hTemp_ffa0]
	ld a, b
	ldh [hTemp_ffa0], a
	ret


; store deck index of selected card or $ff in [hTemp_ffa0]
ChoosePokemonFromDeck_AISelectEffect:
; TODO FIXME
	ld a, $ff
	ldh [hTemp_ffa0], a
	ret


PrimalScythe_AISelectEffect:
	call CheckMysteriousFossilInHand
	ldh [hTemp_ffa0], a
	jr nc, .found
	or a  ; reset carry
	ret

.found
; always discard
	ldh [hTemp_ffa0], a
	ret


OptionalDoubleDamage_AISelectEffect:
	call ApplyDamageModifiers_DamageToTarget  ; damage in e
	ld a, DUELVARS_ARENA_CARD_HP
	call GetNonTurnDuelistVariable
	cp e
	jr c, .no  ; current HP is less than minimum damage
	ld a, e
	add a
	cp [hl]
	ld a, 1
	jr nc, .store  ; double damage is enough
.no
	xor a
.store
	ldh [hTemp_ffa0], a
	ret


Prank_AISelectEffect:
	farcall AISelect_Prank
	ret


; ------------------------------------------------------------------------------
; AI Scoring
; ------------------------------------------------------------------------------


Put1DamageCounterOnTarget_AIEffect:
	ld a, 10
	lb de, 10, 10
	jp UpdateExpectedAIDamage


FirePunch_AIEffect:
	ld a, 10
	lb de, 10, 30
	jp UpdateExpectedAIDamage


IgnitedVoltage_AIEffect:
	ld a, CARDTEST_ENERGIZED_MAGMAR
	call CheckMatchingPokemonInBench
	ret c
; energized Magmar is available
	ld a, 10
	lb de, 10, 40
	jp UpdateExpectedAIDamage


SearingSpark_AIEffect:
	ld a, CARDTEST_ENERGIZED_ELECTABUZZ
	call CheckMatchingPokemonInBench
	ret c
; energized Electabuzz is available
	ld a, 20
	lb de, 20, 50
	jp UpdateExpectedAIDamage


; ------------------------------------------------------------------------------
; Trainer Cards
; ------------------------------------------------------------------------------
