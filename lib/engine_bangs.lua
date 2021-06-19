-- Class for sending out note bangs

local EngineBangs = {}
EngineBangs.__index = EngineBangs

function EngineBangs.new()
    local m = setmetatable({}, EngineBangs)
    
    m.active_notes = {}
    
    m.clock_id = clock.run(function() EngineBangs.loop(m) end)
    
    m.note_on = nil
    m.note_off = nil
    
    return m
end

function EngineBangs:loop()
    local syncTime = 1/24
    
    while true do
        clock.sync(syncTime)
        
        local removeIndices = {}
        
        for j, m in pairs(self.active_notes) do
            m.time = m.time - syncTime
            if m.time <= 0 then
                if self.note_off then self.note_off(j) end
                table.insert(removeIndices, j)
            end
        end
        
        for j, v in pairs(removeIndices) do
            self.active_notes[v] = nil
        end
    end
end

-- length is in beattime, 1 = 1 quater note, 4 = 1 bar
function EngineBangs:bang(noteNumber, vel, length)
    noteNumber = noteNumber or 60
    vel = vel or 100
    length = length or 1
    if noteNumber < 0 or noteNumber > 127 then return end
    
    if self.active_notes[noteNumber] ~= nil then
        if self.note_off then self.note_off(noteNumber) end
    end
    
    if self.note_on then self.note_on(noteNumber, vel) end
    
    self.active_notes[noteNumber] = {
        time = length,
        vel = vel
    }
end

return EngineBangs