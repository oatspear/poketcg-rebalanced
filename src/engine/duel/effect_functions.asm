; ------------------------------------------------------------------------------
; Dummy Functions
; ------------------------------------------------------------------------------

TransparencyEffect:
Firegiver_InitialEffect:
Quickfreeze_InitialEffect:
PealOfThunder_InitialEffect:
PassivePowerEffect:
	scf
	; fallthrough

NullEffect:
	ret

; ------------------------------------------------------------------------------
; Status Effects
; ------------------------------------------------------------------------------

INCLUDE "engine/duel/effect_functions/status.asm"

INCLUDE "engine/duel/effect_functions/substatus.asm"


; ------------------------------------------------------------------------------
; Coin Flip
; ------------------------------------------------------------------------------


TossCoin_BankB:
	jp TossCoin

TossCoinATimes_BankB:
	jp TossCoinATimes


TossACoins:
	cp 2
	jp nc, TossCoinATimes
	jp TossCoin


Serial_TossCoin:
	ld a, $1

Serial_TossCoinATimes:
	push de
	push af
	ld a, OPPACTION_TOSS_COIN_A_TIMES
	call SetOppAction_SerialSendDuelData
	pop af
	pop de
	call SerialSend8Bytes
	jp TossCoinATimes


; ------------------------------------------------------------------------------
; Pokémon Evolution
; ------------------------------------------------------------------------------

INCLUDE "engine/duel/effect_functions/evolution.asm"


PokemonBreeder_PreconditionCheck:
	call CheckDeckIsNotEmpty
	ret c
	jp IsPrehistoricPowerActive


RareCandy_HandPlayAreaCheck:
	call CreatePlayableStage2PokemonCardListFromHand
	jr c, .cannot_evolve
	jp IsPrehistoricPowerActive
.cannot_evolve
	ldtx hl, ConditionsForEvolvingToStage2NotFulfilledText
	scf
	ret

RareCandy_PlayerSelection:
; create hand list of playable Stage2 cards
	call CreatePlayableStage2PokemonCardListFromHand
	bank1call InitAndDrawCardListScreenLayout_MenuTypeSelectCheck

; handle Player selection of Stage2 card
	ldtx hl, PleaseSelectCardText
	ldtx de, DuelistHandText
	bank1call SetCardListHeaderText
	bank1call DisplayCardList
	ret c ; exit if B was pressed

	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	ldtx hl, ChooseBasicPokemonToEvolveText
	call DrawWideTextBox_WaitForInput

; handle Player selection of Basic card to evolve
	bank1call HasAlivePokemonInPlayArea
.read_input
	bank1call OpenPlayAreaScreenForSelection
	ret c ; exit if B was pressed
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTempPlayAreaLocation_ffa1], a
	ld e, a
	ldh a, [hTemp_ffa0]
	ld d, a
	call CheckIfCanEvolveInto_BasicToStage2
	jr c, .read_input ; loop back if cannot evolve this card
	or a
	ret

RareCandy_EvolveEffect:
	ldh a, [hTempCardIndex_ff9f]
	push af
	ld hl, hTemp_ffa0
	ld a, [hli]
	ldh [hTempCardIndex_ff98], a
	ld a, [hl] ; hTempPlayAreaLocation_ffa1
	ldh [hTempPlayAreaLocation_ff9d], a

; load the Basic Pokemon card name to RAM
	add DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer1_FromDeckIndex
	ld hl, wLoadedCard1Name
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call LoadTxRam2

; evolve card and overwrite its stage as STAGE2_WITHOUT_STAGE1
	ldh a, [hTempCardIndex_ff98]
	call EvolvePokemonCard
	ld [hl], STAGE2_WITHOUT_STAGE1

; load Stage2 Pokemon card name to RAM
	ldh a, [hTempCardIndex_ff98]
	call LoadCardDataToBuffer1_FromDeckIndex
	ld a, 18
	call CopyCardNameAndLevel
	xor a
	ld [hl], a ; $0 character
	ld hl, wTxRam2_b
	ld [hli], a
	ld [hl], a

; display Pokemon picture and play sfx,
; print the corresponding card names.
	bank1call DrawLargePictureOfCard
	ld a, $5e
	call PlaySFX
	ldtx hl, PokemonEvolvedIntoPokemonText
	call DrawWideTextBox_WaitForInput
	bank1call OnPokemonPlayedInitVariablesAndPowers
	pop af
	ldh [hTempCardIndex_ff9f], a
	ret

; creates list in wDuelTempList of all Stage2 Pokemon cards
; in the hand that can evolve a Basic Pokemon card in Play Area
; through use of Rare Candy.
; returns carry if that list is empty.
CreatePlayableStage2PokemonCardListFromHand: ; 2f73e (b:773e)
	call CreateHandCardList
	ret c ; return if no hand cards

; check if hand Stage2 Pokemon cards can be made
; to evolve a Basic Pokemon in the Play Area and, if so,
; add it to the wDuelTempList.
	ld hl, wDuelTempList
	ld e, l
	ld d, h
.loop_hand
	ld a, [hl]
	cp $ff
	jr z, .done
	call .CheckIfCanEvolveAnyPlayAreaBasicCard
	jr c, .next_hand_card
	ld a, [hl]
	ld [de], a
	inc de
.next_hand_card
	inc hl
	jr .loop_hand

.done
	ld a, $ff ; terminating byte
	ld [de], a
	ld a, [wDuelTempList]
	cp $ff
	scf
	ret z ; return carry if empty
	; not empty
	or a
	ret

; return carry if Stage2 card in a cannot evolve any
; of the Basic Pokemon in Play Area through Rare Candy.
.CheckIfCanEvolveAnyPlayAreaBasicCard
	push de
	ld d, a
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_ENERGY
	jr nc, .set_carry ; skip if not Pokemon card
	ld a, [wLoadedCard2Stage]
	cp STAGE2
	jr nz, .set_carry ; skip if not Stage2

; check if can evolve any Play Area cards
	push hl
	push bc
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld c, a
	ld e, PLAY_AREA_ARENA
.loop_play_area
	push bc
	push de
	call CheckIfCanEvolveInto_BasicToStage2
	pop de
	pop bc
	jr nc, .done_play_area
	inc e
	dec c
	jr nz, .loop_play_area
; set carry
	scf
.done_play_area
	pop bc
	pop hl
	pop de
	ret
.set_carry
	pop de
	scf
	ret


; ------------------------------------------------------------------------------


SetNoEffectFromStatus: ; 2c09c (b:409c)
	ld a, EFFECT_FAILED_NO_EFFECT
	ld [wEffectFailed], a
	ret

SetWasUnsuccessful: ; 2c0a2 (b:40a2)
	ld a, EFFECT_FAILED_UNSUCCESSFUL
	ld [wEffectFailed], a
	ret

Func_2c0a8: ; 2c0a8 (b:40a8)
	ldh a, [hTemp_ffa0]
	push af
	ldh a, [hWhoseTurn]
	ldh [hTemp_ffa0], a
	ld a, OPPACTION_6B30
	call SetOppAction_SerialSendDuelData
	bank1call AnimateShuffleDeck
	ld c, a
	pop af
	ldh [hTemp_ffa0], a
	ld a, c
	ret

SyncShuffleDeck: ; 2c0bd (b:40bd)
	call ExchangeRNG
	bank1call AnimateShuffleDeck
	call ShuffleDeck
	ret

; ------------------------------------------------------------------------------
; Checks and Tests
; ------------------------------------------------------------------------------

INCLUDE "engine/duel/effect_functions/checks.asm"


CheckIfPlayAreaHasAnyDamageOrStatus:
	call CheckIfPlayAreaHasAnyDamage
	ret nc  ; there is damage to heal
	jp CheckIfPlayAreaHasAnyStatus


Maintenance_CheckHandAndDiscardPile:
	call CheckHandSizeGreaterThan1
	ret c
	jp CreateItemCardListFromDiscardPile


AssassinFlight_CheckBenchAndStatus:
	call CheckOpponentHasStatus
	ret c
	jp StretchKick_CheckBench


AbsorbWater_PreconditionCheck:
	call CheckPokemonPowerCanBeUsed
	ret c
	jp CreateEnergyCardListFromDiscardPile_OnlyWater
	; ldtx hl, ThereAreNoEnergyCardsInDiscardPileText
	; ret


MudSport_PreconditionCheck:
	call CheckPokemonPowerCanBeUsed
	ret c
	jp CreateEnergyCardListFromDiscardPile_WaterFighting
	; ldtx hl, ThereAreNoEnergyCardsInDiscardPileText
	; ret


PrimordialDream_PreconditionCheck:
	call CheckPokemonPowerCanBeUsed
	ret c
	jp CreateItemCardListFromDiscardPile
	; ldtx hl, ThereAreNoTrainerCardsInDiscardPileText
	; ret


Trade_PreconditionCheck:
	call CheckHandSizeGreaterThan1
	ret c
	; fallthrough

Synthesis_PreconditionCheck:
	call CheckDeckIsNotEmpty
	ret c
	jp CheckPokemonPowerCanBeUsed


Shift_OncePerTurnCheck:
  ldh a, [hTempPlayAreaLocation_ff9d]
  ldh [hTemp_ffa0], a
	jp CheckPokemonPowerCanBeUsed


StressPheromones_PreconditionCheck:
	call CheckTempLocationPokemonHasAnyDamage
	ret c
	jp CheckPokemonPowerCanBeUsed


; ------------------------------------------------------------------------------
; Discard Cards
; ------------------------------------------------------------------------------

INCLUDE "engine/duel/effect_functions/discard.asm"


Wildfire_DiscardDeckEffect:
	ldh a, [hTemp_ffa0]
	jp DiscardFromOpponentsDeckEffect


Combustion_DiscardDeckEffect:
	ld a, 2
	jp DiscardFromOpponentsDeckEffect


SmallCombustion_DiscardDeckEffect:
	ld a, 1
	jp DiscardFromOpponentsDeckEffect


PrimalScythe_DiscardDamageBoostEffect:
	call SelectedCards_Discard1FromHand
	ret c  ; no Mysterious Fossil
	jp PrimalScythe_DamageBoostEffect


; ------------------------------------------------------------------------------

; Stores information about the attack damage for AI purposes
; taking into account poison damage between turns.
; if target poisoned
;	[wAIMinDamage] <- [wDamage]
;	[wAIMaxDamage] <- [wDamage]
; else
;	[wAIMinDamage] <- [wDamage] + d
;	[wAIMaxDamage] <- [wDamage] + e
;	[wDamage]      <- [wDamage] + a
UpdateExpectedAIDamage_AccountForPoison: ; 2c0d4 (b:40d4)
; OATS poison ticks only for the turn holder
	; push af
	; ld a, DUELVARS_ARENA_CARD_STATUS
	; call GetNonTurnDuelistVariable
	; and POISONED | DOUBLE_POISONED
	; jr z, UpdateExpectedAIDamage.skip_push_af
	; pop af
	; ld a, [wDamage]
	; ld [wAIMinDamage], a
	; ld [wAIMaxDamage], a
	; ret

; Sets some variables for AI use
;	[wAIMinDamage] <- [wDamage] + d
;	[wAIMaxDamage] <- [wDamage] + e
;	[wDamage]      <- [wDamage] + a
UpdateExpectedAIDamage: ; 2c0e9 (b:40e9)
	push af

.skip_push_af
	ld hl, wDamage
	ld a, [hl]
	add d
	ld [wAIMinDamage], a
	ld a, [hl]
	add e
	ld [wAIMaxDamage], a
	pop af
	add [hl]
	ld [hl], a
	ret

; Stores information about the attack damage for AI purposes
; [wDamage]      <- a (average amount of damage)
; [wAIMinDamage] <- d (minimum)
; [wAIMaxDamage] <- e (maximum)
SetExpectedAIDamage: ; 2c0fb (b:40fb)
	ld [wDamage], a
	xor a
	ld [wDamage + 1], a
	ld a, d
	ld [wAIMinDamage], a
	ld a, e
	ld [wAIMaxDamage], a
	ret

Func_2c10b: ; 2c10b (b:410b)
	ldh [hTempPlayAreaLocation_ff9d], a
	bank1call Func_61a1
	bank1call PrintPlayAreaCardList_EnableLCD
	bank1call Func_6194
	ret


; deal damage to all the turn holder's benched Pokemon
; input: a = amount of damage to deal to each Pokemon
DealDamageToAllBenchedPokemon:
	ld e, a
	ld d, $00
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld c, a
	ld b, PLAY_AREA_ARENA
	jr .skip_to_bench
.loop
	push bc
	call DealDamageToPlayAreaPokemon_RegularAnim
	pop bc
.skip_to_bench
	inc b
	dec c
	jr nz, .loop
	ret

; deal damage to all the turn holder's benched Basic Pokémon
; input: a = amount of damage to deal to each Pokémon
DealDamageToAllBenchedBasicPokemon:
	ld e, a
	ld d, $00
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld c, a
	ld b, PLAY_AREA_ARENA
	jr .next
.loop
	ld a, DUELVARS_ARENA_CARD_STAGE
	add b
	call GetTurnDuelistVariable
	or a
	jr nz, .next  ; not a BASIC Pokémon
	push bc
	call DealDamageToPlayAreaPokemon_RegularAnim
	pop bc
.next
	inc b
	dec c
	jr nz, .loop
	ret


Func_2c12e: ; 2c12e (b:412e)
	ld [wLoadedAttackAnimation], a
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld b, a
	ld c, $0 ; neither WEAKNESS nor RESISTANCE
	ldh a, [hWhoseTurn]
	ld h, a
	bank1call PlayAttackAnimation
	bank1call WaitAttackAnimation
	ret

; overwrites in wDamage, wAIMinDamage and wAIMaxDamage
; with the value in a.
SetDefiniteDamage: ; 2c166 (b:4166)
	ld [wDamage], a
	ld [wAIMinDamage], a
	ld [wAIMaxDamage], a
	xor a
	ld [wDamage + 1], a
	ret

; overwrites wAIMinDamage and wAIMaxDamage
; with value in wDamage.
SetDefiniteAIDamage: ; 2c174 (b:4174)
	ld a, [wDamage]
	ld [wAIMinDamage], a
	ld [wAIMaxDamage], a
	ret

; prints the text "<X> devolved to <Y>!" with
; the proper card names and levels.
; input:
;	d = deck index of the lower stage card
;	e = deck index of card that was devolved
PrintDevolvedCardNameAndLevelText: ; 2c1c4 (b:41c4)
	push de
	ld a, e
	call LoadCardDataToBuffer1_FromDeckIndex
	ld bc, wTxRam2
	ld hl, wLoadedCard1Name
	ld a, [hli]
	ld [bc], a
	inc bc
	ld a, [hl]
	ld [bc], a

	inc bc ; wTxRam2_b
	xor a
	ld [bc], a
	inc bc
	ld [bc], a

	ld a, d
	call LoadCardDataToBuffer1_FromDeckIndex
	ld a, 18
	call CopyCardNameAndLevel
	ld [hl], $00
	ldtx hl, PokemonDevolvedToText
	call DrawWideTextBox_WaitForInput
	pop de
	ret

HandleSwitchDefendingPokemonEffect: ; 2c1ec (b:41ec)
	ld e, a
	cp $ff
	ret z

; check Defending Pokemon's HP
	ld a, DUELVARS_ARENA_CARD_HP
	call GetNonTurnDuelistVariable
	or a
	jr nz, .switch

; if 0, handle Destiny Bond first
	push de
	bank1call HandleDestinyBondSubstatus
	pop de

.switch
	call HandleNoDamageOrEffect
	ret c

; attack was successful, switch Defending Pokemon
	call SwapTurn
	call SwapArenaWithBenchPokemon
	call SwapTurn

	xor a
	ld [wccc5], a
	ld [wDuelDisplayedScreen], a
	inc a
	ld [wccef], a
	ret

; returns carry if Defending has No Damage or Effect
; if so, print its appropriate text.
HandleNoDamageOrEffect: ; 2c216 (b:4216)
	call CheckNoDamageOrEffect
	ret nc
	ld a, l
	or h
	call nz, DrawWideTextBox_PrintText
	scf
	ret

; ------------------------------------------------------------------------------
; Healing
; ------------------------------------------------------------------------------

INCLUDE "engine/duel/effect_functions/healing.asm"


; select the Pokémon with status to heal
FullHeal_PlayerSelection:
	bank1call HasAlivePokemonInPlayArea
.read_input
	bank1call OpenPlayAreaScreenForSelection
	ret c ; exit is B was pressed
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a

	add DUELVARS_ARENA_CARD_STATUS
	call GetTurnDuelistVariable
	or a
	ret nz  ; Pokémon has status

	ldh a, [hTempPlayAreaLocation_ff9d]
	or a  ; arena Pokémon?
	jr nz, .read_input ; not arena, loop back to start

	ld l, DUELVARS_ARENA_CARD_SUBSTATUS2
	ld a, [hl]
	or a
	jr z, .read_input ; no status, loop back to start
	ret

FullHeal_ClearStatusEffect:
	ldh a, [hTemp_ffa0]
	call ClearStatusFromTarget
	bank1call DrawDuelHUDs
	ret


; ------------------------------------------------------------------------------
; Damage
; ------------------------------------------------------------------------------

INCLUDE "engine/duel/effect_functions/damage.asm"


; puts 1 damage counter on the target at location in e,
; without counting as attack damage (does not trigger damage reduction, etc.)
; assumes: call to SwapTurn if needed
; inputs:
;   e: PLAY_AREA_* of the target
Put1DamageCounterOnTarget:
	ld d, 10
	; jr ApplyDirectDamage
	; fallthrough


; Puts damage counters on the target at location in e,
;   without counting as attack damage (does not trigger damage reduction, etc.)
; This is a mix between DealDamageToPlayAreaPokemon_RegularAnim (bank 0)
;   and HandlePoisonDamage (bank 1).
; inputs:
;   d: amount of damage to deal
;   e: PLAY_AREA_* of the target
; preserves:
;   hl, de, bc
ApplyDirectDamage:
	ld a, ATK_ANIM_BENCH_HIT
	ld [wLoadedAttackAnimation], a
	ld a, e
	ld [wTempPlayAreaLocation_cceb], a
	or a ; cp PLAY_AREA_ARENA
	jr nz, .skip_no_damage_or_effect_check
	ld a, [wNoDamageOrEffect]
	or a
	ret nz
.skip_no_damage_or_effect_check
	push hl
	push de
	push bc
	xor a
	ld [wNoDamageOrEffect], a
	ld e, d
	ld d, 0
	push de
	ld a, [wTempPlayAreaLocation_cceb]
	add DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call GetCardIDFromDeckIndex
	ld a, e
	ld [wTempNonTurnDuelistCardID], a
	pop de
	ld a, [wTempPlayAreaLocation_cceb]
	ld b, a
	ld c, 0
	add DUELVARS_ARENA_CARD_HP
	call GetTurnDuelistVariable
	push af
	bank1call PlayAttackAnimation_DealAttackDamageSimple
	push hl
	call WaitForWideTextBoxInput
	pop hl
	; push hl
	; ldtx hl, Received10DamageDueToAfflictionText
	; bank1call PrintNonTurnDuelistCardIDText
	; pop hl
	pop af
	or a
	jr z, .skip_knocked_out
	call PrintKnockedOutIfHLZero
	call WaitForWideTextBoxInput
.skip_knocked_out
	pop bc
	pop de
	pop hl
	ret


Affliction_DamageEffect:
	ld a, [wAfflictionAffectedPlayArea]
	or a
	ret z

	call SwapTurn
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld c, a  ; loop counter
	ld d, 10  ; damage
	ld e, PLAY_AREA_ARENA  ; target
	ld a, DUELVARS_ARENA_CARD_STATUS
	call GetTurnDuelistVariable
.loop_play_area
	ld a, [hli]
	or a
	call nz, ApplyDirectDamage
	inc e
	dec c
	jr nz, .loop_play_area
	jp SwapTurn


; ------------------------------------------------------------------------------
; Damage Modifiers
; ------------------------------------------------------------------------------

INCLUDE "engine/duel/effect_functions/damage_modifiers.asm"


; ------------------------------------------------------------------------------
; Pokémon Powers
; ------------------------------------------------------------------------------

;
RainDance_OncePerTurnCheck:
	call CheckPokemonPowerCanBeUsed
	ret c  ; cannot be used
	call CreateHandCardList_OnlyWaterEnergy
	ret c  ; no energy
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	ret

;
RainDance_AttachEnergyEffect:
	ld a, DUELVARS_DUELIST_TYPE
	call GetTurnDuelistVariable
	cp DUELIST_TYPE_LINK_OPP
	jr z, .link_opp
	and DUELIST_TYPE_AI_OPP
	jr z, .player

; AI Pokémon selection logic is in HandleAIRainDanceEnergy
	jr .attach

.player
	ldtx hl, ChoosePokemonToAttachEnergyCardText
	call DrawWideTextBox_WaitForInput
; choose a Pokemon in Play Area to attach card
	call HandlePlayerSelectionPokemonInPlayArea
	ld e, a  ; set selected Pokémon
	ldh [hTempPlayAreaLocation_ffa1], a
	call SerialSend8Bytes
	jr .attach

.link_opp
	call SerialRecv8Bytes
	ld a, e  ; get selected Pokémon
	ldh [hTempPlayAreaLocation_ffa1], a
	; fallthrough

.attach
; restore [hTempPlayAreaLocation_ff9d] from [hTemp_ffa0]
	ldh a, [hTemp_ffa0]
	ldh [hTempPlayAreaLocation_ff9d], a
; flag Rain Dance as being used (requires [hTempPlayAreaLocation_ff9d])
	call SetUsedPokemonPowerThisTurn

; pick Water Energy from Hand
	call CreateHandCardList_OnlyWaterEnergy
	ld a, [wDuelTempList]
	ldh [hTemp_ffa0], a
	call AttachEnergyFromHand_AttachEnergyEffect

	ldh a, [hTempPlayAreaLocation_ff9d]
	call Func_2c10b
	jp ExchangeRNG


; Draw 1 card per turn.
TradeEffect:
	call SetUsedPokemonPowerThisTurn
	ldh a, [hAIPkmnPowerEffectParam]
	ldh [hTempList], a
	call SelectedCards_Discard1FromHand
	jp Draw2CardsEffect


; Search for any card in deck and add it to the hand.
Courier_SearchAndAddToHandEffect:
	ld a, DUELVARS_DUELIST_TYPE
	call GetTurnDuelistVariable
	cp DUELIST_TYPE_LINK_OPP
	jr z, .link_opp
	and DUELIST_TYPE_AI_OPP
	jr nz, .ai_opp

; player
	; ldtx hl, ChooseCardToPlaceInHandText
	; call DrawWideTextBox_WaitForInput
	call HandlePlayerSelectionAnyCardFromDeckToHand
	; ldh [hAIPkmnPowerEffectParam], a
	call SerialSend8Bytes
	jr .done

.link_opp
	call SerialRecv8Bytes
	; ldh [hAIPkmnPowerEffectParam], a
	jr .done

.ai_opp
; AI just selects the first card in the deck
	ld b, 1
	call CreateDeckCardListTopNCards
	ld a, [wDuelTempList]
	; fallthrough

.done
	cp $ff
	ret z
	jp AddDeckCardToHandAndShuffleEffect


GarbageEater_HealEffect:
	ld a, [wGarbageEaterDamageToHeal]
	or a
	ret z  ; nothing to do

	ld a, GRIMER
	call ListPowerCapablePokemonIDInPlayArea
	ret nc  ; none found

	ld hl, hTempList
.loop_play_area
	ld a, [hli]
	cp $ff
	ret z  ; done
	ld e, a  ; location
	ld a, [wGarbageEaterDamageToHeal]
	ld d, a  ; damage
	push hl
	call HealPlayAreaCardHP
	pop hl
	jr .loop_play_area


; Stores in [wDreamEaterDamageToHeal] the amount of damage to heal
; from sleeping Pokémon in play area.
; Stores 0 if there are no Dream Eater capable Pokémon in play.
DreamEater_CountPokemonAndSetHealingAmount:
	xor a
	ld [wDreamEaterDamageToHeal], a

	ld a, HYPNO
	call ListPowerCapablePokemonIDInPlayArea
	ret nc  ; none found

	ld hl, hTempList
.loop_play_area
	ld a, [hli]
	cp $ff
	ret z  ; done

	ld e, a  ; location
	call GetCardDamageAndMaxHP
	or a
	jr z, .loop_play_area  ; not damaged
	; fallthrough

; stores in [wDreamEaterDamageToHeal] the amount of damage to heal
; from sleeping Pokémon in play area
DreamEater_SetHealingAmount:
	call CountSleepingPokemonInPlayArea
	ld [wDreamEaterDamageToHeal], a
	call SwapTurn
	call CountSleepingPokemonInPlayArea
	call SwapTurn
	ld a, [wDreamEaterDamageToHeal]
	add c
	call ATimes10
	ld [wDreamEaterDamageToHeal], a
	ret

; heals the amount of damage in [wDreamEaterDamageToHeal] from every
; Pokémon Power capable Hypno in the turn holder's play area
DreamEater_HealEffect:
	ld a, [wDreamEaterDamageToHeal]
	or a
	ret z  ; nothing to do

	ld a, HYPNO
	call ListPowerCapablePokemonIDInPlayArea
	ret nc  ; none found

	ld hl, hTempList
.loop_play_area
	ld a, [hli]
	cp $ff
	ret z  ; done

	ld e, a  ; location
	ld a, [wDreamEaterDamageToHeal]
	ld d, a  ; damage
	push hl
	call HealPlayAreaCardHP
	pop hl
	jr .loop_play_area



; Stores in [wAfflictionAffectedPlayArea] whether there are Pokémon to damage
; from status in the opponent's play area.
; Stores 0 if there are no Affliction capable Pokémon in play.
Affliction_CountPokemonAndSetVariable:
	xor a
	ld [wAfflictionAffectedPlayArea], a

	ld a, HAUNTER_LV22
	call CountPokemonIDInPlayArea
	ret nc  ; none found

	call SwapTurn
	call CheckIfPlayAreaHasAnyStatus
	or a
	ld [wAfflictionAffectedPlayArea], a
	jp SwapTurn


StrangeBehavior_SelectAndSwapEffect:
	ld a, DUELVARS_DUELIST_TYPE
	call GetTurnDuelistVariable
	cp DUELIST_TYPE_PLAYER
	jr z, .player

; not player
	bank1call Func_61a1
	bank1call PrintPlayAreaCardList_EnableLCD
	ret

.player
	ldtx hl, ProcedureForStrangeBehaviorText
	bank1call DrawWholeScreenTextBox

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
.loop_input
	call DoFrame
	call HandleMenuInput
	jr nc, .loop_input
	cp $ff
	ret z  ; return when B button is pressed

	ldh [hCurSelectionItem], a
	ldh [hTempPlayAreaLocation_ffa1], a
	ld hl, hTemp_ffa0
	cp [hl]
	jr z, .play_sfx ; can't select Slowbro itself

	call GetCardDamageAndMaxHP
	or a
	jr z, .play_sfx ; can't select card without damage

	call TryGiveDamageCounter_StrangeBehavior
	jr c, .play_sfx
	ld a, OPPACTION_6B15
	call SetOppAction_SerialSendDuelData
	jr .start

.play_sfx
	call PlaySFX_InvalidChoice
	jr .loop_input


StrangeBehavior_SwapEffect:
	call TryGiveDamageCounter_StrangeBehavior
	ret c
	bank1call PrintPlayAreaCardList_EnableLCD
	or a
	ret

; tries to give the damage counter to the target
; chosen by the Player (hTemp_ffa0).
; if the damage counter would KO card, then do
; not give the damage counter and return carry.
TryGiveDamageCounter_StrangeBehavior:
	ldh a, [hTemp_ffa0]
	add DUELVARS_ARENA_CARD_HP
	call GetTurnDuelistVariable
	sub 10
	jr z, .set_carry  ; would bring HP to zero?
; has enough HP to receive a damage counter
	ld [hl], a
	ldh a, [hTempPlayAreaLocation_ffa1]
	add DUELVARS_ARENA_CARD_HP
	ld l, a
	ld a, 10
	add [hl]
	ld [hl], a
	or a
	ret
.set_carry
	scf
	ret


Curse_DamageEffect:
	call SetUsedPokemonPowerThisTurn
	; input e: PLAY_AREA_* of the target
	ldh a, [hTempPlayAreaLocation_ffa1]
	ld e, a
	call SwapTurn
	call Put1DamageCounterOnTarget
	jp SwapTurn


; Remove status conditions from target PLAY_AREA_* and attach an Energy from Hand.
; input:
;   [hTempPlayAreaLocation_ffa1]: PLAY_AREA_* of target card
DraconicEvolutionEffect:
	; ldtx hl, DraconicEvolutionActivatesText
	; call DrawWideTextBox_WaitForInput
; check status
	ldh a, [hTempPlayAreaLocation_ffa1]
	add DUELVARS_ARENA_CARD_STATUS
	call GetTurnDuelistVariable
	or a
	ldh a, [hTempPlayAreaLocation_ffa1]
; remove status
	call nz, ClearStatusFromTarget
	bank1call DrawDuelHUDs
; check energy cards in hand
	call AttachEnergyFromHand_HandCheck
; choose energy card to attach
	call nc, DraconicEvolution_AttachEnergyFromHandEffect
	or a
	ret


; Choose a Basic Energy from hand and attach it to a Pokémon.
; inputs:
;   [wDuelTempList]: list of Basic Energy cards in hand
DraconicEvolution_AttachEnergyFromHandEffect:
	ld a, DUELVARS_DUELIST_TYPE
	call GetTurnDuelistVariable
	cp DUELIST_TYPE_LINK_OPP
	jr z, .link_opp
	and DUELIST_TYPE_AI_OPP
	jr nz, .ai_opp

; player
	call Helper_SelectEnergyFromHand
	ldh [hTemp_ffa0], a
	ld d, a
	ldh a, [hTempPlayAreaLocation_ffa1]
	ld e, a
	call SerialSend8Bytes
	jp AttachEnergyFromHand_AttachEnergyEffect

