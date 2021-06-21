MollyThePoly = require "molly_the_poly/lib/molly_the_poly_engine"
musicutil = require 'musicutil'

engine.name = "MollyThePoly"

Corners_Lib = include('lib/corners')
Corners_Params = include('lib/corners_params')
Engine_Bangs = include('lib/engine_bangs')
Q7Util = include('lib/Q7Util')

corners = Corners_Lib.new()
bangs = Engine_Bangs.new()

local g = grid.connect()
local midi = midi.connect(1)

local heldKeyId = 1 -- polyphonic id for the held key
local prevKeys = 0
local defaultVel = 100

function init()
    corners:bounds(g.cols, g.rows)
    -- corners:init()
    
    Corners_Params.add_params()
    
    MollyThePoly.add_params()
    MollyThePoly.randomize_params("lead")
    
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
    
    
    
    g:all(0)
    
    corners:grid_redraw(g)
    
    g:refresh()
end

function bang_note(noteNumber)
    local lengthMin, lengthMax = Q7Util.get_min_max(params:get("noteLengthMin"), params:get("noteLengthMax"))
    local length = util.linlin(0,1, lengthMin, lengthMax, math.random())
    bangs:bang(noteNumber, 100, length)
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
