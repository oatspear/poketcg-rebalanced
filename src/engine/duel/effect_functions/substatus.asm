; ------------------------------------------------------------------------------
; Application
; ------------------------------------------------------------------------------

; apply a status condition of type 1 identified by register a to the target
ApplySubstatus1ToAttackingCard: ; 2c140 (b:4140)
	push af
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS1
	call GetTurnDuelistVariable
	pop af
	ld [hli], a
	ret

; apply a status condition of type 2 identified by register a to the target,
; unless prevented by wNoDamageOrEffect
ApplySubstatus2ToDefendingCard: ; 2c149 (b:4149)
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
; Substatus 1
; ------------------------------------------------------------------------------


; ------------------------------------------------------------------------------
; Substatus 2
; ------------------------------------------------------------------------------

GrowlEffect:
	ld a, SUBSTATUS2_GROWL
	call ApplySubstatus2ToDefendingCard
	ret


UnableToRetreatEffect:
	ld a, SUBSTATUS2_UNABLE_RETREAT
	call ApplySubstatus2ToDefendingCard
	ret


; ------------------------------------------------------------------------------
; Substatus 3 (Misc)
; ------------------------------------------------------------------------------
