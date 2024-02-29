; stores in wDamage, wAIMinDamage and wAIMaxDamage the calculated damage
; done to the defending Pokémon by a given card and attack
; input:
;	a = attack index to take into account
;	[hTempPlayAreaLocation_ff9d] = location of attacking card to consider
EstimateDamage_VersusDefendingCard:
	ld [wSelectedAttack], a
	ld e, a
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	ld d, a
	call CopyAttackDataAndDamage_FromDeckIndex
	ld a, [wLoadedAttackCategory]
	cp POKEMON_POWER
	jr nz, .is_attack

; is a Pokémon Power
; set wDamage, wDamageFlags, wAIMinDamage and wAIMaxDamage to zero
	ld hl, wDamage
	xor a
	ld [hli], a
	ld [hl], a  ; wDamageFlags
	ld [wAIMinDamage], a
	ld [wAIMaxDamage], a
	ld [wAIAttackLogicFlags], a
	ld e, a
	ld d, a
	ret

.is_attack
; set wAIMinDamage and wAIMaxDamage to damage of attack
; these values take into account the range of damage
; that the attack can span (e.g. min and max number of hits)
	ld a, [wDamage]
	ld [wAIMinDamage], a
	ld [wAIMaxDamage], a
	xor a
	ld [wAIAttackLogicFlags], a
	ld a, EFFECTCMDTYPE_AI
	call TryExecuteEffectCommandFunction
	ld a, [wAIMinDamage]
	ld hl, wAIMaxDamage
	or [hl]
	jr nz, .calculation
	ld a, [wDamage]
	ld [wAIMinDamage], a
	ld [wAIMaxDamage], a

.calculation
; if temp. location is active, damage calculation can be done directly...
	ldh a, [hTempPlayAreaLocation_ff9d]
	or a
	jr z, CalculateDamage_VersusDefendingPokemon

; ...otherwise substatuses need to be temporarily reset to account
; for the switching, to obtain the right damage calculation...
	; reset substatus1
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS1
	call GetTurnDuelistVariable
	push af
	push hl
	ld [hl], $00
	; reset substatus2
	ld l, DUELVARS_ARENA_CARD_SUBSTATUS2
	ld a, [hl]
	push af
	push hl
	ld [hl], $00
	; reset changed resistance
	ld l, DUELVARS_ARENA_CARD_CHANGED_RESISTANCE
	ld a, [hl]
	push af
	push hl
	ld [hl], $00
	call CalculateDamage_VersusDefendingPokemon
; ...and subsequently recovered to continue the duel normally
	pop hl
	pop af
	ld [hl], a
	pop hl
	pop af
	ld [hl], a
	pop hl
	pop af
	ld [hl], a
	ret

; calculates the damage that will be dealt to the player's active card
; using the card that is located in hTempPlayAreaLocation_ff9d
; taking into account weakness/resistance/pluspowers/defenders/etc
; and outputs the result capped at a max of MAX_DAMAGE
; input:
;	[wAIMinDamage] = base damage
;	[wAIMaxDamage] = base damage
;	[wDamage]      = base damage
;	[hTempPlayAreaLocation_ff9d] = turn holder's card location as the attacker
CalculateDamage_VersusDefendingPokemon:
	ld hl, wAIMinDamage
	call _CalculateDamage_VersusDefendingPokemon
	jr nc, .check_max_damage
	ld hl, wAIAttackLogicFlags
	set AI_LOGIC_MIN_DAMAGE_CAN_KO_F, [hl]
.check_max_damage
	ld hl, wAIMaxDamage
	call _CalculateDamage_VersusDefendingPokemon
	jr nc, .check_normal_damage
	ld hl, wAIAttackLogicFlags
	set AI_LOGIC_MAX_DAMAGE_CAN_KO_F, [hl]
.check_normal_damage
	ld hl, wDamage
;	fallthrough

; output:
;   carry: set if the end damage is enough to score a KO
_CalculateDamage_VersusDefendingPokemon:
	ld e, [hl]
	ld d, $00
	push hl

	; load this card's data
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2ID]
	ld [wTempTurnDuelistCardID], a

	; load player's arena card data
	call SwapTurn
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2ID]
	ld [wTempNonTurnDuelistCardID], a
	call SwapTurn

	push de
	call HandleNoDamageOrEffectSubstatus
	pop de
	jr nc, .vulnerable
	; invulnerable to damage
	ld de, $0
	jr .done
.vulnerable
	ldh a, [hTempPlayAreaLocation_ff9d]
	or a
; 1. apply damage bonus effects
	call z, HandleDamageBonusSubstatus
	call HandleDamageBoostingPowers
; 2. apply weakness bonus
	ld a, [wDamageFlags]
	bit UNAFFECTED_BY_WEAKNESS_RESISTANCE_F, a
	jr nz, .apply_pluspower