.link_opp
	call SerialRecv8Bytes
	ld a, d
	ldh [hTemp_ffa0], a
	ld a, e
	ldh [hTempPlayAreaLocation_ffa1], a
	jp AttachEnergyFromHand_AttachEnergyEffect

.ai_opp
; AI selects the first card
	ld a, [wDuelTempList]
	ldh [hTemp_ffa0], a
	jp AttachEnergyFromHand_AttachEnergyEffect


PrimordialDream_PlayerSelectEffect:
; Pokémon Powers must preserve [hTemp_ffa0]
	; ldh a, [hTemp_ffa0]
	; push af
	ldtx hl, ChooseCardToPlaceInHandText
	call DrawWideTextBox_WaitForInput
	call HandlePlayerSelectionItemTrainerFromDiscardPile
	ret c
	ldh [hAIPkmnPowerEffectParam], a
	; pop af
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	ret


; Pokémon Powers do not use [hTemp_ffa0]
; adds a card in [hAIEnergyTransEnergyCard] from the discard pile to the hand
; Note: Pokémon Power no longer needs to preserve [hTemp_ffa0] at this point
PrimordialDream_MorphAndAddToHandEffect:
	call SetUsedPokemonPowerThisTurn
; get deck index and morph the selected card
	ldh a, [hAIPkmnPowerEffectParam]
	cp $ff
	ret z
	call FossilizeCard
; get deck index again and add to the hand
	ldh a, [hAIPkmnPowerEffectParam]
	ldh [hTempList], a
	ld a, $ff
	ldh [hTempList + 1], a
	jp SelectedCard_AddToHandFromDiscardPile


; ------------------------------------------------------------------------------
; Compound Attacks
; ------------------------------------------------------------------------------

Constrict_TrapDamageBoostEffect:
	call IncreaseRetreatCostEffect
	jp Constrict_DamageBoostEffect


; damage to bench target and reset color to whatever it was
Steamroller_DamageAndColorEffect:
	ld a, DUELVARS_ARENA_CARD_CHANGED_TYPE
	call GetTurnDuelistVariable
	ldh a, [hTemp_ffa0]
	ld [hl], a
	jp Deal20DamageToTarget_DamageEffect


; Deal damage to selected Pokémon and apply defense boost to self.
AquaLauncherEffect:
	call Deal30DamageToTarget_DamageEffect
	jp ReduceDamageTakenBy10Effect


PanicVine_ConfusionTrapEffect:
	call UnableToRetreatEffect
	jp ConfusionEffect


NaturalRemedy_HealEffect:
	ldh a, [hTemp_ffa0]
	cp $ff
	ret z
	ld e, a   ; location
	ld d, 30  ; damage
	call HealPlayAreaCardHP
	ldh a, [hTemp_ffa0]
	jp c, ClearStatusFromTarget
	jp ClearStatusFromTarget_NoAnim


; heal up to 30 damage from user and put it to sleep
Rest_HealEffect:
	call ClearAllStatusConditionsAndEffects
	ld a, 30
	call HealADamageEffect
	call SwapTurn
	call SleepEffect
	jp SwapTurn


; look at opponent's hand
CheckOpponentHandEffect:
	; call IsPlayerTurn
	; ret nc
	farcall OpenYourOrOppPlayAreaScreen_NonTurnHolderHand
	xor a
	ret


PoisonPaybackEffect:
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	or a
	ret z  ; not damaged
	call DoubleDamage_DamageBoostEffect
	jp PoisonEffect


ShadowClawEffect:
	ldh a, [hTemp_ffa0]
	cp $ff
	ret z  ; no card was chosen to discard
	jp Discard1RandomCardFromOpponentsHand

; OptionalDiscardEnergy:
; 	ldh a, [hTemp_ffa0]
; 	cp $ff
; 	ret z  ; none selected, do nothing
; 	call DiscardEnergy_DiscardEffect


DeadlyPoisonEffect:
	call DeadlyPoison_DamageBoostEffect
	jp PoisonEffect


OverwhelmEffect:
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	call GetNonTurnDuelistVariable
	cp 6
	ret c  ; less than 7 cards
	call Discard1RandomCardFromOpponentsHand
	jp ParalysisEffect


; ------------------------------------------------------------------------------
; Card Search
; ------------------------------------------------------------------------------

INCLUDE "engine/duel/effect_functions/card_search.asm"


; Searches the Deck for either a Grass Energy or Grass Pokémon
; and adds that card to the Hand.
Sprout_PlayerSelectEffect:
	ld a, $ff
	ldh [hTemp_ffa0], a

	call CreateDeckCardList
	ldtx hl, ChooseGrassCardFromDeckText
	ldtx bc, GrassCardText
	lb de, SEARCHEFFECT_GRASS_CARD, $00
	call LookForCardsInDeck
	ret c

; draw Deck list interface and print text
	bank1call InitAndDrawCardListScreenLayout_MenuTypeSelectCheck
	ldtx hl, ChooseGrassCardFromDeckText
	ldtx de, DuelistDeckText
	bank1call SetCardListHeaderText

.loop
	bank1call DisplayCardList
	jr c, .pressed_b

	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_ENERGY_GRASS
	jr z, .got_card  ; is it a Grass Energy?
	cp TYPE_PKMN_GRASS
	jr nz, .play_sfx ; is it a Grass Pokémon?
.got_card
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	or a
	ret

.play_sfx
	; play SFX and loop back
	call PlaySFX_InvalidChoice
	jr .loop

.pressed_b
; figure if Player can exit the screen without selecting,
; that is, if the Deck has no Grass-type cards.
	ld a, DUELVARS_CARD_LOCATIONS
	call GetTurnDuelistVariable
.loop_b_press
	ld a, [hl]
	cp CARD_LOCATION_DECK
	jr nz, .next
	ld a, l
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_ENERGY_GRASS
	jr z, .play_sfx ; found, go back to top loop
	cp TYPE_PKMN_GRASS
	jr z, .play_sfx ; found, go back to top loop
.next
	inc l
	ld a, l
	cp DECK_SIZE
	jr c, .loop_b_press

; no valid card in Deck, can safely exit screen
	ld a, $ff
	ldh [hTemp_ffa0], a
	or a
	ret

Sprout_AISelectEffect:
	call CreateDeckCardList
	ld b, TYPE_ENERGY_GRASS
	call ChooseCardOfGivenType_AISelectEffect
	ldh [hTemp_ffa0], a
	cp $ff
	ret nz  ; found
	ld b, TYPE_PKMN_GRASS
	call ChooseCardOfGivenType_AISelectEffect
	ldh [hTemp_ffa0], a
	ret


; Looks at the top 4 cards and allows the Player to choose a card.
Ultravision_PlayerSelectEffect:
	ld b, 4
	call CreateDeckCardListTopNCards
	call HandlePlayerSelectionAnyCardFromDeckListToHand
	ldh [hTemp_ffa0], a
	ret


; selects the first Trainer or Energy card that shows up
; FIXME improve
Ultravision_AISelectEffect:
	ld b, 4
	call CreateDeckCardListTopNCards
	ld hl, wDuelTempList
.loop_deck
	ld a, [hli]
	ldh [hTemp_ffa0], a
	cp $ff
	jr z, .anything ; none found
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_ENERGY
	ret nc
	jr .loop_deck
.anything
	ld a, [wDuelTempList]
	ldh [hTemp_ffa0], a
	ret


; assume card list is already initialized from precondition check
; FIXME improve
AquaticRescue_AISelectEffect:
	ld a, $ff
	ldh [hTempList], a
	ldh [hTempList + 1], a
	ldh [hTempList + 2], a
	ldh [hTempList + 3], a
; try to get energy
	call LoopCardList_GetFirstEnergy
	jr c, .done
	ldh [hTempList], a
; try to get energy
	call LoopCardList_GetFirstEnergy
	jr c, .done
	ldh [hTempList + 1], a
; try to get energy
	call LoopCardList_GetFirstEnergy
	jr c, .done
	ldh [hTempList + 2], a
.done
	or a
	ret


; return in a deck index of card or $ff
LoopCardList_GetFirstEnergy:
	ld hl, wDuelTempList
.loop_cards
	ld a, [hl]
	cp $ff
	jr z, .none_found
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_ENERGY
	ld a, [hl]
	ret z  ; found
	inc hl
	jr .loop_cards
.none_found
	scf
	ret


RocketShell_PlayerSelectEffect:
	ld a, $ff
	ldh [hTempList], a
	ld a, [wAlreadyPlayedEnergyOrSupporter]
	and PLAYED_ENERGY_THIS_TURN
	ret z  ; did not play energy
	; fallthrough

TutorWaterEnergy_PlayerSelectEffect:
	; ld b, 5
	; call CreateDeckCardListTopNCards
	call CreateDeckCardList
	ld a, TYPE_ENERGY_WATER
	call HandlePlayerSelectionCardTypeFromDeckListToHand
	ldh [hTempList], a
	ret


RocketShell_AISelectEffect:
	ld a, $ff
	ldh [hTempList], a
	ld a, [wAlreadyPlayedEnergyOrSupporter]
	and PLAYED_ENERGY_THIS_TURN
	ret z  ; did not play energy
	; fallthrough

TutorWaterEnergy_AISelectEffect:
	; ld b, 5
	; call CreateDeckCardListTopNCards
	call CreateDeckCardList
	ld b, TYPE_ENERGY_WATER
	call ChooseCardOfGivenType_AISelectEffect
	ldh [hTempList], a
	ret


WaterReserve_PlayerSelectEffect:
	; ld b, 5
	; call CreateDeckCardListTopNCards
	call CreateDeckCardList
; select the first card
	ld a, TYPE_ENERGY_WATER
	call HandlePlayerSelectionCardTypeFromDeckListToHand
	ldh [hTempList], a
	cp $ff
	ret z  ; no cards or cancelled selection
; remove the first card from the list
	call RemoveCardFromDuelTempList
; choose a second card
	ld a, TYPE_ENERGY_WATER
	call HandlePlayerSelectionCardTypeFromDeckListToHand
	ldh [hTempList + 1], a
	ld a, $ff
	ldh [hTempList + 2], a  ; terminator
	ret

WaterReserve_AISelectEffect:
	; ld b, 5
	; call CreateDeckCardListTopNCards
	call CreateDeckCardList
	ld b, TYPE_ENERGY_WATER
	call ChooseCardOfGivenType_AISelectEffect
	ldh [hTempList], a
	cp $ff
	ret z
	call RemoveCardFromDuelTempList  ; preserves bc
	; ld b, TYPE_ENERGY_WATER
	call ChooseCardOfGivenType_AISelectEffect
	ldh [hTempList + 1], a
	ld a, $ff
	ldh [hTempList + 2], a  ; terminator
	ret


; input:
;   [wDuelTempList]: list of cards to choose from
;   b: TYPE_* constant of card to choose
; output:
;   a: deck index of the selected card
ChooseCardOfGivenType_AISelectEffect:
	ld hl, wDuelTempList
.loop_cards
	ld a, [hli]
	cp $ff
	ret z  ; no more cards
	ld c, a
	call GetCardIDFromDeckIndex  ; preserves af, hl, bc
	call GetCardType  ; preserves hl, bc
	cp b
	ld a, c
	ret z  ; found
	jr .loop_cards


; ------------------------------------------------------------------------------
; Card Lists and Filters
; ------------------------------------------------------------------------------

INCLUDE "engine/duel/effect_functions/card_lists.asm"

; ------------------------------------------------------------------------------


GetNumAttachedWaterEnergy:
	; ldh a, [hTempPlayAreaLocation_ff9d]
	; ld e, a
	ld e, PLAY_AREA_ARENA
	call GetPlayAreaCardAttachedEnergies
	call HandleEnergyBurn
	ld a, [wAttachedEnergies + WATER]
	ret


; handles the Player selection of attack
; to use, i.e. Amnesia or Metronome on.
; returns carry if none selected.
; outputs:
;	  d = card index of defending card
;	  e = attack index selected
HandleDefendingPokemonAttackSelection:
	bank1call DrawDuelMainScene
	call SwapTurn
	xor a
	ldh [hCurSelectionItem], a

.start
	bank1call PrintAndLoadAttacksToDuelTempList
	push af
	ldh a, [hCurSelectionItem]
	ld hl, .menu_parameters
	call InitializeMenuParameters
	pop af

	ld [wNumMenuItems], a
	call EnableLCD
.loop_input
	call DoFrame
	ldh a, [hKeysPressed]
	bit B_BUTTON_F, a
	jr nz, .set_carry
	and START
	jr nz, .open_atk_page
	call HandleMenuInput
	jr nc, .loop_input
	cp -1
	jr z, .loop_input

; an attack was selected
	ldh a, [hCurMenuItem]
	add a
	ld e, a
	ld d, $00
	ld hl, wDuelTempList
	add hl, de
	ld d, [hl]
	inc hl
	ld e, [hl]
	call SwapTurn
	or a
	ret

.set_carry
	call SwapTurn
	scf
	ret

.open_atk_page
	ldh a, [hCurMenuItem]
	ldh [hCurSelectionItem], a
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer1_FromDeckIndex
	bank1call OpenAttackPage
	call SwapTurn
	bank1call DrawDuelMainScene
	call SwapTurn
	jr .start

.menu_parameters
	db 1, 13 ; cursor x, cursor y
	db 2 ; y displacement between items
	db 2 ; number of items
	db SYM_CURSOR_R ; cursor tile number
	db SYM_SPACE ; tile behind cursor
	dw NULL ; function pointer if non-0

; loads in hl the pointer to attack's name.
; input:
;	d = deck index of card
; 	e = attack index (0 = first attack, 1 = second attack)
GetAttackName: ; 2c3fc (b:43fc)
	ld a, d
	call LoadCardDataToBuffer1_FromDeckIndex
	ld hl, wLoadedCard1Atk1Name
	inc e
	dec e
	jr z, .load_name
	ld hl, wLoadedCard1Atk2Name
.load_name
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ret

; returns carry if Defending Pokemon
; doesn't have an attack.
CheckIfDefendingPokemonHasAnyAttack: ; 2c40e (b:440e)
	call SwapTurn
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Atk1Category]
	cp POKEMON_POWER
	jr nz, .has_attack
	ld hl, wLoadedCard2Atk2Name
	ld a, [hli]
	or [hl]
	jr nz, .has_attack
	call SwapTurn
	scf
	ret
.has_attack
	call SwapTurn
	or a
	ret

; overwrites HP and Stage data of the card that was
; devolved in the Play Area to the values of new card.
; if the damage exceeds HP of pre-evolution,
; then HP is set to zero.
; input:
;	a = card index of pre-evolved card
UpdateDevolvedCardHPAndStage: ; 2c431 (b:4431)
	push bc
	push de
	push af
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld e, a
	call GetCardDamageAndMaxHP
	ld b, a ; store damage
	ld a, e
	add DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	pop af

	ld [hl], a
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, e
	add DUELVARS_ARENA_CARD_HP
	ld l, a
	ld a, [wLoadedCard2HP]
	sub b ; subtract damage from new HP
	jr nc, .got_hp
	; damage exceeds HP
	xor a ; 0 HP
.got_hp
	ld [hl], a
	ld a, e
; overwrite card stage
	add DUELVARS_ARENA_CARD_STAGE
	ld l, a
	ld a, [wLoadedCard2Stage]
	ld [hl], a
	pop de
	pop bc
	ret

; OATS possibly unreferenced after all changes.
; reset various status after devolving card.
ResetDevolvedCardStatus: ; 2c45d (b:445d)
; if it's Arena card, clear status conditions
	ldh a, [hTempPlayAreaLocation_ff9d]
	or a
	jr nz, .skip_clear_status
	call ClearAllStatusConditionsAndEffects
.skip_clear_status
; reset changed color status
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD_CHANGED_TYPE
	call GetTurnDuelistVariable
	ld [hl], $00
; reset C2 flags
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD_FLAGS
	ld l, a
	ld [hl], $00
	ret

; prompts the Player with a Yes/No question
; whether to quit the screen, even though
; they can select more cards from list.
; [hCurSelectionItem] holds number of cards
; that were already selected by the Player.
; input:
;	- a = total number of cards that can be selected
; output:
;	- carry set if "No" was selected
AskWhetherToQuitSelectingCards: ; 2c476 (b:4476)
	ld hl, hCurSelectionItem
	sub [hl]
	ld l, a
	ld h, $00
	call LoadTxRam3
	ldtx hl, YouCanSelectMoreCardsQuitText
	call YesOrNoMenuWithText
	ret

; handles the selection of a forced switch by link/AI opponent or by the player.
; outputs the Play Area location of the chosen bench card in hTempPlayAreaLocation_ff9d.
DuelistSelectForcedSwitch: ; 2c487 (b:4487)
	ld a, DUELVARS_DUELIST_TYPE
	call GetNonTurnDuelistVariable
	cp DUELIST_TYPE_LINK_OPP
	jr z, .link_opp

	cp DUELIST_TYPE_PLAYER
	jr z, .player

; AI opponent
	call SwapTurn
	bank1call AIDoAction_ForcedSwitch
	call SwapTurn

	ld a, [wPlayerAttackingAttackIndex]
	ld e, a
	ld a, [wPlayerAttackingCardIndex]
	ld d, a
	ld a, [wPlayerAttackingCardID]
	call CopyAttackDataAndDamage_FromCardID
	call Func_16f6
	ret

.player
	ldtx hl, SelectPkmnOnBenchToSwitchWithActiveText
	call DrawWideTextBox_WaitForInput
	call SwapTurn
	bank1call HasAlivePokemonInBench
	ld a, $01
	ld [wcbd4], a
.asm_2c4c0
	bank1call OpenPlayAreaScreenForSelection
	jr c, .asm_2c4c0
	call SwapTurn
	ret

.link_opp
; get selection from link opponent
	ld a, OPPACTION_FORCE_SWITCH_ACTIVE
	call SetOppAction_SerialSendDuelData
.loop
	call SerialRecvByte
	jr nc, .received
	halt
	nop
	jr .loop
.received
	ldh [hTempPlayAreaLocation_ff9d], a
	ret

; returns in a the card index of energy card
; attached to Defending Pokemon
; that is to be discarded by the AI for an effect.
; outputs $ff is none was found.
; output:
;	a = deck index of attached energy card chosen
AIPickEnergyCardToDiscardFromDefendingPokemon: ; 2c4da (b:44da)
	call SwapTurn
	ld e, PLAY_AREA_ARENA
	call GetPlayAreaCardAttachedEnergies

	xor a
	call CreateArenaOrBenchEnergyCardList
	jr nc, .has_energy
	; no energy, return
	ld a, $ff
	jr .done

.has_energy
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer1_FromDeckIndex
	ld e, COLORLESS
	ld a, [wAttachedEnergies + COLORLESS]
	or a
	jr nz, .pick_color ; has colorless attached?

	; no colorless energy attached.
	; if it's colorless Pokemon, just
	; pick any energy card at random...
	ld a, [wLoadedCard1Type]
	cp COLORLESS
	jr nc, .choose_random

	; ...if not, check if it has its
	; own color energy attached.
	; if it doesn't, pick at random.
	ld e, a
	ld d, $00
	ld hl, wAttachedEnergies
	add hl, de
	ld a, [hl]
	or a
	jr z, .choose_random

; pick attached card with same color as e
.pick_color
	ld hl, wDuelTempList
.loop_energy
	ld a, [hli]
	cp $ff
	jr z, .choose_random
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	and TYPE_PKMN
	cp e
	jr nz, .loop_energy
	dec hl

.done_chosen
	ld a, [hl]
.done
	call SwapTurn
	ret

.choose_random
	call CountCardsInDuelTempList
	ld hl, wDuelTempList
	call ShuffleCards
	jr .done_chosen

; handles AI logic to pick attack for Amnesia
AIPickAttackForAmnesia: ; 2c532 (b:4532)
; load Defending Pokemon attacks
	call SwapTurn
	ld e, PLAY_AREA_ARENA
	call GetPlayAreaCardAttachedEnergies
	call HandleEnergyBurn
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	ld d, a
	call LoadCardDataToBuffer2_FromDeckIndex
; if has no attack 1 name, return
	ld hl, wLoadedCard2Atk1Name
	ld a, [hli]
	or [hl]
	jr z, .chosen

; if Defending Pokemon has enough energy for second attack, choose it
	ld e, SECOND_ATTACK
	bank1call _CheckIfEnoughEnergiesToAttack
	jr nc, .chosen
; otherwise if first attack isn't a Pkmn Power, choose it instead.
	ld e, FIRST_ATTACK_OR_PKMN_POWER
	ld a, [wLoadedCard2Atk1Category]
	cp POKEMON_POWER
	jr nz, .chosen
; if it is a Pkmn Power, choose second attack.
	ld e, SECOND_ATTACK
.chosen
	ld a, e
	call SwapTurn
	ret

; Return in a the PLAY_AREA_* of the non-turn holder's Pokemon card
; in bench with the lowest (remaining) HP.
; if multiple cards are tied for the lowest HP, the one with
; the highest PLAY_AREA_* is returned.
GetOpponentBenchPokemonWithLowestHP:
	call SwapTurn
	call GetBenchPokemonWithLowestHP
	jp SwapTurn

; outputs:
;   a: PLAY_AREA_* of Pokémon with lowest HP
;   d: PLAY_AREA_* of Pokémon with lowest HP
;   e: lowest HP amount found
GetBenchPokemonWithLowestHP:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld c, a
	lb de, PLAY_AREA_ARENA, $ff
	ld b, d
	ld a, DUELVARS_BENCH1_CARD_HP
	call GetTurnDuelistVariable
	jr .start
; find Play Area location with least amount of HP
.loop_bench
	ld a, e
	cp [hl]
	jr c, .next ; skip if HP is higher
	ld e, [hl]
	ld d, b

.next
	inc hl
.start
	inc b
	dec c
	jr nz, .loop_bench

	ld a, d
	ret

; handles drawing and selection of screen for
; choosing a color (excluding colorless), for use
; of Shift Pkmn Power and Conversion attacks.
; outputs in a the color that was selected or,
; if B was pressed, returns carry.
; input:
;	a  = Play Area location (PLAY_AREA_*), with:
;	     bit 7 not set if it's applying to opponent's card
;	     bit 7 set if it's applying to player's card
;	hl = text to be printed in the bottom box
; output:
;	a = color that was selected
HandleColorChangeScreen: ; 2c588 (b:4588)
	or a
	call z, SwapTurn
	push af
	call .DrawScreen
	pop af
	call z, SwapTurn

	ld hl, .menu_params
	xor a
	call InitializeMenuParameters
	call EnableLCD

.loop_input
	call DoFrame
	call HandleMenuInput
	jr nc, .loop_input
	cp -1 ; b pressed?
	jr z, .set_carry
	ld e, a
	ld d, $00
	ld hl, ShiftListItemToColor
	add hl, de
	ld a, [hl]
	or a
	ret
.set_carry
	scf
	ret

.menu_params
	db 1, 1 ; cursor x, cursor y
	db 2 ; y displacement between items
	db MAX_PLAY_AREA_POKEMON ; number of items
	db SYM_CURSOR_R ; cursor tile number
	db SYM_SPACE ; tile behind cursor
	dw NULL ; function pointer if non-0

.DrawScreen: ; 2c5be (b:45be)
	push hl
	push af
	call EmptyScreen
	call ZeroObjectPositions
	call LoadDuelCardSymbolTiles

; load card data
	pop af
	and $7f
	ld [wTempPlayAreaLocation_cceb], a
	add DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer1_FromDeckIndex

; draw card gfx
	ld de, v0Tiles1 + $20 tiles ; destination offset of loaded gfx
	ld hl, wLoadedCard1Gfx
	ld a, [hli]
	ld h, [hl]
	ld l, a
	lb bc, $30, TILE_SIZE
	call LoadCardGfx
	bank1call SetBGP6OrSGB3ToCardPalette
	bank1call FlushAllPalettesOrSendPal23Packet
	ld a, $a0
	lb hl, 6, 1
	lb de, 9, 2
	lb bc, 8, 6
	call FillRectangle
	bank1call ApplyBGP6OrSGB3ToCardImage

; print card name and level at the top
	ld a, 16
	call CopyCardNameAndLevel
	ld [hl], $00
	lb de, 7, 0
	call InitTextPrinting
	ld hl, wDefaultText
	call ProcessText

; list all the colors
	ld hl, ShiftMenuData
	call PlaceTextItems

; print card's color, resistance and weakness
	ld a, [wTempPlayAreaLocation_cceb]
	call GetPlayAreaCardColor
	inc a
	lb bc, 15, 9
	call WriteByteToBGMap0
	ld a, [wTempPlayAreaLocation_cceb]
	call GetPlayAreaCardWeakness
	lb bc, 15, 10
	bank1call PrintCardPageWeaknessesOrResistances
	ld a, [wTempPlayAreaLocation_cceb]
	call GetPlayAreaCardResistance
	lb bc, 15, 11
	bank1call PrintCardPageWeaknessesOrResistances

	call DrawWideTextBox

; print list of color names on all list items
	lb de, 4, 1
	ldtx hl, ColorListText
	call InitTextPrinting_ProcessTextFromID

; print input hl to text box
	lb de, 1, 14
	pop hl
	call InitTextPrinting_ProcessTextFromID

; draw and apply palette to color icons
	ld hl, ColorTileAndBGP
	lb de, 2, 0
	ld c, NUM_COLORED_TYPES
.loop_colors
	ld a, [hli]
	push de
	push bc
	push hl
	lb hl, 1, 2
	lb bc, 2, 2
	call FillRectangle

	ld a, [wConsole]
	cp CONSOLE_CGB
	jr nz, .skip_vram1
	pop hl
	push hl
	call BankswitchVRAM1
	ld a, [hl]
	lb hl, 0, 0
	lb bc, 2, 2
	call FillRectangle
	call BankswitchVRAM0

.skip_vram1
	pop hl
	pop bc
	pop de
	inc hl
	inc e
	inc e
	dec c
	jr nz, .loop_colors
	ret

; loads wTxRam2 and wTxRam2_b:
; [wTxRam2]   <- wLoadedCard1Name
; [wTxRam2_b] <- input color as text symbol
; input:
;	a = type (color) constant
LoadCardNameAndInputColor: ; 2c686 (b:4686)
	add a
	ld e, a
	ld d, $00
	ld hl, ColorToTextSymbol
	add hl, de

; load wTxRam2 with card's name
	ld de, wTxRam2
	ld a, [wLoadedCard1Name]
	ld [de], a
	inc de
	ld a, [wLoadedCard1Name + 1]
	ld [de], a

; load wTxRam2_b with ColorToTextSymbol
	inc de
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	ret

ShiftMenuData: ; 2c6a1 (b:46a1)
	; x, y, text id
	textitem 10,  9, TypeText
	textitem 10, 10, WeaknessText
	textitem 10, 11, ResistanceText
	db $ff

ColorTileAndBGP: ; 2c6ae (b:46ae)
	; tile, BG
	db $e4, $02
	db $e0, $01
	db $eC, $02
	db $e8, $01
	db $f0, $03
	db $f4, $03

ShiftListItemToColor: ; 2c6ba (b:46ba)
	db GRASS
	db FIRE
	db WATER
	db LIGHTNING
	db FIGHTING
	db PSYCHIC

ColorToTextSymbol:  ; 2c6c0 (b:46c0)
	tx FireSymbolText
	tx GrassSymbolText
	tx LightningSymbolText
	tx WaterSymbolText
	tx FightingSymbolText
	tx PsychicSymbolText

DrawSymbolOnPlayAreaCursor: ; 2c6cc (b:46cc)
	ld c, a
	add a
	add c
	add 2
	; a = 3*a + 2
	ld c, a
	ld a, b
	ld b, 0
	call WriteByteToBGMap0
	ret


PlayAreaSelectionMenuParameters: ; 2c6e0 (b:46e0)
	db 0, 0 ; cursor x, cursor y
	db 3 ; y displacement between items
	db MAX_PLAY_AREA_POKEMON ; number of items
	db SYM_CURSOR_R ; cursor tile number
	db SYM_SPACE ; tile behind cursor
	dw NULL ; function pointer if non-0

BenchSelectionMenuParameters: ; 2c6e8 (b:46e8)
	db 0, 3 ; cursor x, cursor y
	db 3 ; y displacement between items
	db MAX_PLAY_AREA_POKEMON ; number of items
	db SYM_CURSOR_R ; cursor tile number
	db SYM_SPACE ; tile behind cursor
	dw NULL ; function pointer if non-0

; return carry if there are no Pokemon cards in the non-turn holder's bench
Lure_AssertPokemonInBench:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	ldtx hl, EffectNoPokemonOnTheBenchText
	cp 2
	ret

; return in hTempPlayAreaLocation_ffa1 the PLAY_AREA_* location
; of the Bench Pokemon that was selected for switch
Lure_SelectSwitchPokemon:
	ldtx hl, SelectPkmnOnBenchToSwitchWithActiveText
	call DrawWideTextBox_WaitForInput
	call SwapTurn
	bank1call HasAlivePokemonInBench
.select_pokemon
	bank1call OpenPlayAreaScreenForSelection
	jr c, .select_pokemon
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	call SwapTurn
	ret

; Return in hTemp_ffa0 the PLAY_AREA_* of the non-turn holder's Pokemon card in bench with the lowest (remaining) HP.
; if multiple cards are tied for the lowest HP, the one with the highest PLAY_AREA_* is returned.
Lure_GetOpponentBenchPokemonWithLowestHP:
	call GetOpponentBenchPokemonWithLowestHP
	ldh [hTemp_ffa0], a
	ret

; Defending Pokemon is swapped out for the one with the PLAY_AREA_* at hTemp_ffa0
; unless Mew's Neutralizing Shield or Haunter's Transparency prevents it.
Lure_SwitchDefendingPokemon:
	call SwapTurn
	ldh a, [hTemp_ffa0]
	ld e, a
	call HandleNShieldAndTransparency
	call nc, SwapArenaWithBenchPokemon
	call SwapTurn
	xor a
	ld [wDuelDisplayedScreen], a
	ret

PoisonLure_SwitchEffect:
	call Lure_SwitchDefendingPokemon
	jp PoisonEffect


