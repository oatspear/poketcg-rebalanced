;


; doubles the damage at de if swords dance or focus energy was used
; in the last turn by the turn holder's arena Pokemon
HandleDoubleDamageSubstatus:
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS3
	call GetTurnDuelistVariable
	bit SUBSTATUS3_THIS_TURN_DOUBLE_DAMAGE, [hl]
	ret z
; double damage at de
	ld a, e
	or d
	ret z
	sla e
	rl d
	ret


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

;

; Weakness doubles damage if [wDamage] <= 30.
; Otherwise, it adds +30 damage.
ApplyWeaknessToDamage:
	ld a, [wDamage + 1]
	or a
	jr nz, .add_30
	ld a, [wDamage]
	or a
	ret z  ; zero damage
; double damage if <= 30
	cp 30 + 1
	jr c, AddToDamage  ; use damage already in a
.add_30
	ld a, 30
	jr AddToDamage


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

;

SubtractFromDamage_DE:
	cp e
	jr c, .subtract
	ld e, 0
	ret
; e (damage) > a (value to subtract)
; this will produce a negative number; use two's complement
.subtract
	sub e
	cpl    ; invert the bits of a
	inc a  ; add one
	; ld d, 0
	ld e, a
	ret





; doubles the damage output
DoubleDamage_DamageBoostEffect:
  ld a, [wDamage + 1]
  ld d, a
  ld a, [wDamage]
  ld e, a
  or d
  ret z  ; zero damage
  sla e
  rl d
  ld a, e
  ld [wDamage], a
  ld a, d
  ld [wDamage + 1], a
  ret


;

ExcavateEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, SelectedCard_AddToHandFromDiscardPile
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, BonusDamageIfNoCardSelected_DamageBoostEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, RetrieveBasicEnergyOrItemFromDiscardPile_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, Excavate_AISelectEffect
	dbw EFFECTCMDTYPE_AI, Excavate_AIEffect
	db  $00


;
BonusDamageIfNoCardSelected_DamageBoostEffect:
	ldh a, [hTemp_ffa0]
	cp $ff
	ret nz
	ld a, 10
	jp AddToDamage


;
RetrieveBasicEnergyOrItemFromDiscardPile_PlayerSelectEffect:
	ldtx hl, ChooseCardToPlaceInHandText
	call DrawWideTextBox_WaitForInput
	call CreateDiscardPileCardList
	call RemovePokemonCardsFromCardList
	ld c, TYPE_TRAINER_SUPPORTER
	call RemoveCardTypeFromCardList
	ld c, TYPE_ENERGY_DOUBLE_COLORLESS
	call RemoveCardTypeFromCardList
	call HandlePlayerSelectionAnyFromDiscardPileList_AllowCancel
	ldh [hTemp_ffa0], a
	or a  ; ignore carry
	ret


Excavate_AIEffect:
	ld a, (10 + 10) / 2
	lb de, 10, 20
	jp SetExpectedAIDamage

Excavate_AISelectEffect:
	ld a, [wAIMaxDamage]
	or a
; select a card if unable to deal damage
	jr z, RetrieveBasicEnergyOrItemFromDiscardPile_AISelectEffect
; do not select a card if boosted damage is enough to KO
	ld a, DUELVARS_ARENA_CARD_HP
	call GetNonTurnDuelistVariable
	ld a, [wAIMinDamage]
	cp [hl]
	jr nc, RetrieveBasicEnergyOrItemFromDiscardPile_AISelectEffect
	ld a, [wAIMaxDamage]
	cp [hl]
	jr nc, RetrieveBasicEnergyOrItemFromDiscardPile_AISelectEffect
	ld a, $ff
	ldh [hTemp_ffa0], a
	or a  ; ignore carry
	ret


RetrieveBasicEnergyOrItemFromDiscardPile_AISelectEffect:
; AI picks Mysterious Fossil if available
	call CreateItemCardListFromDiscardPile
	ld hl, wDuelTempList
.loop
	ld a, [hli]
	cp $ff
	jr z, RetrieveBasicEnergyFromDiscardPile_AISelectEffect
	call GetCardIDFromDeckIndex
	ld a, e
	cp MYSTERIOUS_FOSSIL
	jr nz, .loop
	ldh [hTemp_ffa0], a
	or a  ; ignore carry
	ret

;

; AquaPunchEffectCommands:
; 	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, AquaPunch_DamageBoostEffect
; 	dbw EFFECTCMDTYPE_AI, AquaPunch_AIEffect
; 	db  $00

;
AquaPunch_DamageBoostEffect:
  call GetNumAttachedWaterEnergy
  ld hl, wAttachedEnergies + FIGHTING
  add [hl]
	call ATimes10
	jp AddToDamage

AquaPunch_AIEffect:
	call AquaPunch_DamageBoostEffect
	jp SetDefiniteAIDamage



DualTypeFightingEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, CheckPokemonPowerCanBeUsed
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DualTypeFighting_ChangeColorEffect
	db  $00


DualTypeFighting_ChangeColorEffect:
	call SetUsedPokemonPowerThisTurn
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld e, a
	call GetPlayAreaCardColor
	cp FIGHTING
	jr z, ResetCardColorEffect

; change color to Fighting
	ld d, FIGHTING
	jr ColorShift_ChangeColorEffect



EnergySplashEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, EnergySplash_AddToHandEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, EnergySplash_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, EnergySplash_AISelectEffect
	db  $00


EnergySplash_PlayerSelectEffect:
	ld a, $ff
	ldh [hTempList], a
	call CreateEnergyCardListFromDiscardPile_OnlyBasic
	jr nc, EnergyConversion_PlayerSelectEffect
	ldtx hl, ThereAreNoEnergyCardsInDiscardPileText
	ccf  ; reset carry
	ret

EnergySplash_AISelectEffect:
EnergyConversion_AISelectEffect:

EnergySplash_AddToHandEffect:
EnergyConversion_AddToHandEffect:


;

MagneticStormEffect: ; 2e7d5 (b:67d5)
	ld a, DUELVARS_CARD_LOCATIONS
	call GetTurnDuelistVariable

; writes in wDuelTempList all deck indices
; of Energy cards attached to Pokemon
; in the Turn Duelist's Play Area.
	ld de, wDuelTempList
	ld c, 0
.loop_card_locations
	ld a, [hl]
	and CARD_LOCATION_PLAY_AREA
	jr z, .next_card_location

; is a card that is in the Play Area
	push hl
	push de
	push bc
	ld a, l
	call GetCardIDFromDeckIndex
	call GetCardType
	pop bc
	pop de
	pop hl
	and TYPE_ENERGY
	jr z, .next_card_location
; is an Energy card attached to Pokemon in Play Area
	ld a, l
	ld [de], a
	inc de
	inc c
.next_card_location
	inc l
	ld a, l
	cp DECK_SIZE
	jr c, .loop_card_locations
	ld a, $ff ; terminating byte
	ld [de], a

; divide number of energy cards
; by number of Pokemon in Play Area
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld b, a
	ld a, c
	ld c, -1
.loop_division
	inc c
	sub b
	jr nc, .loop_division
	; c = floor(a / b)

; evenly divides the Energy cards randomly
; to every Pokemon in the Play Area.
	push bc
	ld hl, wDuelTempList
	call CountCardsInDuelTempList
	call ShuffleCards
	ld d, c
	ld e, PLAY_AREA_ARENA
.start_attach
	ld c, d
	inc c
	jr .check_done
.attach_energy
	ld a, [hli]
	push hl
	push de
	push bc
	call AddCardToHand
	call PutHandCardInPlayArea
	pop bc
	pop de
	pop hl
.check_done
	dec c
	jr nz, .attach_energy
; go to next Pokemon in Play Area
	inc e ; next in Play Area
	dec b
	jr nz, .start_attach
	pop bc

	push hl
	ld hl, hTempList

; fill hTempList with PLAY_AREA_* locations
; that have Pokemon in them.
	push hl
	xor a
.loop_init
	ld [hli], a
	inc a
	cp b
	jr nz, .loop_init
	pop hl

; shuffle them and distribute
; the remaining cards in random order.
	ld a, b
	call ShuffleCards
	pop hl
	ld de, hTempList
.next_random_pokemon
	ld a, [hl]
	cp $ff
	jr z, .done
	push hl
	push de
	ld a, [de]
	ld e, a
	ld a, [hl]
	call AddCardToHand
	call PutHandCardInPlayArea
	pop de
	pop hl
	inc hl
	inc de
	jr .next_random_pokemon

.done
	bank1call DrawDuelMainScene
	bank1call DrawDuelHUDs
	ldtx hl, TheEnergyCardFromPlayAreaWasMovedText
	call DrawWideTextBox_WaitForInput
	xor a
	call Func_2c10b
	ret



;

; return carry if card at [hTempCardIndex_ff98] is a water energy card.
CheckRainDanceScenario:  ; unreferenced
	ldh a, [hTempCardIndex_ff98]
	call GetCardIDFromDeckIndex
	call GetCardType
	cp TYPE_ENERGY_WATER
	jr nz, .done
	; ldh a, [hTempPlayAreaLocation_ff9d]
	; call GetPlayAreaCardColor
	; cp TYPE_PKMN_WATER
	; jr nz, .done
	scf
	ret
.done
	or a
	ret


; input:
;   a: number of coins to flip
;   hl: amount of damage per heads
;   de: text to display
; outputs:
;   a: amount of bonus damage
;   [wCoinTossTotalNum]: number of flipped coins
;   [wCoinTossNumHeads]: number of flipped heads
;   [wCoinTossNumTails]: number of flipped tails
GetDamageBonusPerHeads:
  cp 2
  jr nc, .multiple
  call TossCoin_BankB  ; preserves hl
  jr .post

.multiple
	call TossCoinATimes_BankB  ; preserves hl

.post
; number of heads is in a
  or a
  ret z  ; all tails
  ld h, a  ; store number of heads
  xor a  ; set damage bonus to zero
.loop
  add l  ; add damage per heads
  dec h
  jr nz, .loop
  ret  ; got total bonus damage



; input:
;   a: number of coins to flip
;   d: amount of damage to add for each heads
; outputs:
;   a: amount of damage added
;   h: number of flipped heads
;   l: number of flipped tails
IfHeadsPlusDamage_DamageBoostEffect:
  ld e, a  ; store number of coins
  ld h, 0
	ld l, d  ; store damage in hl
	call LoadTxRam3  ; preserves hl, de
  ld a, e
  ldtx de, DamageCheckIfHeadsPlusDamageText
  cp 2
  jr nc, .multiple
  call TossCoin_BankB  ; preserves hl
  jr .post

.multiple
	call TossCoinATimes_BankB  ; preserves hl