; handle weakness
	call SwapTurn
	call GetArenaCardWeakness
	call SwapTurn
	ld b, a
	ldh a, [hTempPlayAreaLocation_ff9d]
	call GetPlayAreaCardColor
	call TranslateColorToWR
	ld [wAttackerColorAsWR], a
	and b
	jr z, .apply_pluspower
	call ApplyWeaknessToDamage_DE

; 3. apply pluspower bonuses
.apply_pluspower
	ldh a, [hTempPlayAreaLocation_ff9d]
	add CARD_LOCATION_ARENA
	ld b, a
	call ApplyAttachedPluspower
; 4. cap damage at 250
	call CapMaximumDamage_DE
; 5. apply resistance
	ld a, [wDamageFlags]
	bit UNAFFECTED_BY_WEAKNESS_RESISTANCE_F, a
	jr nz, .apply_defender
	bit UNAFFECTED_BY_RESISTANCE_F, a
	jr nz, .apply_defender
; affected by resistance
	call SwapTurn
	call GetArenaCardResistance
	call SwapTurn
	ld b, a
	ld a, [wAttackerColorAsWR]
	and b
	jr z, .apply_defender
	call ReduceDamageBy30_DE  ; preserves bc

; 6. apply Defender reduction
.apply_defender
	; apply pluspower and defender boosts
	call SwapTurn
	ld b, CARD_LOCATION_ARENA
	call ApplyAttachedDefender
; 7. apply damage reduction effects
	xor a  ; PLAY_AREA_ARENA
	call HandleDamageReducingPowers
	call HandleDefenderDamageReductionEffects
	call HandleAttackerDamageReductionEffects
; 8. cap damage at zero if negative
	call CapMinimumDamage_DE

; OATS poison only does damage on the target's turn
;	ld a, DUELVARS_ARENA_CARD_STATUS
;	call GetTurnDuelistVariable
;	and DOUBLE_POISONED
;	jr z, .not_poisoned
;	ld c, 20
;	and DOUBLE_POISONED & (POISONED ^ $ff)
;	jr nz, .add_poison
;	ld c, 10
;.add_poison
;	ld a, c
;	add e
;	ld e, a
;	ld a, $00
;	adc d
;	ld d, a
;.not_poisoned
	call SwapTurn

; is this enough damage to KO the Defending Pokémon?
.done
	ld a, DUELVARS_ARENA_CARD_HP
	call GetNonTurnDuelistVariable
; subtract 1 from HP so that we get carry if (HP <= damage)
	dec a
	cp e
	pop hl
	ld [hl], e
	ret

; stores in wDamage, wAIMinDamage and wAIMaxDamage the calculated damage
; done to the Pokémon at hTempPlayAreaLocation_ff9d
; by the defending Pokémon, using the attack index at a
; input:
;	a = attack index
;	[hTempPlayAreaLocation_ff9d] = location of card to calculate
;	                               damage as the receiver
EstimateDamage_FromDefendingPokemon: ; 1450b (5:450b)
	call SwapTurn
	ld [wSelectedAttack], a
	ld e, a
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	ld d, a
	call CopyAttackDataAndDamage_FromDeckIndex
	call SwapTurn
	ld a, [wLoadedAttackCategory]
	cp POKEMON_POWER
	jr nz, .is_attack

; is a Pokémon Power
; set wDamage, wDamageFlags, wAIMinDamage and wAIMaxDamage to zero
	ld hl, wDamage
	xor a
	ld [hli], a
	ld [hl], a  ; wDamageFlags
	ld [wAIMinDamage], a
	ld [wAIMaxDamage], a
	ld e, a
	ld d, a
	ret

.is_attack
; set wAIMinDamage and wAIMaxDamage to damage of attack
; these values take into account the range of damage
; that the attack can span (e.g. min and max number of hits)
	ld a, [wDamage]
	ld [wAIMinDamage], a
	ld [wAIMaxDamage], a
	call SwapTurn
	ldh a, [hTempPlayAreaLocation_ff9d]
	push af
	xor a
	ldh [hTempPlayAreaLocation_ff9d], a
	ld a, EFFECTCMDTYPE_AI
	call TryExecuteEffectCommandFunction
	pop af
	ldh [hTempPlayAreaLocation_ff9d], a
	call SwapTurn
	ld a, [wAIMinDamage]
	ld hl, wAIMaxDamage
	or [hl]
	jr nz, .calculation
	ld a, [wDamage]
	ld [wAIMinDamage], a
	ld [wAIMaxDamage], a

.calculation
; if temp. location is active, damage calculation can be done directly...
	ldh a, [hTempPlayAreaLocation_ff9d]
	or a
	jr z, CalculateDamage_FromDefendingPokemon