Lure_SwitchAndTrapDefendingPokemon:
	call Lure_SwitchDefendingPokemon
	jp UnableToRetreatEffect


KakunaPoisonPowder_AIEffect: ; 2c7b4 (b:47b4)
	ld a, 5
	lb de, 0, 10
	jp UpdateExpectedAIDamage_AccountForPoison


; During your next turn, double damage
SwordsDanceEffect: ; 2c7d0 (b:47d0)
	ld a, [wTempTurnDuelistCardID]
	cp SCYTHER
	ret nz
	ld a, SUBSTATUS1_NEXT_TURN_DOUBLE_DAMAGE
	call ApplySubstatus1ToAttackingCard
	ret


FoulGas_AIEffect: ; 2c822 (b:4822)
	ld a, 5
	lb de, 0, 10
	jp UpdateExpectedAIDamage

; If heads, defending Pokemon becomes poisoned. If tails, defending Pokemon becomes confused
FoulGas_PoisonOrConfusionEffect: ; 2c82a (b:482a)
	ldtx de, PoisonedIfHeadsConfusedIfTailsText
	call TossCoin_BankB
	jp c, PoisonEffect
	jp ConfusionEffect


Agility_PlayerSelectEffect:
OldTeleport_PlayerSelectEffect:
	ld a, $ff
	ldh [hTemp_ffa0], a
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	cp 2
	jr c, .done

	ldtx hl, SelectPkmnOnBenchToSwitchWithActiveText
	call DrawWideTextBox_WaitForInput
	bank1call HasAlivePokemonInBench
	ld a, $01
	ld [wcbd4], a
	bank1call OpenPlayAreaScreenForSelection
	jr c, .done
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
.done
	or a
	ret

Agility_AISelectEffect:
OldTeleport_AISelectEffect:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	call Random
	ldh [hTemp_ffa0], a
	ret

Agility_SwitchEffect:
OldTeleport_SwitchEffect:
	ldh a, [hTemp_ffa0]
	cp $ff
	ret z
	or a
	ret z
	ld e, a
	call SwapArenaWithBenchPokemon
	xor a
	ld [wDuelDisplayedScreen], a
	ret


Teleport_PlayerSelectEffect:
	ldtx hl, SelectPokemonToPlaceInTheArenaText
	call DrawWideTextBox_WaitForInput
	bank1call HasAlivePokemonInBench
	bank1call OpenPlayAreaScreenForSelection
	; ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	ret


Teleport_ReturnToDeckEffect:
	xor a  ; PLAY_AREA_ARENA
	call ReturnPlayAreaPokemonToDeckEffect
	ld a, 4
	jp DrawNCards_NoCardDetails


Eggsplosion_AIEffect:
	ld a, 3
	call GetNumAttachedEnergiesAtMostA_Arena
; tails = heal 10, heads = deal 10
	call ATimes10
	ld d, 0
	ld e, a
	srl a
	; ld a, 15
	; lb de, 0, 30
	jp SetExpectedAIDamage

; Flip coins equal to attached energies;
; deal 10 damage per heads and heal 10 damage per tails
; cap at 30 damage
Eggsplosion_MultiplierEffect:
	ld a, 3
	call GetNumAttachedEnergiesAtMostA_Arena
	call X10DamagePerHeads_MultiplierEffect
; heal 10 damage per tails (store for later)
	ld a, [wCoinTossNumTails]
	ldh [hTemp_ffa0], a
	ret

; heal 10 damage for each tails, stored in [hTemp_ffa0]
Eggsplosion_HealEffect:
	ldh a, [hTemp_ffa0]
	call ATimes10
	jp HealADamageEffect


; returns carry if no Grass Energy in Play Area
EnergyTrans_CheckPlayArea: ; 2cb44 (b:4b44)
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	call CheckCannotUseDueToStatus_Anywhere
	ret c ; cannot use Pkmn Power

; search in Play Area for at least 1 Grass Energy type
	ld a, DUELVARS_CARD_LOCATIONS
	call GetTurnDuelistVariable
.loop_deck
	ld a, [hl]
	and CARD_LOCATION_PLAY_AREA
	jr z, .next
	push hl
	ld a, l
	call GetCardIDFromDeckIndex
	call GetCardType
	pop hl
	cp TYPE_ENERGY_GRASS
	ret z
.next
	inc l
	ld a, l
	cp DECK_SIZE
	jr c, .loop_deck

; none found
	ldtx hl, NoGrassEnergyText
	scf
	ret

EnergyTrans_PrintProcedure: ; 2cb6f (b:4b6f)
	ldtx hl, ProcedureForEnergyTransferText
	bank1call DrawWholeScreenTextBox
	or a
	ret

EnergyTrans_TransferEffect: ; 2cb77 (b:4b77)
	ld a, DUELVARS_DUELIST_TYPE
	call GetTurnDuelistVariable
	cp DUELIST_TYPE_PLAYER
	jr z, .player
; not player
	bank1call Func_61a1
	bank1call PrintPlayAreaCardList_EnableLCD
	ret

.player
	xor a
	ldh [hCurSelectionItem], a
	bank1call Func_61a1

.draw_play_area
	bank1call PrintPlayAreaCardList_EnableLCD
	push af
	ldh a, [hCurSelectionItem]
	ld hl, PlayAreaSelectionMenuParameters
	call InitializeMenuParameters
	pop af
	ld [wNumMenuItems], a

; handle the action of taking a Grass Energy card
.loop_input_take
	call DoFrame
	call HandleMenuInput
	jr nc, .loop_input_take
	cp -1 ; b press?
	ret z

; a press
	ldh [hAIPkmnPowerEffectParam], a
	ldh [hCurSelectionItem], a
	call CheckIfCardHasGrassEnergyAttached
	jr c, .play_sfx ; no Grass attached

	ldh [hAIEnergyTransEnergyCard], a
	; temporarily take card away to draw Play Area
	call AddCardToHand
	bank1call PrintPlayAreaCardList_EnableLCD
	ldh a, [hAIPkmnPowerEffectParam]
	ld e, a
	ldh a, [hAIEnergyTransEnergyCard]
	; give card back
	call PutHandCardInPlayArea

	; draw Grass symbol near cursor
	ldh a, [hAIPkmnPowerEffectParam]
	ld b, SYM_GRASS
	call DrawSymbolOnPlayAreaCursor

; handle the action of placing a Grass Energy card
.loop_input_put
	call DoFrame
	call HandleMenuInput
	jr nc, .loop_input_put
	cp -1 ; b press?
	jr z, .remove_symbol

; a press
	ldh [hCurSelectionItem], a
	ldh [hAIEnergyTransPlayAreaLocation], a
	ld a, OPPACTION_6B15
	call SetOppAction_SerialSendDuelData
	ldh a, [hAIEnergyTransPlayAreaLocation]
	ld e, a
	ldh a, [hAIEnergyTransEnergyCard]
	; give card being held to this Pokemon
	call AddCardToHand
	call PutHandCardInPlayArea

.remove_symbol
	ldh a, [hAIPkmnPowerEffectParam]
	ld b, SYM_SPACE
	call DrawSymbolOnPlayAreaCursor
	call EraseCursor
	jr .draw_play_area

.play_sfx
	call PlaySFX_InvalidChoice
	jr .loop_input_take

EnergyTrans_AIEffect: ; 2cbfb (b:4bfb)
	ldh a, [hAIEnergyTransPlayAreaLocation]
	ld e, a
	ldh a, [hAIEnergyTransEnergyCard]
	call AddCardToHand
	call PutHandCardInPlayArea
	bank1call PrintPlayAreaCardList_EnableLCD
	ret


; ------------------------------------------------------------------------------
; Color Manipulation
; ------------------------------------------------------------------------------


EnergySoak_ChangeColorEffect:
	ld a, WATER
	ld [wEnergyColorOverride], a
	jp SetUsedPokemonPowerThisTurn

EnergyJolt_ChangeColorEffect:
	ld a, LIGHTNING
	ld [wEnergyColorOverride], a
	jp SetUsedPokemonPowerThisTurn

EnergyBurn_ChangeColorEffect:
	ld a, FIRE
	ld [wEnergyColorOverride], a
	jp SetUsedPokemonPowerThisTurn


VaporEssence_OncePerTurnCheck:
JoltEssence_OncePerTurnCheck:
FlareEssence_OncePerTurnCheck:
	ldh a, [hTempPlayAreaLocation_ff9d]
	; add DUELVARS_ARENA_CARD_FLAGS
	; call GetTurnDuelistVariable
	; and USED_PKMN_POWER_THIS_TURN
	; jr nz, .already_used
	call CheckCannotUseDueToStatus_Anywhere
	ret c
	ld a, DUELVARS_ARENA_CARD_STAGE
	call GetTurnDuelistVariable
	ldtx hl, OnlyWorksOnEvolvedPokemonText
	cp STAGE1
	ret
; .already_used
	; ldtx hl, OnlyOncePerTurnText
	; scf
	; ret


Shift_PlayerSelectEffect: ; 2cd21 (b:4d21)
	ldtx hl, ChoosePokemonWishToColorChangeText
	ldh a, [hTemp_ffa0]
	or $80
	call HandleColorChangeScreen
	ldh [hAIPkmnPowerEffectParam], a
	ret c ; cancelled

; check whether the color selected is valid
	; look in Turn Duelist's Play Area
	call .CheckColorInPlayArea
	ret nc
	; look in NonTurn Duelist's Play Area
	call SwapTurn
	call .CheckColorInPlayArea
	call SwapTurn
	ret nc
	; not found in either Duelist's Play Area
	ldtx hl, UnableToSelectText
	call DrawWideTextBox_WaitForInput
	jr Shift_PlayerSelectEffect ; loop back to start

; checks in input color in a exists in Turn Duelist's Play Area
; returns carry if not found.
.CheckColorInPlayArea: ; 2cd44 (b:4d44)
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld c, a
	ld b, PLAY_AREA_ARENA
.loop_play_area
	push bc
	ld a, b
	call GetPlayAreaCardColor
	pop bc
	ld hl, hAIPkmnPowerEffectParam
	cp [hl]
	ret z ; found
	inc b
	dec c
	jr nz, .loop_play_area
	; not found
	scf
	ret


SetUsedPokemonPowerThisTurn:
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD_FLAGS
	call GetTurnDuelistVariable
	set USED_PKMN_POWER_THIS_TURN_F, [hl]
	ret


Steamroller_ChangeColorEffect:
; store current card color
	ld a, DUELVARS_ARENA_CARD_CHANGED_TYPE
	call GetTurnDuelistVariable
	ldh [hTemp_ffa0], a
; temporarily change color to Fighting
	ld a, FIGHTING
	or HAS_CHANGED_COLOR | IS_PERMANENT_COLOR
	ld [hl], a
	ret


Shift_ChangeColorEffect:
	ldh a, [hTemp_ffa0]
	add DUELVARS_ARENA_CARD_FLAGS
	call GetTurnDuelistVariable
	set USED_PKMN_POWER_THIS_TURN_F, [hl]

	ldh a, [hTemp_ffa0]
	ld e, a
	ldh a, [hAIPkmnPowerEffectParam]
	ld d, a
	jr ColorShift_ChangeColorEffect

VaporEssence_ChangeColorEffect:
	call SetUsedPokemonPowerThisTurn
	ld e, PLAY_AREA_ARENA
	ld d, WATER
	jr ColorShift_ChangeColorEffect

JoltEssence_ChangeColorEffect:
	call SetUsedPokemonPowerThisTurn
	ld e, PLAY_AREA_ARENA
	ld d, LIGHTNING
	jr ColorShift_ChangeColorEffect

FlareEssence_ChangeColorEffect:
	call SetUsedPokemonPowerThisTurn
	ld e, PLAY_AREA_ARENA
	ld d, FIRE
	jr ColorShift_ChangeColorEffect


; changes the effective color of a Pokémon in play
; input:
;   e: offset of play area Pokémon
;   d: selected color (type) constant
ColorShift_ChangeColorEffect:
	call _ChangeCardColor
	call LoadCardNameAndInputColor
	ldtx hl, ChangedTheColorOfText
	jp DrawWideTextBox_WaitForInput


; changes the effective color of a Pokémon in play
; input:
;   e: offset of play area Pokémon
;   d: selected color (type) constant
_ChangeCardColor:
	ld a, e
	add DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer1_FromDeckIndex

	ld a, e
	add DUELVARS_ARENA_CARD_CHANGED_TYPE
	ld l, a
	ld a, d
	or HAS_CHANGED_COLOR
	ld [hl], a
	ret

_ChangeCardColorPermanent:
	call _ChangeCardColor
	or IS_PERMANENT_COLOR
	ld [hl], a
	ret


; resets the effective color of the Areana Pokémon
ResetArenaCardColorEffect:
	xor a  ; PLAY_AREA_ARENA
	ld e, a
	; fallthrough

; resets the effective color of a Pokémon in play
; input:
;   e: offset of play area Pokémon
ResetCardColorEffect:
	call _ResetCardColor
	ld a, e
	call GetPlayAreaCardColor
	ld [hl], a
	call LoadCardNameAndInputColor
	ldtx hl, ChangedTheColorOfText
	jp DrawWideTextBox_WaitForInput


; resets the effective color of a Pokémon in play
; input:
;   e: offset of play area Pokémon
_ResetCardColor:
	ld a, e
	add DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer1_FromDeckIndex

	ld a, e
	add DUELVARS_ARENA_CARD_CHANGED_TYPE
	ld l, a
	res HAS_CHANGED_COLOR_F, [hl]
	res IS_PERMANENT_COLOR_F, [hl]
	ret


; VenomPowder_AIEffect: ; 2cd84 (b:4d84)
; 	ld a, 5
; 	lb de, 0, 10
; 	jp UpdateExpectedAIDamage

; VenomPowder_PoisonConfusion50PercentEffect: ; 2cd8c (b:4d8c)
; 	ldtx de, VenomPowderCheckText
; 	call TossCoin_BankB
; 	ret nc ; return if tails
;
; ; heads
; 	call PoisonEffect
; 	call ConfusionEffect
; 	ret c
; 	ld a, CONFUSED | POISONED
; 	ld [wNoEffectFromWhichStatus], a
; 	ret

VenomPowder_PoisonConfusionEffect:
	call PoisonEffect
	call ConfusionEffect
	ret c
	ld a, CONFUSED | POISONED
	ld [wNoEffectFromWhichStatus], a
	ret

Heal_OncePerTurnCheck:
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	add DUELVARS_ARENA_CARD_FLAGS
	call GetTurnDuelistVariable
	and USED_PKMN_POWER_THIS_TURN
	jr nz, .already_used

	call CheckIfPlayAreaHasAnyDamage
	ret c ; no damage counters to heal

	ldh a, [hTemp_ffa0]
	call CheckCannotUseDueToStatus_Anywhere
	ret

.already_used
	ldtx hl, OnlyOncePerTurnText
	scf
	ret

Heal_RemoveDamageEffect:
; OATS no longer requires a coin flip
	ld a, 1
	ldh [hAIPkmnPowerEffectParam], a
	; ldtx de, IfHeadsHealIsSuccessfulText
	; call TossCoin_BankB
	; ldh [hAIPkmnPowerEffectParam], a
	; jr nc, .done

	ld a, DUELVARS_DUELIST_TYPE
	call GetTurnDuelistVariable
	cp DUELIST_TYPE_LINK_OPP
	jr z, .link_opp
	and DUELIST_TYPE_AI_OPP
	jr nz, .done

; player
	ldtx hl, ChoosePkmnToHealText
	call DrawWideTextBox_WaitForInput
	call HandlePlayerSelectionDamagedPokemonInPlayArea
	ldh [hPlayAreaEffectTarget], a
	call SerialSend8Bytes
	jr .done

.link_opp
	call SerialRecv8Bytes
	ldh [hPlayAreaEffectTarget], a
	; fallthrough

.done
; flag Pkmn Power as being used
	ldh a, [hTemp_ffa0]
	add DUELVARS_ARENA_CARD_FLAGS
	call GetTurnDuelistVariable
	set USED_PKMN_POWER_THIS_TURN_F, [hl]
; heal the selected Pokémon
	ldh a, [hPlayAreaEffectTarget]
	ld e, a   ; location
	ld d, 10  ; damage
	call HealPlayAreaCardHP
	call ExchangeRNG
	ret

PetalDance_BonusEffect:
	call Heal20DamageFromAll_HealEffect
	call SwapTurn
	call ConfusionEffect
	call SwapTurn
	ret

PoisonWhip_AIEffect: ; 2ce4b (b:4e4b)
	ld a, 10
	lb de, 10, 10
	jp UpdateExpectedAIDamage_AccountForPoison

SolarPower_CheckUse: ; 2ce53 (b:4e53)
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	add DUELVARS_ARENA_CARD_FLAGS
	call GetTurnDuelistVariable
	and USED_PKMN_POWER_THIS_TURN
	jr nz, .already_used

	ldh a, [hTempPlayAreaLocation_ff9d]
	call CheckCannotUseDueToStatus_Anywhere
	ret c ; can't use PKMN due to status or Toxic Gas

; return carry if none of the Arena cards have status conditions
	ld a, DUELVARS_ARENA_CARD_STATUS
	call GetTurnDuelistVariable
	or a
	jr nz, .has_status
	ld a, DUELVARS_ARENA_CARD_STATUS
	call GetNonTurnDuelistVariable
	or a
	jr z, .no_status
.has_status
	or a
	ret
.already_used
	ldtx hl, OnlyOncePerTurnText
	scf
	ret
.no_status
	ldtx hl, NotAffectedByPoisonSleepParalysisOrConfusionText
	scf
	ret

SolarPower_RemoveStatusEffect: ; 2ce82 (b:4e82)
	ld a, ATK_ANIM_HEAL_BOTH_SIDES
	ld [wLoadedAttackAnimation], a
	bank1call Func_7415
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld b, a
	ld c, $00
	ldh a, [hWhoseTurn]
	ld h, a
	bank1call PlayAttackAnimation
	bank1call WaitAttackAnimation

	ldh a, [hTemp_ffa0]
	add DUELVARS_ARENA_CARD_FLAGS
	call GetTurnDuelistVariable
	set USED_PKMN_POWER_THIS_TURN_F, [hl]
	ld l, DUELVARS_ARENA_CARD_STATUS
	ld [hl], NO_STATUS

	ld a, DUELVARS_ARENA_CARD_STATUS
	call GetNonTurnDuelistVariable
	ld [hl], NO_STATUS
	bank1call DrawDuelHUDs
	ret

HelpingHand_CheckUse:
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	ldtx hl, CanOnlyBeUsedOnTheBenchText
	or a
	jr z, .set_carry

	add DUELVARS_ARENA_CARD_FLAGS
	call GetTurnDuelistVariable
	and USED_PKMN_POWER_THIS_TURN
	jr nz, .already_used

	ldh a, [hTempPlayAreaLocation_ff9d]
	call CheckCannotUseDueToStatus_Anywhere
	ret c ; can't use PKMN due to status or Toxic Gas

; return carry if the Arena card does not have status conditions
	ld a, DUELVARS_ARENA_CARD_STATUS
	call GetTurnDuelistVariable
	or a
	jr z, .no_status
	ret

.already_used
	ldtx hl, OnlyOncePerTurnText
	scf
	ret

.no_status
	ldtx hl, NotAffectedByPoisonSleepParalysisOrConfusionText
.set_carry
	scf
	ret

HelpingHand_RemoveStatusEffect:
	ld a, ATK_ANIM_HEAL
	ld [wLoadedAttackAnimation], a
	bank1call Func_7415
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld b, a
	ld c, $00
	ldh a, [hWhoseTurn]
	ld h, a
	bank1call PlayAttackAnimation
	bank1call WaitAttackAnimation

	ldh a, [hTemp_ffa0]
	add DUELVARS_ARENA_CARD_FLAGS
	call GetTurnDuelistVariable
	set USED_PKMN_POWER_THIS_TURN_F, [hl]
	ld l, DUELVARS_ARENA_CARD_STATUS
	ld [hl], NO_STATUS

	bank1call DrawDuelHUDs
	ret



HeadacheEffect: ; 2d00e (b:500e)
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS3
	call GetNonTurnDuelistVariable
	set SUBSTATUS3_HEADACHE, [hl]
	ret


; returns carry if Defending Pokemon has no attacks
Amnesia_CheckAttacks: ; 2d149 (b:5149)
	call SwapTurn
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Atk1Category]
	cp POKEMON_POWER
	jr nz, .has_attack
	ld hl, wLoadedCard2Atk2Name
	ld a, [hli]
	or [hl]
	jr nz, .has_attack
; has no attack
	call SwapTurn
	ldtx hl, NoAttackMayBeChoosenText
	scf
	ret
.has_attack
	call SwapTurn
	or a
	ret

Amnesia_PlayerSelectEffect: ; 2d16f (b:516f)
	call PlayerPickAttackForAmnesia
	ret

Amnesia_AISelectEffect: ; 2d173 (b:5173)
	call AIPickAttackForAmnesia
	ldh [hTemp_ffa0], a
	ret

Amnesia_DisableEffect: ; 2d179 (b:5179)
	call ApplyAmnesiaToAttack
	ret

PlayerPickAttackForAmnesia: ; 2d17d (b:517d)
	ldtx hl, ChooseAttackOpponentWillNotBeAbleToUseText
	call DrawWideTextBox_WaitForInput
	call HandleDefendingPokemonAttackSelection
	ld a, e
	ldh [hTemp_ffa0], a
	ret

; applies the Amnesia effect on the defending Pokemon,
; for the attack index in hTemp_ffa0.
ApplyAmnesiaToAttack: ; 2d18a (b:518a)
	ld a, SUBSTATUS2_AMNESIA
	call ApplySubstatus2ToDefendingCard
	ld a, [wNoDamageOrEffect]
	or a
	ret nz ; no effect

; set selected attack as disabled
	ld a, DUELVARS_ARENA_CARD_DISABLED_ATTACK_INDEX
	call GetNonTurnDuelistVariable
	ldh a, [hTemp_ffa0]
	ld [hl], a

	ld l, DUELVARS_ARENA_CARD_LAST_TURN_EFFECT
	ld [hl], LAST_TURN_EFFECT_AMNESIA

	call IsPlayerTurn
	ret c ; return if Player

; the rest of the routine if for Opponent
; to announce which attack was used for Amnesia.
	call SwapTurn
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	ld d, a
	ldh a, [hTemp_ffa0]
	ld e, a
	call GetAttackName
	call LoadTxRam2
	ldtx hl, WasChosenForTheEffectOfAmnesiaText
	call DrawWideTextBox_WaitForInput
	call SwapTurn
	ret

PoliwhirlDoubleslap_AIEffect: ; 2d1c0 (b:51c0)
	ld a, 60 / 2
	lb de, 0, 60
	jp SetExpectedAIDamage

PoliwhirlDoubleslap_MultiplierEffect: ; 2d1c8 (b:51c8)
	ld hl, 30
	call LoadTxRam3
	ldtx de, DamageCheckIfHeadsXDamageText
	ld a, 2
	call TossCoinATimes_BankB
	ld e, a
	add a
	add e
	call ATimes10
	call SetDefiniteDamage
	ret


Whirlpool_PlayerSelectEffect: ; 2d1e6 (b:51e6)
	call SwapTurn
	xor a ; PLAY_AREA_ARENA
	call CreateArenaOrBenchEnergyCardList
	jr c, .no_energy

	ldtx hl, ChooseDiscardEnergyCardFromOpponentText
	call DrawWideTextBox_WaitForInput
	xor a ; PLAY_AREA_ARENA
	bank1call DisplayEnergyDiscardScreen
.loop_input
	bank1call HandleEnergyDiscardMenuInput
	jr c, .loop_input

	call SwapTurn
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a ; store selected card to discard
	ret

.no_energy
	call SwapTurn
	ld a, $ff
	ldh [hTemp_ffa0], a
	ret

Whirlpool_AISelectEffect: ; 2d20e (b:520e)
	call AIPickEnergyCardToDiscardFromDefendingPokemon
	ldh [hTemp_ffa0], a
	ret

Whirlpool_DiscardEffect: ; 2d214 (b:5214)
	call HandleNoDamageOrEffect
	ret c ; return if attack had no effect
	ldh a, [hTemp_ffa0]
	cp $ff
	ret z ; return if none selected

	; discard Defending card's energy
	; this doesn't update DUELVARS_ARENA_CARD_LAST_TURN_EFFECT
	call SwapTurn
	call PutCardInDiscardPile
	; ld a, DUELVARS_ARENA_CARD_LAST_TURN_EFFECT
	; call GetTurnDuelistVariable
	; ld [hl], LAST_TURN_EFFECT_DISCARD_ENERGY
	call SwapTurn
	ret


; return carry if can use Cowardice
Cowardice_Check:
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	call CheckCannotUseDueToStatus_Anywhere
	ret c ; return if cannot use

	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ldtx hl, EffectNoPokemonOnTheBenchText
	cp 2
	ret c ; return if no bench

	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD_FLAGS
	call GetTurnDuelistVariable
	ldtx hl, CannotBeUsedInTurnWhichWasPlayedText
	and CAN_EVOLVE_THIS_TURN
	scf
	ret z ; return if was played this turn

	or a
	ret

Cowardice_PlayerSelectEffect:
	ldh a, [hTemp_ffa0]
	or a
	ret nz ; return if not Arena card
	ldtx hl, SelectPokemonToPlaceInTheArenaText
	call DrawWideTextBox_WaitForInput
	bank1call HasAlivePokemonInBench
	bank1call OpenPlayAreaScreenForSelection
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hAIPkmnPowerEffectParam], a
	ret

Cowardice_RemoveFromPlayAreaEffect:
	ldh a, [hTemp_ffa0]
	add DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable

; put card in Discard Pile temporarily, so that
; all cards attached are discarded as well.
	push af
	ldh a, [hTemp_ffa0]
	ld e, a
	call MovePlayAreaCardToDiscardPile

; if card was in Arena, swap selected Bench
; Pokemon with Arena, otherwise skip.
	ldh a, [hTemp_ffa0]
	or a
	jr nz, .skip_switch
	ldh a, [hAIPkmnPowerEffectParam]
	ld e, a
	call SwapArenaWithBenchPokemon

.skip_switch
; move card back to Hand from Discard Pile
; and adjust Play Area
	pop af
	call MoveDiscardPileCardToHand
	call AddCardToHand
	call ShiftAllPokemonToFirstPlayAreaSlots

	xor a
	ld [wDuelDisplayedScreen], a
	ret


Quickfreeze_Paralysis50PercentEffect: ; 2d2f3 (b:52f3)
	ldtx de, ParalysisCheckText
	call TossCoin_BankB
	jr c, .heads

; tails
	call SetWasUnsuccessful
	bank1call DrawDuelMainScene
	call PrintNoEffectTextOrUnsuccessfulText
	call WaitForWideTextBoxInput
	ret

.heads
	call ParalysisEffect
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld b, a
	ld c, $00
	ldh a, [hWhoseTurn]
	ld h, a
	bank1call PlayAttackAnimation
	bank1call Func_741a
	bank1call WaitAttackAnimation
	bank1call Func_6df1
	bank1call DrawDuelHUDs
	call PrintNoEffectTextOrUnsuccessfulText
	call c, WaitForWideTextBoxInput
	ret

IceBreath_ZeroDamage: ; 2d329 (b:5329)
	xor a
	call SetDefiniteDamage
	ret

IceBreath_BenchDamageEffect:
	ldh a, [hTemp_ffa0]
	cp $ff
	ret z
	call SwapTurn
	ldh a, [hTemp_ffa0]
	ld b, a
	ld de, 40
	call DealDamageToPlayAreaPokemon_RegularAnim
	call SwapTurn
	ret


PlayerPickFireEnergyCardToDiscard: ; 2d34b (b:534b)
	call CreateListOfFireEnergyAttachedToArena
	xor a
	bank1call DisplayEnergyDiscardScreen
	bank1call HandleEnergyDiscardMenuInput
	ldh a, [hTempCardIndex_ff98]
	ldh [hTempList], a
	ret

AIPickFireEnergyCardToDiscard: ; 2d35a (b:535a)
	call CreateListOfFireEnergyAttachedToArena
	ld a, [wDuelTempList]
	ldh [hTempList], a ; pick first in list
	ret


; return carry if no Fire energy cards
Wildfire_CheckEnergy: ; 2d49b (b:549b)
	ld e, PLAY_AREA_ARENA
	call GetPlayAreaCardAttachedEnergies
	call HandleEnergyBurn
	ldtx hl, NotEnoughFireEnergyText
	ld a, [wAttachedEnergies + FIRE]
	cp 1
	ret

Wildfire_PlayerSelectEffect: ; 2d4a9 (b:54a9)
	ldtx hl, DiscardOppDeckAsManyFireEnergyCardsText
	call DrawWideTextBox_WaitForInput

	xor a
	ldh [hCurSelectionItem], a
	call CreateListOfFireEnergyAttachedToArena
	xor a
	bank1call DisplayEnergyDiscardScreen

; show list to Player and for each card selected to discard,
; just increase a counter and store it.
; this will be the output used by Wildfire_DiscardEnergyEffect.
	xor a
	ld [wEnergyDiscardMenuDenominator], a
.loop
	ldh a, [hCurSelectionItem]
	ld [wEnergyDiscardMenuNumerator], a
	bank1call HandleEnergyDiscardMenuInput
	jr c, .done
	ld hl, hCurSelectionItem
	inc [hl]
	call RemoveCardFromDuelTempList
	jr c, .done
	bank1call DisplayEnergyDiscardMenu
	jr .loop

.done
; return carry if no cards were discarded
; output the result in hTemp_ffa0
	ldh a, [hCurSelectionItem]
	ldh [hTemp_ffa0], a
	or a
	ret nz
	scf
	ret

Wildfire_AISelectEffect: ; 2d4dd (b:54dd)
; AI always chooses 0 cards to discard
	xor a
	ldh [hTempList], a
	ret

Wildfire_DiscardEnergyEffect: ; 2d4e1 (b:54e1)
	call CreateListOfFireEnergyAttachedToArena
	ldh a, [hTemp_ffa0]
	or a
	ret z ; no cards to discard

