; ------------------------------------------------------------------------------
; Healing
; ------------------------------------------------------------------------------

LeechLifeEffect:
	ld hl, wDealtDamage
	ld e, [hl]
	inc hl ; wDamageEffectiveness
	ld d, [hl]
	jr ApplyAndAnimateHPRecovery


Leech10DamageEffect:
	ld hl, wDealtDamage
	ld a, [hli]
	or a
	ret z ; return if no damage dealt
	; fallthrough

Heal10DamageEffect:
	ld de, 10
	jr ApplyAndAnimateHPRecovery


Leech20DamageEffect:
	ld hl, wDealtDamage
	ld a, [hli]
	or a
	ret z ; return if no damage dealt
	; fallthrough

Heal20DamageEffect:
	ld de, 20
	jr ApplyAndAnimateHPRecovery


; to be used in effects that happen BEFORE_DAMAGE
Heal20DamageEffect_PreserveAttackAnimation:
	ld a, [wLoadedAttackAnimation]
	push af
	call Heal20DamageEffect
	pop af
	ld [wLoadedAttackAnimation], a
	ret


Leech30DamageEffect:
	ld hl, wDealtDamage
	ld a, [hli]
	or a
	ret z ; return if no damage dealt
	; fallthrough

Heal30DamageEffect:
	ld de, 30
	jr ApplyAndAnimateHPRecovery


; to be used in effects that happen BEFORE_DAMAGE
Heal30DamageEffect_PreserveAttackAnimation:
	ld a, [wLoadedAttackAnimation]
	push af
	call Heal30DamageEffect
	pop af
	ld [wLoadedAttackAnimation], a
	ret


HealADamageEffect:
	ld d, 0
	ld e, a
	jr ApplyAndAnimateHPRecovery


; applies HP recovery on Pokemon after an attack
; with HP recovery effect, and handles its animation.
; input:
;	d = damage effectiveness
;	e = HP amount to recover
ApplyAndAnimateHPRecovery:
	push de
	ld hl, wHPRecoveryInputBackup
	ld [hl], e
	inc hl
	ld [hl], d

; get Arena card's damage
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	pop de
	or a
	ret z ; return if no damage

; load correct animation
	push de
	ld a, ATK_ANIM_HEAL
	ld [wLoadedAttackAnimation], a
	ld bc, $01 ; arrow
	bank1call PlayAttackAnimation

; compare HP to be restored with max HP
; if HP to be restored would cause HP to
; be larger than max HP, cap it accordingly
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	ld b, $00
	pop de
	ld a, DUELVARS_ARENA_CARD_HP
	call GetTurnDuelistVariable
	add e
	ld e, a
	xor a
	adc d
	ld d, a
	; de = damage dealt + current HP
	; bc = max HP of card
	call CompareDEtoBC
	jr c, .skip_cap
	; cap de to value in bc
	ld e, c
	ld d, b

.skip_cap
	ld [hl], e ; apply new HP to arena card
	bank1call WaitAttackAnimation
	ret

; input:
;   e: amount to heal
HealUserHP_NoAnimation:
	push de
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	or a
	pop de
	ret z ; no damage counters

	ld a, DUELVARS_ARENA_CARD_HP
	call GetTurnDuelistVariable
	add e
	cp c  ; c contains max HP from GetCardDamageAndMaxHP
	jr c, .store
	ld a, c  ; cap HP
.store
	ld [hl], a
	ret

; heals up to the amount of damage in register d for card in
; Play Area location in e.
; plays healing animation and prints text with card's name.
; uses: a, de, hl
; preserves: bc
; (no longer) uses: [hTempPlayAreaLocation_ff9d]
; input:
;	   d: amount of HP to heal
;	   e: PLAY_AREA_* of card to heal
; output:
;    carry: set if not damaged
HealPlayAreaCardHP:
; check its damage
	; ld d, a
	; ldh a, [hTempPlayAreaLocation_ff9d]
	; ld e, a
	push bc
	call GetCardDamageAndMaxHP
	pop bc
	or a
	jr nz, .damaged
	scf
	ret

.damaged
	cp d
	jr nc, .got_amount_to_heal  ; is damage higher than amount to heal?
	ld d, a                     ; else, heal at most a damage
.got_amount_to_heal
; play heal animation
	push bc
	call PlayHealingAnimation_PlayAreaPokemon
	pop bc

; heal the target Pokemon
	ld a, DUELVARS_ARENA_CARD_HP
	add e
	call GetTurnDuelistVariable
	add d
	ld [hl], a
	ret

	; call GetCardDamageAndMaxHP
	; ld b, $00
	; ld a, DUELVARS_ARENA_CARD_HP
	; call GetTurnDuelistVariable
	; add e
	; ld e, a
	; xor a
	; adc d
	; ld d, a
; de = damage dealt + current HP
; bc = max HP of card
	; call CompareDEtoBC
	; jr c, .skip_cap
; cap de to value in bc
	; ld e, c
	; ld d, b
; .skip_cap
	; ld [hl], e ; apply new HP to arena card
	; ret



; plays a healing animation for a play area Pokémon
; (shows the Play Area screen and the arrow up with healing animation)
; input:
;   d: amount of damage to heal
;   e: PLAY_AREA_* location of card to heal
; preserves: de
PlayHealingAnimation_PlayAreaPokemon:
; play heal animation
	push de
	ld b, e
