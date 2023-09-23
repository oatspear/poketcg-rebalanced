; AI logic used by general decks
AIActionTable_GeneralDecks:
	dw .do_turn ; unused
	dw .do_turn
	dw .start_duel
	dw .forced_switch
	dw .ko_switch
	dw .take_prize

.do_turn
	call AIMainTurnLogic
	ret

.start_duel
	call InitAIDuelVars
	call AIPlayInitialBasicCards
	ret

.forced_switch
	call AIDecideBenchPokemonToSwitchTo
	ret

.ko_switch
	call AIDecideBenchPokemonToSwitchTo
	ret

.take_prize:
	call AIPickPrizeCards
	ret

; handle AI routines for a whole turn
AIMainTurnLogic:
IF DEBUG_MODE
	ldtx hl, CaterpieName
	call DrawWideTextBox_WaitForInput
ENDC
; initialize variables
	call InitAITurnVars
IF DEBUG_MODE
	ldtx hl, MetapodName
	call DrawWideTextBox_WaitForInput
ENDC

	ld a, AI_TRAINER_CARD_PHASE_01
	call AIProcessHandTrainerCards
IF DEBUG_MODE
	ldtx hl, ButterfreeName
	call DrawWideTextBox_WaitForInput
ENDC

	farcall HandleAIAntiMewtwoDeckStrategy
IF DEBUG_MODE
	ldtx hl, WeedleName
	call DrawWideTextBox_WaitForInput
ENDC
	jp nc, .try_attack
IF DEBUG_MODE
	ldtx hl, KakunaName
	call DrawWideTextBox_WaitForInput
ENDC

; handle Pkmn Powers
	farcall HandleAIRainDanceEnergy
IF DEBUG_MODE
	ldtx hl, BeedrillName
	call DrawWideTextBox_WaitForInput
ENDC

	farcall HandleAIFirestarterEnergy
IF DEBUG_MODE
	ldtx hl, ScytherName
	call DrawWideTextBox_WaitForInput
ENDC

	; farcall HandleAIDamageSwap
IF DEBUG_MODE
	ldtx hl, PinsirName
	call DrawWideTextBox_WaitForInput
ENDC

	farcall HandleAIPkmnPowers
	ret c ; return if turn ended
IF DEBUG_MODE
	ldtx hl, ElectabuzzName
	call DrawWideTextBox_WaitForInput
ENDC

	farcall HandleAICowardice
IF DEBUG_MODE
	ldtx hl, FarfetchdName
	call DrawWideTextBox_WaitForInput
ENDC

; process Trainer cards
; phase 2 through 4.
	ld a, AI_TRAINER_CARD_PHASE_02
	call AIProcessHandTrainerCards
IF DEBUG_MODE
	ldtx hl, JynxName
	call DrawWideTextBox_WaitForInput
ENDC

	ld a, AI_TRAINER_CARD_PHASE_03
	call AIProcessHandTrainerCards
IF DEBUG_MODE
	ldtx hl, HorseaName
	call DrawWideTextBox_WaitForInput
ENDC

	ld a, AI_TRAINER_CARD_PHASE_04
	call AIProcessHandTrainerCards

; play Pokemon from hand
IF DEBUG_MODE
	ldtx hl, SeadraName
	call DrawWideTextBox_WaitForInput
ENDC
	call AIDecidePlayPokemonCard
	ret c ; return if turn ended

; process Trainer cards
IF DEBUG_MODE
	ldtx hl, LaprasName
	call DrawWideTextBox_WaitForInput
ENDC
; phase 5 through 12.
	ld a, AI_TRAINER_CARD_PHASE_05
	call AIProcessHandTrainerCards
IF DEBUG_MODE
	ldtx hl, CombustionName
	call DrawWideTextBox_WaitForInput
ENDC

	ld a, AI_TRAINER_CARD_PHASE_06
	call AIProcessHandTrainerCards
IF DEBUG_MODE
	ldtx hl, DreamEaterName
	call DrawWideTextBox_WaitForInput
ENDC

	ld a, AI_TRAINER_CARD_PHASE_07
	call AIProcessHandTrainerCards
IF DEBUG_MODE
	ldtx hl, PsychicName
	call DrawWideTextBox_WaitForInput
ENDC

	ld a, AI_TRAINER_CARD_PHASE_08
	call AIProcessHandTrainerCards
IF DEBUG_MODE
	ldtx hl, MewtwoName
	call DrawWideTextBox_WaitForInput
ENDC

	call AIProcessRetreat
IF DEBUG_MODE
	ldtx hl, DodrioName
	call DrawWideTextBox_WaitForInput
ENDC

	ld a, AI_TRAINER_CARD_PHASE_10
	call AIProcessHandTrainerCards
IF DEBUG_MODE
	ldtx hl, EmberName
	call DrawWideTextBox_WaitForInput
ENDC

	ld a, AI_TRAINER_CARD_PHASE_11
	call AIProcessHandTrainerCards
