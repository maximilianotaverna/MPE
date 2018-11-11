--------------------------------------------------------------------------------
-- MPE Tool
--
-- Copyright 2012 Max Taverna
-- Main tool code
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Main
--------------------------------------------------------------------------------
local my_dialog = nil
function main()--1 dialog at a time
  if (my_dialog and my_dialog.visible) then -- only allows one dialog instance
      my_dialog:close() return 
  end  
--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------
local vb = renoise.ViewBuilder()
local starting_pattern = false
local beats_per_bar = 4
local lpb = renoise.song().transport.lpb
local current_pos = renoise.song().transport.playback_pos_beats
local total_rounded_beats = math.floor(current_pos + 1)
local bar = (total_rounded_beats / beats_per_bar)
local beat_in_bar = total_rounded_beats % beats_per_bar
local default_dialog_margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
local default_control_spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
local text_row_width = 10
local text_row_space = 60
local btn_common_height = 30 --27 --25
local btn_common_width = 85 --83
local btn_extra_height = 32
local btn_extra_width = 71
local btn_function_width =  71
local btn_pad_width = 90 --70 --75 
local btn_pad_height = 80 -- 60 --50
local btn_f1 = {0xf5, 0xf5, 0xf5}--softkey functions
local btn_f2 = {0xb4, 0xb4, 0xb4}--samplemode functions
local btn_f3 = {0x43, 0x43, 0x43}--modes 
local btn_f4 = {0xf5, 0xf5, 0xf5}--timing--tap--other functions
local btn_f6 = {0xb4, 0xb4, 0xb4}--pattern functions
local btn_f7 = {0xef, 0x6a, 0x24}--newsong 
local btn_f8 = {0xff, 0x2f, 0x00}--function on red
local btn_f9 = {0xff, 0x55, 0x00}--function on orange
local btn_f0 = {0x00, 0x89, 0xce}--function on blue
local btn_on = {0x00, 0xc3, 0x5c}--function on green
local btn_o2 = {0x00, 0xf3, 0x5c}--function on lightgreen
local btr_on = {0x65, 0x20, 0x00}--transport record on 
local btn_t1 = {0xaf, 0x3a, 0x24}--transport record 
local btn_t2 = {0xf5, 0xf5, 0xf5}--transport 
local handle_error = false
local samples_per_beat = nil
local seconds_per_beat = nil
local beats_in_sample = nil
local frames_in_sample = nil
local fxamount = 0
local fxpar = 0
local snapcount = 0
local sampcount = 0
local dispcount = 0
local sampdg = false
local original_timing = renoise.song().transport.lpb
local tempo = nil
local counter = 0
local last_clock = 0
local timetable = table.create()
local timetable_filled = false
local options = renoise.Document.create("ScriptingToolPreferences") {
      --tap tempo hits to create a new bpm
      sensitivity = 2,
      round_bpm = true,
      auto_save_bpm = true,}

  

----------------------
--bar/beat calculator      
----------------------

bar = math.ceil(bar)
if beat_in_bar == 0 then beat_in_bar = beats_per_bar 
end 


--------------------------------------------------------------------------------
-- Display Functions
--------------------------------------------------------------------------------



-----------------
--slice clear
-----------------
local function dsliceclear()
    local sample = renoise.song().selected_instrument.samples[1]
    local markers = sample.slice_markers
    for i = 1, #markers, 1 do
      sample:delete_slice_marker(markers[i])
    end
end
-----------------
--slice4
-----------------
local function dslice4()
    dsliceclear()
    local number_of_slices = 4    
    local sample = renoise.song().selected_instrument.samples[1]
    local frames_per_slice = sample.sample_buffer.number_of_frames / number_of_slices
    for i = 0, number_of_slices - 1, 1 do
      sample:insert_slice_marker(1 + math.floor(i * frames_per_slice))
    end
end
-----------------
--slice8
-----------------
local function dslice8()
    dsliceclear()
    local number_of_slices = 8   
    local sample = renoise.song().selected_instrument.samples[1]
    local frames_per_slice = sample.sample_buffer.number_of_frames / number_of_slices
    for i = 0, number_of_slices - 1, 1 do
      sample:insert_slice_marker(1 + math.floor(i * frames_per_slice))
    end
end
-----------------
--slice16
-----------------
local function dslice16()
    dsliceclear()
    local number_of_slices = 16   
    local sample = renoise.song().selected_instrument.samples[1]
    local frames_per_slice = sample.sample_buffer.number_of_frames / number_of_slices
    for i = 0, number_of_slices - 1, 1 do
      sample:insert_slice_marker(1 + math.floor(i * frames_per_slice))
    end
end
-----------------
--slice32
-----------------
local function dslice32()
    dsliceclear()
    local number_of_slices = 32   
    local sample = renoise.song().selected_instrument.samples[1]
    local frames_per_slice = sample.sample_buffer.number_of_frames / number_of_slices
    for i = 0, number_of_slices - 1, 1 do
      sample:insert_slice_marker(1 + math.floor(i * frames_per_slice))
    end
end
-----------------
--loop
-----------------
local function loop_on()
    if (vb.views.loop.value == 1) then
    renoise.song().transport.loop_pattern = false 
    else renoise.song().transport.loop_pattern = true
    end  
end
-----------------
--timing change
-----------------
local function timing_change()          
    if (vb.views.timing.value == 2 ) 
    then renoise.song().transport.lpb = 4 
    renoise.song().patterns[renoise.song().selected_pattern_index].number_of_lines = 16 --1/4
    vb.views.bars.value = 1
    vb.views.bars.max = 32
    elseif (vb.views.timing.value == 3 )
    then renoise.song().transport.lpb = 8
    renoise.song().patterns[renoise.song().selected_pattern_index].number_of_lines = 32 --1/8
    vb.views.bars.value = 1
    vb.views.bars.max = 16
    elseif (vb.views.timing.value == 4 )
    then renoise.song().transport.lpb = 16 
    renoise.song().patterns[renoise.song().selected_pattern_index].number_of_lines = 64 --1/16
    vb.views.bars.value = 1
    vb.views.bars.max = 8
    elseif (vb.views.timing.value == 5 )
    then renoise.song().transport.lpb = 32 
    renoise.song().patterns[renoise.song().selected_pattern_index].number_of_lines = 128 --1/32
    vb.views.bars.value = 1
    vb.views.bars.max = 4
    elseif (vb.views.timing.value == 1)
    then 
    renoise.song().transport.lpb = original_timing 
    end
end
-----------------
--note action overlap
-----------------
local function noteaction()          
    if (vb.views.noteaction.value == 1 ) 
    then renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].new_note_action = 1
    elseif (vb.views.noteaction.value == 2 )
    then renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].new_note_action = 2
    elseif (vb.views.noteaction.value == 3 )
    then renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].new_note_action = 3
    end
end
-----------------
--sample loop mode
-----------------
local function sampleloopmode()          
    if (vb.views.sampleloopmode.value == 1 )  
    then renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].loop_mode = 1
    elseif (vb.views.sampleloopmode.value == 2 )
    then renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].loop_mode = 2
    elseif (vb.views.sampleloopmode.value == 3 )
    then renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].loop_mode = 3
    elseif (vb.views.sampleloopmode.value == 4 )
    then renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].loop_mode = 4    
    end
end
-----------------
--bars change
-----------------
local function bars_change()  
    if (renoise.song().transport.lpb == 4 )
    then renoise.song().patterns[renoise.song().selected_pattern_index].number_of_lines = 16 * vb.views.bars.value
    elseif (renoise.song().transport.lpb == 8 )
    then renoise.song().patterns[renoise.song().selected_pattern_index].number_of_lines = 32 * vb.views.bars.value
    elseif (renoise.song().transport.lpb == 16) 
    then renoise.song().patterns[renoise.song().selected_pattern_index].number_of_lines = 64 * vb.views.bars.value
    elseif (renoise.song().transport.lpb == 32)
    then renoise.song().patterns[renoise.song().selected_pattern_index].number_of_lines = 128 * vb.views.bars.value
    end
end         
-----------------
--slice change
-----------------
local function slice_change()
    if (renoise.song().selected_instrument.samples[1].sample_buffer.has_sample_data) then          
      if(
      vb.views.slice.value == 1) then
      dsliceclear() elseif     
      vb.views.slice.value == 2 then
      dslice4() elseif      
      vb.views.slice.value == 3 then
      dslice8() elseif
      vb.views.slice.value == 4 then
      dslice16() elseif
      vb.views.slice.value == 5 then
      dslice32()      
      end
    end
end
-----------------
--sync value
-----------------
local function sval()
      
      --1/4
      if(renoise.song().transport.lpb == 4 ) then
      
      if(
      vb.views.smpsyncval.value == 1) then --no sync
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].beat_sync_lines = 0 elseif
      vb.views.smpsyncval.value == 2 then --1beat
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].beat_sync_lines = 4 elseif
      vb.views.smpsyncval.value == 3 then --2beat
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].beat_sync_lines = 8 elseif          
      vb.views.smpsyncval.value == 4 then --1bar
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].beat_sync_lines = 16 elseif   
      vb.views.smpsyncval.value == 5 then --2bar
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].beat_sync_lines = 32 elseif           
      vb.views.smpsyncval.value == 6 then --4bar
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].beat_sync_lines = 64 elseif     
      vb.views.smpsyncval.value == 7 then --8bar
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].beat_sync_lines = 128 elseif     
      vb.views.smpsyncval.value == 8 then --16bar
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].beat_sync_lines = 256 elseif     
      vb.views.smpsyncval.value == 9 then --32bar
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].beat_sync_lines = 512         
      end
      
      elseif(renoise.song().transport.lpb == 8 ) then
      
      if(
      vb.views.smpsyncval.value == 1) then --no sync
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].beat_sync_lines = 0 elseif
      vb.views.smpsyncval.value == 2 then --1beat
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].beat_sync_lines = 8 elseif
      vb.views.smpsyncval.value == 3 then --2beat
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].beat_sync_lines = 16 elseif          
      vb.views.smpsyncval.value == 4 then --1bar
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].beat_sync_lines = 32 elseif   
      vb.views.smpsyncval.value == 5 then --2bar
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].beat_sync_lines = 64 elseif           
      vb.views.smpsyncval.value == 6 then --4bar
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].beat_sync_lines = 128 elseif     
      vb.views.smpsyncval.value == 7 then --8bar
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].beat_sync_lines = 256 elseif     
      vb.views.smpsyncval.value == 8 then --16bar
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].beat_sync_lines = 512 elseif     
      vb.views.smpsyncval.value == 9 then --32bar
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].beat_sync_lines = 0         
      end
      
      elseif(renoise.song().transport.lpb == 16 ) then
      
      if(
      vb.views.smpsyncval.value == 1) then --no sync
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].beat_sync_lines = 0 elseif
      vb.views.smpsyncval.value == 2 then --1beat
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].beat_sync_lines = 16 elseif
      vb.views.smpsyncval.value == 3 then --2beat
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].beat_sync_lines = 32 elseif          
      vb.views.smpsyncval.value == 4 then --1bar
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].beat_sync_lines = 64 elseif   
      vb.views.smpsyncval.value == 5 then --2bar
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].beat_sync_lines = 128 elseif           
      vb.views.smpsyncval.value == 6 then --4bar
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].beat_sync_lines = 256 elseif     
      vb.views.smpsyncval.value == 7 then --8bar
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].beat_sync_lines = 512 elseif     
      vb.views.smpsyncval.value == 8 then --16bar
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].beat_sync_lines = 0 elseif     
      vb.views.smpsyncval.value == 9 then --32bar
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].beat_sync_lines = 0         
      end
      
      elseif(renoise.song().transport.lpb == 32 ) then
      
      if(
      vb.views.smpsyncval.value == 1) then --no sync
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].beat_sync_lines = 0 elseif
      vb.views.smpsyncval.value == 2 then --1beat
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].beat_sync_lines = 32 elseif
      vb.views.smpsyncval.value == 3 then --2beat
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].beat_sync_lines = 64 elseif          
      vb.views.smpsyncval.value == 4 then --1bar
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].beat_sync_lines = 128 elseif   
      vb.views.smpsyncval.value == 5 then --2bar
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].beat_sync_lines = 256 elseif           
      vb.views.smpsyncval.value == 6 then --4bar
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].beat_sync_lines = 512 elseif     
      vb.views.smpsyncval.value == 7 then --8bar
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].beat_sync_lines = 0 elseif     
      vb.views.smpsyncval.value == 8 then --16bar
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].beat_sync_lines = 0 elseif     
      vb.views.smpsyncval.value == 9 then --32bar
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].beat_sync_lines = 0         
      end
      
      end