.post
; number of heads is in a
  ld d, l  ; restore damage per heads
  ld h, a  ; store number of heads
  ld a, [wCoinTossTotalNum]
  sub h
  ld l, a  ; store number of tails
  ld a, h
  or a
	ret z ; all tails
  ld e, a  ; store number of heads (a > 0)
  xor a  ; set damage bonus to zero
.loop
  add d  ; add damage per heads
  dec e
  jr nz, .loop
  ld e, a  ; store total bonus damage
  call AddToDamage  ; preserves hl, de
  ld a, e  ; get total bonus damage
  ret




; returns carry if Pkmn Power cannot be used
; or if Arena card is not Charizard.
; this is unused.
EnergyBurnCheck_Unreferenced: ; 2d620 (b:5620)
	call CheckCannotUseDueToStatus
	ret c
	ld a, DUELVARS_ARENA_CARD
	push de
	call GetTurnDuelistVariable
	call GetCardIDFromDeckIndex
	ld a, e
	pop de
	cp CHARIZARD
	jr nz, .not_charizard
	or a
	ret
.not_charizard
	scf
	ret


; possibly unreferenced
Func_2efce: ; 2efce (b:6fce)
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld c, a
	ld l, DUELVARS_ARENA_CARD_HP
	ld de, wce76
.asm_2efd9
	ld a, [de]
	inc de
	ld [hli], a
	dec c
	jr nz, .asm_2efd9
	ret


; possibly unreferenced
Func_2efbc: ; 2efbc (b:6fbc)
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld c, a
	ld l, DUELVARS_ARENA_CARD_HP
	ld de, wce76
.asm_2efc7
	ld a, [hli]
	ld [de], a
	inc de
	dec c
	jr nz, .asm_2efc7
	ret



DragoniteStepInEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, StepIn_BenchCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, StepIn_SwitchEffect
	db  $00


; return carry if cannot use Step In
StepIn_BenchCheck: ; 2eaca (b:6aca)
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	ldtx hl, CanOnlyBeUsedOnTheBenchText
	or a
	jr z, .set_carry

	add DUELVARS_ARENA_CARD_FLAGS
	call GetTurnDuelistVariable
	ldtx hl, OnlyOncePerTurnText
	and USED_PKMN_POWER_THIS_TURN
	jr nz, .set_carry

	ldh a, [hTempPlayAreaLocation_ff9d]
	call CheckCannotUseDueToStatus_Anywhere
	ret

.set_carry
	scf
	ret

StepIn_SwitchEffect: ; 2eae8 (b:6ae8)
	ldh a, [hTemp_ffa0]
	ld e, a
	call SwapArenaWithBenchPokemon
	ld a, DUELVARS_ARENA_CARD_FLAGS
	call GetTurnDuelistVariable
	set USED_PKMN_POWER_THIS_TURN_F, [hl]
	ret




DragoniteHealingWindEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, HealingWind_InitialEffect
	dbw EFFECTCMDTYPE_PKMN_POWER_TRIGGER, HealingWind_PlayAreaHealEffect
	db  $00

;
HealingWind_PlayAreaHealEffect:
; play initial animation
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld b, a
	ld c, $00
	ldh a, [hWhoseTurn]
	ld h, a
	bank1call PlayAttackAnimation
	bank1call WaitAttackAnimation
	ld a, ATK_ANIM_HEALING_WIND_PLAY_AREA
	ld [wLoadedAttackAnimation], a

	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld d, a
	ld e, PLAY_AREA_ARENA
.loop_play_area
	push de
	ld a, e
	ldh [hTempPlayAreaLocation_ff9d], a
	call GetCardDamageAndMaxHP
	or a
	jr z, .next_pkmn ; skip if no damage

; if less than 20 damage, cap recovery at 10 damage
	ld de, 20
	cp e
	jr nc, .heal
	ld e, a

.heal
; add HP to this card
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD_HP
	call GetTurnDuelistVariable
	add e
	ld [hl], a

; play heal animation
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld b, a
	ld c, $01
	ldh a, [hWhoseTurn]
	ld h, a
	bank1call PlayAttackAnimation
	bank1call WaitAttackAnimation
.next_pkmn
	pop de
	inc e
	dec d
	jr nz, .loop_play_area
	ret




; returns carry if Pkmn Power can't be used.
Peek_OncePerTurnCheck: ; 2e29c (b:629c)
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	add DUELVARS_ARENA_CARD_FLAGS
	call GetTurnDuelistVariable
	and USED_PKMN_POWER_THIS_TURN
	jr nz, .already_used
	ldh a, [hTempPlayAreaLocation_ff9d]
	jp CheckCannotUseDueToStatus_Anywhere
.already_used
	ldtx hl, OnlyOncePerTurnText
	scf
	ret

Peek_SelectEffect: ; 2e2b4 (b:62b4)
; set Pkmn Power used flag
	ldh a, [hTemp_ffa0]
	add DUELVARS_ARENA_CARD_FLAGS
	call GetTurnDuelistVariable
	set USED_PKMN_POWER_THIS_TURN_F, [hl]

	ld a, DUELVARS_DUELIST_TYPE
	call GetTurnDuelistVariable
	cp DUELIST_TYPE_LINK_OPP
	jr z, .link_opp
	and DUELIST_TYPE_AI_OPP
	jr nz, .ai_opp

; player
	call Func_3b31
	call HandlePeekSelection
	ldh [hAIPkmnPowerEffectParam], a
	call SerialSend8Bytes
	ret

.link_opp
	call SerialRecv8Bytes
	ldh [hAIPkmnPowerEffectParam], a

.ai_opp
	ldh a, [hAIPkmnPowerEffectParam]
	bit AI_PEEK_TARGET_HAND_F, a
	jr z, .prize_or_deck
	and (~AI_PEEK_TARGET_HAND & $ff) ; unset bit to get deck index
; if masked value is higher than $40, then it means
; that AI chose to look at Player's deck.
; all deck indices will be smaller than $40.
	cp $40
	jr c, .hand
	ldh a, [hAIPkmnPowerEffectParam]
	jr .prize_or_deck

.hand
; AI chose to look at random card in hand,
; so display it to the Player on screen.
	call SwapTurn
	ldtx hl, PeekWasUsedToLookInYourHandText
	bank1call DisplayCardDetailScreen
	call SwapTurn
	ret

.prize_or_deck
; AI chose either a prize card or Player's top deck card,
; so show Play Area and draw cursor appropriately.
	call Func_3b31
	call SwapTurn
	ldh a, [hAIPkmnPowerEffectParam]
	xor $80
	call DrawAIPeekScreen
	call SwapTurn
	ldtx hl, CardPeekWasUsedOnText
	call DrawWideTextBox_WaitForInput
	ret




SpitPoisonEffect:
	ldh a, [hTempPlayAreaLocation_ffa1]
	ld e, a
	or a  ; PLAY_AREA_ARENA ?
	jp nz, PoisonEffect_PlayArea
	ld a, ATK_ANIM_GOO
	ld [wLoadedAttackAnimation], a
	jp PoisonEffect


; Stores in [wAfflictionAffectedPlayArea] the number of which Pokémon to damage
; from status in the opponent's play area.
; Stores 0 if there are no Affliction capable Pokémon in play.
Affliction_CountPokemonAndSetBitVector:
	xor a
	ld [wAfflictionAffectedPlayArea], a

	ld a, HAUNTER_LV22
	call CountPokemonIDInPlayArea
	ret nc  ; none found

	call SwapTurn
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	; or a
	; ret z

	ld b, a  ; loop counter
	ld c, 0  ; status counter
	ld l, DUELVARS_ARENA_CARD_STATUS
.loop_play_area
	ld a, [hli]
	or a
	jr z, .next  ; no status
	inc c
.next
	dec b
	jr nz, .loop_play_area
; end loop, store counter
	ld a, c
	ld [wAfflictionAffectedPlayArea], a
	jp SwapTurn


; Stores in [wAfflictionAffectedPlayArea] a bit vector with which Pokémon to damage
; from status in the opponent's play area.
; Stores 0 if there are no Affliction capable Pokémon in play.
Affliction_CountPokemonAndSetBitVector:
	xor a
	ld [wAfflictionAffectedPlayArea], a

	ld a, HAUNTER_LV22
	call CountPokemonIDInPlayArea
	ret nc  ; none found

	call SwapTurn
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	; or a
	; ret z
; loop from last to first and shift the bit vector to the left
	ld b, 0  ; bit vector
	ld c, a  ; loop counter
	dec a  ; zero-based index
	add DUELVARS_ARENA_CARD_STATUS
	ld l, a
.loop_play_area
	ld a, [hld]
	or a
	jr z, .previous  ; no status
	set 0, b
.previous
	sla b
	dec c
	jr nz, .loop_play_area
; end loop, store bit vector
	ld a, b
	ld [wAfflictionAffectedPlayArea], a
	jp SwapTurn


;
Affliction_DamageEffect:
	ld a, [wAfflictionAffectedPlayArea]
	or a
	ret z

	ld b, a  ; bit vector
	ld d, 10  ; damage
	ld e, PLAY_AREA_ARENA  ; target
	call SwapTurn
	bit PLAY_AREA_ARENA, b
	call nz, ApplyDirectDamage
	inc e
	bit PLAY_AREA_BENCH_1, b
	call nz, ApplyDirectDamage
	inc e
	bit PLAY_AREA_BENCH_2, b
	call nz, ApplyDirectDamage
	inc e
	bit PLAY_AREA_BENCH_3, b
	call nz, ApplyDirectDamage
	inc e
	bit PLAY_AREA_BENCH_4, b
	call nz, ApplyDirectDamage
	inc e
	bit PLAY_AREA_BENCH_5, b
	call nz, ApplyDirectDamage
	jp SwapTurn


;
Affliction_DamageEffect:
	ld a, [wAfflictionAffectedPlayArea]
	or a
	ret z

	ld b, a  ; bit vector
	ld d, 10  ; damage
	ld e, PLAY_AREA_ARENA  ; target
	call SwapTurn
	call DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld c, a  ; loop counter
	sla b
.loop_play_area
	srl b  ; old bit 0 goes to carry
	call c, ApplyDirectDamage
	inc e
	dec c
	jr nz, .loop_play_area
	jp SwapTurn



DarkDrainEffect:
	call DamageAllOpponentBenched10Effect
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	jp HealADamageEffect


DarkMind_PlayerSelectEffect:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	cp 2
	jr nc, .has_bench
; no bench Pokemon to damage.
	ld a, $ff
	ldh [hTemp_ffa0], a
	ret

.has_bench
; opens Play Area screen to select Bench Pokemon
; to damage, and store it before returning.
	ldtx hl, ChoosePkmnInTheBenchToGiveDamageText
	call DrawWideTextBox_WaitForInput
	call SwapTurn
	bank1call HasAlivePokemonInBench
.loop_input
	bank1call OpenPlayAreaScreenForSelection
	jr c, .loop_input
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	call SwapTurn
	ret