IF DEBUG_MODE
	ldtx hl, WaterGunName
	call DrawWideTextBox_WaitForInput
ENDC

	ld a, AI_TRAINER_CARD_PHASE_12
	call AIProcessHandTrainerCards
IF DEBUG_MODE
	ldtx hl, ThundershockName
	call DrawWideTextBox_WaitForInput
ENDC

; play Energy card if possible
	ld a, [wAlreadyPlayedEnergyOrSupporter]
	and PLAYED_ENERGY_THIS_TURN  ; or a
	jr nz, .skip_energy_attach_1
IF DEBUG_MODE
	ldtx hl, DratiniName
	call DrawWideTextBox_WaitForInput
ENDC

	call AIProcessAndTryToPlayEnergy
IF DEBUG_MODE
	ldtx hl, DragonDanceName
	call DrawWideTextBox_WaitForInput
ENDC
.skip_energy_attach_1

; play Pokemon from hand again
	call AIDecidePlayPokemonCard
IF DEBUG_MODE
	ldtx hl, MrMimeName
	call DrawWideTextBox_WaitForInput
ENDC

; handle Pkmn Powers again
	; farcall HandleAIDamageSwap
IF DEBUG_MODE
	ldtx hl, JolteonName
	call DrawWideTextBox_WaitForInput
ENDC

	farcall HandleAIPkmnPowers
	ret c ; return if turn ended
IF DEBUG_MODE
	ldtx hl, CharmeleonName
	call DrawWideTextBox_WaitForInput
ENDC

	farcall HandleAIFirestarterEnergy
IF DEBUG_MODE
	ldtx hl, WartortleName
	call DrawWideTextBox_WaitForInput
ENDC

	farcall HandleAIRainDanceEnergy
IF DEBUG_MODE
	ldtx hl, IvysaurName
	call DrawWideTextBox_WaitForInput
ENDC

	ld a, AI_ENERGY_TRANS_ATTACK
	farcall HandleAIEnergyTrans
IF DEBUG_MODE
	ldtx hl, PikachuName
	call DrawWideTextBox_WaitForInput
ENDC

; process Trainer cards phases 13 and 15
	ld a, AI_TRAINER_CARD_PHASE_13
	call AIProcessHandTrainerCards
IF DEBUG_MODE
	ldtx hl, RaichuName
	call DrawWideTextBox_WaitForInput
ENDC

	ld a, AI_TRAINER_CARD_PHASE_15
	call AIProcessHandTrainerCards
IF DEBUG_MODE
	ldtx hl, PorygonName
	call DrawWideTextBox_WaitForInput
ENDC
; if used Professor Oak, process new hand
; if not, then proceed to attack.
	ld a, [wPreviousAIFlags]
	and AI_FLAG_USED_PROFESSOR_OAK
IF DEBUG_MODE
	jp z, .try_attack
ELSE
	jr z, .try_attack
ENDC

IF DEBUG_MODE
	ldtx hl, MeowthName
	call DrawWideTextBox_WaitForInput
ENDC
	ld a, AI_TRAINER_CARD_PHASE_01
	call AIProcessHandTrainerCards
IF DEBUG_MODE
	ldtx hl, PersianName
	call DrawWideTextBox_WaitForInput
ENDC

	ld a, AI_TRAINER_CARD_PHASE_02
	call AIProcessHandTrainerCards
IF DEBUG_MODE
	ldtx hl, EeveeName
	call DrawWideTextBox_WaitForInput
ENDC

	ld a, AI_TRAINER_CARD_PHASE_03
	call AIProcessHandTrainerCards
IF DEBUG_MODE
	ldtx hl, FlareonName
	call DrawWideTextBox_WaitForInput
ENDC

	ld a, AI_TRAINER_CARD_PHASE_04
	call AIProcessHandTrainerCards
IF DEBUG_MODE
	ldtx hl, VaporeonName
	call DrawWideTextBox_WaitForInput
ENDC

	call AIDecidePlayPokemonCard
	ret c ; return if turn ended
IF DEBUG_MODE
	ldtx hl, ChanseyName
	call DrawWideTextBox_WaitForInput
ENDC

	ld a, AI_TRAINER_CARD_PHASE_05
	call AIProcessHandTrainerCards
IF DEBUG_MODE
	ldtx hl, DragonairName
	call DrawWideTextBox_WaitForInput
ENDC

	ld a, AI_TRAINER_CARD_PHASE_06
	call AIProcessHandTrainerCards
IF DEBUG_MODE
	ldtx hl, DragoniteName
	call DrawWideTextBox_WaitForInput
ENDC

	ld a, AI_TRAINER_CARD_PHASE_07
	call AIProcessHandTrainerCards
IF DEBUG_MODE
	ldtx hl, AbraName
	call DrawWideTextBox_WaitForInput
ENDC

	ld a, AI_TRAINER_CARD_PHASE_08
	call AIProcessHandTrainerCards
