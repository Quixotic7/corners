-- corners 
-- a norns port of tehn's m4l script
-- use the grid to add gravity wells
-- velocities, positions, and border crossings 
-- are mapped to sound parameters and events. 
-- @quixotic7 - Michael P Jones
-- v1.1.4
MollyThePoly = require "molly_the_poly/lib/molly_the_poly_engine"
musicutil = require 'musicutil'

engine.name = "MollyThePoly"

Corners_Lib = include('lib/corners')
Corners_Screen = include('lib/corners_screen')
Corners_Params = include('lib/corners_params')
Screen_Overlays = include('lib/screen_overlays')
Engine_Bangs = include('lib/engine_bangs')
Q7Util = include('lib/Q7Util')
Vector2d = include('lib/vector2d')
tabutil = include('lib/tabutil')
Grid_Events_Handler = include('lib/grid_events')

corners = Corners_Lib.new()
bangs = Engine_Bangs.new()
screen_overlays = Screen_Overlays.new()
corners_screen = nil

local g = grid.connect()
local midi_devices = {}
local grid_events = Grid_Events_Handler.new()

local prevKeys = 0
local defaultVel = 100

local prev = {}
prev.x = 0
prev.y = 0
prev.dx = 0
prev.dy = 0

local b_notes = {}
local key_notes = {}

local b_rand_scale = {}

local shift_down = false

function init()
    
    for i = 1, 4 do
        midi_devices[i] = midi.connect(i)
    end
    
    corners:bounds(g.cols, g.rows)
    
    corners_screen = Corners_Screen.new(corners, 0, 0, 128, 64, g.cols, g.rows)
    
    Corners_Params.add_params()
    -- prevent stuck notes when changing settings
    params:set_action("bSound", function() b_off_all() end)
    params:set_action("keySound", function() key_off_all() end)
    params:set_action("b_deviceId", function() b_off_all() end)
    params:set_action("b_midiChannel", function() b_off_all() end)
    params:set_action("key_deviceId", function() key_off_all() end)
    params:set_action("key_midiChannel", function() key_off_all() end)
    
    params:set_action("rootNote", function(value) 
        gen_b_scale() 
        screen_overlays:show_overlay(musicutil.NOTE_NAMES[value], "rootNote") 
    end)
    params:set_action("scaleMode", function(value) 
        gen_b_scale() 
        screen_overlays:show_overlay(SCALE_NAMES[value], "scale") 
    end)
    params:set_action("b_octave", function(value) 
        gen_b_scale() 
        screen_overlays:show_overlay(value, "b octave") 
        
    end)
    params:set_action("b_octRange", function(value) 
        gen_b_scale() 
        screen_overlays:show_overlay(value, "b octave range") 
    end)
    
    params:set_action("cc_value_x", function() send_cc("x") end)
    params:set_action("cc_value_y", function() send_cc("y") end)
    params:set_action("cc_value_dx", function() send_cc("dx") end)
    params:set_action("cc_value_dy", function() send_cc("dy") end)
    
    params:set_action("friction", function(value) 
        screen_overlays:show_overlay(value, "friction") 
    end)
    
    params:set_action("gravity", function(value) 
        screen_overlays:show_overlay(value, "gravity") 
    end)
    
    MollyThePoly.add_params()
    MollyThePoly.randomize_params("lead")
    
    grid_events.grid_event = function (e) grid_event(e) end
    
    bangs.note_on = b_note_on
    bangs.note_off = b_note_off
    
    corners.bRight = function() bang_note(params:get("bRight")) end
    corners.bLeft = function() bang_note(params:get("bLeft")) end
    corners.bUp = function() bang_note(params:get("bUp")) end
    corners.bDown = function() bang_note(params:get("bDown")) end
    
    -- set some default param mappings for fun and profit
    params:set("cc_enabled_x", 2)
    params:set("cc_intern_x", 24)
    params:set("cc_enabled_y", 2)
    params:set("cc_intern_y", 14)
    params:set("cc_enabled_dx", 2)
    params:set("cc_intern_dx", 4)
    
    gen_b_scale()
    
    clock.run(physics_update_clock) 
    clock.run(screen_redraw_clock) 
    clock.run(grid_redraw_clock) -- grid drawing happens in physics_update_clock, synced to clock

    screen_overlays:show_overlay("")

end

function key(n, v)
    -- corners:key(n, v)
    
    if n == 1 then
        shift_down = v == 1
    end
    
    if shift_down then
        if n == 2 and v == 1 then
            MollyThePoly.randomize_params("pad")
            screen_overlays:show_overlay("random pad")
        elseif n == 3 and v == 1 then
            MollyThePoly.randomize_params("perc")
            screen_overlays:show_overlay("random perc")
        end
    else
        if n == 2 and v == 1 then
            MollyThePoly.randomize_params("lead")
            screen_overlays:show_overlay("random lead")
        elseif n == 3 and v == 1 then
            Corners_Params.generate_notes()
            screen_overlays:show_overlay("randomize notes")
        end
    end