DarkMind_AISelectEffect: ; 2d92a (b:592a)
	ld a, $ff
	ldh [hTemp_ffa0], a
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	cp 2
	ret c ; return if no Bench Pokemon
; just pick Pokemon with lowest remaining HP.
	call GetOpponentBenchPokemonWithLowestHP
	ldh [hTemp_ffa0], a
	ret

DarkMind_DamageBenchEffect: ; 2d93c (b:593c)
	ldh a, [hTemp_ffa0]
	cp $ff
	ret z ; no target chosen
	call SwapTurn
	ld b, a
	ld de, 10
	call DealDamageToPlayAreaPokemon_RegularAnim
	call SwapTurn
	ret




; unused
Gale_LoadAnimation: ; 2f0d0 (b:70d0)
	ld a, ATK_ANIM_GALE
	ld [wLoadedAttackAnimation], a
	ret

; unused
Gale_SwitchEffect: ; 2f0d6 (b:70d6)
; if Defending card is unaffected by attack
; jump directly to switching this card only.
	call HandleNoDamageOrEffect
	jr c, .SwitchWithRandomBenchPokemon

; handle switching Defending card
	ld a, DUELVARS_ARENA_CARD_HP
	call GetNonTurnDuelistVariable
	or a
	jr nz, .skip_destiny_bond
	bank1call HandleDestinyBondSubstatus
.skip_destiny_bond
	call SwapTurn
	call .SwitchWithRandomBenchPokemon
	jr c, .skip_clear_damage
; clear dealt damage because Pokemon was switched
	xor a
	ld hl, wDealtDamage
	ld [hli], a
	ld [hl], a
.skip_clear_damage
	call SwapTurn
;	fallthrough for attacking card switch

.SwitchWithRandomBenchPokemon
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	cp 2
	ret c ; return if no Bench Pokemon

; get random Bench location and swap
	dec a
	call Random
	inc a
	ld e, a
	call SwapArenaWithBenchPokemon

	xor a
	ld [wDuelDisplayedScreen], a
	ret




CurseEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Curse_CheckDamageAndBench
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Curse_TransferDamageEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Curse_PlayerSelectEffect
	db  $00

; returns carry if Pkmn Power cannot be used, and
; sets the correct text in hl for failure.
Curse_CheckDamageAndBench: ; 2d7fc (b:57fc)
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a

; fail if Pkmn Power has already been used
	add DUELVARS_ARENA_CARD_FLAGS
	call GetTurnDuelistVariable
	ldtx hl, OnlyOncePerTurnText
	and USED_PKMN_POWER_THIS_TURN
	jr nz, .set_carry

; fail if Opponent only has 1 Pokemon in Play Area
	call SwapTurn
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	call SwapTurn
	ldtx hl, CannotUseSinceTheresOnly1PkmnText
	cp 2
	jr c, .set_carry

; fail if Opponent has no damage counters
	call SwapTurn
	call CheckIfPlayAreaHasAnyDamage
	call SwapTurn
	ret c

; return carry if Pkmn Power cannot be used due
; to Toxic Gas or status.
	ldh a, [hTempPlayAreaLocation_ff9d]
	call CheckCannotUseDueToStatus_Anywhere
	ret

.set_carry
	scf
	ret

;

Curse_PlayerSelectEffect: ; 2d834 (b:5834)
	ldtx hl, ProcedureForCurseText
	bank1call DrawWholeScreenTextBox
	call SwapTurn
	xor a
	ldh [hCurSelectionItem], a
	bank1call Func_61a1
.start
	bank1call PrintPlayAreaCardList_EnableLCD
	push af
	ldh a, [hCurSelectionItem]
	ld hl, PlayAreaSelectionMenuParameters
	call InitializeMenuParameters
	pop af
	ld [wNumMenuItems], a

; first pick a target to take 1 damage counter from.
.loop_input_first
	call DoFrame
	call HandleMenuInput
	jr nc, .loop_input_first
	cp $ff
	jr z, .cancel
	ldh [hCurSelectionItem], a
	ldh [hTempPlayAreaLocation_ffa1], a
	call GetCardDamageAndMaxHP
	or a
	jr nz, .picked_first ; test if has damage
	; play sfx
	call PlaySFX_InvalidChoice
	jr .loop_input_first

.picked_first
; give 10 HP to card selected, draw the scene,
; then immediately revert this.
	ldh a, [hTempPlayAreaLocation_ffa1]
	add DUELVARS_ARENA_CARD_HP
	call GetTurnDuelistVariable
	push af
	push hl
	add 10
	ld [hl], a
	bank1call PrintPlayAreaCardList_EnableLCD
	pop hl
	pop af
	ld [hl], a

; draw damage counter on cursor
	ldh a, [hTempPlayAreaLocation_ffa1]
	ld b, SYM_HP_NOK
	call DrawSymbolOnPlayAreaCursor

; handle input to pick the target to receive the damage counter.
.loop_input_second
	call DoFrame
	call HandleMenuInput
	jr nc, .loop_input_second
	ldh [hPlayAreaEffectTarget], a
	cp $ff
	jr nz, .a_press ; was a pressed?

; b press
; erase the damage counter symbol
; and loop back up again.
	ldh a, [hTempPlayAreaLocation_ffa1]
	ld b, SYM_SPACE
	call DrawSymbolOnPlayAreaCursor
	call EraseCursor
	jr .start

.a_press
	ld hl, hTempPlayAreaLocation_ffa1
	cp [hl]
	jr z, .loop_input_second ; same as first?
; a different Pokemon was picked,
; so store this Play Area location
; and erase the damage counter in the cursor.
	ldh a, [hTempPlayAreaLocation_ffa1]
	ld b, SYM_SPACE
	call DrawSymbolOnPlayAreaCursor
	call EraseCursor
	call SwapTurn
	or a
	ret

.cancel
; return carry if operation was cancelled.
	call SwapTurn
	scf
	ret

Curse_TransferDamageEffect: ; 2d8bb (b:58bb)
; set Pkmn Power as used
	ldh a, [hTempList]
	add DUELVARS_ARENA_CARD_FLAGS
	call GetTurnDuelistVariable
	set USED_PKMN_POWER_THIS_TURN_F, [hl]

; figure out the type of duelist that used Curse.
; if it was the player, no need to draw the Play Area screen.
	call SwapTurn
	ld a, DUELVARS_DUELIST_TYPE
	call GetNonTurnDuelistVariable
	cp DUELIST_TYPE_PLAYER
	jr z, .vs_player

; vs. opponent
	bank1call Func_61a1
.vs_player
; transfer the damage counter to the targets that were selected.
	ldh a, [hPlayAreaEffectTarget]
	add DUELVARS_ARENA_CARD_HP
	call GetTurnDuelistVariable
	sub 10
	ld [hl], a
	ldh a, [hTempPlayAreaLocation_ffa1]
	add DUELVARS_ARENA_CARD_HP
	ld l, a
	ld a, 10
	add [hl]
	ld [hl], a

	bank1call PrintPlayAreaCardList_EnableLCD
	ld a, DUELVARS_DUELIST_TYPE
	call GetNonTurnDuelistVariable
	cp DUELIST_TYPE_PLAYER
	jr z, .done
; vs. opponent
	ldh a, [hPlayAreaEffectTarget]
	ldh [hTempPlayAreaLocation_ff9d], a
	bank1call Func_6194

.done
	call SwapTurn
	call ExchangeRNG
	bank1call Func_6e49
	ret





; if the id of the card provided in register a as a deck index is WEEZING,
; clear the changed type of all arena and bench Pokemon
ClearChangedTypesIfWeezing:
	ld d, a
	; ldh a, [hTempPlayAreaLocation_ff9d]
	; or a
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	cp d
	ret nz  ; not Active spot
	ld a, d
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



; doubles the damage at de if swords dance or focus energy was used
; in the last turn by the turn holder's arena Pokemon
HandleDoubleDamageSubstatus:
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS3
	call GetTurnDuelistVariable
	bit SUBSTATUS3_THIS_TURN_DOUBLE_DAMAGE, [hl]
	call nz, .double_damage_at_de
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS1
	call GetTurnDuelistVariable
	or a
	call nz, .ret1
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS2
	call GetTurnDuelistVariable
	or a
	call nz, .ret2
	ret
.ret1
	ret
.double_damage_at_de
	ld a, e
	or d
	ret z
	sla e
	rl d
	ret
.ret2
	ret



SongOfRest_CheckUse:
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	add DUELVARS_ARENA_CARD_FLAGS
	call GetTurnDuelistVariable
	and USED_PKMN_POWER_THIS_TURN
	jr nz, .already_used

	ldh a, [hTempPlayAreaLocation_ff9d]
	call CheckCannotUseDueToStatus_Anywhere
	ret c  ; can't use PKMN due to status or Toxic Gas

; return carry if no Pokémon has damage counters
	; call CheckIfPlayAreaHasAnyDamage_ExcludeTempLocation
	; ret nc  ; found damage
	; call SwapTurn
	; call CheckIfPlayAreaHasAnyDamage
	; call SwapTurn
	ret  ; carry set if no damage

.already_used
	ldtx hl, OnlyOncePerTurnText
	scf
	ret


; selects a target Pokémon from either play area (player or opponent)
; outputs:
;   [hAIPkmnPowerEffectParam]: 0 if player area, 1 if opponent area
;   [hPlayAreaEffectTarget]: PLAY_AREA_* of the selected card
SongOfRest_PlayerSelectEffect:
; print procedure here, check DevolutionBeam_DevolveEffect
.start
	bank1call DrawDuelMainScene
	ldtx hl, PleaseSelectThePlayAreaText
	call TwoItemHorizontalMenu
	ldh a, [hKeysHeld]
	and B_BUTTON
	jr nz, .set_carry

; a Play Area was selected
	ldtx hl, ChoosePkmnToHealText
	call DrawWideTextBox_WaitForInput

; store Pokémon using the Power
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a

; which play area?
	ldh a, [hCurMenuItem]
	or a
	jr nz, .opp_chosen

; player chosen
	call HandlePlayerSelectionPokemonInPlayArea_AllowCancel
	jr c, .start

	xor a
.store_selection
	ldh [hAIPkmnPowerEffectParam], a ; store which Duelist Play Area selected
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hPlayAreaEffectTarget], a ; store which card selected
	ldh a, [hTemp_ffa0]
	ldh [hTempPlayAreaLocation_ff9d], a ; restore Pokémon Power user
	or a  ; ensure no carry
	ret

.opp_chosen
	call SwapTurn
	call HandlePlayerSelectionPokemonInPlayArea_AllowCancel
	call SwapTurn
	jr c, .start
	ld a, $01
	jr .store_selection

.set_carry
	scf
	ret