end
-----------------
--effects ON
-----------------
local function feffecton()    
    -- create the fx track
    local function fsubeffecton()    
    renoise.song():insert_track_at(1)
    renoise.song().tracks[1].name = "MPEFX"
    renoise.song().selected_track_index  = 1     
    ----------------------------
    renoise.song().tracks[1]:insert_device_at("Audio/Effects/Native/Multitap Delay", 2)
    renoise.song().tracks[1].devices[2].is_active = false      
    ----------------------------
    renoise.song().tracks[1]:insert_device_at("Audio/Effects/Native/Delay", 3)
    renoise.song().tracks[1].devices[3].is_active = false
    ----------------------------
    renoise.song().tracks[1]:insert_device_at("Audio/Effects/Native/Flanger", 4)
    renoise.song().tracks[1].devices[4].is_active = false      
    ----------------------------
    renoise.song().tracks[1]:insert_device_at("Audio/Effects/Native/Phaser", 5)
    renoise.song().tracks[1].devices[5].is_active = false
    ----------------------------
    renoise.song().tracks[1]:insert_device_at("Audio/Effects/Native/mpReverb", 6)
    renoise.song().tracks[1].devices[6].is_active = false            
    ----------------------------
    renoise.song().tracks[1]:insert_device_at("Audio/Effects/Native/LofiMat", 7)
    renoise.song().tracks[1].devices[7].is_active = false
    ----------------------------
    renoise.song().tracks[1]:insert_device_at("Audio/Effects/Native/Gate", 8)
    renoise.song().tracks[1].devices[8].is_active = false
    ----------------------------
    renoise.song().tracks[1]:insert_device_at("Audio/Effects/Native/RingMod", 9)
    renoise.song().tracks[1].devices[9].is_active = false
    ----------------------------
    renoise.song().tracks[1]:insert_device_at("Audio/Effects/Native/Scream Filter", 10)
    renoise.song().tracks[1].devices[10].is_active = false
    ----------------------------
    renoise.song().tracks[1]:insert_device_at("Audio/Effects/Native/Filter", 11)
    renoise.song().tracks[1].devices[11].is_active = false
    ----------------------------
    renoise.song().tracks[1]:insert_device_at("Audio/Effects/Native/Comb Filter", 12)
    renoise.song().tracks[1].devices[12].is_active = false
    ----------------------------
    renoise.song().tracks[1]:insert_device_at("Audio/Effects/Native/Repeater", 13)
    renoise.song().tracks[1].devices[13].is_active = false      
    ---------------------------- 
    renoise.song().selected_device_index = 1     
    end    
    --create or re-create the effects track
    --------------------------------------- 
    if (renoise.song().tracks[1].name == "MPEFX" and #renoise.song().tracks[1].devices == 13) then 
    renoise.song().selected_track_index = 1 
    elseif 
    renoise.song().tracks[1].name == "MPEFX" and #renoise.song().tracks[1].devices < 13 then
    renoise.song():delete_track_at(1)
    fsubeffecton()
    else
    fsubeffecton()
    end
end   
-----------------
--effects device
-----------------
local function ffxdevice()       
      --check the effect track exists with all devices
      ------------------------------------------------
      if (renoise.song().tracks[1].name == "MPEFX" and #renoise.song().tracks[1].devices == 13) then
      renoise.song().selected_track_index  = 1
      --Turn all effect devices off if its device is set to 14
      ---------------------------------------------------------
      if (vb.views.fxv2.value == 14 ) then
        for i=2,#renoise.song().tracks[1].devices do     
        renoise.song().tracks[1].devices[i].is_active = false 
        end
      else        
      --Only make current selected device active
      ---------------------------------------------------------
      renoise.song().selected_device_index = vb.views.fxv2.value
        for i=2,#renoise.song().tracks[1].devices do     
        renoise.song().tracks[1].devices[i].is_active = false 
        end
      renoise.song().selected_device.is_active = true 
      --reset the fx control values to limits
      ------------------------------------------------
      vb.views.fxv1.value = 1
      vb.views.fcontrolfx2.value = 0
      
    if ( renoise.song().selected_device_index == 2 ) then --Multitap
    vb.views.fcontrolfx2.min = renoise.song().tracks[1].devices[2].parameters[6].value_min
    vb.views.fcontrolfx2.max = renoise.song().tracks[1].devices[2].parameters[6].value_max    
    elseif
    renoise.song().selected_device_index == 3  then --Delay
    vb.views.fcontrolfx2.min = renoise.song().tracks[1].devices[3].parameters[5].value_min
    vb.views.fcontrolfx2.max = renoise.song().tracks[1].devices[3].parameters[5].value_max
    elseif
    renoise.song().selected_device_index == 4  then --Flanger
    vb.views.fcontrolfx2.min = renoise.song().tracks[1].devices[4].parameters[8].value_min
    vb.views.fcontrolfx2.max = renoise.song().tracks[1].devices[4].parameters[8].value_max
    elseif
    renoise.song().selected_device_index == 5  then --Phaser
    vb.views.fcontrolfx2.min = renoise.song().tracks[1].devices[5].parameters[4].value_min
    vb.views.fcontrolfx2.max = renoise.song().tracks[1].devices[5].parameters[4].value_max   
    elseif
    renoise.song().selected_device_index == 6  then --mpReverb
    vb.views.fcontrolfx2.min = renoise.song().tracks[1].devices[6].parameters[8].value_min
    vb.views.fcontrolfx2.max = renoise.song().tracks[1].devices[6].parameters[8].value_max 
    elseif
    renoise.song().selected_device_index == 7  then --LofiMat
    vb.views.fcontrolfx2.min = renoise.song().tracks[1].devices[7].parameters[2].value_min
    vb.views.fcontrolfx2.max = renoise.song().tracks[1].devices[7].parameters[2].value_max
    vb.views.fcontrolfx2.value = 1
    elseif
    renoise.song().selected_device_index == 8  then --Gate
    vb.views.fcontrolfx2.min = renoise.song().tracks[1].devices[8].parameters[1].value_min
    vb.views.fcontrolfx2.max = renoise.song().tracks[1].devices[8].parameters[1].value_max
    vb.views.fcontrolfx2.value = -60
    elseif
    renoise.song().selected_device_index == 9  then --RingMod
    vb.views.fcontrolfx2.min = renoise.song().tracks[1].devices[9].parameters[3].value_min
    vb.views.fcontrolfx2.max = renoise.song().tracks[1].devices[9].parameters[3].value_max
    elseif
    renoise.song().selected_device_index == 10  then --Scream
    vb.views.fcontrolfx2.min = renoise.song().tracks[1].devices[10].parameters[2].value_min
    vb.views.fcontrolfx2.max = renoise.song().tracks[1].devices[10].parameters[2].value_max 
    elseif
    renoise.song().selected_device_index == 11  then --Filter
    vb.views.fcontrolfx2.min = renoise.song().tracks[1].devices[11].parameters[2].value_min
    vb.views.fcontrolfx2.max = renoise.song().tracks[1].devices[11].parameters[2].value_max 
    elseif
    renoise.song().selected_device_index == 12  then --Comb Filter
    vb.views.fcontrolfx2.min = renoise.song().tracks[1].devices[12].parameters[1].value_min
    vb.views.fcontrolfx2.max = renoise.song().tracks[1].devices[12].parameters[1].value_max 
    end    
       
      end --end turn all effect devices off            
      else feffecton() 
      end
end
-----------------
--mute display
-----------------
local function fmuted()
    if (vb.views.mute_on.value == 2 ) then
    renoise.song().selected_track:mute() else
    renoise.song().selected_track:unmute()
    end
end


--------------------------------------------------------------------------------
-- Button Functions
--------------------------------------------------------------------------------


-----------------
--step
-----------------
local function fstep()
    renoise.app().window.active_middle_frame = 1
    renoise.app().window.active_lower_frame = 2
    renoise.app().window.lower_frame_is_visible = true
    renoise.app().window.upper_frame_is_visible = false
    renoise.app().window.pattern_matrix_is_visible = false    
    renoise.song().transport.edit_step = 0
    if(renoise.song().transport.follow_player == true and renoise.song().transport.edit_mode == false) then
    --vb.views.fstep.color = btn_on
    renoise.song().transport.follow_player = false 
    renoise.song().transport.edit_mode = true
    else
    --vb.views.fstep.color = btn_f1
    renoise.song().transport.follow_player = true 
    renoise.song().transport.edit_mode = false
    renoise.app().window.sample_record_dialog_is_visible = false
    renoise.app().window.active_upper_frame = 2
    renoise.app().window.active_middle_frame = 1
    renoise.app().window.active_lower_frame = 4
    renoise.app().window.lower_frame_is_visible = false
    renoise.app().window.upper_frame_is_visible = true
    renoise.app().window.pattern_matrix_is_visible = true
    --additional functions
    renoise.song().transport.follow_player = true
    renoise.song().transport.edit_step = 2
    end
end
-----------------
--edit
-----------------
local function fedit()
    if(renoise.app().window.pattern_advanced_edit_is_visible == false) then
    renoise.app().window.active_middle_frame = 1
    renoise.app().window.pattern_advanced_edit_is_visible = true else
    renoise.app().window.pattern_advanced_edit_is_visible = false
    end
end
-----------------
--mute
-----------------
local function fmute()
    if (renoise.song().selected_track.mute_state == 1 ) then
    renoise.song().selected_track:mute()else
    renoise.song().selected_track:unmute()
    end
end
-----------------
--solo
-----------------
local function fsolo()
    renoise.song().selected_track:solo()
end 
-----------------
--trackback
-----------------
local function ftrackback()
    if (renoise.song().selected_track_index == 1 ) then renoise.song().selected_track_index = 1 
    else      
    renoise.song().selected_track_index = renoise.song().selected_track_index - 1
    end
end
-----------------
--trackforward
-----------------
local function ftrackforward()
    if (renoise.song().selected_track_index == #renoise.song().tracks ) then renoise.song().selected_track_index = #renoise.song().tracks 
    else
    renoise.song().selected_track_index = renoise.song().selected_track_index + 1
    end
end
-----------------
--loop off
-----------------
local function fundo()   
    renoise.song():undo()
end
-----------------
--loop forward
-----------------
local function floopforwardsample()
    if (renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].loop_mode == 2) then
    renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].loop_mode = 1 else
    renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].loop_mode = 2
    end
end
-----------------
--loop forward all
-----------------
local function floopforwardpgm()
    if (renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].loop_mode == 2) then
    for i=1,#renoise.song().selected_instrument.samples do        
    renoise.song().selected_instrument.samples[i].loop_mode = 1 end 
    else
    for i=1,#renoise.song().selected_instrument.samples do
    renoise.song().selected_instrument.samples[i].loop_mode = 2 end
    end
end    
-----------------
--loop back
-----------------
local function fpgmloopbk()
    if (renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].loop_mode == 3) then
    renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].loop_mode = 1 else
    renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].loop_mode = 3
    end
end
-----------------
--loop pingpong
-----------------
local function fpgmlooppg()
    if (renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].loop_mode == 4) then
    renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].loop_mode = 1 else
    renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].loop_mode = 4
    end
end
-----------------
--sample instrument beatsync transpose
-----------------
local function ftransposesyncsample()
    if (renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].beat_sync_enabled == false) then
    renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].beat_sync_enabled = true else
    renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].beat_sync_enabled = false
    end
end
-----------------
--sample instrument beatsync transpose all slots
-----------------
local function ftransposesyncpgm()
if (renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].beat_sync_enabled == false) then
    for i=1,#renoise.song().selected_instrument.samples do        
    renoise.song().selected_instrument.samples[i].beat_sync_enabled = true end 
    else
    for i=1,#renoise.song().selected_instrument.samples do
    renoise.song().selected_instrument.samples[i].beat_sync_enabled = false  
    end
end
end    
-----------------
--sample instrument add slice marker
-----------------
local function fpgmslicemarker()
    if (renoise.song().selected_sample.sample_buffer.has_sample_data == true and 
    renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].is_slice_alias == false) then
    --set a marker 
    renoise.song().selected_instrument.samples[1]:insert_slice_marker(renoise.song().selected_instrument.
    samples[renoise.song().selected_sample_index].sample_buffer.selection_start)
    end
end
-----------------
--pgmback
-----------------
local function fpgmback()
    if (renoise.song().selected_instrument_index == 1 ) then 
    handle_error = true
    else      
    renoise.song().selected_instrument_index = renoise.song().selected_instrument_index - 1
    end