end

function enc(n, v)
    if shift_down then
        if n == 1 then params:delta("rootNote", v) end
        if n == 2 then params:delta("b_octave", v) end
        if n == 3 then params:delta("b_octRange", v) end
    else
        if n == 1 then params:delta("scaleMode", v) end
        if n == 2 then params:delta("friction", v) end
        if n == 3 then params:delta("gravity", v) end
    end
end

function redraw()
    screen.clear()
    screen.aa(0)
    
    corners_screen:draw()
    screen_overlays:draw()
    
    screen.update()
end

g.key = function(x, y, z)
    corners:grid_key(x, y, z)
    
    grid_events:key(x,y,z)
end

function grid_event(e)
    if e.x == g.cols and e.y > 1 and e.y < g.rows and e.type == "double_click" then
        corners:toggle_ref(1, e.x, e.y)
    end
    
    if e.x == 1 and e.y > 1 and e.y < g.rows and e.type == "double_click" then
        corners:toggle_ref(3, e.x, e.y)
    end
    
    if e.y == 1 and e.x > 1 and e.x < g.cols and e.type == "double_click" then
        corners:toggle_ref(2, e.x, e.y)
    end
    
    if e.y == g.rows and e.x > 1 and e.x < g.cols and e.type == "double_click" then
        corners:toggle_ref(4, e.x, e.y)
    end
end

function screen_redraw_clock()
    while true do -- while it's running...
        redraw()
        clock.sleep(1/15) -- refresh rate
    end
end

function grid_redraw_clock() -- our grid redraw clock
    while true do -- while it's running...
        physics_update()
        grid_redraw()
        clock.sleep(1/20) -- refresh rate
    end
end

function physics_update_clock()
    while true do -- while it's running...
        local sync_rate = SYNC_RATE_VALUES[params:get("physicsRate")]
        clock.sync(sync_rate)
        physics_update()
        -- if corners.grid_dirty then
        --     grid_redraw() -- may be problem for midi grids if sync_rate is too high
        -- end
    end
end

function physics_update()
    corners:fric(params:get("friction"))
    corners:grr(params:get("gravity"))
    corners:bang()
    
    -- play notes while holding keys
    if corners.keys ~= prevKeys then
        if corners.keys == 0 then
            local noteNumber = params:get(KEY_PARAMS[prevKeys])
            key_note_off(noteNumber)
            prevKeys = corners.keys
        else
            if corners.keys <= #KEY_PARAMS then
                if prevKeys ~= 0 then
                    local prevNoteNumber = params:get(KEY_PARAMS[prevKeys])
                    key_note_off(prevNoteNumber)
                end
                local noteNumber = params:get(KEY_PARAMS[corners.keys])
                key_note_on(noteNumber)
                prevKeys = corners.keys
            end
        end
    end
    
    if corners.x ~= prev.x then
        local val = util.round(util.linlin(0, g.cols, 0, 127, corners.x))
        params:set("cc_value_x", val)
        prev.x = corners.x
    end
    if corners.y ~= prev.y then
        local val = util.round(util.linlin(0, g.rows, 0, 127, corners.y))
        params:set("cc_value_y", val)
        prev.y = corners.y
    end
    
    local gRatio = g.cols / g.rows
    
    if corners.dx ~= prev.dx then
        local val = util.round(util.linlin(-2.0 * gRatio, 2.0 * gRatio, 0, 127, corners.dx))
        params:set("cc_value_dx", val)
        -- print("dx "..val)
        prev.dx = corners.dx
    end
    
    if corners.dy ~= prev.dy then
        local val = util.round(util.linlin(-2.0, 2.0, 0, 127, -corners.dy))
        params:set("cc_value_dy", val)
        -- print("dy "..val)
        prev.dy = corners.dy
    end
end

function grid_redraw()
    g:all(0)
    
    corners:grid_redraw(g)
    
    g:refresh()
end

function gen_b_scale()
    local b_root = params:get("rootNote") + (12 * (params:get("b_octave") - 1))
    b_rand_scale = musicutil.generate_scale(b_root, params:get("scaleMode"), params:get("b_octRange"))
end