; heal up to 20 damage from selected target and put it to sleep
; inputs:
;   [hAIPkmnPowerEffectParam]: 0 if player area, 1 if opponent area
;   [hPlayAreaEffectTarget]: PLAY_AREA_* of the selected card
SongOfRest_HealEffect:
; flag Pkmn Power as being used
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD_FLAGS
	call GetTurnDuelistVariable
	set USED_PKMN_POWER_THIS_TURN_F, [hl]

	ldh a, [hAIPkmnPowerEffectParam]
	or a  ; which play area?
	jr z, .HealSleepEffect

; opponent play area
	call SwapTurn
	call .HealSleepEffect
	jp SwapTurn

.HealSleepEffect
; heal the selected Pokémon
	ldh a, [hPlayAreaEffectTarget]
	ld e, a   ; location
	ld d, 20  ; damage
	push de
	call HealPlayAreaCardHP
	pop de
	call SleepEffect_PlayArea
	jp ExchangeRNG




SmogEffect:
	call DamageAllOpponentBenched10Effect
	ld b, CNF_SLP_PRZ ; mask of status conditions to preserve on the target
	ld c, POISONED ; status condition to inflict to the target
	jp ApplyStatusEffectToAllOpponentBenchedPokemon



NidoqueenBoyfriendsEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, BoyfriendsEffect
	db  $00


BoyfriendsEffect: ; 2c998 (b:4998)
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	ld c, PLAY_AREA_ARENA
.loop
	ld a, [hl]
	cp $ff
	jr z, .done
	call GetCardIDFromDeckIndex
	ld a, e
	cp NIDOKING
	jr nz, .next
	ld a, d
	cp $00 ; why check d? Card IDs are only 1 byte long
	jr nz, .next
	inc c
.next
	inc hl
	jr .loop
.done
; c holds number of Nidoking found in Play Area
	ld a, c
	add a
	call ATimes10
	call AddToDamage ; adds 2 * 10 * c
	ret



TailWagEffect: ; 2e94e (b:694e)
	ldtx de, IfHeadsOpponentCannotAttackText
	call TossCoin_BankB
	jp nc, SetWasUnsuccessful
	ld a, ATK_ANIM_LURE
	ld [wLoadedAttackAnimation], a
	ld a, SUBSTATUS2_UNABLE_ATTACK
	call ApplySubstatus2ToDefendingCard
	ret



MewMysteryAttackEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, MysteryAttack_RandomEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, MysteryAttack_RecoverEffect
	dbw EFFECTCMDTYPE_AI, MysteryAttack_AIEffect
	db  $00

;
MysteryAttack_AIEffect: ; 2e001 (b:6001)
	ld a, 10
	lb de, 0, 20
	jp SetExpectedAIDamage

MysteryAttack_RandomEffect: ; 2e009 (b:6009)
	ld a, 10
	call SetDefiniteDamage

; chooses a random effect from 8 possible options.
	call UpdateRNGSources
	and %111
	ldh [hTemp_ffa0], a
	ld hl, .random_effect
	jp JumpToFunctionInTable

.random_effect
	dw ParalysisEffect
	dw PoisonEffect
	dw SleepEffect
	dw ConfusionEffect
	dw .no_effect ; this will actually activate recovery effect afterwards
	dw .no_effect
	dw .more_damage
	dw .no_damage

.more_damage
	ld a, 20
	call SetDefiniteDamage
	ret

.no_damage
	ld a, ATK_ANIM_GLOW_EFFECT
	ld [wLoadedAttackAnimation], a
	xor a
	call SetDefiniteDamage
	call SetNoEffectFromStatus
.no_effect
	ret

MysteryAttack_RecoverEffect: ; 2e03e (b:603e)
; in case the 5th option was chosen for random effect,
; trigger recovery effect for 10 HP.
	ldh a, [hTemp_ffa0]
	cp 4
	ret nz
	lb de, 0, 10
	call ApplyAndAnimateHPRecovery
	ret




; return carry if Defending Pokemon is not asleep
DreamEaterEffect:
	ld a, DUELVARS_ARENA_CARD_STATUS
	call GetNonTurnDuelistVariable
	and CNF_SLP_PRZ
	cp ASLEEP
	ret z ; return if asleep
; not asleep, set carry and load text
	ldtx hl, OpponentIsNotAsleepText
	scf
	ret


Gigashock_PlayerSelectEffect: ; 2e60d (b:660d)
	call SwapTurn
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	cp 2
	jr nc, .has_bench
	call SwapTurn
	ld a, $ff
	ldh [hTempList], a
	ret

.has_bench
	ldtx hl, ChooseUpTo3PkmnOnBenchToGiveDamageText
	call DrawWideTextBox_WaitForInput

; init number of items in list and cursor position
	xor a
	ldh [hCurSelectionItem], a
	ld [wce72], a
	bank1call Func_61a1
.start
	bank1call PrintPlayAreaCardList_EnableLCD
	push af
	ld a, [wce72]
	ld hl, BenchSelectionMenuParameters
	call InitializeMenuParameters
	pop af

; exclude Arena Pokemon from number of items
	dec a
	ld [wNumMenuItems], a

.loop_input
	call DoFrame
	call HandleMenuInput
	jr nc, .loop_input
	cp -1
	jr z, .try_cancel

	ld [wce72], a
	call .CheckIfChosenAlready
	jr nc, .not_chosen
	; play SFX
	call PlaySFX_InvalidChoice
	jr .loop_input

.not_chosen
; mark this Play Area location
	ldh a, [hCurMenuItem]
	inc a
	ld b, SYM_LIGHTNING
	call DrawSymbolOnPlayAreaCursor
; store it in the list of chosen Bench Pokemon
	call GetNextPositionInTempList
	ldh a, [hCurMenuItem]
	inc a
	ld [hl], a

; check if 3 were chosen already
	ldh a, [hCurSelectionItem]
	ld c, a
	cp 3
	jr nc, .chosen ; check if already chose 3

	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	dec a
	cp c
	jr nz, .start ; if sill more options available, loop back
	; fallthrough if no other options available to choose

.chosen
	ldh a, [hCurMenuItem]
	inc a
	call Func_2c10b
	ldh a, [hKeysPressed]
	and B_BUTTON
	jr nz, .try_cancel
	call SwapTurn
	call GetNextPositionInTempList
	ld [hl], $ff ; terminating byte
	ret

.try_cancel
	ldh a, [hCurSelectionItem]
	or a
	jr z, .start ; none selected, can safely loop back to start

; undo last selection made
	dec a
	ldh [hCurSelectionItem], a
	ld e, a
	ld d, $00
	ld hl, hTempList
	add hl, de
	ld a, [hl]

	push af
	ld b, SYM_SPACE
	call DrawSymbolOnPlayAreaCursor
	call EraseCursor
	pop af

	dec a
	ld [wce72], a
	jr .start

; returns carry if Bench Pokemon
; in register a was already chosen.
.CheckIfChosenAlready: ; 2e6af (b:66af)
	inc a
	ld c, a
	ldh a, [hCurSelectionItem]
	ld b, a
	ld hl, hTempList
	inc b
	jr .next_check
.check_chosen
	ld a, [hli]
	cp c
	scf
	ret z ; return if chosen already
.next_check
	dec b
	jr nz, .check_chosen
	or a
	ret

Gigashock_AISelectEffect: ; 2e6c3 (b:66c3)
; if Bench has 3 Pokemon or less, no need for selection,
; since AI will choose them all.
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	cp MAX_PLAY_AREA_POKEMON - 1
	jr nc, .start_selection

; select them all
	ld hl, hTempList
	ld b, PLAY_AREA_ARENA
	jr .next_bench
.select_bench
	ld [hl], b
	inc hl
.next_bench
	inc b
	dec a
	jr nz, .select_bench
	ld [hl], $ff ; terminating byte
	ret

.start_selection
; has more than 3 Bench cards, proceed to sort them
; by lowest remaining HP to highest, and pick first 3.
	call SwapTurn
	dec a
	ld c, a
	ld b, PLAY_AREA_BENCH_1

; first select all of the Bench Pokemon and write to list
	ld hl, hTempList
.loop_all
	ld [hl], b
	inc hl
	inc b
	dec c
	jr nz, .loop_all
	ld [hl], $00 ; end list with $00

; then check each of the Bench Pokemon HP
; sort them from lowest remaining HP to highest.
	ld de, hTempList
.loop_outer
	ld a, [de]
	add DUELVARS_ARENA_CARD_HP
	call GetTurnDuelistVariable
	ld c, a
	ld l, e
	ld h, d
	inc hl

.loop_inner
	ld a, [hli]
	or a
	jr z, .next ; reaching $00 means it's end of list

	push hl
	add DUELVARS_ARENA_CARD_HP
	call GetTurnDuelistVariable
	pop hl
	cp c
	jr c, .loop_inner
	; a Bench Pokemon was found with less HP
	ld c, a ; store its HP

; switch the two
	dec hl
	ld b, [hl]
	ld a, [de]
	ld [hli], a
	ld a, b
	ld [de], a
	jr .loop_inner

.next
	inc de
	ld a, [de]
	or a
	jr nz, .loop_outer

; done
	ld a, $ff ; terminating byte
	ldh [hTempList + 3], a
	call SwapTurn
	ret

Gigashock_BenchDamageEffect: ; 2e71f (b:671f)
	call SwapTurn
	ld hl, hTempList
.loop_selection
	ld a, [hli]
	cp $ff
	jr z, .done
	push hl
	ld b, a
	ld de, 10
	call DealDamageToPlayAreaPokemon_RegularAnim
	pop hl
	jr .loop_selection
.done
	call SwapTurn
	ret



; return carry if neither Play Area
; has room for more Bench Pokemon.
Wail_BenchCheck: ; 2e31c (b:631c)
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	cp MAX_PLAY_AREA_POKEMON
	jr c, .no_carry
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	cp MAX_PLAY_AREA_POKEMON
	jr c, .no_carry
	ldtx hl, NoSpaceOnTheBenchText
	scf
	ret
.no_carry
	or a
	ret

Wail_FillBenchEffect: ; 2e335 (b:6335)
	call SwapTurn
	call .FillBench
	call SwapTurn
	call .FillBench

; display both Play Areas
	ldtx hl, BasicPokemonWasPlacedOnEachBenchText
	call DrawWideTextBox_WaitForInput
	bank1call HasAlivePokemonInPlayArea
	bank1call OpenPlayAreaScreenForSelection
	call SwapTurn
	bank1call HasAlivePokemonInPlayArea
	bank1call OpenPlayAreaScreenForSelection
	call SwapTurn
	ret

.FillBench ; 2e35a (b:635a)
	call CreateDeckCardList
	ret c
	ld hl, wDuelTempList
	call ShuffleCards

; if no more space in the Bench, then return.
.check_bench
	push hl
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	pop hl
	cp MAX_PLAY_AREA_POKEMON
	jr nc, .done

