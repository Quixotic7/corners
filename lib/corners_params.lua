local Corners_Params = {}
Corners_Params.__index = Corners_Params

local controlSpecs = {}

controlSpecs.friction = controlspec.new(0, 1, 'lin', 0, 0.4, '%')
controlSpecs.gravity = controlspec.new(0, 1, 'lin', 0, 0.98, '%')
controlSpecs.noteLengthMin = controlspec.new(0, 16.0, 'lin', 0.01, 1/4, 'bt', 1/24/10)
controlSpecs.noteLengthMax = controlspec.new(0, 16.0, 'lin', 0.01, 1/16, 'bt', 1/24/10)

KEY_PARAMS = {"key1", "key2", "key3", "key4"}

function Corners_Params.formatNote(param)
    return musicutil.note_num_to_name(param:get(), true)
end

function Corners_Params.add_params()
    params:add_separator()
    params:add{type = "control", id = "friction", name = "Friction", controlspec = controlSpecs.friction}
    params:add{type = "control", id = "gravity", name = "Gravity", controlspec = controlSpecs.gravity}
    params:add_separator()
    params:add{type = "option", id = "internalSynth", name = "Internal Synth", options = {"off", "on"}, default = 2, action = function(value)
        if value ~= 2 then
            engine.noteOffAll()
        end
    end}
    params:add{type = "option", id = "midiOut", name = "Midi Out", options = {"off", "on"}, default = 1}
    params:add{type = "number", id = "b_midiChannel", name = "B Channel", min = 1, max = 16, default = 1 }
    params:add{type = "number", id = "key_midiChannel", name = "Key Channel", min = 1, max = 16, default = 2 }
    params:add{type = "option", id = "midiCCs", name = "Midi CCs", options = {"off", "on"}, default = 1}
    params:add_separator()
    Corners_Params.add_midi_control("Midi CC x", "x")
    Corners_Params.add_midi_control("Midi CC y", "y")
    Corners_Params.add_midi_control("Midi CC dx", "dx")
    Corners_Params.add_midi_control("Midi CC dy", "dy")

    params:add_group("notes", 8)
    -- D4 A#4 D6 G6 - 62, 70, 86, 91
    params:add{type="number", id="bRight", name="B Right", min = 0, max = 127, default = 62, formatter = Corners_Params.formatNote }
    params:add{type="number", id="bUp", name="B Up", min = 0, max = 127, default = 70, formatter = Corners_Params.formatNote }
    params:add{type="number", id="bLeft", name="B Left", min = 0, max = 127, default = 86, formatter = Corners_Params.formatNote }
    params:add{type="number", id="bDown", name="B Down", min = 0, max = 127, default = 91, formatter = Corners_Params.formatNote }
    params:add{type="number", id=KEY_PARAMS[1], name="Key 1", min = 0, max = 127, default = 31, formatter = Corners_Params.formatNote }
    params:add{type="number", id=KEY_PARAMS[2], name="Key 2", min = 0, max = 127, default = 34, formatter = Corners_Params.formatNote }
    params:add{type="number", id=KEY_PARAMS[3], name="Key 3", min = 0, max = 127, default = 41, formatter = Corners_Params.formatNote }
    params:add{type="number", id=KEY_PARAMS[4], name="Key 4", min = 0, max = 127, default = 50, formatter = Corners_Params.formatNote }
 
    params:add_group("note variation", 4)
    params:add{type="number", id="velMin", name="Vel Min", min = 0, max = 127, default = 60 }
    params:add{type="number", id="velMax", name="Vel Max", min = 0, max = 127, default = 120 }

    params:add{type = "control", id = "noteLengthMin", name = "Length Min", controlspec = controlSpecs.noteLengthMin}
    params:add{type = "control", id = "noteLengthMax", name = "Length Max", controlspec = controlSpecs.noteLengthMax}
    
    params:add_separator()
end

function Corners_Params.add_midi_control(groupName, controlName)
    params:add_group(groupName, 6)
    params:add{type = "option", id = "cc_enabled_"..controlName, name = "Enabled", options = {"off", "on"}, default = 1}
    params:add{type = "number", id = "cc_"..controlName, name = "CC", min = 0, max = 127, default = 23}
    params:add{type = "number", id = "cc_value_"..controlName, name = "Value", min = 0, max = 127, default = 0}
    params:add{type = "number", id = "cc_min_"..controlName, name = "Min Value", min = 0, max = 127, default = 0}
    params:add{type = "number", id = "cc_max_"..controlName, name = "Min Value", min = 0, max = 127, default = 127}
    params:add{type = "number", id = "cc_channel_"..controlName, name = "Channel", min = 1, max = 16, default = 1 }
end

return Corners_Params