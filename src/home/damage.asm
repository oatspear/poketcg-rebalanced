; [wDamage] += a
AddToDamage:
	push hl
	ld l, a
	ld a, [wDamage]
	add l
	ld [wDamage], a
	pop hl
	ret nc  ; no overflow
	ld a, MAX_DAMAGE
	ld [wDamage], a
	ret

; [wDamage] -= a
SubtractFromDamage:
	push hl
	ld l, a
	ld a, [wDamage]
	sub l
	ld [wDamage], a
	pop hl
	ret nc  ; no underflow
	xor a
	ld [wDamage], a
	ret

; Weakness doubles damage if [wDamage] <= 30.
; Otherwise, it adds +30 damage.
; ApplyWeaknessToDamage:
; 	ld a, [wDamage + 1]
; 	or a
; 	jr nz, .add_30
; 	ld a, [wDamage]
; 	or a
; 	ret z  ; zero damage
; ; double damage if <= 30
; 	cp 30 + 1
; 	jr c, AddToDamage  ; use damage already in a
; .add_30
; 	ld a, 30
; 	jr AddToDamage


; Weakness doubles damage if de <= 30.
; Otherwise, it adds +30 damage.
; (damage capped at 250, just ignore d)
ApplyWeaknessToDamage_DE:
	ld a, d
	or a
	jr nz, .add_30
	ld a, e
	cp 30 + 1
	jr nc, .add_30

; double de if <= 30
	add e
	ld d, 0
	ld e, a
	ret nc  ; no overflow
	ld e, MAX_DAMAGE
	ret

.add_30
	ld hl, 30
	add hl, de
	ld e, l
	ld d, 0
	ld a, h
	or a
	ret z  ; no overflow
	ld e, MAX_DAMAGE
	ret