; ...otherwise substatuses need to be temporarily reset to account
; for the switching, to obtain the right damage calculation...
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS1
	call GetTurnDuelistVariable
	push af
	push hl
	ld [hl], $00
	; reset substatus2
	ld l, DUELVARS_ARENA_CARD_SUBSTATUS2
	ld a, [hl]
	push af
	push hl
	ld [hl], $00
	; reset changed resistance
	ld l, DUELVARS_ARENA_CARD_CHANGED_RESISTANCE
	ld a, [hl]
	push af
	push hl
	ld [hl], $00
	call CalculateDamage_FromDefendingPokemon
; ...and subsequently recovered to continue the duel normally
	pop hl
	pop af
	ld [hl], a
	pop hl
	pop af
	ld [hl], a
	pop hl
	pop af
	ld [hl], a
	ret

; similar to CalculateDamage_VersusDefendingPokemon but reversed,
; calculating damage of the defending Pokémon versus
; the card located in hTempPlayAreaLocation_ff9d
; taking into account weakness/resistance/pluspowers/defenders/etc
; and poison damage for two turns
; and outputs the result capped at a max of $ff
; input:
;	[wAIMinDamage] = base damage
;	[wAIMaxDamage] = base damage
;	[wDamage]      = base damage
;	[hTempPlayAreaLocation_ff9d] = location of card to calculate
;								 damage as the receiver
CalculateDamage_FromDefendingPokemon: ; 1458c (5:458c)
	ld hl, wAIMinDamage
	call .CalculateDamage
	ld hl, wAIMaxDamage
	call .CalculateDamage
	ld hl, wDamage
	; fallthrough

.CalculateDamage ; 1459b (5:459b)
	ld e, [hl]
	ld d, $00
	push hl

	; load player active card's data
	call SwapTurn
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2ID]
	ld [wTempTurnDuelistCardID], a
	call SwapTurn

	; load opponent's card data
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2ID]
	ld [wTempNonTurnDuelistCardID], a

	call SwapTurn
; 1. apply damage bonus effects
	call HandleDamageBonusSubstatus
	call HandleDamageBoostingPowers
; 2. apply weakness bonus
	ld a, [wDamageFlags]
	bit UNAFFECTED_BY_WEAKNESS_RESISTANCE_F, a
	jr nz, .apply_pluspower
; handle weakness
	call SwapTurn
	ldh a, [hTempPlayAreaLocation_ff9d]
	call GetPlayAreaCardWeakness
	call SwapTurn
	ld b, a
	call GetArenaCardColor
	call TranslateColorToWR
	ld [wAttackerColorAsWR], a
	and b
	jr z, .apply_pluspower
	call ApplyWeaknessToDamage_DE

; 3. apply pluspower bonuses
.apply_pluspower
	ld b, CARD_LOCATION_ARENA
	call ApplyAttachedPluspower
; 4. cap damage at 250
	call CapMaximumDamage_DE
; 5. apply resistance
	ld a, [wDamageFlags]
	bit UNAFFECTED_BY_WEAKNESS_RESISTANCE_F, a
	jr nz, .apply_defender
	bit UNAFFECTED_BY_RESISTANCE_F, a
	jr nz, .apply_defender
; affected by Resistance
	call SwapTurn
	ldh a, [hTempPlayAreaLocation_ff9d]
	call GetPlayAreaCardResistance
	call SwapTurn
	ld b, a
	ld a, [wAttackerColorAsWR]
	and b
	call nz, ReduceDamageBy30_DE

; 6. apply Defender reduction
.apply_defender
	call SwapTurn
	ldh a, [hTempPlayAreaLocation_ff9d]
	add CARD_LOCATION_ARENA
	ld b, a
	call ApplyAttachedDefender
; 7. apply damage reduction effects
	ldh a, [hTempPlayAreaLocation_ff9d]
	or a
	jr nz, .no_damage_reduction
	call HandleDefenderDamageReductionEffects
	call HandleAttackerDamageReductionEffects
	xor a  ; PLAY_AREA_ARENA
; 8. cap damage at zero if negative
.no_damage_reduction
	call HandleDamageReducingPowers
	call CapMinimumDamage_DE

	ldh a, [hTempPlayAreaLocation_ff9d]
	or a
	jr nz, .done

; OATS Poison only deals damage on the target's turn
	ld a, DUELVARS_ARENA_CARD_STATUS
	call GetTurnDuelistVariable
	and DOUBLE_POISONED
	jr z, .done
	; ld c, 40
	ld hl, 20
	and DOUBLE_POISONED & (POISONED ^ $ff)
	jr nz, .add_poison
	; ld c, 20
	ld hl, 10
.add_poison
	call AddToDamage_DE
	call CapMaximumDamage_DE

.done
	pop hl
	ld [hl], e
	ret
