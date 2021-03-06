[ENABLE]
{$asm}
/* config symbols */
globalalloc(CFG_ENABLE_INSTANT_SLASH,1)
CFG_ENABLE_INSTANT_SLASH:
db 0x01

globalalloc(CFG_ENABLE_SLASH_SFX,1)
CFG_ENABLE_SLASH_SFX:
db 0x01

globalalloc(CFG_ENABLE_INSTANT_SLASH_DURING_CHRONOS,1)
CFG_ENABLE_INSTANT_SLASH_DURING_CHRONOS:
db 0x01

globalalloc(CFG_IS_CHRONOS_TRIGGER,1)
CFG_IS_CHRONOS_TRIGGER:
db 0x00

globalalloc(CFG_TIMER_INTERVAL,4)
CFG_TIMER_INTERVAL:
dd #30

globalalloc(CFG_CHRONOS_MULT,4)
CFG_CHRONOS_MULT:
dd (float)1.0

globalalloc(CFG_CHRONOS_WITHDRAWL_MULT,4)
CFG_CHRONOS_WITHDRAWL_MULT:
dd (float)2.0

globalalloc(CFG_CHRONOS_KEYBOARD_KEY,4)
CFG_CHRONOS_KEYBOARD_KEY:
dd #49

globalalloc(CFG_CHRONOS_CONTROLLER_BUTTON,4)
CFG_CHRONOS_CONTROLLER_BUTTON:
dd #8

globalalloc(CFG_CHRONOS_BRIGHTNESS_MAX,4)
CFG_CHRONOS_BRIGHTNESS_MAX:
dd (float)2.0

globalalloc(CFG_CHRONOS_SLOW_MIN,4)
CFG_CHRONOS_SLOW_MIN:
dd (float)0.02

globalalloc(CFG_CHRONOS_MAX,4)
CFG_CHRONOS_MAX:
dd #50

globalalloc(CFG_CHRONOS_LIGHT_MIN,4)
CFG_CHRONOS_LIGHT_MIN:
dd (float)0.35


/* CFG_USE_MOVEMENT_MULT and CFG_ENABLE_PLAYER_MOVE were mutually exclusive */
globalalloc(CFG_USE_MOVEMENT_MULT,1)
CFG_USE_MOVEMENT_MULT:
db #0

globalalloc(CFG_ENABLE_PLAYER_MOVE,1)
CFG_ENABLE_PLAYER_MOVE:
db #0

globalalloc(CFG_ENABLE_EXHAUSTION,1)
CFG_ENABLE_EXHAUSTION:
db #1



/* Injection symbols */


globalalloc(GAMESPEED,$32,"sekiro.exe"+B2F2FF)
GAMESPEED:
dd (float)1.0

globalalloc(MAX_BULLET_SPEED_MULT,32,"sekiro.exe"+AFE947)
MAX_BULLET_SPEED_MULT:
dd (float)1.0

globalalloc(ACCELERATION_MULT,32,"sekiro.exe"+AFE65F)
ACCELERATION_MULT:
dd (float)1.0

globalalloc(ACCELERATION_ADD,32,"sekiro.exe"+AFE65F)
ACCELERATION_ADD:
dd (float)0.6

globalalloc(FREEZE_BULLET_TIME,1,"sekiro.exe"+AFD931)
FREEZE_BULLET_TIME:
db 00

globalalloc(RELEASE_BULLET_TIME,1,"sekiro.exe"+AFE65F)
RELEASE_BULLET_TIME:
db 00

globalalloc(ZERO,32,"sekiro.exe"+AFE65F)
ZERO:
dd (float)0.0

globalalloc(ALMOST_ZERO,32,"sekiro.exe"+AFE65F)
ALMOST_ZERO:
dd (float)0.1

globalalloc(MOVEMENT_MULT,32,"sekiro.exe"+AFE65F)
MOVEMENT_MULT:
dd (float)1.0

globalalloc(MOVEMENT_DIST_MULT,32,"sekiro.exe"+136B4DB)
MOVEMENT_DIST_MULT:
dd (float)1.0

//Phantom color
globalalloc(PHANTOM_COLOR_OPACITY,32,"sekiro.exe"+108230F)
PHANTOM_COLOR_OPACITY:
dd (float)0.0

globalalloc(PHANTOM_LIGHT_OPACITY,32,"sekiro.exe"+108242F)
PHANTOM_LIGHT_OPACITY:
dd (float)0.0

globalalloc(PHANTOM_EDGE_RGB,12,"sekiro.exe"+10822CD)

PHANTOM_EDGE_RGB:
dd #0
PHANTOM_EDGE_RGB+4:
dd #255
PHANTOM_EDGE_RGB+8:
dd #255

globalalloc(ENABLE_RAINBOW,1)
ENABLE_RAINBOW:
db #0

globalalloc(PHANTOM_DIFF,4,"sekiro.exe"+0x108223D)
PHANTOM_DIFF:
db 0xff 0xff 0xff 0xff

globalalloc(BULLET_NUM,8,"sekiro.exe"+AF68AA)
BULLET_NUM:
dd #5


//global Lighting
globalalloc(LIGHT_MULTIPLIER,$32,"sekiro.exe"+2487C0)
LIGHT_MULTIPLIER:
dd (float)1.0

LIGHT_MULTIPLIER+4:
dd (float)1.0

LIGHT_MULTIPLIER+8:
dd (float)1.0

LIGHT_MULTIPLIER+0xc:
dd (float)1.0


/*
  Argument for the debug_add_spEffect function
  sets wether the effect is aplied or removed
  The SpEffect Param ID that is applied/removed on attacks has to be set at a special address
*/
globalalloc(Debug_SpEffect_Type,4)
Debug_SpEffect_Type:
dd 0xFFFF

/* Debug Add SpEffect function */
alloc(AddEffect,512,sekiro.exe)
registersymbol(AddEffect)


AddEffect:
mov rcx,[sekiro.exe+3D7A1E0] //playerBase
mov rcx,[rcx+88]
mov rcx,[rcx+11D0]
mov edx,[Debug_SpEffect_Type]
sub rsp,28
call sekiro.exe+BFB3B0  //40 53 48 83 ec 60 48 8b d9 85 d2 0f 84 c6 00 00 00 83 ea 01 0f 84 b3 00 00 00 83 ea 01
add rsp,28
ret



[DISABLE]
{$asm}

dealloc("GAMESPEED")
dealloc("PHANTOM_COLOR_OPACITY")
dealloc("PHANTOM_LIGHT_OPACITY")
dealloc("PHANTOM_EDGE_RED_W")
dealloc("PHANTOM_EDGE_BLUE_W")
dealloc("PHANTOM_EDGE_GREEN_W")
dealloc("PHANTOM_DIFF")
dealloc("LIGHT_MULTIPLIER")
dealloc("Debug_SpEffect_Type")
dealloc("MAX_BULLET_SPEED_MULT")
dealloc("FREEZE_BULLET_TIME")

unregisterSymbol("GAMESPEED")
unregisterSymbol("PHANTOM_COLOR_OPACITY")
unregisterSymbol("PHANTOM_LIGHT_OPACITY")
unregisterSymbol("PHANTOM_EDGE_RED_W")
unregisterSymbol("PHANTOM_EDGE_BLUE_W")
unregisterSymbol("PHANTOM_EDGE_GREEN_W")
unregisterSymbol("PHANTOM_DIFF")
unregisterSymbol("LIGHT_MULTIPLIER")
unregisterSymbol("Debug_SpEffect_Type")
unregisterSymbol("MAX_BULLET_SPEED_MULT")
unregisterSymbol("FREEZE_BULLET_TIME")