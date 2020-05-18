[ENABLE]
{$lua}
if syntaxcheck then return end

  CHRONOS_LIGHT_MIN = 0.35

  chronos_counter = 1
  speed = 0.03
  light_counter = 1

  -- Chronos States and state transitions
  -- Ready | Slowing down | Speeding up -- cant go from Speed to Slow
  TRANS_INIT = 0 --<const>
  S_READY = 1
  TRANS_READY_SLOW = 2

  S_SLOW = 3
  TRANS_SLOW_READY = 4
  TRANS_SLOW_SPEED = 5

  S_SPEED = 6
  TRANS_SPEED_READY = 7

  state = TRANS_INIT

  -- Instant Slash States and state transitions
  -- ready | slashing | waiting for release
  SLASH_TRANS_INIT = 0
  SLASH_S_READY = 1
  SLASH_TRANS_READY_ACTIVE = 2

  SLASH_S_ACTIVE = 3
  SLASH_TRANS_ACTIVE_WAITING = 4

  SLASH_S_WAITING = 5
  SLASH_TRANS_WAITING_READY = 6

  SLASH_S_EX = 7
  SLASH_TRANS_EX_READY = 8
  SLASH_TRANS_ACTIVE_EX = 9

  state_slash = SLASH_TRANS_INIT


  --read config
  CHRONOS_COUNTER_MAX = readInteger(getAddress("CFG_CHRONOS_MAX"))
  enable_instant_slash = readBytes(getAddress("CFG_ENABLE_INSTANT_SLASH"),1)
  enable_slash_sfx = readBytes(getAddress("CFG_ENABLE_SLASH_SFX"),1)
  enable_airtime = readBytes(getAddress("CFG_USE_MOVEMENT_MULT"),1)
  enable_player_during_stopped_time = readBytes(getAddress("CFG_ENABLE_PLAYER_MOVE"),1)
  enable_slash_exhaustion = readBytes(getAddress("CFG_ENABLE_EXHAUSTION"),1)
  is_chronos_trigger = readBytes(getAddress("CFG_IS_CHRONOS_TRIGGER"),1)

  --TIMER_INTERVAL: time in ms to wait between cycles (default:20)
  TIMER_INTERVAL = readInteger(getAddress("CFG_TIMER_INTERVAL"))

  --CHRONOS MULT: sets speed at which chronos mode activates or deactivates
  CHRONOS_MULT = readFloat(getAddress("CFG_CHRONOS_MULT"))
  CHRONOS_WITHDRAWL_MULT = readFloat(getAddress("CFG_CHRONOS_WITHDRAWL_MULT"))

  CHRONOS_KEYBOARD_KEY = readInteger(getAddress("CFG_CHRONOS_KEYBOARD_KEY"))
  CHRONOS_CONTROLLER_BUTTON= readInteger(getAddress("CFG_CHRONOS_CONTROLLER_BUTTON"))
  BRIGHTNESS_MAX = readFloat(getAddress("CFG_CHRONOS_BRIGHTNESS_MAX"))
  SLOW_MIN = readFloat(getAddress("CFG_CHRONOS_SLOW_MIN"))
  CHRONOS_LIGHT_MIN = readFloat(getAddress("CFG_CHRONOS_LIGHT_MIN"))

  CHRONOS_COUNTER_INTERVAL = 0.5 * (TIMER_INTERVAL/10) * CHRONOS_MULT
  CHRONOS_COLOR_INTERVAL = 0.1 * (TIMER_INTERVAL/10) * CHRONOS_MULT
  CHRONOS_LIGHT_INTERVAL = 0.04 * (TIMER_INTERVAL/10) * CHRONOS_MULT


  SLASH_DURATION = 150/TIMER_INTERVAL
  SLASH_DELAY = 800/TIMER_INTERVAL
  SLASH_SPEED = 5
  SLASH_GAUGE_MAX = 100
  SP_EFFECT_ID = 3451
  EXHAUSTION_HKS = 600 --600=sheathe

  slash_counter = 0
  local release_counter = 0 -- used to speed up bullets after chronos ends
  slash_gauge = SLASH_GAUGE_MAX --used to prevent spamming attacks vs bosses
  chronos_button_pressed = 0
  color_intensity = 0
  trigger_triggered = false
  trigger_transition = false


  Game_speed_ptr = getAddress("GAMESPEED")
  Bullet_speed_ptr = getAddress("MAX_BULLET_SPEED_MULT")
  Freeze_bullet_time_ptr = getAddress("FREEZE_BULLET_TIME")
  Bullet_accel_ptr = getAddress("ACCELERATION_MULT")
  Release_bullet_time_ptr = getAddress("RELEASE_BULLET_TIME") -- 0 off 2 on 1 transition to normal
  Player_speed_ptr = getAddress("[[[[sekiro.exe+3B68E30]+88]+1FF8]+28]+D00")
  Movement_mult_ptr = getAddress("MOVEMENT_MULT")
  Phantom_param_ptr = getAddress("PHANTOM_COLOR_OPACITY")
  Light_ptr = getAddress("LIGHT_MULTIPLIER")
  SpEffect_Type_ptr = getAddress("Debug_SpEffect_Type")
  SpEffect_ID_ptr = getAddress("[[[sekiro.exe+3B68E30]+88]+11D0]+24")
  Light_ptr = Light_ptr + 0x8
  Buff_ptr = getAddress("[[[[sekiro.exe+3B858C0]+4B0]+70]+70]+071090") -- ID: 3630 white mibu buff visual

  -- Setup exhaustion buff
  writeInteger(Buff_ptr,2107)
  writeFloat(Buff_ptr+8,-1)
  --writeFloat(Buff_ptr+0x10,0.5) -- maxHPRate   0x94 maxhpchangerate
  writeInteger(Buff_ptr+0x0178,48355) --vfx0 (all mibu buffs signs)
  writeInteger(Buff_ptr+0x0198,-1) --vfx1
  writeInteger(Buff_ptr+0x03C0,-1) -- hksCommand 600=sheate 401=disable combo 590=insane

  writeInteger(SpEffect_Type_ptr,0)
  writeInteger(SpEffect_ID_ptr,3630) --divine confetti
  autoAssemble("CreateThread(AddEffect)")

  --turn off Errors that arise during Loading screens and instead return int
  errorOnLookupFailure(false)



  if(SLOW_MIN>1) then -- maybe add some more sanity checks (but if you want a broken game i won't stop you)
    print("Please choose a minimum chronos slowdown value < 1")
  end


function transition_init()
    state = S_READY
end

  -- Default state, ready to activate chronos mode or instant attack/dash
function state_ready()
    speed = 1.0
    was_SpEffect_successful = true
    was_Player_Speed_write_successful = true

    if(release_counter>0) then
      if(release_counter==1) then
        writeBytes(Release_bullet_time_ptr,0)
        release_counter = 0
     else
        release_counter = release_counter - 1
     end
    end

    if(chronos_button_pressed==1) then
      state = TRANS_READY_SLOW
     end
end

function transition_ready_slow()
  trigger_triggered = false
  trigger_transition = true
  state = S_SLOW
end

--activated chronos mode
function state_slow()
  if(is_chronos_trigger==0) then
    if(chronos_button_pressed==0) then
      state = TRANS_SLOW_SPEED
    end
  else
    if(chronos_button_pressed==1) then
      if(trigger_transition) then
      else
        trigger_triggered = true  --for exit slowdown mode, wait for button release instead
      end
    else
      if(trigger_transition) then
        trigger_transition = false
      else
        if(trigger_triggered) then
          trigger_triggered = false
          state = TRANS_SLOW_SPEED
        end
      end
    end
  end

  if(chronos_counter<CHRONOS_COUNTER_MAX) then
    chronos_counter = chronos_counter + CHRONOS_COUNTER_INTERVAL
    color_intensity = color_intensity + CHRONOS_COLOR_INTERVAL
    light_counter = light_counter + CHRONOS_LIGHT_INTERVAL

    end
    writeBytes(Freeze_bullet_time_ptr,1,1)
end

function transition_slow_ready()
  state = S_READY
end

function transition_slow_speed()
  state = S_SPEED
end

--ending chronos mode
-- speed up game to normal
function state_speed()
    if(chronos_counter>1.5) then
     chronos_counter = chronos_counter - (CHRONOS_COUNTER_INTERVAL * CHRONOS_WITHDRAWL_MULT)
     color_intensity = color_intensity - (CHRONOS_COLOR_INTERVAL * CHRONOS_WITHDRAWL_MULT)
     if(light_counter>1) then
        light_counter = light_counter - (CHRONOS_LIGHT_INTERVAL * CHRONOS_WITHDRAWL_MULT)
      end
     writeBytes(Release_bullet_time_ptr,2)
     writeFloat(Bullet_accel_ptr,chronos_counter*2*CHRONOS_WITHDRAWL_MULT)
    else
      state = TRANS_SPEED_READY
      chronos_counter = 1
      color_intensity = 0
      light_counter = 1
      writeBytes(Freeze_bullet_time_ptr,0)
      writeBytes(Release_bullet_time_ptr,1)
      release_counter = 60 * CHRONOS_WITHDRAWL_MULT
      writeFloat(Bullet_accel_ptr,1)
      writeFloat(Player_speed_ptr,1)
    end
end

function transition_speed_ready()
  state = S_READY
end

  local state_tbl =
  {
  [TRANS_INIT] = transition_init,
  [S_READY] = state_ready, --READY
  [TRANS_READY_SLOW] = transition_ready_slow,
  [S_SLOW] = state_slow, --SLOW
  [TRANS_SLOW_READY] = transition_slow_ready,
  [TRANS_SLOW_SPEED] = transition_slow_speed,
  [S_SPEED] = state_speed, --SPEED
  [TRANS_SPEED_READY] = transition_speed_ready,
  }



-- Slash states

function slash_transition_init()
  state_slash = SLASH_S_READY
end
function slash_state_ready()

  --check if player is attacking
  if((speed_slash_trigger or ((controller_table==nil) and isKeyPressed(1)))) then --check speed slash [optional] (controller_table==nil) 
    state_slash = SLASH_TRANS_READY_ACTIVE
   end

  if(slash_gauge<SLASH_GAUGE_MAX) then
     slash_gauge = slash_gauge + 5 * (TIMER_INTERVAL/20)
  end

  --state_slash = SLASH_S_READY
end

--speed up animation and apply sfx
function slash_transition_ready_active()
  --print("transition ready active")
  slash_gauge = slash_gauge - 25
  slash_counter = 0
  if(enable_slash_sfx>0) then
    if(SpEffect_Type_ptr>0) then
        was_SpEffect_successful = writeInteger(SpEffect_Type_ptr,0)
        was_SpEffect_successful = was_SpEffect_successful and writeInteger(SpEffect_ID_ptr,SP_EFFECT_ID) --divine confetti
        autoAssemble("CreateThread(AddEffect)")
     else
        print("ERROR: Debug_SpEffect_Type not defined " .. getAddress("Debug_SpEffect_Type"))
    end
   end

  if(Player_speed_ptr>0) then
       if(chronos_counter>1) then
          was_Player_Speed_write_successful = writeFloat(Player_speed_ptr, SLASH_SPEED*(1/speed))
       else
          was_Player_Speed_write_successful = writeFloat(Player_speed_ptr, SLASH_SPEED)
       end
   else
       print("ERROR: PLAYER_SPEED not defined " .. getAddress("PLAYER_SPEED"))
  end

  if(not was_SpEffect_successful) then print("could not apply SpEffect") end
  if(not was_Player_Speed_write_successful) then print("could not write to Player speed ptr") end
  
  state_slash = SLASH_S_ACTIVE
end

function slash_state_active()

    slash_counter = slash_counter + 1
    if(slash_counter>=SLASH_DURATION) then
      writeFloat(Player_speed_ptr, 1)
      --sheathe sword when exhausted
      if(slash_gauge<=0 and enable_slash_exhaustion>0) then
        state_slash = SLASH_TRANS_ACTIVE_EX
      end
      if(slash_gauge>0 or enable_slash_exhaustion==0) then --instantly allow follow up slashes if either the gauge is not used up or the gauge is ignored
        state_slash = SLASH_TRANS_ACTIVE_WAITING
        writeInteger(SpEffect_Type_ptr,3)
        writeInteger(SpEffect_ID_ptr,SP_EFFECT_ID) --divine confetti
        autoAssemble("CreateThread(AddEffect)")
      end
    end


  --state_slash = SLASH_TRANS_ACTIVE_WAITING
end

function slash_transition_active_waiting()
  --print("transition active waiting")
  slash_counter = 0
  state_slash = SLASH_S_WAITING
end

-- waiting for button to be released
function slash_state_waiting()
    if((not speed_slash_trigger) and (not isKeyPressed(1))) then
      state_slash = SLASH_TRANS_WAITING_READY
    end
end

function slash_transition_waiting_ready()
  --print("transition waiting ready")
  state_slash = SLASH_S_READY
end

function slash_state_exhaustet()
  slash_counter = slash_counter + 1
  --if(slash_gauge<SLASH_GAUGE_MAX) then
    slash_gauge = slash_gauge + 5 * (TIMER_INTERVAL/20)
  --else
    if(slash_counter>=SLASH_DURATION+SLASH_DELAY) then
      state_slash = SLASH_TRANS_EX_READY
    end
  --end
end


function slash_transition_exhaustet_ready()
  --print("transition ex ready")
  writeInteger(Buff_ptr+0x03C0,-1) --unsheate
  writeInteger(Buff_ptr,2107) --icon
  writeInteger(Buff_ptr+0x0178,48355) --vfx0
  slash_counter = 0
  slash_gauge = SLASH_GAUGE_MAX
  state_slash = SLASH_S_READY
end

function slash_transition_active_exhaustet()
  --print("transition active ex")
  writeInteger(Buff_ptr+0x03C0,EXHAUSTION_HKS) --sheate
  writeInteger(Buff_ptr,2210) --icon
  writeInteger(Buff_ptr+0x0178,48353) --vfx0
  state_slash = SLASH_S_EX
end
local slash_state_tbl =
  {
  [SLASH_TRANS_INIT] = slash_transition_init,
  [SLASH_S_READY] = slash_state_ready, --READY
  [SLASH_TRANS_READY_ACTIVE] = slash_transition_ready_active,
  [SLASH_S_ACTIVE] = slash_state_active, --ACTIVE
  [SLASH_TRANS_ACTIVE_WAITING] = slash_transition_active_waiting,
  [SLASH_S_WAITING] = slash_state_waiting,--WAITING
  [SLASH_TRANS_WAITING_READY] = slash_transition_waiting_ready,
  [SLASH_S_EX] = slash_state_exhaustet,--WAITING
  [SLASH_TRANS_EX_READY] = slash_transition_exhaustet_ready,
  [SLASH_TRANS_ACTIVE_EX] = slash_transition_active_exhaustet,
  }

function read_controller_chronos_trigger()
    if(CHRONOS_CONTROLLER_BUTTON==1) then --GAMEPAD_DPAD_UP
        return (controller_table.GAMEPAD_DPAD_UP)
      end
      if(CHRONOS_CONTROLLER_BUTTON==2) then --GAMEPAD_DPAD_DOWN
        return (controller_table.GAMEPAD_DPAD_DOWN)
      end
      if(CHRONOS_CONTROLLER_BUTTON==3) then --GAMEPAD_DPAD_LEFT
        return (controller_table.GAMEPAD_DPAD_LEFT)
      end
      if(CHRONOS_CONTROLLER_BUTTON==4) then --GAMEPAD_DPAD_RIGHT
        return (controller_table.GAMEPAD_DPAD_RIGHT)
      end
      if(CHRONOS_CONTROLLER_BUTTON==5) then --GAMEPAD_START
        return (controller_table.GAMEPAD_START)
      end
      if(CHRONOS_CONTROLLER_BUTTON==6) then --GAMEPAD_BACK
        return (controller_table.GAMEPAD_BACK)
      end
      if(CHRONOS_CONTROLLER_BUTTON==7) then --GAMEPAD_LEFT_THUMB
        return (controller_table.GAMEPAD_LEFT_THUMB)
      end

      if(CHRONOS_CONTROLLER_BUTTON==8) then --GAMEPAD_RIGHT_THUMB (default)
        return (controller_table.GAMEPAD_RIGHT_THUMB)
      end

      if(CHRONOS_CONTROLLER_BUTTON==9) then --GAMEPAD_LEFT_SHOULDER
        return (controller_table.GAMEPAD_LEFT_SHOULDER)
      end
      if(CHRONOS_CONTROLLER_BUTTON==10) then --GAMEPAD_RIGHT_SHOULDER
        return (controller_table.GAMEPAD_RIGHT_SHOULDER)
      end

      if(CHRONOS_CONTROLLER_BUTTON==11) then --GAMEPAD_A
        return (controller_table.GAMEPAD_A)
      end
      if(CHRONOS_CONTROLLER_BUTTON==12) then --GAMEPAD_B
        return (controller_table.GAMEPAD_B)
      end
      if(CHRONOS_CONTROLLER_BUTTON==13) then --GAMEPAD_X
        return (controller_table.GAMEPAD_X)
      end
      if(CHRONOS_CONTROLLER_BUTTON==14) then --GAMEPAD_Y
        return (controller_table.GAMEPAD_Y)
      end

      if(CHRONOS_CONTROLLER_BUTTON==15) then --LeftTrigger (default in Katana Zero)
        return (controller_table.LeftTrigger>30) --cant use left trigger near grappling nodes
      end

      if(CHRONOS_CONTROLLER_BUTTON==16) then --RightTrigger
        return (controller_table.RightTrigger>30) --Tool
      end

      if(CHRONOS_CONTROLLER_BUTTON==17) then --ThumbLeftX
        return (math.abs(controller_table.ThumbLeftX)>5000) --Why would you use these?
      end
      if(CHRONOS_CONTROLLER_BUTTON==18) then --ThumbLeftY
        return (math.abs(controller_table.ThumbLeftY)>5000)
      end
      if(CHRONOS_CONTROLLER_BUTTON==19) then --ThumbRightX
        return (math.abs(controller_table.ThumbRightX)>5000)
      end
      if(CHRONOS_CONTROLLER_BUTTON==20) then --ThumbRightY
        return (math.abs(controller_table.ThumbRightY)>5000)
      end
end



  --main function
function checkChronosInput()
      Player_speed_ptr=getAddress("[[[[sekiro.exe+3B68E30]+88]+1FF8]+28]+D00") -- player speed address can change during loading screens
      SpEffect_ID_ptr=getAddress("[[[sekiro.exe+3B68E30]+88]+11D0]+24")

      if(Player_speed_ptr==0) then --don't write to uninitialized memory during loading screens
        inLoadingScreen = 1
        return
      end

      if(inLoadingScreen==1) then --exit loading screen
        writeInteger(SpEffect_Type_ptr,0)
        writeInteger(SpEffect_ID_ptr,3630) --divine confetti
        autoAssemble("CreateThread(AddEffect)")
        inLoadingScreen = 0
      end

      controller_table = getXBox360ControllerState()

      if(controller_table==nil) then
        chronos_trigger = false
        speed_slash_trigger = false
      else

      --controllerID = controller_table.ControllerID
      --print("Controller ID: " .. controllerID)

      chronos_trigger = false

      chronos_trigger = read_controller_chronos_trigger()

      speed_slash_trigger = controller_table.GAMEPAD_RIGHT_SHOULDER
     end

     if(chronos_trigger or isKeyPressed(CHRONOS_KEYBOARD_KEY)) then
       chronos_button_pressed = 1
     else
       chronos_button_pressed = 0
     end

    local current_state_function = state_tbl[state]
    if(current_state_function) then
      current_state_function()
    else
    print("Error: State out of range")
    print(state)
    end

    if((1/light_counter)>CHRONOS_LIGHT_MIN) then
      writeFloat(Light_ptr,1/light_counter)
    else
      writeFloat(Light_ptr,CHRONOS_LIGHT_MIN)
    end

    speed = (1/chronos_counter)
    --print("Chronos counter: " .. chronos_counter)
    --print("Color intensity: " .. color_intensity)

    if(speed<SLOW_MIN) then
      speed = SLOW_MIN
    end

    if(enable_instant_slash>0) then
      local current_slash_state_function = slash_state_tbl[state_slash]
      if(current_slash_state_function) then
        current_slash_state_function()
      else
        print("Error: Slash State out of range")
        print(slash_state)
      end
    end


     writeFloat(Game_speed_ptr,speed)
     writeFloat(Bullet_speed_ptr,speed)

     -- enable Player during stopped time
     if((enable_player_during_stopped_time>0) and (state>S_READY)) then
      writeFloat(Player_speed_ptr, (1/speed))
     end

     if(enable_airtime>0) then
        writeFloat(Movement_mult_ptr,speed)
     end

    if(color_intensity>=BRIGHTNESS_MAX) then
      color_intensity = BRIGHTNESS_MAX
    else
      if(color_intensity<0) then
        color_intensity=0
      end
    end
    writeFloat(Phantom_param_ptr,color_intensity)

  end

  if(chronosInputTimer == nil) then
    chronosInputTimer = createTimer(getMainForm())
    chronosInputTimer.Interval = TIMER_INTERVAL
    chronosInputTimer.OnTimer = function(timer)
      checkChronosInput()
    end
end


chronosInputTimer.setEnabled(true)


[DISABLE]
{$lua}
if syntaxcheck then return end
  if chronosInputTimer ~= nil then
    chronosInputTimer.setEnabled(false)
  end
  chronosInputTimer.destroy()
  chronosInputTimer = nil
