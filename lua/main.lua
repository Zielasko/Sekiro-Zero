[ENABLE]
{$lua}
if syntaxcheck then return end

  CHRONOS_LIGHT_MIN = 0.35

  chronos_counter = 1
  speed = 0.03
  light_counter = 1

  --read config
  CHRONOS_COUNTER_MAX = readInteger(getAddress("CFG_CHRONOS_MAX"))
  enable_instant_slash = readBytes(getAddress("CFG_ENABLE_INSTANT_SLASH"),1)
  enable_slash_sfx = readBytes(getAddress("CFG_ENABLE_SLASH_SFX"),1)
  enable_airtime = readBytes(getAddress("CFG_USE_MOVEMENT_MULT"),1)

  --TIMER_INTERVAL: time in ms to wait between cycles (default:20)
  TIMER_INTERVAL = readInteger(getAddress("CFG_TIMER_INTERVAL"))

  --CHRONOS MULT: sets speed at which chronos mode activates or deactivates
  CHRONOS_MULT = readFloat(getAddress("CFG_CHRONOS_MULT"))
  CHRONOS_WITHDRAWL_MULT = readFloat(getAddress("CFG_CHRONOS_WITHDRAWL_MULT"))

  CHRONOS_KEYBOARD_KEY = readInteger(getAddress("CFG_CHRONOS_KEYBOARD_KEY"))
  CHRONOS_CONTROLLER_BUTTON= readInteger(getAddress("CFG_CHRONOS_CONTROLLER_BUTTON"))
  BRIGHTNESS_MAX = readFloat(getAddress("CFG_CHRONOS_BRIGHTNESS_MAX"))


  CHRONOS_COUNTER_INTERVAL = 0.5 * (TIMER_INTERVAL/10) * CHRONOS_MULT
  CHRONOS_COLOR_INTERVAL = 0.1 * (TIMER_INTERVAL/10) * CHRONOS_MULT
  CHRONOS_LIGHT_INTERVAL = 0.04 * (TIMER_INTERVAL/10) * CHRONOS_MULT


  SLASH_DURATION = 150/TIMER_INTERVAL
  SLASH_SPEED = 5
  SP_EFFECT_ID = 3451

  local state = 0 -- 0 ready 1 slowing down 2 speeding up -- cant go from 2 to 1
  local state_slash = 0 -- 0 ready 1 slashing 2 waiting for release
  local slash_counter = 0
  chronos_button_pressed = 0
  color_intensity = 0



  Game_speed_ptr = getAddress("GAMESPEED")
  Bullet_speed_ptr = getAddress("MAX_BULLET_SPEED_MULT")
  Freeze_bullet_time_ptr = getAddress("FREEZE_BULLET_TIME")
  Bullet_accel_ptr = getAddress("ACCELERATION_MULT")
  Release_bullet_time_ptr = getAddress("RELEASE_BULLET_TIME")
  Player_speed_ptr = getAddress("[[[[sekiro.exe+3B68E30]+88]+1FF8]+28]+D00")
  Movement_mult_ptr = getAddress("MOVEMENT_MULT")
  Phantom_param_ptr = getAddress("PHANTOM_COLOR_OPACITY")
  Light_ptr = getAddress("LIGHT_MULTIPLIER")
  SpEffect_Type_ptr = getAddress("Debug_SpEffect_Type")
  SpEffect_ID_ptr = getAddress("[[[sekiro.exe+3B68E30]+88]+11D0]+24")
  Light_ptr = Light_ptr + 0x8

  errorOnLookupFailure(false) --turn off Errors that arise during Loading screens

  -- Default state, ready to activate chronos mode or instant attack/dash
