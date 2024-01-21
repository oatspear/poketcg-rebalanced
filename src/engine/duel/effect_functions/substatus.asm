; ------------------------------------------------------------------------------
; Substatus 1
; ------------------------------------------------------------------------------


FocusEnergyEffect:
; OATS Focus Energy applies to any Pokémon
	; ld a, [wTempTurnDuelistCardID]
	; cp VAPOREON_LV29
	; ret nz
	ld a, SUBSTATUS1_NEXT_TURN_DOUBLE_DAMAGE
	jr ApplySubstatus1ToAttackingCard


NextTurnUnableToAttackEffect:
	ld a, SUBSTATUS1_NEXT_TURN_UNABLE_ATTACK
	jr ApplySubstatus1ToAttackingCard


ReduceDamageTakenBy10Effect:
	ld a, SUBSTATUS1_REDUCE_BY_10
	jr ApplySubstatus1ToAttackingCard


IncreaseDamageTakenBy40Effect:
	ld a, SUBSTATUS1_VULNERABLE_40
	jr ApplySubstatus1ToAttackingCard


; apply a status condition of type 1 identified by register a to the target
ApplySubstatus1ToAttackingCard:
	push af
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS1
	call GetTurnDuelistVariable
	pop af
	ld [hli], a
	ret


; ------------------------------------------------------------------------------
; Substatus 2
; ------------------------------------------------------------------------------

ReduceAccuracyEffect:
	ld a, SUBSTATUS2_ACCURACY
	jr ApplySubstatus2ToDefendingCard


GrowlEffect:
	ld a, SUBSTATUS2_REDUCE_BY_20
	jr ApplySubstatus2ToDefendingCard


UnableToRetreatEffect:
	ld a, SUBSTATUS2_UNABLE_RETREAT
	jr ApplySubstatus2ToDefendingCard


IncreaseRetreatCostEffect:
	ld a, SUBSTATUS2_RETREAT_PLUS_1
	jr ApplySubstatus2ToDefendingCard


ReduceAttackBy10Effect:
	ld a, SUBSTATUS2_REDUCE_BY_10
	jr ApplySubstatus2ToDefendingCard


; apply a status condition of type 2 identified by register a to the target,
; unless prevented by wNoDamageOrEffect
ApplySubstatus2ToDefendingCard:
	push af
	call CheckNoDamageOrEffect
	jr c, .no_damage_orEffect
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS2
	call GetNonTurnDuelistVariable
	pop af
	ld [hl], a
; OATS using $f6 (DUELVARS_DUELIST_TYPE) here makes the AI take control
; of both players. Kinda fun to watch.
	ld l, DUELVARS_ARENA_CARD_LAST_TURN_SUBSTATUS2
	ld [hl], a
	ret

.no_damage_orEffect
	pop af
	push hl
	bank1call DrawDuelMainScene
	pop hl
	ld a, l
	or h
	call nz, DrawWideTextBox_PrintText
	ret


; ------------------------------------------------------------------------------
; Substatus 3 (Misc)
; ------------------------------------------------------------------------------