end
-----------------
--pgmforward
-----------------
local function fpgmforward()
    if (renoise.song().selected_instrument_index == #renoise.song().instruments ) then 
    handle_error = true
    else
    renoise.song().selected_instrument_index = renoise.song().selected_instrument_index + 1
    end
end
-----------------
--fxsave
-----------------
local function ffxsave()
    if (renoise.song().tracks[renoise.song().selected_track_index].name == "MPEFX" and 
    vb.views.fxv2.value > 1 and 
    vb.views.fxv2.value < 14 ) then
    renoise.song().selected_track_index  = 1
     --remove the inactive devices
     ------------------------------------------------      
     renoise.song().tracks[1]:swap_devices_at(vb.views.fxv2.value,13)
     renoise.song().tracks[1]:delete_device_at(2)
     renoise.song().tracks[1]:delete_device_at(2)
     renoise.song().tracks[1]:delete_device_at(2)
     renoise.song().tracks[1]:delete_device_at(2)
     renoise.song().tracks[1]:delete_device_at(2)
     renoise.song().tracks[1]:delete_device_at(2) 
     renoise.song().tracks[1]:delete_device_at(2)
     renoise.song().tracks[1]:delete_device_at(2)
     renoise.song().tracks[1]:delete_device_at(2)
     renoise.song().tracks[1]:delete_device_at(2)
     renoise.song().tracks[1]:delete_device_at(2)
     renoise.song().tracks[1].name = "FX"..renoise.song().tracks[1].devices[2].name      
    end
end
-----------------
--sample
-----------------
local function fsample()
    if (renoise.app().window.sample_record_dialog_is_visible == false) then
    renoise.app().window.sample_record_dialog_is_visible = true
    else -- start recording 
    renoise.song().transport:start_stop_sample_recording()
    end
end
-----------------
--trim
-----------------
local function ftrim()
    vb.views.gui_screen01.visible = false
    vb.views.gui_screen02.visible = true
    vb.views.gui_screen03.visible = false
    renoise.app().window.sample_record_dialog_is_visible = false
    renoise.app().window.active_upper_frame = 1
    renoise.app().window.active_middle_frame = 4
    renoise.app().window.active_lower_frame = 3
    renoise.app().window.lower_frame_is_visible = false
    renoise.app().window.upper_frame_is_visible = false
end
-----------------
--mixer
-----------------
local function fmixer()
    renoise.app().window.sample_record_dialog_is_visible = false
    renoise.app().window.active_upper_frame = 4
    renoise.app().window.active_middle_frame = 2
    renoise.app().window.active_lower_frame = 1
    --renoise.app().window.upper_frame_is_visible = false
    renoise.app().window.lower_frame_is_visible = true
    renoise.app().window.pattern_matrix_is_visible = false
    if (renoise.app().window.upper_frame_is_visible == true ) then
    renoise.app().window.upper_frame_is_visible = false 
    renoise.app().window.lower_frame_is_visible = false else
    renoise.app().window.upper_frame_is_visible = true
    renoise.app().window.lower_frame_is_visible = true
    end
end
-----------------
--save_bpm
-----------------
local function save_bpm(bpm)
    if (bpm >= 32 and bpm <= 999) then renoise.song().transport.bpm = bpm      
    end
end
-----------------
--tap tempo
-----------------
local function tap() 
    local function get_average(tb)
    return (tb[#tb] - tb[1]) / (#tb - 1)
    end
    -------
    local function get_bpm(dt) -- 60 BPM => 1 beat per sec  
    return (60 / dt)
    end
    -------
    local function reset()
    counter = 1
    timetable_filled = false
    while (#timetable > 1) do 
    timetable:remove(1) 
    end
    end
    -------
    local function increase_counter()  
    counter = counter + 1
    if (counter > options.sensitivity.value) then
    timetable_filled = true
    counter = 1
    end  
    end
    -------
    increase_counter()
    -------
    local clock = os.clock()
    timetable:insert(clock) 
    -------  
    if (last_clock > 0 and (clock - last_clock) > 2) then -- reset after 2 sec idle 
    reset()
    end
    -------
    last_clock = clock
    -------
    if (#timetable > options.sensitivity.value) then
    timetable:remove(1)
    end
    -------
    if (timetable_filled) then
    tempo = get_bpm(get_average(timetable))
    local field = "%.2f"
    -------
    if (options.round_bpm.value) then
    tempo = math.floor(tempo + 0.5)
    field = "%d"
    end  
    -------
    if (counter == 1 and options.auto_save_bpm.value) then 
    save_bpm(tempo)
    end  
    end
end
-----------------
--snap
-----------------
local function fsnap()
  snapcount = snapcount + 1 
  vb.views.fsnap.color = btn_on
  ftrim()
  if (snapcount == 2 ) then
  vb.views.fsnap.color = btn_f1
  snapcount = 0
  end  
end
-----------------
--full level
-----------------
local function flevel()   
if (renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].volume == 4 ) then 
    for i=1,#renoise.song().selected_instrument.samples do
    renoise.song().selected_instrument.samples[i].volume = 1.5         
    end
    -------
    else  
    -------
    for i=1,#renoise.song().selected_instrument.samples do
    renoise.song().selected_instrument.samples[i].volume = 4         
    end     
end
    if (renoise.song().selected_instrument.plugin_properties.volume == 4 ) then
    renoise.song().selected_instrument.plugin_properties.volume = 1.5 else
    renoise.song().selected_instrument.plugin_properties.volume = 4
    end
end 
-----------------
--plugin  prev
-----------------
local function fplugpreviouspreset() 
if not (renoise.song().selected_instrument.plugin_properties.plugin_device == nil or
      renoise.song().selected_instrument.plugin_properties.plugin_device.active_preset == 0 or 
      renoise.song().selected_instrument.plugin_properties.plugin_device.active_preset == 1 )
      then
      renoise.song().selected_instrument.plugin_properties.plugin_device.active_preset = 
      renoise.song().selected_instrument.plugin_properties.plugin_device.active_preset-1
      end
end
-----------------
--plugin  next
-----------------
local function fplugnextpreset() 
if not (renoise.song().selected_instrument.plugin_properties.plugin_device == nil or
      renoise.song().selected_instrument.plugin_properties.plugin_device.active_preset == 0 or 
      renoise.song().selected_instrument.plugin_properties.plugin_device.active_preset == 
      #renoise.song().selected_instrument.plugin_properties.plugin_device.presets ) 
      then
      renoise.song().selected_instrument.plugin_properties.plugin_device.active_preset = 
      renoise.song().selected_instrument.plugin_properties.plugin_device.active_preset+1
      end
end
-----------------
--fnna cut
-----------------
local function fcutnotesample()    
if (renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].new_note_action > 1 ) then      
    renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].new_note_action = 1     
    else
    renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].new_note_action = 3  
    end
end
-----------------
--fnna cutall
-----------------
local function fcutnotepgm() 
if (renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].new_note_action > 1 ) then
    for i=1,#renoise.song().selected_instrument.samples do        
    renoise.song().selected_instrument.samples[i].new_note_action = 1 
    end else
    for i=1,#renoise.song().selected_instrument.samples do
    renoise.song().selected_instrument.samples[i].new_note_action = 3
    end
end
end
-----------------
--fxdelay
-----------------
local function fxdelay()  
if (renoise.song().tracks[1].name == "MPEFX" and renoise.song().selected_track_index == 1 and
renoise.song().tracks[1].devices[2].is_active == false ) then
vb.views.fxv2.value = 2
vb.views.fxdelay.color = btn_on 
vb.views.fcontrolfx2.value = 0.5
elseif (renoise.song().tracks[1].name == "MPEFX" and renoise.song().selected_track_index == 1 and
renoise.song().tracks[1].devices[2].is_active == true ) then
vb.views.fxv2.value = 1
vb.views.fxdelay.color = btn_f2
else feffecton()
vb.views.fxv2.value = 2
vb.views.fxdelay.color = btn_on     
end
end
-----------------
--hold
-----------------
local function fhold()   
if (renoise.song().selected_instrument.sample_envelopes.volume.enabled == true ) then
    --turn off
    for i=1,#renoise.song().selected_instrument.samples do       
    --disabled--set the note to cut when played
    --disabled--renoise.song().selected_instrument.samples[i].new_note_action = 1
    renoise.song().selected_instrument.samples[i].autofade = true
    renoise.song().selected_instrument.sample_envelopes.volume.enabled = false
    renoise.song().selected_instrument.sample_envelopes.volume:clear_points()
    renoise.song().selected_instrument.sample_envelopes.volume:add_point_at(1,1)
    renoise.song().selected_instrument.sample_envelopes.volume.fade_amount = 1
    vb.views.fhold.color = btn_f2
    end
    -------
    else  
    -------
    --turn on
    for i=1,#renoise.song().selected_instrument.samples do        
    --disabled--set the note to continue (overlap) when played
    --disabled--renoise.song().selected_instrument.samples[i].new_note_action = 3 
    renoise.song().selected_instrument.samples[i].autofade = true
    renoise.song().selected_instrument.sample_envelopes.volume.enabled = true   
    renoise.song().selected_instrument.sample_envelopes.volume:clear_points()
    renoise.song().selected_instrument.sample_envelopes.volume:add_point_at(1,1)
    renoise.song().selected_instrument.sample_envelopes.volume.fade_amount = 0
    vb.views.fhold.color = btn_on
    end     
end
end
-----------------
--song
-----------------
local function fsong()
    vb.views.gui_screen01.visible = true
    vb.views.gui_screen02.visible = false
    vb.views.gui_screen03.visible = false
    renoise.app().window.sample_record_dialog_is_visible = false
    renoise.app().window.active_upper_frame = 2
    renoise.app().window.active_middle_frame = 1
    renoise.app().window.active_lower_frame = 4
    renoise.app().window.lower_frame_is_visible = false
    renoise.app().window.pattern_matrix_is_visible = true
    --additional functions
    renoise.song().transport.follow_player = true
    renoise.song().transport.edit_step = 2
    if (renoise.app().window.upper_frame_is_visible == true ) then
    renoise.app().window.upper_frame_is_visible = false else
    renoise.app().window.upper_frame_is_visible = true
    end
end
-----------------
--program
-----------------
local function fprog()
    vb.views.gui_screen01.visible = false
    vb.views.gui_screen02.visible = false
    vb.views.gui_screen03.visible = true
    renoise.app().window.sample_record_dialog_is_visible = false
    renoise.app().window.active_upper_frame = 1
    renoise.app().window.active_middle_frame = 3
    renoise.app().window.active_lower_frame = 3
    renoise.app().window.lower_frame_is_visible = true
    renoise.app().window.upper_frame_is_visible = true
end
-----------------
--load
-----------------
local function fload()
    renoise.app().window.sample_record_dialog_is_visible = false
    renoise.app().window.active_upper_frame = 1
    renoise.app().window.active_middle_frame = 3
    renoise.app().window.active_lower_frame = 3
    renoise.app().window.lower_frame_is_visible = false
    renoise.app().window.upper_frame_is_visible = true
    renoise.app().window.disk_browser_is_expanded = true
end
-----------------
--save
-----------------
local function fsave()
    renoise.app():save_song()
end
-----------------
--new
-----------------
local function fnew()
    renoise.app():new_song()
end
-----------------
--instant sample
-----------------
    --close the sample recorder dialog window
    local function fisampleclose()
    renoise.app().window.sample_record_dialog_is_visible = false
    renoise.tool():remove_timer(fisampleclose)
    end   
    local function fisample() 
    --if the instrumnt is new and there is no sample data then create 1 frame
    if (renoise.song().selected_sample.sample_buffer.has_sample_data == false) then
    renoise.song().selected_instrument.samples[1].sample_buffer:create_sample_data(44100, 32, 1, 2)
    end
    
      if (renoise.app().window.sample_record_dialog_is_visible == false and
      sampcount == 0) then
      sampcount = sampcount + 1
      renoise.app().window.sample_record_dialog_is_visible = true
      renoise.song().transport:start_stop_sample_recording()
      print("recording")    
      else
      renoise.song().transport:start_stop_sample_recording()
      print("recordstop")
      sampcount = 0
      renoise.tool():add_timer(fisampleclose,70) 
      end --if
    
end --fisample function
-----------------
--timing
-----------------
local function ftiming()
    if (
    renoise.song().transport.record_quantize_enabled == false) then
    renoise.song().transport.record_quantize_enabled = true
    renoise.song().transport.record_quantize_lines = 2
    vb.views.timingonoff.color = btn_on
    else renoise.song().transport.record_quantize_enabled = false
    vb.views.timingonoff.color = btn_f4
    end
end
-----------------
--erase
-----------------
local function ferase()
    renoise.song().selected_pattern_track:clear()
end
-----------------
--step back
-----------------
local function fstepback()
    if (
    --moving back in song do not past first bar
    renoise.song().transport.playback_pos_beats == 0  and renoise.song().transport.edit_pos_beats == 0 ) 
    then
    renoise.song().transport.playback_pos_beats = 0 
    renoise.song().transport.edit_pos_beats = 0      
    else        
            --do not accept edit positions between steps
            if (  
            renoise.song().transport.edit_pos_beats ~= math.floor(renoise.song().transport.edit_pos_beats) and
            renoise.song().transport.edit_pos_beats ~= math.floor(renoise.song().transport.edit_pos_beats)+0.25 and
            renoise.song().transport.edit_pos_beats ~= math.floor(renoise.song().transport.edit_pos_beats)+0.5 and
            renoise.song().transport.edit_pos_beats ~= math.floor(renoise.song().transport.edit_pos_beats)+0.75 )
            then 
            --move to bar rounded up  
            renoise.song().transport.playback_pos_beats = math.floor(renoise.song().transport.playback_pos_beats)
            renoise.song().transport.edit_pos_beats = math.floor(renoise.song().transport.edit_pos_beats)  
            else
            renoise.song().transport.edit_pos_beats = renoise.song().transport.edit_pos_beats - 0.25
            end              
    end
end
-----------------
--step forward
-----------------
local function fstepforward()
    if (
    --moving forward in song do not past last bar  
    renoise.song().transport.edit_pos_beats == renoise.song().transport.song_length_beats - 0.25 )
    then handle_error = true  
    else                           
            --do not accept edit positions between steps
            if (  
            renoise.song().transport.edit_pos_beats ~= math.floor(renoise.song().transport.edit_pos_beats) and
            renoise.song().transport.edit_pos_beats ~= math.floor(renoise.song().transport.edit_pos_beats)+0.25 and
            renoise.song().transport.edit_pos_beats ~= math.floor(renoise.song().transport.edit_pos_beats)+0.5 and
            renoise.song().transport.edit_pos_beats ~= math.floor(renoise.song().transport.edit_pos_beats)+0.75 )
            then 
            --move to bar rounded up  
            renoise.song().transport.playback_pos_beats = math.floor(renoise.song().transport.playback_pos_beats)
            renoise.song().transport.edit_pos_beats = math.floor(renoise.song().transport.edit_pos_beats)  
            else
            renoise.song().transport.edit_pos_beats = renoise.song().transport.edit_pos_beats + 0.25
            end   
    end
end
-----------------
--bar back
-----------------
local function fbarback()
    if (
    --moving back in song do not past bar 0
    renoise.song().transport.playback_pos_beats < 1  and renoise.song().transport.edit_pos_beats < 1 ) then
    renoise.song().transport.playback_pos_beats = 0
    renoise.song().transport.edit_pos_beats = 0        
    else        
    --move back one bar rounded up  
    renoise.song().transport.playback_pos_beats = math.floor(renoise.song().transport.playback_pos_beats - 1)
    renoise.song().transport.edit_pos_beats = math.floor(renoise.song().transport.edit_pos_beats - 1)  
    end
end
-----------------
--bar forward
-----------------
local function fbarforward()
    if (
    --moving forward in song do not past last bar  
    math.floor(renoise.song().transport.edit_pos_beats) == renoise.song().transport.song_length_beats-1 )
    then
    handle_error = true   
    else        
    --move forward one bar rounded up
    renoise.song().transport.edit_pos_beats = math.floor(renoise.song().transport.edit_pos_beats + 1)
    renoise.song().transport.playback_pos_beats = math.floor(renoise.song().transport.playback_pos_beats + 1)
    end
end
-----------------
--prev sequence
-----------------
local function fprevsq()
    if (renoise.song().selected_sequence_index == 1 ) then 
    handle_error = true else
    renoise.song().selected_sequence_index = renoise.song().selected_sequence_index -1
    end
end
-----------------
--next sequence
-----------------
local function fnextsq()
    if (renoise.song().selected_sequence_index == #renoise.song().sequencer.pattern_sequence ) then 
    handle_error = true else
    renoise.song().selected_sequence_index = renoise.song().selected_sequence_index +1
    end
end
-----------------
--insert sequence
-----------------
local function faddsq()
    renoise.song().sequencer:insert_new_pattern_at(renoise.song().selected_sequence_index)
end
-----------------
--remove sequence
-----------------
local function fremsq()
    renoise.song().sequencer:delete_sequence_at(renoise.song().selected_sequence_index)
end
-----------------
--clone sequence
-----------------
local function fclonesq()
    renoise.song().sequencer:clone_range(renoise.song().selected_sequence_index, renoise.song().selected_sequence_index)
end
-----------------
--record
-----------------
local function frecord()
    renoise.app().window.sample_record_dialog_is_visible = false
    renoise.app().window.active_upper_frame = 2
    renoise.app().window.active_middle_frame = 1
    renoise.app().window.active_lower_frame = 4
    renoise.app().window.lower_frame_is_visible = false
    renoise.app().window.upper_frame_is_visible = false
    renoise.app().window.pattern_matrix_is_visible = true
    renoise.song().transport.follow_player = true  
    if renoise.song().transport.edit_mode == false then
    renoise.song().transport.edit_mode = true
    renoise.song().transport:start(1)
    vb.views.frecord.color = btr_on
    vb.views.fplay.color = btn_on 
    else
    renoise.song().transport.edit_mode = false
    vb.views.frecord.color = btn_t1
    vb.views.foverdub.color = btn_t1
    end
end
-----------------
--over dub
-----------------
local function foverdub()
    renoise.app().window.sample_record_dialog_is_visible = false
    renoise.app().window.active_upper_frame = 2
    renoise.app().window.active_middle_frame = 1
    renoise.app().window.active_lower_frame = 4
    renoise.app().window.lower_frame_is_visible = false
    renoise.app().window.upper_frame_is_visible = false
    renoise.app().window.pattern_matrix_is_visible = true 
    renoise.song().transport.follow_player = true     
    if (renoise.song().transport.edit_mode == false) then
    renoise.song().transport.edit_mode = true 
    vb.views.foverdub.color = btr_on 
    else
    renoise.song().transport.edit_mode = false
    vb.views.foverdub.color = btn_t1
    vb.views.frecord.color = btn_t1 
    end
end
-----------------
--stop
-----------------
local function fstop()
    --renoise.song().transport:panic()
    renoise.song().transport:stop()
    renoise.song().transport.edit_mode = false
    vb.views.frecord.color = btn_t1
    vb.views.foverdub.color = btn_t1
    vb.views.fplay.color = btn_t2
    vb.views.fplaystart.color = btn_t2
end
-----------------
--play
-----------------
local function fplay()
    renoise.song().transport:start(2)
    vb.views.fplay.color = btn_on 
end
-----------------
--playstart
-----------------
local function fplaystart()
    renoise.song().transport:start(1)
    vb.views.fplaystart.color = btn_on
    vb.views.fplay.color = btn_on 
end
-----------------
--transpose samp
-----------------
local function ftransample()
 renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].transpose = vb.views.smptran.value
end  
-----------------
--transpose inst
-----------------
local function ftraninstrument()
    for i=1,#renoise.song().selected_instrument.samples do
    renoise.song().selected_instrument.samples[i].transpose = vb.views.insttran.value
    end
end
-----------------
--tune reset
-----------------
local function fresettune()
    for i=1,#renoise.song().selected_instrument.samples do
    renoise.song().selected_instrument.samples[i].transpose = 0
    end
end 
-----------------
--block pattern loop
-----------------
local function floopblock()
  renoise.song().transport.loop_block_enabled = not renoise.song().transport.loop_block_enabled 
  if (renoise.song().transport.playing == false ) then
  fstop()  
  end
end
-----------------
--sample select start
-----------------
local function fselectstart()    
    if (renoise.song().selected_sample.sample_buffer.has_sample_data == true) then      
    renoise.app().window.active_middle_frame = 4    
    vb.views.smpstart.min = 1
    --set the new end selection when start moves forwards
    vb.views.smpend.min = math.floor(renoise.song().selected_instrument.
    samples[renoise.song().selected_sample_index].sample_buffer.selection_start + 1)
    --dont go past the length of the sample
    vb.views.smpstart.max = renoise.song().selected_instrument.
    samples[renoise.song().selected_sample_index].sample_buffer.number_of_frames 
    --snap on or off
    if (snapcount == 1 ) then
      --snap and deal with samples per beat as 0
      if (samples_per_beat * math.floor(vb.views.smpstart.value/samples_per_beat) == 0 ) then
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].sample_buffer.selection_start = 1
      else
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].sample_buffer.selection_start =
      samples_per_beat * math.floor(vb.views.smpstart.value/samples_per_beat)
      end
      --no snapping
      else
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].sample_buffer.selection_start =
      vb.views.smpstart.value
      end 
    end      
end
-----------------
--sample select end
-----------------
local function fselectend()
    if (renoise.song().selected_sample.sample_buffer.has_sample_data == true) then    
    renoise.app().window.active_middle_frame = 4 
    --dont go past the start select range
    vb.views.smpend.min = renoise.song().selected_instrument.
    samples[renoise.song().selected_sample_index].sample_buffer.selection_start + 1    
    --dont go past the length of the sample
    vb.views.smpend.max = renoise.song().selected_instrument.
    samples[renoise.song().selected_sample_index].sample_buffer.number_of_frames
    --snap on or off
    if (snapcount == 1 and samples_per_beat * math.floor(vb.views.smpend.value/samples_per_beat) > 1 ) then
      --snap and deal with samples per beat as 0
      if (samples_per_beat * math.floor(vb.views.smpend.value/samples_per_beat) == 0 ) then
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].sample_buffer.selection_end = samples_per_beat
      else
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].sample_buffer.selection_end =
      samples_per_beat * math.floor(vb.views.smpend.value/samples_per_beat)
      end
      --no snapping
      else
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].sample_buffer.selection_end =
      vb.views.smpend.value
      end 
    end           
end
-----------------
--sample select start loop
-----------------
local function fselectstartloop()
    if (renoise.song().selected_sample.sample_buffer.has_sample_data == true) then   
    vb.views.smpstartloop.min = 1     
    --dont allow the end marker to go past the start
    vb.views.smpendloop.min = renoise.song().selected_instrument.
    samples[renoise.song().selected_sample_index].loop_start         
    --dont go past the length of the sample
    vb.views.smpstartloop.max = renoise.song().selected_instrument.
    samples[renoise.song().selected_sample_index].sample_buffer.number_of_frames  
    --snap on or off
    if (snapcount == 1 ) then
      --snap and deal with samples per beat as 0
      if (samples_per_beat * math.floor(vb.views.smpstartloop.value/samples_per_beat) == 0 ) then
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].loop_start = 1
      else
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].loop_start =
      samples_per_beat * math.floor(vb.views.smpstartloop.value/samples_per_beat)
      end
      --no snapping
      else
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].loop_start =
      vb.views.smpstartloop.value
      end 
    end      
end
-----------------
--sample select end loop
-----------------
local function fselectendloop()
    if (renoise.song().selected_instrument.samples[renoise.song().selected_sample_index]
    .sample_buffer.has_sample_data == true) then    
    --dont go past the start loop marker
    vb.views.smpendloop.min = vb.views.smpstartloop.value + 1    
    --dont go past the length of the sample
    vb.views.smpendloop.max = renoise.song().selected_instrument.
    samples[renoise.song().selected_sample_index].sample_buffer.number_of_frames 
    --snap on or off
    if (snapcount == 1 ) then
      --snap and deal with samples per beat as 0
      if (samples_per_beat * math.floor(vb.views.smpendloop.value/samples_per_beat) == 0 ) then
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].loop_end = samples_per_beat
      else
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].loop_end =
      samples_per_beat * math.floor(vb.views.smpendloop.value/samples_per_beat)
      end
      --no snapping
      else
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].loop_end =
      vb.views.smpendloop.value
      end 
    end 
end
-----------------
--volume samp
-----------------
local function fsmprvol()
 renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].volume =
 vb.views.smprvol.value * 4
end  
-----------------
--volume inst
-----------------
local function finstrvol()
    for i=1,#renoise.song().selected_instrument.samples do
    renoise.song().selected_instrument.samples[i].volume =
    vb.views.instrvol.value * 4
    end
end
-----------------
--volume reset
-----------------
local function fresetvolume()
    for i=1,#renoise.song().selected_instrument.samples do
    renoise.song().selected_instrument.samples[i].volume = 1.5
    end
end
-----------------
--pan samp
-----------------
local function fpansamp()
 renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].panning =
 vb.views.smppan.value
end  
-----------------
--pan inst
-----------------
local function fpaninst()
    for i=1,#renoise.song().selected_instrument.samples do
    renoise.song().selected_instrument.samples[i].panning =
    vb.views.instrpan.value 
    end
end
-----------------
--pan reset
-----------------
local function fresetpan()
    for i=1,#renoise.song().selected_instrument.samples do
    renoise.song().selected_instrument.samples[i].panning = 0.5
    end
end
-----------------
--control finetune transpose samp
-----------------
local function finetransample()
 renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].fine_tune = vb.views.finesmptran.value
end  
-----------------
--control finetune transpose inst
-----------------
local function finetraninstrument()
    for i=1,#renoise.song().selected_instrument.samples do
    renoise.song().selected_instrument.samples[i].fine_tune = vb.views.fineinsttran.value
    end
end
-----------------
--finetune reset
-----------------
local function fresetfinetune()
    for i=1,#renoise.song().selected_instrument.samples do
    renoise.song().selected_instrument.samples[i].fine_tune = 0
    end
end  
-----------------
--control freq
-----------------
local function fcontrolfreq()
    renoise.song().selected_instrument.sample_envelopes.cutoff.enabled = true
    renoise.song().selected_instrument.sample_envelopes.cutoff:clear_points()
    renoise.song().selected_instrument.sample_envelopes.cutoff:add_point_at(1,vb.views.fcontrolfreq1.value)
end
-----------------
--control reso
-----------------
local function fcontrolreso()
    renoise.song().selected_instrument.sample_envelopes.resonance.enabled = true
    renoise.song().selected_instrument.sample_envelopes.resonance:clear_points()
    renoise.song().selected_instrument.sample_envelopes.resonance:add_point_at(1,vb.views.fcontrolreso1.value)
end
-----------------
--control fx1
-----------------
local function fxv1()
    if (renoise.song().tracks[1].name == "MPEFX" ) then
    renoise.song().selected_track_index  = 1
    renoise.song().tracks[1].devices[renoise.song().selected_device_index].active_preset = 
    vb.views.fxv1.value
    else handle_error = true
    end
