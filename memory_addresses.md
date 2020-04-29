## World Speed Multiplier
"sekiro.exe"+B2F2FF
F3 0F 59 83 60 09 00 00

## All Phantom Param ID
"sekiro.exe"+1087891
41 8B 40 04 89 04 24

## Phantom Edge color Alpha replace
"sekiro.exe"+108230F
F3 41 0F 10 00

## Phantom Light opacity
"sekiro.exe"+108242F
F3 41 0F 10 40 10

## Phantom Edge RGB
"sekiro.exe"+10822CD
41 0F B6 40 14

## Phantom Diffuse RGB
"sekiro.exe"+108223D
41 0F B6 40 1A

## global illumination
"sekiro.exe"+2487C0
0F 28 05 29 24 EB 02

(+8)

## slashcutrate
"sekiro.exe"+1088EA4
F3 0F 10 40 1C

## shot damage
"sekiro.exe"+1088F38
F3 0F 10 80 98 03 00 00

## Debug add spEffect
```x86asm
alloc(AddEffect,512,sekiro.exe)
registersymbol(AddEffect)


AddEffect:
mov rcx,[sekiro.exe+3B68E30] //playerBase
mov rcx,[rcx+88]
mov rcx,[rcx+11D0]
mov edx,[Debug_SpEffect_Type]
sub rsp,28
call sekiro.exe+BE4290 // 140BE3BE0 //40 53 48 83 ec 60 48 8b d9 85 d2 0f 84 c6 00 00 00 83 ea 01 0f 84 b3 00 00 00 83 ea 01
add rsp,28
ret
```