function bang_note(noteNumber)
    local velMin, velMax = Q7Util.get_min_max(params:get("b_velMin"), params:get("b_velMax"))
    local vel = util.round(util.linlin(0,1, velMin, velMax, math.random()))
    
    local lengthMin, lengthMax = Q7Util.get_min_max(params:get("b_noteLengthMin"), params:get("b_noteLengthMax"))
    local length = util.linlin(0,1, lengthMin, lengthMax, math.random())
    
    if params:get("b_randomNotes") == 2 then
        noteNumber = b_rand_scale[math.random(1, #b_rand_scale)]
    end
    
    bangs:bang(noteNumber, vel, length)
end

function b_off_all()
    for key, n in pairs(b_notes) do
        note_off(n.intern, n.midi, n.note, n.vel, n.d, n.chan)
    end
    
    b_notes = {}
end

function key_off_all()
    for key, n in pairs(key_notes) do
        note_off(n.intern, n.midi, n.note, n.vel, n.d, n.chan)
    end
    
    key_notes = {}
end

function b_note_on(noteNumber, vel)
    -- print("NoteOn "..noteNumber)
    local soundDest = SOUND_OPTIONS[params:get("bSound")]
    
    local sendIntern = ((soundDest == "internal") or (soundDest == "intern + midi"))
    local sendMidi = ((soundDest == "midi") or (soundDest == "intern + midi"))
    
    local deviceId = params:get("b_deviceId")
    local channel = params:get("b_midiChannel")
    note_on(sendIntern, sendMidi, noteNumber, vel, deviceId, channel)
    
    b_notes[noteNumber] = {intern = sendIntern, midi = sendMidi, note = noteNumber, v = vel, d = deviceId, chan = channel}
end

function b_note_off(noteNumber)
    -- print("NoteOff")
    local soundDest = SOUND_OPTIONS[params:get("bSound")]
    
    local sendIntern = ((soundDest == "internal") or (soundDest == "intern + midi"))
    local sendMidi = ((soundDest == "midi") or (soundDest == "intern + midi"))
    
    local deviceId = params:get("b_deviceId")
    local channel = params:get("b_midiChannel")
    
    note_off(sendIntern, sendMidi, noteNumber, defaultVel, deviceId, channel)
    
    b_notes[noteNumber] = nil
end

function key_note_on(noteNumber)
    local soundDest = SOUND_OPTIONS[params:get("keySound")]
    
    local sendIntern = ((soundDest == "internal") or (soundDest == "intern + midi"))
    local sendMidi = ((soundDest == "midi") or (soundDest == "intern + midi"))
    
    local deviceId = params:get("key_deviceId")
    local channel = params:get("key_midiChannel")
    local vel = params:get("key_vel")
    note_on(sendIntern, sendMidi, noteNumber, vel, deviceId, channel)
    key_notes[noteNumber] = {intern = sendIntern, midi = sendMidi, note = noteNumber, v = vel, d = deviceId, chan = channel}
end

function key_note_off(noteNumber)
    local soundDest = SOUND_OPTIONS[params:get("keySound")]
    
    local sendIntern = ((soundDest == "internal") or (soundDest == "intern + midi"))
    local sendMidi = ((soundDest == "midi") or (soundDest == "intern + midi"))
    
    local deviceId = params:get("key_deviceId")
    local channel = params:get("key_midiChannel")
    local vel = params:get("key_vel")
    
    note_off(sendIntern, sendMidi, noteNumber, vel, deviceId, channel)
    
    key_notes[noteNumber] = nil
end

function note_on(sendIntern, sendMidi, noteNumber, vel, deviceId, channel)
    -- sendIntern = sendIntern or true
    -- sendMidi = sendMidi or false
    -- noteNumber = noteNumber or 60
    -- vel = vel or defaultVel
    -- deviceId = deviceId or 1
    -- channel = channel or 1
    
    if sendIntern then
        engine.noteOn(noteNumber, musicutil.note_num_to_freq(noteNumber), vel / 127.0)
    end
    
    if sendMidi then
        midi_devices[deviceId]:note_on(noteNumber, vel, channel)
    end
end

function note_off(sendIntern, sendMidi, noteNumber, vel, deviceId, channel)
    -- sendIntern = sendIntern or true
    -- sendMidi = sendMidi or false
    -- noteNumber = noteNumber or 60
    -- vel = vel or defaultVel
    -- deviceId = deviceId or 1
    -- channel = channel or 1
    
    if sendIntern then
        engine.noteOff(noteNumber)
    end
    
    if sendMidi then
        midi_devices[deviceId]:note_off(noteNumber, vel, channel)
    end
end

function send_cc(id)
    local ccDest = SOUND_OPTIONS[params:get("paramCCs")]
    
    if ccDest == "midi" or ccDest == "intern + midi" then
        local cc = params:get("cc_"..id)
        local value = params:get("cc_value_"..id)
        local deviceId = params:get("cc_deviceId_"..id)
        local channel = params:get("cc_channel_"..id)
        local valMin, valMax = Q7Util.get_min_max(params:get("cc_min_"..id), params:get("cc_max_"..id))
        local val = util.round(util.linlin(0,127, valMin, valMax, value))
        midi_devices[deviceId]:cc(cc, val, channel)
    end
    
    if ccDest == "internal" or ccDest == "intern + midi" then
        local ccParam = SYNTH_CC_PARAMS[params:get("cc_intern_"..id)]
        
        if ccParam ~= "none" then
            local value = params:get("cc_value_"..id)
            local valMin, valMax = Q7Util.get_min_max(params:get("cc_min_"..id), params:get("cc_max_"..id))
            local val = util.linlin(0,127, valMin, valMax, value)
            val = util.linlin(0, 127, 0, 1, val)
            params:set_raw(ccParam, val)
        end
    end
end