end
-----------------
--control fx2
-----------------
local function fcontrolfx2()   
    if (renoise.song().tracks[1].name == "MPEFX" ) then 
    renoise.song().selected_track_index  = 1
    --set min and max and value
    ---------------------------
    if (
    renoise.song().selected_device_index == 2 ) then --Multitap
    vb.views.fcontrolfx2.min = renoise.song().tracks[1].devices[2].parameters[6].value_min
    vb.views.fcontrolfx2.max = renoise.song().tracks[1].devices[2].parameters[6].value_max
    renoise.song().tracks[1].devices[2].parameters[6].value =
    vb.views.fcontrolfx2.value
    elseif
    renoise.song().selected_device_index == 3  then --Delay
    vb.views.fcontrolfx2.min = renoise.song().tracks[1].devices[3].parameters[5].value_min
    vb.views.fcontrolfx2.max = renoise.song().tracks[1].devices[3].parameters[5].value_max
    renoise.song().tracks[1].devices[3].parameters[5].value =
    vb.views.fcontrolfx2.value
    elseif
    renoise.song().selected_device_index == 4  then --Flanger
    vb.views.fcontrolfx2.min = renoise.song().tracks[1].devices[4].parameters[8].value_min
    vb.views.fcontrolfx2.max = renoise.song().tracks[1].devices[4].parameters[8].value_max
    renoise.song().tracks[1].devices[4].parameters[8].value =
    vb.views.fcontrolfx2.value
    elseif
    renoise.song().selected_device_index == 5  then --Phaser
    vb.views.fcontrolfx2.min = renoise.song().tracks[1].devices[5].parameters[4].value_min
    vb.views.fcontrolfx2.max = renoise.song().tracks[1].devices[5].parameters[4].value_max   
    renoise.song().tracks[1].devices[5].parameters[4].value =
    math.floor(vb.views.fcontrolfx2.value)
    elseif
    renoise.song().selected_device_index == 6  then --mpReverb
    vb.views.fcontrolfx2.min = renoise.song().tracks[1].devices[6].parameters[8].value_min
    vb.views.fcontrolfx2.max = renoise.song().tracks[1].devices[6].parameters[8].value_max
    renoise.song().tracks[1].devices[6].parameters[8].value =
    vb.views.fcontrolfx2.value /1.2
    elseif
    renoise.song().selected_device_index == 7  then --LofiMat
    vb.views.fcontrolfx2.min = renoise.song().tracks[1].devices[7].parameters[2].value_min
    vb.views.fcontrolfx2.max = renoise.song().tracks[1].devices[7].parameters[2].value_max
    renoise.song().tracks[1].devices[7].parameters[2].value =
    vb.views.fcontrolfx2.value
    elseif
    renoise.song().selected_device_index == 8  then --Gate
    vb.views.fcontrolfx2.min = renoise.song().tracks[1].devices[8].parameters[1].value_min
    vb.views.fcontrolfx2.max = renoise.song().tracks[1].devices[8].parameters[1].value_max
    renoise.song().tracks[1].devices[8].parameters[1].value =
    math.floor(vb.views.fcontrolfx2.value)
    elseif
    renoise.song().selected_device_index == 9  then --RingMod
    vb.views.fcontrolfx2.min = renoise.song().tracks[1].devices[9].parameters[3].value_min
    vb.views.fcontrolfx2.max = renoise.song().tracks[1].devices[9].parameters[3].value_max
    renoise.song().tracks[1].devices[9].parameters[3].value =
    vb.views.fcontrolfx2.value
    elseif
    renoise.song().selected_device_index == 10  then --Scream
    vb.views.fcontrolfx2.min = renoise.song().tracks[1].devices[10].parameters[2].value_min
    vb.views.fcontrolfx2.max = renoise.song().tracks[1].devices[10].parameters[2].value_max
    renoise.song().tracks[1].devices[10].parameters[2].value =
    vb.views.fcontrolfx2.value
    elseif
    renoise.song().selected_device_index == 11  then --Filter
    vb.views.fcontrolfx2.min = renoise.song().tracks[1].devices[11].parameters[2].value_min
    vb.views.fcontrolfx2.max = renoise.song().tracks[1].devices[11].parameters[2].value_max
    renoise.song().tracks[1].devices[11].parameters[2].value =
    vb.views.fcontrolfx2.value
    elseif
    renoise.song().selected_device_index == 12  then --Comb Filter
    vb.views.fcontrolfx2.min = renoise.song().tracks[1].devices[12].parameters[1].value_min
    vb.views.fcontrolfx2.max = renoise.song().tracks[1].devices[12].parameters[1].value_max
    renoise.song().tracks[1].devices[12].parameters[1].value =
    vb.views.fcontrolfx2.value
    end    

    end
end
-----------------
--control filter reset
-----------------
local function fresetfilter()
    renoise.song().selected_instrument.sample_envelopes.cutoff.enabled = false
    renoise.song().selected_instrument.sample_envelopes.resonance.enabled = false
end
-----------------
--control variation type
-----------------
local function fcontrolvartype1()
    renoise.song().selected_instrument.sample_envelopes.cutoff.enabled = true
    renoise.song().selected_instrument.sample_envelopes.filter_type = vb.views.fcontrolvartype1.value
end
-----------------
--control variation1/2 reset
-----------------
local function fresetvar()
    renoise.song().selected_instrument.sample_envelopes.pitch.enabled = false
    renoise.song().selected_instrument.sample_envelopes.cutoff.enabled = false
end
-----------------
--control attack
-----------------
local function fcontrolattack()
    renoise.song().selected_instrument.sample_envelopes.volume.enabled = true
    renoise.song().selected_instrument.sample_envelopes.volume:clear_points()
    renoise.song().selected_instrument.sample_envelopes.volume.length = 6
    renoise.song().selected_instrument.sample_envelopes.volume:add_point_at(6,1)
    renoise.song().selected_instrument.sample_envelopes.volume:add_point_at(1,vb.views.fcontrolattack.value)
end
-----------------
--control decay
-----------------
local function fcontroldecay()
    renoise.song().selected_instrument.sample_envelopes.volume.enabled = true
    renoise.song().selected_instrument.sample_envelopes.volume.fade_amount = vb.views.fcontroldecay1.value
end
-----------------
--control reset env
-----------------
local function fresetenv()
    renoise.song().selected_instrument.sample_envelopes.volume.enabled = false
    renoise.song().selected_instrument.sample_envelopes.volume.fade_amount = 128
    --set the note to continue (cut) when played
    renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].new_note_action = 1  
end
-----------------
--reset all
-----------------
local function freset()
  fresettune()
  fresetvolume()
  fresetpan()
  fresetfinetune()
  fresetfilter()
  fresetvar()
  fresetenv()
  dsliceclear()
  vb.views.slice.value = 1
end
-----------------
--chord
-----------------
local function fchord()
  if (renoise.song().transport.chord_mode_enabled == false ) then
  renoise.song().transport.chord_mode_enabled = true else
  renoise.song().transport.chord_mode_enabled = false
  end
end
-----------------
--count display
-----------------
local function fcounton()
    if (vb.views.countm.value == 1 ) then
    renoise.song().transport.metronome_enabled = false 
    else renoise.song().transport.metronome_enabled = true
    end
end         
-----------------
--hide all
-----------------
local function hideall()
  -- toggle visibility of the view on each click
  vb.views.gui_left.visible = not vb.views.gui_left.visible
end  
-----------------
--hide half
-----------------
local function hidehalf()
  vb.views.gui_right.visible = not vb.views.gui_right.visible
end  
-----------------


--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------


