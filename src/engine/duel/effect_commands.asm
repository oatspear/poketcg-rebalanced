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

HealingNectarEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, SetCarryNullEffect
	db  $00

EkansSpitPoisonEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SpitPoison_Poison50PercentEffect
	dbw EFFECTCMDTYPE_AI, SpitPoison_AIEffect
	db  $00

ArbokPoisonFangEffectCommands:
PoisonClawsEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PoisonEffect
	dbw EFFECTCMDTYPE_AI, PoisonFang_AIEffect
	db  $00

WeepinbellPoisonPowderEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Poison50PercentEffect
	dbw EFFECTCMDTYPE_AI, WeepinbellPoisonPowder_AIEffect
	db  $00

LureEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Lure_AssertPokemonInBench
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Lure_SwitchDefendingPokemon
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Lure_SelectSwitchPokemon
	dbw EFFECTCMDTYPE_AI_SELECTION, Lure_GetBenchPokemonWithLowestHP
	db  $00

PoisonLureEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Lure_AssertPokemonInBench
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, PoisonLure_SwitchEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Lure_SelectSwitchPokemon
	dbw EFFECTCMDTYPE_AI_SELECTION, Lure_GetBenchPokemonWithLowestHP
	db  $00

AcidEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, UnableToRetreatEffect
	db  $00

FlytrapEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, UnableToRetreatEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Heal20DamageEffect
	db  $00

SproutEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Sprout_DeckCheck
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Sprout_AddToHandEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Sprout_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, Sprout_AISelectEffect
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

ZubatSupersonicEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, ZubatSupersonicEffect
	db  $00

AscensionEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, DeckIsNotEmptyCheck
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Ascension_EvolveEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Ascension_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, Ascension_AISelectEffect
	db  $00

HatchEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, DeckIsNotEmptyCheck
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Hatch_EvolveEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Hatch_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, Hatch_AISelectEffect
	db  $00

PoisonEvolutionEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, DeckIsNotEmptyCheck
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
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Teleport_CheckBench
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Teleport_SwitchEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Teleport_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, Teleport_AISelectEffect
	db  $00

ExeggutorBigEggsplosionEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, BigEggsplosion_MultiplierEffect
	dbw EFFECTCMDTYPE_AI, BigEggsplosion_AIEffect
	db  $00

NidokingThrashEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Thrash_ModifierEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Thrash_RecoilEffect
	dbw EFFECTCMDTYPE_AI, Thrash_AIEffect
	db  $00

ToxicEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DoublePoisonEffect
	; dbw EFFECTCMDTYPE_AI, Toxic_AIEffect
	db  $00

NidoqueenBoyfriendsEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, BoyfriendsEffect
	db  $00

NidoranFFurySwipesEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, NidoranFFurySwipes_MultiplierEffect
	dbw EFFECTCMDTYPE_AI, NidoranFFurySwipes_AIEffect
	db  $00

PeckEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Peck_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, Peck_AIEffect
	db  $00

RagingStormEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, RagingStorm_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, RagingStorm_AIEffect
	db  $00

CrabhammerEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Crabhammer_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, Crabhammer_AIEffect
	db  $00

ClawEffectCommands:
HornHazardEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, HornHazard_NoDamage50PercentEffect
	dbw EFFECTCMDTYPE_AI, HornHazard_AIEffect
	db  $00

NidorinaSupersonicEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, NidorinaSupersonicEffect
	db  $00

NidorinaDoubleKickEffectCommands:
;	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DoubleAttackX30_MultiplierEffect
;	dbw EFFECTCMDTYPE_AI, DoubleAttackX30_AIEffect
;	db  $00

TwineedleEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DoubleAttackX20X10_MultiplierEffect
	dbw EFFECTCMDTYPE_AI, DoubleAttackX20X10_AIEffect
	db  $00