; there's still space, so look for the next
; Basic Pokemon card to put in the Bench.
.loop
	ld a, [hli]
	ldh [hTempCardIndex_ff98], a
	cp $ff
	jr z, .done
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_ENERGY
	jr nc, .loop ; is Pokemon card?
	ld a, [wLoadedCard2Stage]
	or a
	jr nz, .loop ; is Basic?
; place card in Bench
	push hl
	ldh a, [hTempCardIndex_ff98]
	call SearchCardInDeckAndSetToJustDrawn
	call AddCardToHand
	call PutHandPokemonCardInPlayArea
	pop hl
	jr .check_bench

.done
	call SyncShuffleDeck
	ret


PayDayEffect: ; 2ebe8 (b:6be8)
	ldtx de, IfHeadsDraw1CardFromDeckText
	call TossCoin_BankB
	ret nc ; tails
	ldtx hl, Draw1CardFromTheDeckText
	call DrawWideTextBox_WaitForInput
	bank1call DisplayDrawOneCardScreen
	call DrawCardFromDeck
	ret c ; empty deck
	call AddCardToHand
	call LoadCardDataToBuffer1_FromDeckIndex
	ld a, [wDuelistType]
	cp DUELIST_TYPE_PLAYER
	ret nz
	; show card on screen if it was Player
	bank1call OpenCardPage_FromHand
	ret



MegaDrainEffect: ; 2cb0f (b:4b0f)
	ld hl, wDealtDamage
	ld a, [hli]
	ld h, [hl]
	ld l, a
	srl h
	rr l
	bit 0, l
	jr z, .rounded
	; round up to nearest 10
	ld de, 10 / 2
	add hl, de
.rounded
	ld e, l
	ld d, h
	call ApplyAndAnimateHPRecovery
	ret



;
SpearowMirrorMove_AIEffect: ; 2e97d (b:697d)
	jr MirrorMoveEffects.AIEffect

SpearowMirrorMove_InitialEffect1: ; 2e97f (b:697f)
	jr MirrorMoveEffects.InitialEffect1

SpearowMirrorMove_InitialEffect2: ; 2e981 (b:6981)
	jr MirrorMoveEffects.InitialEffect2

SpearowMirrorMove_PlayerSelection: ; 2e983 (b:6983)
	jr MirrorMoveEffects.PlayerSelection

SpearowMirrorMove_AISelection: ; 2e985 (b:6985)
	jr MirrorMoveEffects.AISelection

SpearowMirrorMove_BeforeDamage: ; 2e987 (b:6987)
	jr MirrorMoveEffects.BeforeDamage

SpearowMirrorMove_AfterDamage: ; 2e989 (b:6989)
	jp MirrorMoveEffects.AfterDamage

; these are effect commands that Mirror Move uses
; in order to mimic last turn's attack.
; it covers all possible effect steps to perform its commands
; (i.e. selection for Amnesia and Energy discarding attacks, etc)
MirrorMoveEffects: ; 2e98c (b:698c)
.AIEffect
	ld a, DUELVARS_ARENA_CARD_LAST_TURN_DAMAGE
	call GetTurnDuelistVariable
	ld a, [hl]
	ld [wAIMinDamage], a
	ld [wAIMaxDamage], a
	ret

.InitialEffect1
	ld a, DUELVARS_ARENA_CARD_LAST_TURN_DAMAGE
	call GetTurnDuelistVariable
	ld a, [hli]
	or [hl]
	inc hl
	or [hl]
	inc hl
	ret nz ; return if has last turn damage
	ld a, [hli]
	or a
	ret nz ; return if has last turn status
	; no attack received last turn
	ldtx hl, YouDidNotReceiveAnAttackToMirrorMoveText
	scf
	ret

.InitialEffect2
	ld a, $ff
	ldh [hTemp_ffa0], a
	ld a, DUELVARS_ARENA_CARD_LAST_TURN_EFFECT
	call GetTurnDuelistVariable
	or a
	ret z ; no effect
	cp LAST_TURN_EFFECT_AMNESIA
	jp z, PlayerPickAttackForAmnesia
	or a
	ret

.PlayerSelection
	ld a, DUELVARS_ARENA_CARD_LAST_TURN_EFFECT
	call GetTurnDuelistVariable
	or a
	ret z ; no effect
; handle Energy card discard effect
	cp LAST_TURN_EFFECT_DISCARD_ENERGY
	jp z, DiscardOpponentEnergy_PlayerSelectEffect
	ret

.AISelection
	ld a, $ff
	ldh [hTemp_ffa0], a
	ld a, DUELVARS_ARENA_CARD_LAST_TURN_EFFECT
	call GetTurnDuelistVariable
	or a
	ret z ; no effect
	cp LAST_TURN_EFFECT_DISCARD_ENERGY
	jr z, .discard_energy
	cp LAST_TURN_EFFECT_AMNESIA
	jr z, .pick_amnesia_attack
	ret

.discard_energy
	call AIPickEnergyCardToDiscardFromDefendingPokemon
	ldh [hTemp_ffa0], a
	ret

.pick_amnesia_attack
	call AIPickAttackForAmnesia
	ldh [hTemp_ffa0], a
	ret

.BeforeDamage
; if was attacked with Amnesia, apply it to the selected attack
	ld a, DUELVARS_ARENA_CARD_LAST_TURN_EFFECT
	call GetTurnDuelistVariable
	cp LAST_TURN_EFFECT_AMNESIA
	jr z, .apply_amnesia

; otherwise, check if there was last turn damage,
; and write it to wDamage.
	ld a, DUELVARS_ARENA_CARD_LAST_TURN_DAMAGE
	call GetTurnDuelistVariable
	ld de, wDamage
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hld]
	ld [de], a
	or [hl]
	jr z, .no_damage
	ld a, ATK_ANIM_HIT
	ld [wLoadedAttackAnimation], a
.no_damage
	inc hl
	inc hl ; DUELVARS_ARENA_CARD_LAST_TURN_STATUS
; check if there was a status applied to Defending Pokemon
; from the attack it used.
	push hl
	ld a, DUELVARS_ARENA_CARD_STATUS
	call GetNonTurnDuelistVariable
	ld e, l
	ld d, h
	pop hl
	ld a, [hli]
	or a
	jr z, .no_status
	push hl
	push de
	call .ExecuteStatusEffect
	pop de
	pop hl
.no_status
; hl is at DUELVARS_ARENA_CARD_LAST_TURN_SUBSTATUS2
; apply substatus2 to self
	ld e, DUELVARS_ARENA_CARD_SUBSTATUS2
	ld a, [hli]
	ld [de], a
	ret

.apply_amnesia
	call ApplyAmnesiaToAttack
	ret

.AfterDamage: ; 2ea28 (b:6a28)
	ld a, [wNoDamageOrEffect]
	or a
	ret nz ; is unaffected
	ld a, DUELVARS_ARENA_CARD_LAST_TURN_EFFECT
	call GetTurnDuelistVariable
	cp LAST_TURN_EFFECT_DISCARD_ENERGY
	jr nz, .change_weakness

; execute Energy discard effect for card chosen
	call SwapTurn
	ldh a, [hTemp_ffa0]
	call PutCardInDiscardPile
	ld a, DUELVARS_ARENA_CARD_LAST_TURN_EFFECT
	call GetTurnDuelistVariable
	ld [hl], LAST_TURN_EFFECT_DISCARD_ENERGY
	call SwapTurn

.change_weakness
	ld a, DUELVARS_ARENA_CARD_LAST_TURN_CHANGE_WEAK
	call GetTurnDuelistVariable
	ld a, [hl]
	or a
	ret z ; weakness wasn't changed last turn

	push hl
	call SwapTurn
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer2_FromDeckIndex
	call SwapTurn
	pop hl

	ld a, [wLoadedCard2Weakness]
	or a
	ret z ; defending Pokemon has no weakness to change

; apply same color weakness to Defending Pokemon
	ld a, [hl]
	push af
	ld a, DUELVARS_ARENA_CARD_CHANGED_WEAKNESS
	call GetNonTurnDuelistVariable
	pop af
	ld [hl], a

; print message of weakness color change
	ld c, -1
.loop_color
	inc c
	rla
	jr nc, .loop_color
	ld a, c
	call SwapTurn
	push af
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer1_FromDeckIndex
	pop af
	call LoadCardNameAndInputColor
	ldtx hl, ChangedTheWeaknessOfPokemonToColorText
	call DrawWideTextBox_PrintText
	call SwapTurn
	ret

.ExecuteStatusEffect: ; 2ea8f (b:6a8f)
	ld c, a
	and PSN_DBLPSN
	jr z, .cnf_slp_prz
	ld b, a
	cp DOUBLE_POISONED
	push bc
	call z, DoublePoisonEffect
	pop bc
	ld a, b
	cp POISONED
	push bc
	call z, PoisonEffect
	pop bc
.cnf_slp_prz
	ld a, c
	and CNF_SLP_PRZ
	ret z
	cp CONFUSED
	jp z, ConfusionEffect
	cp ASLEEP
	jp z, SleepEffect
	cp PARALYZED
	jp z, ParalysisEffect
	ret


;
PidgeottoMirrorMove_AIEffect: ; 2ecef (b:6cef)
	jp MirrorMoveEffects.AIEffect

PidgeottoMirrorMove_InitialEffect1: ; 2ecf2 (b:6cf2)
	jp MirrorMoveEffects.InitialEffect1

PidgeottoMirrorMove_InitialEffect2: ; 2ecf5 (b:6cf5)
	jp MirrorMoveEffects.InitialEffect2

PidgeottoMirrorMove_PlayerSelection: ; 2ecf8 (b:6cf8)
	jp MirrorMoveEffects.PlayerSelection

PidgeottoMirrorMove_AISelection: ; 2ecfb (b:6cfb)
	jp MirrorMoveEffects.AISelection

PidgeottoMirrorMove_BeforeDamage: ; 2ecfe (b:6cfe)
	jp MirrorMoveEffects.BeforeDamage

PidgeottoMirrorMove_AfterDamage: ; 2ed01 (b:6d01)
	jp MirrorMoveEffects.AfterDamage



FlamesOfRage_PlayerSelectEffect:
	ldtx hl, ChooseAndDiscard2FireEnergyCardsText
	call DrawWideTextBox_WaitForInput

	xor a
	ldh [hCurSelectionItem], a
	call CreateListOfFireEnergyAttachedToArena
	xor a
	bank1call DisplayEnergyDiscardScreen
.loop_input
	bank1call HandleEnergyDiscardMenuInput
	ret c
	call GetNextPositionInTempList
	ldh a, [hTempCardIndex_ff98]
	ld [hl], a
	call RemoveCardFromDuelTempList
	ldh a, [hCurSelectionItem]
	cp 2
	ret nc ; return when 2 have been chosen
	bank1call DisplayEnergyDiscardMenu
	jr .loop_input