; discard cards from wDuelTempList equal to the number
; of cards that were input in hTemp_ffa0.
; these are all the Fire Energy cards attached to Arena card
; so it will discard the cards in order, regardless
; of the actual order that was selected by Player.
	ld c, a
	ld hl, wDuelTempList
.loop_discard
	ld a, [hli]
	call PutCardInDiscardPile
	dec c
	jr nz, .loop_discard
	ret


FlareonQuickAttack_AIEffect: ; 2d541 (b:5541)
	ld a, (10 + 30) / 2
	lb de, 10, 30
	jp SetExpectedAIDamage

FlareonQuickAttack_DamageBoostEffect: ; 2d549 (b:5549)
	ld hl, 20
	call LoadTxRam3
	ldtx de, DamageCheckIfHeadsPlusDamageText
	call TossCoin_BankB
	ret nc ; return if tails
	ld a, 20
	call AddToDamage
	ret


Rage_AIEffect:
	call Rage_DamageBoostEffect
	jp SetDefiniteAIDamage

Rage_DamageBoostEffect:
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	call AddToDamage
	ret

Firegiver_AddToHandEffect: ; 2d6c2 (b:56c2)
; fill wDuelTempList with all Fire Energy card
; deck indices that are in the Deck.
	ld a, DUELVARS_CARD_LOCATIONS
	call GetTurnDuelistVariable
	ld de, wDuelTempList
	ld c, 0
.loop_cards
	ld a, [hl]
	cp CARD_LOCATION_DECK
	jr nz, .next
	push hl
	push de
	ld a, l
	call GetCardIDFromDeckIndex
	call GetCardType
	pop de
	pop hl
	cp TYPE_ENERGY_FIRE
	jr nz, .next
	ld a, l
	ld [de], a
	inc de
	inc c
.next
	inc l
	ld a, l
	cp DECK_SIZE
	jr c, .loop_cards
	ld a, $ff
	ld [de], a

; check how many were found
	ld a, c
	or a
	jr nz, .found
	; return if none found
	ldtx hl, ThereWasNoFireEnergyText
	call DrawWideTextBox_WaitForInput
	call SyncShuffleDeck
	ret

.found
; pick a random number between 1 and 4,
; up to the maximum number of Fire Energy
; cards that were found.
	ld a, 4
	call Random
	inc a
	cp c
	jr c, .ok
	ld a, c

.ok
	ldh [hCurSelectionItem], a
; load correct attack animation depending
; on what side the effect is from.
	ld d, ATK_ANIM_FIREGIVER_PLAYER
	ld a, [wDuelistType]
	cp DUELIST_TYPE_PLAYER
	jr z, .player_1
; opponent
	ld d, ATK_ANIM_FIREGIVER_OPP
.player_1
	ld a, d
	ld [wLoadedAttackAnimation], a

; start loop for adding Energy cards to hand
	ldh a, [hCurSelectionItem]
	ld c, a
	ld hl, wDuelTempList
.loop_energy
	push hl
	push bc
	ld bc, $0
	ldh a, [hWhoseTurn]
	ld h, a
	bank1call PlayAttackAnimation
	bank1call WaitAttackAnimation

; load correct coordinates to update the number of cards
; in hand and deck during animation.
	lb bc, 18, 7 ; x, y for hand number
	ld e, 3 ; y for deck number
	ld a, [wLoadedAttackAnimation]
	cp ATK_ANIM_FIREGIVER_PLAYER
	jr z, .player_2
	lb bc, 4, 5 ; x, y for hand number
	ld e, 10 ; y for deck number

.player_2
; update and print number of cards in hand
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	call GetTurnDuelistVariable
	inc a
	bank1call WriteTwoDigitNumberInTxSymbolFormat
; update and print number of cards in deck
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	call GetTurnDuelistVariable
	ld a, DECK_SIZE - 1
	sub [hl]
	ld c, e
	bank1call WriteTwoDigitNumberInTxSymbolFormat

; load Fire Energy card index and add to hand
	pop bc
	pop hl
	ld a, [hli]
	call SearchCardInDeckAndSetToJustDrawn
	call AddCardToHand
	dec c
	jr nz, .loop_energy

; load the number of cards added to hand and print text
	ldh a, [hCurSelectionItem]
	ld l, a
	ld h, $00
	call LoadTxRam3
	ldtx hl, DrewFireEnergyFromTheHandText
	call DrawWideTextBox_WaitForInput
	call SyncShuffleDeck
	ret

MoltresLv37DiveBomb_AIEffect: ; 2d76e (b:576e)
	ld a, 70 / 2
	lb de, 0, 70
	jp SetExpectedAIDamage

MoltresLv37DiveBomb_Success50PercentEffect: ; 2d776 (b:5776)
	ldtx de, SuccessCheckIfHeadsAttackIsSuccessfulText
	call TossCoin_BankB
	jr c, .heads
; tails
	xor a
	call SetDefiniteDamage
	call SetWasUnsuccessful
	ret
.heads
	ld a, ATK_ANIM_DIVE_BOMB
	ld [wLoadedAttackAnimation], a
	ret


; draws list of Energy Cards in Discard Pile
; for Player to select from.
; the Player can select up to 2 cards from the list.
; these cards are given in $ff-terminated list
; in hTempList.
HandleEnergyCardsInDiscardPileSelection:
	push hl
	xor a
	ldh [hCurSelectionItem], a
	call CreateEnergyCardListFromDiscardPile_OnlyBasic
	; call CreateEnergyCardListFromDiscardPile_AllEnergy
	pop hl
	jr c, .finish

	call DrawWideTextBox_WaitForInput
.loop
	call Helper_ChooseAnEnergyCardFromList
	jr nc, .selected

; Player is trying to exit screen,
; but can select up to 2 cards total.
; prompt Player to confirm exiting screen.
	ld a, 2
	call AskWhetherToQuitSelectingCards
	jr c, .loop
	jr .finish

.selected
; a card was selected, so add it to list
	call GetNextPositionInTempList
	ldh a, [hTempCardIndex_ff98]
	ld [hl], a
	call RemoveCardFromDuelTempList
	or a
	jr z, .finish ; no more cards?
	ldh a, [hCurSelectionItem]
	cp 2
	jr c, .loop ; already selected 2 cards?

.finish
; place terminating byte on list
	call GetNextPositionInTempList
	ld [hl], $ff
	or a
	ret

; Draws list of Energy Cards in Discard Pile for Player to select from.
; Output deck index or $ff in hTemp_ffa0 and a.
; Return carry if there are no cards to choose.
HandleSelectBasicEnergyFromDiscardPile_NoCancel:
	push hl
	call CreateEnergyCardListFromDiscardPile_OnlyBasic
	pop hl
	jr nc, .select_card
; return terminating byte
	ld a, $ff
	ldh [hTemp_ffa0], a
	scf
	ret

.select_card
	call DrawWideTextBox_WaitForInput
.loop
	call Helper_ChooseAnEnergyCardFromList
	jr c, .loop

	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	or a
	ret

; Draws list of Energy Cards in Discard Pile for Player to select from.
; input: hHowManyCardsToSelectOneByOne - how many cards still left to choose
; Output deck index or $ff in hTemp_ffa0 and a.
; Return carry if cancelled or if there are no cards to choose.
HandleSelectBasicEnergyFromDiscardPile_AllowCancel:
	push hl
	call CreateEnergyCardListFromDiscardPile_OnlyBasic
	pop hl
	jr nc, .select_card
.not_chosen
; return terminating byte
	ld a, $ff
	ldh [hTemp_ffa0], a
	scf
	ret

.select_card
	call DrawWideTextBox_WaitForInput
.loop
	call Helper_ChooseAnEnergyCardFromList
	jr nc, .selected

; Player is trying to exit screen, prompt to confirm.
	ldh a, [hHowManyCardsToSelectOneByOne]
	call AskWhetherToQuitSelectingCards
	jr c, .loop
	jr .not_chosen

.selected
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	or a
	ret

; Draws Discard Pile screen and textbox, and handles Player input.
; Returns carry if B is pressed to exit the card list screen.
; Otherwise, returns the selected card (deck index) at hTempCardIndex_ff98 and at a.
Helper_ChooseAnEnergyCardFromList:
	bank1call InitAndDrawCardListScreenLayout
	ldtx hl, ChooseAnEnergyCardText
	ldtx de, PlayerDiscardPileText
	bank1call SetCardListHeaderText
	bank1call DisplayCardList
	ret


;
PainAmplifier_DamageEffect:
	call SwapTurn
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld c, a
	xor a  ; PLAY_AREA_ARENA
	ld b, a

.loop
	push bc
	ld e, a
	call GetCardDamageAndMaxHP
	or a
	jr z, .next  ; no damage
	ld a, e  ; PLAY_AREA_*
	ld b, a  ; input location
	ld de, 10  ; input damage
	call DealDamageToPlayAreaPokemon_RegularAnim

.next
	pop bc
	inc b
	ld a, b
	dec c
	jr nz, .loop
	call SwapTurn
	ret

ApplyDestinyBondEffect: ; 2d987 (b:5987)
	ld a, SUBSTATUS1_DESTINY_BOND
	call ApplySubstatus1ToAttackingCard
	ret


EnergyConversion_PlayerSelectEffect:
	ldtx hl, Choose2EnergyCardsFromDiscardPileForHandText
	jp HandleEnergyCardsInDiscardPileSelection


EnergyConversion_AISelectEffect:
	call CreateEnergyCardListFromDiscardPile_OnlyBasic
	; call CreateEnergyCardListFromDiscardPile_AllEnergy
	ld hl, wDuelTempList
	ld de, hTempList
	ld c, 2
; select the first two energy cards found in Discard Pile
.loop
	ld a, [hli]
	cp $ff
	jr z, .done
	ld [de], a
	inc de
	dec c
	jr nz, .loop
.done
	ld a, $ff
	ld [de], a
	ret

EnergyConversion_AddToHandEffect:
; loop cards that were chosen
; until $ff is reached,
; and move them to the hand.
	ld hl, hTempList
	ld de, wDuelTempList
.loop_cards
	ld a, [hli]
	ld [de], a
	inc de
	cp $ff
	jr z, .done
	call MoveDiscardPileCardToHand
	call AddCardToHand
	jr .loop_cards

.done
	call IsPlayerTurn
	ret c
	bank1call DisplayCardListDetails
	ret


; returns carry if neither the Turn Duelist or
; the non-Turn Duelist have any deck cards.
Prophecy_CheckDeck:
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	call GetTurnDuelistVariable
	cp DECK_SIZE
	jr c, .no_carry
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	call GetNonTurnDuelistVariable
	cp DECK_SIZE
	jr c, .no_carry
	ldtx hl, NoCardsLeftInTheDeckText
	scf
	ret
.no_carry
	or a
	ret

Prophecy_PlayerSelectEffect:
	; ldtx hl, ProcedureForProphecyText
	; bank1call DrawWholeScreenTextBox
.select_deck
	bank1call DrawDuelMainScene
	ldtx hl, PleaseSelectTheDeckText
	call TwoItemHorizontalMenu
	ldh a, [hKeysHeld]
	and B_BUTTON
	jr nz, Prophecy_PlayerSelectEffect ; loop back to start

	ldh a, [hCurMenuItem]
	ldh [hAIPkmnPowerEffectParam], a ; store selection
	or a
	jr z, .turn_duelist

; non-turn duelist
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	call GetNonTurnDuelistVariable
	cp DECK_SIZE
	jr nc, .select_deck ; no cards, go back to deck selection
	call SwapTurn
	call HandleProphecyScreen
	call SwapTurn
	ret

.turn_duelist
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	call GetTurnDuelistVariable
	cp DECK_SIZE
	jr nc, .select_deck ; no cards, go back to deck selection
	call HandleProphecyScreen
	ret

Prophecy_ReorderDeckEffect:
	ld hl, hAIPkmnPowerEffectParam
	ld a, [hli]
	or a
	jr z, .ReorderCards ; turn duelist's deck
	cp $ff
	ret z

; non-turn duelist's deck
	call SwapTurn
	call .ReorderCards
	call SwapTurn
	ret

.ReorderCards
	ld c, 0
; add selected cards to hand in the specified order
.loop_add_hand
	ld a, [hli]
	cp $ff
	jr z, .dec_hl
	call SearchCardInDeckAndSetToJustDrawn
	inc c
	jr .loop_add_hand

.dec_hl
; go to last card that was in the list
	dec hl
	dec hl

.loop_return_deck
; return the cards to the top of the deck
	ld a, [hld]
	call ReturnCardToDeck
	dec c
	jr nz, .loop_return_deck
	call IsPlayerTurn
	ret c
; print text in case it was the opponent
	ldtx hl, SortedCardsInDuelistsDeckText
	call DrawWideTextBox_WaitForInput
	ret

; draw and handle Player selection for reordering
; the top 3 cards of Deck.
; the resulting list is output in order in hTempList.
HandleProphecyScreen: ; 2da76 (b:5a76)
	ld b, 3
	call CreateDeckCardListTopNCards
	inc a
	ld [wNumberOfCardsToOrder], a

.start
	call CountCardsInDuelTempList
	ld b, a
	ld a, 1 ; start at 1
	ldh [hCurSelectionItem], a

; initialize buffer ahead in wDuelTempList.
	ld hl, wDuelTempList + 10
	xor a
.loop_init_buffer
	ld [hli], a
	dec b
	jr nz, .loop_init_buffer
	ld [hl], $ff

	bank1call InitAndDrawCardListScreenLayout
	ldtx hl, ChooseTheOrderOfTheCardsText
	ldtx de, DuelistDeckText
	bank1call SetCardListHeaderText
	bank1call Func_5735

.loop_selection
	bank1call DisplayCardList
	jr c, .clear

; first check if this card was already selected
	ldh a, [hCurMenuItem]
	ld e, a
	ld d, $00
	ld hl, wDuelTempList + 10
	add hl, de
	ld a, [hl]
	or a
	jr nz, .loop_selection ; already chosen

; being here means card hasn't been selected yet,
; so add its order number to buffer and increment
; the sort number for the next card.
	ldh a, [hCurSelectionItem]
	ld [hl], a
	inc a
	ldh [hCurSelectionItem], a
	bank1call Func_5744
	ldh a, [hCurSelectionItem]
	ld hl, wNumberOfCardsToOrder
	cp [hl]
	jr c, .loop_selection ; still more cards

; confirm that the ordering has been completed
	call EraseCursor
	ldtx hl, IsThisOKText
	call YesOrNoMenuWithText_LeftAligned
	jr c, .start ; if not, return back to beginning of selection

; write in hTempList the card list
; in order that was selected.
	ld hl, wDuelTempList + 10
	ld de, wDuelTempList
	ld c, 0
.loop_order
	ld a, [hli]
	cp $ff
	jr z, .done
	push hl
	push bc
	ld c, a
	ld b, $00
; start at hAIPkmnPowerEffectParam + 1
	ld hl, hAIPkmnPowerEffectParam
	add hl, bc
	ld a, [de]
	ld [hl], a
	pop bc
	pop hl
	inc de
	inc c
	jr .loop_order
; now hTempRetreatCostCards has the list of card deck indices
; in the order selected to be place on top of the deck.

.done
	ld b, $00
	ld hl, hAIPkmnPowerEffectParam + 1
	add hl, bc
	ld [hl], $ff ; terminating byte
	or a
	ret

.clear
; check if any reordering was done.
	ld hl, hCurSelectionItem
	ld a, [hl]
	cp 1
	jr z, .loop_selection ; none done, go back
; clear the order that was selected thus far.
	dec a
	ld [hl], a
	ld c, a
	ld hl, wDuelTempList + 10
.loop_clear
	ld a, [hli]
	cp c
	jr nz, .loop_clear
	; clear this byte
	dec hl
	ld [hl], $00
	bank1call Func_5744
	jr .loop_selection

Rend_AIEffect:
	call Rend_DamageBoostEffect
	jp SetDefiniteAIDamage

Rend_DamageBoostEffect:
; add 20 damage if the Defending Pokémon has damage counters
	call SwapTurn
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	call SwapTurn
	or a
	ret z
	ld a, 20
	call AddToDamage
	ret


; returns carry if Damage Swap cannot be used.
DamageSwap_CheckDamage: ; 2db8e (b:5b8e)
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	call CheckIfPlayAreaHasAnyDamage
	ret c
	ldh a, [hTempPlayAreaLocation_ff9d]
	jp CheckCannotUseDueToStatus_Anywhere

DamageSwap_SelectAndSwapEffect: ; 2dba2 (b:5ba2)
	ld a, DUELVARS_DUELIST_TYPE
	call GetTurnDuelistVariable
	cp DUELIST_TYPE_PLAYER
	jr z, .player
; non-player
	bank1call Func_61a1
	bank1call PrintPlayAreaCardList_EnableLCD
	ret

.player
	ldtx hl, ProcedureForDamageSwapText
	bank1call DrawWholeScreenTextBox
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

; handle selection of Pokemon to take damage from
.loop_input_first
	call DoFrame
	call HandleMenuInput
	jr nc, .loop_input_first
	cp $ff
	ret z ; quit when B button is pressed

	ldh [hTempPlayAreaLocation_ffa1], a
	ldh [hCurSelectionItem], a

; if card has no damage, play sfx and return to start
	call GetCardDamageAndMaxHP
	or a
	jr z, .no_damage

; take damage away temporarily to draw UI.
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

; draw damage counter in cursor
	ldh a, [hTempPlayAreaLocation_ffa1]
	ld b, SYM_HP_NOK
	call DrawSymbolOnPlayAreaCursor

; handle selection of Pokemon to give damage to
.loop_input_second
	call DoFrame
	call HandleMenuInput
	jr nc, .loop_input_second
	; if B is pressed, return damage counter
	; to card that it was taken from
	cp $ff
	jr z, .update_ui

; try to give the card selected the damage counter
; if it would KO, ignore it.
	ldh [hPlayAreaEffectTarget], a
	ldh [hCurSelectionItem], a
	call TryGiveDamageCounter_DamageSwap
	jr c, .loop_input_second

	ld a, OPPACTION_6B15
	call SetOppAction_SerialSendDuelData

.update_ui
	ldh a, [hTempPlayAreaLocation_ffa1]
	ld b, SYM_SPACE
	call DrawSymbolOnPlayAreaCursor
	call EraseCursor
	jr .start

.no_damage
	call PlaySFX_InvalidChoice
	jr .loop_input_first

; tries to give damage counter to hPlayAreaEffectTarget,
; and if successful updates UI screen.
DamageSwap_SwapEffect: ; 2dc27 (b:5c27)
	call TryGiveDamageCounter_DamageSwap
	ret c
	bank1call PrintPlayAreaCardList_EnableLCD
	or a
	ret

; tries to give the damage counter to the target
; chosen by the Player (hPlayAreaEffectTarget).
; if the damage counter would KO card, then do
; not give the damage counter and return carry.
TryGiveDamageCounter_DamageSwap: ; 2dc30 (b:5c30)
	ldh a, [hPlayAreaEffectTarget]
	add DUELVARS_ARENA_CARD_HP
	call GetTurnDuelistVariable
	sub 10
	jr z, .set_carry ; would bring HP to zero?
; has enough HP to receive a damage counter
	ld [hl], a
	ldh a, [hTempPlayAreaLocation_ffa1]
	add DUELVARS_ARENA_CARD_HP
	ld l, a
	ld a, 10
	add [hl]
	ld [hl], a
	or a
	ret
.set_carry
	scf
	ret

PsywaveEffect: ; 2dc49 (b:5c49)
	call GetEnergyAttachedMultiplierDamage
	ld hl, wDamage
	ld [hl], e
	inc hl
	ld [hl], d
	ret

; returns carry if neither Duelist has evolved Pokemon.
DevolutionBeam_CheckPlayArea: ; 2dc53 (b:5c53)
	call CheckIfTurnDuelistHasEvolvedCards
	ret nc
	call SwapTurn
	call CheckIfTurnDuelistHasEvolvedCards
	call SwapTurn
	ldtx hl, ThereAreNoStage1PokemonText
	ret

; returns carry of Player cancelled selection.
; otherwise, output in hTemp_ffa0 which Play Area
; was selected ($0 = own Play Area, $1 = opp. Play Area)
; and in hTempPlayAreaLocation_ffa1 selected card.
DevolutionBeam_PlayerSelectEffect: ; 2dc64 (b:5c64)
	ldtx hl, ProcedureForDevolutionBeamText
	bank1call DrawWholeScreenTextBox

.start
	bank1call DrawDuelMainScene
	ldtx hl, PleaseSelectThePlayAreaText
	call TwoItemHorizontalMenu
	ldh a, [hKeysHeld]
	and B_BUTTON
	jr nz, .set_carry

; a Play Area was selected
	ldh a, [hCurMenuItem]
	or a
	jr nz, .opp_chosen

; player chosen
	call HandleEvolvedCardSelection
	jr c, .start

	xor a
.store_selection
	ld hl, hTemp_ffa0
	ld [hli], a ; store which Duelist Play Area selected
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld [hl], a ; store which card selected
	or a
	ret

.opp_chosen
	call SwapTurn
	call HandleEvolvedCardSelection
	call SwapTurn
	jr c, .start
	ld a, $01
	jr .store_selection

.set_carry
	scf
	ret

DevolutionBeam_AISelectEffect: ; 2dc9e (b:5c9e)
	ld a, $01
	ldh [hTemp_ffa0], a
	call SwapTurn
	call FindFirstNonBasicCardInPlayArea
	call SwapTurn
	jr c, .found
	xor a
	ldh [hTemp_ffa0], a
	call FindFirstNonBasicCardInPlayArea
.found
	ldh [hTempPlayAreaLocation_ffa1], a
	ret

DevolutionBeam_LoadAnimation: ; 2dcb6 (b:5cb6)
	xor a ; ATK_ANIM_NONE
	ld [wLoadedAttackAnimation], a
	ret

DevolveDefendingPokemonEffect:
	ld a, 1  ; opponent's Play Area
	ldh [hTemp_ffa0], a
	xor a  ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ffa1], a

	call SwapTurn
	call HandleNoDamageOrEffect
	jp c, SwapTurn  ; exit

	ld b, PLAY_AREA_ARENA
	ld c, $00
	ldh a, [hWhoseTurn]
	ld h, a
	call DevolutionBeam_DevolveEffect.DevolvePokemonSkipAnimation
	jp SwapTurn


DevolutionBeam_DevolveEffect: ; 2dcbb (b:5cbb)
	ldh a, [hTemp_ffa0]
	or a
	jr z, .DevolvePokemon
	cp $ff
	ret z

; opponent's Play Area
	call SwapTurn
	ldh a, [hTempPlayAreaLocation_ffa1]
	or a
	jr nz, .skip_handle_no_damage_effect
	call HandleNoDamageOrEffect
	jr c, .unaffected
.skip_handle_no_damage_effect
	call .DevolvePokemon
.unaffected
	jp SwapTurn

.DevolvePokemon
	ld a, ATK_ANIM_DEVOLUTION_BEAM
	ld [wLoadedAttackAnimation], a
	ldh a, [hTempPlayAreaLocation_ffa1]
	ld b, a
	ld c, $00
	ldh a, [hWhoseTurn]
	ld h, a
	bank1call PlayAttackAnimation
	bank1call WaitAttackAnimation

.DevolvePokemonSkipAnimation
; load selected card's data
	ldh a, [hTempPlayAreaLocation_ffa1]
	ldh [hTempPlayAreaLocation_ff9d], a
	ld [wTempPlayAreaLocation_cceb], a
	add DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer1_FromDeckIndex

; check if card is affected
	ld a, [wLoadedCard1ID]
	ld [wTempNonTurnDuelistCardID], a
	ld de, $0
	ldh a, [hTempPlayAreaLocation_ff9d]
	or a
	jr nz, .skip_substatus_check
	call HandleNoDamageOrEffectSubstatus
	jr c, .check_no_damage_effect
.skip_substatus_check
	call HandleDamageReductionOrNoDamageFromPkmnPowerEffects
.check_no_damage_effect
	call CheckNoDamageOrEffect
	jr nc, .devolve
	jp DrawWideTextBox_WaitForInput

.devolve
	ldh a, [hTempPlayAreaLocation_ffa1]
	ldh [hTempPlayAreaLocation_ff9d], a
	add DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	bank1call GetCardOneStageBelow
	call PrintDevolvedCardNameAndLevelText

	ld a, d
	call UpdateDevolvedCardHPAndStage
	call ResetDevolvedCardStatus

; add the evolved card to the hand
	ld a, e
	call AddCardToHand

; check if this devolution KO's card
	ldh a, [hTempPlayAreaLocation_ffa1]
	call PrintPlayAreaCardKnockedOutIfNoHP

	xor a
	ld [wDuelDisplayedScreen], a
	ret

; returns carry if Turn Duelist
; has no Stage1 or Stage2 cards in Play Area.
CheckIfTurnDuelistHasEvolvedCards: ; 2dd3b (b:5d3b)
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	ld d, h
	ld e, DUELVARS_ARENA_CARD_STAGE
.loop
	ld a, [hli]
	cp $ff
	jr z, .set_carry
	ld a, [de]
	inc de
	or a
	jr z, .loop ; is Basic Stage
	ret
.set_carry
	scf
	ret

; handles Player selection of an evolved card in Play Area.
; returns carry if Player cancelled operation.
HandleEvolvedCardSelection: ; 2dd50 (b:5d50)
	bank1call HasAlivePokemonInPlayArea
.loop
	bank1call OpenPlayAreaScreenForSelection
	ret c
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD_STAGE
	call GetTurnDuelistVariable
	or a
	jr z, .loop ; if Basic, loop
	ret

; finds first occurrence in Play Area
; of Stage 1 or 2 card, and outputs its
; Play Area location in a, with carry set.
; if none found, don't return carry set.
FindFirstNonBasicCardInPlayArea: ; 2dd62 (b:5d62)
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld c, a

	ld b, PLAY_AREA_ARENA
	ld l, DUELVARS_ARENA_CARD_STAGE
.loop
	ld a, [hli]
	or a
	jr nz, .not_basic
	inc b
	dec c
	jr nz, .loop
	or a
	ret
.not_basic
	ld a, b
	scf
	ret


Barrier_BarrierEffect:
	ld a, SUBSTATUS1_BARRIER
	call ApplySubstatus1ToAttackingCard
	ret


QueenPressEffect:
	ld a, SUBSTATUS1_NO_DAMAGE_FROM_BASIC
	jp ApplySubstatus1ToAttackingCard


EnergySpores_PlayerSelectEffect:
EnergyAbsorption_PlayerSelectEffect:
	ldtx hl, Choose2EnergyCardsFromDiscardPileToAttachText
	jp HandleEnergyCardsInDiscardPileSelection


GatherToxins_PlayerSelectEffect:
	call RetrieveBasicEnergyFromDiscardPile_PlayerSelectEffect
	ld a, $ff
	ldh [hTempList + 1], a  ; terminating byte
	ret


RetrieveBasicEnergyFromDiscardPile_PlayerSelectEffect:
	ldtx hl, Choose1BasicEnergyCardFromDiscardPileText
	call DrawWideTextBox_WaitForInput
	call HandlePlayerSelectionBasicEnergyFromDiscardPile_AllowCancel
	ldh [hTemp_ffa0], a
	or a  ; ignore carry
	ret

RetrieveBasicEnergyFromDiscardPile_AISelectEffect:
; AI picks the first energy card
	call CreateEnergyCardListFromDiscardPile_OnlyBasic
	ld a, [wDuelTempList]
	ldh [hTemp_ffa0], a
	or a  ; ignore carry
	ret


EnergySpores_AISelectEffect:
EnergyAbsorption_AISelectEffect:
; AI picks first 2 energy cards
	call CreateEnergyCardListFromDiscardPile_OnlyBasic
	; call CreateEnergyCardListFromDiscardPile_AllEnergy
	ld a, 2
	jr PickFirstNCardsFromList_SelectEffect


Retrieve1WaterEnergyFromDiscard_SelectEffect:
; pick the first energy card
	call CreateEnergyCardListFromDiscardPile_OnlyWater
	ld a, 1
	jr PickFirstNCardsFromList_SelectEffect


Attach1FireEnergyFromDiscard_SelectEffect:
; pick the first energy card
	call CreateEnergyCardListFromDiscardPile_OnlyFire
	ld a, 1
	; jr PickFirstNCardsFromList_SelectEffect
	; fallthrough


; input:
;   a: number of cards to pick from wDuelTempList
PickFirstNCardsFromList_SelectEffect:
	ld hl, wDuelTempList
	ld de, hTempList
	ld c, a
.loop
	ld a, [hli]
	cp $ff
	jr z, .done
	ld [de], a
	inc de
	dec c
	jr nz, .loop
.done
	ld a, $ff ; terminating byte
	ld [de], a
	ret


CollectFire_AttachToPokemonEffect:
EnergyAbsorption_AttachToPokemonEffect:
GatherToxins_AttachToPokemonEffect:
	ld e, CARD_LOCATION_ARENA
	jp SetCardLocationsFromDiscardPileToPlayArea

AttachEnergyFromDiscard_AttachToPokemonEffect:
	call IsPlayerTurn
	jr c, .player_turn

; AI energy attachment selection
; special attack handling already picks a suitable Pokémon
	ldh a, [hTempPlayAreaLocation_ff9d]
	or CARD_LOCATION_PLAY_AREA
	ld e, a
	call SetCardLocationsFromDiscardPileToPlayArea
; show detail screen and which Pokemon was chosen to attach Energy
	jp Helper_GenericShowAttachedEnergyToPokemon

.player_turn
	ld hl, hTempList
.loop
	ld a, [hl]
	cp $ff
	ret z
	push hl
	ldtx hl, ChoosePokemonToAttachEnergyCardText
	bank1call DisplayCardDetailScreen
; select target Pokémon in play area
	call Helper_ChooseAPokemonInPlayArea
	; ldh a, [hTempPlayAreaLocation_ff9d]
; attach card(s) to the selected Pokemon
	or CARD_LOCATION_PLAY_AREA
	ld e, a
	pop hl
	ld a, [hli]
	call Helper_AttachCardFromDiscardPile
	jr .loop
	or a
	ret

