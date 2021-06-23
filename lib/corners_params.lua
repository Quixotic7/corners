local Corners_Params = {}
Corners_Params.__index = Corners_Params

local controlSpecs = {}

controlSpecs.friction = controlspec.new(0, 1, 'lin', 0, 0.35, '%')
controlSpecs.gravity = controlspec.new(0, 1, 'lin', 0, 0.9, '%')
controlSpecs.noteLengthMin = controlspec.new(0, 16.0, 'lin', 0.01, 1/4, 'bt', 1/24/10)
controlSpecs.noteLengthMax = controlspec.new(0, 16.0, 'lin', 0.01, 1/16, 'bt', 1/24/10)

SOUND_OPTIONS = {"off", "internal", "midi", "intern + midi"}
KEY_PARAMS = {"key1", "key2", "key3", "key4"}
SYNTH_CC_PARAMS = {"none", 
"amp", "amp_mod", 
"lp_filter_cutoff", "lp_filter_resonance", "hp_filter_cutoff", "lp_filter_mod_env", "lp_filter_mod_lfo", "lp_filter_tracking", 
"pulse_width_mod", "main_osc_level", "sub_osc_level", "sub_osc_detune", "noise_level", "freq_mod_lfo", "freq_mod_env", "glide", "lfo_freq", "lfo_fade", 
"env_1_attack", "env_1_decay", "env_1_sustain", "env_1_release", "env_2_attack", "env_2_decay", "env_2_sustain", "env_2_release", 
"ring_mod_freq", "ring_mod_fade", "ring_mod_mix", "chorus_mix"}
SYNC_RATES = {"1/1", "1/2", "1/4", "1/8", "1/16", "1/32"}
SYNC_RATE_VALUES = {(1/1), (1/2), (1/4), (1/8), (1/16), (1/32)}

SCALE_NAMES = {}

function Corners_Params.formatNote(param)
    return musicutil.note_num_to_name(param:get(), true)
end

function Corners_Params.add_params()
    for i = 1, #musicutil.SCALES do
        table.insert(SCALE_NAMES, string.lower(musicutil.SCALES[i].name))
    end

    params:add_separator()
    params:add{type = "control", id = "friction", name = "Friction", controlspec = controlSpecs.friction}
    params:add{type = "control", id = "gravity", name = "Gravity", controlspec = controlSpecs.gravity}
    params:add{type = "option", id = "physicsRate", name = "Physics Clock", options = SYNC_RATES, default = 5}

    params:add_separator()
    params:add{type = "option", id = "bSound", name = "B Sound", options = SOUND_OPTIONS, default = 2}
    params:add{type = "option", id = "keySound", name = "Key Sound", options = SOUND_OPTIONS, default = 2}
    params:add{type = "option", id = "paramCCs", name = "Param CCs", options = SOUND_OPTIONS, default = 2}

    params:add_group("Notes", 18)
    params:add{type = "trigger", id = "generateNotes", name = "Gen Notes", action = Corners_Params.generate_notes }
    params:add{type = "option", id = "b_randomNotes", name = "B Random", options = {"off", "on"}, default = 1}

    params:add_separator()
    params:add{type = "option", id = "rootNote", name = "Root Note", options = musicutil.NOTE_NAMES, default = 3}
    params:add{type = "option", id = "scaleMode", name = "Scale", options = SCALE_NAMES, default = 3}
    params:add{type = "number", id = "b_octave", name = "B Octave", min = 1, max = 8, default = 6 }
    params:add{type = "number", id = "b_octRange", name = "B Range", min = 1, max = 4, default = 3 }
    params:add{type = "number", id = "key_octave", name = "Key Octave", min = 1, max = 8, default = 3 }
    params:add{type = "number", id = "key_octRange", name = "Key Range", min = 1, max = 4, default = 2 }
    params:add_separator()

    -- D4 A#4 D6 G6 - 62, 70, 86, 91
    params:add{type="number", id="bRight", name="B Right", min = 0, max = 127, default = 62, formatter = Corners_Params.formatNote }
    params:add{type="number", id="bUp", name="B Up", min = 0, max = 127, default = 70, formatter = Corners_Params.formatNote }
    params:add{type="number", id="bLeft", name="B Left", min = 0, max = 127, default = 86, formatter = Corners_Params.formatNote }
    params:add{type="number", id="bDown", name="B Down", min = 0, max = 127, default = 91, formatter = Corners_Params.formatNote }
    params:add{type="number", id=KEY_PARAMS[1], name="Key 1", min = 0, max = 127, default = 31, formatter = Corners_Params.formatNote }
    params:add{type="number", id=KEY_PARAMS[2], name="Key 2", min = 0, max = 127, default = 34, formatter = Corners_Params.formatNote }
    params:add{type="number", id=KEY_PARAMS[3], name="Key 3", min = 0, max = 127, default = 41, formatter = Corners_Params.formatNote }
    params:add{type="number", id=KEY_PARAMS[4], name="Key 4", min = 0, max = 127, default = 50, formatter = Corners_Params.formatNote }

    params:add_group("Note Variation", 5)
    params:add{type="number", id="b_velMin", name="B Vel Min", min = 0, max = 127, default = 100 }
    params:add{type="number", id="b_velMax", name="B Vel Max", min = 0, max = 127, default = 120 }
    params:add{type = "control", id = "b_noteLengthMin", name = "B Length Min", controlspec = controlSpecs.noteLengthMin}
    params:add{type = "control", id = "b_noteLengthMax", name = "B Length Max", controlspec = controlSpecs.noteLengthMax}
    params:add{type="number", id="key_vel", name="Key Vel", min = 0, max = 127, default = 100 }

    params:add_group("MIDI Setup", 4)
    params:add{type = "number", id = "b_deviceId", name = "B Device", min = 1, max = 4, default = 1 }
    params:add{type = "number", id = "b_midiChannel", name = "B Channel", min = 1, max = 16, default = 1 }
    params:add{type = "number", id = "key_deviceId", name = "Key Device", min = 1, max = 4, default = 1 }
    params:add{type = "number", id = "key_midiChannel", name = "Key Channel", min = 1, max = 16, default = 2 }
    -- params:add{type = "option", id = "midiCCs", name = "Midi CCs", options = {"off", "on"}, default = 1}
    params:add_separator()
    Corners_Params.add_midi_control("Param X", "x")
    Corners_Params.add_midi_control("Param Y", "y")
    Corners_Params.add_midi_control("Param DX", "dx")
    Corners_Params.add_midi_control("Param DY", "dy")

    params:add_separator()