function state_ready()
    speed = 1.0
    was_SpEffect_successful = true
    was_Player_Speed_write_successful = true

    if((speed_slash_trigger or ((controller_table==nil) and isKeyPressed(1))) and (state_slash==0) and (enable_instant_slash>0)) then --check speed slash
     state_slash = 1
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
          was_Player_Speed_write_successful = writeFloat(Player_speed_ptr, SLASH_SPEED)
      else
          print("ERROR: PLAYER_SPEED not defined " .. getAddress("PLAYER_SPEED"))
     end

     if(not was_SpEffect_successful) then print("could not apply SpEffect") end
     if(not was_Player_Speed_write_successful) then print("could not write to Player speed ptr") end

    end

    if(chronos_button_pressed==1) then
     state = 1
    end
end

--activated chronos mode
function state_slow()
    if(chronos_button_pressed==0) then
      state = 2
      return
    end

  if(chronos_counter<CHRONOS_COUNTER_MAX) then
    chronos_counter = chronos_counter + CHRONOS_COUNTER_INTERVAL
    color_intensity = color_intensity + CHRONOS_COLOR_INTERVAL
    light_counter = light_counter + CHRONOS_LIGHT_INTERVAL

    end
    writeBytes(Freeze_bullet_time_ptr,1,1)
    speed = 1/chronos_counter
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
     writeBytes(Release_bullet_time_ptr,1,1)
     writeFloat(Bullet_accel_ptr,chronos_counter*2*CHRONOS_WITHDRAWL_MULT*CHRONOS_WITHDRAWL_MULT)
    else
      state = 0
      chronos_counter = 1
      color_intensity = 0
      light_counter = 1
      writeBytes(Freeze_bullet_time_ptr,0,1)
      writeBytes(Release_bullet_time_ptr,0,1)
      writeFloat(Bullet_accel_ptr,1)
    end
end

  local state_tbl =
  {
  [0] = state_ready,
  [1] = state_slow,
  [2] = state_speed,
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
        return
      end

      controller_table = getXBox360ControllerState()

      if(controller_table==nil) then
        chronos_trigger = false
        speed_slash_trigger = false
      else

      --controllerID = controller_table.ControllerID
      --print("Controller ID: " .. controllerID)

      chronos_trigger = controller_table.GAMEPAD_RIGHT_THUMB

      chronos_trigger = read_controller_chronos_trigger()

      speed_slash_trigger = controller_table.GAMEPAD_RIGHT_SHOULDER
    end

    if(chronos_trigger or isKeyPressed(CHRONOS_KEYBOARD_KEY)) then
      chronos_button_pressed = 1
    else
      chronos_button_pressed = 0
    end

   if(state_slash==1) then
     slash_counter = slash_counter + 1
     if(slash_counter>=SLASH_DURATION) then
       writeFloat(Player_speed_ptr, 1)
       slash_counter = 0
       state_slash = 2

       writeInteger(SpEffect_Type_ptr,3)
       writeInteger(SpEffect_ID_ptr,SP_EFFECT_ID) --divine confetti
       autoAssemble("CreateThread(AddEffect)")
     end
   end

   if(state_slash==2) then
    if(((not speed_slash_trigger) and (controller_table~=nil)) or ((controller_table==nil) and (not isKeyPressed(1)))) then
      state_slash = 0
    end
   end

   if((1/light_counter)>CHRONOS_LIGHT_MIN) then
       writeFloat(Light_ptr,1/light_counter)
   else
       writeFloat(Light_ptr,CHRONOS_LIGHT_MIN)
   end

    local current_function = state_tbl[state]
    if(current_function) then
     current_function()
    else
    print("Error: State out of range")
    end

    speed = (1/chronos_counter)
    --print("Chronos counter: " .. chronos_counter)
    --print("Color intensity: " .. color_intensity)

    if(speed>0) then
     writeFloat(Game_speed_ptr,speed)
     writeFloat(Bullet_speed_ptr,speed)
     if(enable_airtime>0) then
        writeFloat(Movement_mult_ptr,speed)
     end
    end
    if(color_intensity<=BRIGHTNESS_MAX) then
       writeFloat(Phantom_param_ptr,color_intensity)
    else
       writeFloat(Phantom_param_ptr,BRIGHTNESS_MAX)
    end

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