--dialog_content (entire GUI)
-------------------------
local dialog_content =
      vb:column { 
      -- style = "panel",
      margin = text_row_space/4.6,
      spacing = 6,
-------------------------


--above screen
----------------------------------
vb:row {
----------------------------------

        
      -----------------       
      vb:bitmap {
      midi_mapping = "MPE:Display:Hide & Show Tool",
      mode = "transparent",
      bitmap = "Bitmaps/mpe.bmp",
      tooltip = "Sevenscientist's special thanks to: \nbantai / dblue / it-alien / conner_bw / esaruoho / mxb / danoise .\nIf you are using a demo copy please consider purchasing the full version of Renoise.",
      notifier = function ()
      hideall()
      end
      },
      -----------------       
      vb:bitmap {
      mode = "transparent",
      bitmap = "Bitmaps/mpe 3.bmp",
      },
      -----------------
      vb:bitmap {
      mode = "transparent",
      bitmap = "Bitmaps/vd.bmp",
      },
      -----------------
      vb:bitmap {
      mode = "transparent",
      bitmap = "Bitmaps/mpe 7.bmp",
      },
      -----------------
      

----------------------------      
}, --above screen
----------------------------

----------------------------------------------------------------------------------------------------------------
--interface
----------------------------------------------------------------------------------------------------------------

  vb:column {
  id = "gui_left", 
  --spacing = default_control_spacing*3,

vb:column { 
id = "screen_g",
uniform = true,
style = "group",
margin = 6,
spacing = 1,

--------------------------------------------------------------------------------
-- GUI Screen 01 song
--------------------------------------------------------------------------------

  vb:column {
  id = "gui_screen01",
  spacing = default_control_spacing, 
  style = "border",
  uniform = true,
  width = "100%",
  vb:row{height=12},--spacer

----------------------------------
vb:horizontal_aligner {
mode = "center", 
----------------------------------       


      -----------------
      vb:text {
      tooltip = "Change the pattern in the current (Sequence). Decimal values are invalid.",
      width = text_row_space,
      align = "right",          
      text = "sq :",
      },
      ----------------- 
      vb:valuebox {
      id = "sq", 
      min = 1,
      max = 99, 
      width = text_row_space,
      value = renoise.song().selected_pattern_index,
      notifier = function(sqs)
      renoise.song().selected_pattern_index = sqs
      end,                  
      },
      ------------------ 
      vb:textfield {
      id = "sqname",
      width = text_row_space + text_row_space,
      align = "left",
      value = renoise.song().selected_pattern.name,      
      notifier = function(sqname)
      renoise.song().selected_pattern.name = sqname 
      end,  
      },
      -----------------           
      vb:text {
      tooltip = "Displays the songs position as BAR.BEAT.COUNT.",        
      width = text_row_space,
      align = "right",          
      text = "now :"
      }, 
      ----------------- 
      vb:text {
      id = "nowbar",        
      width = text_row_space, 
      text = tostring(bar),
      font = "bold",
      },
      ----------------- 


},   
----------------------------------
vb:horizontal_aligner {
mode = "center",  
----------------------------------
    
      
      -----------------    
      vb:text {
      tooltip = "Change the song BPM. Decimal values are invalid.",
      width = text_row_space,
      align = "right",
      text = "bpm :",
      }, 
      -----------------
      vb:valuebox {
      id = "beatpm",
      midi_mapping = "MPE:Display:BPM", 
      min = 32,
      max = 999,
      width = text_row_space,
      value = renoise.song().transport.bpm,
      notifier = function(bp)
      renoise.song().transport.bpm = bp
      end,
      },
      -----------------
      vb:text {
      tooltip = "The values change the songs time resolution.\nHigher values for more detail (speeds up playback).\nUse with timing/quantize button",
      width = text_row_space,
      align = "right",
      text = "timing :"
      }, 
      -----------------
      vb:popup {
      width = text_row_space,
      id = "timing",  
      midi_mapping = "MPE:Song:Timing",        
      items = {"-","1/4", "1/8", "1/16", "1/32"},
      notifier = function()
      timing_change()
      end
      }, 
      -----------------      
      vb:text {
      tooltip = "Quantize, correct live recording by amount of lines.\nEnable timing first",
      width = text_row_space,
      align = "right",
      text = "quantize :",          
      }, 
      -----------------
      vb:valuebox {
      id = "qtime",
      min = 1,
      max = 32,
      notifier = function(qtime)
      renoise.song().transport.record_quantize_lines = qtime
      end,
      },     
      -----------------           
      

}, 
----------------------------------
vb:horizontal_aligner {
mode = "center",  
----------------------------------


      -----------------
      vb:text {
      tooltip = "Enable/Disable the metronome",
      width = text_row_space,
      align = "right",
      text = "count :",  
      }, 
      -----------------    
      vb:popup {
      width = text_row_space,
      id = "countm",
      midi_mapping = "MPE:Display:Count",          
      items = {"no", "yes"},
      notifier = function()
      fcounton()         
      end   
      },      
      -----------------
      vb:text {
      tooltip = "Repeat the current pattern.",
      width = text_row_space,
      align = "right",
      text = "loop :",        
      }, 
      -----------------
      vb:popup {
      width = text_row_space,
      id = "loop",       
      midi_mapping = "MPE:Display:Loop",   
      items = {"off", "on"},
      notifier = function()
      loop_on()                   
      end                 
      },    
      -----------------
      vb:text {
      tooltip = "Change the quantity of (Bars) in a pattern.\nDecreasing will not delete notes.\nTime Signature is 4/4.",
      width = text_row_space,
      align = "right",
      text = "bars :"
      }, 
      -----------------
      vb:valuebox {
      id = "bars",
      min = 1,
      max = 16,
      value = 1, 
      width = text_row_space,
      notifier = function()
      bars_change()
      end
      },
      -----------------
 
 
}, 
----------------------------------
vb:horizontal_aligner {
mode = "center",  
---------------------------------- 


      -----------------
      vb:text {
      tooltip = "The currently selected (Track) in the song.",
      width = text_row_space,
      align = "right",
      text = "track :",
      }, 
      ----------------- 
      vb:valuebox {
      id = "track",
      min = 1,
      max = #renoise.song().tracks,
      width = text_row_space,    
      value = renoise.song().selected_track_index,          
      notifier = function(tr)
      renoise.song().selected_track_index  = tr
      --change the instrument (pgm) to match the track
      renoise.song():capture_nearest_instrument_from_pattern()
      end,  
      },   
      -----------------  
      vb:textfield {
      id = "trackname",
      width = text_row_space + text_row_space,
      align = "left",
      value = renoise.song().tracks[renoise.song().selected_track_index].name,
      notifier = function(tname)
      renoise.song().tracks[renoise.song().selected_track_index].name = tname 
      end,  
      }, 
      -----------------           
      vb:text {
      tooltip = "Mute the currently selected track.\nWhen displayed as -yes-\nthe track will actually be turned (Off) .",
      width = text_row_space,
      align = "right",
      text = "mute :",        
      }, 
      -----------------
      vb:popup {
      width = text_row_space,
      id = "mute_on",          
      items = {"no", "yes"},          
      notifier = function()
      fmuted()
      end      
      },  
      -----------------


}, 
----------------------------------
vb:horizontal_aligner {
mode = "center",  
----------------------------------     
      
      -----------------       
      vb:text {
      tooltip = "The currently selected instrument.\nOr the recorded instrument in the current (Track).",
      width = text_row_space,
      align = "right",
      text = "pgm :",          
      }, 
      -----------------           
      vb:valuebox {
      id = "pgm",
      min = 1,
      max = #renoise.song().instruments,
      width = text_row_space,                    
      value = renoise.song().selected_instrument_index,
      notifier = function(inst)
      renoise.song().selected_instrument_index = inst
      end,
      },   
      -----------------   
      vb:textfield {
      id = "pgmname",
      width = text_row_space + text_row_space,
      align = "left",
      value = renoise.song().selected_instrument.name, 
      notifier = function(pname)
      renoise.song().selected_instrument.name = pname  
      end,                     
      }, 
      -----------------      
      vb:text {
      tooltip = "The current pattern loop block fraction size.",
      width = text_row_space,
      align = "right",
      text = "blocksize :",          
      }, 
      -----------------
      vb:valuebox {
      midi_mapping = "MPE:Song:LoopBlock Size",
      id = "sngblk",
      min = 2,
      max = 16,
      notifier = function(sngblk)
      renoise.song().transport.loop_block_range_coeff = sngblk
      end
      },
      -----------------  
      

}, 

vb:row{height=12},--spacer

----------------------------------
},--screen01
----------------------------------
 

--------------------------------------------------------------------------------
-- GUI Screen 02 trim
--------------------------------------------------------------------------------

  vb:column {  
  id = "gui_screen02",
  visible = false,
  spacing = default_control_spacing, 
  style = "border",
  uniform = true,
  width = "100%",  
  vb:row{height=12},--spacer

----------------------------------
vb:horizontal_aligner {
mode = "center",  
----------------------------------



      -----------------
      vb:text {
      tooltip = "Sample name for the current selected instrument",
      width = text_row_space,
      align = "right",
      text = "sample :",          
      },
      -----------------           
      vb:valuebox {
      id = "pgmsample",
      min = 1,
      max = #renoise.song().selected_instrument.samples,
      width = text_row_space,                    
      value = renoise.song().selected_sample_index,
      notifier = function(pgmsample)
      renoise.song().selected_sample_index = pgmsample
      end,
      },
      -----------------   
      vb:text {
      tooltip = "The currently selected instrument.\nOr the recorded instrument in the current (Track).",
      width = text_row_space,
      align = "right",
      text = "name :",          
      },              
      ----------------- 
      vb:textfield {
      tooltip = "Sample name for the current selected instrument",
      id = "pgmsamplename",
      width = text_row_space*3,
      align = "left",
      value = renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].name,      
      notifier = function(pgmsamplename)
      renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].name = pgmsamplename 
      end,  
      },
      -----------------   

      


}, 
----------------------------------
vb:horizontal_aligner {
mode = "center",  
----------------------------------
      


      -----------------
      vb:text {
      tooltip = "Sample volume.",
      width = text_row_space,
      align = "right",
      text = "vol :",          
      },
      -----------------           
      vb:minislider {
      id = "smprvol",
      midi_mapping = "MPE:Sample:Volume",
      width = text_row_space,
      notifier = function()
      fsmprvol()
      end
      },
      -----------------
      vb:text {
      tooltip = "Select-start sample selection point.",
      width = text_row_space,
      align = "right",
      text = "s-select :",          
      },
      -----------------                  
      vb:minislider {
      width = text_row_space,
      id = "smpstart",
      min = 1,
      midi_mapping = "MPE:Sample:Select Start", 
      notifier = function()
      fselectstart()
      end
      },
      -----------------
      vb:text {
      tooltip = "Sample note playback action.",
      width = text_row_space,
      align = "right",
      text = "overlap :",          
      },
      -----------------
      vb:popup {
      id = "noteaction",
      width = text_row_space,         
      items = {"Cut","Note Off", "Continue"},
      midi_mapping = "MPE:Display:voice NNA",
      notifier = function()
      noteaction()
      end
      },        
      -----------------      
      
      
}, 
----------------------------------
vb:horizontal_aligner {
mode = "center",  
----------------------------------

      -----------------
      vb:text {
      tooltip = "Sample pan.",
      width = text_row_space,
      align = "right",
      text = "pan :",          
      },
      -----------------                    
      vb:minislider {
      width = text_row_space,
      id = "smppan",
      min = 0,
      max = 1,
      value = 0.5,
      midi_mapping = "MPE:Sample:Pan", 
      notifier = function()
      fpansamp()
      end
      },
      -----------------
      vb:text {
      tooltip = "Select-end sample selection point.",
      width = text_row_space,
      align = "right",
      text = "e-select :",          
      },
      -----------------
      vb:minislider {
      width = text_row_space,
      id = "smpend",
      min = 1,
      midi_mapping = "MPE:Sample:Select End",
      notifier = function()
      fselectend()
      end
      },
      -----------------
      vb:text {
      tooltip = "The length of the current sample in beats or bars when sample Sync is enabled ",
      width = text_row_space,
      align = "right",
      text = "sync :",          
      },
      -----------------           
      vb:popup {
      id = "smpsyncval",
      midi_mapping = "MPE:Sample:Syncval",
      items = {"-","1-Beat", "2-Beat", "1-Bar", "2-Bar", "4-Bar", "8-Bar", "16-Bar", "32-Bar"},
      width = text_row_space,                    
      value = 1,
      notifier = function()
      sval()
      end,
      },   
      -----------------

 
}, 
----------------------------------
vb:horizontal_aligner {
mode = "center",  
----------------------------------


      -----------------
      vb:text {
      tooltip = "Sample transpose.\nmidi map-mode = Relative bin offset",
      width = text_row_space,
      align = "right",
      text = "tune :",          
      },
      -----------------      
      vb:valuebox {
      id = "smptran",
      min = -120, 
      max = 120,
      midi_mapping = "MPE:Sample:Transpose",
      notifier = function()
      ftransample()    
      end
      },      
      -----------------
      vb:text {
      tooltip = "Loop-start marker.",
      width = text_row_space,
      align = "right",
      text = "s-loop :",          
      },
      -----------------                   
      vb:minislider {
      width = text_row_space,
      midi_mapping = "MPE:Sample:Loop Start",
      id = "smpstartloop",
      min = 1,
      notifier = function()
      fselectstartloop()
      end
      },
      -----------------
      vb:text {
      tooltip = "Slice the selected sample into an even number of slices.\nWorks best with samples that are whole beats in 4/4 signature",
      width = text_row_space,
      align = "right",
      text = "slices :",          
      },
      -----------------
      vb:popup {
      width = text_row_space,
      id = "slice",       
      items = {"-", "4", "8", "16", "32"},
      --midi_mapping = "MPE:Display:Slices",
      notifier = function()
      slice_change()
      end
      },        
      -----------------
      
      
}, 
----------------------------------
vb:horizontal_aligner {
mode = "center",  
----------------------------------


      -----------------
      vb:text {
      tooltip = "Sample finetune.\nmidi map-mode = Relative bin offset",
      width = text_row_space,
      align = "right",
      text = "finetune :",          
      },
      -----------------     
      vb:valuebox {
      id = "finesmptran",
      min = -127, 
      max = 127,
      midi_mapping = "MPE:Sample:Finetune Transpose",
      notifier = function()
      finetransample()     
      end
      },      
      -----------------
      vb:text {
      tooltip = "Loop-end marker.",
      width = text_row_space,
      align = "right",
      text = "e-loop :",          
      },
      -----------------
      vb:minislider {
      width = text_row_space,      
      tooltip = "LOOP-End marker.",
      midi_mapping = "MPE:Sample:Loop End",
      id = "smpendloop",
      min = 1,
      notifier = function()
      fselectendloop()
      end
      },
      -----------------
      vb:text {
      tooltip = "Sample loop mode.",
      width = text_row_space,
      align = "right",
      text = "loopmode :",          
      },
      -----------------
      vb:popup {
      id = "sampleloopmode",
      midi_mapping = "MPE:Sample:LoopMode",
      width = text_row_space,         
      items = {"off", "Forward","Backward", "PingPong"},
      notifier = function()
      sampleloopmode()  
      end     
      },        
      -----------------     
      
},

vb:row{height=12},--spacer

----------------------------------
}, --screen02
----------------------------------


--------------------------------------------------------------------------------
-- GUI Screen 03 prog
--------------------------------------------------------------------------------

  vb:column {  
  id = "gui_screen03",
  visible = false,
  spacing = default_control_spacing, 
  style = "border",
  uniform = true,
  width = "100%",
  vb:row{height=12},--spacer


----------------------------------
vb:horizontal_aligner {
mode = "center",  
----------------------------------



      -----------------       
      vb:text {
      tooltip = "The currently selected instrument.\nOr the recorded instrument in the current (Track).",
      width = text_row_space,
      align = "right",
      text = "pgm :",          
      }, 
      -----------------           
      vb:valuebox {
      id = "pgmprog",
      min = 1,
      max = #renoise.song().instruments,
      width = text_row_space,                    
      value = renoise.song().selected_instrument_index,
      notifier = function(inst)
      renoise.song().selected_instrument_index = inst
      end,
      },         
      -----------------   
      vb:text {
      tooltip = "The currently selected instrument.\nOr the recorded instrument in the current (Track).",
      width = text_row_space,
      align = "right",
      text = "name :",          
      }, 
      -----------------  
      vb:textfield {
      id = "pgmnameprog",
      width = text_row_space*3,
      align = "left",
      value = renoise.song().selected_instrument.name, 
      notifier = function(pname)
      renoise.song().selected_instrument.name = pname  
      end,                     
      }, 
      -----------------       
  


}, 
----------------------------------
vb:horizontal_aligner {
mode = "center",  
----------------------------------
      


      -----------------
      vb:text {
      tooltip = "Instrument sample volume.",
      width = text_row_space,
      align = "right",
      text = "vol :",          
      },
      -----------------
      vb:minislider {
      width = text_row_space,
      id = "instrvol",
      midi_mapping = "MPE:Sample:Volume Inst",
      notifier = function()
      finstrvol()
      end
      },
      -----------------
      vb:text {
      tooltip = "Sample instrument Attack.",
      width = text_row_space,
      align = "right",
      text = "attack :",          
      },
      -----------------            
      vb:minislider {
      width = text_row_space,
      id = "fcontrolattack",
      min = 0,
      max = 1,
      midi_mapping = "MPE:Sample:Attack",
      notifier = function()
      fcontrolattack()
      end
      },
      -----------------
      vb:text {
      tooltip = "Sample Cutoff filter type LowPass/HighPass/Band/EQ/Dist/Ring",
      width = text_row_space,
      align = "right",
      text = "filter :",          
      },
      -----------------                 
      vb:valuebox {
      midi_mapping = "MPE:Sample:Filter Type",
      id = "fcontrolvartype1",
      min = 1,
      max = 20,
      notifier = function()
      fcontrolvartype1()
      end
      },
      -----------------
      
        

}, 
----------------------------------
vb:horizontal_aligner {
mode = "center",  
----------------------------------


      -----------------
      vb:text {
      tooltip = "Instrument pan.",
      width = text_row_space,
      align = "right",
      text = "pan :",          
      },
      -----------------
      vb:minislider {
      width = text_row_space,
      id = "instrpan",
      min = 0,
      max = 1,
      value = 0.5,
      midi_mapping = "MPE:Sample:Pan Inst",
      notifier = function()
      fpaninst()
      end
      },
      -----------------
      vb:text {
      tooltip = "Sample instrument Decay.",
      width = text_row_space,
      align = "right",
      text = "decay :",          
      },
      -----------------
      vb:minislider {
      width = text_row_space,
      id = "fcontroldecay1",
      min = 0,
      max = 4095,
      midi_mapping = "MPE:Sample:Decay",
      notifier = function()
      fcontroldecay()
      end
      },
      ----------------- 
      vb:text {
      tooltip = "1.Off\n2.Multitap\n3.Delay\n4.Flanger\n5.Phaser\n6.Reverb\n7.Lofi\n8.Gate\n9.RingMod\n10.Scream\n11.Filter\n12.CombFilter\n13.Repeater",
      width = text_row_space,
      align = "right",
      text = "fx :",          
      },
      -----------------
      vb:valuebox {
      id = "fxv2",      
      midi_mapping = "MPE:Sample:Effect Type",
      min = 1, -- 1 is off
      max = 13,
      notifier = function()
      ffxdevice()
      end
      },
      ----------------- 


}, 
----------------------------------
vb:horizontal_aligner {
mode = "center",  
----------------------------------


      -----------------
      vb:text {
      tooltip = "Instrument sample transpose.\nmidi map-mode = Relative bin offset",
      width = text_row_space,
      align = "right",
      text = "tune :",          
      },
      -----------------   
      vb:valuebox {
      id = "insttran",
      min = -12, 
      max = 12,
      midi_mapping = "MPE:Sample:Transpose Inst",
      notifier = function()
      ftraninstrument()
      end
      }, 
      -----------------
      vb:text {
      tooltip = "Sample instrument frequency cutoff.",
      width = text_row_space,
      align = "right",
      text = "cutoff :",          
      },
      -----------------                   
      vb:minislider {
      width = text_row_space,
      id = "fcontrolfreq1",
      min = 0,
      max = 1,
      midi_mapping = "MPE:Sample:Cutoff Freq", 
      notifier = function()
      fcontrolfreq()
      end
      },
      -----------------
      vb:text {
      tooltip = "Instrument effect preset",
      width = text_row_space,
      align = "right",
      text = "preset :",          
      },
      -----------------                 
      vb:minislider {
      width = text_row_space,
      id = "fxv1",
      min = 1,
      --value = 1,
      midi_mapping = "MPE:Sample:Effect Preset", 
      notifier = function()
      fxv1()
      end
      },
      -----------------


}, 
----------------------------------
vb:horizontal_aligner {
mode = "center",  
----------------------------------


      -----------------
      vb:text {
      tooltip = "Instrument sample finetune.\nmidi map-mode = Relative bin offset",
      width = text_row_space,
      align = "right",
      text = "finetune :",          
      },
      -----------------     
      vb:valuebox {
      id = "fineinsttran",
      min = -127, 
      max = 127,
      midi_mapping = "MPE:Sample:Finetune Transpose Inst",
      notifier = function()
      finetraninstrument()
      end
      }, 
      -----------------
      vb:text {
      tooltip = "Sample instrument resonance.",
      width = text_row_space,
      align = "right",
      text = "reso :",          
      },
      -----------------
      vb:minislider {
      width = text_row_space,
      id = "fcontrolreso1",
      min = 0,
      max = 0.7,
      midi_mapping = "MPE:Sample:Resonance", 
      notifier = function()
      fcontrolreso()
      end
      },
      -----------------
      vb:text {
      tooltip = "Instrument effect amount",
      width = text_row_space,
      align = "right",
      text = "amount :",          
      },
      -----------------
      vb:minislider {
      width = text_row_space,      
      id = "fcontrolfx2",
      midi_mapping = "MPE:Sample:Effect Amount",
      notifier = function()
      fcontrolfx2()      
      end
      },
      -----------------         

}, 

vb:row{height=12},--spacer

----------------------------------
}, --screen03
----------------------------------

vb:row{height=2},--spacer  

--------------------------------------------------------------------------------
--functions  
--------------------------------------------------------------------------------


----------------------------------
vb:horizontal_aligner {
mode = "center",  
----------------------------------


      
      -----------------
      vb:button {
      id = "fstep",
      tooltip = "Disable (Follow Player Position) and (Enable Record Mode).",
      text = "STEP",
      width = btn_function_width,
      color = btn_f1,
      midi_mapping = "MPE:Function:Step Editing",
      pressed = function()
      fstep()
      end 
      },
      -----------------
      vb:button {
      tooltip = "Enable the (Advanced Edit Functions) for the pattern window.\nSelect / Cut / Copy / Paste.",
      text = "EDIT",
      width = btn_function_width,
      color = btn_f1,
      midi_mapping = "MPE:Function:Edit Functions",
      pressed = function()
      fedit()
      end
      },
      -----------------
      vb:button {
      tooltip = "Mute the currently selected track.\nThe track will actually be turned (Off) .",
      text = "MUTE",
      width = btn_function_width,
      color = btn_f1,
      midi_mapping = "MPE:Function:Mute Track",
      pressed = function()
      fmute() 
      end
      },
      -----------------
      vb:button {
      tooltip = "(Solo) the currently selected (Track).",
      text = "SOLO",
      width = btn_function_width,
      color = btn_f1,
      midi_mapping = "MPE:Function:Solo Track",
      pressed = function()
      fsolo()
      end      
      },
      -----------------
      vb:button {
      tooltip = "Move to the previous (Track) in the song.",
      text = "TR -",
      width = btn_function_width,
      color = btn_f1,
      midi_mapping = "MPE:Function:Select the Previous Track",
      pressed = function()
      ftrackback()
      end
      },     
      -----------------
      vb:button {
      tooltip = "Move to the next (Track) in the song.",
      text = "TR +",
      width = btn_function_width,
      color = btn_f1,
      midi_mapping = "MPE:Function:Select Next Track",
      pressed = function()
      ftrackforward()
      end
      },           
      -----------------


},

}, --group

vb:row{height=8},--spacer

--------------------------------------------------------------------------------
--samplemode
--------------------------------------------------------------------------------

