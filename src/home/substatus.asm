; doubles the damage at de if swords dance or focus energy was used
; in the last turn by the turn holder's arena Pokemon
; also applies other damage bonus effects based on the Defender's substatus 1
; or the attacker's substatus 2.
; preserves: bc
HandleDamageBonusSubstatus:
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS3
	call GetTurnDuelistVariable
	bit SUBSTATUS3_THIS_TURN_DOUBLE_DAMAGE, [hl]
	call nz, DoubleDE

	ld a, DUELVARS_ARENA_CARD_SUBSTATUS1
	call GetNonTurnDuelistVariable
	cp SUBSTATUS1_VULNERABLE_40
	ret nz
	ld hl, 40
	jp AddToDamage_DE

; check if the attacking card (non-turn holder's arena card) has any substatus that
; reduces the damage dealt this turn (SUBSTATUS2).
; damage is given in de as input and the possibly updated damage is also returned in de.
; preserves: bc
HandleAttackerDamageReductionEffects:
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS2
	call GetNonTurnDuelistVariable
	or a
	ret z
	cp SUBSTATUS2_REDUCE_BY_20
	jp z, ReduceDamageBy20_DE
	cp SUBSTATUS2_REDUCE_BY_10
	jp z, ReduceDamageBy10_DE
	ret

; check if the defending card (turn holder's arena card) has any substatus that
; reduces the damage dealt to it this turn. (SUBSTATUS1 or Pkmn Powers)
; damage is given in de as input and the possibly updated damage is also returned in de.
HandleDefenderDamageReductionEffects:
	ld a, [wNoDamageOrEffect]
	or a
	jr z, .substatus1
; no damage
	ld de, 0
	ret
.substatus1
	call HandleDefenderDamageReduction_Substatus
.pkmn_power
	call CheckCannotUseDueToStatus
	ret c
	; jr HandleDefenderDamageReduction_PokemonPowers
	; fallthrough

HandleDefenderDamageReduction_PokemonPowers:
	ld a, [wLoadedAttackCategory]
	cp POKEMON_POWER
	ret z
	ld a, [wTempNonTurnDuelistCardID]
	cp MR_MIME
	jr z, .prevent_30_or_more_damage ; invisible wall
	cp MAROWAK_LV26
	jp z, ReduceDamageBy20_DE ; Battle Armor
	cp KAKUNA
	jp z, ReduceDamageBy20_DE ; Exoskeleton
	cp CLOYSTER
	jp z, ReduceDamageBy20_DE ; Exoskeleton
	cp KABUTO
	jp z, HalveDamage_DE ; kabuto armor
	ret

.prevent_30_or_more_damage
	ld bc, 30
	call CompareDEtoBC
	ret c  ; de < 30
	ld de, 0
	ret


HandleDefenderDamageReduction_Substatus:
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS1
	call GetTurnDuelistVariable
	or a
	ret z
	cp SUBSTATUS1_NO_DAMAGE_FROM_BASIC
	jr z, .no_damage_from_basic
	cp SUBSTATUS1_NO_DAMAGE
	jr z, .no_damage
	cp SUBSTATUS1_REDUCE_BY_10
	jp z, ReduceDamageBy10_DE
	cp SUBSTATUS1_REDUCE_BY_20
	jp z, ReduceDamageBy20_DE
	cp SUBSTATUS1_HARDEN
	jr z, .prevent_less_than_40_damage
	cp SUBSTATUS1_HALVE_DAMAGE
	call z, HalveDamage_DE

.no_damage_from_basic
	ld a, DUELVARS_ARENA_CARD_STAGE
	call GetNonTurnDuelistVariable
	or a
	ret nz  ; not a Basic Pokémon
.no_damage
	ld de, 0
	ret

.prevent_less_than_40_damage
	ld bc, 40
	call CompareDEtoBC
	ret nc  ; de >= 40
	ld de, 0
	ret


; check for Invisible Wall, Kabuto Armor, NShield, or Transparency, in order to
; possibly reduce or make zero the damage at de.
; TODO FIXME this function can be refactored and eliminated
HandleDamageReductionOrNoDamageFromPkmnPowerEffects:
	ld a, [wLoadedAttackCategory]
	cp POKEMON_POWER
	ret z
.attack
	call ArePokemonPowersDisabled
	ret c
	ld a, [wTempPlayAreaLocation_cceb]
	or a
	jr z, .not_bench
	call IsBodyguardActive
	jr c, .no_damage
	call HandleDefenderDamageReduction_PokemonPowers
.not_bench
	push de ; push damage from call above, which handles Invisible Wall and Kabuto Armor
	call HandleNoDamageOrEffectSubstatus.pkmn_power
	; call nc, HandleTransparency
	pop de ; restore damage
	ret nc
; if carry was set due to NShield or Transparency, damage is 0
.no_damage
	ld de, 0
	ret


; return carry if NShield or Transparency activate (if MEW_LV8 or HAUNTER_LV17 is
; the turn holder's arena Pokemon), and print their corresponding text if so
HandleNShieldAndTransparency:
	push de
	ld a, DUELVARS_ARENA_CARD
	add e
	call GetTurnDuelistVariable
	call GetCardIDFromDeckIndex
	ld a, e
	cp MEW_LV8
	jr z, .nshield
	; cp HAUNTER_LV17
	; jr z, .transparency
.done
	pop de
	or a
	ret
.nshield
	ld a, DUELVARS_ARENA_CARD_STAGE
	call GetNonTurnDuelistVariable
	or a
	jr z, .done
	ld a, NO_DAMAGE_OR_EFFECT_NSHIELD
	ld [wNoDamageOrEffect], a
	ldtx hl, NoDamageOrEffectDueToNShieldText
.print_text
	call DrawWideTextBox_WaitForInput
	pop de
	scf
	ret
; .transparency
; 	xor a
; 	ld [wDuelDisplayedScreen], a
; 	ldtx de, TransparencyCheckText
; 	call TossCoin
; 	jr nc, .done
; 	ld a, NO_DAMAGE_OR_EFFECT_TRANSPARENCY
; 	ld [wNoDamageOrEffect], a
; 	ldtx hl, NoDamageOrEffectDueToTransparencyText
; 	jr .print_text

; return carry if the turn holder's arena Pokemon is under a condition that makes
; it unable to attack. also return in hl the text id to be displayed
HandleCantAttackSubstatus:
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS2
	call GetTurnDuelistVariable
	or a
	ret z
	ldtx hl, UnableToAttackDueToEffectText
	cp SUBSTATUS2_UNABLE_ATTACK
	jr z, .return_with_cant_attack
	or a
	ret
.return_with_cant_attack
	scf
	ret

; return carry if the turn holder's arena Pokemon cannot use
; selected attack at wSelectedAttack due to amnesia
HandleAmnesiaSubstatus:
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS2
	call GetTurnDuelistVariable
	or a
	jr nz, .check_amnesia
	ret
.check_amnesia
	cp SUBSTATUS2_AMNESIA
	jr z, .affected_by_amnesia
.not_the_disabled_atk
	or a
	ret
.affected_by_amnesia
	ld a, DUELVARS_ARENA_CARD_DISABLED_ATTACK_INDEX
	call GetTurnDuelistVariable
	ld a, [wSelectedAttack]
	cp [hl]
	jr nz, .not_the_disabled_atk
	ldtx hl, UnableToUseAttackDueToAmnesiaText
	scf
	ret

; return carry if the turn holder's attack was unsuccessful due to reduced accuracy effect
HandleReducedAccuracySubstatus:
	call CheckReducedAccuracySubstatus
	ret nc
	call TossCoin
	ld [wGotHeadsFromAccuracyCheck], a
	ccf
	ret nc
	ldtx hl, AttackUnsuccessfulText
	call DrawWideTextBox_WaitForInput
	scf
	ret

; return carry if the turn holder's arena card is under the effects of reduced accuracy
CheckReducedAccuracySubstatus:
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS2
	call GetTurnDuelistVariable
	or a
	ret z
	ldtx de, AccuracyCheckText
	cp SUBSTATUS2_ACCURACY
	jr z, .card_is_affected
	or a
	ret
.card_is_affected
	ld a, [wGotHeadsFromAccuracyCheck]
	or a
	ret nz
	scf
	ret

; return carry if the defending card (turn holder's arena card) is under a substatus
; that prevents any damage or effect dealt to it for a turn.
; also return the cause of the substatus in wNoDamageOrEffect
HandleNoDamageOrEffectSubstatus:
	xor a
	ld [wNoDamageOrEffect], a
	ld a, [wLoadedAttackCategory]
	cp POKEMON_POWER
	ret z
.attack
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS1
	call GetTurnDuelistVariable
	ld e, NO_DAMAGE_OR_EFFECT_FLY
	ldtx hl, NoDamageOrEffectDueToFlyText
	cp SUBSTATUS1_FLY
	jr z, .no_damage_or_effect
	ld e, NO_DAMAGE_OR_EFFECT_BARRIER
	ldtx hl, NoDamageOrEffectDueToBarrierText
	cp SUBSTATUS1_BARRIER
	jr z, .no_damage_or_effect
	call CheckCannotUseDueToStatus
	ccf
	ret nc

.pkmn_power
	ld a, [wTempNonTurnDuelistCardID]
	cp MEW_LV8
	jr z, .neutralizing_shield
	or a
	ret

.no_damage_or_effect
	ld a, e
	ld [wNoDamageOrEffect], a
	scf
	ret

.neutralizing_shield
	ld a, [wIsDamageToSelf]
	or a
	ret nz

; prevent damage if attacked by a non-basic Pokemon
	ld a, [wTempTurnDuelistCardID]
	ld e, a
	ld d, $0
	call LoadCardDataToBuffer2_FromCardID
	ld a, [wLoadedCard2Stage]
	or a
	ret z

	ld e, NO_DAMAGE_OR_EFFECT_NSHIELD
	ldtx hl, NoDamageOrEffectDueToNShieldText
	jr .no_damage_or_effect


; if the Pokemon being attacked is HAUNTER_LV17, and its Transparency is active,
; there is a 50% chance that any damage or effect is prevented
; return carry if damage is prevented
; HandleTransparency:
; 	ld a, [wTempNonTurnDuelistCardID]
; 	cp HAUNTER_LV17
; 	jr z, .transparency
; .done
; 	or a
; 	ret
; .transparency
; 	ld a, [wLoadedAttackCategory]
; 	cp POKEMON_POWER
; 	jr z, .done ; Transparency has no effect against Pkmn Powers
; 	call CheckCannotUseDueToStatus
; 	jr c, .done
; 	xor a
; 	ld [wDuelDisplayedScreen], a
; 	ldtx de, TransparencyCheckText
; 	call TossCoin
; 	ret nc
; 	ld a, NO_DAMAGE_OR_EFFECT_TRANSPARENCY
; 	ld [wNoDamageOrEffect], a
; 	ldtx hl, NoDamageOrEffectDueToTransparencyText
; 	scf
; 	ret

; return carry and return the appropriate text id in hl if the target has an
; special status or power that prevents any damage or effect done to it this turn
; input: a = NO_DAMAGE_OR_EFFECT_*
CheckNoDamageOrEffect:
	ld a, [wNoDamageOrEffect]
	or a
	ret z
	bit 7, a
	jr nz, .dont_print_text ; already been here so don't repeat the text
	ld hl, wNoDamageOrEffect
	set 7, [hl]
	dec a
	add a
	ld e, a
	ld d, $0
	ld hl, NoDamageOrEffectTextIDTable
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	scf
	ret

.dont_print_text
	ld hl, $0000
	scf
	ret

NoDamageOrEffectTextIDTable:
	tx NoDamageText                          ; NO_DAMAGE_OR_EFFECT_UNUSED
	tx NoDamageOrEffectDueToBarrierText      ; NO_DAMAGE_OR_EFFECT_BARRIER
	tx NoDamageOrEffectDueToFlyText          ; NO_DAMAGE_OR_EFFECT_FLY
	tx NoDamageOrEffectDueToTransparencyText ; NO_DAMAGE_OR_EFFECT_TRANSPARENCY
	tx NoDamageOrEffectDueToNShieldText      ; NO_DAMAGE_OR_EFFECT_NSHIELD

; returns carry if turn holder's card in location a is paralyzed, asleep, confused,
; and/or toxic gas in play, meaning that attack and/or pkmn power cannot be used
; preserves: bc, de
CheckCannotUseDueToStatus_Anywhere:
	add DUELVARS_ARENA_CARD_STATUS
	jr CheckCannotUseDueToStatus_OnlyToxicGasIfANon0.status_check

; returns carry if turn holder's arena card is paralyzed, asleep, confused,
; and/or toxic gas in play, meaning that attack and/or pkmn power cannot be used
; preserves: bc, de
CheckCannotUseDueToStatus:
	xor a  ; PLAY_AREA_ARENA

; same as above, but if a is non-0, only toxic gas is checked
; preserves: bc, de
CheckCannotUseDueToStatus_OnlyToxicGasIfANon0:
	or a
	jr nz, .check_toxic_gas
	ld a, DUELVARS_ARENA_CARD_STATUS
.status_check
	call GetTurnDuelistVariable
	and CNF_SLP_PRZ
	ldtx hl, CannotUseDueToStatusText
	scf
	ret nz  ; return carry
.check_toxic_gas
	call ArePokemonPowersDisabled
	ret nc
	ldtx hl, UnableToUsePkmnPowerText
	ret


; Check whether Toxic Gas (Weezing) or other Pokémon Power cancelling
; effects are currently active.
; preserves: bc, de
; outputs:
;   a: 1 if Pokémon Powers cannot be used | 0
;   carry: set if Pokémon Powers cannot be used
ArePokemonPowersDisabled:
	call IsToxicGasActive
	ld a, 1
	ret c
	ld a, DUELVARS_MISC_TURN_FLAGS
	call GetTurnDuelistVariable
	and 1 << TURN_FLAG_PKMN_POWERS_DISABLED_F
	ret z
	ld a, 1
	scf
	ret


; Check whether Toxic Gas (Weezing) is found in either player's Active Spot,
; and whether it is Pokémon Power capable.
; Returns carry if the Pokémon card is at least found once.
; outputs:
;   a: 0 if not found; 1 if found
;   carry: set iff found
; preserves: hl, bc, de
IsToxicGasActive:
	push bc
	ld c, WEEZING
	call IsActiveSpotPokemonPowerActive
	pop bc
	ret

; Check whether a given Pokémon is found in either player's Active Spot,
; and whether it is Pokémon Power capable.
; Returns carry if the Pokémon card is at least found once.
; input:
;   c: ID of the Pokémon to check
; outputs:
;   a: 0 if not found; 1 if found
;   carry: set iff found
; preserves: hl, bc, de
IsActiveSpotPokemonPowerActive:
	push hl
	push de
	; push bc
	; ld a, WEEZING
	; ld [wTempPokemonID_ce7c], a
	call .check_active_spot
	jr c, .found
	call SwapTurn
	call .check_active_spot
	call SwapTurn
	; jr c, .found
; not found
	; xor a
.found
	; pop bc
	pop de
	pop hl
	ret

.check_active_spot
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
; check if it is the right Pokémon
	call GetCardIDFromDeckIndex  ; preserves bc
	ld a, e
	cp c
	jr z, .is_this_pokemon
.nope
	xor a  ; reset carry
	ret
.is_this_pokemon
; check if the Pokémon is affected with a status condition
	ld a, DUELVARS_ARENA_CARD_STATUS
	call GetTurnDuelistVariable
	and CNF_SLP_PRZ
	jr nz, .nope
	ld a, 1
	scf
	ret


; return carry if turn holder has Mew and its Clairvoyance Pkmn Power is active
; preserves: bc, de
IsClairvoyanceActive:
	call ArePokemonPowersDisabled
	ccf
	ret nc
	ld a, MEW_LV15
	jp GetFirstPokemonWithAvailablePower


; return carry if turn holder has Marowak and its Bodyguard Pkmn Power is active
; preserves: bc, de
IsBodyguardActive:
	call ArePokemonPowersDisabled  ; preserves: bc, de
	ccf
	ret nc
	ld a, 0  ; TODO insert Pokémon ID
	jp GetFirstPokemonWithAvailablePower  ; preserves: hl, bc, de


; return carry if a Pokémon Power capable Aerodactyl
; is found in either player's Active Spot.
; preserves: hl, bc, de
IsPrehistoricPowerActive:
	push bc
	ld c, AERODACTYL
	call IsActiveSpotPokemonPowerActive
	pop bc
	ret


; returns carry if the turn holder's Pokémon in the given location
; benefits from Dark Retribution
; input:
;   a: PLAY_AREA_* of the Pokémon benefiting from the Power
; output:
;   carry: set if Dark Retribution is active
IsDarkRetributionActive:
	ld b, a
	ld c, DARKNESS
	ld e, NIDORINO
	jr IsSpecialEnergyPowerActive


; returns carry if the turn holder's Pokémon in the given location
; benefits from Stone Skin
; input:
;   a: PLAY_AREA_* of the Pokémon benefiting from the Power
; output:
;   carry: set if Stone Skin is active
IsStoneSkinActive:
	ld b, a
	ld c, FIGHTING
	ld e, GRAVELER
	jr IsSpecialEnergyPowerActive


; returns carry if the turn holder's Active Pokémon benefits
; from Fighting Fury
; output:
;   carry: set if Fighting Fury is active
IsFightingFuryActive:
	ld b, PLAY_AREA_ARENA
	ld c, FIGHTING
	ld e, MACHOKE
	; jr IsSpecialEnergyPowerActive
	; fallthrough


; returns carry if the turn holder's Pokémon Power
; that enhances Energies is active
; input:
;   b: PLAY_AREA_* of the Pokémon benefiting from the Power
;   c: color of the energy to look for
;   e: ID of the Pokémon granting the Power
; output:
;   carry: set if the Power is active
IsSpecialEnergyPowerActive:
	call ArePokemonPowersDisabled  ; preserves bc, de
	ccf
	ret nc
	ld a, e
	call GetFirstPokemonWithAvailablePower  ; preserves hl, bc, de
	ret nc  ; not found
; Feedback is returned in wAttachedEnergies and wTotalAttachedEnergies.
	ld e, b
	call GetPlayAreaCardAttachedEnergies  ; preserves hl, bc, de
	ld hl, wAttachedEnergies
	ld b, 0  ; bc is color offset
	add hl, bc
	ld a, [hl]
	cp 1
	ccf
	ret


; return, in a, the amount of times that the Pokemon card with a given ID is found in the
; play area of both duelists. Also return carry if the Pokemon card is at least found once.
; if the arena Pokemon is asleep, confused, or paralyzed (Pkmn Power-incapable), it doesn't count.
; input: a = Pokemon card ID to search
CountPokemonIDInBothPlayAreas:
	push bc
	ld [wTempPokemonID_ce7c], a
	call CountPokemonIDInPlayArea
	ld c, a
	call SwapTurn
	ld a, [wTempPokemonID_ce7c]
	call CountPokemonIDInPlayArea
	call SwapTurn
	add c
	or a
	scf
	jr nz, .found
	or a
.found
	pop bc
	ret

; return, in a, the amount of times that the Pokemon card with a given ID is found in the
; turn holder's play area. Also return carry if the Pokemon card is at least found once.
; if the Pokemon is asleep, confused, or paralyzed (Pkmn Power-incapable), it doesn't count.
; input: a = Pokemon card ID to search
; preserves: hl, bc, de
CountPokemonIDInPlayArea:
	push hl
	push de
	push bc
	ld [wTempPokemonID_ce7c], a
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld b, a
	ld c, 0
	or a
	jr z, .found
.loop_play_area
	ld a, DUELVARS_ARENA_CARD
	add b
	dec a  ; b starts at 1, we want a 0-based index
	call GetTurnDuelistVariable
	cp $ff
	jr z, .done
; check if it is the right Pokémon
	call GetCardIDFromDeckIndex
	ld a, [wTempPokemonID_ce7c]
	cp e
	jr nz, .skip
; check if the Pokémon is affected with a status condition
	ld a, DUELVARS_ARENA_CARD_STATUS
	add b
	dec a  ; b starts at 1, we want a 0-based index
	call GetTurnDuelistVariable
	and CNF_SLP_PRZ
	jr nz, .skip
	inc c
.skip
	dec b
	jr nz, .loop_play_area
.done
	ld a, c
	or a
	scf
	jr nz, .found
	or a
.found
	pop bc
	pop de
	pop hl
	ret


; Similar to CountPokemonIDInPlayArea, but returns the PLAY_AREA_* location of
; the first Pokémon Power capable Pokémon with the given ID in play.
; If a Pokémon is Asleep, Confused, or Paralyzed (Power-incapable), it does not count.
; If a Pokémon's Power has been used this turn, it does not count.
; Returns $ff if no Pokémon is found.
; input:
;   a: Pokémon card ID to search
; output:
;   a: PLAY_AREA_* of the first Pokémon with given ID | $ff
;   carry: set if a Pokémon is found
; preserves: hl, bc, de
GetFirstPokemonWithAvailablePower:
	push hl
	push de
	push bc
	ld [wTempPokemonID_ce7c], a
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld c, a  ; loop counter
	ld b, 0  ; use b as a 0-based index
; optimize: assume that hl is already in DUELVARS
.loop_play_area
	ld a, DUELVARS_ARENA_CARD
	add b
	ld l, a
	ld a, [hl]
	cp $ff
	jr z, .done
; check if it is the right Pokémon
	call GetCardIDFromDeckIndex
	ld a, [wTempPokemonID_ce7c]
	cp e
	jr nz, .skip
; check if the Pokémon is affected with a status condition
	ld a, DUELVARS_ARENA_CARD_STATUS
	add b
	ld l, a
	ld a, [hl]
	and CNF_SLP_PRZ
	jr nz, .skip
; check if this Pokémon's Power has been used
	ld a, DUELVARS_ARENA_CARD_FLAGS
	add b
	ld l, a
	ld a, [hl]
	and USED_PKMN_POWER_THIS_TURN
	jr nz, .skip
; found a valid Pokémon
	ld a, b  ; get the PLAY_AREA_* offset
	scf
	jr .found
.skip
	inc b
	dec c
	jr nz, .loop_play_area
	ld a, $ff
.done
	or a
.found
	pop bc
	pop de
	pop hl
	ret


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

.no_more_bench
	ld a, c
	or a
	jr nz, .modified_cost
.powers_disabled
	ld a, [wLoadedCard1RetreatCost] ; return regular retreat cost
	ret
.modified_cost
	ld a, [wLoadedCard1RetreatCost]
	sub c  ; apply Retreat Aid for each Pkmn Power-capable Dodrio
	ret nc
	xor a
	ret

; return carry if the turn holder's arena Pokemon is affected by Acid and can't retreat
CheckCantRetreatDueToAcid:
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS2
	call GetTurnDuelistVariable
	or a
	ret z
	cp SUBSTATUS2_UNABLE_RETREAT
	jr z, .cant_retreat
	or a
	ret
.cant_retreat
	ldtx hl, UnableToRetreatDueToTrapText
	scf
	ret

; return carry if the turn holder is affected by Headache and trainer cards can't be used
CheckCantUseTrainerDueToHeadache:
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS3
	call GetTurnDuelistVariable
	or a
	bit SUBSTATUS3_HEADACHE, [hl]
	ret z
	ldtx hl, UnableToUseTrainerDueToHeadacheText
	scf
	ret


; clears some SUBSTATUS2 conditions from the turn holder's active Pokemon.
; more specifically, those conditions that reduce the damage from an attack
; or prevent the opposing Pokemon from attacking the substatus condition inducer.
ClearDamageReductionSubstatus2:
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS2
	call GetTurnDuelistVariable
	or a
	ret z
	cp SUBSTATUS2_REDUCE_BY_20
	jr z, .zero
	cp SUBSTATUS2_REDUCE_BY_10
	jr z, .zero
	cp SUBSTATUS2_UNABLE_ATTACK
	jr z, .zero
	ret
.zero
	ld [hl], 0
	ret

; clears the SUBSTATUS1 and updates the double damage condition of the player about to start his turn
UpdateSubstatusConditions_StartOfTurn:
	ld a, $ff
	ld [wEnergyColorOverride], a
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS1
	call GetTurnDuelistVariable
	ld [hl], $0
	or a
	ret z
	cp SUBSTATUS1_NEXT_TURN_DOUBLE_DAMAGE
	jr z, .double_damage
	cp SUBSTATUS1_NEXT_TURN_UNABLE_ATTACK
	ret nz

; .unable_to_attack
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS2
	call GetTurnDuelistVariable
	ld [hl], SUBSTATUS2_UNABLE_ATTACK
	ret

.double_damage
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS3
	call GetTurnDuelistVariable
	set SUBSTATUS3_THIS_TURN_DOUBLE_DAMAGE, [hl]
	ret

; clears the SUBSTATUS2, Headache, and updates the double damage condition
; and the "became active" condition of the player ending his turn
UpdateSubstatusConditions_EndOfTurn:
	ld a, DUELVARS_MISC_TURN_FLAGS
	call GetTurnDuelistVariable
	res TURN_FLAG_PKMN_POWERS_DISABLED_F, [hl]
	res TURN_FLAG_TOSSED_TAILS_F, [hl]
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS3
	call GetTurnDuelistVariable
	res SUBSTATUS3_HEADACHE, [hl]
	res SUBSTATUS3_THIS_TURN_ACTIVE, [hl]
	push hl
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS2
	call GetTurnDuelistVariable
	xor a
	ld [hl], a
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS1
	call GetTurnDuelistVariable
	pop hl
	cp SUBSTATUS1_NEXT_TURN_DOUBLE_DAMAGE
	ret z
	res SUBSTATUS3_THIS_TURN_DOUBLE_DAMAGE, [hl]
	ret

; return carry if turn holder has Wartortle and its Rain Dance Pkmn Power is active
IsRainDanceActive:
	; ld a, [wAlreadyPlayedEnergyOrSupporter]
	; and USED_RAIN_DANCE_THIS_TURN
	; ret nz ; return if Rain Dance was already used this turn
	ld a, WARTORTLE
	call CountPokemonIDInPlayArea
	ret nc ; return if no Pkmn Power-capable Wartortle found in turn holder's play area
	call ArePokemonPowersDisabled
	ccf
	ret


; if the defending (non-turn) card's HP is 0 and the attacking (turn) card's HP
;  is not, the attacking card faints if it was affected by destiny bond
HandleDestinyBondSubstatus:
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS1
	call GetNonTurnDuelistVariable
	cp SUBSTATUS1_DESTINY_BOND
	ret nz

	ld a, DUELVARS_ARENA_CARD
	call GetNonTurnDuelistVariable
	cp $ff
	ret z

	ld a, DUELVARS_ARENA_CARD_HP
	call GetNonTurnDuelistVariable
	or a
	ret nz

	ld a, DUELVARS_ARENA_CARD_HP
	call GetTurnDuelistVariable
	or a
	ret z

	ld [hl], 0
	push hl
	call DrawDuelMainScene
	call DrawDuelHUDs
	pop hl
	ld l, DUELVARS_ARENA_CARD
	ld a, [hl]
	call LoadCardDataToBuffer2_FromDeckIndex
	ld hl, wLoadedCard2Name
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call LoadTxRam2
	ldtx hl, KnockedOutDueToDestinyBondText
	jp DrawWideTextBox_WaitForInput


; If a Strikes Back ability is active, the attacking Pokémon
; (turn holder's arena Pokémon) takes damage back.
; Used to bounce back an attack of the RESIDUAL category.
; Used to handle direct damage in the Active spot after an attack.
HandleStrikeBack_AfterDirectAttack:
	ld a, [wLoadedAttackCategory]
	and RESIDUAL
	ret nz

; not a RESIDUAL attack
	ld a, [wDealtDamage]
	or a
	ret z

; damaging attack
	call SwapTurn
	call IsCounterattackActive
	call SwapTurn
	ret nc  ; not active or no capable Pokémon

	; de: amount of counter damage to deal
	call ApplyCounterattackDamage
	jp c, DrawDuelHUDs
	ret


; If a Strikes Back ability is active, the attacking Pokémon
; (non-turn holder's arena Pokémon) takes damage back.
; Ignore if damage taken at de is 0.
; Used to bounce back a damaging attack.
; This is called with turns swapped (turn holder is the defender).
HandleStrikeBack_AgainstDamagingAttack:
	ld a, e
	or d
	ret z

; do not counter recoil or confusion damage
	ld a, [wIsDamageToSelf]
	or a
	ret nz

; do not counter damage from Pokémon Powers
	ld a, [wLoadedAttackCategory]
	cp POKEMON_POWER
	ret z

; do not counter damage while on the bench
	ld a, [wTempPlayAreaLocation_cceb]  ; defending Pokemon's PLAY_AREA_*
	or a
	ret nz  ; bench

; do not counter if the Pokémon Power is disabled or not available	
	call IsCounterattackActive
	ret nc  ; not active or no capable Pokémon
	ccf

; assume: no carry is set at this point
; back up wTempTurnDuelistCardID (not sure if needed)
	ld a, [wTempTurnDuelistCardID]
	push af  ; ld [wMultiPurposeByte], a

; subtract HP from attacking Pokémon (non-turn holder's arena Pokémon)
	call SwapTurn
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	push de  ; amount of counter damage to deal
	call GetCardIDFromDeckIndex
	ld a, e
	ld [wTempTurnDuelistCardID], a
	pop de  ; amount of counter damage to deal

	call ApplyCounterattackDamage
	; not sure if these assignments are needed
	ld a, [wLoadedCard2ID]
	ld [wTempNonTurnDuelistCardID], a

; restore backed up variables
	pop af  ; ld a, [wMultiPurposeByte]
	ld [wTempTurnDuelistCardID], a
	jp SwapTurn


; subtract HP from the attacking Pokémon due to a counter attack
; input:
;   e: damage to be dealt
; output:
;   z: set if no Knock Out due to damage
;   carry: set if Knock Out occurred
ApplyCounterattackDamage:
	push de
	ld l, e
	ld h, 0
	call LoadTxRam3
	ld a, [wTempTurnDuelistCardID]
	ld e, a
	ld d, 0
	call LoadCardDataToBuffer2_FromCardID
	ld hl, wLoadedCard2Name
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call LoadTxRam2
	ld a, DUELVARS_ARENA_CARD_HP
	call GetTurnDuelistVariable
	pop de
	push af
	push hl
	call SubtractHP
	ldtx hl, ReceivesDamageDueToStrikeBackText
	call DrawWideTextBox_WaitForInput
	pop hl
	pop af
	or a
	ret z
	xor a  ; PLAY_AREA_ARENA
	call PrintPlayAreaCardKnockedOutIfNoHP
	scf
	ret


; Checks whether the target Pokémon in the turn holder's play area
; is capable of dealing counterattack damage.
; input:
;   wTempNonTurnDuelistCardID: ID of the target Pokémon receiving damage
; output:
;   carry: set if counterattack damage is active
;   de: amount of counter damage to deal
IsCounterattackActive:
	ld de, 0

; do not counter if the defender's Pokémon Power is disabled
; ArePokemonPowersDisabled is called here
	; ld a, [wTempPlayAreaLocation_cceb]  ; defending Pokemon's PLAY_AREA_*
	; call CheckCannotUseDueToStatus_Anywhere  ; preserves de
	call CheckCannotUseDueToStatus  ; preserves de
	jr c, .dark_retribution

; check the ID of the defending Pokémon
	ld a, [wTempNonTurnDuelistCardID]
	cp MACHAMP
	; ld hl, 20  ; damage to return
	; call z, AddToDamage_DE
	jr nz, .dark_retribution
	ld de, 20  ; damage to return

.dark_retribution
	push de
	xor a  ; PLAY_AREA_ARENA
	call IsDarkRetributionActive
	pop de
	jr nc, .rocky_helmet  ; not active
	ld hl, 10
	call AddToDamage_DE

.rocky_helmet
	; TODO

; carry set if non-zero damage
	call CapMaximumDamage_DE
	ld a, e
	cp 1
	ccf
	ret


; if the id of the arena card is WEEZING,
; clear the changed type of all arena and bench Pokémon
ClearChangedTypesIfWeezing:
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call GetCardIDFromDeckIndex
	ld a, e
	cp WEEZING
	ret nz

	call SwapTurn
	call .zero_changed_types
	call SwapTurn
.zero_changed_types
	ld a, DUELVARS_ARENA_CARD_CHANGED_TYPE
	call GetTurnDuelistVariable
	ld c, MAX_PLAY_AREA_POKEMON
.zero_changed_types_loop
	xor a
	ld [hli], a
	dec c
	jr nz, .zero_changed_types_loop
	ret