end

function Corners_Params.generate_notes()
    local b_root = params:get("rootNote") + (12 * (params:get("b_octave") - 1))
    local b_scale = musicutil.generate_scale(b_root, params:get("scaleMode"), params:get("b_octRange"))

    local b_params = {"bDown", "bLeft", "bRight", "bUp"}

    local b_notes = {}

    for i = 1, #b_params do
        local note_i = math.random(1, #b_scale)
        table.insert(b_notes, b_scale[note_i])
        table.remove(b_scale, note_i)
    end

    table.sort(b_notes)

    for i = 1, #b_params do
        params:set(b_params[i], b_notes[i])
    end

    local key_root = params:get("rootNote") + (12 * (params:get("key_octave") - 1))
    local key_scale = musicutil.generate_scale(key_root, params:get("scaleMode"), params:get("key_octRange"))

    local key_notes = {}

    for i = 1, #KEY_PARAMS do
        local note_i = math.random(1, #key_scale)
        table.insert(key_notes, key_scale[note_i])
        table.remove(key_scale, note_i)
    end

    table.sort(key_notes)

    for i = 1, #KEY_PARAMS do
        params:set(KEY_PARAMS[i], key_notes[i])
    end

    -- b_off_all()
    key_off_all()
end

function Corners_Params.add_midi_control(groupName, controlName)
    params:add_group(groupName, 8)
    params:add{type = "option", id = "cc_enabled_"..controlName, name = "Enabled", options = {"off", "on"}, default = 1}
    params:add{type = "option", id = "cc_intern_"..controlName, name = "Int Param", options = SYNTH_CC_PARAMS, default = 1}
    params:add{type = "number", id = "cc_"..controlName, name = "CC", min = 0, max = 127, default = 23}
    params:add{type = "number", id = "cc_value_"..controlName, name = "Value", min = 0, max = 127, default = 0}
    params:add{type = "number", id = "cc_min_"..controlName, name = "Min Value", min = 0, max = 127, default = 0}
    params:add{type = "number", id = "cc_max_"..controlName, name = "Min Value", min = 0, max = 127, default = 127}
    params:add{type = "number", id = "cc_deviceId_"..controlName, name = "Device", min = 1, max = 4, default = 1 }
    params:add{type = "number", id = "cc_channel_"..controlName, name = "Channel", min = 1, max = 16, default = 1 }
end

return Corners_Params