vb:column { 
id = "samplemode_g",
uniform = true,
-- style = "panel",
margin = 6,
spacing = 1,

---------------------------------
vb:horizontal_aligner {
mode = "center", 
----------------------------------


      -----------------
      vb:button {
      tooltip = "Select the previous instrument",
      text = "PGM -",
      color = btn_f1,
      width = btn_extra_width,
      height = btn_extra_height,
      midi_mapping = "MPE:Function:Select the Previous Instrument",
      pressed = function()
      fpgmback()
      end
      },      
      -----------------
      vb:button {
      tooltip = "Select the next instrument",
      text = "PGM +",
      color = btn_f1,
      width = btn_extra_width,
      height = btn_extra_height,
      midi_mapping = "MPE:Function:Select the Next Instrument",
      pressed = function()
      fpgmforward()
      end
      }, 
      -----------------     
      vb:button {
      tooltip = "Save the MPEFX track with current\nactive effect selected in TRIM screen.",
      text = "SAVEFX",
      color = btn_f1,
      width = btn_extra_width,
      height = btn_extra_height,
      midi_mapping = "MPE:Function:Effect to Track",
      pressed = function()
      ffxsave()
      end
      }, 
      -----------------
      vb:button {
      tooltip = "Reset the sample Volume / Envelope / Pan\nTune / Finetune / Cutoff / Resonance / Slices",
      text = "RESET",
      color = btn_f1,
      width = btn_extra_width,
      height = btn_extra_height,
      midi_mapping = "MPE:Function:Sample Reset",
      pressed = function()
      freset()
      end
      },  
      -----------------  
      vb:button {
      id = "fsnap",
      tooltip = "Move the selection and loop markers to the nearest beat.",
      text = "SNAP",
      color = btn_f1,
      width = btn_extra_width,
      height = btn_extra_height,
      midi_mapping = "MPE:Function:Snap",
      pressed = function()
      fsnap()
      end
      }, 
      -----------------
      vb:button {
      id = "slicemarker",
      tooltip = "Add a slice marker at the current selected start point.\nUse the select start control.",
      text = "SLICE",
      color = btn_f1,
      width = btn_extra_width,
      height = btn_extra_height,
      midi_mapping = "MPE:Function:Slice Marker",
      pressed = function()
      fpgmslicemarker()
      end 
      },       
      ----------------- 
      
},

----------------------------------
vb:horizontal_aligner {
mode = "center", 
----------------------------------


      -----------------
      vb:button {
      id = "floopforwardpgm",
      tooltip = "Instrument loop forward\n* using loop start and end points.",
      text = "LP / PGM",
      color = btn_f1,
      width = btn_extra_width,
      height = btn_extra_height,
      midi_mapping = "MPE:Function:Loop Sample Forward Instrument",
      pressed = function()
      floopforwardpgm()
      end
      }, 
      -----------------
      vb:button {
      id = "ftransposesyncpgm",
      tooltip = "Instrument transpose / tune to song BPM.\n* Tap tempo to the original beat first.\n* Adjust the sync value in the Trim screen",
      text = "SC / PGM",
      color = btn_f1,
      width = btn_extra_width,
      height = btn_extra_height,
      midi_mapping = "MPE:Function:Beatsync Transpose Instrument",
      pressed = function()
      ftransposesyncpgm()
      end 
      }, 
      -----------------    
      vb:button {
      id = "fcutnotepgm",
      tooltip = "Instrument playback to CUT.\n* Notes wont overlap when triggered over each other.\n* Acts as 1 mute group.",
      text = "CUT / PGM",
      color = btn_f1,
      width = btn_extra_width,
      height = btn_extra_height,
      midi_mapping = "MPE:Function:Cut Instrument",
      pressed = function()
      fcutnotepgm()
      end
      }, 
      -----------------
      vb:button {
      id = "fhold",
      tooltip = "Holds / sustains the instrument samples.",
      text = "HOLD",
      color = btn_f1,
      width = btn_extra_width,
      height = btn_extra_height,
      midi_mapping = "MPE:Function:Hold",
      pressed = function()
      fhold()
      end
      },       
      -----------------
      vb:button {
      id = "fxdelay",
      tooltip = "Apply the MultiTap Delay effect",
      text = "DELAY",
      color = btn_f1,
      width = btn_extra_width,
      height = btn_extra_height,
      midi_mapping = "MPE:Function:Delay",
      pressed = function()
      fxdelay()
      end
      },  
      ----------------- 
      vb:button {
      id = "flevel",
      tooltip = "Set volume to maximum for all samples.\nIn the selected instrument.",
      text = "FLEVEL",
      color = btn_f1,
      width = btn_extra_width,
      height = btn_extra_height,
      midi_mapping = "MPE:Function:Full Level",
      pressed = function()
      flevel()
      end
      },
      ----------------- 
},

----------------------------------
vb:horizontal_aligner {
mode = "center", 
----------------------------------




      -----------------
      vb:button {
      id = "fpgmloopfw",
      tooltip = "Sample loop forward\n * using loop start and end points.",
      text = "LOOP",
      color = btn_f1,
      width = btn_extra_width,
      height = btn_extra_height,
      midi_mapping = "MPE:Function:Loop Sample Forward",
      pressed = function()
      floopforwardsample()
      end
      }, 
      -----------------
      vb:button {
      id = "ftransposesyncsample",
      tooltip = "Sample transpose / tune to song BPM.\n* Tap tempo to the original beat first.\n* Adjust the sync value in the Trim screen",
      text = "SYNC",
      color = btn_f1,
      width = btn_extra_width,
      height = btn_extra_height,
      midi_mapping = "MPE:Function:Beatsync Transpose",
      pressed = function()
      ftransposesyncsample()
      end 
      }, 
      -----------------
      vb:button {
      id = "fcutnotesample",
      tooltip = "Sample playback to CUT.\n* Notes wont overlap when triggered over each other.",
      text = "CUT",
      color = btn_f1,
      width = btn_extra_width,
      height = btn_extra_height,
      midi_mapping = "MPE:Function:Cut",
      pressed = function()
      fcutnotesample()
      end
      }, 
      -----------------
      vb:button {
      id = "fchord",
      tooltip = "Enable/Disable Chord mode. (Enabled multiple notes can be played at once).",
      text = "CHORD",
      color = btn_f1,
      width = btn_extra_width,
      height = btn_extra_height,
      midi_mapping = "MPE:Function:Chord",
      pressed = function()
      fchord()
      end
      },
      ----------------- 
      vb:button {
      tooltip = "The previous plugin's preset",
      text = "PRE -",
      color = btn_f1,
      width = btn_extra_width,
      height = btn_extra_height,
      midi_mapping = "MPE:Function:Plugin Previous Preset",
      pressed = function()
      fplugpreviouspreset()
      end
      },  
      -----------------
      vb:button {
      tooltip = "The next plugin's preset",
      text = "PRE +",
      color = btn_f1,
      width = btn_extra_width,
      height = btn_extra_height,
      midi_mapping = "MPE:Function:Plugin Next Preset",
      pressed = function()
      fplugnextpreset()
      end
      },  
      -----------------     
         
},
}, --group

vb:row{height=8},--spacer

--------------------------------------------------------------------------------
--mode 
--------------------------------------------------------------------------------

vb:column { 
id = "mode_g",
uniform = true,
-- style = "panel",
margin = 6,
spacing = 0,

---------------------------------- 
  vb:horizontal_aligner {
  mode = "center",
----------------------------------


      -----------------    
      vb:button {
      tooltip = "Display the - Mixer Window.",
      text = "MIXER",
      color = btn_f3,
      width = btn_common_width,
      height = btn_common_height,
      midi_mapping = "MPE:Function:Mixer",
      pressed = function()
      fmixer()    
      end
      },
      -----------------
      vb:button {
      tooltip = "Coming Soon..",
      text = "PADS",
      color = btn_f3,
      width = btn_common_width,
      height = btn_common_height,
      }, 
      -----------------
      vb:button {
      tooltip = "Record a new sample.\n* Press again to stop sampling",
      text = "REC",
      color = btn_f3,
      width = btn_common_width,
      height = btn_common_height,
      midi_mapping = "MPE:Function:Instant Sample",
      pressed = function()
      fisample()
      end
      },   
      -----------------
      vb:button {
      tooltip = "Undo the last action",
      text = "UNDO",
      color = btr_on,
      width = btn_common_width,
      height = btn_common_height,
      midi_mapping = "MPE:Function:Undo",
      pressed = function()
      fundo()
      end 
      },
      -----------------
      vb:button {
      tooltip = "Clear the current pattern.\nCan be done while recording.",
      text = "ERASE",
      color = btr_on,
      width = btn_common_width,
      height = btn_common_height,
      midi_mapping = "MPE:Function:Erase",
      pressed = function()
      ferase()
      end
      },
      -----------------    
      

},
----------------------------------
vb:horizontal_aligner {
mode = "center",  
----------------------------------


      ----------------- 
      vb:button {
      tooltip = "Display the - Sample Recorder.\n* Press again to sample and again to stop.",
      text = "SAMPLE",
      color = btn_f3,
      width = btn_common_width,
      height = btn_common_height,
      midi_mapping = "MPE:Function:Sample",
      pressed = function()
      fsample()
      end
      },
      -----------------
      vb:button {
      tooltip = "Display the - Sample Editor Window.",
      text = "TRIM",
      color = btn_f3,
      width = btn_common_width,
      height = btn_common_height,
      midi_mapping = "MPE:Function:Trim",
      pressed = function()
      ftrim()
      end
      },
      -----------------
      vb:button {
      tooltip = "Display the - Sample Keyzones Window.",
      text = "PROG",
      color = btn_f3,
      width = btn_common_width,
      height = btn_common_height,
      midi_mapping = "MPE:Function:Program",
      pressed = function()
      fprog()    
      end
      },
      -----------------
      vb:button {
      tooltip = "Create a new song.\nwill ask to save or discard current song",
      text = "NEW",
      color = btn_f7,
      width = btn_common_width,
      height = btn_common_height,
      pressed = function()
      fnew()
      end
      },    
      -----------------
      vb:button {
      tooltip = "Switch ON or OFF timing (quantize-2 lines).",
      id = "timingonoff",
      text = "TIMING",
      color = btn_f4,
      width = btn_common_width,
      height = btn_common_height,
      midi_mapping = "MPE:Function:Timing ON",
      pressed = function()
      ftiming()
      end
      },
      -----------------  


},
----------------------------------
vb:horizontal_aligner {
mode = "center",  
----------------------------------


      -----------------
      vb:button {
      tooltip = "Display the - Pattern Editor Window.",
      text = "SONG",
      color = btn_f3,
      width = btn_common_width,
      height = btn_common_height,
      midi_mapping = "MPE:Function:Song",
      pressed = function()
      fsong()
      end
      },
      -----------------
      vb:button {
      tooltip = "Display the - Expanded Disk Browser.",
      text = "LOAD",
      color = btn_f3,
      width = btn_common_width,
      height = btn_common_height,
      midi_mapping = "MPE:Function:Load",
      pressed = function()
      fload()
      end
      },
      -----------------          
      vb:button {
      tooltip = "Save the current Song.",
      text = "SAVE",
      color = btn_f3,
      width = btn_common_width,
      height = btn_common_height,
      midi_mapping = "MPE:Function:Save Song",
      pressed = function()
      fsave()
      end
      },
      -----------------
      
      -----------------            
      vb:button {
      tooltip = "Set the songs BPM.\nTap button in rhythm at least (2) times.",
      text = "TAP",
      color = btn_f4,
      width = btn_common_width*2,
      height = btn_common_height,
      midi_mapping = "MPE:Function:Tap Tempo",
      pressed = function()
      tap()
      end 
      },
      -----------------

},
----------------------------------
vb:horizontal_aligner {
mode = "center",  
----------------------------------



      -----------------
      vb:button {
      tooltip = "Move the playback position to the previous\npattern in the  song.",
      text = "PREV",
      color = btn_f6,
      width = btn_common_width,
      height = btn_common_height,
      midi_mapping = "MPE:Function:Previous Sequence",
      pressed = function ()
      fprevsq()
      end
      },
      -----------------
      vb:button {
      tooltip = "Move the playback position to the next\npattern in the song.",
      text = "NEXT",
      color = btn_f6,          
      width = btn_common_width,
      height = btn_common_height,
      midi_mapping = "MPE:Function:Next Sequence",
      pressed = function ()
      fnextsq()
      end
      },
      -----------------
      vb:button {
      tooltip = "Add a pattern to the song.",
      text = "INSERT",
      color = btn_f6,          
      width = btn_common_width,
      height = btn_common_height,
      midi_mapping = "MPE:Function:Add Sequence",
      pressed = function ()
      faddsq()
      end
      },
      -----------------
      vb:button {
      tooltip = "Remove the current pattern.",
      text = "REMOVE",
      color = btn_f6,          
      width = btn_common_width,
      height = btn_common_height,
      midi_mapping = "MPE:Function:Add Sequence",
      pressed = function ()
      fremsq()
      end
      },
      -----------------
      vb:button {
      tooltip = "Clone / Duplicate the current pattern.",
      text = "CLONE",
      color = btn_f6,          
      width = btn_common_width,
      height = btn_common_height,
      midi_mapping = "MPE:Function:Add Sequence",
      pressed = function ()
      fclonesq()
      end
      },
      -----------------      
        

},

--------------------------------------------------------------------------------
--transport
--------------------------------------------------------------------------------

----------------------------------
vb:horizontal_aligner {
mode = "center",  
----------------------------------
 

      -----------------
      vb:button {
      tooltip = "Move the playback position back (quarter beat).",
      text = "< STEP",
      color = btn_f1,
      width = btn_common_width,
      height = btn_common_height,
      midi_mapping = "MPE:Function:Move < 1 step",
      pressed = function ()
      fstepback()
      end
      },
      -----------------
      vb:button {
      tooltip = "Move the playback position forward (quarter beat).",
      text = "STEP >",
      color = btn_f1,
      width = btn_common_width,
      height = btn_common_height,
      midi_mapping = "MPE:Function:Move > 1 step",
      pressed = function () 
      fstepforward()
      end
      },
      ----------------- 
      vb:button {
      id = "loopblock",
      tooltip = "Loops a block of the current pattern.\n(Use with block-size)",
      text = "REPEAT",
      color = btn_f1,
      width = btn_common_width,
      height = btn_common_height,
      midi_mapping = "MPE:Song:LoopBlock",
      pressed = function()
      floopblock()
      end
      }, 
      -----------------   
      vb:button {
      tooltip = "Move the playback position back (1 bar).",
      text = "<< BAR",
      color = btn_f1,
      width = btn_common_width,
      height = btn_common_height,
      midi_mapping = "MPE:Function:Move < 1 bar",
      pressed = function ()
      fbarback()
      end
      },
      -----------------
      vb:button {
      tooltip = "Move the playback position forward (1 bar).",
      text = "BAR >>",
      color = btn_f1,
      width = btn_common_width,
      height = btn_common_height,
      midi_mapping = "MPE:Function:Move > 1 bar",
      pressed = function ()
      fbarforward()
      end
      },
      -----------------
                         

}, 
----------------------------------
vb:horizontal_aligner {
mode = "center",  
----------------------------------


      -----------------
      vb:button {
      id = "frecord",
      tooltip = "Begin (Record+Playback) from the start of the current pattern.",
      text = "Record",
      width = btn_common_width,
      height = btn_common_height*2,
      color = btn_t1,
      midi_mapping = "MPE:Transport:Record",
      pressed = function()
      frecord()
      end
      },
      -----------------          
      vb:button {
      id = "foverdub",
      tooltip = "Enable (Song Recording).",
      text = "OverDUB",
      width = btn_common_width,
      height = btn_common_height*2,
      color = btn_t1,
      midi_mapping = "MPE:Transport:OverDUB",
      pressed = function()
      foverdub()
      end
      },
      -----------------   
      vb:button {
      id = "fstopp",
      tooltip = "Stop the song playback and disable the (Song Recording).",
      text = "Stop",
      color = btn_t2,
      width = btn_common_width,
      height = btn_common_height*2,
      midi_mapping = "MPE:Transport:Stop",
      pressed = function()
      fstop()
      end
      },
      -----------------   
      vb:button {
      id = "fplay",
      tooltip = "Begin (Playback) from the current song position.",
      text = "Play",
      color = btn_t2,
      width = btn_common_width,
      height = btn_common_height*2,
      midi_mapping = "MPE:Transport:Play",
      pressed = function()
      fplay()
      end
      },    
      -----------------      
      vb:button {
      id = "fplaystart",
      tooltip = "Begin (Playback) from the start of the current pattern.",
      text = "PlaySTART",
      color = btn_t2,
      width = btn_common_width,
      height = btn_common_height*2,
      midi_mapping = "MPE:Transport:PlaySTART",
      pressed = function()
      fplaystart()
      end
      },
      -----------------

}, 
}, --group

----------------------------------
}, --interface
----------------------------------                  
} -- GUI dialog content
----------------------------------

----------------------------------------------------------------------
-- At tool launch
----------------------------------------------------------------------

--Create Effects track

feffecton()  

----------------------------------------------------------------------
-- key Handler
----------------------------------------------------------------------


local function my_keyhandler_func(dialog, key)
  if not (key.modifiers == "" and key.name == "_") then
  return key
  else
  dialog:close()end
end


  
--------------------------------------------------------------------------------
-- Initiate GUI Dialog
--------------------------------------------------------------------------------


my_dialog = renoise.app():show_custom_dialog("Musical Programming Environment", dialog_content,my_keyhandler_func)


-----------------------------------------------------------
-- function that runs with timer to update the GUI 
-----------------------------------------------------------

local function view_updater(my_dialog,beats_per_bar) 

-----------------------------------------------------------

  -- get user GUI values
  beats_per_bar = 4
  starting_pattern = nil
  
  -- get renoise values
  local rs = renoise.song()
  local lpb = renoise.song().transport.lpb
  local current_pos = renoise.song().transport.playback_pos_beats
  local current_sequence_pos = renoise.song().transport.playback_pos.sequence
  
  --adjust current pos when first pattern = upbeats
  if starting_pattern == true then
    --pattern 1 length   renoise.song().sequencer.pattern_sequence[1]
    local sequencer_index_1 = renoise.song().sequencer.pattern_sequence[1]
    local pattern_1_length = renoise.song().patterns[sequencer_index_1].number_of_lines
    --pattern 1 beats
    local pattern_1_beats = pattern_1_length/ lpb
    current_pos = current_pos - pattern_1_beats
  end
  
  --set values and calculate bars + beats
  local total_rounded_beats = math.floor(current_pos + 1)
  local bar = (total_rounded_beats / beats_per_bar) 
    bar = math.ceil(bar)
  local beat_in_bar = total_rounded_beats % beats_per_bar
  if beat_in_bar == 0 then
    beat_in_bar = beats_per_bar 
  end



--------------------------------------------------------------------------------
-- update GUI  
--------------------------------------------------------------------------------


--update now
vb.views["nowbar"].text = "0"..tostring(bar)..".0"..tostring(beat_in_bar).."."..tostring(total_rounded_beats)

--update transport playback button
if (renoise.song().transport.playing == true) then
vb.views.fplay.color = btn_on else 
vb.views.fplay.color = btn_t2
end

--update transport rec/overdub button
if (renoise.song().transport.edit_mode == true) then
vb.views.foverdub.color = btr_on else 
vb.views.foverdub.color = btn_t1 
end

--update BPM when it changes in song
vb.views.beatpm.value = renoise.song().transport.bpm

--update sequence name and number when it changes in song
vb.views.sq.value = renoise.song().selected_pattern_index
vb.views.sqname.value = renoise.song().selected_pattern.name

--update sample name and number when it changes in song
vb.views.pgmsample.max = #renoise.song().selected_instrument.samples
vb.views.pgmsample.value = renoise.song().selected_sample_index
vb.views.pgmsamplename.value = renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].name

-- update trackname and number when it changes in song
vb.views.track.max = #renoise.song().tracks
vb.views.track.value = renoise.song().selected_track_index
vb.views.trackname.value = renoise.song().tracks[renoise.song().selected_track_index].name

