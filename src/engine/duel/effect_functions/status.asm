; ------------------------------------------------------------------------------
; Status Effects
; ------------------------------------------------------------------------------

Poison50PercentEffect: ; 2c000 (b:4000)
	ldtx de, PoisonCheckText
	call TossCoin_BankB
	ret nc

PoisonEffect: ; 2c007 (b:4007)
	lb bc, CNF_SLP_PRZ, POISONED
	jr ApplyStatusEffect

; Defending Pokémon becomes double poisoned (takes 20 damage per turn rather than 10)
DoublePoisonEffect:
	lb bc, CNF_SLP_PRZ, DOUBLE_POISONED
	jr ApplyStatusEffect

Paralysis50PercentEffect: ; 2c011 (b:4011)
	ldtx de, ParalysisCheckText
	call TossCoin_BankB
	ret nc

ParalysisEffect: ; 2c018 (b:4018)
	lb bc, PSN_DBLPSN, PARALYZED
	jr ApplyStatusEffect

Confusion50PercentEffect: ; 2c01d (b:401d)
	ldtx de, ConfusionCheckText
	call TossCoin_BankB
	ret nc

ConfusionEffect: ; 2c024 (b:4024)
	lb bc, PSN_DBLPSN, CONFUSED
	jr ApplyStatusEffect

Sleep50PercentEffect: ; 2c029 (b:4029)
	ldtx de, SleepCheckText
	call TossCoin_BankB
	ret nc

SleepEffect: ; 2c030 (b:4030)
	lb bc, PSN_DBLPSN, ASLEEP
	jr ApplyStatusEffect


ApplyStatusEffect: ; 2c035 (b:4035)
	ldh a, [hWhoseTurn]
	ld hl, wWhoseTurn
	cp [hl]
	jr nz, .can_induce_status
	ld a, [wTempNonTurnDuelistCardID]
	cp CLEFAIRY_DOLL
	jr z, .cant_induce_status
	cp MYSTERIOUS_FOSSIL
	jr z, .cant_induce_status
	; Snorlax's Thick Skinned prevents it from being statused...
	cp SNORLAX
	jr nz, .can_induce_status
	call SwapTurn
	; ...unless already so, or if affected by Muk's Toxic Gas
	call CheckCannotUseDueToStatus
	call SwapTurn
	jr c, .can_induce_status

.cant_induce_status
	ld a, c
	ld [wNoEffectFromWhichStatus], a
	call SetNoEffectFromStatus
	or a
	ret

.can_induce_status
	ld hl, wEffectFunctionsFeedbackIndex
	push hl
	ld e, [hl]
	ld d, $0
	ld hl, wEffectFunctionsFeedback
	add hl, de
	call SwapTurn
	ldh a, [hWhoseTurn]
	ld [hli], a
	call SwapTurn
	ld [hl], b ; mask of status conditions not to discard on the target
	inc hl
	ld [hl], c ; status condition to inflict to the target
	pop hl
	; advance wEffectFunctionsFeedbackIndex
	inc [hl]
	inc [hl]
	inc [hl]
	scf
	ret



; Defending Pokémon and user become confused.
; Defending Pokémon also becomes Poisoned.
FoulOdorEffect:
	call PoisonEffect
	call ConfusionEffect
	call SwapTurn
	call ConfusionEffect
	call SwapTurn
	ret

; If heads, Poison + Paralysis.
; If tails, Poison + Sleep.
PollenFrenzy_Status50PercentEffect:
	ldtx de, ParalysisCheckText
	call TossCoin_BankB
	jr nc, .tails
; heads
	call ParalysisEffect
	jp PoisonEffect
.tails
	call SleepEffect
	jp PoisonEffect

; If heads, defending Pokémon becomes asleep.
; If tails, defending Pokémon becomes poisoned.
SleepOrPoisonEffect:
	ldtx de, AsleepIfHeadsPoisonedIfTailsText
	call TossCoin_BankB
	jp c, SleepEffect
	jp PoisonEffect

; Poisons the Defending Pokémon if an evolution card was chosen.
PoisonEvolution_PoisonEffect:
	ldh a, [hTemp_ffa0]
	cp $ff
	ret z ; skip if no evolution card was chosen
	jp PoisonEffect

; If the Defending Pokémon is Basic, it is Paralyzed
ParalysisIfBasicEffect:
	ld a, DUELVARS_ARENA_CARD_STAGE
	call GetNonTurnDuelistVariable
	or a
	jp z, ParalysisEffect  ; BASIC
	ret


; ------------------------------------------------------------------------------
; Play Area Status Effects
; ------------------------------------------------------------------------------

; input e: PLAY_AREA_* of the target Pokémon
PoisonEffect_PlayArea:
	lb bc, CNF_SLP_PRZ, POISONED
	jr ApplyStatusEffectToPlayAreaPokemon

; input e: PLAY_AREA_* of the target Pokémon
DoublePoisonEffect_PlayArea:
	lb bc, CNF_SLP_PRZ, DOUBLE_POISONED
	jr ApplyStatusEffectToPlayAreaPokemon

; input e: PLAY_AREA_* of the target Pokémon
ParalysisEffect_PlayArea:
	lb bc, PSN_DBLPSN, PARALYZED
	jr ApplyStatusEffectToPlayAreaPokemon

; input e: PLAY_AREA_* of the target Pokémon
ConfusionEffect_PlayArea:
	lb bc, PSN_DBLPSN, CONFUSED
	jr ApplyStatusEffectToPlayAreaPokemon

; input e: PLAY_AREA_* of the target Pokémon
SleepEffect_PlayArea:
	lb bc, PSN_DBLPSN, ASLEEP
	jr ApplyStatusEffectToPlayAreaPokemon


; assumes:
;   - SwapTurn if needed to change to the correct play area
; input:
;   b: mask of status conditions to preserve on the target
;   c: status condition to inflict to the target
;   e: PLAY_AREA_* of the target Pokémon
; outputs:
;   [wNoEffectFromWhichStatus]: set with the input status condition
;   carry: set if able to apply status
ApplyStatusEffectToPlayAreaPokemon:
	ld a, DUELVARS_ARENA_CARD
	add e
	call GetTurnDuelistVariable
	cp $ff
	jr z, .cant_induce_status
	push de
	call GetCardIDFromDeckIndex
	ld a, e
	pop de
	cp CLEFAIRY_DOLL
	jr z, .cant_induce_status
	cp MYSTERIOUS_FOSSIL
	jr z, .cant_induce_status
	; Snorlax's Thick Skinned prevents it from being statused...
	cp SNORLAX
	jr nz, .can_induce_status
	; ...unless already so, or if affected by Muk's Toxic Gas
	call CheckCannotUseDueToStatus
	jr c, .can_induce_status

.cant_induce_status
	ld a, c
	ld [wNoEffectFromWhichStatus], a
	call SetNoEffectFromStatus
	or a
	ret

.can_induce_status
	ld a, DUELVARS_ARENA_CARD_STATUS
	add e
	call GetTurnDuelistVariable  ; current status
	and b  ; status condition to preserve
	or c  ; status to apply on top
	scf
	ret


; assumes:
;   - SwapTurn if needed to change to the correct play area
; input:
;   b: mask of status conditions to preserve on the target
;   c: status condition to inflict to the target
ApplyStatusEffectToAllPlayAreaPokemon:
	call ApplyStatusEffect
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld d, a
	ld e, PLAY_AREA_ARENA
	jr .next
.loop_play_area
	call ApplyStatusEffectToPlayAreaPokemon
.next
	inc e
	dec d
	ret z
	jr .loop_play_area