; return carry if has less than 2 Fire Energy cards
FlamesOfRage_CheckEnergy:
	ld e, PLAY_AREA_ARENA
	call GetPlayAreaCardAttachedEnergies
	call HandleEnergyBurn
	ld a, [wAttachedEnergies + FIRE]
	ldtx hl, NotEnoughFireEnergyText
	cp 2
	ret

FlamesOfRage_AISelectEffect: ; 2d3d5 (b:53d5)
	call AIPickFireEnergyCardToDiscard
	ld a, [wDuelTempList + 1]
	ldh [hTempList + 1], a
	ret

FlamesOfRage_DiscardEffect: ; 2d3de (b:53de)
	ldh a, [hTempList]
	call PutCardInDiscardPile
	ldh a, [hTempList + 1]
	call PutCardInDiscardPile
	ret



;
MixUpEffect: ; 2d647 (b:5647)
	call SwapTurn
	call CreateHandCardList
	call SortCardsInDuelTempListByID

; first go through Hand to place
; all Pkmn cards in it in the Deck.
	ld hl, wDuelTempList
	ld c, 0
.loop_hand
	ld a, [hl]
	cp $ff
	jr z, .done_hand
	call .CheckIfCardIsPkmnCard
	jr nc, .next_hand
	; found Pkmn card, place in deck
	inc c
	ld a, [hl]
	call RemoveCardFromHand
	call ReturnCardToDeck
.next_hand
	inc hl
	jr .loop_hand

.done_hand
	ld a, c
	ldh [hCurSelectionItem], a
	push bc
	ldtx hl, ThePkmnCardsInHandAndDeckWereShuffledText
	call DrawWideTextBox_WaitForInput

	call SyncShuffleDeck
	call CreateDeckCardList
	pop bc
	ldh a, [hCurSelectionItem]
	or a
	jr z, .done ; if no cards were removed from Hand, return

; c holds the number of cards that were placed in the Deck.
; now pick Pkmn cards from the Deck to place in Hand.
	ld hl, wDuelTempList
.loop_deck
	ld a, [hl]
	call .CheckIfCardIsPkmnCard
	jr nc, .next_deck
	dec c
	ld a, [hl]
	call SearchCardInDeckAndSetToJustDrawn
	call AddCardToHand
.next_deck
	inc hl
	ld a, c
	or a
	jr nz, .loop_deck
.done
	call SwapTurn
	ret

; returns carry if card index in a is Pkmn card
.CheckIfCardIsPkmnCard: ; 2d69a (b:569a)
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_ENERGY
	ret


;
DancingEmbers_AIEffect: ; 2d6a3 (b:56a3)
	ld a, 80 / 2
	lb de, 0, 80
	jp SetExpectedAIDamage

DancingEmbers_MultiplierEffect: ; 2d6ab (b:56ab)
	ld hl, 10
	call LoadTxRam3
	ldtx de, DamageCheckIfHeadsXDamageText
	ld a, 8
	call TossCoinATimes_BankB
	call ATimes10
	call SetDefiniteDamage
	ret


; If heads, defending Pokemon can't retreat next turn
UnableToRetreat50PercentEffect:
	ldtx de, TrapCheckText
	call TossCoin_BankB
	ret nc
	; fallthrough to UnableToRetreatEffect



;
PoisonFang_AIEffect: ; 2c730 (b:4730)
	ld a, 10
	lb de, 10, 10
	jp UpdateExpectedAIDamage_AccountForPoison


;
SpitPoison_AIEffect: ; 2c6f0 (b:46f0)
	ld a, 10 / 2
	lb de, 0, 10
	jp SetExpectedAIDamage


;
Recycle_PlayerSelection:
	ld de, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call Serial_TossCoin
	jr nc, .tails

	call CreateDiscardPileCardList
	bank1call InitAndDrawCardListScreenLayout_MenuTypeSelectCheck
	ldtx hl, PleaseSelectCardText
	ldtx de, PlayerDiscardPileText
	bank1call SetCardListHeaderText
.read_input
	bank1call DisplayCardList
	jr c, .read_input ; can't cancel with B button

; Discard Pile card was chosen
	ldh a, [hTempCardIndex_ff98]
	ldh [hTempList], a
	ret

.tails
	ld a, $ff
	ldh [hTempList], a
	or a
	ret



;
; return carry if not enough cards in hand for effect
Maintenance_HandCheck: ; 2fa70 (b:7a70)
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	call GetTurnDuelistVariable
	ldtx hl, NotEnoughCardsInHandText
	cp 3
	ret

Maintenance_PlayerSelection: ; 2fa7b (b:7a7b)
	ldtx hl, Choose2HandCardsFromHandToReturnToDeckText
	ldtx de, ChooseTheCardToPutBackText
	call HandlePlayerSelection2HandCardsExcludeSelf
	ret

Maintenance_ReturnToDeckAndDrawEffect: ; 2fa85 (b:7a85)
; return both selected cards to the deck
	ldh a, [hTempList]
	call RemoveCardFromHand
	call ReturnCardToDeck
	ldh a, [hTempList + 1]
	call RemoveCardFromHand
	call ReturnCardToDeck
	call SyncShuffleDeck

; draw one card
	ld a, 1
	bank1call DisplayDrawNCardsScreen
	call DrawCardFromDeck
	ldh [hTempCardIndex_ff98], a
	call AddCardToHand
	call IsPlayerTurn
	ret nc
	; show card on screen if played by Player
	bank1call DisplayPlayerDrawCardScreen
	ret



;

PokemonCenter_HealDiscardEnergyEffect: ; 2f618 (b:7618)
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld d, a
	ld e, PLAY_AREA_ARENA

; go through every Pokemon in the Play Area
; and heal all damage & discard their Energy cards.
.loop_play_area
; check its damage
	ld a, e
	ldh [hTempPlayAreaLocation_ff9d], a
	call GetCardDamageAndMaxHP
	or a
	jr z, .next_pkmn ; if no damage, skip Pokemon

; heal all its damage
	push de
	ld e, a
	ld d, $00
	call HealPlayAreaCardHP

; loop all cards in deck and for all the Energy cards
; that are attached to this Play Area location Pokemon,
; place them in the Discard Pile.
	ldh a, [hTempPlayAreaLocation_ff9d]
	or CARD_LOCATION_PLAY_AREA
	ld e, a
	ld a, $00
	call GetTurnDuelistVariable
.loop_deck
	ld a, [hl]
	cp e
	jr nz, .next_card_deck ; not attached to card, skip
	ld a, l
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	and TYPE_ENERGY
	jr z, .next_card_deck ; not Energy, skip
	ld a, l
	call PutCardInDiscardPile
.next_card_deck
	inc l
	ld a, l
	cp DECK_SIZE
	jr c, .loop_deck

	pop de
.next_pkmn
	inc e
	dec d
	jr nz, .loop_play_area
	ret


;
; return carry if not enough cards in hand to discard
; or if there are no cards left in the deck.
ComputerSearch_HandDeckCheck: ; 2f513 (b:7513)
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	call GetTurnDuelistVariable
	ldtx hl, NotEnoughCardsInHandText
	cp 3
	ret c
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	call GetTurnDuelistVariable
	ldtx hl, NoCardsLeftInTheDeckText
	cp DECK_SIZE
	ccf
	ret

ComputerSearch_PlayerDiscardHandSelection: ; 2f52a (b:752a)
	call HandlePlayerSelection2HandCardsToDiscardExcludeSelf
	call c, CancelSupporterCard
	ret

ComputerSearch_PlayerDeckSelection: ; 2f52e (b:752e)
	call CreateDeckCardList
	bank1call InitAndDrawCardListScreenLayout_MenuTypeSelectCheck
	ldtx hl, ChooseCardToPlaceInHandText
	ldtx de, DuelistDeckText
	bank1call SetCardListHeaderText
.loop_input
	bank1call DisplayCardList
	jr c, .loop_input ; can't exit with B button
	ldh [hTempList + 2], a
	ret

ComputerSearch_DiscardAddToHandEffect: ; 2f545 (b:7545)
; discard cards from hand
	ld hl, hTempList
	ld a, [hli]
	call RemoveCardFromHand
	call PutCardInDiscardPile
	ld a, [hli]
	call RemoveCardFromHand
	call PutCardInDiscardPile

; add card from deck to hand
	ld a, [hl]
	call SearchCardInDeckAndSetToJustDrawn
	call AddCardToHand
	call SyncShuffleDeck
	ret



;
; return carry if Defending card has no weakness
Conversion1_WeaknessCheck: ; 2edd5 (b:6dd5)
	call SwapTurn
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer2_FromDeckIndex
	call SwapTurn
	ld a, [wLoadedCard2Weakness]
	or a
	ret nz
	ldtx hl, NoWeaknessText
	scf
	ret

Conversion1_PlayerSelectEffect: ; 2eded (b:6ded)
	ldtx hl, ChooseWeaknessYouWishToChangeText
	xor a ; PLAY_AREA_ARENA
	call HandleColorChangeScreen
	ldh [hTemp_ffa0], a
	ret

Conversion1_AISelectEffect: ; 2edf7 (b:6df7)
	call AISelectConversionColor
	ret

Conversion1_ChangeWeaknessEffect: ; 2edfb (b:6dfb)
	call HandleNoDamageOrEffect
	ret c ; is unaffected

; apply changed weakness
	ld a, DUELVARS_ARENA_CARD_CHANGED_WEAKNESS
	call GetNonTurnDuelistVariable
	ldh a, [hTemp_ffa0]
	call TranslateColorToWR
	ld [hl], a
	ld l, DUELVARS_ARENA_CARD_LAST_TURN_CHANGE_WEAK
	ld [hl], a

; print text box
	call SwapTurn
	ldtx hl, ChangedTheWeaknessOfPokemonToColorText
	call PrintArenaCardNameAndColorText
	call SwapTurn

; apply substatus
	ld a, SUBSTATUS2_CONVERSION2
	call ApplySubstatus2ToDefendingCard
	ret


;
; returns carry if Active Pokemon has no Resistance.
Conversion2_ResistanceCheck: ; 2ee1f (b:6e1f)
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Resistance]
	or a
	ret nz
	ldtx hl, NoResistanceText
	scf
	ret

Conversion2_PlayerSelectEffect: ; 2ee31 (b:6e31)
	ldtx hl, ChooseResistanceYouWishToChangeText
	ld a, $80
	call HandleColorChangeScreen
	ldh [hTemp_ffa0], a
	ret

Conversion2_AISelectEffect: ; 2ee3c (b:6e3c)
; AI will choose Defending Pokemon's color
; unless it is colorless.
	call SwapTurn
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer1_FromDeckIndex
	call SwapTurn
	ld a, [wLoadedCard1Type]
	cp COLORLESS
	jr z, .is_colorless
	ldh [hTemp_ffa0], a
	ret

