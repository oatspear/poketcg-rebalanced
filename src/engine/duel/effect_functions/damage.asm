; ------------------------------------------------------------------------------
; Recoil
; ------------------------------------------------------------------------------


Thunderpunch_RecoilEffect:
	ldh a, [hTemp_ffa0]
	or a
	ret nz ; return if got heads
	; fallthrough

Recoil10Effect:
	ld a, 10
	jp DealRecoilDamageToSelf

Recoil20Effect:
	ld a, 20
	jp DealRecoilDamageToSelf


; ------------------------------------------------------------------------------
; Targeted Damage
; ------------------------------------------------------------------------------


Deal10DamageToTarget_DamageEffect:
	ld de, 10
	jr DealDamageToTarget_DE_DamageEffect

Deal20DamageToTarget_DamageEffect:
	ld de, 20
	jr DealDamageToTarget_DE_DamageEffect

Deal30DamageToTarget_DamageEffect:
	ld de, 30
	; jr DealDamageToTarget_DE_DamageEffect
	; fallthrough


; Deals DE damage to 1 of the opponent's Pokémon
DealDamageToTarget_DE_DamageEffect:
	ldh a, [hTempPlayAreaLocation_ffa1]
	cp $ff
	ret z
	call SwapTurn
	; ldh a, [hTempPlayAreaLocation_ffa1]
	ld b, a
	; ld de, 30
	call DealDamageToPlayAreaPokemon_RegularAnim
	jp SwapTurn


; ------------------------------------------------------------------------------
; Targeted Damage - Player Selection
; ------------------------------------------------------------------------------


; can choose any Pokémon in Play Area
DamageTargetPokemon_PlayerSelectEffect:
	xor a  ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ffa1], a
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	cp 2
	jr c, .done ; has no Bench Pokemon

	ldtx hl, ChoosePkmnToGiveDamageText
	call DrawWideTextBox_WaitForInput
	call SwapTurn
	bank1call HasAlivePokemonInPlayArea

.loop_input
	bank1call OpenPlayAreaScreenForSelection
	jr c, .loop_input
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTempPlayAreaLocation_ffa1], a
	call SwapTurn
.done
	or a
	ret


DamageTargetBenchedPokemon_PlayerSelectEffect:
	ld a, $ff
	ldh [hTempPlayAreaLocation_ffa1], a
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	cp 2
	ret c ; has no Bench Pokemon

	ldtx hl, ChoosePkmnInTheBenchToGiveDamageText
	call DrawWideTextBox_WaitForInput
	call SwapTurn
	bank1call HasAlivePokemonInBench

.loop_input
	bank1call OpenPlayAreaScreenForSelection
	jr c, .loop_input
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTempPlayAreaLocation_ffa1], a
	jp SwapTurn


; ------------------------------------------------------------------------------
; Targeted Damage - AI Selection
; ------------------------------------------------------------------------------


; can choose any Pokémon in Play Area
DamageTargetPokemon_AISelectEffect:
	xor a  ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ffa1], a
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	cp 2
	jr c, .done ; has no Bench Pokemon
; AI always picks Pokemon with lowest HP remaining
	call GetOpponentBenchPokemonWithLowestHP
; amount of HP remaining is in e
	ldh [hTempPlayAreaLocation_ffa1], a
	ld a, DUELVARS_ARENA_CARD_HP
	call GetNonTurnDuelistVariable
	ld a, e
	cp [hl]
	jr c, .done  ; got minimum
; arena is lower
	xor a
	ldh [hTempPlayAreaLocation_ffa1], a
.done
	or a
	ret


DamageTargetBenchedPokemon_AISelectEffect:
	ld a, $ff
	ldh [hTempPlayAreaLocation_ffa1], a
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	cp 2
	ret c ; has no Bench Pokemon
; AI always picks Pokemon with lowest HP remaining
	call GetOpponentBenchPokemonWithLowestHP
	ldh [hTempPlayAreaLocation_ffa1], a
	ret


; ------------------------------------------------------------------------------
; Passive Damage - Pokémon Powers
; ------------------------------------------------------------------------------

SpikesDamageEffect:
	call ArePokemonPowersDisabled
	ret c  ; Powers are disabled
	call SwapTurn
	ld a, SANDSLASH
	call CountPokemonIDInPlayArea
	call SwapTurn
	or a
	ret z  ; no Sandslash in the opponent's Play Area
	ld e, PLAY_AREA_ARENA
	jp Put1DamageCounterOnTarget
