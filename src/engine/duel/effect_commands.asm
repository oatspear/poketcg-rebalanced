EffectCommands: ; 186f7 (6:46f7)
; Each attack has a two-byte effect pointer (attack's 7th param) that points to one of these structures.
; Similarly, trainer cards have a two-byte pointer (7th param) to one of these structures, which determines the card's function.
; Energy cards also point to one of these, but their data is just $00.
;	db EFFECTCMDTYPE_* ($01 - $0a)
;	dw Function
;	...
;	db $00


; Commands are associated to a time or a scope (EFFECTCMDTYPE_*) that determines when their function is executed during the turn.
; - EFFECTCMDTYPE_INITIAL_EFFECT_1: Executed right after attack or trainer card is used. Bypasses Smokescreen and Sand Attack effects.
; - EFFECTCMDTYPE_INITIAL_EFFECT_2: Executed right after attack, Pokemon Power, or trainer card is used.
; - EFFECTCMDTYPE_DISCARD_ENERGY: For attacks or trainer cards that require putting one or more attached energy cards into the discard pile.
; - EFFECTCMDTYPE_REQUIRE_SELECTION: For attacks, Pokemon Powers, or trainer cards requiring the user to select a card (from e.g. play area screen or card list).
; - EFFECTCMDTYPE_BEFORE_DAMAGE: Effect command of an attack executed prior to the damage step. For trainer card or Pokemon Power, usually the main effect.
; - EFFECTCMDTYPE_AFTER_DAMAGE: Effect command executed after the damage step.
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

; Function name examples
;	PoisonEffect                     ; generic effect shared by multiple attacks.
;	Paralysis50PercentEffect         ;
;	KakunaStiffenEffect              ; unique effect from an attack known by multiple cards.
;	MetapodStiffenEffect             ;
;	AcidEffect                       ; unique effect from an attack known by a single card
;	FoulOdorEffect                   ;
;	SpitPoison_Poison50PercentEffect ; unique effect made of more than one command.
;	SpitPoison_AIEffect              ;

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

LureEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Lure_AssertPokemonInBench
	; dbw EFFECTCMDTYPE_BEFORE_DAMAGE, UnableToRetreatEffect
	; dbw EFFECTCMDTYPE_AFTER_DAMAGE, Lure_SwitchDefendingPokemon
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

AcidEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, UnableToRetreatEffect
	db  $00

PanicVineEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PanicVine_ConfusionTrapEffect
	db  $00

FlytrapEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, UnableToRetreatEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Heal20DamageEffect
	db  $00

SproutEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckDeckIsNotEmpty
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Sprout_AddToHandEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Sprout_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, Sprout_AISelectEffect
	db  $00

UltravisionEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckDeckIsNotEmpty
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Ultravision_AddToHandEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Ultravision_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, Ultravision_AISelectEffect
	db  $00

FoulOdorEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, FoulOdorEffect
	db  $00

LeechLifeEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, LeechLifeEffect
	db  $00

ScytherSwordsDanceEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SwordsDanceEffect
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

KoffingFoulGasEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, FoulGas_PoisonOrConfusionEffect
	dbw EFFECTCMDTYPE_AI, FoulGas_AIEffect
	db  $00

TeleportEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckBenchIsNotEmpty
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Teleport_ReturnToDeckEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Teleport_PlayerSelectEffect
	db  $00

OldTeleportEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckBenchIsNotEmpty
	; fallthrough
TeleportBlastEffectCommands:
AgilityEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Agility_SwitchEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Agility_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, Agility_AISelectEffect
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

BigEggsplosionEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, BigEggsplosion_MultiplierEffect
	dbw EFFECTCMDTYPE_AI, BigEggsplosion_AIEffect
	db  $00

TropicalStormEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, TropicalStorm_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, TropicalStorm_AIEffect
	db  $00

RoutEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Rout_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, Rout_AIEffect
	db  $00

ToxicEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DoublePoisonEffect
	; dbw EFFECTCMDTYPE_AI, Toxic_AIEffect
	db  $00

PeckEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Peck_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, Peck_AIEffect
	db  $00

GrassKnotEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, GrassKnot_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, GrassKnot_AIEffect
	db  $00

RagingStormEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, RagingStorm_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, RagingStorm_AIEffect
	db  $00

CrabhammerEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Crabhammer_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, Crabhammer_AIEffect
	db  $00

PowerLariatEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PowerLariat_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, PowerLariat_AIEffect
	db  $00

DenProtectorEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DenProtector_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, DenProtector_AIEffect
	db  $00

FamilyPowerEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, FamilyPower_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, FamilyPower_AIEffect
	db  $00

RetaliateEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckArenaPokemonHasAnyDamage
	db  $00

AssassinFlightEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, AssassinFlight_CheckBenchAndStatus
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, AssassinFlight_BenchDamageEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, AssassinFlight_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, AssassinFlight_AISelectEffect
	db  $00

TwineedleEffectCommands:
DoubleAttackX20X10EffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DoubleAttackX20X10_MultiplierEffect
	dbw EFFECTCMDTYPE_AI, DoubleAttackX20X10_AIEffect
	db  $00

MarowakBonemerangEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DoubleAttackX30_MultiplierEffect
	dbw EFFECTCMDTYPE_AI, DoubleAttackX30_AIEffect
	db  $00

Heal20DamageEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Heal20DamageEffect
	db  $00

Heal30DamageEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Heal30DamageEffect
	db  $00

Poison50PercentEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Poison50PercentEffect
	db  $00

IvysaurPoisonWhipEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PoisonEffect
	db  $00

LeechSeedEffectCommands:
Heal10DamageEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Heal10DamageEffect
	db  $00

EnergyTransEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, EnergyTrans_CheckPlayArea
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, EnergyTrans_TransferEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, EnergyTrans_AIEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, EnergyTrans_PrintProcedure
	db  $00

VaporEssenceEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, VaporEssence_OncePerTurnCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, VaporEssence_ChangeColorEffect
	db  $00

JoltEssenceEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, JoltEssence_OncePerTurnCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, JoltEssence_ChangeColorEffect
	db  $00

FlareEssenceEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, FlareEssence_OncePerTurnCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, FlareEssence_ChangeColorEffect
	db  $00

DualTypeFightingEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, CheckPokemonPowerCanBeUsed
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DualTypeFighting_ChangeColorEffect
	db  $00

ShiftEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Shift_OncePerTurnCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Shift_ChangeColorEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Shift_PlayerSelectEffect
	db  $00

VenomothVenomPowderEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, VenomPowder_PoisonConfusionEffect
	; dbw EFFECTCMDTYPE_AI, VenomPowder_AIEffect
	db  $00

PokemonPowerHealEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Heal_OncePerTurnCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Heal_RemoveDamageEffect
	db  $00

PetalDanceEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, PetalDance_BonusEffect
	db  $00

VenusaurSolarPowerEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, SolarPower_CheckUse
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SolarPower_RemoveStatusEffect
	db  $00

PollenFrenzyEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PollenFrenzy_Status50PercentEffect
	db  $00

FirestarterEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Firestarter_OncePerTurnCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Firestarter_AttachEnergyEffect
	db  $00

HelpingHandEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, HelpingHand_CheckUse
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, HelpingHand_RemoveStatusEffect
	db  $00

RestEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Rest_HealEffect
	db  $00

SongOfRestEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, SongOfRest_CheckUse
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SongOfRest_HealEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, SongOfRest_PlayerSelectEffect
	db  $00

RainDanceEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, RainDanceEffect
	db  $00

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

HorseaSmokescreenEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, HorseaSmokescreenEffect
	db  $00

SupersonicEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SupersonicEffect
	db  $00

TentacruelJellyfishStingEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PoisonEffect
	dbw EFFECTCMDTYPE_AI, JellyfishSting_AIEffect
	db  $00

AmnesiaEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Amnesia_CheckAttacks
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Amnesia_PlayerSelectEffect
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Amnesia_DisableEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, Amnesia_AISelectEffect
	db  $00

GastlyLickEffectCommands:
ElectabuzzThundershockEffectCommands:
MagnemiteThunderWaveEffectCommands:
FlyingPikachuThundershockEffectCommands:
PikachuLv16ThundershockEffectCommands:
PikachuAltLv16ThundershockEffectCommands:
MagnetonThunderWaveEffectCommands:
JolteonStunNeedleEffectCommands:
SnorlaxBodySlamEffectCommands:
PinsirIronGripEffectCommands:
CloysterClampEffectCommands:
CaterpieStringShotEffectCommands:
DewgongIceBeamEffectCommands:
ArticunoFreezeDryEffectCommands:
Paralysis50PercentEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Paralysis50PercentEffect
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

ArticunoIceBreathEffectCommands:
	; dbw EFFECTCMDTYPE_BEFORE_DAMAGE, IceBreath_ZeroDamage
	; dbw EFFECTCMDTYPE_AFTER_DAMAGE, IceBreath_RandomPokemonDamageEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, IceBreath_BenchDamageEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, IceBreath_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, IceBreath_AISelectEffect
	db  $00

FocusEnergyEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, FocusEnergyEffect
	db  $00

Recoil10EffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Recoil10Effect
	db  $00

Recoil20EffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Recoil20Effect
	db  $00

JolteonQuickAttackEffectCommands:
VaporeonQuickAttackEffectCommands:
FlareonQuickAttackEffectCommands:
NinetalesQuickAttackEffectCommands:
ArcanineQuickAttackEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Heads10BonusDamage_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, ArcanineQuickAttack_AIEffect
	db  $00

QuickAttackEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, IfActiveThisTurnDoubleDamage_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, IfActiveThisTurnDoubleDamage_AIEffect
	db  $00

KangaskhanCometPunchEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Heads10BonusDamage_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, CometPunch_AIEffect
	db  $00

FurySwipes20Plus10EffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Heads10BonusDamage_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, Heads20Plus10Damage_AIEffect
	db  $00

ArcanineFlamesOfRageEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Check2EnergiesAttached
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Discard2Energies_PlayerSelectEffect
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Rage_DamageBoostEffect
	dbw EFFECTCMDTYPE_DISCARD_ENERGY, Discard2Energies_DiscardEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, Discard2Energies_AISelectEffect
	dbw EFFECTCMDTYPE_AI, Rage_AIEffect
	db  $00

EmberEffectCommands:
FlamethrowerEffectCommands:
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

MagmarSmokescreenEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, MagmarSmokescreenEffect
	db  $00

CharizardEnergyBurnEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, EnergyBurnEffect
	db  $00

FireBlastEffectCommands:
FireSpinEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Check2EnergiesAttached
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Discard2Energies_PlayerSelectEffect
	dbw EFFECTCMDTYPE_DISCARD_ENERGY, Discard2Energies_DiscardEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, Discard2Energies_AISelectEffect
	db  $00

Confusion50PercentEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Confusion50PercentEffect
	db  $00

RageEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Rage_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, Rage_AIEffect
	db  $00

MoltresFiregiverEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Firegiver_InitialEffect
	dbw EFFECTCMDTYPE_PKMN_POWER_TRIGGER, Firegiver_AddToHandEffect
	db  $00

ProwlEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, PassivePowerEffect
	dbw EFFECTCMDTYPE_PKMN_POWER_TRIGGER, Prowl_SearchAndAddToHandEffect
	db  $00

ShadowClawEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, OptionalDiscardEnergy_PlayerSelectEffect
	dbw EFFECTCMDTYPE_DISCARD_ENERGY, ShadowClawEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, ShadowClaw_AISelectEffect
	db  $00

CurseEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Curse_CheckDamageAndBench
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Curse_TransferDamageEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Curse_PlayerSelectEffect
	db  $00

PainAmplifierEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, PainAmplifier_DamageEffect
	db  $00

DarkMindEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, DarkMind_DamageBenchEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, DarkMind_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, DarkMind_AISelectEffect
	db  $00

GastlyDestinyBondEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckArenaPokemonHasAnyEnergiesAttached
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, DiscardEnergy_PlayerSelectEffect
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, ApplyDestinyBondEffect
	dbw EFFECTCMDTYPE_DISCARD_ENERGY, DiscardEnergy_DiscardEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, DiscardEnergy_AISelectEffect
	db  $00

EnergyConversionEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckDiscardPileHasBasicEnergyCards
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, EnergyConversion_AddToHandEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, EnergyConversion_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, EnergyConversion_AISelectEffect
	db  $00

GatherToxinsEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckDiscardPileHasBasicEnergyCards
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PoisonEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, GatherToxins_AttachToPokemonEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, GatherToxins_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, GatherToxins_AISelectEffect
	db  $00

EnergySplashEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, EnergySplash_AddToHandEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, EnergySplash_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, EnergySplash_AISelectEffect
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
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, FishingTail_AddToHandEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, FishingTail_PlayerSelection
	dbw EFFECTCMDTYPE_AI_SELECTION, FishingTail_AISelection
	db  $00

StrangeBehaviorEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, StrangeBehavior_CheckDamage
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, StrangeBehavior_SelectAndSwapEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, StrangeBehavior_SwapEffect
	db  $00

PsychicAssaultEffectCommands:
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

; AlakazamDamageSwapEffectCommands:
; 	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, DamageSwap_CheckDamage
; 	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DamageSwap_SelectAndSwapEffect
; 	dbw EFFECTCMDTYPE_AFTER_DAMAGE, DamageSwap_SwapEffect
; 	db  $00

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
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, CollectFire_AttachToPokemonEffect
	db  $00

AbsorbWaterEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, AbsorbWater_PreconditionCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, AbsorbWater_AddToHandEffect
	db  $00

EnergyAbsorptionEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckDiscardPileHasBasicEnergyCards
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, EnergyAbsorption_AttachToPokemonEffect
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
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Scavenge_CheckDiscardPile
	; dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Scavenge_PlayerSelectEnergyEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Scavenge_AddToHandEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, PlayerSelectAndStoreItemCardFromDiscardPile
	; dbw EFFECTCMDTYPE_DISCARD_ENERGY, Scavenge_DiscardEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, Scavenge_AISelectEffect
	db  $00

RecoverEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Recover_CheckEnergyHP
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, DiscardEnergy_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Recover_HealEffect
	dbw EFFECTCMDTYPE_DISCARD_ENERGY, DiscardEnergy_DiscardEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, DiscardEnergy_AISelectEffect
	db  $00

GeodudeStoneBarrageEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, StoneBarrage_MultiplierEffect
	dbw EFFECTCMDTYPE_AI, StoneBarrage_AIEffect
	db  $00

PrimeapeFurySwipesEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PrimeapeFurySwipes_MultiplierEffect
	dbw EFFECTCMDTYPE_AI, PrimeapeFurySwipes_AIEffect
	db  $00

PrimeapeTantrumEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, TantrumEffect
	db  $00

KabutopsAbsorbEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, AbsorbEffect
	db  $00

CallForFriendEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CallForFriend_CheckDeckAndPlayArea
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, CallForFriend_PutInPlayAreaEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, CallForFriend_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, CallForFriend_AISelectEffect
	db  $00

KarateChopEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, KarateChop_DamageSubtractionEffect
	dbw EFFECTCMDTYPE_AI, KarateChop_AIEffect
	db  $00

HardenEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, HardenEffect
	db  $00

RhydonRamEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Ram_RecoilSwitchEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Ram_SelectSwitchEffect
	dbw EFFECTCMDTYPE_AI_SWITCH_DEFENDING_PKMN, Ram_SelectSwitchEffect
	db  $00

RhyhornLeerEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, LeerEffect
	db  $00

MarowakBoneAttackEffectCommands:
DiglettDigEffectCommands:
HitmonleeStretchKickEffectCommands:
Deal20ToBenchEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, StretchKick_CheckBench
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, StretchKick_BenchDamageEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, StretchKick_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, StretchKick_AISelectEffect
	db  $00

SandshrewSandAttackEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SandAttackEffect
	db  $00

Earthquake10EffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Earthquake10Effect
	db  $00

BlizzardEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, DamageAllOpponentBenched10Effect
	db  $00

TailSwingEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, DamageAllOpponentBenchedBasic20Effect
	db  $00

SmogEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PoisonEffect
	; dbw EFFECTCMDTYPE_AFTER_DAMAGE, SmogEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Earthquake10Effect
	db  $00

DeadlyPoisonEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DeadlyPoisonEffect
	dbw EFFECTCMDTYPE_AI, DeadlyPoison_AIEffect
	db  $00

StrangleEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, StrangleEffect
	db  $00

; SpitPoisonEffectCommands:
; 	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SpitPoisonEffect
; 	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Spark_PlayerSelectEffect
; 	dbw EFFECTCMDTYPE_AI_SELECTION, Spark_AISelectEffect
; 	db  $00

AerodactylPrehistoricPowerEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, PrehistoricPowerEffect
	db  $00

; MankeyPeekEffectCommands:
; 	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Peek_OncePerTurnCheck
; 	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Peek_SelectEffect
; 	db  $00

; WailEffectCommands:
; 	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Wail_BenchCheck
; 	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Wail_FillBenchEffect
; 	db  $00

VengeanceEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Vengeance_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, Vengeance_AIEffect
	db  $00

ElectabuzzThunderpunchEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Thunderpunch_ModifierEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Thunderpunch_RecoilEffect
	dbw EFFECTCMDTYPE_AI, Thunderpunch_AIEffect
	db  $00

ElectabuzzLightScreenEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, LightScreenEffect
	db  $00

ElectabuzzQuickAttackEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, ElectabuzzQuickAttack_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, ElectabuzzQuickAttack_AIEffect
	db  $00

Selfdestruct40Bench10EffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Selfdestruct40Bench10Effect
	db  $00

Selfdestruct50Bench10EffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Selfdestruct50Bench10Effect
	db  $00

Selfdestruct80Bench20EffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Selfdestruct80Bench20Effect
	db  $00

Selfdestruct100Bench20EffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Selfdestruct100Bench20Effect
	db  $00

GolemSelfdestructEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Selfdestruct100Bench20Effect
	db  $00

ZapdosThunderEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, ZapdosThunder_Recoil50PercentEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, ZapdosThunder_RecoilEffect
	db  $00

ThunderboltEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DiscardAllAttachedEnergiesEffect
	db  $00

ZapdosThunderstormEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, ThunderstormEffect
	db  $00

JolteonPinMissileEffectCommands:
SandslashFurySwipesEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, TripleAttackX20X10_MultiplierEffect
	dbw EFFECTCMDTYPE_AI, TripleAttackX20X10_AIEffect
	db  $00

FlyingPikachuFlyEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Fly_Success50PercentEffect
	dbw EFFECTCMDTYPE_AI, Fly_AIEffect
	db  $00

SparkEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Spark_BenchDamageEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Spark_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, Spark_AISelectEffect
	db  $00

GrowlEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, GrowlEffect
	db  $00

ChainLightningEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, ChainLightningEffect
	db  $00

RaichuThunderEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, RaichuThunder_Recoil50PercentEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, RaichuThunder_RecoilEffect
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

ZapdosPealOfThunderEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, PealOfThunder_InitialEffect
	dbw EFFECTCMDTYPE_PKMN_POWER_TRIGGER, PealOfThunder_RandomlyDamageEffect
	db  $00

ZapdosBigThunderEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, BigThunderEffect
	db  $00

MagnemiteMagneticStormEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, MagneticStormEffect
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

JolteonDoubleKickEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, JolteonDoubleKick_MultiplierEffect
	dbw EFFECTCMDTYPE_AI, JolteonDoubleKick_AIEffect
	db  $00

EeveeQuickAttackEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, EeveeQuickAttack_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, EeveeQuickAttack_AIEffect
	db  $00

; SpearowMirrorMoveEffectCommands:
; 	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, SpearowMirrorMove_InitialEffect1
; 	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, SpearowMirrorMove_InitialEffect2
; 	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SpearowMirrorMove_BeforeDamage
; 	dbw EFFECTCMDTYPE_AFTER_DAMAGE, SpearowMirrorMove_AfterDamage
; 	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, SpearowMirrorMove_PlayerSelection
; 	dbw EFFECTCMDTYPE_AI_SELECTION, SpearowMirrorMove_AISelection
; 	dbw EFFECTCMDTYPE_AI, SpearowMirrorMove_AIEffect
; 	db  $00

UnableToRetreatEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, UnableToRetreatEffect
	db  $00

DragoniteStepInEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, StepIn_BenchCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, StepIn_SwitchEffect
	db  $00

FarfetchdLeekSlapEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, LeekSlap_OncePerDuelCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, LeekSlap_NoDamage50PercentEffect
	dbw EFFECTCMDTYPE_DISCARD_ENERGY, LeekSlap_SetUsedThisDuelFlag
	dbw EFFECTCMDTYPE_AI, LeekSlap_AIEffect
	db  $00

Draw1CardEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, FetchEffect
	db  $00

Draw2CardsEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, CollectEffect
	db  $00

TaurosStompEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, TaurosStomp_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, TaurosStomp_AIEffect
	db  $00

TaurosRampageEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Rampage_Confusion50PercentEffect
	dbw EFFECTCMDTYPE_AI, Rampage_AIEffect
	db  $00

DoduoFuryAttackEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, FuryAttack_MultiplierEffect
	dbw EFFECTCMDTYPE_AI, FuryAttack_AIEffect
	db  $00

DodrioRetreatAidEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, RetreatAidEffect
	db  $00

DragonairSlamEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DragonairSlam_MultiplierEffect
	dbw EFFECTCMDTYPE_AI, DragonairSlam_AIEffect
	db  $00

WhirlpoolEffectCommands:
TwisterEffectCommands:
HyperBeamEffectCommands:
FireFangEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, DiscardOpponentEnergy_DiscardEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, DiscardOpponentEnergy_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, DiscardOpponentEnergy_AISelectEffect
	db  $00

CorrosiveAcidEffectCommands:
 	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, DiscardOpponentEnergyIfHeads_50PercentEffect
 	dbw EFFECTCMDTYPE_AFTER_DAMAGE, DiscardOpponentEnergy_DiscardEffect
 	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, DiscardOpponentEnergyIfHeads_PlayerSelectEffect
 	dbw EFFECTCMDTYPE_AI_SELECTION, DiscardOpponentEnergyIfHeads_AISelectEffect
 	db  $00

SmallCombustionEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, SmallCombustion_DiscardDeckEffect
	db  $00

CombustionEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Combustion_DiscardDeckEffect
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

PidgeotHurricaneEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, HurricaneEffect
	db  $00

SingEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SingEffect
	db  $00

DoTheWaveEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DoTheWave_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, DoTheWave_AIEffect
	db  $00

SwarmEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Swarm_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, Swarm_AIEffect
	db  $00

MoonblastEffectCommands:
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

WhirlwindEffectCommands:
WaterfallEffectCommands:
TerrorStrikeEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Whirlwind_SwitchEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Whirlwind_SelectEffect
	dbw EFFECTCMDTYPE_AI_SWITCH_DEFENDING_PKMN, Whirlwind_SelectEffect
	db  $00

; PorygonConversion1EffectCommands:
; 	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Conversion1_WeaknessCheck
; 	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Conversion1_PlayerSelectEffect
; 	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Conversion1_ChangeWeaknessEffect
; 	dbw EFFECTCMDTYPE_AI_SELECTION, Conversion1_AISelectEffect
; 	db  $00
;
; PorygonConversion2EffectCommands:
; 	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Conversion2_ResistanceCheck
; 	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Conversion2_PlayerSelectEffect
; 	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Conversion2_ChangeResistanceEffect
; 	dbw EFFECTCMDTYPE_AI_SELECTION, Conversion2_AISelectEffect
; 	db  $00

ConversionBeamEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, ConversionBeam_ChangeWeaknessEffect
	db  $00

ChanseyScrunchEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, ScrunchEffect
	db  $00

RaticateSuperFangEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SuperFang_HalfHPEffect
	dbw EFFECTCMDTYPE_AI, SuperFang_AIEffect
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

DragoniteHealingWindEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, HealingWind_InitialEffect
	dbw EFFECTCMDTYPE_PKMN_POWER_TRIGGER, HealingWind_PlayAreaHealEffect
	db  $00

DoubleAttackX40EffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DoubleAttackX40_MultiplierEffect
	dbw EFFECTCMDTYPE_AI, DoubleAttackX40_AIEffect
	db  $00

MorphEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckDiscardPileHasBasicPokemonCards
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, MorphEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Morph_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, Morph_AISelectEffect
	db  $00

Deal10ToAnyPokemonEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Deal10Damage_DamageEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, DealTargetedDamage_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, DealTargetedDamage_AISelectEffect
	db  $00

Deal20ToAnyPokemonEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Deal20Damage_DamageEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, DealTargetedDamage_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, DealTargetedDamage_AISelectEffect
	db  $00

Deal30ToAnyPokemonEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Deal30Damage_DamageEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, DealTargetedDamage_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, DealTargetedDamage_AISelectEffect
	db  $00

PidgeotGaleEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Gale_LoadAnimation
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Gale_SwitchEffect
	db  $00
;	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Whirlwind_SwitchEffect
;	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Whirlwind_SelectEffect
;	dbw EFFECTCMDTYPE_AI_SWITCH_DEFENDING_PKMN, Whirlwind_SelectEffect
;	db  $00
;	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Teleport_SwitchEffect
;	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Teleport_PlayerSelectEffect
;	dbw EFFECTCMDTYPE_AI_SELECTION, Teleport_AISelectEffect
;	db  $00

LeadEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckDeckIsNotEmpty
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SelectedCards_AddToHandFromDeck
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Lead_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, Lead_AISelectEffect
	db  $00


RockHeadEffectCommands:
JigglypuffExpandEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, ExpandEffect
	db  $00

SneakAttackEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SneakAttack_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, SneakAttack_AIEffect
	db  $00

PunishingSlapEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PunishingSlap_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, PunishingSlap_AIEffect
	db  $00

AquaPunchEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, AquaPunch_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, AquaPunch_AIEffect
	db  $00

DragonRageEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DragonRage_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, DragonRage_AIEffect
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
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, EnergyRetrieval_PlayerHandSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, EnergyRetrieval_DiscardAndAddToHandEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, EnergyRetrieval_PlayerDiscardPileSelection
	db  $00

EnergySearchEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckDeckIsNotEmpty
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SelectedCards_AddToHandFromDeck
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
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SelectedCards_AddToHandFromDeck
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
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, BillEffect
	db  $00

LassEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, LassEffect
	db  $00

MaintenanceEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Maintenance_CheckHandAndDiscardPile
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Maintenance_PlayerHandCardSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Maintenance_DiscardAndAddToHandEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Maintenance_PlayerDiscardPileSelection
	db  $00

PokeBallEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckDeckIsNotEmpty
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SelectedCards_AddToHandFromDeck
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
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, EnergyRecycler_PlayerDiscardPileSelection
	db  $00

GiovanniEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Giovanni_BenchCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Giovanni_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Giovanni_SwitchEffect
	db  $00