IF DEBUG_MODE
	ldtx hl, KadabraName
	call DrawWideTextBox_WaitForInput
ENDC

	call AIProcessRetreat
IF DEBUG_MODE
	ldtx hl, AlakazamName
	call DrawWideTextBox_WaitForInput
ENDC

	ld a, AI_TRAINER_CARD_PHASE_10
	call AIProcessHandTrainerCards
IF DEBUG_MODE
	ldtx hl, DrowzeeName
	call DrawWideTextBox_WaitForInput
ENDC

	ld a, AI_TRAINER_CARD_PHASE_11
	call AIProcessHandTrainerCards
IF DEBUG_MODE
	ldtx hl, HypnoName
	call DrawWideTextBox_WaitForInput
ENDC

	ld a, AI_TRAINER_CARD_PHASE_12
	call AIProcessHandTrainerCards
IF DEBUG_MODE
	ldtx hl, RazorLeafName
	call DrawWideTextBox_WaitForInput
ENDC

	ld a, [wAlreadyPlayedEnergyOrSupporter]
	and PLAYED_ENERGY_THIS_TURN  ; or a
	jr nz, .skip_energy_attach_2
IF DEBUG_MODE
	ldtx hl, VineWhipName
	call DrawWideTextBox_WaitForInput
ENDC
	call AIProcessAndTryToPlayEnergy
IF DEBUG_MODE
	ldtx hl, BellsproutName
	call DrawWideTextBox_WaitForInput
ENDC
.skip_energy_attach_2
IF DEBUG_MODE
	ldtx hl, WeepinbellName
	call DrawWideTextBox_WaitForInput
ENDC
	call AIDecidePlayPokemonCard
IF DEBUG_MODE
	ldtx hl, VictreebelName
	call DrawWideTextBox_WaitForInput
ENDC

	; farcall HandleAIDamageSwap
IF DEBUG_MODE
	ldtx hl, OddishName
	call DrawWideTextBox_WaitForInput
ENDC

	farcall HandleAIPkmnPowers
	ret c ; return if turn ended
IF DEBUG_MODE
	ldtx hl, GloomName
	call DrawWideTextBox_WaitForInput
ENDC

	farcall HandleAIRainDanceEnergy
IF DEBUG_MODE
	ldtx hl, VileplumeName
	call DrawWideTextBox_WaitForInput
ENDC

	ld a, AI_ENERGY_TRANS_ATTACK
	farcall HandleAIEnergyTrans
IF DEBUG_MODE
	ldtx hl, CuboneName
	call DrawWideTextBox_WaitForInput
ENDC

	ld a, AI_TRAINER_CARD_PHASE_13
	call AIProcessHandTrainerCards
IF DEBUG_MODE
	ldtx hl, MarowakName
	call DrawWideTextBox_WaitForInput
ENDC
	; skip AI_TRAINER_CARD_PHASE_15
.try_attack
	ld a, AI_ENERGY_TRANS_TO_BENCH
	farcall HandleAIEnergyTrans
IF DEBUG_MODE
	ldtx hl, KangaskhanName
	call DrawWideTextBox_WaitForInput
ENDC
; attack if possible, if not,
; finish turn without attacking.
	call AIProcessAndTryToUseAttack
	ret c ; return if AI attacked
IF DEBUG_MODE
	ldtx hl, PidgeyName
	call DrawWideTextBox_WaitForInput
ENDC
	ld a, OPPACTION_FINISH_NO_ATTACK
	bank1call AIMakeDecision
IF DEBUG_MODE
	ldtx hl, PidgeottoName
	call DrawWideTextBox_WaitForInput
ENDC
	ret

; handles AI retreating logic
AIProcessRetreat:
	ld a, [wAlreadyRetreatedThisTurn]
	or a
	ret nz ; return, already retreated this turn

	call AIDecideWhetherToRetreat
	ret nc ; return if not retreating

	call AIDecideBenchPokemonToSwitchTo
	ret c ; return if no Bench Pokemon

; store Play Area to retreat to and
; set wAlreadyRetreatedThisTurn to true
	ld [wAIPlayAreaCardToSwitch], a
	ld a, $01
	ld [wAlreadyRetreatedThisTurn], a

; if AI can use Switch from hand, use it instead...
	ld a, AI_TRAINER_CARD_PHASE_09
	call AIProcessHandTrainerCards
	ld a, [wPreviousAIFlags]
	and AI_FLAG_USED_SWITCH
	jr nz, .used_switch
; ... else try Energy Transfer to help retreating normally.
	ld a, AI_ENERGY_TRANS_RETREAT ; retreat
	farcall HandleAIEnergyTrans
	ld a, [wAIPlayAreaCardToSwitch]
	call AITryToRetreat
	ret

.used_switch
; if AI used switch, unset its AI flag
	ld a, [wPreviousAIFlags]
	and ~AI_FLAG_USED_SWITCH ; clear Switch flag
	ld [wPreviousAIFlags], a
	ret
