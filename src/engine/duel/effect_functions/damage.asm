; ------------------------------------------------------------------------------
; Recoil
; ------------------------------------------------------------------------------

Recoil10Effect:
	ld a, 10
	jp DealRecoilDamageToSelf

Recoil20Effect:
	ld a, 20
	jp DealRecoilDamageToSelf

Recoil30Effect:
	ld a, 30
	jp DealRecoilDamageToSelf

Recoil40Effect:
	ld a, 40
	jp DealRecoilDamageToSelf

Recoil50Effect:
	ld a, 50
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

Deal40DamageToTarget_DamageEffect:
	ld de, 40
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


Deal10DamageToFriendlyTarget_DamageEffect:
	ld de, 10
	jr DealDamageToFriendlyTarget_DE_DamageEffect

Deal20DamageToFriendlyTarget_DamageEffect:
	ld de, 20
	jr DealDamageToFriendlyTarget_DE_DamageEffect

Deal30DamageToFriendlyTarget_DamageEffect:
	ld de, 30
	; jr DealDamageToFriendlyTarget_DE_DamageEffect
	; fallthrough

; Deals DE damage to 1 of the turn holder's Pokémon
DealDamageToFriendlyTarget_DE_DamageEffect:
	ldh a, [hTempPlayAreaLocation_ffa1]
	cp $ff
	ret z
	ld b, a
	jp DealDamageToPlayAreaPokemon_RegularAnim


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
	call DamageTargetBenchedPokemon_PlayerSelectEffect.loop_input
.done
	or a
	ret


DamageTargetBenchedPokemonIfAny_PlayerSelectEffect:
	ld a, $ff
	ldh [hTempPlayAreaLocation_ffa1], a
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	cp 2
	ret c ; has no Bench Pokemon
	; fallthrough

DamageTargetBenchedPokemon_PlayerSelectEffect:
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


DamageFriendlyBenchedPokemonIfAny_PlayerSelectEffect:
	call SwapTurn
	call DamageTargetBenchedPokemonIfAny_PlayerSelectEffect
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


DamageTargetBenchedPokemonIfAny_AISelectEffect:
	ld a, $ff
	ldh [hTempPlayAreaLocation_ffa1], a
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	cp 2
	ret c ; has no Bench Pokemon
	; fallthrough

DamageTargetBenchedPokemon_AISelectEffect:
; AI always picks Pokemon with lowest HP remaining
	call GetOpponentBenchPokemonWithLowestHP
	ldh [hTempPlayAreaLocation_ffa1], a
	ret


DamageFriendlyBenchedPokemonIfAny_AISelectEffect:
	ld a, $ff
	ldh [hTempPlayAreaLocation_ffa1], a
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	cp 2
	ret c ; has no Bench Pokemon
	; fallthrough

DamageFriendlyBenchedPokemon_AISelectEffect:
; AI always picks Pokemon with highest HP remaining
	call GetBenchPokemonWithHighestHP
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

	; ld a, [wDuelDisplayedScreen]
	; cp DUEL_MAIN_SCENE
	; jr z, .main_scene
	; bank1call DrawDuelMainScene
; .main_scene
	ld e, PLAY_AREA_ARENA
	jp Put1DamageCounterOnTarget

	; ld a, DUELVARS_ARENA_CARD
	; call LoadCardNameAndLevelFromVarToRam2
	; ldtx hl, Received10DamageDueToSpikesText
	; jp DrawWideTextBox_WaitForInput