MarowakBonemerangEffectCommands:
NidorinoDoubleKickEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DoubleAttackX30_MultiplierEffect
	dbw EFFECTCMDTYPE_AI, DoubleAttackX30_AIEffect
	db  $00

Heal20DamageEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Heal20DamageEffect
	db  $00

WeedlePoisonStingEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Poison50PercentEffect
	dbw EFFECTCMDTYPE_AI, WeedlePoisonSting_AIEffect
	db  $00

IvysaurPoisonWhipEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PoisonEffect
	dbw EFFECTCMDTYPE_AI, IvysaurPoisonWhip_AIEffect
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

GrimerMinimizeEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, GrimerMinimizeEffect
	db  $00

MukToxicGasEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, ToxicGasEffect
	db  $00

MukSludgeEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Poison50PercentEffect
	dbw EFFECTCMDTYPE_AI, Sludge_AIEffect
	db  $00

WeezingSmogEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Poison50PercentEffect
	dbw EFFECTCMDTYPE_AI, WeezingSmog_AIEffect
	db  $00

VenomothShiftEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Shift_OncePerTurnCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Shift_ChangeColorEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Shift_PlayerSelectEffect
	db  $00

VenomothVenomPowderEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, VenomPowder_PoisonConfusion50PercentEffect
	dbw EFFECTCMDTYPE_AI, VenomPowder_AIEffect
	db  $00

TangelaPoisonPowderEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PoisonEffect
	dbw EFFECTCMDTYPE_AI, TangelaPoisonPowder_AIEffect
	db  $00

PokemonPowerHealEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Heal_OncePerTurnCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Heal_RemoveDamageEffect
	db  $00

PetalDanceEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, PetalDance_BonusEffect
	db  $00

TangelaPoisonWhipEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PoisonEffect
	dbw EFFECTCMDTYPE_AI, PoisonWhip_AIEffect
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

OmastarWaterGunEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, OmastarWaterGunEffect
	dbw EFFECTCMDTYPE_AI, OmastarWaterGunEffect
	db  $00

OmastarSpikeCannonEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, OmastarSpikeCannon_MultiplierEffect
	dbw EFFECTCMDTYPE_AI, OmastarSpikeCannon_AIEffect
	db  $00

OmanyteClairvoyanceEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, ClairvoyanceEffect
	db  $00

WaterGun1WEffectCommands:
OmanyteWaterGunEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, OmanyteWaterGunEffect
	dbw EFFECTCMDTYPE_AI, OmanyteWaterGunEffect
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

PsyduckFurySwipesEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PsyduckFurySwipes_MultiplierEffect
	dbw EFFECTCMDTYPE_AI, PsyduckFurySwipes_AIEffect
	db  $00

SeadraWaterGunEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SeadraWaterGunEffect
	dbw EFFECTCMDTYPE_AI, SeadraWaterGunEffect
	db  $00

SeadraAgilityEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SeadraAgilityEffect
	db  $00

ShellderSupersonicEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, ShellderSupersonicEffect
	db  $00

VaporeonWaterGunEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, VaporeonWaterGunEffect
	dbw EFFECTCMDTYPE_AI, VaporeonWaterGunEffect
	db  $00

WithdrawEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, WithdrawEffect
	db  $00

HorseaSmokescreenEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, HorseaSmokescreenEffect
	db  $00

TentacruelSupersonicEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, TentacruelSupersonicEffect
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

PoliwhirlDoubleslapEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PoliwhirlDoubleslap_MultiplierEffect
	dbw EFFECTCMDTYPE_AI, PoliwhirlDoubleslap_AIEffect
	db  $00

PoliwrathWaterGunEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PoliwrathWaterGunEffect
	dbw EFFECTCMDTYPE_AI, PoliwrathWaterGunEffect
	db  $00

PoliwagWaterGunEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PoliwagWaterGunEffect
	dbw EFFECTCMDTYPE_AI, PoliwagWaterGunEffect
	db  $00

CloysterSpikeCannonEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, CloysterSpikeCannon_MultiplierEffect
	dbw EFFECTCMDTYPE_AI, CloysterSpikeCannon_AIEffect
	db  $00

StarmieStarFreezeEffectCommands:
AbraPsyshockEffectCommands:
GastlyLickEffectCommands:
MewPsyshockEffectCommands:
SlowbroPsyshockEffectCommands:
ElectabuzzThundershockEffectCommands:
MagnemiteThunderWaveEffectCommands:
FlyingPikachuThundershockEffectCommands:
PikachuLv16ThundershockEffectCommands:
PikachuAltLv16ThundershockEffectCommands:
MagnetonThunderWaveEffectCommands:
JolteonStunNeedleEffectCommands:
SnorlaxBodySlamEffectCommands:
EkansWrapEffectCommands:
PinsirIronGripEffectCommands:
CloysterClampEffectCommands:
CaterpieStringShotEffectCommands:
VenonatStunSporeEffectCommands:
MetapodStunSporeEffectCommands:
GrimerNastyGooEffectCommands:
TangelaBindEffectCommands:
TangelaStunSporeEffectCommands:
GyaradosBubblebeamEffectCommands:
GolduckPsyshockEffectCommands:
DewgongIceBeamEffectCommands:
SquirtleBubbleEffectCommands:
ArticunoFreezeDryEffectCommands:
Paralysis50PercentEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Paralysis50PercentEffect
	db  $00

CowardiceEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Cowardice_Check
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Cowardice_RemoveFromPlayAreaEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Cowardice_PlayerSelectEffect
	db  $00

AdaptiveEvolutionEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, AdaptiveEvolution_InitialEffect
	dbw EFFECTCMDTYPE_PKMN_POWER_TRIGGER, AdaptiveEvolution_AllowEvolutionEffect
	db  $00

SilverWhirlwindEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SleepOrPoisonEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Whirlwind_SwitchEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Whirlwind_SelectEffect
	dbw EFFECTCMDTYPE_AI_SWITCH_DEFENDING_PKMN, Whirlwind_SelectEffect
	db  $00

LaprasWaterGunEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, LaprasWaterGunEffect
	dbw EFFECTCMDTYPE_AI, LaprasWaterGunEffect
	db  $00

LaprasConfuseRayEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Confusion50PercentEffect
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

KangaskhanCometPunchEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Heads10BonusDamage_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, CometPunch_AIEffect
	db  $00

ArcanineFlamesOfRageEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, FlamesOfRage_CheckEnergy
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, FlamesOfRage_PlayerSelectEffect
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, FlamesOfRage_DamageBoostEffect
	dbw EFFECTCMDTYPE_DISCARD_ENERGY, FlamesOfRage_DiscardEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, FlamesOfRage_AISelectEffect
	dbw EFFECTCMDTYPE_AI, FlamesOfRage_AIEffect
	db  $00

RapidashStompEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, RapidashStomp_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, RapidashStomp_AIEffect
	db  $00

RapidashAgilityEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, RapidashAgilityEffect
	db  $00

EmberEffectCommands:
FlamethrowerEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckAnyEnergiesAttached
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, DiscardEnergy_PlayerSelectEffect
	dbw EFFECTCMDTYPE_DISCARD_ENERGY, DiscardEnergy_DiscardEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, DiscardEnergy_AISelectEffect
	db  $00

MoltresWildfireEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Wildfire_CheckEnergy
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Wildfire_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Wildfire_DiscardDeckEffect
	dbw EFFECTCMDTYPE_DISCARD_ENERGY, Wildfire_DiscardEnergyEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, Wildfire_AISelectEffect
	db  $00

MoltresLv35DiveBombEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, MoltresLv35DiveBomb_Success50PercentEffect
	dbw EFFECTCMDTYPE_AI, MoltresLv35DiveBomb_AIEffect
	db  $00

MagmarSmokescreenEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, MagmarSmokescreenEffect
	db  $00

MagmarSmogEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Poison50PercentEffect
	dbw EFFECTCMDTYPE_AI, MagmarSmog_AIEffect
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

VulpixConfuseRayEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Confusion50PercentEffect
	db  $00

RageEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Rage_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, Rage_AIEffect
	db  $00

NinetalesMixUpEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, MixUpEffect
	db  $00

NinetalesDancingEmbersEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DancingEmbers_MultiplierEffect
	dbw EFFECTCMDTYPE_AI, DancingEmbers_AIEffect
	db  $00

MoltresFiregiverEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Firegiver_InitialEffect
	dbw EFFECTCMDTYPE_PKMN_POWER_TRIGGER, Firegiver_AddToHandEffect
	db  $00

MoltresLv37DiveBombEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, MoltresLv37DiveBomb_Success50PercentEffect
	dbw EFFECTCMDTYPE_AI, MoltresLv37DiveBomb_AIEffect
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
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CheckAnyEnergiesAttached
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, DiscardEnergy_PlayerSelectEffect
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, ApplyDestinyBondEffect
	dbw EFFECTCMDTYPE_DISCARD_ENERGY, DiscardEnergy_DiscardEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, DiscardEnergy_AISelectEffect
	db  $00

EnergyConversionEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, EnergyConversion_CheckEnergy
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, EnergyConversion_AddToHandEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, EnergyConversion_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, EnergyConversion_AISelectEffect
	db  $00

InflictSleepEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SleepEffect
	db  $00

HaunterDreamEaterEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, DreamEaterEffect
	db  $00

HaunterTransparencyEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, TransparencyEffect
	db  $00

HypnoProphecyEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Prophecy_CheckDeck
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Prophecy_ReorderDeckEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Prophecy_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, Prophecy_AISelectEffect
	db  $00

DrowzeeConfuseRayEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Confusion50PercentEffect
	db  $00

MrMimeInvisibleWallEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, InvisibleWallEffect
	db  $00

RendEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Rend_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, Rend_AIEffect
	db  $00

MrMimeMeditateEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, MrMimeMeditate_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, MrMimeMeditate_AIEffect
	db  $00

AlakazamDamageSwapEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, DamageSwap_CheckDamage
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DamageSwap_SelectAndSwapEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, DamageSwap_SwapEffect
	db  $00

AlakazamConfuseRayEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, ConfusionEffect
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

MewNeutralizingShieldEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, NeutralizingShieldEffect
	db  $00

MewtwoPsychicEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Psychic_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, Psychic_AIEffect
	db  $00

MewtwoBarrierEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Barrier_CheckEnergy
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Barrier_PlayerSelectEffect
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Barrier_BarrierEffect
	dbw EFFECTCMDTYPE_DISCARD_ENERGY, Barrier_DiscardEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, Barrier_AISelectEffect
	db  $00

EnergyAbsorptionEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, EnergyAbsorption_CheckDiscardPile
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, EnergyAbsorption_AttachToPokemonEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, EnergyAbsorption_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, EnergyAbsorption_AISelectEffect
	db  $00

EnergySporesEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, EnergySpores_CheckDiscardPile
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, AttachEnergyFromDiscard_AttachToPokemonEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, EnergySpores_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, EnergySpores_AISelectEffect
	db  $00

SpacingOutEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, SpacingOut_CheckDamage
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SpacingOut_Success50PercentEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, SpacingOut_HealEffect
	db  $00

ScavengeEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Scavenge_CheckDiscardPile
	; dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Scavenge_PlayerSelectEnergyEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Scavenge_AddToHandEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Scavenge_PlayerSelectTrainerEffect
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

JynxDoubleslapEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, JynxDoubleslap_MultiplierEffect
	dbw EFFECTCMDTYPE_AI, JynxDoubleslap_AIEffect
	db  $00

JynxMeditateEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, JynxMeditate_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, JynxMeditate_AIEffect
	db  $00

MewMysteryAttackEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, MysteryAttack_RandomEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, MysteryAttack_RecoverEffect
	dbw EFFECTCMDTYPE_AI, MysteryAttack_AIEffect
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

MachampStrikesBackEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, StrikesBackEffect
	db  $00

BattleArmorEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, BattleArmorEffect
	db  $00

KabutoKabutoArmorEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, KabutoArmorEffect
	db  $00

KabutopsAbsorbEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, AbsorbEffect
	db  $00

CuboneSnivelEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SnivelEffect
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

Selfdestruct80Bench20EffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Selfdestruct80Bench20Effect
	db  $00

Selfdestruct100Bench20EffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Selfdestruct100Bench20Effect
	db  $00

WeezingSelfdestructEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Selfdestruct60Bench10Effect
	db  $00

GolemSelfdestructEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Selfdestruct100Bench20Effect
	db  $00

ZapdosThunderEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, ZapdosThunder_Recoil50PercentEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, ZapdosThunder_RecoilEffect
	db  $00

ZapdosThunderboltEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, ThunderboltEffect
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

PikachuThunderJoltEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, ThunderJolt_Recoil50PercentEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, ThunderJolt_RecoilEffect
	db  $00

SparkEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Spark_BenchDamageEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Spark_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, Spark_AISelectEffect
	db  $00

BulbasaurGrowlEffectCommands:
PikachuLv16GrowlEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PikachuLv16GrowlEffect
	db  $00

PikachuAltLv16GrowlEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PikachuAltLv16GrowlEffect
	db  $00

ChainLightningEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, ChainLightningEffect
	db  $00

RaichuAgilityEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, RaichuAgilityEffect
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
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Sonicboom_NullEffect
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

EnergySpikeEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, EnergySpike_DeckCheck
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, EnergySpike_AttachEnergyEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, EnergySpike_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, EnergySpike_AISelectEffect
	db  $00

JolteonDoubleKickEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, JolteonDoubleKick_MultiplierEffect
	dbw EFFECTCMDTYPE_AI, JolteonDoubleKick_AIEffect
	db  $00

EeveeTailWagEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, TailWagEffect
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

SnorlaxThickSkinnedEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, ThickSkinnedEffect
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

ClefableMetronomeEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, ClefableMetronome_CheckAttacks
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, ClefableMetronome_UseAttackEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, ClefableMetronome_AISelectEffect
	db  $00

ClefableMinimizeEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, ClefableMinimizeEffect
	db  $00

PidgeotHurricaneEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, HurricaneEffect
	db  $00

SingEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SingEffect
	db  $00

ClefairyMetronomeEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, ClefairyMetronome_CheckAttacks
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, ClefairyMetronome_UseAttackEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, ClefairyMetronome_AISelectEffect
	db  $00

WigglytuffDoTheWaveEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DoTheWaveEffect
	dbw EFFECTCMDTYPE_AI, DoTheWaveEffect
	db  $00

MoonblastEffectCommands:
PersianPounceEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PounceEffect
	db  $00

LickitungSupersonicEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, LickitungSupersonicEffect
	db  $00

WhirlwindEffectCommands:
WaterfallEffectCommands:
TerrorStrikeEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Whirlwind_SwitchEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Whirlwind_SelectEffect
	dbw EFFECTCMDTYPE_AI_SWITCH_DEFENDING_PKMN, Whirlwind_SelectEffect
	db  $00

PorygonConversion1EffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Conversion1_WeaknessCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Conversion1_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Conversion1_ChangeWeaknessEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, Conversion1_AISelectEffect
	db  $00

PorygonConversion2EffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Conversion2_ResistanceCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Conversion2_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Conversion2_ChangeResistanceEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, Conversion2_AISelectEffect
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

DittoMorphEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, MorphEffect
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
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Whirlwind_SwitchEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Whirlwind_SelectEffect
	dbw EFFECTCMDTYPE_AI_SWITCH_DEFENDING_PKMN, Whirlwind_SelectEffect
	db  $00
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Teleport_SwitchEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Teleport_PlayerSelectEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, Teleport_AISelectEffect
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

DragonRageEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DragonRage_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, DragonRage_AIEffect
	db  $00

FungalGrowthEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SleepEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, LeechLifeEffect
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

EnergyRemovalEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, EnergyRemoval_EnergyCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, EnergyRemoval_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, EnergyRemoval_DiscardEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, EnergyRemoval_AISelection
	db  $00

EnergyRetrievalEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, EnergyRetrieval_HandEnergyCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, EnergyRetrieval_PlayerHandSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, EnergyRetrieval_DiscardAndAddToHandEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, EnergyRetrieval_PlayerDiscardPileSelection
	db  $00

EnergySearchEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, EnergySearch_DeckCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, EnergySearch_AddToHandEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, EnergySearch_PlayerSelection
	db  $00

ProfessorOakEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, ProfessorOakEffect
	db  $00

PotionEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Potion_DamageCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Potion_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Potion_HealEffect
	db  $00

GamblerEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, GamblerEffect
	db  $00

ItemFinderEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, ItemFinder_HandDiscardPileCheck
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
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, FullHeal_StatusCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, FullHeal_ClearStatusEffect
	db  $00

ImposterProfessorOakEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, ImposterProfessorOakEffect
	db  $00

ComputerSearchEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, ComputerSearch_HandDeckCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, ComputerSearch_PlayerDiscardHandSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, ComputerSearch_DiscardAddToHandEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, ComputerSearch_PlayerDeckSelection
	db  $00

ClefairyDollEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, ClefairyDoll_BenchCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, ClefairyDoll_PlaceInPlayAreaEffect
	db  $00

MrFujiEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, MrFuji_BenchCheck
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
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, PokemonCenter_DamageCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PokemonCenter_HealDiscardEnergyEffect
	db  $00

PokemonFluteEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, PokemonFlute_BenchCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, PokemonFlute_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PokemonFlute_PlaceInPlayAreaText
	db  $00

PokemonBreederEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, PokemonBreeder_HandPlayAreaCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, PokemonBreeder_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PokemonBreeder_EvolveEffect
	db  $00

ScoopUpEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, ScoopUp_BenchCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, ScoopUp_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, ScoopUp_ReturnToHandEffect
	db  $00

PokemonTraderEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, PokemonTrader_HandDeckCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, PokemonTrader_PlayerHandSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PokemonTrader_TradeCardsEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, PokemonTrader_PlayerDeckSelection
	db  $00

PokedexEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Pokedex_DeckCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Pokedex_OrderDeckCardsEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Pokedex_PlayerSelection
	db  $00

BillEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, BillEffect
	db  $00

LassEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, LassEffect
	db  $00

MaintenanceEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Maintenance_HandCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Maintenance_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Maintenance_ReturnToDeckAndDrawEffect
	db  $00

PokeBallEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, PokeBall_DeckCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PokeBall_AddToHandEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, PokeBall_PlayerSelection
	db  $00

RecycleEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Recycle_DiscardPileCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Recycle_AddToHandEffect
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

SuperEnergyRemovalEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, SuperEnergyRemoval_EnergyCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, SuperEnergyRemoval_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SuperEnergyRemoval_DiscardEffect
	db  $00

SuperEnergyRetrievalEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, SuperEnergyRetrieval_HandEnergyCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, SuperEnergyRetrieval_PlayerHandSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SuperEnergyRetrieval_DiscardAndAddToHandEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, SuperEnergyRetrieval_PlayerDiscardPileSelection
	db  $00

GustOfWindEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, GustOfWind_BenchCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, GustOfWind_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, GustOfWind_SwitchEffect
	db  $00