--update the (mute) field when changing track selection
if (renoise.song().selected_track.mute_state == 2 ) then
vb.views.mute_on.value = 2 else
vb.views.mute_on.value = 1
end

--update instrument (pgm) when it changes in song including deleted or added
vb.views.pgm.max = #renoise.song().instruments 
vb.views.pgm.value = renoise.song().selected_instrument_index          
vb.views.pgmname.value = renoise.song().selected_instrument.name
vb.views.pgmprog.max = #renoise.song().instruments --screen03
vb.views.pgmprog.value = renoise.song().selected_instrument_index           
vb.views.pgmnameprog.value = renoise.song().selected_instrument.name

--update sample when it changes in song including deleted or added
vb.views.pgmsample.value = renoise.song().selected_sample_index        
vb.views.pgmsamplename.value = renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].name

--update transpose sample
vb.views.smptran.value = renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].transpose

--update fine transpose sample
vb.views.finesmptran.value = renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].fine_tune

--update volume
vb.views.smprvol.value = renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].volume / 4

--update panning
vb.views.smppan.value = renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].panning

--update slice
--!!!bug this update deletes recorded track notes for selected instrument!!!
--if (renoise.song().selected_instrument.samples[1].sample_buffer.has_sample_data) then
--if (#renoise.song().selected_instrument.samples[1].slice_markers == 0 ) then
--vb.views.slice.value = 1 elseif 
--(#renoise.song().selected_instrument.samples[1].slice_markers == 4 ) then
--vb.views.slice.value = 2 elseif 
--(#renoise.song().selected_instrument.samples[1].slice_markers == 8 ) then
--vb.views.slice.value = 3 elseif 
--(#renoise.song().selected_instrument.samples[1].slice_markers == 16 ) then
--vb.views.slice.value = 4 elseif 
--(#renoise.song().selected_instrument.samples[1].slice_markers == 32 ) then
--vb.views.slice.value = 5 
--end
--end

--update fx preset max
if (renoise.song().tracks[1].name == "MPEFX" and renoise.song().selected_track_index == 1 and
  renoise.song().tracks[1].devices[renoise.song().selected_device_index].is_active == true) then
  vb.views.fxv1.max = #renoise.song().tracks[1].devices[renoise.song().selected_device_index].presets 
end

--update the count when the (metronome) changes in song
if (renoise.song().transport.metronome_enabled == false) then
vb.views.countm.value = 1 
else vb.views.countm.value = 2 
end

--update loop (repeat pattern) when it changes in song
if (renoise.song().transport.loop_pattern == false) then
vb.views.loop.value = 1 else 
vb.views.loop.value = 2
end  

--update block loop when it changes in song
if (renoise.song().transport.loop_block_enabled == false) then
vb.views.loopblock.color = btn_f1 else 
vb.views.loopblock.color = btn_on
end  
      
--update the sync button for the selected instrument
if (renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].beat_sync_enabled == true) then 
vb.views.ftransposesyncsample.color = btn_on else
vb.views.ftransposesyncsample.color = btn_f1
end

--update bar
--local lpb = renoise.song().transport.lpb
local nol = renoise.song().patterns[renoise.song().selected_pattern_index].number_of_lines
if (lpb == 4 and nol == 16 ) then
   vb.views.bars.value = 1 elseif
   (lpb == 4 and nol == 16 * 2 ) then
   vb.views.bars.value = 2 elseif
   (lpb == 4 and nol == 16 * 3 ) then
   vb.views.bars.value = 3 elseif
   (lpb == 4 and nol == 16 * 4 ) then
   vb.views.bars.value = 4 elseif
   (lpb == 4 and nol == 16 * 5 ) then  
   vb.views.bars.value = 5 elseif
   (lpb == 4 and nol == 16 * 6 ) then
   vb.views.bars.value = 6 elseif
   (lpb == 4 and nol == 16 * 7 ) then
   vb.views.bars.value = 7 elseif
   (lpb == 4 and nol == 16 * 8 ) then
   vb.views.bars.value = 8 elseif
   (lpb == 4 and nol == 16 * 9 ) then
   vb.views.bars.value = 9 elseif
   (lpb == 4 and nol == 16 * 10 ) then
   vb.views.bars.value = 10 elseif
   (lpb == 4 and nol == 16 * 11 ) then
   vb.views.bars.value = 11 elseif
   (lpb == 4 and nol == 16 * 12 ) then  
   vb.views.bars.value = 12 elseif
   (lpb == 4 and nol == 16 * 13 ) then
   vb.views.bars.value = 13 elseif
   (lpb == 4 and nol == 16 * 14 ) then
   vb.views.bars.value = 14 elseif
   (lpb == 4 and nol == 16 * 15 ) then
   vb.views.bars.value = 15 elseif
   (lpb == 4 and nol == 16 * 16 ) then
   vb.views.bars.value = 16 elseif 
   (lpb == 4 and nol == 16 * 17 ) then
   vb.views.bars.value = 17 elseif
   (lpb == 4 and nol == 16 * 18 ) then
   vb.views.bars.value = 18 elseif
   (lpb == 4 and nol == 16 * 19 ) then
   vb.views.bars.value = 19 elseif
   (lpb == 4 and nol == 16 * 20 ) then  
   vb.views.bars.value = 20 elseif
   (lpb == 4 and nol == 16 * 21 ) then
   vb.views.bars.value = 21 elseif
   (lpb == 4 and nol == 16 * 22 ) then
   vb.views.bars.value = 22 elseif
   (lpb == 4 and nol == 16 * 23 ) then
   vb.views.bars.value = 23 elseif
   (lpb == 4 and nol == 16 * 24 ) then
   vb.views.bars.value = 24 elseif
   (lpb == 4 and nol == 16 * 25 ) then
   vb.views.bars.value = 25 elseif
   (lpb == 4 and nol == 16 * 26 ) then
   vb.views.bars.value = 26 elseif
   (lpb == 4 and nol == 16 * 27 ) then  
   vb.views.bars.value = 27 elseif
   (lpb == 4 and nol == 16 * 28 ) then
   vb.views.bars.value = 28 elseif
   (lpb == 4 and nol == 16 * 29 ) then
   vb.views.bars.value = 29 elseif
   (lpb == 4 and nol == 16 * 30 ) then
   vb.views.bars.value = 30 elseif
   (lpb == 4 and nol == 16 * 31 ) then
   vb.views.bars.value = 31 elseif 
   (lpb == 4 and nol == 16 * 33 ) then
   vb.views.bars.value = 32 elseif 
   
   (lpb == 8 and nol == 32 ) then
   vb.views.bars.value = 1 elseif
   (lpb == 8 and nol == 32 * 2 ) then
   vb.views.bars.value = 2 elseif
   (lpb == 8 and nol == 32 * 3 ) then
   vb.views.bars.value = 3 elseif
   (lpb == 8 and nol == 32 * 4 ) then
   vb.views.bars.value = 4 elseif
   (lpb == 8 and nol == 32 * 5 ) then  
   vb.views.bars.value = 5 elseif
   (lpb == 8 and nol == 32 * 6 ) then
   vb.views.bars.value = 6 elseif
   (lpb == 8 and nol == 32 * 7 ) then
   vb.views.bars.value = 7 elseif
   (lpb == 8 and nol == 32 * 8 ) then
   vb.views.bars.value = 8 elseif
   (lpb == 8 and nol == 32 * 9 ) then
   vb.views.bars.value = 9 elseif
   (lpb == 8 and nol == 32 * 10 ) then
   vb.views.bars.value = 10 elseif
   (lpb == 8 and nol == 32 * 11 ) then
   vb.views.bars.value = 11 elseif
   (lpb == 8 and nol == 32 * 12 ) then  
   vb.views.bars.value = 12 elseif
   (lpb == 8 and nol == 32 * 13 ) then
   vb.views.bars.value = 13 elseif
   (lpb == 8 and nol == 32 * 14 ) then
   vb.views.bars.value = 14 elseif
   (lpb == 8 and nol == 32 * 15 ) then
   vb.views.bars.value = 15 elseif
   (lpb == 8 and nol == 32 * 16 ) then
   vb.views.bars.value = 16 elseif 

   (lpb == 16 and nol == 64 ) then
   vb.views.bars.value = 1 elseif
   (lpb == 16 and nol == 64 * 2 ) then
   vb.views.bars.value = 2 elseif
   (lpb == 16 and nol == 64 * 3 ) then
   vb.views.bars.value = 3 elseif
   (lpb == 16 and nol == 64 * 4 ) then
   vb.views.bars.value = 4 elseif
   (lpb == 16 and nol == 64 * 5 ) then  
   vb.views.bars.value = 5 elseif
   (lpb == 16 and nol == 64 * 6 ) then
   vb.views.bars.value = 6 elseif
   (lpb == 16 and nol == 64 * 7 ) then
   vb.views.bars.value = 7 elseif
   (lpb == 16 and nol == 64 * 8 ) then
   vb.views.bars.value = 8 elseif
   
   (lpb == 32 and nol == 128 ) then
   vb.views.bars.value = 1 elseif
   (lpb == 32 and nol == 128 * 2 ) then
   vb.views.bars.value = 2 elseif
   (lpb == 32 and nol == 128 * 3 ) then
   vb.views.bars.value = 3 elseif
   (lpb == 32 and nol == 128 * 4 ) then
   vb.views.bars.value = 4    
end

--update the sync valule
local synlns = renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].beat_sync_lines

if(renoise.song().transport.lpb == 4 ) then --1/4 timing
  if( synlns == 4 ) then --1beat
      vb.views.smpsyncval.value = 2 elseif
      synlns == 8 then --2beat
      vb.views.smpsyncval.value = 3 elseif
      synlns == 16 then --1bar
      vb.views.smpsyncval.value = 4 elseif
      synlns == 32 then --2bar
      vb.views.smpsyncval.value = 5 elseif
      synlns == 64 then --4bar
      vb.views.smpsyncval.value = 6 elseif
      synlns == 128 then --8bar
      vb.views.smpsyncval.value = 7 elseif
      synlns == 256 then --16bar
      vb.views.smpsyncval.value = 8 elseif
      synlns == 512 then --32bar
      vb.views.smpsyncval.value = 9
  end

elseif(renoise.song().transport.lpb == 8 ) then --1/8 timing
  if( synlns == 8 ) then --1beat
      vb.views.smpsyncval.value = 2 elseif
      synlns == 16 then --2beat
      vb.views.smpsyncval.value = 3 elseif
      synlns == 32 then --1bar
      vb.views.smpsyncval.value = 4 elseif
      synlns == 64 then --2bar
      vb.views.smpsyncval.value = 5 elseif
      synlns == 128 then --4bar
      vb.views.smpsyncval.value = 6 elseif
      synlns == 256 then --8bar
      vb.views.smpsyncval.value = 7 elseif
      synlns == 512 then --16bar
      vb.views.smpsyncval.value = 8
  end

elseif(renoise.song().transport.lpb == 16 ) then --1/16 timing
  if( synlns == 16 ) then --1beat
      vb.views.smpsyncval.value = 2 elseif
      synlns == 32 then --2beat
      vb.views.smpsyncval.value = 3 elseif
      synlns == 64 then --1bar
      vb.views.smpsyncval.value = 4 elseif
      synlns == 128 then --2bar
      vb.views.smpsyncval.value = 5 elseif
      synlns == 256 then --4bar
      vb.views.smpsyncval.value = 6 elseif
      synlns == 512 then --8bar
      vb.views.smpsyncval.value = 7 
  end

elseif(renoise.song().transport.lpb == 32 ) then --1/32 timing
  if( synlns == 32 ) then --1beat
      vb.views.smpsyncval.value = 2 elseif
      synlns == 64 then --2beat
      vb.views.smpsyncval.value = 3 elseif
      synlns == 128 then --1bar
      vb.views.smpsyncval.value = 4 elseif
      synlns == 256 then --2bar
      vb.views.smpsyncval.value = 5 elseif
      synlns == 512 then --4bar
      vb.views.smpsyncval.value = 6 
  end
  
end

--update the fxtype
if (renoise.song().tracks[renoise.song().selected_track_index].name == "MPEFX" and #renoise.song().tracks[renoise.song().selected_track_index].devices == 13) then
vb.views.fxv2.value = renoise.song().selected_device_index
end

--update the full level button for the selected instrument
if (renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].volume == 4 )then 
vb.views.flevel.color = btn_on else
vb.views.flevel.color = btn_f1
end

--update the timing button
if (renoise.song().transport.record_quantize_enabled == true) then    
vb.views.timingonoff.color = btn_on else 
vb.views.timingonoff.color = btn_f4
end

--update the timing quantize
if (renoise.song().transport.record_quantize_enabled == true) then    
vb.views.qtime.value = renoise.song().transport.record_quantize_lines
end

--update the instrument loop mode
if (renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].loop_mode == 1 ) then
vb.views.sampleloopmode.value = 1 elseif
renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].loop_mode == 2  then
vb.views.sampleloopmode.value = 2 elseif
renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].loop_mode == 3  then
vb.views.sampleloopmode.value = 3 elseif
renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].loop_mode == 3  then
vb.views.sampleloopmode.value = 4
end

--update the delay button
--if (not renoise.song().tracks[renoise.song().selected_track_index].name == "MPEFX" and #renoise.song().tracks[1].devices < 13 and 

if (renoise.song().tracks[1].devices[2].is_active == false ) then
vb.views.fxdelay.color = btn_f1
elseif (renoise.song().tracks[renoise.song().selected_track_index].name > "MPEFX" ) then
vb.views.fxdelay.color = btn_f1
end

--update the loop button
if (renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].loop_mode == 2 ) then
vb.views.fpgmloopfw.color = btn_on else 
vb.views.fpgmloopfw.color = btn_f1
end

--update the hold button
if (renoise.song().selected_instrument.sample_envelopes.volume.fade_amount == 0 and 
renoise.song().selected_instrument.sample_envelopes.volume.enabled == true ) then
vb.views.fhold.color = btn_on else 
vb.views.fhold.color = btn_f1
end

--update the chord mode button
if (renoise.song().transport.chord_mode_enabled == true ) then
vb.views.fchord.color = btn_on else 
vb.views.fchord.color = btn_f1
end

--update the fnna cut button
if (renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].new_note_action == 1 ) then
vb.views.fcutnotesample.color = btn_on else 
vb.views.fcutnotesample.color = btn_f1
end
  
--update the sample overlap note action mode
if (renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].new_note_action == 1 ) then    
vb.views.noteaction.value = 1 elseif
renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].new_note_action == 2 then
vb.views.noteaction.value = 2 elseif
renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].new_note_action == 3 then
vb.views.noteaction.value = 3 
end

--update sample selection maximum range
if (renoise.song().selected_sample.sample_buffer.has_sample_data == true) then
vb.views.smpend.max = renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].sample_buffer.number_of_frames
vb.views.smpstart.max = renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].sample_buffer.number_of_frames
end

--update sample loop maximum range
if (renoise.song().selected_sample.sample_buffer.has_sample_data == true) then
vb.views.smpendloop.max = renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].sample_buffer.number_of_frames
--
vb.views.smpstartloop.max = renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].sample_buffer.number_of_frames
end

--snap calculator      
if (renoise.song().selected_sample.sample_buffer.has_sample_data) then  
local seconds_per_beat = 60 / renoise.song().transport.bpm
local beats_in_sample = renoise.song().selected_sample.beat_sync_lines / lpb
local frames_in_sample = renoise.song().selected_sample.sample_buffer.number_of_frames

--snap and deal with sync    
if (renoise.song().selected_sample.beat_sync_enabled) then     
samples_per_beat = frames_in_sample / beats_in_sample else
samples_per_beat = renoise.song().selected_sample.sample_buffer.sample_rate * seconds_per_beat
end      
end

----------------------------------------------------------------------
end --local function view_updater 
----------------------------------------------------------------------

--add timer
if not renoise.tool():has_timer(view_updater) then
  renoise.tool():add_timer(view_updater ,5)
end


----------------------------------------------------------------------
-- close on document(song) and release timer
----------------------------------------------------------------------

local function closer(d)    
  if d and d.visible then
  d:close()end
  if renoise.tool():has_timer(view_updater) then
  renoise.tool():remove_timer(view_updater)
  end  
end
--add notifier on document(song) release 
if not renoise.tool().app_release_document_observable:has_notifier(closer) then 
  renoise.tool().app_release_document_observable:add_notifier(closer, my_dialog)
end

----------------------------------------------------------------------
-- release updater function
----------------------------------------------------------------------

local function release_updater(d)
  if not d.visible then
  if renoise.tool():has_timer(view_updater) then
  renoise.tool():remove_timer(view_updater) 
  end        
  if renoise.tool():has_timer(release_updater) then
  renoise.tool():remove_timer(release_updater)
  print(renoise.tool():has_timer(release_updater)) 
  end
  end
end

--add second timer (slower) to release updater when dialog closes (tested and works)  
if not renoise.tool():has_timer(release_updater) then
  renoise.tool():add_timer(function () release_updater(my_dialog) end ,200) 
end

--focus pattern editor
renoise.app().window.lock_keyboard_focus = false
renoise.app().window.lock_keyboard_focus = true


--------------------------------------------------------------------------------
-- Midi Binding
--------------------------------------------------------------------------------


