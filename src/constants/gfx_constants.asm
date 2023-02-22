; screen size
DEF SCREEN_WIDTH  EQU 20 ; tiles
DEF SCREEN_HEIGHT EQU 18 ; tiles

; background map size
DEF BG_MAP_WIDTH  EQU 32 ; tiles
DEF BG_MAP_HEIGHT EQU 32 ; tiles

; cgb palette size
DEF CGB_PAL_SIZE EQU 8 ; bytes
DEF palettes EQUS "* CGB_PAL_SIZE"

DEF NUM_BACKGROUND_PALETTES EQU 8
DEF NUM_OBJECT_PALETTES     EQU 8

DEF PALRGB_WHITE EQU (31 << 10 | 31 << 5 | 31)

; tile size
DEF TILE_SIZE EQU 16 ; bytes
DEF tiles EQUS "* TILE_SIZE"

DEF TILE_SIZE_1BPP EQU 8 ; bytes
DEF tiles_1bpp EQUS "* TILE_SIZE_1BPP"

; icon tile offsets
DEF ICON_TILE_BASIC_POKEMON   EQU $d0
DEF ICON_TILE_STAGE_1_POKEMON EQU $d4
DEF ICON_TILE_STAGE_2_POKEMON EQU $d8
DEF ICON_TILE_TRAINER         EQU $dc

DEF ICON_TILE_FIRE            EQU $e0
DEF ICON_TILE_GRASS           EQU $e4
DEF ICON_TILE_LIGHTNING       EQU $e8
DEF ICON_TILE_WATER           EQU $ec
DEF ICON_TILE_FIGHTING        EQU $f0
DEF ICON_TILE_PSYCHIC         EQU $f4
DEF ICON_TILE_DARKNESS        EQU $f8
DEF ICON_TILE_COLORLESS       EQU $fc
; DEF ICON_TILE_ENERGY          EQU $fc