; input:
;   e: CARD_LOCATION_* constant
SetCardLocationsFromDiscardPileToPlayArea:
	ld hl, hTempList
.loop
	ld a, [hli]
	cp $ff
	ret z
	call Helper_AttachCardFromDiscardPile
	jr .loop

; input:
;   a: deck index of discarded card to attach
;   e: CARD_LOCATION_* constant
Helper_AttachCardFromDiscardPile:
	push hl
	call MoveDiscardPileCardToHand
	call GetTurnDuelistVariable
	ld a, e
	ld [hl], a
	pop hl
	ret


; sets carry if no Trainer cards in the Discard Pile.
Scavenge_CheckDiscardPile:
	jp CreateItemCardListFromDiscardPile

Scavenge_AISelectEffect:
; AI picks first Trainer card in list
	call CreateItemCardListFromDiscardPile
	ld a, [wDuelTempList]
	ldh [hTempPlayAreaLocation_ffa1], a
	ret

; Fishing Tail uses hTemp_ffa0 for storage
FishingTail_AddToHandEffect:
	ldh a, [hTemp_ffa0]
	cp $ff
	ret z
	ldh [hTempPlayAreaLocation_ffa1], a
	; fallthrough

Scavenge_AddToHandEffect:
	ldh a, [hTempPlayAreaLocation_ffa1]
	call MoveDiscardPileCardToHand
	call AddCardToHand
	call IsPlayerTurn
	ret c
	ldh a, [hTempPlayAreaLocation_ffa1]
	ldtx hl, WasPlacedInTheHandText
	bank1call DisplayCardDetailScreen
	ret

; returns carry if Arena card has no Energies attached
; or if it doesn't have any damage counters.
Recover_CheckEnergyHP:
	call CheckArenaPokemonHasAnyDamage
	ret c ; return carry if no damage
	jp CheckArenaPokemonHasAnyEnergiesAttached

; ------------------------------------------------------------------------------
; Energy Discard
; ------------------------------------------------------------------------------

DiscardEnergy_PlayerSelectEffect:
	xor a ; PLAY_AREA_ARENA
	call CreateArenaOrBenchEnergyCardList
.got_energy_list
	xor a ; PLAY_AREA_ARENA
	bank1call DisplayEnergyDiscardScreen
	bank1call HandleEnergyDiscardMenuInput
	ret c ; exit if B was pressed
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a ; store card chosen
	ret

DiscardEnergy_AISelectEffect:
	xor a ; PLAY_AREA_ARENA
	call CreateArenaOrBenchEnergyCardList
	ld a, [wDuelTempList] ; pick first card
	ldh [hTemp_ffa0], a
	ret


OptionalDiscardEnergy_PlayerSelectEffect:
	ld a, $ff
	ldh [hTemp_ffa0], a
	xor a ; PLAY_AREA_ARENA
	call CreateArenaOrBenchEnergyCardList
	call nc, DiscardEnergy_PlayerSelectEffect.got_energy_list
; ignore carry if set, otherwise the deck index is in [hTemp_ffa0]
	or a
	ret


BounceEnergy_BounceEffect:
	ldh a, [hTemp_ffa0]
	cp $ff
	ret z
	call PutCardInDiscardPile
	call MoveDiscardPileCardToHand
	call AddCardToHand
	ld d, a
	call IsPlayerTurn  ; preserves bc, de
	ld a, d
	ret c
	ldtx hl, WasPlacedInTheHandText
	bank1call DisplayCardDetailScreen
	ret


DiscardEnergy_DiscardEffect:
	ldh a, [hTemp_ffa0]
	cp $ff
	ret z
	jp PutCardInDiscardPile


Discard2Energies_PlayerSelectEffect:
	ldtx hl, ChooseAndDiscard2EnergyCardsText
	call DrawWideTextBox_WaitForInput

	xor a
	ldh [hCurSelectionItem], a
	; xor a ; PLAY_AREA_ARENA
	call CreateArenaOrBenchEnergyCardList
	call SortCardsInDuelTempListByID
	xor a ; PLAY_AREA_ARENA
	bank1call DisplayEnergyDiscardScreen

	ld a, 2
	ld [wEnergyDiscardMenuDenominator], a
.loop_input
	bank1call HandleEnergyDiscardMenuInput
	ret c
	call GetNextPositionInTempList
	ldh a, [hTempCardIndex_ff98]
	ld [hl], a
	ld hl, wEnergyDiscardMenuNumerator
	inc [hl]
	ldh a, [hCurSelectionItem]
	cp 2
	jr nc, .done
	ldh a, [hTempCardIndex_ff98]
	call RemoveCardFromDuelTempList
	bank1call DisplayEnergyDiscardMenu
	jr .loop_input
.done
; return when 2 have been chosen
	or a
	ret

; select the first two Energies
; TODO avoid Energies of the same type as the user
Discard2Energies_AISelectEffect:
	xor a ; PLAY_AREA_ARENA
	call CreateArenaOrBenchEnergyCardList
	ld hl, wDuelTempList
	ld a, [hli]
	ldh [hTempList], a
	ld a, [hl]
	ldh [hTempList + 1], a
	ret

Discard2Energies_DiscardEffect:
	ld hl, hTempList
	ld a, [hli]
	call PutCardInDiscardPile
	ld a, [hli]
	jp PutCardInDiscardPile


; ------------------------------------------------------------------------------
; Energy Discard (Opponent)
; ------------------------------------------------------------------------------

; handles screen for selecting an Energy card to discard
; that is attached to Defending Pokemon,
; and store the Player selection in [hTemp_ffa0].
DiscardOpponentEnergy_PlayerSelectEffect:
	call SwapTurn
	xor a ; PLAY_AREA_ARENA
	call CreateArenaOrBenchEnergyCardList
	jr c, .no_energy
	ldtx hl, ChooseDiscardEnergyCardFromOpponentText
	call DrawWideTextBox_WaitForInput
	xor a ; PLAY_AREA_ARENA
	bank1call DisplayEnergyDiscardScreen

.loop_input
	bank1call HandleEnergyDiscardMenuInput
	jr c, .loop_input

	call SwapTurn
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a ; store selected card to discard
	ret

.no_energy
	call SwapTurn
	ld a, $ff
	ldh [hTemp_ffa0], a
	ret

DiscardOpponentEnergy_AISelectEffect:
	call AIPickEnergyCardToDiscardFromDefendingPokemon
	ldh [hTemp_ffa0], a
	ret

DiscardOpponentEnergy_DiscardEffect:
	call HandleNoDamageOrEffect
	ret c ; return if attack had no effect

	; check if energy card was chosen to discard
	ldh a, [hTemp_ffa0]
	cp $ff
	ret z ; return if none selected

	; discard Defending card's energy
	call SwapTurn
	call PutCardInDiscardPile
	ld a, DUELVARS_ARENA_CARD_LAST_TURN_EFFECT
	call GetTurnDuelistVariable
	ld [hl], LAST_TURN_EFFECT_DISCARD_ENERGY
	call SwapTurn
	ret

DiscardOpponentEnergyIfHeads_50PercentEffect:
	ldtx de, IfHeadsDiscard1EnergyFromTargetText
	call TossCoin_BankB
	ldh [hTemp_ffa0], a
	or a  ; reset carry, otherwise heads cancels the attack
	ret

DiscardOpponentEnergyIfHeads_PlayerSelectEffect:
; check the result of the previous coin flip
	ldh a, [hTemp_ffa0]
	or a
	jr nz, DiscardOpponentEnergy_PlayerSelectEffect
; no energy chosen if tails
	ld a, $ff
	ldh [hTemp_ffa0], a
	ret

DiscardOpponentEnergyIfHeads_AISelectEffect:
; check the result of the previous coin flip
	ldh a, [hTemp_ffa0]
	or a
	jr nz, DiscardOpponentEnergy_AISelectEffect
; no energy chosen if tails
	ld a, $ff
	ldh [hTemp_ffa0], a
	ret

; ------------------------------------------------------------------------------


TantrumEffect: ; 2e099 (b:6099)
	ldtx de, IfTailsYourPokemonBecomesConfusedText
	call TossCoin_BankB
	ret c ; return if heads
; confuse Pokemon
	ld a, ATK_ANIM_MULTIPLE_SLASH
	ld [wLoadedAttackAnimation], a
	call SwapTurn
	call ConfusionEffect
	jp SwapTurn


AbsorbEffect: ; 2e0b3 (b:60b3)
	ld hl, wDealtDamage
	ld a, [hli]
	ld h, [hl]
	ld l, a
	srl h
	rr l
	bit 0, l
	jr z, .rounded
	; round up to nearest 10
	ld de, 5
	add hl, de
.rounded
	ld e, l
	ld d, h
	jp ApplyAndAnimateHPRecovery


; returns carry if can't add Pokemon from deck
CallForFriend_CheckDeckAndPlayArea: ; 2e100 (b:6100)
	call CheckDeckIsNotEmpty
	ret c ; no cards in deck
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ldtx hl, NoSpaceOnTheBenchText
	cp MAX_PLAY_AREA_POKEMON
	ccf
	ret

CallForFriend_PlayerSelectEffect: ; 2e110 (b:6110)
	ld a, $ff
	ldh [hTemp_ffa0], a

	call CreateDeckCardList
	ldtx hl, ChooseBasicPokemonFromDeckText
	ldtx bc, BasicPokemonDeckText
	lb de, SEARCHEFFECT_BASIC_POKEMON, $00
	call LookForCardsInDeck
	ret c

; draw Deck list interface and print text
	bank1call InitAndDrawCardListScreenLayout_MenuTypeSelectCheck
	ldtx hl, ChooseBasicPokemonText
	ldtx de, DuelistDeckText
	bank1call SetCardListHeaderText

.loop
	bank1call DisplayCardList
	jr c, .pressed_b

	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_PKMN + 1
	jr nc, .play_sfx  ; is it a Pokemon?
	ld a, [wLoadedCard2Stage]
	or a
	jr nz, .play_sfx ; is it Basic?
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	or a
	ret

.play_sfx
	; play SFX and loop back
	call PlaySFX_InvalidChoice
	jr .loop

.pressed_b
; figure if Player can exit the screen without selecting,
; that is, if the Deck has no Basic Pokemon.
	ld a, DUELVARS_CARD_LOCATIONS
	call GetTurnDuelistVariable
.loop_b_press
	ld a, [hl]
	cp CARD_LOCATION_DECK
	jr nz, .next
	ld a, l
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_PKMN + 1
	jr nc, .next ; go to the next card
	ld a, [wLoadedCard2Stage]
	or a
	jr z, .play_sfx ; found, go back to top loop
.next
	inc l
	ld a, l
	cp DECK_SIZE
	jr c, .loop_b_press

; no valid card in Deck, can safely exit screen
	ld a, $ff
	ldh [hTemp_ffa0], a
	or a
	ret

CallForFriend_AISelectEffect: ; 2e177 (b:6177)
	call CreateDeckCardList
	ld hl, wDuelTempList
.loop_deck
	ld a, [hli]
	ldh [hTemp_ffa0], a
	cp $ff
	ret z ; none found
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_PKMN + 1
	jr nc, .loop_deck
	ld a, [wLoadedCard2Stage]
	or a
	jr nz, .loop_deck
; found
	ret

CallForFriend_PutInPlayAreaEffect: ; 2e194 (b:6194)
	ldh a, [hTemp_ffa0]
	cp $ff
	jp z, SyncShuffleDeck
	call SearchCardInDeckAndSetToJustDrawn
	call AddCardToHand
	call PutHandPokemonCardInPlayArea
	call IsPlayerTurn
	jp c, SyncShuffleDeck
	; display card on screen
	ldh a, [hTemp_ffa0]
	ldtx hl, PlacedOnTheBenchText
	bank1call DisplayCardDetailScreen
	jp SyncShuffleDeck

; ------------------------------------------------------------------------------

HardenEffect: ; 2e1f6 (b:61f6)
	ld a, SUBSTATUS1_HARDEN
	jp ApplySubstatus1ToAttackingCard

Ram_SelectSwitchEffect: ; 2e1fc (b:61fc)
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	cp 2
	jr c, .no_bench
	call DuelistSelectForcedSwitch
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	ret
.no_bench
	ld a, $ff
	ldh [hTemp_ffa0], a
	ret

Ram_RecoilSwitchEffect: ; 2e212 (b:6212)
	ld a, 20
	call DealRecoilDamageToSelf
	ldh a, [hTemp_ffa0]
	call HandleSwitchDefendingPokemonEffect
	ret


; return carry if opponent has no Bench Pokemon.
StretchKick_CheckBench:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	ldtx hl, EffectNoPokemonOnTheBenchText
	cp 2
	ret

AssassinFlight_PlayerSelectEffect:
StretchKick_PlayerSelectEffect:
	ldtx hl, ChoosePkmnInTheBenchToGiveDamageText
	call DrawWideTextBox_WaitForInput
	call SwapTurn
	bank1call HasAlivePokemonInBench
.loop_input
	bank1call OpenPlayAreaScreenForSelection
	jr c, .loop_input
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	jp SwapTurn

AssassinFlight_AISelectEffect:
StretchKick_AISelectEffect:
; chooses Bench Pokemon with least amount of remaining HP
	call GetOpponentBenchPokemonWithLowestHP
	ldh [hTemp_ffa0], a
	ret

StretchKick_BenchDamageEffect:
	call SwapTurn
	ldh a, [hTemp_ffa0]
	ld b, a
	ld de, 20
	call DealDamageToPlayAreaPokemon_RegularAnim
	jp SwapTurn

AssassinFlight_BenchDamageEffect:
	call SwapTurn
	ldh a, [hTemp_ffa0]
	ld b, a
	ld de, 40
	call DealDamageToPlayAreaPokemon_RegularAnim
	jp SwapTurn


Thunderpunch_AIEffect: ; 2e399 (b:6399)
	ld a, (30 + 40) / 2
	lb de, 30, 40
	jp SetExpectedAIDamage

Thunderpunch_ModifierEffect: ; 2e3a1 (b:63a1)
	ldtx de, IfHeadPlus10IfTails10ToYourselfText
	call TossCoin_BankB
	ldh [hTemp_ffa0], a
	ret nc ; return if got tails
	ld a, 10
	call AddToDamage
	ret

LightScreenEffect:
	ld a, SUBSTATUS1_HALVE_DAMAGE
	jp ApplySubstatus1ToAttackingCard


ElectabuzzQuickAttack_AIEffect: ; 2e3c0 (b:63c0)
	ld a, (10 + 30) / 2
	lb de, 10, 30
	jp SetExpectedAIDamage

ElectabuzzQuickAttack_DamageBoostEffect: ; 2e3c8 (b:63c8)
	ld hl, 20
	call LoadTxRam3
	ldtx de, DamageCheckIfHeadsPlusDamageText
	call TossCoin_BankB
	ret nc ; return if tails
	ld a, 20
	call AddToDamage
	ret

Selfdestruct40Bench10Effect:
	ld a, 40
	jr Selfdestruct50Bench10Effect.recoil

Selfdestruct50Bench10Effect:
	ld a, 50
.recoil
	call DealRecoilDamageToSelf
	; fallthrough

; deal 10 damage to all benched Pokémon
Earthquake10Effect:
	ld a, $01
	ld [wIsDamageToSelf], a
	ld a, 10
	call DealDamageToAllBenchedPokemon
	; fallthrough

; deal 10 damage to each of the opponent's benched Pokémon
DamageAllOpponentBenched10Effect:
	call SwapTurn
	xor a
	ld [wIsDamageToSelf], a
	ld a, 10
	call DealDamageToAllBenchedPokemon
	jp SwapTurn

; deal 20 damage to each of the opponent's benched Basic Pokémon
DamageAllOpponentBenchedBasic20Effect:
	call SwapTurn
	xor a
	ld [wIsDamageToSelf], a
	ld a, 20
	call DealDamageToAllBenchedBasicPokemon
	jp SwapTurn


Selfdestruct80Bench20Effect: ; 2e739 (b:6739)
	ld a, 80
	jr Selfdestruct100Bench20Effect.recoil

Selfdestruct100Bench20Effect: ; 2e75f (b:675f)
	ld a, 100
.recoil
	call DealRecoilDamageToSelf

; own bench
	ld a, $01
	ld [wIsDamageToSelf], a
	ld a, 20
	call DealDamageToAllBenchedPokemon

; opponent's bench
	call SwapTurn
	xor a
	ld [wIsDamageToSelf], a
	ld a, 20
	call DealDamageToAllBenchedPokemon
	call SwapTurn
	ret

DiscardAllAttachedEnergiesEffect:
	xor a
	call CreateArenaOrBenchEnergyCardList
	ld hl, wDuelTempList
; put all energy cards in Discard Pile
.loop
	ld a, [hli]
	cp $ff
	ret z
	call PutCardInDiscardPile
	jr .loop

ThunderstormEffect: ; 2e429 (b:6429)
	ld a, 1
	ldh [hCurSelectionItem], a

	call SwapTurn
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld c, a
	ld b, 0
	ld e, b
	jr .next_pkmn

.check_damage
	push de
	push bc
	call .DisplayText
	ld de, $0
	call SwapTurn
	call TossCoin_BankB
	call SwapTurn
	push af
	call GetNextPositionInTempList
	pop af
	ld [hl], a ; store result in list
	pop bc
	pop de
	jr c, .next_pkmn
	inc b ; increase number of tails

.next_pkmn
	inc e
	dec c
	jr nz, .check_damage

; all coins were tossed for each Benched Pokemon
	call GetNextPositionInTempList
	ld [hl], $ff
	ld a, b
	ldh [hTemp_ffa0], a
	call Func_3b21
	call SwapTurn

; tally recoil damage
	ldh a, [hTemp_ffa0]
	or a
	jr z, .skip_recoil
	; deal number of tails times 10 to self
	call ATimes10
	call DealRecoilDamageToSelf
.skip_recoil

; deal damage for Bench Pokemon that got heads
	call SwapTurn
	ld hl, hTempPlayAreaLocation_ffa1
	ld b, PLAY_AREA_BENCH_1
.loop_bench
	ld a, [hli]
	cp $ff
	jr z, .done
	or a
	jr z, .skip_damage ; skip if tails
	ld de, 20
	call DealDamageToPlayAreaPokemon_RegularAnim
.skip_damage
	inc b
	jr .loop_bench

.done
	call SwapTurn
	ret

; displays text for current Bench Pokemon,
; printing its Bench number and name.
.DisplayText ; 2e491 (b:6491)
	ld b, e
	ldtx hl, BenchText
	ld de, wDefaultText
	call CopyText
	ld a, $30 ; 0 FW character
	add b
	ld [de], a
	inc de
	ld a, $20 ; space FW character
	ld [de], a
	inc de

	ld a, DUELVARS_ARENA_CARD
	add b
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer2_FromDeckIndex
	ld hl, wLoadedCard2Name
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call CopyText

	xor a
	ld [wDuelDisplayedScreen], a
	ret

JolteonQuickAttack_AIEffect: ; 2e4bb (b:64bb)
	ld a, (10 + 30) / 2
	lb de, 10, 30
	jp SetExpectedAIDamage

JolteonQuickAttack_DamageBoostEffect: ; 2e4c3 (b:64c3)
	ld hl, 20
	call LoadTxRam3
	ldtx de, DamageCheckIfHeadsPlusDamageText
	call TossCoin_BankB
	ret nc ; return if tails
	ld a, 20
	call AddToDamage
	ret

TripleAttackX20X10_AIEffect: ; 2e4d6 (b:64d6)
	ld a, (15 * 3)
	lb de, 30, 60
	jp SetExpectedAIDamage

TripleAttackX20X10_MultiplierEffect: ; 2e4de (b:64de)
	ld hl, 20
	call LoadTxRam3
	ldtx de, DamageCheckIfHeadsXDamageText
	ld a, 3
	call TossCoinATimes_BankB
	; tails = 10, heads = 20
	; result = (tails + 2 * heads) = coins + heads
	add 3
	call ATimes10
	call SetDefiniteDamage
	ret

Fly_AIEffect: ; 2e4f4 (b:64f4)
	ld a, 30 / 2
	lb de, 0, 30
	jp SetExpectedAIDamage

Fly_Success50PercentEffect: ; 2e4fc (b:64fc)
	ldtx de, SuccessCheckIfHeadsAttackIsSuccessfulText
	call TossCoin_BankB
	jr c, .heads
	xor a ; ATK_ANIM_NONE
	ld [wLoadedAttackAnimation], a
	call SetDefiniteDamage
	call SetWasUnsuccessful
	ret
.heads
	ld a, ATK_ANIM_AGILITY_PROTECT
	ld [wLoadedAttackAnimation], a
	ld a, SUBSTATUS1_FLY
	call ApplySubstatus1ToAttackingCard
	ret


ChainLightningEffect: ; 2e595 (b:6595)
	ld a, 10
	call SetDefiniteDamage
	call SwapTurn
	call GetArenaCardColor
	call SwapTurn
	ldh [hCurSelectionItem], a
	cp COLORLESS
	ret z ; don't damage if colorless

; opponent's Bench
	call SwapTurn
	call .DamageSameColorBench
	call SwapTurn

; own Bench
	ld a, $01
	ld [wIsDamageToSelf], a
	; fallthrough

.DamageSameColorBench
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld e, a
	ld d, PLAY_AREA_ARENA
	jr .next_bench

.check_damage
	ld a, d
	call GetPlayAreaCardColor
	ld c, a
	ldh a, [hCurSelectionItem]
	cp c
	jr nz, .next_bench ; skip if not same color
; apply damage to this Bench card
	push de
	ld b, d
	ld de, 10
	call DealDamageToPlayAreaPokemon_RegularAnim
	pop de

.next_bench
	inc d
	dec e
	jr nz, .check_damage
	ret


ZapdosThunder_Recoil50PercentEffect: ; 2e3fa (b:63fa)
RaichuThunder_Recoil50PercentEffect: ; 2e5ee (b:65ee)
	ld hl, 30
	call LoadTxRam3
	ldtx de, IfTailsDamageToYourselfTooText
	call TossCoin_BankB
	ldh [hTemp_ffa0], a
	ret

ZapdosThunder_RecoilEffect: ; 2e409 (b:6409)
RaichuThunder_RecoilEffect: ; 2e5fd (b:65fd)
	ld hl, 30
	call LoadTxRam3
	ldh a, [hTemp_ffa0]
	or a
	ret nz ; return if got heads
	ld a, 30
	call DealRecoilDamageToSelf
	ret


SelectUpTo2Benched_PlayerSelectEffect:
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
	ldtx hl, ChooseUpTo2PkmnOnBenchToGiveDamageText
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
	ld b, SYM_HP_NOK
	call DrawSymbolOnPlayAreaCursor
; store it in the list of chosen Bench Pokemon
	call GetNextPositionInTempList
	ldh a, [hCurMenuItem]
	inc a
	ld [hl], a

; check if 2 were chosen already
	ldh a, [hCurSelectionItem]
	ld c, a
	cp 2
	jr nc, .chosen ; check if already chose 2

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

SelectUpTo2Benched_AISelectEffect: ; 2e6c3 (b:66c3)
; if Bench has 2 Pokemon or less, no need for selection,
; since AI will choose them all.
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	cp 3 + 1  ; 3 benched + arena
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
; has more than 2 Bench cards, proceed to sort them
; by lowest remaining HP to highest, and pick first 2.
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

SelectUpTo2Benched_BenchDamageEffect: ; 2e71f (b:671f)
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

Sonicboom_UnaffectedByColorEffect: ; 2e758 (b:6758)
	ld hl, wDamage + 1
	set UNAFFECTED_BY_WEAKNESS_RESISTANCE_F, [hl]
	ret

PealOfThunder_RandomlyDamageEffect: ; 2e780 (b:6780)
	call ExchangeRNG
	ld de, 30 ; damage to inflict
	call RandomlyDamagePlayAreaPokemon
	bank1call Func_6e49
	ret

; randomly damages a Pokemon in play, except
; card that is in [hTempPlayAreaLocation_ff9d].
; plays thunder animation when Play Area is shown.
; input:
;	de = amount of damage to deal
RandomlyDamagePlayAreaPokemon: ; 2e78d (b:678d)
	xor a
	ld [wNoDamageOrEffect], a

; choose randomly which Play Area to attack
	call UpdateRNGSources
	and 1
	jr nz, .opp_play_area

; own Play Area
	ld a, $01
	ld [wIsDamageToSelf], a
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	call Random
	ld b, a
	; can't select Zapdos
	ldh a, [hTempPlayAreaLocation_ff9d]
	cp b
	jr z, RandomlyDamagePlayAreaPokemon ; re-roll Pokemon to attack

.damage
	ld a, ATK_ANIM_THUNDER_PLAY_AREA
	ld [wLoadedAttackAnimation], a
	call DealDamageToPlayAreaPokemon
	ret

.opp_play_area
	xor a
	ld [wIsDamageToSelf], a
	call SwapTurn
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	call Random
	ld b, a
	call .damage
	call SwapTurn
	ret

BigThunderEffect: ; 2e7cb (b:67cb)
	call ExchangeRNG
	ld de, 70 ; damage to inflict
	call RandomlyDamagePlayAreaPokemon
	ret


NutritionSupport_PlayerSelectEffect:
EnergySpike_PlayerSelectEffect:
	ld a, $ff
	ldh [hTemp_ffa0], a

; search cards in Deck
	call CreateDeckCardList
	ldtx hl, Choose1BasicEnergyCardFromDeckText
	ldtx bc, BasicEnergyText
	lb de, SEARCHEFFECT_BASIC_ENERGY, 0
	call LookForCardsInDeck
	ret c

	bank1call InitAndDrawCardListScreenLayout_MenuTypeSelectCheck
	ldtx hl, ChooseBasicEnergyCardText
	ldtx de, DuelistDeckText
	bank1call SetCardListHeaderText
.select_card
	bank1call DisplayCardList
	jr c, .try_cancel
	call GetCardIDFromDeckIndex
	call GetCardType
	cp TYPE_ENERGY_DOUBLE_COLORLESS
	jr nc, .select_card ; not a Basic Energy card
	and TYPE_ENERGY
	jr z, .select_card ; not a Basic Energy card
	; Energy card selected

	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	call EmptyScreen
	ldtx hl, ChoosePokemonToAttachEnergyCardText
	call DrawWideTextBox_WaitForInput

; choose a Pokemon in Play Area to attach card
	call HandlePlayerSelectionPokemonInPlayArea
	ldh [hTempPlayAreaLocation_ffa1], a
	ret

.play_sfx
	call PlaySFX_InvalidChoice
	jr .select_card

.try_cancel
; Player tried exiting screen, if there are
; any Basic Energy cards, Player is forced to select them.
; otherwise, they can safely exit.
	ld a, DUELVARS_CARD_LOCATIONS
	call GetTurnDuelistVariable
.loop_deck
	ld a, [hl]
	cp CARD_LOCATION_DECK
	jr nz, .next_card
	ld a, l
	call GetCardIDFromDeckIndex
	call GetCardType
	and TYPE_ENERGY
	jr z, .next_card
	cp TYPE_ENERGY_DOUBLE_COLORLESS
	jr c, .play_sfx
.next_card
	inc l
	ld a, l
	cp DECK_SIZE
	jr c, .loop_deck
	; can exit

	ld a, $ff
	ldh [hTemp_ffa0], a
	ret

NutritionSupport_AISelectEffect:
EnergySpike_AISelectEffect:
; retrieve the presered [hTempPlayAreaLocation_ffa1] from scoring phase
; just for safety, ensure it is a valid play area index
	ld a, $ff
	ldh [hTemp_ffa0], a
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ldh a, [hTempPlayAreaLocation_ffa1]
	cp [hl]
	ret nc  ; error, use $ff for [hTemp_ffa0]
; find the first available energy
	call CreateDeckCardList
	ld hl, wDuelTempList
.loop_deck
	ld a, [hli]
	ldh [hTemp_ffa0], a
	cp $ff
	ret z  ; end of list
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_ENERGY
	jr c, .loop_deck  ; not an energy
	cp TYPE_ENERGY + NUM_COLORED_TYPES
	jr nc, .loop_deck  ; not a basic energy
	or a  ; reset carry flag
	ret

EnergySpike_AttachEnergyEffect:
	ldh a, [hTemp_ffa0]
	cp $ff
	jr z, .done

; add card to hand and attach it to the selected Pokemon
	call SearchCardInDeckAndSetToJustDrawn
	call AddCardToHand
	ldh a, [hTempPlayAreaLocation_ffa1]
	ld e, a
	ldh a, [hTemp_ffa0]
	call PutHandCardInPlayArea
	call IsPlayerTurn
	jr c, .done

; not Player, so show detail screen
; and which Pokemon was chosen to attach Energy.
	call Helper_ShowAttachedEnergyToPokemon

.done
	call SyncShuffleDeck
	ret

NutritionSupport_AttachEnergyEffect:
	call EnergySpike_AttachEnergyEffect
	ldh a, [hTempPlayAreaLocation_ffa1]
	ld e, a   ; location
	ld d, 10  ; damage
	jp HealPlayAreaCardHP


Firestarter_OncePerTurnCheck:
	call CheckPokemonPowerCanBeUsed
	ret c  ; cannot be used
	call CheckBenchIsNotEmpty
	ret c  ; no bench
	call CreateEnergyCardListFromDiscardPile_OnlyFire
	ret c  ; no energy

	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a

;	ld a, [wAlreadyPlayedEnergyOrSupporter]
;	and USED_FIRESTARTER_THIS_TURN
;	jr nz, .already_used

;.already_used
;	ldtx hl, OnlyOncePerTurnText
;	scf
	ret

Firestarter_AttachEnergyEffect:
	ld a, DUELVARS_DUELIST_TYPE
	call GetTurnDuelistVariable
	cp DUELIST_TYPE_LINK_OPP
	jr z, .link_opp
	and DUELIST_TYPE_AI_OPP
	jr z, .player

; AI Pokémon selection logic is in HandleAIFirestarterEnergy
	jr .attach

.player
	ldtx hl, ChoosePokemonToAttachEnergyCardText
	call DrawWideTextBox_WaitForInput
