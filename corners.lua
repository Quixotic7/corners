MollyThePoly = require "molly_the_poly/lib/molly_the_poly_engine"
musicutil = require 'musicutil'

engine.name = "MollyThePoly"

Corners_Lib = include('lib/corners')
Corners_Params = include('lib/corners_params')
Engine_Bangs = include('lib/engine_bangs')
Q7Util = include('lib/Q7Util')
tabutil = include('lib/tabutil')
Grid_Events_Handler = include('lib/grid_events')

corners = Corners_Lib.new()
bangs = Engine_Bangs.new()

local g = grid.connect()
local midi = midi.connect(1)
local grid_events = Grid_Events_Handler.new()

local prevKeys = 0
local defaultVel = 100

local prev = {}
prev.x = 0
prev.y = 0
prev.dx = 0
prev.dy = 0

function init()
    corners:bounds(g.cols, g.rows)
    -- corners:init()
    
    Corners_Params.add_params()
    params:set_action("cc_value_x", function() send_cc("x") end)
    params:set_action("cc_value_y", function() send_cc("y") end)
    params:set_action("cc_value_dx", function() send_cc("dx") end)
    params:set_action("cc_value_dy", function() send_cc("dy") end)
    
    MollyThePoly.add_params()
    MollyThePoly.randomize_params("lead")
    
    grid_events.grid_event = function (e) grid_event(e) end
    
    corners.bRight = function() bang_note(params:get("bRight")) end
    corners.bLeft = function() bang_note(params:get("bLeft")) end
    corners.bUp = function() bang_note(params:get("bUp")) end
    corners.bDown = function() bang_note(params:get("bDown")) end
    
    bangs.note_on = function (noteNumber, vel)
        -- print("NoteOn "..noteNumber)
        local channel = params:get("b_midiChannel")
        note_on(noteNumber, vel, channel)
    end
    
    bangs.note_off = function (noteNumber)
        -- print("NoteOff")
        local channel = params:get("b_midiChannel")
        note_off(noteNumber, defaultVel, channel)
    end
    
    clock.run(grid_redraw_clock) 
end

function key(n, v)
    -- corners:key(n, v)
    
    if n == 2 and v == 1 then
        MollyThePoly.randomize_params("lead")
    elseif n == 3 and v == 1 then
        MollyThePoly.randomize_params("perc")
    end
end

function enc(n, v)
    -- corners:enc(n, v)
end

g.key = function(x, y, z)
    corners:grid_key(x, y, z)
    
    grid_events:key(x,y,z)
end

function grid_event(e)
    if e.x == g.cols and e.y > 1 and e.y < g.rows and e.type == "double_click" then
        corners:toggle_ref(1)
    end

    if e.x == 1 and e.y > 1 and e.y < g.rows and e.type == "double_click" then
        corners:toggle_ref(3)
    end

    if e.y == 1 and e.x > 1 and e.x < g.cols and e.type == "double_click" then
        corners:toggle_ref(2)
    end
    
    if e.y == g.rows and e.x > 1 and e.x < g.cols and e.type == "double_click" then
        corners:toggle_ref(4)
    end
end


function grid_redraw_clock() -- our grid redraw clock
    while true do -- while it's running...
        grid_redraw()
        -- clock.sleep(1/15) -- refresh rate
        
        clock.sleep(1/20) -- refresh rate
    end
end

function grid_redraw()
    corners:fric(params:get("friction"))
    corners:grr(params:get("gravity"))
    corners:bang()
    
    -- play notes while holding keys
    if corners.keys ~= prevKeys then
        if corners.keys == 0 then
            local channel = params:get("key_midiChannel")
            
            local noteNumber = params:get(KEY_PARAMS[prevKeys])
            note_off(noteNumber, defaultVel, channel)
            prevKeys = corners.keys
        else
            if corners.keys <= #KEY_PARAMS then
                local channel = params:get("key_midiChannel")
                
                if prevKeys ~= 0 then
                    local prevNoteNumber = params:get(KEY_PARAMS[prevKeys])
                    note_off(prevNoteNumber, defaultVel, channel)
                end
                local noteNumber = params:get(KEY_PARAMS[corners.keys])
                note_on(noteNumber, defaultVel, channel)
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
        local val = util.round(util.linlin(0, g.cols, 0, 127, corners.y))
        params:set("cc_value_y", val)
        prev.y = corners.y
    end

    if corners.dx ~= prev.dx then
        local val = util.round(util.linlin(-4.0, 4.0, 0, 127, corners.dx))
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

    -- print(corners.dx)
    -- print(corners.dx)

    
    -- send_cc("x")
    
    
    
    g:all(0)
    
    corners:grid_redraw(g)
    
    g:refresh()
end

function bang_note(noteNumber)
    local velMin, velMax = Q7Util.get_min_max(params:get("velMin"), params:get("velMax"))
    local vel = util.round(util.linlin(0,1, velMin, velMax, math.random()))
    
    local lengthMin, lengthMax = Q7Util.get_min_max(params:get("noteLengthMin"), params:get("noteLengthMax"))
    local length = util.linlin(0,1, lengthMin, lengthMax, math.random())
    
    bangs:bang(noteNumber, vel, length)
end

function note_on(noteNumber, vel, channel)
    vel = vel or defaultVel
    channel = channel or 1
    
    if params:get("internalSynth") == 2 then
        engine.noteOn(noteNumber, musicutil.note_num_to_freq(noteNumber), vel / 127.0)
    end
    
    if params:get("midiOut") == 2 then
        midi:note_on(noteNumber, vel, channel)
    end
end

function note_off(noteNumber, vel, channel)
    vel = vel or defaultVel
    channel = channel or 1
    
    if params:get("internalSynth") == 2 then
        engine.noteOff(noteNumber)
    end
    
    if params:get("midiOut") == 2 then
        midi:note_off(noteNumber, vel, channel)
    end
end

function send_cc(id)
    if params:get("midiCCs") == 2 and params:get("cc_enabled_"..id) == 2 then
        local cc = params:get("cc_"..id)
        local value = params:get("cc_value_"..id)
        local channel = params:get("cc_channel_"..id)
        local valMin, valMax = Q7Util.get_min_max(params:get("cc_min_"..id), params:get("cc_max_"..id))
        local val = util.round(util.linlin(0,127, valMin, valMax, value))
        midi:cc(cc, val, channel)
    end
end