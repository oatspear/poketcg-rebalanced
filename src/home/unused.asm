
; return, in a, the retreat cost of the card in wLoadedCard1,
; adjusting for any Pokémon Power that is active
GetLoadedCard1RetreatCost:
	call ArePokemonPowersDisabled
	jr c, .powers_disabled
	ld c, 0
	ld a, DUELVARS_BENCH
	call GetTurnDuelistVariable
.check_bench_loop
	ld a, [hli]
	cp $ff
	jr z, .no_more_bench
	call GetCardIDFromDeckIndex  ; preserves bc
	ld a, e
	cp DODRIO
	jr nz, .check_bench_loop  ; not Dodrio
	inc c
	jr .check_bench_loop

; handle Rock and Roll Power
.no_more_bench
	ld a, GRAVELER
	call GetFirstPokemonWithAvailablePower  ; preserves bc
	ld a, 0  ; preserve carry flag
	adc a
	ld b, a  ; stores 1 if Graveler was found
	or c
	jr nz, .modified_cost
.powers_disabled
	ld a, [wLoadedCard1RetreatCost] ; return regular retreat cost
	ret
.modified_cost
	ld a, [wLoadedCard1RetreatCost]
	add b  ; apply Rock and Roll if there is a Pkmn Power-capable Graveler
	sub c  ; apply Retreat Aid for each Pkmn Power-capable Dodrio
	ret nc
	xor a
	ret