; choose a Pokemon in Play Area to attach card
	call HandlePlayerSelectionPokemonInBench
	ld e, a  ; set selected Pokémon
	ldh [hTempPlayAreaLocation_ffa1], a
	call SerialSend8Bytes
	jr .attach

.link_opp
	call SerialRecv8Bytes
	ld a, e  ; get selected Pokémon
	ldh [hTempPlayAreaLocation_ffa1], a
	; fallthrough

.attach
; restore [hTempPlayAreaLocation_ff9d] from [hTemp_ffa0]
	ldh a, [hTemp_ffa0]
	ldh [hTempPlayAreaLocation_ff9d], a
; flag Firestarter as being used (requires [hTempPlayAreaLocation_ff9d])
	call SetUsedPokemonPowerThisTurn
	; ld a, [wAlreadyPlayedEnergyOrSupporter]
	; or USED_FIRESTARTER_THIS_TURN
	; ld [wAlreadyPlayedEnergyOrSupporter], a

; pick Fire Energy from Discard Pile
	call CreateEnergyCardListFromDiscardPile_OnlyFire
; input e: CARD_LOCATION_* constant
	ldh a, [hTempPlayAreaLocation_ffa1]
	or CARD_LOCATION_PLAY_AREA
	ld e, a
; input a: deck index of discarded card to attach
	ld a, [wDuelTempList]
	call Helper_AttachCardFromDiscardPile

	call IsPlayerTurn
	jr c, .done
	call Helper_GenericShowAttachedEnergyToPokemon

.done
	ldh a, [hTempPlayAreaLocation_ff9d]
	call Func_2c10b
	jp ExchangeRNG


LeekSlap_AIEffect: ; 2eb17 (b:6b17)
	ld a, 30 / 2
	lb de, 0, 30
	jp SetExpectedAIDamage

; return carry if already used attack in this duel
LeekSlap_OncePerDuelCheck: ; 2eb1f (b:6b1f)
; can only use attack if it was never used before this duel
	ld a, DUELVARS_ARENA_CARD_FLAGS
	call GetTurnDuelistVariable
	and USED_LEEK_SLAP_THIS_DUEL
	ret z
	ldtx hl, ThisAttackCannotBeUsedTwiceText
	scf
	ret

LeekSlap_SetUsedThisDuelFlag: ; 2eb2c (b:6b2c)
	ld a, DUELVARS_ARENA_CARD_FLAGS
	call GetTurnDuelistVariable
	set USED_LEEK_SLAP_THIS_DUEL_F, [hl]
	ret

LeekSlap_NoDamage50PercentEffect: ; 2eb34 (b:6b34)
	ldtx de, DamageCheckIfTailsNoDamageText
	call TossCoin_BankB
	ret c
	xor a ; 0 damage
	call SetDefiniteDamage
	ret

CollectEffect:
	ldtx hl, Draw2CardsFromTheDeckText
	call DrawWideTextBox_WaitForInput
	ld a, 2
	bank1call DisplayDrawNCardsScreen
	ld c, 2
.loop_draw
	call DrawCardFromDeck
	jr c, .done
	ldh [hTempCardIndex_ff98], a
	call AddCardToHand
	call IsPlayerTurn
	jr nc, .skip_display_screen
	push bc
	bank1call DisplayPlayerDrawCardScreen
	pop bc
.skip_display_screen
	dec c
	jr nz, .loop_draw
.done
	ret

FetchEffect:
	ldtx hl, Draw1CardFromTheDeckText
	call DrawWideTextBox_WaitForInput
	bank1call DisplayDrawOneCardScreen
	call DrawCardFromDeck
	ret c ; return if deck is empty
	call AddCardToHand
	call LoadCardDataToBuffer1_FromDeckIndex
	ld a, [wDuelistType]
	cp DUELIST_TYPE_PLAYER
	ret nz
	; show card on screen if it was Player
	bank1call OpenCardPage_FromHand
	ret


; shuffle hand back into deck and draw as many cards as the opponent has
MimicEffect:
	call ShuffleHandIntoDeck
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	call GetNonTurnDuelistVariable
	jp DrawNCards_NoCardDetails


TaurosStomp_AIEffect: ; 2eb7b (b:6b7b)
	ld a, (20 + 30) / 2
	lb de, 20, 30
	jp SetExpectedAIDamage

TaurosStomp_DamageBoostEffect: ; 2eb83 (b:6b83)
	ld hl, 10
	call LoadTxRam3
	ldtx de, DamageCheckIfHeadsPlusDamageText
	call TossCoin_BankB
	ret nc ; tails
	ld a, 10
	call AddToDamage
	ret

Rampage_AIEffect: ; 2eb96 (b:6b96)
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	call AddToDamage
	jp SetDefiniteAIDamage

Rampage_Confusion50PercentEffect: ; 2eba1 (b:6ba1)
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	call AddToDamage
	ldtx de, IfTailsYourPokemonBecomesConfusedText
	call TossCoin_BankB
	ret c ; heads
	call SwapTurn
	call ConfusionEffect
	call SwapTurn
	ret

FuryAttack_AIEffect: ; 2ebba (b:6bba)
	ld a, (10 * 2) / 2
	lb de, 0, 20
	jp SetExpectedAIDamage

FuryAttack_MultiplierEffect: ; 2ebc2 (b:6bc2)
	ld hl, 10
	call LoadTxRam3
	ld a, 2
	ldtx de, DamageCheckIfHeadsXDamageText
	call TossCoinATimes_BankB
	call ATimes10
	jp SetDefiniteDamage


ReduceDamageTakenBy20Effect:
	ld a, SUBSTATUS1_REDUCE_BY_20
	call ApplySubstatus1ToAttackingCard
	ret

GaleEffect:
	call HandleNoDamageOrEffect
	ret c ; is unaffected

	ld a, DUELVARS_ARENA_CARD_HP
	call GetNonTurnDuelistVariable
	or a
	ret z ; return if Pokemon was KO'd

; look at all the card locations and put all cards
; that are in the Arena in the hand.
	call SwapTurn
	ld a, DUELVARS_CARD_LOCATIONS
	call GetTurnDuelistVariable
.loop_locations
	ld a, [hl]
	cp CARD_LOCATION_ARENA
	jr nz, .next_card
	; card in Arena found, put in hand
	ld a, l
	call AddCardToHand
.next_card
	inc l
	ld a, l
	cp DECK_SIZE
	jr c, .loop_locations

; empty the Arena card slot
	ld l, DUELVARS_ARENA_CARD
	ld a, [hl]
	ld [hl], $ff
	ld l, DUELVARS_ARENA_CARD_HP
	ld [hl], 0
	call LoadCardDataToBuffer1_FromDeckIndex
	ld hl, wLoadedCard1Name
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call LoadTxRam2
	ldtx hl, PokemonAndAllAttachedCardsReturnedToHandText
	call DrawWideTextBox_WaitForInput
	xor a
	ld [wDuelDisplayedScreen], a
	call SwapTurn
	ret

Whirlwind_SelectEffect:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	cp 2
	jr nc, .switch
	; no Bench Pokemon
	ld a, $ff
	ldh [hTemp_ffa0], a
	ret
.switch
	call DuelistSelectForcedSwitch
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	ret

Whirlwind_SwitchEffect:
	ldh a, [hTemp_ffa0]
	call HandleSwitchDefendingPokemonEffect
	ret


RapidSpin_PlayerSelectEffect:
	call Agility_PlayerSelectEffect
	ldh a, [hTemp_ffa0]
	ldh [hTempPlayAreaLocation_ffa1], a
	jp Whirlwind_SelectEffect

RapidSpin_AISelectEffect:
	call Agility_AISelectEffect
	ldh a, [hTemp_ffa0]
	ldh [hTempPlayAreaLocation_ffa1], a
	jp Whirlwind_SelectEffect

RapidSpin_SwitchEffect:
	call Whirlwind_SwitchEffect
	ldh a, [hTempPlayAreaLocation_ffa1]
	ldh [hTemp_ffa0], a
	jp Agility_SwitchEffect


; return carry if Defending Pokemon has no attacks
Metronome_CheckAttacks:
	call CheckIfDefendingPokemonHasAnyAttack
	ldtx hl, NoAttackMayBeChoosenText
	ret

Metronome_AISelectEffect:
	call HandleAIMetronomeEffect
	ret

; Metronome1_UseAttackEffect:
; 	ld a, 1 ; energy cost of this attack
; 	jr HandlePlayerMetronomeEffect

Metronome_UseAttackEffect:
	ld hl, wLoadedAttackEnergyCost
	ld b, 0
	ld c, (NUM_TYPES / 2) - 1
.loop
; check all basic energy cards except colorless
; each nybble is an energy cost for a type
	ld a, [hl]
	swap a
	and $f
	add b
	ld b, a
	ld a, [hli]
	and $f
	add b
	ld b, a
	dec c
	jr nz, .loop
; last byte, check for darkness energy
	ld a, [hl]
	swap a
	and $f
	add b
	ld b, a
; colorless energy cost
	ld a, [hl]
	and $f
; total energy cost of the attack
	add b
	;	fallthrough

; handles Metronome selection, and validates
; whether it can use the selected attack.
; if unsuccessful, returns carry.
; input:
;	a = amount of colorless energy needed for Metronome
HandlePlayerMetronomeEffect:
	ld [wMetronomeEnergyCost], a
	ldtx hl, ChooseOppAttackToBeUsedWithMetronomeText
	call DrawWideTextBox_WaitForInput

	call HandleDefendingPokemonAttackSelection
	ret c ; return if operation cancelled

; store this attack as selected attack to use
	ld hl, wMetronomeSelectedAttack
	ld [hl], d
	inc hl
	ld [hl], e

; compare selected attack's name with
; the attack that is loaded, which is Metronome.
; if equal, then cannot select it.
; (i.e. cannot use Metronome with Metronome.)
	ld hl, wLoadedAttackName
	ld a, [hli]
	ld h, [hl]
	ld l, a
	push hl
	call SwapTurn
	call CopyAttackDataAndDamage_FromDeckIndex
	call SwapTurn
	pop de
	ld hl, wLoadedAttackName
	ld a, e
	cp [hl]
	jr nz, .try_use
	inc hl
	ld a, d
	cp [hl]
	jr nz, .try_use
	; cannot select Metronome
	ldtx hl, UnableToSelectText
.failed
	call DrawWideTextBox_WaitForInput
.set_carry
	scf
	ret

.try_use
; run the attack checks to determine
; whether it can be used.
	ld a, EFFECTCMDTYPE_INITIAL_EFFECT_1
	call TryExecuteEffectCommandFunction
	jr c, .failed
	ld a, EFFECTCMDTYPE_INITIAL_EFFECT_2
	call TryExecuteEffectCommandFunction
	jr c, .set_carry
	; successful

; send data to link opponent
	call SendAttackDataToLinkOpponent
	ld a, OPPACTION_USE_METRONOME_ATTACK
	call SetOppAction_SerialSendDuelData
	ld hl, wMetronomeSelectedAttack
	ld d, [hl]
	inc hl
	ld e, [hl]
	ld a, [wMetronomeEnergyCost]
	ld c, a
	call SerialSend8Bytes

	ldh a, [hTempCardIndex_ff9f]
	ld [wPlayerAttackingCardIndex], a
	ld a, [wSelectedAttack]
	ld [wPlayerAttackingAttackIndex], a
	ld a, [wTempCardID_ccc2]
	ld [wPlayerAttackingCardID], a
	or a
	ret

; does nothing for AI.
HandleAIMetronomeEffect:
	ret


ConversionBeam_ChangeWeaknessEffect:
	call HandleNoDamageOrEffect
	ret c ; is unaffected

; Choose this Pokemon's color unless it is colorless.
	call GetArenaCardColor
	cp COLORLESS
	ret z

; apply changed weakness
	ld c, a
	ld a, DUELVARS_ARENA_CARD_CHANGED_WEAKNESS
	call GetNonTurnDuelistVariable
	ld a, c
	call TranslateColorToWR
	ld [hl], a
	call SwapTurn
	ldtx hl, ChangedTheWeaknessOfPokemonToColorText
	call PrintArenaCardNameAndColorText
	call SwapTurn
	ret

; prints text that requires card name and color,
; with the card name of the Turn Duelist's Arena Pokemon
; and color in [hTemp_ffa0].
; input:
;	hl = text to print
PrintArenaCardNameAndColorText:
	push hl
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer1_FromDeckIndex
	ldh a, [hTemp_ffa0]
	call LoadCardNameAndInputColor
	pop hl
	call DrawWideTextBox_PrintText
	ret

ScrunchEffect: ; 2eee7 (b:6ee7)
	ldtx de, IfHeadsNoDamageNextTurnText
	call TossCoin_BankB
	jp nc, SetWasUnsuccessful
	ld a, ATK_ANIM_SCRUNCH
	ld [wLoadedAttackAnimation], a
	ld a, SUBSTATUS1_NO_DAMAGE_17
	call ApplySubstatus1ToAttackingCard
	ret

SuperFang_AIEffect: ; 2ef01 (b:6f01)
	call SuperFang_HalfHPEffect
	jp SetDefiniteAIDamage

SuperFang_HalfHPEffect: ; 2ef07 (b:6f07)
	ld a, DUELVARS_ARENA_CARD_HP
	call GetNonTurnDuelistVariable
	srl a
	bit 0, a
	jr z, .rounded
	; round up
	add 5
.rounded
	call SetDefiniteDamage
	ret

; return carry if no Pokemon in Bench
TrainerCardAsPokemon_BenchCheck: ; 2ef18 (b:6f18)
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ldtx hl, EffectNoPokemonOnTheBenchText
	cp 2
	ret

TrainerCardAsPokemon_PlayerSelectSwitch:
	ldh a, [hTemp_ffa0]
	or a
	ret nz ; no need to switch if it's not Arena card

	ldtx hl, SelectPokemonToPlaceInTheArenaText
	call DrawWideTextBox_WaitForInput
	bank1call HasAlivePokemonInBench
	bank1call OpenPlayAreaScreenForSelection
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTempPlayAreaLocation_ffa1], a
	ret

TrainerCardAsPokemon_DiscardEffect:
	ldh a, [hTemp_ffa0]
	ld e, a
	call MovePlayAreaCardToDiscardPile
	ldh a, [hTemp_ffa0]
	or a
	jr nz, .shift_cards
	ldh a, [hTempPlayAreaLocation_ffa1]
	ld e, a
	call SwapArenaWithBenchPokemon
.shift_cards
	jp ShiftAllPokemonToFirstPlayAreaSlots


; return carry if no energy cards in hand,
AttachEnergyFromHand_HandCheck:
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	call GetTurnDuelistVariable
	ldtx hl, NoCardsInHandText
	cp 1
	ret c ; return if no cards in hand
	ld c, $01
	call Helper_CreateEnergyCardListFromHand
	ldtx hl, NoEnergyCardsText
	ret
	; ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	; call GetTurnDuelistVariable
	; ldtx hl, EffectNoPokemonOnTheBenchText
	; cp 2
	; ret

Helper_SelectEnergyFromHand:
; print text box
	ldtx hl, ChooseCardFromYourHandToAttachText
	call DrawWideTextBox_WaitForInput

; create list with all Energy cards in hand
	ld c, $01
	call Helper_CreateEnergyCardListFromHand
	bank1call InitAndDrawCardListScreenLayout_MenuTypeSelectCheck

; handle Player selection (from hand)
	ldtx hl, ChooseBasicEnergyCardText
	ldtx de, DuelistHandText
	bank1call SetCardListHeaderText
.loop_hand_input
	bank1call DisplayCardList
; if B pressed, return carry and $ff in a
; otherwise, return deck index in a
	ret nc
	ld a, $ff
	ret

OptionalAttachEnergyFromHand_PlayerSelectEffect:
	call Helper_SelectEnergyFromHand
	ldh [hTemp_ffa0], a
	cp $ff
	ret z
	jr AttachEnergyFromHand_PlayerSelectEffect.select_play_area

AttachEnergyFromHand_PlayerSelectEffect:
	call Helper_SelectEnergyFromHand
	jr c, Helper_SelectEnergyFromHand.loop_hand_input
	ldh [hTemp_ffa0], a
.select_play_area
; handle Player selection (play area)
	call Helper_ChooseAPokemonInPlayArea_EmptyScreen
	ldh [hTempPlayAreaLocation_ffa1], a
	ret

AttachEnergyFromHand_OnlyActive_PlayerSelectEffect:
	call Helper_SelectEnergyFromHand
; always choose Active Pokémon
	xor a  ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ffa1], a
	ret

AttachEnergyFromHand_AISelectEffect:
; AI doesn't select any card
	ld a, $ff
	ldh [hTemp_ffa0], a
	ret

AttachEnergyFromHand_OnlyActive_AISelectEffect:
; AI doesn't select any card
	ld a, $ff
	ldh [hTemp_ffa0], a
; always choose Active Pokémon
	xor a  ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ffa1], a
	ret

AttachEnergyFromHand_AttachEnergyEffect:
	ldh a, [hTemp_ffa0]
	cp $ff
	ret z

; attach card to the selected Pokemon
	ldh a, [hTempPlayAreaLocation_ffa1]
	ld e, a
	ldh a, [hTemp_ffa0]
	call PutHandCardInPlayArea
	call IsPlayerTurn
	ret c

; not Player, so show detail screen
; and which Pokemon was chosen to attach Energy.
	jp Helper_ShowAttachedEnergyToPokemon


Morph_PlayerSelectEffect:
	call HandlePlayerSelectionBasicPokemonFromDiscardPile_AllowCancel
	ldh [hTemp_ffa0], a
	ret

Morph_AISelectEffect:
; prioritize cards for which there are no duplicates on the play area
; assume card list is already populated from initial check
	; call CreateBasicPokemonCardListFromDiscardPile
	ld hl, wDuelTempList
.loop_cards
	ld a, [hli]
	ldh [hTemp_ffa0], a
	cp $ff
	jr z, .choose_first_card

; which Pokémon are we iterating over?
	call GetCardIDFromDeckIndex
	ld a, e
	ld [wTempPokemonID_ce7c], a

; check play area for duplicates (similar to CountPokemonIDInPlayArea)
	push hl
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld b, a
	ld c, 0

.loop_play_area
	ld a, DUELVARS_ARENA_CARD
	add b
	dec a  ; b starts at 1, we want a 0-based index
	call GetTurnDuelistVariable
	cp $ff
	jr z, .found
; check if it is the same Pokémon
	call GetCardIDFromDeckIndex
	ld a, [wTempPokemonID_ce7c]
	cp e
	jr z, .found_duplicate
	dec b
	jr nz, .loop_play_area
; no duplicates in play area
; card is already stored in [hTemp_ffa0]
	jr .found

.found_duplicate
	pop hl
	jr .loop_cards

.found
	pop hl
	ret

.choose_first_card
	ld a, [wDuelTempList]
	ldh [hTemp_ffa0], a
	ret


MorphEffect:
	ldh a, [hTemp_ffa0]
	cp $ff
	jr nz, .successful
	ldtx hl, AttackUnsuccessfulText
	call DrawWideTextBox_WaitForInput
	ret

.successful
	ldh [hTempCardIndex_ff98], a
	ld a, DUELVARS_ARENA_CARD_STAGE
	call GetTurnDuelistVariable
	or a
	jr z, .skip_discard_stage_below

; if this is an evolved Pokémon (in case it's used with Metronome)
; then first discard the lower stage card.
	push hl
	xor a
	ldh [hTempPlayAreaLocation_ff9d], a
	bank1call GetCardOneStageBelow
	ld a, d
	call PutCardInDiscardPile
	pop hl
	ld [hl], BASIC

.skip_discard_stage_below
; overwrite card ID
; store in de the ID of the card we want to Morph to
	ldh a, [hTempCardIndex_ff98]
	call GetCardIDFromDeckIndex
; store in [hTempCardIndex_ff98] the deck index of the current card
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	ldh [hTempCardIndex_ff98], a
; point hl to the index in deck list, to overwrite ID (preserves de)
	call _GetCardIDFromDeckIndex
	ld [hl], e

; overwrite HP to new card's maximum HP
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	ld a, DUELVARS_ARENA_CARD_HP
	call GetTurnDuelistVariable
	ld [hl], c

; clear changed color and status
	ld l, DUELVARS_ARENA_CARD_CHANGED_TYPE
	ld [hl], $00
	call ClearAllStatusConditionsAndEffects

; load both card's names for printing text
	ld a, [wTempTurnDuelistCardID]
	ld e, a
	ld d, $00
	call LoadCardDataToBuffer2_FromCardID
	ld hl, wLoadedCard2Name
	ld de, wTxRam2
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hl]
	ld [de], a
	inc de
	ldh a, [hTempCardIndex_ff98]
	call LoadCardDataToBuffer2_FromDeckIndex
	ld hl, wLoadedCard2Name
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hl]
	ld [de], a
	ldtx hl, MetamorphsToText
	call DrawWideTextBox_WaitForInput

	xor a
	ld [wDuelDisplayedScreen], a
	ret


; Converts the selected card into a Mysterious Fossil
; input:
;   a - deck index of the selected card
FossilizeCard:
	ld e, MYSTERIOUS_FOSSIL
	; fallthrough

; input:
;   a - deck index of the card to transform
;   e - ID of the card to transform into
OverwriteCardID:
; point hl to the index in deck list, to overwrite ID (preserves de)
	call _GetCardIDFromDeckIndex
	ld [hl], e
	ret


; returns carry if either there are no damage counters
; or no Energy cards attached in the Play Area.
SuperPotion_DamageEnergyCheck: ; 2f159 (b:7159)
	call CheckIfPlayAreaHasAnyDamage
	ret c ; no damage counters
	call CheckIfThereAreAnyEnergyCardsAttached
	ldtx hl, ThereIsNoEnergyCardAttachedText
	ret

SuperPotion_PlayerSelectEffect: ; 2f167 (b:7167)
	ldtx hl, ChoosePokemonToRemoveDamageCounterFromText
	call DrawWideTextBox_WaitForInput
.start
	bank1call HasAlivePokemonInPlayArea
.read_input
	bank1call OpenPlayAreaScreenForSelection
	ret c ; exit if B is pressed
	ld e, a
	call GetCardDamageAndMaxHP
	or a
	jr z, .read_input ; Pokemon has no damage?
	ldh a, [hCurMenuItem]
	ld e, a
	call GetPlayAreaCardAttachedEnergies
	ld a, [wTotalAttachedEnergies]
	or a
	jr nz, .got_pkmn
	; no energy cards attached
	ldtx hl, NoEnergyCardsText
	call DrawWideTextBox_WaitForInput
	jr .start

.got_pkmn
; Pokemon has damage and Energy cards attached,
; prompt the Player for Energy selection to discard.
	ldh a, [hCurMenuItem]
	call CreateArenaOrBenchEnergyCardList
	ldh a, [hCurMenuItem]
	bank1call DisplayEnergyDiscardScreen
	bank1call HandleEnergyDiscardMenuInput
	ret c ; exit if B was pressed

	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTempPlayAreaLocation_ffa1], a
	ret

SuperPotion_HealEffect:
	ldh a, [hTemp_ffa0]
	call PutCardInDiscardPile
	ldh a, [hTempPlayAreaLocation_ffa1]
	ld e, a   ; location
	ld d, 60  ; damage
	jp HealPlayAreaCardHP


; checks if there is at least one Energy card
; attached to some card in the Turn Duelist's Play Area.
; return no carry if one is found,
; and returns carry set if none is found.
CheckIfThereAreAnyEnergyCardsAttached: ; 2f1c4 (b:71c4)
	ld a, DUELVARS_CARD_LOCATIONS
	call GetTurnDuelistVariable
.loop_deck
	ld a, [hl]
	bit CARD_LOCATION_PLAY_AREA_F, a
	jr z, .next_card ; skip if not in Play Area
	ld a, l
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
; OATS begin support trainer subtypes
	cp TYPE_TRAINER
	; original: jr z
	jr nc, .next_card  ; skip if it's a Trainer card
; OATS end support trainer subtypes
	cp TYPE_ENERGY
	jr nc, .found
.next_card
	inc l
	ld a, l
	cp DECK_SIZE
	jr c, .loop_deck
	scf
	ret
.found
	or a
	ret


ImakuniEffect: ; 2f216 (b:7216)
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer1_FromDeckIndex
	ld a, [wLoadedCard1ID]

; cannot confuse Clefairy Doll and Mysterious Fossil
	cp CLEFAIRY_DOLL
	jr z, .failed
	cp MYSTERIOUS_FOSSIL
	jr z, .failed

; cannot confuse Snorlax if its Pkmn Power is active
	cp SNORLAX
	jr nz, .success
	call CheckCannotUseDueToStatus
	jr c, .success
	; fallthrough if Thick Skinned is active

.failed
; play confusion animation and print failure text
	ld a, ATK_ANIM_IMAKUNI_CONFUSION
	call PlayAttackAnimation_AdhocEffect
	ldtx hl, ThereWasNoEffectText
	call DrawWideTextBox_WaitForInput
	ret

.success
; play confusion animation and confuse card
	ld a, ATK_ANIM_IMAKUNI_CONFUSION
	call PlayAttackAnimation_AdhocEffect
	ld a, DUELVARS_ARENA_CARD_STATUS
	call GetTurnDuelistVariable
	and PSN_DBLPSN
	or CONFUSED
	ld [hl], a
	bank1call DrawDuelHUDs
	ret

; returns carry if opponent has no energy cards attached
RocketGrunts_EnergyCheck: ; 2f252 (b:7252)
	call SwapTurn
	call CheckIfThereAreAnyEnergyCardsAttached
	ldtx hl, NoEnergyAttachedToOpponentsActiveText
	call SwapTurn
	ret

RocketGrunts_PlayerSelection: ; 2f25f (b:725f)
	ldtx hl, ChoosePokemonToRemoveEnergyFromText
	call DrawWideTextBox_WaitForInput
	call SwapTurn
	call HandlePokemonAndEnergySelectionScreen
	call SwapTurn
	call c, CancelSupporterCard
	ret

RocketGrunts_AISelection: ; 2f26f (b:726f)
	call AIPickEnergyCardToDiscardFromDefendingPokemon
	ret

RocketGrunts_DiscardEffect: ; 2f273 (b:7273)
	call SwapTurn
	ldh a, [hTempPlayAreaLocation_ffa1]
	call PutCardInDiscardPile
	call SwapTurn
	call IsPlayerTurn
	ret c

; show Player which Pokemon was affected
	call SwapTurn
	ldh a, [hTemp_ffa0]
	call Func_2c10b
	call SwapTurn
	ret

; ------------------------------------------------------------------------------
; UI, Menus and Prompts
; ------------------------------------------------------------------------------

INCLUDE "engine/duel/effect_functions/ui_card_selection.asm"


; search Pokémon cards in Deck
; return carry if there are none and the player refused to look into the deck
_LookForPokemonInDeck:
	call CreateDeckCardList
	ldtx hl, ChooseAnyPokemonFromDeckText
	ldtx bc, AnyPokemonDeckText
	ld d, SEARCHEFFECT_POKEMON
	jp LookForCardsInDeck


; store deck index of selected card or $ff in [hTemp_ffa0]
ChoosePokemonFromDeck_PlayerSelectEffect:
	call _LookForPokemonInDeck
	; jr c, .none_in_deck
	ld a, $ff
	call nc, _HandlePlayerSelectionPokemonFromDeck
	ldh [hTemp_ffa0], a
	or a  ; the effect has been handled, regardless of cancel
	ret



; store deck index of selected card or $ff in [hAIPkmnPowerEffectParam]
StressPheromones_PlayerSelectEffect:
	call _LookForPokemonInDeck
	; jr c, .none_in_deck
	ld a, $ff
	call nc, _HandlePlayerSelectionPokemonFromDeck
	ldh [hAIPkmnPowerEffectParam], a
	or a  ; the Power has been used, regardless of cancel
	ret


Lead_PlayerSelectEffect:
	call HandlePlayerSelectionSupporterFromDeck
	ldh [hTemp_ffa0], a
	ret

; selects the first available card
Lead_AISelectEffect:
	call CreateDeckCardList
	ld hl, wDuelTempList
.loop_deck
	ld a, [hli]
	ldh [hTemp_ffa0], a
	cp $ff
	ret z  ; none found
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_TRAINER_SUPPORTER
	ret z  ; found one
	jr .loop_deck


; select a Pokémon to heal damage and status
NaturalRemedy_PlayerSelection:
	ldtx hl, ChoosePkmnToHealText
	call DrawWideTextBox_WaitForInput
.read_input
	call PlayerSelectAndStorePokemonInPlayArea
	ld e, a
	call GetCardDamageAndMaxHP
	or a
	jr nz, .done
	ld a, DUELVARS_ARENA_CARD_STATUS
	add e
	call GetTurnDuelistVariable
	or a
	jr z, .read_input ; no damage, no status, loop back to start
.done
	ret


PrimalScythe_PlayerHandCardSelection:
	call CheckMysteriousFossilInHand
	jr c, .none_in_hand
; found a Mysterious Fossil in hand
	ldh [hTemp_ffa0], a
	ldtx hl, DiscardMysteriousFossilText
	call YesOrNoMenuWithText_SetCursorToYes
	ret nc  ; selected Yes

; selected No
	ld a, $ff
.none_in_hand
	or a  ; reset carry
.done
	ldh [hTemp_ffa0], a
	ret


OptionalDiscard_PlayerHandCardSelection:
	call CheckHandSizeGreaterThan1
	ld a, $ff
	call nc, HandlePlayerSelection1HandCardToDiscard
	ldh [hTemp_ffa0], a
	or a
	ret

ShadowClaw_AISelectEffect:
; the AI never discards hand cards
	ld a, $ff
	ldh [hTemp_ffa0], a
	ret
	; ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	; call GetNonTurnDuelistVariable
	; or a
	; ret z  ; Player has no cards in hand
	; jp DiscardEnergy_AISelectEffect


Trade_PlayerHandCardSelection:
	call HandlePlayerSelection1HandCardToDiscard
	ldh [hAIPkmnPowerEffectParam], a
	ret