if not renoise.tool():has_midi_mapping("MPE:Function:Step Editing")then
    
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Display:Hide & Show Display",
invoke = function(message)
  if (message:is_trigger()) then  
  hidehalf()
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Display:Hide & Show Tool",
invoke = function(message)
  if (message:is_trigger()) then  
  hidehall()
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Display:BPM", 
invoke = function(message)
  if (message.int_value < 32 )then handle_error = true else
  vb.views.beatpm.value = math.floor(message.int_value*1.2)
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Display:Count", 
invoke = function(message)
  if (message:is_trigger()) then 
  renoise.song().transport.metronome_enabled = not renoise.song().transport.metronome_enabled
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Display:Loop", 
invoke = function(message)
  if (message:is_trigger()) then 
  renoise.song().transport.loop_pattern = not renoise.song().transport.loop_pattern
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Song:LoopBlock", 
invoke = function(message)
  if (message:is_trigger()) then
  floopblock()
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Song:LoopBlock Size", 
invoke = function(message)
  if (math.floor(message.int_value) *0.14 > 16 or math.floor(message.int_value) *0.14 < 2 )then handle_error = true else
  vb.views.sngblk.value = math.floor(message.int_value)*0.14
  end
  end  
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Sample:LoopMode", 
invoke = function(message)
  if (math.floor(message.int_value) /31.75 > 4 
  or math.floor(message.int_value) /31.75 < 1 )then handle_error = true else
  vb.views.sampleloopmode.value = math.floor(message.int_value)/31.75
  end
  end  
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Song:Timing", 
invoke = function(message)
  if (math.floor(message.int_value) /31.75 > 4 
  or math.floor(message.int_value) /31.75 < 1 )then handle_error = true else
  vb.views.timing.value = math.floor(message.int_value)/31.75
  end
  end  
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Display:voice NNA", 
invoke = function(message)
  if (math.floor(message.int_value)/42.333333333333333 < 1 )then handle_error = true else
  vb.views.noteaction.value = math.floor(message.int_value)/42.333333333333333
  end
  end  
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Sample:Filter Type",
invoke = function(message)
  local m = math.floor(message.int_value) /6.5 
  if (m > 20 or m < 1 )then handle_error = true else
  vb.views.fcontrolvartype1.value = m
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Undo",
invoke = function(message)
  if (message:is_trigger()) then  
  fundo()
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Loop Sample Forward",
invoke = function(message)
  if (message:is_trigger()) then  
  floopforwardsample()
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Loop Sample Forward Instrument",
invoke = function(message)
  if (message:is_trigger()) then  
  floopforwardpgm()
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Loop Sample Back",
invoke = function(message)
  if (message:is_trigger()) then  
  fpgmloobk()
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Loop Sample PingPong",
invoke = function(message)
  if (message:is_trigger()) then  
  fpgmlooppg()
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Beatsync Transpose Instrument",
invoke = function(message)
  if (message:is_trigger()) then      
  ftransposesyncpgm()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Beatsync Transpose",
invoke = function(message)
  if (message:is_trigger()) then      
  ftransposesyncsample()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Clear Markers",
invoke = function(message)
  if (message:is_trigger()) then      
  dsliceclear()
  vb.views.slice.value = 1     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Slice Marker",
invoke = function(message)
  if (message:is_trigger()) then      
  fpgmslicemarker()     
  end
  end
}
---------------------------------------------------      
renoise.tool():add_midi_mapping{
name = "MPE:Sample:Transpose",
invoke = function(message)  
  if (message.int_value >= 61 or message.int_value <= -61 )then handle_error = true else
  vb.views.smptran.value = math.floor(message.int_value * 2 )
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Sample:Transpose Inst",
invoke = function(message)
  if (message.int_value >= 61 or message.int_value <= -61 )then handle_error = true else
  vb.views.insttran.value = math.floor(message.int_value * 0.2)
  end
  end
} 
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Sample:Attack",
invoke = function(message)
  vb.views.fcontrolattack.value = message.int_value / 127
  end
} 
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Sample:Decay",
invoke = function(message)
  vb.views.fcontroldecay1.value = message.int_value * 32
  end
} 
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Sample:Cutoff Freq",
invoke = function(message)
  vb.views.fcontrolfreq1.value = message.int_value /127
  end
} 
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Sample:Resonance",
invoke = function(message)
  vb.views.fcontrolreso1.value = message.int_value /182
  end
} 
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Sample:Select Start",
invoke = function(message)
if (renoise.song().selected_sample.sample_buffer.has_sample_data == true) then
  
  if (message.int_value >= 128 or message.int_value == 0 )then handle_error = true else
  renoise.app().window.active_middle_frame = 4
  vb.views.smpstart.value = 1
  --set the views value from midi
  vb.views.smpstart.value =
  math.floor(renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].
  sample_buffer.number_of_frames  
  * message.int_value /  127)
  end -- if
  
end -- if
end --function
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Sample:Select End",
invoke = function(message)
if (renoise.song().selected_sample.sample_buffer.has_sample_data == true) then
  
  local start = math.floor(127 /
  renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].sample_buffer.number_of_frames * 
  renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].sample_buffer.selection_start)    
  
  if (message.int_value <= start )then handle_error = true else
  renoise.app().window.active_middle_frame = 4 
  --end minimum
  vb.views.smpend.min = renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].
  sample_buffer.selection_start
  --end maximum
  vb.views.smpend.max = renoise.song().selected_instrument.
  samples[renoise.song().selected_sample_index].sample_buffer.number_of_frames
  --set the views value from midi
  vb.views.smpend.value = 
  math.floor(renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].
  sample_buffer.number_of_frames  
  * message.int_value / 127)
  end -- if
  
end -- if
end --function
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Sample:Loop Start",
invoke = function(message)
if (renoise.song().selected_sample.sample_buffer.has_sample_data == true) then

  if (message.int_value >= 128 or message.int_value == 0 )then handle_error = true else  
  renoise.app().window.active_middle_frame = 4
  --start minimum
  vb.views.smpstartloop.min = 1
  --start maximum
  vb.views.smpstartloop.max = renoise.song().selected_instrument.
  samples[renoise.song().selected_sample_index].sample_buffer.number_of_frames
  --set the views value from midi
  vb.views.smpstartloop.value = 
  renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].sample_buffer.number_of_frames 
  * math.floor(message.int_value) / 127  
  end -- if
  
end -- if
end --function
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Sample:Loop End",
invoke = function(message)
if (renoise.song().selected_sample.sample_buffer.has_sample_data == true) then

  local start = math.floor(127 /
  renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].sample_buffer.number_of_frames * 
  renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].loop_start)
  
  if (message.int_value <= start )then handle_error = true else
  renoise.app().window.active_middle_frame = 4
  --end minimum
  vb.views.smpendloop.min = renoise.song().selected_instrument.samples[renoise.song().
  selected_sample_index].loop_start
  --end maximum
  vb.views.smpendloop.max = renoise.song().selected_instrument.
  samples[renoise.song().selected_sample_index].sample_buffer.number_of_frames
  --set the views value from midi
  vb.views.smpendloop.value =
  renoise.song().selected_instrument.samples[renoise.song().selected_sample_index].sample_buffer.number_of_frames 
  * math.floor(message.int_value) / 127  
  end -- if
  
end -- if
end --function
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Sample:Volume",
invoke = function(message)
  if (message.int_value >= 61 )then handle_error = true else
  vb.views.smprvol.value = message.int_value / 60
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Sample:Volume Inst",
invoke = function(message)
  if (message.int_value >= 61 )then handle_error = true else
  vb.views.instrvol.value = message.int_value / 60
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Sample:Pan",
invoke = function(message)
  if (message.int_value >= 49 or message.int_value <= 0 )then handle_error = true else
  vb.views.smppan.value = math.floor(message.int_value)/50
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Sample:Pan Inst",
invoke = function(message)
  if (message.int_value >= 49 or message.int_value <= 0 )then handle_error = true else
  vb.views.instrpan.value = math.floor(message.int_value)/50
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Loop Sample",
invoke = function(message)
  if (message:is_trigger()) then      
  fpgmloop()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Chord",
invoke = function(message)
  if (message:is_trigger()) then      
  fchord()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Select the Previous Instrument",
invoke = function(message)
  if (message:is_trigger()) then      
  fpgmback()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Select the Next Instrument",
invoke = function(message)
  if (message:is_trigger()) then      
  fpgmforward()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Step Editing",
invoke = function(message)
  if (message:is_trigger()) then      
  fstep()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Edit Functions",
invoke = function(message)
  if (message:is_trigger()) then      
  fedit()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Mute Track",
invoke = function(message)
  if (message:is_trigger()) then      
  fmute()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Solo Track",
invoke = function(message)
  if (message:is_trigger()) then      
  fsolo()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Select the Previous Track",
invoke = function(message)
  if (message:is_trigger()) then      
  ftrackback()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Select Next Track",  
invoke = function(message)
  if (message:is_trigger()) then      
  ftrackforward()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Hold",  
invoke = function(message)
  if (message:is_trigger()) then      
  fhold()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Cut",  
invoke = function(message)
  if (message:is_trigger()) then      
  fcutnotesample()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Cut Instrument",  
invoke = function(message)
  if (message:is_trigger()) then      
  fcutnotepgm()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Plugin Previous Preset",  
invoke = function(message)
  if (message:is_trigger()) then      
  fplugpreviouspreset()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Plugin Next Preset",  
invoke = function(message)
  if (message:is_trigger()) then      
  fplugnextpreset()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Delay",  
invoke = function(message)
  if (message:is_trigger()) then      
  fxdelay()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Sample Reset",  
invoke = function(message)
  if (message:is_trigger()) then      
  freset()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Snap",  
invoke = function(message)
  if (message:is_trigger()) then      
  fsnap()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Effect to Track",  
invoke = function(message)
  if (message:is_trigger()) then      
  ffxsave()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Load",
invoke = function(message)
  if (message:is_trigger()) then      
  fload()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Sample",
invoke = function(message)
  if (message:is_trigger()) then      
  fsample()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Trim",
invoke = function(message)
  if (message:is_trigger()) then      
  ftrim()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Mixer",
invoke = function(message)
  if (message:is_trigger()) then      
  fmixer()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Tap Tempo",
invoke = function(message)
  if (message:is_trigger()) then      
  tap()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Full Level",
invoke = function(message)
  if (message:is_trigger()) then      
  flevel()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Song",
invoke = function(message)
  if (message:is_trigger()) then      
  fsong()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Program",
invoke = function(message)
  if (message:is_trigger()) then      
  fprog()     
  end
  end
}

renoise.tool():add_midi_mapping{
name = "MPE:Function:Save Song",
invoke = function(message)
  if (message:is_trigger()) then      
  fsave()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Instant Sample",
invoke = function(message)
  if (message:is_trigger()) then      
  fisample()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Erase",
invoke = function(message)
  if (message:is_trigger()) then      
  ferase()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Move < 1 step",
invoke = function(message)
  if (message:is_trigger()) then      
  fstepback()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Move > 1 step",
invoke = function(message)
  if (message:is_trigger()) then      
  fstepforward()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Move < 1 bar",
invoke = function(message)
  if (message:is_trigger()) then      
  fbarback()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Move > 1 bar",
invoke = function(message)
  if (message:is_trigger()) then      
  fbarforward()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Previous Sequence",
invoke = function(message)
  if (message:is_trigger()) then      
  fprevsq()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Add Sequence",
invoke = function(message)
  if (message:is_trigger()) then      
  faddsq()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Next Sequence",
invoke = function(message)
  if (message:is_trigger()) then      
  fnextsq()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Transport:Record",
invoke = function(message)
  if (message:is_trigger()) then      
  frecord()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Transport:OverDUB",
invoke = function(message)
  if (message:is_trigger()) then      
  foverdub()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Transport:Stop",
invoke = function(message)
  if (message:is_trigger()) then      
  fstop()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Transport:Play",
invoke = function(message)
  if (message:is_trigger()) then      
  fplay()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Transport:PlaySTART",
invoke = function(message)
  if (message:is_trigger()) then      
  fplaystart()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Sample:Effect Type",
invoke = function(message) 
  --check the effect track exists with all devices
  ------------------------------------------------
  if (renoise.song().tracks[renoise.song().selected_track_index].name == "MPEFX" ) then
    if (math.ceil(message.int_value/10) < 1 )then handle_error = true else
    vb.views.fxv2.value = math.ceil(message.int_value/10)  
    vb.views.fxv1.max = #renoise.song().tracks[1].devices[renoise.song().selected_device_index].presets 
    end
  else ffxdevice()  
  end     
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Sample:Effect Preset",
invoke = function(message) 
  --check the effect track exists with all devices
  ------------------------------------------------
  if (renoise.song().tracks[renoise.song().selected_track_index].name == "MPEFX" ) then
    local fxpreset = 
    #renoise.song().tracks[1].devices[renoise.song().selected_device_index].presets / 127
    if (math.ceil(message.int_value * fxpreset) <= 1 ) then handle_error = true 
    else
    vb.views.fxv1.value = math.ceil(message.int_value)*fxpreset
    end      
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Sample:Effect Amount",
invoke = function(message)
    --check the effect track exists with all devices
  ------------------------------------------------
  if (renoise.song().tracks[renoise.song().selected_track_index].name == "MPEFX" ) then
    if (
    renoise.song().selected_device_index == 2 ) then --Multitap
    vb.views.fcontrolfx2.value =  math.ceil(message.int_value) *
    renoise.song().tracks[1].devices[2].parameters[6].value_max / 127
    elseif
    renoise.song().selected_device_index == 3  then --Delay
    vb.views.fcontrolfx2.value =  math.ceil(message.int_value) *
    renoise.song().tracks[1].devices[3].parameters[5].value_max / 127
    elseif
    renoise.song().selected_device_index == 4  then --Flanger
    vb.views.fcontrolfx2.value =  math.ceil(message.int_value) *
    renoise.song().tracks[1].devices[4].parameters[8].value_max / 127
    elseif
    renoise.song().selected_device_index == 5  then --Phaser
    vb.views.fcontrolfx2.value =  math.ceil(message.int_value) *
    renoise.song().tracks[1].devices[5].parameters[4].value_max / 127   
    elseif
    renoise.song().selected_device_index == 6  then --mpReverb
    vb.views.fcontrolfx2.value =  math.ceil(message.int_value) *
    renoise.song().tracks[1].devices[6].parameters[8].value_max / 127
    elseif
    renoise.song().selected_device_index == 7  then --LofiMat
    vb.views.fcontrolfx2.value =  math.ceil(message.int_value) *
    renoise.song().tracks[1].devices[7].parameters[2].value_max / 127
    elseif
    renoise.song().selected_device_index == 8  then --Gate
    vb.views.fcontrolfx2.value =  math.ceil(message.int_value)*
    renoise.song().tracks[1].devices[8].parameters[1].value_min / 127
    elseif
    renoise.song().selected_device_index == 9  then --RingMod
    vb.views.fcontrolfx2.value =  math.ceil(message.int_value) *
    renoise.song().tracks[1].devices[9].parameters[3].value_max / 127
    elseif
    renoise.song().selected_device_index == 10  then --Scream
    vb.views.fcontrolfx2.value =  math.ceil(message.int_value) *
    renoise.song().tracks[1].devices[10].parameters[2].value_max / 127
    elseif
    renoise.song().selected_device_index == 11  then --Filter
    vb.views.fcontrolfx2.value =  math.ceil(message.int_value) *
    renoise.song().tracks[1].devices[11].parameters[2].value_max / 127
    elseif
    renoise.song().selected_device_index == 12  then --Comb Filter
    vb.views.fcontrolfx2.value =  math.ceil(message.int_value) *
    renoise.song().tracks[1].devices[12].parameters[2].value_max / 127
    end    
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Sample:Syncval",
invoke = function(message)   
    if (math.floor(message.int_value) /14.111111111111111 > 9 
    or math.floor(message.int_value) /14.111111111111111 < 1 )then handle_error = true else
    vb.views.smpsyncval.value = math.floor(message.int_value)/14.111111111111111
    end
  end  
}   
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Sample Snap select",
invoke = function(message)
  if (message:is_trigger()) then      
  fsnapselect()     
  end
  end
}
---------------------------------------------------  
renoise.tool():add_midi_mapping{
name = "MPE:Function:Sample Snap loop",
invoke = function(message)
  if (message:is_trigger()) then      
  fsnaploop()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Function:Sample Reset Vol",
invoke = function(message)
  if (message:is_trigger()) then      
  fresetvolume()     
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Sample:Finetune Transpose",
invoke = function(message)
  if (message.int_value >= 61 or message.int_value <= -61 )then handle_error = true else
  vb.views.finesmptran.value = math.floor(message.int_value * 2 )
  end
  end
}
---------------------------------------------------
renoise.tool():add_midi_mapping{
name = "MPE:Sample:Finetune Transpose Inst",
invoke = function(message)
  if (message.int_value >= 61 or message.int_value <= -61 )then handle_error = true else
  vb.views.fineinsttran.value = math.floor(message.int_value * 2 )
  end
  end
}
---------------------------------------------------

else handle_error = true
end

--------------------------------------------------------------------------------
end -- Main
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Menu Integration
--------------------------------------------------------------------------------

renoise.tool():add_keybinding {
  name = "Global:Tools:MPE",
  invoke = function()
  main() 
  end 
}

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:MPE",
  invoke = function()
  local my_dialog = nil
  main()
  end
}