.is_colorless
	call SwapTurn
	call AISelectConversionColor
	call SwapTurn
	ret

Conversion2_ChangeResistanceEffect: ; 2ee5e (b:6e5e)
; apply changed resistance
	ld a, DUELVARS_ARENA_CARD_CHANGED_RESISTANCE
	call GetTurnDuelistVariable
	ldh a, [hTemp_ffa0]
	call TranslateColorToWR
	ld [hl], a
	ldtx hl, ChangedTheResistanceOfPokemonToColorText
;	fallthrough

; prints text that requires card name and color,
; with the card name of the Turn Duelist's Arena Pokemon
; and color in [hTemp_ffa0].
; input:
;	hl = text to print
PrintArenaCardNameAndColorText: ; 2ee6c (b:6e6c)
	push hl
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer1_FromDeckIndex
	ldh a, [hTemp_ffa0]
	call LoadCardNameAndInputColor
	pop hl
	call DrawWideTextBox_PrintText
	ret

; handles AI logic for selecting a new color
; for weakness/resistance.
; - if within the context of Conversion1, looks
; in own Bench for a non-colorless card that can attack.
; - if within the context of Conversion2, looks
; in Player's Bench for a non-colorless card that can attack.
AISelectConversionColor: ; 2ee7f (b:6e7f)
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld d, a
	ld e, PLAY_AREA_ARENA
	jr .next_pkmn_atk

; look for a non-colorless Bench Pokemon
; that has enough energy to use an attack.
.loop_atk
	push de
	call GetPlayAreaCardAttachedEnergies
	ld a, e
	add DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	ld d, a
	call LoadCardDataToBuffer1_FromDeckIndex
	ld a, [wLoadedCard1Type]
	cp COLORLESS
	jr z, .skip_pkmn_atk ; skip colorless Pokemon
	ld e, FIRST_ATTACK_OR_PKMN_POWER
	bank1call _CheckIfEnoughEnergiesToAttack
	jr nc, .found
	ld e, SECOND_ATTACK
	bank1call _CheckIfEnoughEnergiesToAttack
	jr nc, .found
.skip_pkmn_atk
	pop de
.next_pkmn_atk
	inc e
	dec d
	jr nz, .loop_atk

; none found in Bench.
; next, look for a non-colorless Bench Pokemon
; that has any Energy cards attached.
	ld d, e ; number of Play Area Pokemon
	ld e, PLAY_AREA_ARENA
	jr .next_pkmn_energy

.loop_energy
	push de
	call GetPlayAreaCardAttachedEnergies
	ld a, [wTotalAttachedEnergies]
	or a
	jr z, .skip_pkmn_energy
	ld a, e
	add DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	ld d, a
	call LoadCardDataToBuffer1_FromDeckIndex
	ld a, [wLoadedCard1Type]
	cp COLORLESS
	jr nz, .found
.skip_pkmn_energy
	pop de
.next_pkmn_energy
	inc e
	dec d
	jr nz, .loop_energy

; otherwise, just select a random energy.
	ld a, NUM_COLORED_TYPES
	call Random
	ldh [hTemp_ffa0], a
	ret

.found
	pop de
	ld a, [wLoadedCard1Type]
	and TYPE_PKMN
	ldh [hTemp_ffa0], a
	ret


;
BigEggsplosion_AIEffect:
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld e, a
	call GetPlayAreaCardAttachedEnergies
	ld a, [wTotalAttachedEnergies]
	call SetDamageToATimes20
	inc h
	jr nz, .capped
	ld l, 255
.capped
	ld a, l
	ld [wAIMaxDamage], a
	srl a
	ld [wAIMinDamage], a
	ld l, a
	srl a
	add l
	ld [wDamage], a
	ret

; Flip coins equal to attached energies; deal 20 damage per heads
BigEggsplosion_MultiplierEffect:
	ld e, PLAY_AREA_ARENA
	call GetPlayAreaCardAttachedEnergies
	ld hl, 20
	call LoadTxRam3
	ld a, [wTotalAttachedEnergies]
	ldtx de, DamageCheckIfHeadsXDamageText
	call TossCoinATimes_BankB
; fallthrough

; set damage to 20*a. Also return result in hl
SetDamageToATimes20:
	ld l, a
	ld h, $00
	ld e, l
	ld d, h
	add hl, hl
	add hl, hl
	add hl, de
	add hl, hl
	add hl, hl
	ld a, l
	ld [wDamage], a
	ld a, h
	ld [wDamage + 1], a
	ret



;
; return carry if Arena card has no status to heal.
FullHeal_StatusCheck: ; 2f4c5 (b:74c5)
	ld a, DUELVARS_ARENA_CARD_STATUS
	call GetTurnDuelistVariable
	or a
	ret nz
	ldtx hl, NotAffectedByPoisonSleepParalysisOrConfusionText
	scf
	ret

FullHeal_ClearStatusEffect: ; 2f4d1 (b:74d1)
	ld a, ATK_ANIM_FULL_HEAL
	call PlayAttackAnimation_AdhocEffect
	ld a, DUELVARS_ARENA_CARD_STATUS
	call GetTurnDuelistVariable
	ld [hl], NO_STATUS
	bank1call DrawDuelHUDs
	ret



;

; returns carry if neither duelist has any energy cards attached
SuperEnergyRemoval_EnergyCheck: ; 2fcd0 (b:7cd0)
	call CheckIfThereAreAnyEnergyCardsAttached
	ldtx hl, NoEnergyCardsAttachedToPokemonInYourPlayAreaText
	ret c
	call SwapTurn
	call CheckIfThereAreAnyEnergyCardsAttached
	ldtx hl, NoEnergyCardsAttachedToPokemonInOppPlayAreaText
	call SwapTurn
	ret

SuperEnergyRemoval_PlayerSelection: ; 2fce4 (b:7ce4)
; handle selection of Energy to discard in own Play Area
	ldtx hl, ChoosePokemonInYourAreaThenPokemonInYourOppText
	call DrawWideTextBox_WaitForInput
	call HandlePokemonAndEnergySelectionScreen
	call c, CancelSupporterCard
	ret c ; return if operation was cancelled

	ldtx hl, ChoosePokemonToRemoveEnergyFromText
	call DrawWideTextBox_WaitForInput

	call SwapTurn
	ld a, 3
	ldh [hCurSelectionItem], a
.select_opp_pkmn
	bank1call HasAlivePokemonInPlayArea
	bank1call OpenPlayAreaScreenForSelection
	jr nc, .opp_pkmn_selected
	; B was pressed
	call SwapTurn
	call CancelSupporterCard
	ret ; return if operation was cancelled
.opp_pkmn_selected
	ld e, a
	call GetPlayAreaCardAttachedEnergies
	ld a, [wTotalAttachedEnergies]
	or a
	jr nz, .has_energy ; has any energy cards attached?
	; no energy, loop back
	ldtx hl, NoEnergyCardsText
	call DrawWideTextBox_WaitForInput
	jr .select_opp_pkmn

.has_energy
; store this Pokemon's Play Area location
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hPlayAreaEffectTarget], a
; store which energy card to discard from it
	call CreateArenaOrBenchEnergyCardList
	ldh a, [hTempPlayAreaLocation_ff9d]
	bank1call DisplayEnergyDiscardScreen
	ld a, 2
	ld [wEnergyDiscardMenuDenominator], a

.loop_discard_energy_selection
	bank1call HandleEnergyDiscardMenuInput
	jr nc, .energy_selected
	; B pressed
	ld a, 5
	call AskWhetherToQuitSelectingCards
	jr nc, .done ; finish operation
	; player selected to continue selection
	ld a, [wEnergyDiscardMenuNumerator]
	push af
	ldh a, [hTempPlayAreaLocation_ff9d]
	bank1call DisplayEnergyDiscardScreen
	ld a, 2
	ld [wEnergyDiscardMenuDenominator], a
	pop af
	ld [wEnergyDiscardMenuNumerator], a
	jr .loop_discard_energy_selection

.energy_selected
; store energy cards to discard from opponent
	call GetNextPositionInTempList
	ldh a, [hTempCardIndex_ff98]
	ld [hl], a
	call RemoveCardFromDuelTempList
	ld hl, wEnergyDiscardMenuNumerator
	inc [hl]
	ldh a, [hCurSelectionItem]
	cp 5
	jr nc, .done ; no more energy cards to select
	ld a, [wDuelTempList]
	cp $ff
	jr z, .done ; no more energy cards to select
	bank1call DisplayEnergyDiscardMenu
	jr .loop_discard_energy_selection

.done
	call GetNextPositionInTempList
	ld [hl], $ff
	call SwapTurn
	or a
	ret

SuperEnergyRemoval_DiscardEffect: ; 2fd73 (b:7d73)
	ld hl, hTempList + 1

; discard energy card of own Play Area
	ld a, [hli]
	call PutCardInDiscardPile

; iterate and discard opponent's energy cards
	inc hl
	call SwapTurn
.loop
	ld a, [hli]
	cp $ff
	jr z, .done_discard
	call PutCardInDiscardPile
	jr .loop

.done_discard
; if it's Player's turn, return...
	call SwapTurn
	call IsPlayerTurn
	ret c
; ...otherwise show Play Area of affected Pokemon
; in opponent's Play Area
	ldh a, [hTemp_ffa0]
	call Func_2c10b
; in player's Play Area
	xor a
	ld [wDuelDisplayedScreen], a
	call SwapTurn
	ldh a, [hPlayAreaEffectTarget]
	call Func_2c10b
	call SwapTurn
	ret



;
; return carry if not enough cards in hand to
; discard for Super Energy Retrieval effect
; or if the Discard Pile has no basic Energy cards
SuperEnergyRetrieval_HandEnergyCheck: ; 2fda4 (b:7da4)
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	call GetTurnDuelistVariable
	ldtx hl, NotEnoughCardsInHandText
	cp 3
	ret c
	call CreateEnergyCardListFromDiscardPile_OnlyBasic
	ldtx hl, ThereAreNoBasicEnergyCardsInDiscardPileText
	ret

SuperEnergyRetrieval_PlayerHandSelection: ; 2fdb6 (b:7db6)
	call HandlePlayerSelection2HandCardsToDiscardExcludeSelf
	call c, CancelSupporterCard
	ret

SuperEnergyRetrieval_PlayerDiscardPileSelection: ; 2fdba (b:7dba)
	ldtx hl, ChooseUpTo4FromDiscardPileText
	call DrawWideTextBox_WaitForInput
	call CreateEnergyCardListFromDiscardPile_OnlyBasic

