Func_3189:
	ld hl, PointerTable_3190
	dec a
	jp JumpToFunctionInTable

PointerTable_3190:
	dw Func_31a8
	dw Func_31a8
	dw Func_31a8
	dw Func_31a8
	dw Func_31a8
	dw Func_31b0
	dw Func_31ca
	dw Func_31dd
	dw Func_31e5
	dw Func_31ef
	dw Func_31ea
	dw Func_31f2

Func_31a8:
	call Func_31fc
Func_31ab:
	ld hl, wce63
	inc [hl]
	ret

Func_31b0:
	call Func_31ab
	ld hl, wce68
	ld a, [hli]
	or [hl]
	jr nz, .set_data_ptr
	call Func_31ab
	jr Func_31dd

.set_data_ptr
	ld hl, wPrinterPacketDataPtr
	ld de, wSerialDataPtr
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hl]
	ld [de], a
;	fallthrough

Func_31ca:
	call Func_31fc
	ld hl, wce68
	ld a, [hl]
	dec [hl]
	or a
	jr nz, .asm_31d8
	inc hl
	dec [hl]
	dec hl
.asm_31d8
	ld a, [hli]
	or [hl]
	jr z, Func_31ab
	ret

Func_31dd:
	ld a, [wce6c]
Func_31e0:
	call Func_3212
	jr Func_31ab

Func_31e5:
	ld a, [wce6d]
	jr Func_31e0

Func_31ea:
	ldh a, [rSB]
	ld [wce6e], a
Func_31ef:
	xor a
	jr Func_31e0

Func_31f2:
	ldh a, [rSB]
	ld [wPrinterStatus], a
	xor a
	ld [wce63], a
	ret

Func_31fc:
	ld hl, wSerialDataPtr
	ld e, [hl]
	inc hl
	ld d, [hl]
	ld a, [de]
	inc de
	ld [hl], d
	dec hl
	ld [hl], e
	ld e, a

	ld hl, wce6c
	add [hl]
	ld [hli], a
	ld a, $0
	adc [hl]
	ld [hl], a
	ld a, e
;	fallthrough

Func_3212:
	ldh [rSB], a
	ld a, SC_INTERNAL
	ldh [rSC], a
	ld a, SC_START | SC_INTERNAL
	ldh [rSC], a
	ret