; animation requires damage to heal in de, not d
	ld e, d
	ld d, $00
	ld a, ATK_ANIM_HEALING_WIND_PLAY_AREA
	bank1call PlayAdhocAnimationOnPlayAreaLocation_Weakness  ; preserves de
	ld l, e
	ld h, d

; print Pokemon card name and damage healed
	call LoadTxRam3
	pop de
	push de
	ld a, DUELVARS_ARENA_CARD
	add e
	call LoadCardNameAndLevelFromVarToRam2
	ldtx hl, PokemonHealedDamageText
	call DrawWideTextBox_WaitForInput
	pop de
	ret


Heal10DamageFromAll_HealEffect:
	ld d, 10
	jr HealNDamageFromAll

Heal20DamageFromAll_HealEffect:
	ld d, 20
	jr HealNDamageFromAll

Heal30DamageFromAll_HealEffect:
	ld d, 30
	; jr HealNDamageFromAll
	; fallthrough

; Heals some damage from all friendly Pokémon in Play Area (Active and Benched).
; input:
;   d - amount to heal
; uses: a, de, hl
; preserves: bc
; output:
;   carry: set if no Pokémon had damage to heal
HealNDamageFromAll:
	push bc
; play the global healing wind animation (uses bc)
	; ld a, ATK_ANIM_HEALING_WIND
	; bank1call PlayAdhocAnimationOnPlayAreaArena_NoEffectiveness

	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld b, 0  ; how many were healed
	ld c, a  ; loop counter
	ld e, PLAY_AREA_ARENA

; go through every Pokemon in the Play Area and heal c damage.
.loop_play_area
	push de
	call HealPlayAreaCardHP
	pop de
	jr c, .no_damage
	inc b
.no_damage
	inc e
	dec c
	jr nz, .loop_play_area
	ld a, b
	pop bc
	or a
	ret nz  ; some were healed
	scf
	ret  ; none healed


Recover_HealEffect:
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	ld e, a ; all damage for recovery
	ld d, 0
	call ApplyAndAnimateHPRecovery
	ret


; ------------------------------------------------------------------------------
; Status and Effects
; ------------------------------------------------------------------------------

; plays a healing animation for the arena Pokémon
; preserves: de
PlayStatusClearAnimation_ArenaPokemon:
	ld bc, $00
	ld a, ATK_ANIM_FULL_HEAL
	jr _PlayStatusClearAnimation

; plays a healing animation for a play area Pokémon
; input:
;   [hTempPlayAreaLocation_ff9d]: PLAY_AREA_* offset of card to heal
; preserves: de
PlayStatusClearAnimation_PlayAreaPokemon:
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld b, a
	ld c, WEAKNESS
	ld a, ATK_ANIM_GLOW_PLAY_AREA
	; jr _PlayStatusClearAnimation
	; fallthrough

_PlayStatusClearAnimation:
	push de
	bank1call PlayAdhocAnimationOnPlayAreaLocation
; print Pokemon card name
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD
	call LoadCardNameAndLevelFromVarToRam2
	ldtx hl, IsCuredOfStatusAndEffectsText
	call DrawWideTextBox_WaitForInput
	pop de
	ret


; Removes status conditions from turn holder's target.
; Input:
;    a: [0, 5] (PLAY_AREA_* offsets)
; Affects hl.
ClearStatusFromTarget:
	ldh [hTempPlayAreaLocation_ff9d], a
	call _ClearStatusFromTarget
	ldh a, [hTempPlayAreaLocation_ff9d]
	or a
	jr nz, PlayStatusClearAnimation_PlayAreaPokemon
; arena Pokémon additionally clears all substatus effects from attacks
	; call ClearAllArenaEffectsAndSubstatus
	call ClearSubstatus2FromArenaPokemon
	jr PlayStatusClearAnimation_ArenaPokemon

; Removes status conditions from turn holder's target.
; Input:
;    a: [0, 5] (PLAY_AREA_* offsets)
; Affects hl.
ClearStatusFromTarget_NoAnim:
	push af
	call _ClearStatusFromTarget
	pop af
	or a
	ret nz
	; arena Pokémon additionally clears all substatus effects from attacks
	; call ClearAllArenaEffectsAndSubstatus
	jr ClearSubstatus2FromArenaPokemon

; Removes status conditions from turn holder's target.
; Input:
;    a: [0, 5] (PLAY_AREA_* offsets)
; Affects hl.
_ClearStatusFromTarget:
	add DUELVARS_ARENA_CARD_STATUS
	ld l, a
	ldh a, [hWhoseTurn]
	ld h, a
	xor a
	ld [hl], a ; NO_STATUS
	ret


; clears SUBSTATUS2 effects (harmful) from arena Pokémon
ClearSubstatus2FromArenaPokemon:
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS2
	call GetTurnDuelistVariable
	xor a
	ld [hl], a
	; ld l, DUELVARS_ARENA_CARD_CHANGED_WEAKNESS
	; ld [hl], a
	; ld l, DUELVARS_ARENA_CARD_CHANGED_RESISTANCE
	; ld [hl], a
	; ld l, DUELVARS_ARENA_CARD_CHANGED_TYPE
	; ld [hl], a
	ret
