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


CapMaximumDamage_DE:
	ld a, d
	or a
	ret z  ; no overflow
	ld de, MAX_DAMAGE
	ret


CapMinimumDamage_DE:
	ld a, d
	or a
	ret z  ; no underflow
	ld de, 0
	ret


; Weakness doubles damage if de <= 30.
; Otherwise, it adds +30 damage.
; preserves: bc
ApplyWeaknessToDamage_DE:
	ld a, d
	or a
	jr nz, .add_30
	ld a, e
	cp 30 + 1
	jr nc, .add_30

; double damage if de <= 30
	add e
	ld e, a
	ret  ; no overflow, a <= 60

.add_30
	ld hl, 30
	; fallthrough

; Adds the value in hl to damage at de.
; preserves: bc
AddToDamage_DE:
	add hl, de
	ld e, l
	ld d, h
	ret


; Subtracts the (positive) value in hl from damage at de.
; preserves: bc
SubtractFromDamage_DE:
	ld a, e
	sub l
	ld e, a
	ld a, d
	sbc h
	ld d, a
	ret


; Subtract 10 from damage at de.
; preserves: bc
ReduceDamageBy10_DE:
	ld hl, -10
	jr AddToDamage_DE

; Subtract 20 from damage at de.
; preserves: bc
ReduceDamageBy20_DE:
	ld hl, -20
	jr AddToDamage_DE

; Subtract 30 from damage at de.
; preserves: bc
ReduceDamageBy30_DE:
	ld hl, -30
	jr AddToDamage_DE
