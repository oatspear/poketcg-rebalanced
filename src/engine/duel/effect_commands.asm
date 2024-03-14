EffectCommands: ; 186f7 (6:46f7)
; Each attack has a two-byte effect pointer (attack's 7th param) that points to one of these structures.
; Similarly, trainer cards have a two-byte pointer (7th param) to one of these structures, which determines the card's function.
; Energy cards also point to one of these, but their data is just $00.
;	db EFFECTCMDTYPE_* ($01 - $0a)
;	dw Function
;	...
;	db $00


; Commands are associated to a time or a scope (EFFECTCMDTYPE_*) that determines when their function is executed during the turn.
; - EFFECTCMDTYPE_INITIAL_EFFECT_1: Executed right after attack or trainer card is used. Bypasses Accuracy effects.
; - EFFECTCMDTYPE_INITIAL_EFFECT_2: Executed right after attack, Pokemon Power, or trainer card is used.
; - EFFECTCMDTYPE_DISCARD_ENERGY: For attacks or trainer cards that require putting one or more attached energy cards into the discard pile.
; - EFFECTCMDTYPE_REQUIRE_SELECTION: For attacks, Pokemon Powers, or trainer cards requiring the user to select a card (from e.g. play area screen or card list).
; - EFFECTCMDTYPE_BEFORE_DAMAGE: Effect command of an attack executed prior to the damage step. For trainer card or Pokemon Power, usually the main effect.
; - EFFECTCMDTYPE_AFTER_DAMAGE: Effect command executed after the damage step.
; - EFFECTCMDTYPE_INTERACTIVE_STEP: Effect command executed interactively during link battles or in multi-step menus.
; - EFFECTCMDTYPE_AI_SWITCH_DEFENDING_PKMN: For attacks that may result in the defending Pokemon being switched out. Called only for AI-executed attacks.
; - EFFECTCMDTYPE_PKMN_POWER_TRIGGER: Pokemon Power effects that trigger the moment the Pokemon card is played.
; - EFFECTCMDTYPE_AI: Used for AI scoring.
; - EFFECTCMDTYPE_AI_SELECTION: When AI is required to select a card

; NOTE: EFFECTCMDTYPE_INITIAL_EFFECT_2 in ATTACKS is not executed by AI.
; NOTE: EFFECTCMDTYPE_INITIAL_EFFECT_1 in POWERS is only used to determine if
;       the ability is passive. The error message is always the same.
;       Use EFFECTCMDTYPE_INITIAL_EFFECT_2 for precondition checks.

; Attacks that have an EFFECTCMDTYPE_REQUIRE_SELECTION also must have either an EFFECTCMDTYPE_AI_SWITCH_DEFENDING_PKMN or an
; EFFECTCMDTYPE_AI_SELECTION (for anything not involving switching the defending Pokemon), to handle selections involving the AI.

; Similar attack effects of different Pokemon cards all point to a different command list,
; even though in some cases their commands and function pointers match.


PassivePowerEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, PassivePowerEffect
	db  $00

InflictPoisonEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PoisonEffect
	; dbw EFFECTCMDTYPE_AI, PoisonFang_AIEffect
	db  $00

PoisonPaybackEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PoisonPaybackEffect
	dbw EFFECTCMDTYPE_AI, DoubleDamageIfUserIsDamaged_AIEffect
	db  $00

StressPheromonesEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, StressPheromones_PreconditionCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, StressPheromones_AddToHandEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, StressPheromones_PlayerSelectEffect
	db  $00

PrimalHuntEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, SelectedCard_AddToHandFromDeckEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, ChoosePokemonFromDeck_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, ChoosePokemonFromDeck_AISelectEffect
	db  $00

LureEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Lure_AssertPokemonInBench
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Lure_SwitchAndTrapDefendingPokemon
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Lure_SelectSwitchPokemon
	dbw EFFECTCMDTYPE_AI_SELECTION, Lure_GetOpponentBenchPokemonWithLowestHP
	db  $00

PoisonLureEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Lure_AssertPokemonInBench
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, PoisonLure_SwitchEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Lure_SelectSwitchPokemon
	dbw EFFECTCMDTYPE_AI_SELECTION, Lure_GetOpponentBenchPokemonWithLowestHP
	db  $00

; AcidEffectCommands:
; 	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, UnableToRetreatEffect
; 	db  $00

ConstrictEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Constrict_TrapDamageBoostEffect
	dbw EFFECTCMDTYPE_AI, Constrict_AIEffect
	db  $00

PanicVineEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PanicVine_ConfusionTrapEffect
	db  $00

FlytrapEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, UnableToRetreatEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Leech20DamageEffect
	db  $00

SproutEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckDeckIsNotEmpty
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, SelectedCard_AddToHandFromDeckEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Sprout_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, Sprout_AISelectEffect
	db  $00

UltravisionEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckDeckIsNotEmpty
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, SelectedCard_AddToHandFromDeckEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Ultravision_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, Ultravision_AISelectEffect
	db  $00

FoulOdorEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, FoulOdorEffect
	db  $00

LeechLifeEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, LeechLifeEffect
	db  $00

AscensionEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckDeckIsNotEmpty
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Ascension_EvolveEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Ascension_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, Ascension_AISelectEffect
	db  $00

HatchEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckDeckIsNotEmpty
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Hatch_EvolveEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Hatch_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, Hatch_AISelectEffect
	db  $00

PoisonEvolutionEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckDeckIsNotEmpty
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PoisonEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, PoisonEvolution_EvolveEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, PoisonEvolution_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, PoisonEvolution_AISelectEffect
	db  $00

FoulGasEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, FoulGas_PoisonOrConfusionEffect
	db  $00

DefensiveStanceEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckBenchIsNotEmpty
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Heal20DamageEffect_PreserveAttackAnimation
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, SwitchUser_SwitchEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, SwitchUser_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, SwitchUser_AISelectEffect
	db  $00

DeepDiveEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckBenchIsNotEmpty
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Heal30DamageEffect_PreserveAttackAnimation
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, SwitchUser_SwitchEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, SwitchUser_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, SwitchUser_AISelectEffect
	db  $00

TeleportEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckBenchIsNotEmpty
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Teleport_ReturnToDeckEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Teleport_PlayerSelectEffect
	db  $00

StealthPoisonEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PoisonEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, SwitchUser_SwitchEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, SwitchUser_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, SwitchUser_AISelectEffect
	db  $00

OldTeleportEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckBenchIsNotEmpty
	; fallthrough
SwitchUserEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, SwitchUser_SwitchEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, SwitchUser_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, SwitchUser_AISelectEffect
	db  $00

RapidSpinEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, RapidSpin_SwitchEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, RapidSpin_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, RapidSpin_AISelectEffect
	db  $00

EggsplosionEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Eggsplosion_MultiplierEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Eggsplosion_HealEffect
	dbw EFFECTCMDTYPE_AI, Eggsplosion_AIEffect
	db  $00

DamagePerEnergyAttachedToBothActiveEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DamagePerEnergyAttachedToBothActive_MultiplierEffect
	dbw EFFECTCMDTYPE_AI, DamagePerEnergyAttachedToBothActive_AIEffect
	db  $00

TropicalStormEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, TropicalStorm_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, TropicalStorm_AIEffect
	db  $00

RoutEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Rout_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, Rout_AIEffect
	db  $00

TerrorStrikeEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, TerrorStrike_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, TerrorStrike_AIEffect
	db  $00

ToxicEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DoublePoisonEffect
	; dbw EFFECTCMDTYPE_AI, Toxic_AIEffect
	db  $00

GrassKnotEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, GrassKnot_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, GrassKnot_AIEffect
	db  $00

DoubleDamageIfMorePrizesEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DoubleDamageIfMorePrizes_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, DoubleDamageIfMorePrizes_AIEffect
	db  $00

PrimalThunderEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, PrimalThunder_DrawbackEffect
	db  $00

ChopDownEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, ChopDown_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, ChopDown_AIEffect
	db  $00

CrabhammerEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Crabhammer_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, Crabhammer_AIEffect
	db  $00

SharpSickleEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SharpSickle_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, SharpSickle_AIEffect
	db  $00

PowerLariatEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PowerLariat_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, PowerLariat_AIEffect
	db  $00

VengefulHornEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, VengefulHorn_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, VengefulHorn_AIEffect
	db  $00

FamilyPowerEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, FamilyPower_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, FamilyPower_AIEffect
	db  $00

RetaliateEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckArenaPokemonHasAnyDamage
	db  $00

FinishingBiteEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckOpponentArenaPokemonHasAnyDamage
	db  $00

AssassinFlightEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, AssassinFlight_CheckBenchAndStatus
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Deal40DamageToTarget_DamageEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, DamageTargetBenchedPokemon_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, DamageTargetBenchedPokemon_AISelectEffect
	db  $00

TwineedleEffectCommands:
DoubleAttackX20X10EffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DoubleAttackX20X10_MultiplierEffect
	dbw EFFECTCMDTYPE_AI, DoubleAttackX20X10_AIEffect
	db  $00

Leech10DamageEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Leech10DamageEffect
	db  $00

Leech20DamageEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Leech20DamageEffect
	db  $00

Leech30DamageEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Leech30DamageEffect
	db  $00

Poison50PercentEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Poison50PercentEffect
	db  $00

EnergyTransEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, EnergyTrans_CheckPlayArea
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, EnergyTrans_TransferEffect
	dbw EFFECTCMDTYPE_INTERACTIVE_STEP, EnergyTrans_AIEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, EnergyTrans_PrintProcedure
	db  $00

EnergySoakEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, CheckPokemonPowerCanBeUsed
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, EnergySoak_ChangeColorEffect
	db  $00

EnergyJoltEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, CheckPokemonPowerCanBeUsed
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, EnergyJolt_ChangeColorEffect
	db  $00

EnergyBurnEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, CheckPokemonPowerCanBeUsed
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, EnergyBurn_ChangeColorEffect
	db  $00

ShiftEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Shift_OncePerTurnCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Shift_ChangeColorEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Shift_PlayerSelectEffect
	db  $00

VenomPowderEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, VenomPowder_PoisonConfusionEffect
	; dbw EFFECTCMDTYPE_AI, VenomPowder_AIEffect
	db  $00

JellyfishStingEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, JellyfishSting_PoisonConfusionEffect
	db  $00

PokemonPowerHealEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Heal_OncePerTurnCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Heal_RemoveDamageEffect
	db  $00

PetalDanceEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, PetalDance_BonusEffect
	db  $00

PollenFrenzyEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PollenFrenzy_Status50PercentEffect
	db  $00

RainbowTeamEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, RainbowTeam_OncePerTurnCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, RainbowTeam_AttachEnergyEffect
	db  $00

CrushingChargeEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, CrushingCharge_PreconditionCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, CrushingCharge_DiscardAndAttachEnergyEffect
	db  $00

FirestarterEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Firestarter_OncePerTurnCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Firestarter_AttachEnergyEffect
	db  $00

LightningHasteEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, LightningHaste_OncePerTurnCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, LightningHaste_AttachEnergyEffect
	db  $00

HelpingHandEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, HelpingHand_CheckUse
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, HelpingHand_RemoveStatusEffect
	db  $00

RestEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Rest_HealEffect
	db  $00

; SongOfRestEffectCommands:
; 	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, SongOfRest_CheckUse
; 	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SongOfRest_HealEffect
; 	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, SongOfRest_PlayerSelectEffect
; 	db  $00

HydroPumpEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, HydroPumpEffect
	dbw EFFECTCMDTYPE_AI, HydroPumpEffect
	db  $00

FlailEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Flail_HPCheck
	dbw EFFECTCMDTYPE_AI, Flail_AIEffect
	db  $00

HeadacheEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, HeadacheEffect
	db  $00

ReduceDamageTakenBy20EffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, ReduceDamageTakenBy20Effect
	db  $00

SandAttackEffectCommands:
SmokescreenEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, ReduceAccuracyEffect
	db  $00

IncreaseRetreatCostEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, IncreaseRetreatCostEffect
	db  $00

SupersonicEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SupersonicEffect
	db  $00

AmnesiaEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Amnesia_CheckAttacks
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Amnesia_PlayerSelectEffect
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Amnesia_DisableEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, Amnesia_AISelectEffect
	db  $00

Paralysis50PercentEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Paralysis50PercentEffect
	db  $00

ParalysisIfDiscardedEnergyEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, OptionalDiscardEnergy_PlayerSelectEffect
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, ParalysisIfSelectedCardEffect
	dbw EFFECTCMDTYPE_DISCARD_ENERGY, DiscardEnergy_DiscardEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, OptionalDiscardEnergyForStatus_AISelectEffect
	db  $00

BindEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, ParalysisIfBasicEffect
	db  $00

CowardiceEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Cowardice_Check
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Cowardice_RemoveFromPlayAreaEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Cowardice_PlayerSelectEffect
	db  $00

AdaptiveEvolutionEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, PassivePowerEffect
	dbw EFFECTCMDTYPE_PKMN_POWER_TRIGGER, AdaptiveEvolution_AllowEvolutionEffect
	db  $00

SilverWhirlwindEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SleepOrPoisonEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Whirlwind_SwitchEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Whirlwind_SelectEffect
	dbw EFFECTCMDTYPE_AI_SWITCH_DEFENDING_PKMN, Whirlwind_SelectEffect
	db  $00

ArticunoQuickfreezeEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Quickfreeze_InitialEffect
	dbw EFFECTCMDTYPE_PKMN_POWER_TRIGGER, Quickfreeze_Paralysis50PercentEffect
	db  $00

FocusEnergyEffectCommands:
SwordsDanceEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, FocusEnergyEffect
	db  $00

OptionalDoubleDamageEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DoubleDamageIfCondition_DamageBoostEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, OptionalDoubleDamage_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, OptionalDoubleDamage_AISelectEffect
	dbw EFFECTCMDTYPE_AI, DoubleDamageIfCondition_AIEffect
	; fallthrough

NextTurnUnableToAttackEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, NextTurnUnableToAttackEffect
	db  $00

Recoil10EffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Recoil10Effect
	db  $00

Recoil20EffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Recoil20Effect
	db  $00

Recoil30EffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Recoil30Effect
	db  $00

Recoil40EffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Recoil40Effect
	db  $00

Recoil50EffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Recoil50Effect
	db  $00

Recoil30UnlessActiveThisTurnEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Recoil30UnlessActiveThisTurnEffect
	db  $00

QuickAttack10EffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, IfActiveThisTurn10BonusDamage_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, IfActiveThisTurn10BonusDamage_AIEffect
	db  $00

QuickAttack20EffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, IfActiveThisTurn20BonusDamage_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, IfActiveThisTurn20BonusDamage_AIEffect
	db  $00

QuickAttack30EffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, IfActiveThisTurn30BonusDamage_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, IfActiveThisTurn30BonusDamage_AIEffect
	db  $00

OutrageEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckArenaPokemonHasAnyEnergiesAttached
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, DiscardEnergy_PlayerSelectEffect
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Rage_DamageBoostEffect
	dbw EFFECTCMDTYPE_DISCARD_ENERGY, DiscardEnergy_DiscardEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, DiscardEnergy_AISelectEffect
	dbw EFFECTCMDTYPE_AI, Rage_AIEffect
	db  $00

Discard1EnergyEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckArenaPokemonHasAnyEnergiesAttached
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, DiscardEnergy_PlayerSelectEffect
	dbw EFFECTCMDTYPE_DISCARD_ENERGY, DiscardEnergy_DiscardEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, DiscardEnergy_AISelectEffect
	db  $00

WildfireEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Wildfire_CheckEnergy
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Wildfire_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Wildfire_DiscardDeckEffect
	dbw EFFECTCMDTYPE_DISCARD_ENERGY, Wildfire_DiscardEnergyEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, Wildfire_AISelectEffect
	db  $00

Discard2EnergiesEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Check2EnergiesAttached
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Discard2Energies_PlayerSelectEffect
	dbw EFFECTCMDTYPE_DISCARD_ENERGY, Discard2Energies_DiscardEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, Discard2Energies_AISelectEffect
	db  $00

Discard1EnergyFromOpponentEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, DiscardOpponentEnergy_DiscardEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, DiscardOpponentEnergy_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, DiscardOpponentEnergy_AISelectEffect
	db  $00

; EFFECTCMDTYPE_AI_SWITCH_DEFENDING_PKMN runs after EFFECTCMDTYPE_DISCARD_ENERGY,
; but before EFFECTCMDTYPE_BEFORE_DAMAGE
Discard1EnergyFromBothActiveEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckArenaPokemonHasAnyEnergiesAttached
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, DiscardEnergy_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, DiscardEnergy_AISelectEffect
	dbw EFFECTCMDTYPE_DISCARD_ENERGY, DiscardEnergy_DiscardEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, DiscardOpponentEnergy_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SWITCH_DEFENDING_PKMN, DiscardOpponentEnergy_AISelectEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, DiscardOpponentEnergy_DiscardEffect
	db  $00

Bounce1EnergyEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckArenaPokemonHasAnyEnergiesAttached
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, DiscardEnergy_PlayerSelectEffect
	dbw EFFECTCMDTYPE_DISCARD_ENERGY, BounceEnergy_BounceEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, DiscardEnergy_AISelectEffect
	db  $00

FirePunchEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, FirePunch_PlayerSelectEffect
	dbw EFFECTCMDTYPE_DISCARD_ENERGY, DiscardEnergy_DiscardEffect
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, IfSelectedCard20BonusDamage_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, FirePunch_AISelectEffect
	dbw EFFECTCMDTYPE_AI, FirePunch_AIEffect
	db  $00

ThunderPunchEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, ThunderPunch_PlayerSelectEffect
	dbw EFFECTCMDTYPE_DISCARD_ENERGY, DiscardEnergy_DiscardEffect
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, IfSelectedCard30BonusDamage_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, ThunderPunch_AISelectEffect
	dbw EFFECTCMDTYPE_AI, ThunderPunch_AIEffect
	db  $00

IgnitedVoltageEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, IgnitedVoltage_PlayerSelectEffect
	dbw EFFECTCMDTYPE_DISCARD_ENERGY, DiscardEnergy_DiscardEffect
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, IfSelectedCard30BonusDamage_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, IgnitedVoltage_AISelectEffect
	dbw EFFECTCMDTYPE_AI, IgnitedVoltage_AIEffect
	db  $00

SearingSparkEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, SearingSpark_PlayerSelectEffect
	dbw EFFECTCMDTYPE_DISCARD_ENERGY, DiscardEnergy_DiscardEffect
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, IfSelectedCard30BonusDamage_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, SearingSpark_AISelectEffect
	dbw EFFECTCMDTYPE_AI, SearingSpark_AIEffect
	db  $00

DiscardToolsFromOpponentEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DiscardOpponentTool_DiscardEffect
	db  $00

PluckEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PluckEffect
	dbw EFFECTCMDTYPE_AI, IfOpponentHasAttachedToolDoubleDamage_AIEffect
	db  $00

IncinerateEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PluckEffect
	dbw EFFECTCMDTYPE_AI, IfOpponentHasAttachedToolDoubleDamage_AIEffect
	db  $00

OvervoltageEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PluckEffect
	dbw EFFECTCMDTYPE_AI, IfOpponentHasAttachedToolDoubleDamage_AIEffect
	db  $00

BoostedVoltageEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, IfAttachedToolDamageOpponentBench10Effect
	db  $00

CorrosiveAcidEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, DiscardOpponentEnergyIfHeads_50PercentEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, DiscardOpponentEnergy_DiscardEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, DiscardOpponentEnergyIfHeads_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, DiscardOpponentEnergyIfHeads_AISelectEffect
	db  $00

Confusion50PercentEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Confusion50PercentEffect
	db  $00

FlamesOfRageEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Check2EnergiesAttached
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Discard2Energies_PlayerSelectEffect
	dbw EFFECTCMDTYPE_DISCARD_ENERGY, Discard2Energies_DiscardEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, Discard2Energies_AISelectEffect
	; fallthrough

RageEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Rage_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, Rage_AIEffect
	db  $00

DoubleDamageIfUserIsDamagedEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DoubleDamageIfUserIsDamaged_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, DoubleDamageIfUserIsDamaged_AIEffect
	db  $00

MoltresFiregiverEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Firegiver_InitialEffect
	dbw EFFECTCMDTYPE_PKMN_POWER_TRIGGER, Firegiver_AddToHandEffect
	db  $00

CourierEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, PassivePowerEffect
	dbw EFFECTCMDTYPE_PKMN_POWER_TRIGGER, Courier_SearchAndAddToHandEffect
	db  $00

WaveRiderEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, WaveRider_PreconditionCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DrawUntil3CardsInHandEffect
	db  $00

FleetFootedEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, FleetFooted_PreconditionCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, FleetFootedEffect
	db  $00

TradeEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Trade_PreconditionCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, TradeEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Trade_PlayerHandCardSelection
	db  $00

ShadowClawEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, OptionalDiscard_PlayerHandCardSelection
	dbw EFFECTCMDTYPE_DISCARD_ENERGY, SelectedCards_Discard1FromHand
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, ShadowClawEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, ShadowClaw_AISelectEffect
	db  $00

ThiefEffectCommands:
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Thief_PlayerHandCardSelection
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, ThiefEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, Thief_AIHandCardSelection
	db  $00

CurseEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, CheckPokemonPowerCanBeUsed
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Curse_DamageEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, DamageTargetPokemon_PlayerSelectEffect
	db  $00

Put1DamageCounterOnTargetEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Put1DamageCounterOnTarget_DamageEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, DamageTargetPokemon_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, DamageTargetPokemon_AISelectEffect
	dbw EFFECTCMDTYPE_AI, Put1DamageCounterOnTarget_AIEffect
	db  $00

PainAmplifierEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, PainAmplifier_DamageEffect
	db  $00

; DarkMindEffectCommands:
; 	dbw EFFECTCMDTYPE_AFTER_DAMAGE, DarkMind_DamageBenchEffect
; 	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, DarkMind_PlayerSelectEffect
; 	dbw EFFECTCMDTYPE_AI_SELECTION, DarkMind_AISelectEffect
; 	db  $00

GastlyDestinyBondEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckArenaPokemonHasAnyEnergiesAttached
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, DiscardEnergy_PlayerSelectEffect
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, ApplyDestinyBondEffect
	dbw EFFECTCMDTYPE_DISCARD_ENERGY, DiscardEnergy_DiscardEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, DiscardEnergy_AISelectEffect
	db  $00

EnergyConversionEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckDiscardPileHasBasicEnergyCards
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, SelectedCardList_AddToHandFromDiscardPileEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, EnergyConversion_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, EnergyConversion_AISelectEffect
	db  $00

RiptideEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Riptide_DamageBoostEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, SelectedCardList_AddToHandFromDiscardPileEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, EnergyConversion_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, EnergyConversion_AISelectEffect
	dbw EFFECTCMDTYPE_AI, Riptide_AIEffect
	db  $00

WaterReserveEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckDeckIsNotEmpty
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, SelectedCardList_AddToHandFromDeckEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, WaterReserve_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, WaterReserve_AISelectEffect
	db  $00

RapidChargeEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckDeckIsNotEmpty
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, SelectedCardList_AddToHandFromDeckEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, RapidCharge_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, RapidCharge_AISelectEffect
	db  $00

RocketShellEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, RocketShell_AddToHandEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, ReduceDamageTakenBy10Effect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, RocketShell_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, RocketShell_AISelectEffect
	db  $00

DoubleDamageIfAttachedEnergyEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DoubleDamageIfAttachedEnergy_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, DoubleDamageIfAttachedEnergy_AIEffect
	db  $00

GatherToxinsEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckDiscardPileHasBasicEnergyCards
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PoisonEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, AccelerateFromDiscard_AttachToPokemonEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, GatherToxins_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, RetrieveBasicEnergyFromDiscardPile_AISelectEffect
	db  $00

Retrieve1BasicEnergyEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, SelectedCard_AddToHandFromDiscardPile
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, RetrieveBasicEnergyFromDiscardPile_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, RetrieveBasicEnergyFromDiscardPile_AISelectEffect
	db  $00

CoreRegenerationEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Heal10DamageEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Draw1CardEffect
	db  $00

InflictSleepEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SleepEffect
	db  $00

ProphecyEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Prophecy_CheckDeck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Prophecy_ReorderDeckEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Prophecy_PlayerSelectEffect
	; dbw EFFECTCMDTYPE_AI_SELECTION, Prophecy_AISelectEffect
	db  $00

RendEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Rend_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, Rend_AIEffect
	db  $00

PesterEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Pester_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, Pester_AIEffect
	db  $00

FishingTailEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, FishingTail_DiscardPileCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SelectedCard_AddToHandFromDiscardPile
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, FishingTail_PlayerSelection
	dbw EFFECTCMDTYPE_AI_SELECTION, FishingTail_AISelection
	db  $00

AquaticRescueEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, FishingTail_DiscardPileCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SelectedCardList_AddToHandFromDiscardPileEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, ChooseUpTo3Cards_PlayerDiscardPileSelection
	dbw EFFECTCMDTYPE_AI_SELECTION, AquaticRescue_AISelectEffect
	db  $00

RototillerEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, SelectedDiscardPileCards_ShuffleIntoDeckEffect
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Rototiller_DamageBoostEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Rototiller_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, Rototiller_AISelectEffect
	dbw EFFECTCMDTYPE_AI, Rototiller_AIEffect
	db  $00

StrangeBehaviorEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, StrangeBehavior_CheckDamage
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, StrangeBehavior_SelectAndSwapEffect
	dbw EFFECTCMDTYPE_INTERACTIVE_STEP, StrangeBehavior_SwapEffect
	db  $00

GetMadEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, GetMad_CheckDamage
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, GetMad_MoveDamageCountersEffect
	db  $00

PsychicAssaultEffectCommands:
PainBurstEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PsychicAssault_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, PsychicAssault_AIEffect
	db  $00

MimicEffectCommands:
	; dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckDeckIsNotEmpty
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, MimicEffect
	db  $00

MeditateEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Meditate_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, Meditate_AIEffect
	db  $00

PsyshockEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Psyshock_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, Psyshock_AIEffect
	db  $00

MindBlastEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, MindBlast_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, MindBlast_AIEffect
	db  $00

HandPressEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, HandPress_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, HandPress_AIEffect
	db  $00

InvadeMindEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, InvadeMind_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, InvadeMind_AIEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, CheckOpponentHandEffect
	db  $00

InflictConfusionEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, ConfusionEffect
	db  $00

ConfusionWaveEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, ConfusionWaveEffect
	db  $00

MewPsywaveEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PsywaveEffect
	db  $00

MewDevolutionBeamEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, DevolutionBeam_CheckPlayArea
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, DevolutionBeam_PlayerSelectEffect
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DevolutionBeam_LoadAnimation
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, DevolutionBeam_DevolveEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, DevolutionBeam_AISelectEffect
	db  $00

PrimalSwirlEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, DevolveDefendingPokemonEffect
	db  $00

PsychicEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Psychic_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, Psychic_AIEffect
	db  $00

BarrierEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckArenaPokemonHasAnyEnergiesAttached
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Barrier_BarrierEffect
	dbw EFFECTCMDTYPE_DISCARD_ENERGY, DiscardAllAttachedEnergiesEffect
	db  $00

CollectFireEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckDiscardPileHasFireEnergyCards
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Attach1FireEnergyFromDiscard_SelectEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, AccelerateFromDiscard_AttachToPokemonEffect
	db  $00

EnergizeEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckDiscardPileHasLightningEnergyCards
	; fallthrough

PlasmaEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Attach1LightningEnergyFromDiscard_SelectEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, AccelerateFromDiscard_AttachToPokemonEffect
	db  $00

AbsorbWaterEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, AbsorbWater_PreconditionCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, AbsorbWater_AddToHandEffect
	db  $00

PrimordialDreamEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, PrimordialDream_PreconditionCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PrimordialDream_MorphAndAddToHandEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, PrimordialDream_PlayerSelectEffect
	db  $00

MudSportEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, MudSport_PreconditionCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, MudSport_AddToHandEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, MudSport_PlayerSelection
	db  $00

MagneticChargeEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, MagneticCharge_PreconditionCheck
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, AccelerateFromDiscard_AttachToPlayAreaEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, AttachBasicEnergyFromDiscardPileToBench_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, AttachBasicEnergyFromDiscardPileToBench_AISelectEffect
	db  $00

MendEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckDiscardPileHasBasicEnergyCards
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, MendEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, AttachBasicEnergyFromDiscardPile_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, RetrieveBasicEnergyFromDiscardPile_AISelectEffect
	db  $00

EnergyAbsorptionEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckDiscardPileHasBasicEnergyCards
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, AccelerateFromDiscard_AttachToPokemonEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, EnergyAbsorption_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, EnergyAbsorption_AISelectEffect
	db  $00

EnergySporesEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckDiscardPileHasBasicEnergyCards
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, AttachEnergyFromDiscard_AttachToPokemonEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, EnergySpores_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, EnergySpores_AISelectEffect
	db  $00

ScavengeEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckDiscardPileHasItemCards
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, SelectedCard_AddToHandFromDiscardPile
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Scavenge_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, Scavenge_AISelectEffect
	db  $00

JunkMagnetEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckDiscardPileHasItemCards
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, SelectedCardList_AddToHandFromDiscardPileEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, JunkMagnet_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, JunkMagnet_AISelectEffect
	db  $00

RecoverEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Recover_CheckEnergyHP
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, DiscardEnergy_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Recover_HealEffect
	dbw EFFECTCMDTYPE_DISCARD_ENERGY, DiscardEnergy_DiscardEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, DiscardEnergy_AISelectEffect
	db  $00

FurySwipesEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, FurySwipes_MultiplierEffect
	dbw EFFECTCMDTYPE_AI, FurySwipes_AIEffect
	db  $00

TantrumEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SelfConfusionEffect
	db  $00

RampageEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, RampageEffect
	dbw EFFECTCMDTYPE_AI, Rage_AIEffect
	db  $00

PrankEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckOpponentDiscardPileNotEmpty
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Prank_AddToDeckEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Prank_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, Prank_AISelectEffect
	db  $00

PrimalScytheEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PrimalScythe_DiscardDamageBoostEffect
	dbw EFFECTCMDTYPE_AI, PrimalScythe_AIEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, PrimalScythe_PlayerHandCardSelection
	dbw EFFECTCMDTYPE_AI_SELECTION, PrimalScythe_AISelectEffect
	db  $00

CallForFamilyEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CallForFamily_CheckDeckAndPlayArea
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, CallForFamily_PutInPlayAreaEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, CallForFamily_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, CallForFamily_AISelectEffect
	db  $00

KarateChopEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, KarateChop_DamageSubtractionEffect
	dbw EFFECTCMDTYPE_AI, KarateChop_AIEffect
	db  $00

HardenEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, HardenEffect
	db  $00

CloseCombatEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, IncreaseDamageTakenBy40Effect
	db  $00

Deal20ToBenchEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckOpponentBenchIsNotEmpty
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Deal20DamageToTarget_DamageEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, DamageTargetBenchedPokemon_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, DamageTargetBenchedPokemon_AISelectEffect
	db  $00

Earthquake10EffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Earthquake10Effect
	db  $00

DamageAllOpponentBenched10EffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, DamageAllOpponentBenched10Effect
	db  $00

SinisterFogEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PoisonEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, DamageAllOpponentBenched10Effect
	db  $00

TailSwingEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, DamageAllOpponentBenchedBasic20Effect
	db  $00

SmogEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SmogEffect
	db  $00

DeadlyPoisonEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DeadlyPoisonEffect
	dbw EFFECTCMDTYPE_AI, DeadlyPoison_AIEffect
	db  $00

OverwhelmEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, OverwhelmEffect
	db  $00

VengeanceEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Vengeance_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, Vengeance_AIEffect
	db  $00

LightScreenEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, LightScreenEffect
	db  $00

ExplosionEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Selfdestruct100Bench20Effect
	db  $00

ThunderboltEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DiscardAllAttachedEnergiesEffect
	db  $00

ZapdosThunderstormEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, ThunderstormEffect
	db  $00

ImmuneIfKnockedOutOpponentEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, ImmuneIfKnockedOutOpponentEffect
	db  $00

Damage1BenchedPokemon10EffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Deal10DamageToTarget_DamageEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, DamageTargetBenchedPokemonIfAny_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, DamageTargetBenchedPokemonIfAny_AISelectEffect
	db  $00

Damage1BenchedPokemon20EffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Deal20DamageToTarget_DamageEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, DamageTargetBenchedPokemonIfAny_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, DamageTargetBenchedPokemonIfAny_AISelectEffect
	db  $00

Damage1BenchedPokemon30EffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Deal30DamageToTarget_DamageEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, DamageTargetBenchedPokemonIfAny_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, DamageTargetBenchedPokemonIfAny_AISelectEffect
	db  $00

Damage1FriendlyBenchedPokemon10EffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Deal10DamageToFriendlyTarget_DamageEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, DamageFriendlyBenchedPokemonIfAny_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, DamageFriendlyBenchedPokemonIfAny_AISelectEffect
	db  $00

Damage1FriendlyBenchedPokemon20EffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Deal20DamageToFriendlyTarget_DamageEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, DamageFriendlyBenchedPokemonIfAny_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, DamageFriendlyBenchedPokemonIfAny_AISelectEffect
	db  $00

Damage1FriendlyBenchedPokemon30EffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Deal30DamageToFriendlyTarget_DamageEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, DamageFriendlyBenchedPokemonIfAny_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, DamageFriendlyBenchedPokemonIfAny_AISelectEffect
	db  $00

SteamrollerEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Steamroller_ChangeColorEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Steamroller_DamageAndColorEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, DamageTargetBenchedPokemonIfAny_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, DamageTargetBenchedPokemonIfAny_AISelectEffect
	db  $00

ArticunoIceBreathEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, IceBreath_BenchDamageEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, DamageTargetBenchedPokemonIfAny_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, DamageTargetBenchedPokemonIfAny_AISelectEffect
	db  $00

GrowlEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, GrowlEffect
	db  $00

ChainLightningEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, ChainLightningEffect
	db  $00

DamageUpTo2Benched10EffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, SelectUpTo2Benched_BenchDamageEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, SelectUpTo2Benched_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, SelectUpTo2Benched_AISelectEffect
	db  $00

SonicboomEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Sonicboom_UnaffectedByColorEffect
	; dbw EFFECTCMDTYPE_AFTER_DAMAGE, NullEffect
	dbw EFFECTCMDTYPE_AI, Sonicboom_UnaffectedByColorEffect
	db  $00

UnaffectedByResistanceEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, UnaffectedByResistanceEffect
	dbw EFFECTCMDTYPE_AI, UnaffectedByResistanceEffect
	db  $00

NutritionSupportEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckDeckIsNotEmpty
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, NutritionSupport_AttachEnergyEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, NutritionSupport_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, NutritionSupport_AISelectEffect
	db  $00

EnergySpikeEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckDeckIsNotEmpty
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, EnergySpike_AttachEnergyEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, EnergySpike_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, EnergySpike_AISelectEffect
	db  $00

UnableToRetreatEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, UnableToRetreatEffect
	db  $00

Draw1CardEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Draw1CardEffect
	db  $00

Draw2CardsEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Draw2CardsEffect
	db  $00

DrawUntil5CardsInHandEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, DrawUntil5CardsInHandEffect
	db  $00

FriendTackleEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, IfPlayedSupporter20BonusDamage_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, IfPlayedSupporter20BonusDamage_AIEffect
	db  $00

FuryAttackEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, IfOpponentPlayedSupporter20BonusDamage_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, IfOpponentPlayedSupporter20BonusDamage_AIEffect
	db  $00

SmallCombustionEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, SmallCombustion_DiscardDeckEffect
	db  $00

CombustionEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Combustion_DiscardDeckEffect
	db  $00

LandslideEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckDeckIsNotEmpty
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Landslide_DiscardDeckEffect
	db  $00

MountainSwingEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckDeckIsNotEmpty
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, MountainSwing_DiscardDeckEffect
	db  $00

MetronomeEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Metronome_CheckAttacks
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Metronome_UseAttackEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, Metronome_AISelectEffect
	db  $00

LunarPowerEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, PokemonBreeder_PreconditionCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PokemonBreeder_EvolveEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, PokemonBreeder_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, EvolutionFromDeck_AISelectEffect
	db  $00

GaleEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, GaleEffect
	db  $00

DevastatingWindEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, DevastatingWindEffect
	db  $00

AvalancheEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Avalanche_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, Avalanche_AIEffect
	db  $00

DoTheWaveEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DoTheWave_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, DoTheWave_AIEffect
	db  $00

SwarmEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Swarm_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, Swarm_AIEffect
	db  $00

ReduceAttackBy10EffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, ReduceAttackBy10Effect
	db  $00

EnergySlideEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckArenaPokemonHasAnyEnergiesAttached
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, EnergySlide_TransferEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, EnergySlide_PlayerSelection
	; dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, EnergySlide_PlayerSelection
	; dbw EFFECTCMDTYPE_DISCARD_ENERGY, EnergySlide_TransferEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, EnergySlide_AISelectEffect
	db  $00

WickedTentacleEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, WickedTentacle_PreconditionCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, MoveOpponentEnergyToBench_TransferEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, TargetedPoisonEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, MoveOpponentEnergyToBench_PlayerSelection
	dbw EFFECTCMDTYPE_AI_SELECTION, MoveOpponentEnergyToBench_AISelectEffect
	db  $00

MoveOpponentEnergyToBenchEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, MoveOpponentEnergyToBench_TransferEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, MoveOpponentEnergyToBench_PlayerSelection
	dbw EFFECTCMDTYPE_AI_SELECTION, OptionalMoveOpponentEnergyToBench_AISelectEffect
	db  $00

WhirlwindEffectCommands:
WaterfallEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Whirlwind_SwitchEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Whirlwind_SelectEffect
	dbw EFFECTCMDTYPE_AI_SWITCH_DEFENDING_PKMN, Whirlwind_SelectEffect
	db  $00

RamEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Ram_RecoilSwitchEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Whirlwind_SelectEffect
	dbw EFFECTCMDTYPE_AI_SWITCH_DEFENDING_PKMN, Whirlwind_SelectEffect
	db  $00

ConversionBeamEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, ConversionBeam_ChangeWeaknessEffect
	db  $00

TrainerCardAsPokemonEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, TrainerCardAsPokemon_BenchCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, TrainerCardAsPokemon_DiscardEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, TrainerCardAsPokemon_PlayerSelectSwitch
	db  $00

HealingMelodyEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Heal10DamageFromAll_HealEffect
	db  $00

AromatherapyEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Heal20DamageFromAll_HealEffect
	db  $00

GrowthEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, AttachEnergyFromHand_HandCheck
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, AttachEnergyFromHand_AttachEnergyEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, AttachEnergyFromHand_OnlyActive_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, AttachEnergyFromHand_OnlyActive_AISelectEffect
	db  $00

DragonDanceEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, AttachEnergyFromHand_HandCheck
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, AttachEnergyFromHand_AttachEnergyEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, AttachEnergyFromHand_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, AttachEnergyFromHand_AISelectEffect
	db  $00

EnergyLiftEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, EnergyLift_PreconditionCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, EnergyLift_AttachEnergyEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, EnergyLift_PlayerSelectEffect
	; dbw EFFECTCMDTYPE_AI_SELECTION, AttachEnergyFromHand_AISelectEffect
	db  $00

MorphEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckDiscardPileHasBasicPokemonCards
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, MorphEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Morph_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, Morph_AISelectEffect
	db  $00

Deal10ToAnyPokemonEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Deal10DamageToTarget_DamageEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, DamageTargetPokemon_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, DamageTargetPokemon_AISelectEffect
	db  $00

NightAmbushEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, TargetedPoisonEffect
	; fallthrough

Deal20ToAnyPokemonEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Deal20DamageToTarget_DamageEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, DamageTargetPokemon_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, DamageTargetPokemon_AISelectEffect
	db  $00

Deal30ToAnyPokemonEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Deal30DamageToTarget_DamageEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, DamageTargetPokemon_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, DamageTargetPokemon_AISelectEffect
	db  $00

Deal40ToAnyPokemonEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Deal40DamageToTarget_DamageEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, DamageTargetPokemon_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, DamageTargetPokemon_AISelectEffect
	db  $00

AquaLauncherEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, AquaLauncherEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, DamageTargetPokemon_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, DamageTargetPokemon_AISelectEffect
	db  $00

SearchingMagnetEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckDeckIsNotEmpty
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SelectedCard_AddToHandFromDeckEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, SearchingMagnet_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, SearchingMagnet_AISelectEffect
	db  $00

LeadEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckDeckIsNotEmpty
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SelectedCard_AddToHandFromDeckEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Lead_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, Lead_AISelectEffect
	db  $00

ReduceDamageTakenBy10EffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, ReduceDamageTakenBy10Effect
	db  $00

DragonRageEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DragonRage_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, DragonRage_AIEffect
	db  $00

SpeedImpactEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SpeedImpact_DamageSubtractionEffect
	dbw EFFECTCMDTYPE_AI, SpeedImpact_AIEffect
	db  $00

FungalGrowthEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SleepEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, LeechLifeEffect
	db  $00

NaturalRemedyEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckIfPlayAreaHasAnyDamageOrStatus
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, NaturalRemedy_HealEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, NaturalRemedy_PlayerSelection
	dbw EFFECTCMDTYPE_AI_SELECTION, NaturalRemedy_AISelectEffect
	db  $00

SynthesisEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Synthesis_PreconditionCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Synthesis_AddToHandEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Synthesis_PlayerSelection
	db  $00

EnergyGeneratorEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, EnergyGenerator_PreconditionCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, EnergyGenerator_AttachEnergyEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, EnergySpike_PlayerSelectEffect
	db  $00

QueenPressEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, QueenPressEffect
	db  $00


DoubleColorlessEnergyEffectCommands:
	db  $00

DarknessEnergyEffectCommands:
	db  $00

PsychicEnergyEffectCommands:
	db  $00

FightingEnergyEffectCommands:
	db  $00

LightningEnergyEffectCommands:
	db  $00

WaterEnergyEffectCommands:
	db  $00

FireEnergyEffectCommands:
	db  $00

GrassEnergyEffectCommands:
	db  $00

SuperPotionEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, SuperPotion_DamageEnergyCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, SuperPotion_PlayerSelectEffect
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SuperPotion_HealEffect
	db  $00

ImakuniEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, ImakuniEffect
	db  $00

RocketGruntsEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, RocketGrunts_EnergyCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, RocketGrunts_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, RocketGrunts_DiscardEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, RocketGrunts_AISelection
	db  $00

EnergyRetrievalEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, EnergyRetrieval_HandEnergyCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Discard_PlayerHandCardSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, EnergyRetrieval_DiscardAndAddToHandEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, EnergyRetrieval_PlayerDiscardPileSelection
	db  $00

EnergySearchEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckDeckIsNotEmpty
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SelectedCard_AddToHandFromDeckEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, EnergySearch_PlayerSelection
	db  $00

ProfessorOakEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, ProfessorOakEffect
	db  $00

PotionEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckIfPlayAreaHasAnyDamage
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Potion_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Potion_HealEffect
	db  $00

GamblerEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, GamblerEffect
	db  $00

ItemFinderEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckHandSizeGreaterThan1
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, ItemFinder_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, ItemFinder_DiscardAddToHandEffect
	db  $00

DefenderEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Defender_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Defender_AttachDefenderEffect
	db  $00

MysteriousFossilEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, MysteriousFossil_BenchCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, MysteriousFossil_PlaceInPlayAreaEffect
	db  $00

FullHealEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, FullHeal_CheckPlayAreaStatus
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, FullHeal_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, FullHeal_ClearStatusEffect
	db  $00

ImposterProfessorOakEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, ImposterProfessorOakEffect
	db  $00

ComputerSearchEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckDeckIsNotEmpty
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SelectedCard_AddToHandFromDeckEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, ComputerSearch_PlayerSelection
	db  $00

ClefairyDollEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, ClefairyDoll_BenchCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, ClefairyDoll_PlaceInPlayAreaEffect
	db  $00

MrFujiEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckBenchIsNotEmpty
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, MrFuji_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, MrFuji_ReturnToDeckEffect
	db  $00

PlusPowerEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, PlusPower_PreconditionCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PlusPowerEffect
	db  $00

SwitchEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Switch_BenchCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Switch_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Switch_SwitchEffect
	db  $00

PokemonCenterEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckIfPlayAreaHasAnyDamage
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Heal10DamageFromAll_HealEffect
	db  $00

PokemonFluteEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, PokemonFlute_BenchCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, PokemonFlute_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PokemonFlute_PlaceInPlayAreaText
	; dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PokemonFlute_DisablePowersEffect
	db  $00

PokemonBreederEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, PokemonBreeder_PreconditionCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PokemonBreeder_EvolveEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, PokemonBreeder_PlayerSelectEffect
	; dbw EFFECTCMDTYPE_AI_SELECTION, PokemonBreeder_AISelectEffect
	db  $00

RareCandyEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, RareCandy_HandPlayAreaCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, RareCandy_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, RareCandy_EvolveEffect
	db  $00

ScoopUpNetEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckBenchIsNotEmpty
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, ScoopUpNet_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, ScoopUpNet_ReturnToHandEffect
	db  $00

PokemonTraderEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, PokemonTrader_HandDeckCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, PokemonTrader_PlayerHandSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PokemonTrader_TradeCardsEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, PokemonTrader_PlayerDeckSelection
	db  $00

PokedexEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckDeckIsNotEmpty
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Pokedex_AddToHandAndOrderDeckCardsEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Pokedex_PlayerSelection
	db  $00

BillEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Draw3Cards
	db  $00

LassEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, LassEffect
	db  $00

MaintenanceEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Maintenance_CheckHandAndDiscardPile
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Discard_PlayerHandCardSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Maintenance_DiscardAndAddToHandEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Maintenance_PlayerDiscardPileSelection
	db  $00

PokeBallEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckDeckIsNotEmpty
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SelectedCard_AddToHandFromDeckEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, PokeBall_PlayerSelection
	db  $00

RecycleEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Recycle_DiscardPileCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Recycle_AddToDeckEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Recycle_PlayerSelection
	db  $00

ReviveEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Revive_BenchCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Revive_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Revive_PlaceInPlayAreaEffect
	db  $00

DevolutionSprayEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, DevolutionSpray_PlayAreaEvolutionCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, DevolutionSpray_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DevolutionSpray_DevolutionEffect
	db  $00

EnergySwitchEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckIfPlayAreaHasAnyEnergies
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, EnergySwitch_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, EnergySwitch_TransferEffect
	db  $00

EnergyRecyclerEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckDiscardPileHasBasicEnergyCards
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, EnergyRecycler_ReturnToDeckEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, ChooseUpTo4Cards_PlayerDiscardPileSelection
	db  $00

GiovanniEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Giovanni_BenchCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Giovanni_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Giovanni_SwitchEffect
	db  $00