.loop_discard_pile_selection
	bank1call InitAndDrawCardListScreenLayout
	ldtx hl, PleaseSelectCardText
	ldtx de, PlayerDiscardPileText
	bank1call SetCardListHeaderText
	bank1call DisplayCardList
	jr nc, .store_selected_card
	; B pressed
	ld a, 6
	call AskWhetherToQuitSelectingCards
	jr c, .loop_discard_pile_selection ; player selected to continue
	jr .done

.store_selected_card
	ldh a, [hTempCardIndex_ff98]
	call GetTurnDuelistVariable
	call GetNextPositionInTempList
	ldh a, [hTempCardIndex_ff98]
	ld [hl], a ; store selected energy card
	call RemoveCardFromDuelTempList
	jr c, .done
	; this shouldn't happen
	ldh a, [hCurSelectionItem]
	cp 6
	jr c, .loop_discard_pile_selection

.done
; insert terminating byte
	call GetNextPositionInTempList
	ld [hl], $ff
	or a
	ret

SuperEnergyRetrieval_DiscardAndAddToHandEffect: ; 2fdfa (b:7dfa)
; discard 2 cards selected from the hand
	ld hl, hTemp_ffa0
	ld a, [hli]
	call RemoveCardFromHand
	call PutCardInDiscardPile
	ld a, [hli]
	call RemoveCardFromHand
	call PutCardInDiscardPile

; put selected cards in hand
	ld de, wDuelTempList
.loop
	ld a, [hli]
	ld [de], a
	inc de
	cp $ff
	jr z, .done
	call MoveDiscardPileCardToHand
	call AddCardToHand
	jr .loop

.done
; if Player played the card, exit
	call IsPlayerTurn
	ret c
; if not, show card list selected by Opponent
	bank1call DisplayCardListDetails
	ret


;
WithdrawEffect: ; 2d120 (b:5120)
	ldtx de, IfHeadsNoDamageNextTurnText
	call TossCoin_BankB
	jp nc, SetWasUnsuccessful
	ld a, ATK_ANIM_PROTECT
	ld [wLoadedAttackAnimation], a
	ld a, SUBSTATUS1_NO_DAMAGE_10
	call ApplySubstatus1ToAttackingCard
	ret


;

;
ThunderJolt_Recoil50PercentEffect: ; 2e51a (b:651a)
	ld hl, 10
	call LoadTxRam3
	ldtx de, IfTailsDamageToYourselfTooText
	call TossCoin_BankB
	ldh [hTemp_ffa0], a
	ret

ThunderJolt_RecoilEffect: ; 2e529 (b:6529)
	ld hl, 10
	call LoadTxRam3
	jp Thrash_RecoilEffect



;


LeerEffect: ; 2e21d (b:621d)
	ldtx de, IfHeadsOpponentCannotAttackText
	call TossCoin_BankB
	jp nc, SetWasUnsuccessful
	ld a, ATK_ANIM_LEER
	ld [wLoadedAttackAnimation], a
	ld a, SUBSTATUS2_LEER
	call ApplySubstatus2ToDefendingCard
	ret

BoneAttackEffect: ; 2e30f (b:630f)
	ldtx de, IfHeadsOpponentCannotAttackText
	call TossCoin_BankB
	ret nc
	ld a, SUBSTATUS2_UNABLE_ATTACK
	call ApplySubstatus2ToDefendingCard
	ret


;
SeadraAgilityEffect: ; 2d08b (b:508b)
	ldtx de, IfHeadsDoNotReceiveDamageOrEffectText
	call TossCoin_BankB
	ret nc ; return if tails
	ld a, ATK_ANIM_AGILITY_PROTECT
	ld [wLoadedAttackAnimation], a
	ld a, SUBSTATUS1_AGILITY
	call ApplySubstatus1ToAttackingCard
	ret


;
SeadraWaterGunEffect: ; 2d085 (b:5085)
	lb bc, 1, 1
	jp ApplyExtraWaterEnergyDamageBonus

VaporeonWaterGunEffect: ; 2d0d3 (b:50d3)
	lb bc, 2, 0
	jp ApplyExtraWaterEnergyDamageBonus

PoliwrathWaterGunEffect: ; 2d1e0 (b:51e0)
	lb bc, 1, 1
	jp ApplyExtraWaterEnergyDamageBonus

PoliwagWaterGunEffect: ; 2d227 (b:5227)
	lb bc, 1, 0
	jp ApplyExtraWaterEnergyDamageBonus

LaprasWaterGunEffect: ; 2d2eb (b:52eb)
	lb bc, 1, 0
	jp ApplyExtraWaterEnergyDamageBonus

OmastarWaterGunEffect: ; 2cf05 (b:4f05)
	lb bc, 2, 0
	jr ApplyExtraWaterEnergyDamageBonus

OmanyteWaterGunEffect: ; 2cf2c (b:4f2c)
	lb bc, 1, 0
	jp ApplyExtraWaterEnergyDamageBonus


;
; applies the damage bonus for attacks that get bonus
; from extra Water energy cards.
; this bonus is always 10 more damage for each extra Water energy
; and is always capped at a maximum of 20 damage.
; input:
;	b = number of Water energy cards needed for paying Energy Cost
;	c = number of colorless energy cards needed for paying Energy Cost
ApplyExtraWaterEnergyDamageBonus: ; 2cec8 (b:4ec8)
	ld a, [wMetronomeEnergyCost]
	or a
	jr z, .not_metronome
	ld c, a ; amount of colorless needed for Metronome
	ld b, 0 ; no Water energy needed for Metronome

.not_metronome
	push bc
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld e, a
	call GetPlayAreaCardAttachedEnergies
	call HandleEnergyBurn
	pop bc

	ld hl, wAttachedEnergies + WATER
	ld a, c
	or a
	jr z, .check_bonus ; is Energy cost all water energy?

	; it's not, so we need to remove the
	; Water energy cards from calculations
	; if they pay for colorless instead.
	ld a, [wTotalAttachedEnergies]
	cp [hl]
	jr nz, .check_bonus ; skip if at least 1 non-Water energy attached

	; Water is the only energy color attached
	ld a, c
	add b
	ld b, a
	; b += c

.check_bonus
	ld a, [hl]
	sub b
	jr c, .skip_bonus ; is water energy <  b?
	jr z, .skip_bonus ; is water energy == b?

; a holds number of water energy not payed for energy cost
	cp 3
	jr c, .less_than_3
	ld a, 2 ; cap this to 2 for bonus effect
.less_than_3
	call ATimes10
	call AddToDamage ; add 10 * a to damage

.skip_bonus
	ld a, [wDamage]
	ld [wAIMinDamage], a
	ld [wAIMaxDamage], a
	ret




;

LassEffect: ; 2f9e3 (b:79e3)
; first discard Lass card that was used
	ldh a, [hTempCardIndex_ff9f]
	call RemoveCardFromHand
	call PutCardInDiscardPile

	ldtx hl, PleaseCheckTheOpponentsHandText
	call DrawWideTextBox_WaitForInput

	call .DisplayLinkOrCPUHand
	; do for non-Turn Duelist
	call SwapTurn
	call .ShuffleDuelistHandTrainerCardsInDeck
	call SwapTurn
	; do for Turn Duelist
;	fallthrough

.ShuffleDuelistHandTrainerCardsInDeck
	call CreateHandCardList
	call SortCardsInDuelTempListByID
	xor a
	ldh [hCurSelectionItem], a
	ld hl, wDuelTempList

; go through all cards in hand
; and any Trainer card is returned to deck.
.loop_hand
	ld a, [hli]
	ldh [hTempCardIndex_ff98], a
	cp $ff
	jr z, .done
	call GetCardIDFromDeckIndex
	call GetCardType
; OATS begin support trainer subtypes
	cp TYPE_TRAINER
	jr c, .loop_hand  ; original: jr nz
; OATS end support trainer subtypes
	ldh a, [hTempCardIndex_ff98]
	call RemoveCardFromHand
	call ReturnCardToDeck
	push hl
	ld hl, hCurSelectionItem
	inc [hl]
	pop hl
	jr .loop_hand
.done
; show card list
	ldh a, [hCurSelectionItem]
	or a
	call nz, SyncShuffleDeck ; only show list if there were any Trainer cards
	ret

.DisplayLinkOrCPUHand ; 2fa31 (b:7a31)
	ld a, [wDuelType]
	or a
	jr z, .cpu_opp

; link duel
	ldh a, [hWhoseTurn]
	push af
	ld a, OPPONENT_TURN
	ldh [hWhoseTurn], a
	call .DisplayOppHand
	pop af
	ldh [hWhoseTurn], a
	ret

.cpu_opp
	call SwapTurn
	call .DisplayOppHand
	call SwapTurn
	ret

.DisplayOppHand ; 2fa4f (b:7a4f)
	call CreateHandCardList
	jr c, .no_cards
	bank1call InitAndDrawCardListScreenLayout
	ldtx hl, ChooseTheCardYouWishToExamineText
	ldtx de, DuelistHandText
	bank1call SetCardListHeaderText
	ld a, A_BUTTON | START
	ld [wNoItemSelectionMenuKeys], a
	bank1call DisplayCardList
	ret
.no_cards
	ldtx hl, DuelistHasNoCardsInHandText
	call DrawWideTextBox_WaitForInput
	ret



;
; return carry if not enough cards in hand to discard
; or if there are no cards in the Discard Pile
ItemFinder_HandDiscardPileCheck:
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	call GetTurnDuelistVariable
	ldtx hl, NotEnoughCardsInHandText
	cp 3
	ret c
	call CreateTrainerCardListFromDiscardPile
	ret

ItemFinder_PlayerSelection:
	call HandlePlayerSelection2HandCardsToDiscardExcludeSelf
	; was operation cancelled?
	call c, CancelSupporterCard
	ret c

; cards were selected to discard from hand.
; now to choose a Trainer card from Discard Pile.
	call CreateTrainerCardListFromDiscardPile
	bank1call InitAndDrawCardListScreenLayout_MenuTypeSelectCheck
	ldtx hl, ChooseCardToPlaceInHandText
	ldtx de, PlayerDiscardPileText
	bank1call SetCardListHeaderText
	bank1call DisplayCardList
	ldh [hTempList + 2], a ; placed after the 2 cards selected to discard
	ret

ItemFinder_DiscardAddToHandEffect:
; discard cards from hand
	ld hl, hTempList
	ld a, [hli]
	call RemoveCardFromHand
	call PutCardInDiscardPile
	ld a, [hli]
	call RemoveCardFromHand
	call PutCardInDiscardPile

; place card from Discard Pile to hand
	ld a, [hl]
	call MoveDiscardPileCardToHand
	call AddCardToHand
	call IsPlayerTurn
	ret c
; display card in screen
	ldh a, [hTempList + 2]
	ldtx hl, WasPlacedInTheHandText
	bank1call DisplayCardDetailScreen
	ret
