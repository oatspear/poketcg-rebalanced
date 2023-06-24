; [wDamage] += a
AddToDamage:
	push hl
	ld hl, wDamage
	add [hl]
	ld [hli], a
	ld a, 0
	adc [hl]
	ld [hl], a
	pop hl
	ret

; [wDamage] -= a
SubtractFromDamage:
	push de
	push hl
	ld e, a
	ld hl, wDamage
	ld a, [hl]
	sub e
	ld [hli], a
	ld a, [hl]
	sbc 0
	ld [hl], a
	pop hl
	pop de
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
ApplyWeaknessToDamage_DE:
	ld a, d
	or a
	jr nz, .add_30
	ld a, e
	cp 30 + 1
	jr nc, .add_30

; double de if <= 30
	sla e
	rl d
	ret

.add_30
	ld hl, 30
	add hl, de
	ld e, l
	ld d, h
	; ld a, 30
	; add e
	; ld e, a
	; ld a, 0
	; adc d
	; ld d, a
	ret
