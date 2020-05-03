{
  Replace Phantom Param ID
  Phantom color is only used for IDs greater 0
}

define(getPhantomID,"sekiro.exe"+1087891)
define(bytes,41 8B 40 04 89 04 24)

[ENABLE]

assert(getPhantomID,bytes)
alloc(newmem,$1000,"sekiro.exe"+1087891)

label(code)
label(return)

newmem:

code:
  mov eax,[r8+04]
  pushf
  cmp eax,#0
  je set_default_and_exit
  cmp eax,#-1 /* check if is already uses a phantom param || cmp eax,#74 exclude special? npcs phantoms*/
  jne exit_ppr
  cmp [PHANTOM_COLOR_OPACITY],#0 /*check if chronos is active*/
  je reset_ppr_and_exit
  mov eax,#1  /* values > 0 make some phantom enemies invisible */ 
  jmp exit_ppr

set_default_ppr_and_exit:
  mov eax,#-1
  jmp exit_ppr

reset_ppr_and_exit:
  mov eax,#0
exit_ppr:
  mov [rsp],eax
  jmp return

getPhantomID:
  jmp newmem
  nop 2
return:
  popf

[DISABLE]

getPhantomID:
  db bytes

dealloc(newmem)