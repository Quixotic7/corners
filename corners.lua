MollyThePoly = require "molly_the_poly/lib/molly_the_poly_engine"
musicutil = require 'musicutil'

engine.name = "MollyThePoly"

Corners_Lib = include('lib/corners')
Engine_Bangs = include('lib/engine_bangs')
Q7Util = include('lib/Q7Util')

corners = Corners_Lib.new()
bangs = Engine_Bangs.new()

bangs.note_on = function (noteNumber, vel)
    -- print("NoteOn "..noteNumber)
    engine.noteOn(noteNumber, musicutil.note_num_to_freq(noteNumber), vel / 127.0)
end

bangs.note_off = function (noteNumber)
    -- print("NoteOff")
    engine.noteOff(noteNumber)
end

corners.bRight = function() bang_note(params:get("bRight")) end
corners.bLeft = function() bang_note(params:get("bLeft")) end
corners.bUp = function() bang_note(params:get("bUp")) end
corners.bDown = function() bang_note(params:get("bDown")) end

local g = grid.connect()

local controlSpecs = {}

controlSpecs.friction = controlspec.new(0, 1, 'lin', 0, 0.4, '%')
controlSpecs.gravity = controlspec.new(0, 1, 'lin', 0, 0.98, '%')
controlSpecs.noteLengthMin = controlspec.new(0, 16.0, 'lin', 0.01, 1/4, 'bt', 1/24/10)
controlSpecs.noteLengthMax = controlspec.new(0, 16.0, 'lin', 0.01, 1/16, 'bt', 1/24/10)

function init()
    corners:bounds(g.cols, g.rows)
    -- corners:init()

    params:add_separator()
    params:add{type = "control", id = "friction", name = "Friction", controlspec = controlSpecs.friction}
    params:add{type = "control", id = "gravity", name = "Gravity", controlspec = controlSpecs.gravity}

    params:add_separator()
    -- D4 A#4 D6 G6 - 62, 70, 86, 91
    params:add{type="number", id="bRight", name="B Right", min = 0, max = 127, default = 62 }
    params:add{type="number", id="bUp", name="B Up", min = 0, max = 127, default = 70 }
    params:add{type="number", id="bLeft", name="B Left", min = 0, max = 127, default = 86 }
    params:add{type="number", id="bDown", name="B Down", min = 0, max = 127, default = 91 }

    params:add_separator()
    params:add{type="number", id="velMin", name="Vel Min", min = 0, max = 127, default = 60 }
    params:add{type="number", id="velMax", name="Vel Max", min = 0, max = 127, default = 120 }

    params:add{type = "control", id = "noteLengthMin", name = "Length Min", controlspec = controlSpecs.noteLengthMin}
    params:add{type = "control", id = "noteLengthMax", name = "Length Max", controlspec = controlSpecs.noteLengthMax}
    
    params:add_separator()
    
    MollyThePoly.add_params()
    MollyThePoly.randomize_params("lead")
    
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
    
    g:all(0)
    
    corners:grid_redraw(g)
    
    g:refresh()
end

function bang_note(noteNumber)
    local lengthMin, lengthMax = Q7Util.get_min_max(params:get("noteLengthMin"), params:get("noteLengthMax"))
    local length = util.linlin(0,1, lengthMin, lengthMax, math.random())
    bangs:bang(noteNumber, 100, length)
end