Discard_PlayerHandCardSelection:
	call HandlePlayerSelection1HandCardToDiscardExcludeSelf
	ldh [hTempList], a
	ret


Maintenance_PlayerDiscardPileSelection:
	call HandlePlayerSelectionItemTrainerFromDiscardPile
	ret c
	ldh [hTempList + 1], a
	ld a, $ff  ; terminating byte
	ldh [hTempList + 2], a
	ret


EnergySwitch_PlayerSelection:
	ldtx hl, ChoosePokemonToRemoveEnergyFromText
	call DrawWideTextBox_WaitForInput
	call HandlePokemonAndBasicEnergySelectionScreen
	; call c, CancelSupporterCard
	ret c  ; gave up on using the card
; choose a Pokemon in Play Area to attach card
	call EmptyScreen
	ldtx hl, ChoosePokemonToAttachEnergyCardText
	call DrawWideTextBox_WaitForInput
.loop_input
	call HandlePlayerSelectionPokemonInPlayArea
; cannot choose the same Pokémon
	ld e, a
	ldh a, [hTemp_ffa0]
	cp e
	jr nz, .got_pkmn
	call PlaySFX_InvalidChoice
	jr .loop_input
.got_pkmn
; target location is already in [hTempPlayAreaLocation_ff9d]
; move energy to [hTempList]
	ldh a, [hTempPlayAreaLocation_ffa1]
	ldh [hTempList], a
	ld a, $ff
	ldh [hTempList + 1], a
	or a
	ret


; output:
;   [hTemp_ffa0]: deck index of energy card to move | $ff
;   [hTempPlayAreaLocation_ffa1]: PLAY_AREA_* of benched Pokémon
EnergySlide_PlayerSelection:
	ld a, $ff
	ldh [hTemp_ffa0], a
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	cp 2
	ccf
	ret nc  ; nothing to do if there are no Benched Pokémon

	ld e, PLAY_AREA_ARENA
	call HandleAttachedBasicEnergySelectionScreen
	ccf
	ret nc  ; gave up on choosing energy or there are no Basic energies

; selected energy index is in a and [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	call EmptyScreen
	ldtx hl, ChoosePokemonToAttachEnergyCardText
	call DrawWideTextBox_WaitForInput
	call HandlePlayerSelectionPokemonInBench
	ldh [hTempPlayAreaLocation_ffa1], a
	ret

; chooses a benched Pokémon without any attached energies
EnergySlide_AISelectEffect:
	ld a, $ff
	ldh [hTemp_ffa0], a

	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	dec a
	ret z  ; nothing to do
	ld d, a
	ld e, PLAY_AREA_BENCH_1

.loop_play_area
	call GetPlayAreaCardAttachedEnergies
	ld a, [wTotalAttachedEnergies]
	or a
	jr nz, .skip
; found Pokémon without any attached energies
	ld a, e
	ldh [hTempPlayAreaLocation_ffa1], a
; choose an energy to move
	jp DiscardEnergy_AISelectEffect
.skip
	inc e
	dec d
	ret z  ; nothing to do
	jr .loop_play_area


WickedTentacle_PlayerSelection:
	call SwapTurn
	call EnergySlide_PlayerSelection
	jp SwapTurn

; Precondition ensures there are Bench Pokémon and energy on the Active Pokémon.
WickedTentacle_AISelectEffect:
	call SwapTurn
; store energy to discard in [hTemp_ffa0]
	call DiscardEnergy_AISelectEffect
; pick the first Benched Pokémon
	ld a, PLAY_AREA_BENCH_1
	ldh [hTempPlayAreaLocation_ffa1], a
	jp SwapTurn


; ------------------------------------------------------------------------------
; Move Selected Cards
; ------------------------------------------------------------------------------


;
ItemFinder_DiscardAddToHandEffect:
SelectedCards_Discard1AndAdd1ToHandFromDeck:
; discard the first card in hTempList
	call SelectedCards_Discard1FromHand
; add the second card in hTempList to the hand
	ldh a, [hTempList + 1]
	ldh [hTempList], a
	; ld a, $ff
	; ldh [hTempList + 1], a
	jr SelectedCard_AddToHandFromDeckEffect


; Pokémon Powers do not use [hTemp_ffa0]
; adds a card in [hAIEnergyTransEnergyCard] from the deck to the hand
; Note: Pokémon Power no longer needs to preserve [hTemp_ffa0] at this point
Synthesis_AddToHandEffect:
	call SetUsedPokemonPowerThisTurn
	ldh a, [hAIEnergyTransEnergyCard]
	ldh [hTemp_ffa0], a
	jr SelectedCard_AddToHandFromDeckEffect


; Pokémon Powers do not use [hTemp_ffa0]
; adds a card in [hAIEnergyTransEnergyCard] from the discard pile to the hand
; Note: Pokémon Power no longer needs to preserve [hTemp_ffa0] at this point
MudSport_AddToHandEffect:
	call SetUsedPokemonPowerThisTurn
	ldh a, [hAIEnergyTransEnergyCard]
	ldh [hTemp_ffa0], a
	jp SelectedCard_AddToHandFromDiscardPile


; Pokémon Powers do not use [hTemp_ffa0]
; adds a card in [hAIPkmnPowerEffectParam] from the deck to the hand
; Note: Pokémon Power no longer needs to preserve [hTemp_ffa0] at this point
StressPheromones_AddToHandEffect:
	call SetUsedPokemonPowerThisTurn
	ldh a, [hAIPkmnPowerEffectParam]
	ldh [hTemp_ffa0], a
	; jr SelectedCard_AddToHandFromDeckEffect
	; fallthrough


; Adds the selected card to the turn holder's Hand.
SelectedCard_AddToHandFromDeckEffect:
	ldh a, [hTemp_ffa0]
	cp $ff
	jp z, SyncShuffleDeck ; skip if no card was chosen
	; fallthrough

; add selected card to the hand and show it on screen if
; it wasn't the Player who used the attack.
; input:
;   a: deck index of card to add from deck to hand
AddDeckCardToHandAndShuffleEffect:
	call AddDeckCardToHandEffect
	jp SyncShuffleDeck

; add selected card to the hand and show it on screen if
; it wasn't the Player who used the attack.
; input:
;   a: deck index of card to add from deck to hand
AddDeckCardToHandEffect:
	call SearchCardInDeckAndSetToJustDrawn  ; preserves af, hl, bc, de
	call AddCardToHand  ; preserves af, hl bc, de
	push de
	ld d, a
	call IsPlayerTurn  ; preserves bc, de
	ld a, d
	pop de
	ret c
	ldtx hl, WasPlacedInTheHandText
	bank1call DisplayCardDetailScreen
	ret


; adds all the cards in hTempList to the turn holder's hand
SelectedCardList_AddToHandFromDeckEffect:
	ld hl, hTempList
.loop_cards
	ld a, [hli]
	cp $ff
	jp z, SyncShuffleDeck  ; done
	push hl
	call AddDeckCardToHandEffect
	pop hl
	jr .loop_cards



; Move the selected deck card to the top of the deck.
SelectedCard_DredgeEffect:
SelectedCard_MoveToTopOfDeckEffect:
	ldh a, [hTemp_ffa0]
	cp $ff
	ret z ; skip if no card was chosen
	; fallthrough

; move selected card to the top of the deck.
; input:
;   a: deck index of card to move
DredgeEffect:
MoveDeckCardToTopOfDeckEffect:
	call SearchCardInDeckAndSetToJustDrawn  ; preserves af, hl, bc, de
	call AddCardToHand  ; preserves af, hl bc, de
	call RemoveCardFromHand  ; preserves af, hl bc, de
	jp ReturnCardToDeck  ; preserves a, hl, de, bc


SelectedCard_AddToHandFromDiscardPile:
; add the first card in hTempList to the hand
	ldh a, [hTempList]
	cp $ff
	ret z
	; fallthrough

; move the card with deck index given in a from the discard pile to the hand
AddDiscardPileCardToHandEffect:
	call MoveDiscardPileCardToHand
	call AddCardToHand
	call IsPlayerTurn
	ret c
; display card on screen
	ldh a, [hTempList]
	ldtx hl, WasPlacedInTheHandText
	bank1call DisplayCardDetailScreen
	ret


; moves all the cards in hTempList from the discard pile to the turn holder's hand
SelectedCardList_AddToHandFromDiscardPileEffect:
	ld hl, hTempList
.loop_cards
	ld a, [hli]
	cp $ff
	ret z  ; done
	push hl
	call AddDiscardPileCardToHandEffect
	pop hl
	jr .loop_cards


AbsorbWater_AddToHandEffect:
	call CreateEnergyCardListFromDiscardPile_OnlyWater
; choose the first energy in the list
	ld a, [wDuelTempList]
	ldh [hTempList], a
	ld a, $ff
	ldh [hTempList + 1], a
	jr SelectedCard_AddToHandFromDiscardPile


Maintenance_DiscardAndAddToHandEffect:
SelectedCards_Discard1AndAdd1ToHandFromDiscardPile:
; discard the first card in hTempList
	call SelectedCards_Discard1FromHand
; add the second card in hTempList to the hand
	ldh a, [hTempList + 1]
	ldh [hTempList], a
	ld a, $ff
	ldh [hTempList + 1], a
	jr SelectedCard_AddToHandFromDiscardPile


; discard the first card in hTempList
SelectedCards_Discard1FromHand:
	ldh a, [hTempList]
	cp $ff
	scf
	ret z
	call RemoveCardFromHand
	call PutCardInDiscardPile
	or a
	ret


WickedTentacle_TransferEffect:
	call SwapTurn
	call EnergySlide_TransferEffect
; restore target location to [hTempPlayAreaLocation_ffa1]
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTempPlayAreaLocation_ffa1], a
	jp SwapTurn


; input:
;   [hTemp_ffa0]: deck index of card to move
;   [hTempPlayAreaLocation_ffa1]: target location to move card to
EnergySlide_TransferEffect:
	ldh a, [hTemp_ffa0]
	cp $ff
	ret z  ; nothing to do

	ldh a, [hTempPlayAreaLocation_ffa1]
	ldh [hTempPlayAreaLocation_ff9d], a  ; target location
	; [hTempList]: card to move
	ld a, $ff
	ldh [hTempList + 1], a  ; list terminator
	; jr SelectedCards_MoveWithinPlayArea
	; fallthrough


; input:
;   [hTempPlayAreaLocation_ff9d]: target location to move cards to
;   [hTempList]: list of cards to move
EnergySwitch_TransferEffect:
SelectedCards_MoveWithinPlayArea:
; get target location to assign to cards in list
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld e, a
	ld d, 0
	ld hl, hTempList
; relocate all cards in [hTempList]
.loop
	ld a, [hli]
	cp $ff
	jr z, .done
	call AddCardToHand
	push hl
	call PutHandCardInPlayArea  ; location in e
	pop hl
	inc d
	jr .loop

; if not Player, show which Pokemon was chosen to attach Energy
.done
	call IsPlayerTurn
	ret c
	jp Helper_GenericShowAttachedEnergyToPokemon


; add a card to the bottom of the turn holder's deck
; input:
;   a: the deck index (0-59) of the card
ReturnCardToBottomOfDeck:
	push hl
	push af
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	call GetTurnDuelistVariable
	dec a
	ld [hl], a  ; decrement number of cards not in deck
	ld a, DECK_SIZE
	sub [hl]
	dec a    ; how many cards there were in the deck before
	ld b, a  ; how many cards to shift position
	or a
	jr z, .done_shift
	ld a, [hl]
	add DUELVARS_DECK_CARDS
	ld l, a  ; point to the new top deck position
	ld e, l
	ld d, h
	inc hl   ; point to the actual top deck card
; shift all cards up to make space at the bottom
.loop
	ld a, [hli]
	ld [de], a
	inc de
	dec b
	jr nz, .loop
.done_shift
	pop af
	ld l, DUELVARS_DECK_CARDS + DECK_SIZE - 1  ; last card
	ld [hl], a ; set the last deck card
	ld l, a
	ld [hl], CARD_LOCATION_DECK
	ld a, l
	pop hl
	ret


; ------------------------------------------------------------------------------
; AI Logic
; ------------------------------------------------------------------------------

NaturalRemedy_AISelectEffect:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld c, a   ; loop counter
	ld d, 30  ; current max damage (heal at least 30)
	ld e, PLAY_AREA_ARENA  ; location iterator
	ld b, $ff  ; location of max damage
	ld l, DUELVARS_ARENA_CARD_STATUS
; find Play Area location with most amount of damage
.loop
	push bc
	ld b, 0  ; score
; status conditions are worth 20 damage
	ld a, [hli]
	or a
	jr z, .get_damage
	ld b, 20
.get_damage
; e already has the current PLAY_AREA_* offset
	call GetCardDamageAndMaxHP
; add score from status conditions
	add b
	pop bc
	or a
	jr z, .next ; skip if nothing to heal (redundant)
; compare to current max damage
	cp d
	jr c, .next ; skip if stored damage is higher
; store new target Pokémon
	ld d, a
	ld b, e
.next
	inc e  ; next location
	dec c  ; decrement counter
	jr nz, .loop
; return selected location (or $ff) in a and [hTemp_ffa0]
	ld a, b
	ldh [hTemp_ffa0], a
	ret


; store deck index of selected card or $ff in [hTemp_ffa0]
ChoosePokemonFromDeck_AISelectEffect:
; TODO FIXME
	ld a, $ff
	ldh [hTemp_ffa0], a
	ret


PrimalScythe_AIEffect:
	call CheckMysteriousFossilInHand
	call nc, PrimalScythe_DamageBoostEffect
	or a
	ret


PrimalScythe_AISelectEffect:
	call CheckMysteriousFossilInHand
	ldh [hTemp_ffa0], a
	jr nc, .found
	or a  ; reset carry
	ret

.found
; always discard
	ldh [hTemp_ffa0], a
	ret


; ------------------------------------------------------------------------------

; return carry if no other card in hand to discard
; or if there are no Basic Energy cards in Discard Pile.
EnergyRetrieval_HandEnergyCheck:
	call CheckHandSizeGreaterThan1
	ret c ; return if doesn't have another card to discard
	call CreateEnergyCardListFromDiscardPile_OnlyBasic
	ldtx hl, ThereAreNoBasicEnergyCardsInDiscardPileText
	ret


EnergyRetrieval_PlayerDiscardPileSelection: ; 2f2b9 (b:72b9)
	ld a, 1 ; start at 1 due to card selected from hand
	ldh [hCurSelectionItem], a
	ldtx hl, Choose2BasicEnergyCardsFromDiscardPileText
	call DrawWideTextBox_WaitForInput
	call CreateEnergyCardListFromDiscardPile_OnlyBasic

.select_card
	bank1call InitAndDrawCardListScreenLayout
	ldtx hl, PleaseSelectCardText
	ldtx de, PlayerDiscardPileText
	bank1call SetCardListHeaderText
	bank1call DisplayCardList
	jr nc, .selected
	; B was pressed
	ld a, 2 + 1 ; includes the card selected from hand
	call AskWhetherToQuitSelectingCards
	jr c, .select_card ; player selected No
	jr .done

.selected
	call GetNextPositionInTempList
	ldh a, [hTempCardIndex_ff98]
	ld [hl], a
	call RemoveCardFromDuelTempList
	jr c, .done
	ldh a, [hCurSelectionItem]
	cp 2 + 1 ; includes the card selected from hand
	jr c, .select_card

.done
	call GetNextPositionInTempList
	ld [hl], $ff ; terminating byte
	or a
	ret

EnergyRetrieval_DiscardAndAddToHandEffect:
	ld hl, hTempList
	ld a, [hli]
	call RemoveCardFromHand
	call PutCardInDiscardPile
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
	call IsPlayerTurn
	ret c
	bank1call DisplayCardListDetails
	ret


Synthesis_PlayerSelection:
; Pokémon Powers must preserve [hTemp_ffa0]
	; ldh a, [hTemp_ffa0]
	; push af
	call EnergySearch_PlayerSelection
	ldh a, [hTemp_ffa0]
	ldh [hAIEnergyTransEnergyCard], a
	; pop af
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	ret


MudSport_PlayerSelection:
; Pokémon Powers must preserve [hTemp_ffa0]
	; ldh a, [hTemp_ffa0]
	; push af
	ldtx hl, Choose1BasicEnergyCardFromDiscardPileText
	call DrawWideTextBox_WaitForInput
	call HandlePlayerSelectionBasicEnergyFromDiscardPile_AllowCancel
	ret c
	ldh [hAIEnergyTransEnergyCard], a
	; pop af
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	ret


EnergySearch_PlayerSelection:
	ld a, $ff
	ldh [hTemp_ffa0], a
	call CreateDeckCardList
	ldtx hl, Choose1BasicEnergyCardFromDeckText
	lb de, SEARCHEFFECT_BASIC_ENERGY, 0
	ldtx bc, BasicEnergyText
	call LookForCardsInDeck
	ret c ; skip showing deck

	bank1call InitAndDrawCardListScreenLayout_MenuTypeSelectCheck
	ldtx hl, ChooseBasicEnergyCardText
	ldtx de, DuelistDeckText
	bank1call SetCardListHeaderText
.read_input
	bank1call DisplayCardList
	jr c, .try_exit ; B pressed?
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	call CheckIfCardIsBasicEnergy
	jr c, .play_sfx
	or a
	ret
.play_sfx
	call PlaySFX_InvalidChoice
	jr .read_input

.try_exit
; check if Player can exit without selecting anything
	ld hl, wDuelTempList
.next_card
	ld a, [hli]
	cp $ff
	jr z, .exit
	call CheckIfCardIsBasicEnergy
	jr c, .next_card
	jr .read_input ; no, has to select Energy card
.exit
	ld a, $ff
	ldh [hTemp_ffa0], a
	or a
	ret


; check if card index in a is a Basic Energy card.
; returns carry in case it's not.
CheckIfCardIsBasicEnergy: ; 2f38f (b:738f)
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_ENERGY
	jr c, .not_basic_energy
	cp TYPE_ENERGY_DOUBLE_COLORLESS
	jr nc, .not_basic_energy
; is basic energy
	or a
	ret
.not_basic_energy
	scf
	ret


ProfessorOakEffect:
; discard hand
	call CreateHandCardList
	call SortCardsInDuelTempListByID
	ld hl, wDuelTempList
.discard_loop
	ld a, [hli]
	cp $ff
	jr z, .draw_cards
	call RemoveCardFromHand
	call PutCardInDiscardPile
	jr .discard_loop

.draw_cards
	ld a, 7
	bank1call DisplayDrawNCardsScreen
	ld c, 7
.draw_loop
	call DrawCardFromDeck
	jr c, .done
	call AddCardToHand
	dec c
	jr nz, .draw_loop
.done
	ret


; shuffle hand back into deck and draw N cards
LassEffect:
	call ShuffleHandIntoDeckExcludeSelf
	ld a, 5
	jp DrawNCards_NoCardDetails


Potion_PlayerSelection:
	bank1call HasAlivePokemonInPlayArea
.read_input
	bank1call OpenPlayAreaScreenForSelection
	ret c ; exit is B was pressed
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	ld e, a
	call GetCardDamageAndMaxHP
	or a
	jr z, .read_input ; no damage, loop back to start
	ret

Potion_HealEffect:
	ldh a, [hTemp_ffa0]
	ld e, a
	ld d, 30
	jp HealPlayAreaCardHP


GamblerEffect: ; 2f3f9 (b:73f9)
	ldtx de, CardCheckIfHeads8CardsIfTails1CardText
	call TossCoin_BankB
	ldh [hTemp_ffa0], a
; discard Gambler card from hand
	ldh a, [hTempCardIndex_ff9f]
	call RemoveCardFromHand
	call PutCardInDiscardPile

; shuffle cards into deck
	call CreateHandCardList
	call SortCardsInDuelTempListByID
	ld hl, wDuelTempList
.loop_return_deck
	ld a, [hli]
	cp $ff
	jr z, .check_coin_toss
	call RemoveCardFromHand
	call ReturnCardToDeck
	jr .loop_return_deck

.check_coin_toss
	call SyncShuffleDeck
	ld c, 8
	ldh a, [hTemp_ffa0]
	or a
	jr nz, .draw_cards ; coin toss was heads?
	; if tails, number of cards to draw is 1
	ld c, 1

; correct number of cards to draw is in c
.draw_cards
	ld a, c
	jp DrawNCards_NoCardDetails


ItemFinder_PlayerSelection:
	; call HandlePlayerSelection2HandCardsToDiscardExcludeSelf
	call HandlePlayerSelection1HandCardToDiscardExcludeSelf
	; was operation cancelled?
	; call c, CancelSupporterCard
	ret c

; cards were selected to discard from hand
	ldh [hTempList], a
; now to choose an Item card from Deck
	call HandlePlayerSelectionItemTrainerFromDeck
	ldh [hTempList + 1], a  ; placed after the selected cards to discard
	ret


Defender_PlayerSelection: ; 2f488 (b:7488)
	ldtx hl, ChoosePokemonToAttachDefenderToText
	call DrawWideTextBox_WaitForInput
	bank1call HasAlivePokemonInPlayArea
	bank1call OpenPlayAreaScreenForSelection
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	ret

Defender_AttachDefenderEffect: ; 2f499 (b:7499)
; attach Trainer card to Play Area Pokemon
	ldh a, [hTemp_ffa0]
	ld e, a
	ldh a, [hTempCardIndex_ff9f]
	call PutHandCardInPlayArea

; increase number of Defender cards of this location by 1
	ldh a, [hTemp_ffa0]
	add DUELVARS_ARENA_CARD_ATTACHED_DEFENDER
	call GetTurnDuelistVariable
	inc [hl]
	call IsPlayerTurn
	ret c

	ldh a, [hTemp_ffa0]
	jp Func_2c10b


; return carry if Bench is full.
ClefairyDoll_BenchCheck:
MysteriousFossil_BenchCheck:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	cp MAX_PLAY_AREA_POKEMON
	ccf
	ldtx hl, NoSpaceOnTheBenchText
	ret

ClefairyDoll_PlaceInPlayAreaEffect:
MysteriousFossil_PlaceInPlayAreaEffect:
	ldh a, [hTempCardIndex_ff9f]
	jp PutHandPokemonCardInPlayArea



ImposterProfessorOakEffect:
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	call GetTurnDuelistVariable
	dec a  ; exclude this card
	or a
	jr nz, .has_cards  ; at least 1 player has cards in hand
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	call GetNonTurnDuelistVariable
	or a
	ret z  ; neither player has any cards in hand

.has_cards
	call ShuffleHandAndReturnToBottomOfDeckExcludeSelf
	call CheckOpponentHasMorePrizeCardsRemaining
	ld a, 3  ; player draws 3 cards
	jr nc, .draw_cards
	ld a, 5  ; player is losing, draws 5 cards
.draw_cards
	call DrawNCards_NoCardDetails
	call SwapTurn
	call ShuffleHandAndReturnToBottomOfDeck
	ld a, 4  ; opponent draws 4 cards
	call DrawNCards_NoCardDetails
	jp SwapTurn


JudgeEffect:
	call ShuffleHandIntoDeckExcludeSelf
	ld a, 4  ; player draws 4 cards
	call DrawNCards_NoCardDetails
	call SwapTurn
	call ShuffleHandIntoDeck
	ld a, 4  ; opponent draws 4 cards
	call DrawNCards_NoCardDetails
	jp SwapTurn


; Returns all hand cards (excluding the Trainer card currently in use) to
; the turn holder's deck and then shuffles the deck.
ShuffleHandIntoDeckExcludeSelf:
	call CreateHandCardListExcludeSelf
	jr ShuffleHandIntoDeck.got_card_list

; Returns all hand cards to the turn holder's deck and then shuffles the deck.
ShuffleHandIntoDeck:
	call CreateHandCardList
.got_card_list
	; call SortCardsInDuelTempListByID
	ld hl, wDuelTempList
.loop_return_deck
	ld a, [hli]
	cp $ff
	jr z, .done_return
	call RemoveCardFromHand
	call ReturnCardToDeck
	jr .loop_return_deck
.done_return
	jp SyncShuffleDeck


; Shuffles all hand cards (excluding the Trainer card in use) and then puts
; those cards at the bottom of the turn holder's deck.
ShuffleHandAndReturnToBottomOfDeckExcludeSelf:
	call CreateHandCardListExcludeSelf
	jr ShuffleHandAndReturnToBottomOfDeck.got_card_list

; Shuffles all hand cards and then puts those cards at the bottom of
; the turn holder's deck.
ShuffleHandAndReturnToBottomOfDeck:
	call CreateHandCardList
.got_card_list
	ld hl, wDuelTempList
	call ShuffleCards
.loop_return_deck
	ld a, [hli]
	cp $ff
	ret z
	call RemoveCardFromHand
	call ReturnCardToBottomOfDeck
	jr .loop_return_deck


; input:
;   a: how many cards to draw
DrawNCards_NoCardDetails:
	ld c, a  ; store in c to use later
	bank1call DisplayDrawNCardsScreen  ; preserves bc
.loop_draw
	call DrawCardFromDeck
	ret c
	call AddCardToHand
	dec c
	jr nz, .loop_draw
	ret


ComputerSearch_PlayerSelection:
; create the list of the top 7 cards in deck
	ld b, 7
	call CreateDeckCardListTopNCards
; handle input
	bank1call InitAndDrawCardListScreenLayout_MenuTypeSelectCheck
	ldtx hl, ChooseSupporterCardText
	ldtx de, DuelistDeckText
	bank1call SetCardListHeaderText
.read_input
	bank1call DisplayCardList
; if B was pressed, either there are no Supporters or Player does not want any
	jr c, .no_cards
	ldh a, [hTempCardIndex_ff98]
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_TRAINER_SUPPORTER
	jr nz, .play_sfx ; can't select non-Supporter card
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	or a
	ret

.no_cards
	ld a, $ff
	ldh [hTemp_ffa0], a
	or a
	ret

.play_sfx
	call PlaySFX_InvalidChoice
	jr .read_input


MrFuji_PlayerSelection:
	ldtx hl, ChoosePokemonToReturnToTheDeckText
	call DrawWideTextBox_WaitForInput
	bank1call HasAlivePokemonInBench
	bank1call OpenPlayAreaScreenForSelection
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	call c, CancelSupporterCard
	ret

MrFuji_ReturnToDeckEffect:
; get Play Area location's card index
	ldh a, [hTemp_ffa0]
	; fallthrough

; Return the Pokémon in the location given in a
; and all cards attached to it to the turn holder's deck.
ReturnPlayAreaPokemonToDeckEffect:
	ld e, a
	add DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	ldh [hTempCardIndex_ff98], a
	ld a, e
	or a
	jr nz, _ReturnBenchedPokemonToDeckEffect

; if Pokemon was in Arena, then switch it with the selected Bench card first
; this avoids a bug that occurs when arena is empty before
; calling ShiftAllPokemonToFirstPlayAreaSlots
	ldh a, [hTemp_ffa0]
	ld e, a
; this eventually calls ClearAllArenaEffectsAndSubstatus
	call SwapArenaWithBenchPokemon

; after switching, return the benched Pokémon as normal
	; fallthrough

_ReturnBenchedPokemonToDeckEffect:
; find all cards that are in the same location
; (previous evolutions and energy cards attached)
; and return them all to the deck.
	ldh a, [hTemp_ffa0]
	or CARD_LOCATION_PLAY_AREA
	ld e, a
	ld a, DUELVARS_CARD_LOCATIONS
	call GetTurnDuelistVariable
.loop_cards
	push de
	push hl
	ld a, [hl]
	cp e
	jr nz, .next_card
	ld a, l
	call ReturnCardToDeck
.next_card
	pop hl
	pop de
	inc l
	ld a, l
	cp DECK_SIZE
	jr c, .loop_cards

; clear Play Area location of card
	ldh a, [hTemp_ffa0]
	ld e, a
	call EmptyPlayAreaSlot
	ld l, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	dec [hl]
	call ShiftAllPokemonToFirstPlayAreaSlots

; if not the Player's turn, print text and show card on screen
	call IsPlayerTurn
	jr c, .done
	ldh a, [hTempCardIndex_ff98]
	call LoadCardDataToBuffer1_FromDeckIndex
	ld hl, wLoadedCard1Name
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call LoadTxRam2
	bank1call DrawLargePictureOfCard
	ldtx hl, PokemonAndAllAttachedCardsWereReturnedToDeckText
	call DrawWideTextBox_WaitForInput
.done
	jp SyncShuffleDeck


PlusPowerEffect: ; 2f5e0 (b:75e0)
; attach Trainer card to Arena Pokemon
	ld e, PLAY_AREA_ARENA
	ldh a, [hTempCardIndex_ff9f]
	call PutHandCardInPlayArea

; increase number of Defender cards of this location by 1
	ld a, DUELVARS_ARENA_CARD_ATTACHED_PLUSPOWER
	call GetTurnDuelistVariable
	inc [hl]
	ret

; return carry if no Pokemon in the Bench.
Switch_BenchCheck: ; 2f5ee (b:75ee)
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ldtx hl, EffectNoPokemonOnTheBenchText
	cp 2
	ret

Switch_PlayerSelection: ; 2f5f9 (b:75f9)
	ldtx hl, SelectPkmnOnBenchToSwitchWithActiveText
	call DrawWideTextBox_WaitForInput
	bank1call HasAlivePokemonInBench
	bank1call OpenPlayAreaScreenForSelection
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	call c, CancelSupporterCard
	ret

Switch_SwitchEffect: ; 2f60a (b:760a)
	ldh a, [hTemp_ffa0]
	ld e, a
	call SwapArenaWithBenchPokemon
	ret


; return carry if non-Turn Duelist has full Bench
; or if they have no Basic Pokemon cards in Discard Pile.
PokemonFlute_BenchCheck:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	ldtx hl, NoSpaceOnTheBenchText
	cp MAX_PLAY_AREA_POKEMON
	ccf
	ret c ; not enough space in Bench
	; check Discard Pile
	call SwapTurn
	call CreateBasicPokemonCardListFromDiscardPile
	ldtx hl, ThereAreNoPokemonInDiscardPileText
	call SwapTurn
	ret

PokemonFlute_PlayerSelection:
; create Discard Pile list
	call SwapTurn
	call CreateBasicPokemonCardListFromDiscardPile

; display selection screen and store Player's selection
	bank1call InitAndDrawCardListScreenLayout_MenuTypeSelectCheck
	ldtx hl, ChoosePokemonToPlaceInPlayText
	ldtx de, PlayerDiscardPileText
	bank1call SetCardListHeaderText
	bank1call DisplayCardList
	call SwapTurn
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	ret

PokemonFlute_PlaceInPlayAreaText:
; place selected card in non-Turn Duelist's Bench
	call SwapTurn
	ldh a, [hTemp_ffa0]
	call MoveDiscardPileCardToHand
	call AddCardToHand
	call PutHandPokemonCardInPlayArea
	call SwapTurn

; unless it was the Player who played the card,
; display the Pokemon card on screen.
	call IsPlayerTurn
	ret c
	call SwapTurn
	ldh a, [hTemp_ffa0]
	ldtx hl, CardWasChosenText
	bank1call DisplayCardDetailScreen
	call SwapTurn
	ret


PokemonFlute_DisablePowersEffect:
	ld a, DUELVARS_MISC_TURN_FLAGS
	call GetTurnDuelistVariable
	set TURN_FLAG_PKMN_POWERS_DISABLED_F, [hl]
	ld a, DUELVARS_MISC_TURN_FLAGS
	call GetNonTurnDuelistVariable
	set TURN_FLAG_PKMN_POWERS_DISABLED_F, [hl]
	ret




ScoopUpNet_PlayerSelection:
; print text box
	ldtx hl, ChoosePokemonToScoopUpText
	call DrawWideTextBox_WaitForInput

; handle Player selection
	bank1call HasAlivePokemonInPlayArea
	bank1call OpenPlayAreaScreenForSelection
	; call c, CancelSupporterCard
	ret c ; exit if B was pressed

	; ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	or a
	ret nz ; if it wasn't the Active Pokemon, we are done

; handle switching to a Pokemon in Bench and store location selected.
	call EmptyScreen
	ldtx hl, SelectPokemonToPlaceInTheArenaText
	call DrawWideTextBox_WaitForInput
	bank1call HasAlivePokemonInBench
	bank1call OpenPlayAreaScreenForSelection
	; ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTempPlayAreaLocation_ffa1], a
	ret


ScoopUpNet_ReturnToHandEffect:
; if card was in Bench, simply return Pokémon to hand
	ldh a, [hTemp_ffa0]
	or a
	jr nz, ScoopUpFromBench
	; fallthrough

; if Pokemon was in Arena, then switch it with the selected Bench card first
; this avoids a bug that occurs when arena is empty before
; calling ShiftAllPokemonToFirstPlayAreaSlots
ScoopUpFromArena:
	ldh a, [hTempPlayAreaLocation_ffa1]
	ld e, a
; this eventually calls ClearAllArenaEffectsAndSubstatus
	call SwapArenaWithBenchPokemon

; after switching, scoop up the benched Pokémon as normal
	ldh a, [hTempPlayAreaLocation_ffa1]
	ldh [hTemp_ffa0], a
	call _ReturnBenchedPokemonToHandEffect

; if card was not played by Player, show detail screen
	call IsPlayerTurn
	ret c

	ldtx hl, PokemonWasReturnedFromArenaToHandText
	ldh a, [hTempCardIndex_ff98]
	bank1call DisplayCardDetailScreen
	ret


ScoopUpFromBench:
	call _ReturnBenchedPokemonToHandEffect

; if card was not played by Player, show detail screen
	call IsPlayerTurn
	ret c

	ldtx hl, PokemonWasReturnedFromBenchToHandText
	ldh a, [hTempCardIndex_ff98]
	bank1call DisplayCardDetailScreen
	ret


_ReturnBenchedPokemonToHandEffect:
; store chosen card location to Scoop Up
	ldh a, [hTemp_ffa0]
	or CARD_LOCATION_PLAY_AREA
	ld e, a

; find Pokémon cards that are in the selected Play Area location
; and add them to the hand, discarding all cards attached.
	ld a, DUELVARS_CARD_LOCATIONS
	call GetTurnDuelistVariable
.loop
	ld a, [hl]
	cp e
	jr nz, .next_card ; skip if not in selected location
	ld a, l
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_ENERGY
	jr nc, .next_card ; skip if not Pokemon card
	; ld a, [wLoadedCard2Stage]
	; or a
	; jr nz, .next_card  ; skip if not Basic stage
; found
	ld a, l
	ldh [hTempCardIndex_ff98], a
	call AddCardToHand
.next_card
	inc l
	ld a, l
	cp DECK_SIZE
	jr c, .loop

; The Pokémon has been moved to hand.
; MovePlayAreaCardToDiscardPile will discard other cards that were attached.
	ldh a, [hTemp_ffa0]
	ld e, a
	call MovePlayAreaCardToDiscardPile

; clear status from Pokémon location
; handled by EmptyPlayAreaSlot, called by MovePlayAreaCardToDiscardPile
;	ldh a, [hTemp_ffa0]
;	call ClearStatusFromTarget_NoAnim

; finally, shift Pokemon slots
	jp ShiftAllPokemonToFirstPlayAreaSlots


; return carry if no other cards in hand,
; or if there are no Pokemon cards in hand.
PokemonTrader_HandDeckCheck:
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	call GetTurnDuelistVariable
	ldtx hl, ThereAreNoCardsInHandThatYouCanChangeText
	cp 2
	ret c ; return if no other cards in hand
	call CreatePokemonCardListFromHand
	ldtx hl, ThereAreNoCardsInHandThatYouCanChangeText
	ret

PokemonTrader_PlayerHandSelection:
; print text box
	ldtx hl, ChooseCardFromYourHandToSwitchText
	call DrawWideTextBox_WaitForInput

; create list with all Pokemon cards in hand
	call CreatePokemonCardListFromHand
	bank1call InitAndDrawCardListScreenLayout_MenuTypeSelectCheck

; handle Player selection
	ldtx hl, ChooseCardToSwitchText
	ldtx de, DuelistHandText
	bank1call SetCardListHeaderText
	bank1call DisplayCardList
	call c, CancelSupporterCard
	ldh [hTemp_ffa0], a
	ret

PokemonTrader_PlayerDeckSelection:
; temporarily place chosen hand card in deck
; so it can be potentially chosen to be traded.
	ldh a, [hTemp_ffa0]
	call RemoveCardFromHand
	call ReturnCardToDeck

; display deck card list screen
	ldtx hl, ChooseBasicOrEvolutionPokemonCardFromDeckText
	call DrawWideTextBox_WaitForInput
	call CreateDeckCardList
	bank1call InitAndDrawCardListScreenLayout_MenuTypeSelectCheck
	ldtx hl, ChoosePokemonCardText
	ldtx de, DuelistDeckText
	bank1call SetCardListHeaderText

; handle Player selection
.read_input
	bank1call DisplayCardList
	jr c, .read_input ; pressing B loops back to selection
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_ENERGY
	jr nc, .read_input ; can't select non-Pokemon cards

; a valid card was selected, store its card index and
; place the selected hand card back to the hand.
	ldh a, [hTempCardIndex_ff98]
	ldh [hTempPlayAreaLocation_ffa1], a
	ldh a, [hTemp_ffa0]
	call SearchCardInDeckAndSetToJustDrawn
	call AddCardToHand
	or a
	ret

PokemonTrader_TradeCardsEffect:
; place hand card in deck
	ldh a, [hTemp_ffa0]
	call RemoveCardFromHand
	call ReturnCardToDeck

; place deck card in hand
	ldh a, [hTempPlayAreaLocation_ffa1]
	call SearchCardInDeckAndSetToJustDrawn
	call AddCardToHand

; display cards if the Pokemon Trader wasn't played by Player
	call IsPlayerTurn
	jr c, .done
	ldh a, [hTemp_ffa0]
	ldtx hl, PokemonWasReturnedToDeckText
	bank1call DisplayCardDetailScreen
	ldh a, [hTempPlayAreaLocation_ffa1]
	ldtx hl, WasPlacedInTheHandText
	bank1call DisplayCardDetailScreen
.done
	call SyncShuffleDeck
	ret

; makes list in wDuelTempList with all Pokemon cards
; that are in Turn Duelist's hand.
; if list turns out empty, return carry.
CreatePokemonCardListFromHand: ; 2f8b6 (b:78b6)
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	call GetTurnDuelistVariable
	ld c, a
	ld l, DUELVARS_HAND
	ld de, wDuelTempList
.loop
	ld a, [hl]
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_ENERGY
	jr nc, .next_hand_card
	ld a, [hl]
	ld [de], a
	inc de
.next_hand_card
	inc l
	dec c
	jr nz, .loop
	ld a, $ff ; terminating byte
	ld [de], a
	ld a, [wDuelTempList]
	cp $ff
	jr z, .set_carry
	or a
	ret
.set_carry
	scf
	ret


Pokedex_PlayerSelection:
; cap the number of cards to reorder up to
; number of cards left in the deck (maximum of 5)
; fill wDuelTempList with cards that are going to be sorted
	ld b, 5
	call CreateDeckCardListTopNCards
	inc a
	ld [wNumberOfCardsToOrder], a
; initialize safety variables
	ld a, $ff
	ldh [hTempList + 5], a  ; terminator for the sorting list
	ldh [hTempList + 6], a  ; placeholder for chosen Pokémon

; check if there are any Pokémon
	call CardSearch_FunctionTable.SearchDuelTempListForPokemon
	jr c, .no_pokemon

; print text box
	ldtx hl, ChooseBasicOrEvolutionPokemonCardFromDeckText
	call DrawWideTextBox_WaitForInput

; let the Player choose a Pokémon to add to the hand
	call _HandlePlayerSelectionPokemonFromDeck
	ldh [hTempList], a
	cp $ff
	jr z, .got_pkmn

; store chosen Pokémon
	ldh [hTempList + 6], a
; remove selected card from the ordering list
	call RemoveCardFromDuelTempList
	ld a, $ff
	ldh [hTempList], a  ; terminator for the sorting list
	ldh [hTempList + 1], a  ; terminator for the sorting list
	ld a, [wNumberOfCardsToOrder]
	dec a
	ld [wNumberOfCardsToOrder], a
; check if there was only the selected Pokémon
	dec a
	or a
	ret z
; check if there are still multiple cards to reorder
	cp 2
	jr nc, .got_pkmn
; there is only one more card, no need to reorder
	ld a, [wDuelTempList]
	ldh [hTempList], a
	; [hTempList + 1] already has terminator
	or a  ; remove carry flag
	ret

.got_pkmn
	call EmptyScreen

.no_pokemon
; print text box
	ldtx hl, RearrangeTheCardsAtTopOfDeckText
	call DrawWideTextBox_WaitForInput


.clear_list
	call InitializeListForReordering

; display card list to order
	bank1call InitAndDrawCardListScreenLayout
	ldtx hl, ChooseTheOrderOfTheCardsText
	ldtx de, DuelistDeckText
	bank1call SetCardListHeaderText
	bank1call Func_5735

.read_input
	bank1call DisplayCardList
	jr c, .undo ; if B is pressed, undo last order selection

; a card was selected, check if it's already been selected
	ldh a, [hCurMenuItem]
	ld e, a
	ld d, $00
	ld hl, wDuelTempList + 10
	add hl, de
	ld a, [hl]
	or a
	jr nz, .read_input ; already has an ordering number

; hasn't been ordered yet, apply to it current ordering number
; and increase it by 1.
	ldh a, [hCurSelectionItem]
	ld [hl], a
	inc a
	ldh [hCurSelectionItem], a

; refresh screen
	push af
	bank1call Func_5744
	pop af

; check if we're done ordering
	ldh a, [hCurSelectionItem]
	ld hl, wNumberOfCardsToOrder
	cp [hl]
	jr c, .read_input ; if still more cards to select, loop back up

; we're done selecting cards
	call EraseCursor
	ldtx hl, IsThisOKText
	call YesOrNoMenuWithText_LeftAligned
	jr c, .clear_list ; "No" was selected, start over
	; selection was confirmed

; now wDuelTempList + 10 will be overwritten with the
; card indices in order of selection.
	ld hl, wDuelTempList + 10
	ld de, wDuelTempList
	ld c, 0
.loop_write_indices
	ld a, [hli]
	cp $ff
	jr z, .done_write_indices
	push hl
	push bc
	ld c, a
	ld b, $00
	ld hl, hTempCardIndex_ff9f
	add hl, bc
	ld a, [de]
	ld [hl], a
	pop bc
	pop hl
	inc de
	inc c
	jr .loop_write_indices

.done_write_indices
	ld b, $00
	ld hl, hTempList
	add hl, bc
	ld [hl], $ff ; terminating byte
	or a
	ret

.undo
; undo last selection and get previous order number
	ld hl, hCurSelectionItem
	ld a, [hl]
	cp 1
	jr z, .read_input ; already at first input, nothing to undo
	dec a
	ld [hl], a
	ld c, a
	ld hl, wDuelTempList + 10
.asm_2f99e
	ld a, [hli]
	cp c
	jr nz, .asm_2f99e
	dec hl
	ld [hl], $00 ; overwrite order number with 0
	bank1call Func_5744
	jr .read_input


Pokedex_AddToHandAndOrderDeckCardsEffect:
	ldh a, [hTempList + 6]
	cp $ff
	jr z, Pokedex_OrderDeckCardsEffect  ; none chosen

; add Pokémon card to hand and show it on screen
	call AddCardToHand
	ldtx hl, WasPlacedInTheHandText
	bank1call DisplayCardDetailScreen
	; fallthrough

Pokedex_OrderDeckCardsEffect:
; place cards in order to the hand.
	ld hl, hTempList
	ld c, 0
.loop_place_hand
	ld a, [hli]
	cp $ff
	jr z, .place_top_deck
	call SearchCardInDeckAndSetToJustDrawn
	inc c
	jr .loop_place_hand

.place_top_deck
; go to last card in list and iterate in decreasing order
; placing each card in top of deck.
	dec hl
	dec hl
.loop_place_deck
	ld a, [hld]
	call ReturnCardToDeck
	dec c
	jr nz, .loop_place_deck
	ret


Draw2CardsEffect:
	ld a, 2
	bank1call DisplayDrawNCardsScreen
	ld c, 2
	jr Draw3CardsEffect.loop_draw

BillEffect:
Draw3CardsEffect:
	ld a, 3
	bank1call DisplayDrawNCardsScreen
	ld c, 3
.loop_draw
	call DrawCardFromDeck
	jr c, .done
	ldh [hTempCardIndex_ff98], a
	call AddCardToHand
	call IsPlayerTurn
	jr nc, .skip_display_screen
	push bc
	bank1call DisplayPlayerDrawCardScreen
	pop bc
.skip_display_screen
	dec c
	jr nz, .loop_draw
.done
	ret



PokeBall_PlayerSelection:
; OATS skip coin toss
; re-enabling coin requires changing [hTemp_ffa0] to [hTempList + 1] below
	; ld de, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	; call Serial_TossCoin
	; ldh [hTempList], a ; store coin result
	; ret nc

; create list of all Pokemon cards in deck to search for
	call CreateDeckCardList
	; ldtx hl, ChooseBasicOrEvolutionPokemonCardFromDeckText
	ldtx hl, ChooseBasicPokemonFromDeckText
	ldtx bc, BasicPokemonDeckText
	lb de, SEARCHEFFECT_BASIC_POKEMON, 0
	call LookForCardsInDeck
	jr c, .no_pkmn ; return if Player chose not to check deck

; handle input
	bank1call InitAndDrawCardListScreenLayout_MenuTypeSelectCheck
	ldtx hl, ChoosePokemonCardText
	ldtx de, DuelistDeckText
	bank1call SetCardListHeaderText
.read_input
	bank1call DisplayCardList
	jr c, .try_exit ; B was pressed, check if Player can cancel operation
	ldh a, [hTempCardIndex_ff98]
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_ENERGY
	jr nc, .play_sfx ; can't select non-Pokemon card
	ld a, [wLoadedCard2Stage]
	and a  ; cp BASIC
	jr nz, .play_sfx ; can't select non-Basic Pokemon card
	ldh a, [hTempCardIndex_ff98]
	; ldh [hTempList + 1], a
	ldh [hTemp_ffa0], a
	or a
	ret

.no_pkmn
	ld a, $ff
	; ldh [hTempList + 1], a
	ldh [hTemp_ffa0], a
	or a
	ret

.play_sfx
	call PlaySFX_InvalidChoice
	jr .read_input

.try_exit
; Player can only exit screen if there are no cards to choose
	ld hl, wDuelTempList
.loop
	ld a, [hli]
	cp $ff
	jr z, .no_pkmn
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_ENERGY
	jr nc, .loop  ; not a Pokémon
	ld a, [wLoadedCard2Stage]
	and a
	jr nz, .loop  ; not Basic
	jr .read_input


; return carry if no eligible cards in the Discard Pile
FishingTail_DiscardPileCheck:
Recycle_DiscardPileCheck:
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_DISCARD_PILE
	call GetTurnDuelistVariable
	ldtx hl, ThereAreNoCardsInTheDiscardPileText
	cp 1
	ret c
	call CreateDiscardPileCardList
	call RemoveTrainerCardsFromCardList
	call CountCardsInDuelTempList
	cp 1
	ldtx hl, ThereAreNoCardsInTheDiscardPileText
	ret


FishingTail_PlayerSelection:
Recycle_PlayerSelection:
; assume: wDuelTempList is initialized from Recycle_DiscardPileCheck
	; call CreateDiscardPileCardList
	; call RemoveTrainerCardsFromCardList
	bank1call InitAndDrawCardListScreenLayout_MenuTypeSelectCheck
	ldtx hl, PleaseSelectCardText
	ldtx de, PlayerDiscardPileText
	bank1call SetCardListHeaderText
.read_input
	bank1call DisplayCardList
	jr c, .read_input ; can't cancel with B button

; Discard Pile card was chosen
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	ret

FishingTail_AISelection:
; reuse the same logic as for Recycle
	farcall AIDecide_Recycle
	jr c, .got_card
	ld a, $ff
.got_card
	ldh [hTemp_ffa0], a
	or a
	ret


Recycle_AddToDeckEffect:
	ldh a, [hTemp_ffa0]
	cp $ff
	ret z ; return if no card was selected

; put card on top of the deck and show it on screen if
; it wasn't the Player who played the Trainer card.
	call MoveDiscardPileCardToHand
	call ReturnCardToDeck
	call IsPlayerTurn
	ret c
	ldh a, [hTemp_ffa0]
	ldtx hl, CardWasChosenText
	bank1call DisplayCardDetailScreen
	ret

; return carry if Bench is full or
; if no Basic Pokemon cards in Discard Pile.
Revive_BenchCheck: ; 2fb80 (b:7b80)
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ldtx hl, NoSpaceOnTheBenchText
	cp MAX_PLAY_AREA_POKEMON
	ccf
	ret c
	call CreateBasicPokemonCardListFromDiscardPile
	ldtx hl, ThereAreNoPokemonInDiscardPileText
	ret

Revive_PlayerSelection: ; 2fb93 (b:7b93)
; create Basic Pokemon card list from Discard Pile
	ldtx hl, ChooseBasicPokemonToPlaceOnBenchText
	call DrawWideTextBox_WaitForInput
	call CreateBasicPokemonCardListFromDiscardPile
	bank1call InitAndDrawCardListScreenLayout_MenuTypeSelectCheck

; display screen to select Pokemon
	ldtx hl, PleaseSelectCardText
	ldtx de, PlayerDiscardPileText
	bank1call SetCardListHeaderText
	bank1call DisplayCardList

; store selection
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	ret

Revive_PlaceInPlayAreaEffect: ; 2fbb0 (b:7bb0)
; place selected Pokemon in the Bench
	ldh a, [hTemp_ffa0]
	call MoveDiscardPileCardToHand
	call AddCardToHand
	call PutHandPokemonCardInPlayArea

; set HP to half, rounded up
; OATS no longer sets to half
;	add DUELVARS_ARENA_CARD_HP
;	call GetTurnDuelistVariable
;	srl a
;	bit 0, a
;	jr z, .rounded
;	add 5 ; round up HP to nearest 10
;.rounded
;	ld [hl], a
	call IsPlayerTurn
	ret c ; done if Player played Revive

; display card
	ldh a, [hTemp_ffa0]
	ldtx hl, PlacedOnTheBenchText
	bank1call DisplayCardDetailScreen
	ret

; return carry if Turn Duelist has no Evolution cards in Play Area
DevolutionSpray_PlayAreaEvolutionCheck: ; 2fc0b (b:7c0b)
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld c, a
	ld l, DUELVARS_ARENA_CARD
.loop
	ld a, [hli]
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Stage]
	or a
	ret nz ; found an Evolution card
	dec c
	jr nz, .loop

	ldtx hl, ThereAreNoStage1PokemonText
	scf
	ret

DevolutionSpray_PlayerSelection: ; 2fc24 (b:7c24)
; display textbox
	ldtx hl, ChooseEvolutionCardAndPressAButtonToDevolveText
	call DrawWideTextBox_WaitForInput

; have Player select an Evolution card in Play Area
	ld a, 1
	ldh [hCurSelectionItem], a
	bank1call HasAlivePokemonInPlayArea
.read_input
	bank1call OpenPlayAreaScreenForSelection
	ret c ; exit if B was pressed
	bank1call GetCardOneStageBelow
	jr c, .read_input ; can't select Basic cards

; get pre-evolution card data
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD_HP
	call GetTurnDuelistVariable
	push hl
	push af
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD_STAGE
	ld l, a
	ld a, [hl]
	push hl
	push af
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD
	ld l, a
	ld a, [hl]
	push hl
	push af
	jr .update_data

.repeat_devolution
; show Play Area screen with static cursor
; so that the Player either presses A to do one more devolution
; or presses B to finish selection.
	bank1call Func_6194
	jr c, .done_selection ; if B pressed, end selection instead
	; do one more devolution
	bank1call GetCardOneStageBelow

.update_data
; overwrite the card data to new devolved stats
	ld a, d
	call UpdateDevolvedCardHPAndStage
	call GetNextPositionInTempList
	ld [hl], e
	ld a, d
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Stage]
	or a
	jr nz, .repeat_devolution ; can do one more devolution

.done_selection
	call GetNextPositionInTempList
	ld [hl], $ff ; terminating byte

; store this Play Area location in first item of temp list
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTempList], a

; update Play Area location display of this Pokemon
	call EmptyScreen
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld hl, wHUDEnergyAndHPBarsX
	ld [hli], a
	ld [hl], $00
	bank1call PrintPlayAreaCardInformationAndLocation
	call EnableLCD
	pop bc
	pop hl

; rewrite all duelvars from before the selection was done
; this is so that if "No" is selected in confirmation menu,
; then the Pokemon isn't devolved and remains unchanged.
	ld [hl], b
	ldtx hl, IsThisOKText
	call YesOrNoMenuWithText
	pop bc
	pop hl

	ld [hl], b
	pop bc
	pop hl

	ld [hl], b
	ret

DevolutionSpray_DevolutionEffect: ; 2fc99 (b:7c99)
; first byte in list is Play Area location chosen
	ld hl, hTempList
	ld a, [hli]
	ldh [hTempPlayAreaLocation_ff9d], a
	add DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	push hl
	push af

; loop through devolutions selected
	ld hl, hTempList + 1
.loop_devolutions
	ld a, [hl]
	cp $ff
	jr z, .check_ko ; list is over
	; devolve card to its stage below
	push hl
	bank1call GetCardOneStageBelow
	ld a, d
	call UpdateDevolvedCardHPAndStage
	call ResetDevolvedCardStatus
	pop hl
	ld a, [hli]
	call PutCardInDiscardPile
	jr .loop_devolutions

.check_ko
	pop af
	ld e, a
	pop hl
	ld d, [hl]
	call PrintDevolvedCardNameAndLevelText
	ldh a, [hTempList]
	call PrintPlayAreaCardKnockedOutIfNoHP
	bank1call Func_6e49
	ret


ChooseUpTo3Cards_PlayerDiscardPileSelection:
	ld a, 3
	ld [wCardListNumberOfCardsToChoose], a
	jr ChooseUpToNCards_PlayerDiscardPileSelection

ChooseUpTo4Cards_PlayerDiscardPileSelection:
	ld a, 4
	ld [wCardListNumberOfCardsToChoose], a
	; jr ChooseUpToNCards_PlayerDiscardPileSelection
	; fallthrough

; number of cards is given in [wCardListNumberOfCardsToChoose]
ChooseUpToNCards_PlayerDiscardPileSelection:
	xor a
	ldh [hCurSelectionItem], a
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
	ld a, [wCardListNumberOfCardsToChoose]
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
	ld a, [wCardListNumberOfCardsToChoose]
	ld b, a
	ldh a, [hCurSelectionItem]
	cp b
	jr c, .loop_discard_pile_selection

.done
; insert terminating byte
	call GetNextPositionInTempList
	ld [hl], $ff
	or a
	ret

EnergyRecycler_ReturnToDeckEffect:
; return selected cards to the deck
	ld hl, hTempList
	ld de, wDuelTempList
.loop
	ld a, [hli]
	ld [de], a
	inc de
	cp $ff
	jr z, .done
	; this is kinda dumb and can probably be abbreviated
	call MoveDiscardPileCardToHand
	call AddCardToHand
	call RemoveCardFromHand
	call ReturnCardToDeck
	jr .loop

.done
	call SyncShuffleDeck
; if Player played the card, exit
	call IsPlayerTurn
	ret c
; if not, show card list selected by Opponent
	bank1call DisplayCardListDetails
	ret


; return carry if non-turn duelist has no benched Pokemon
Giovanni_BenchCheck: ; 2fe6e (b:7e6e)
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	ldtx hl, EffectNoPokemonOnTheBenchText
	cp 2
	ret

Giovanni_PlayerSelection: ; 2fe79 (b:7e79)
	ldtx hl, ChooseAPokemonToSwitchWithActivePokemonText
	call DrawWideTextBox_WaitForInput
	call SwapTurn
	bank1call HasAlivePokemonInBench
	bank1call OpenPlayAreaScreenForSelection
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	call SwapTurn
	call c, CancelSupporterCard
	ret

Giovanni_SwitchEffect: ; 2fe90 (b:7e90)
; play whirlwind animation
	ld a, ATK_ANIM_GUST_OF_WIND
	call PlayAttackAnimation_AdhocEffect

; switch Arena card
	call SwapTurn
	ldh a, [hTemp_ffa0]
	ld e, a
	call SwapArenaWithBenchPokemon
	call SwapTurn
	call ClearDamageReductionSubstatus2
	xor a
	ld [wDuelDisplayedScreen], a
	ret

; plays animation on turn holder's side (e.g. for play area animations)
; input:
;	  a: attack animation to play
; preserves: de
PlayAttackAnimation_AdhocEffect:
	ld [wLoadedAttackAnimation], a
	bank1call Func_7415
	ld bc, $0
	ldh a, [hWhoseTurn]
	ld h, a
	bank1call PlayAttackAnimation
	bank1call WaitAttackAnimation
	ret

CancelSupporterCard:
	push af  ; retain flags
	ld a, [wAlreadyPlayedEnergyOrSupporter]
	and ~PLAYED_SUPPORTER_THIS_TURN  ; clear this flag
	ld [wAlreadyPlayedEnergyOrSupporter], a
	pop af
	ret

; makes a list in wDuelTempList with the deck indices
; of energy cards found in Turn Duelist's Hand.
; if (c == 0), all energy cards are allowed;
; if (c != 0), double colorless energy cards are not included.
; returns carry if no energy cards were found.
Helper_CreateEnergyCardListFromHand:
	call CreateHandCardList
	ret c ; return if no hand cards

	ld hl, wDuelTempList
	ld e, l
	ld d, h
.loop_hand
	ld a, [hl]
	cp $ff
	jr z, .done
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	and TYPE_ENERGY
	jr z, .next_hand_card
; if (c != $00), then we dismiss Double Colorless energy cards found.
	ld a, c
	or a
	jr z, .copy
	ld a, [wLoadedCard2Type]
	cp TYPE_ENERGY_DOUBLE_COLORLESS
	jr nc, .next_hand_card
.copy
	ld a, [hl]
	ld [de], a
	inc de
.next_hand_card
	inc hl
	jr .loop_hand

.done
	ld a, $ff ; terminating byte
	ld [de], a
	ld a, [wDuelTempList]
	cp $ff
	scf
	ret z ; return carry if empty
	; not empty
	or a
	ret


Helper_ChooseAPokemonInPlayArea_EmptyScreen:
	call EmptyScreen
Helper_ChooseAPokemonInPlayArea:
	ldtx hl, ChoosePokemonToAttachEnergyCardText
	call DrawWideTextBox_WaitForInput
; choose a Pokemon in Play Area
	bank1call HasAlivePokemonInPlayArea
.loop_play_area_input
	bank1call OpenPlayAreaScreenForSelection
	jr c, .loop_play_area_input
	ldh a, [hTempPlayAreaLocation_ff9d]
	; ldh [hTempPlayAreaLocation_ffa1], a
	; using hTempPlayAreaLocation_ffa1 invalidates the use of hTempList
	ret

Helper_ShowAttachedEnergyToPokemon:
; show detail screen and which Pokemon was chosen to attach Energy
	ldh a, [hTempPlayAreaLocation_ffa1]
	add DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer1_FromDeckIndex
	ld hl, wLoadedCard1Name
	ld de, wTxRam2_b
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	ldh a, [hTemp_ffa0]
	ldtx hl, AttachedEnergyToPokemonText
	bank1call DisplayCardDetailScreen
	ret

Helper_GenericShowAttachedEnergyToPokemon:
; show detail screen and which Pokemon was chosen to attach Energy
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	ld c, a  ; deck index of Pokémon card
	call LoadCardDataToBuffer1_FromDeckIndex
	ld hl, wLoadedCard1Name
	ld de, wTxRam2
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	ld a, c
	ldtx hl, GenericAttachedEnergyToPokemonText
	bank1call DisplayCardDetailScreen
	ret
