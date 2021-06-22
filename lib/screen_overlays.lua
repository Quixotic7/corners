local Screen_Overlays = {}
Screen_Overlays.__index = Screen_Overlays

function Screen_Overlays.new()
    local c = setmetatable({}, Screen_Overlays)

    c.overlay = nil
    
    return c
end

function Screen_Overlays:show_overlay(message, message2, time)
    message = message and message or ""
    message2 = message2 and message2 or ""
    time = time and time or 2
    
    self.overlay = {text = message, text2 = message2, time = util.time() + time}
end

function Screen_Overlays:draw()
    if self.overlay then
        -- TEXT
        screen.blend_mode('add')
        screen.level(5)
        screen.font_size(8)
        screen.move(64,10)
        screen.text_center(self.overlay.text)
        screen.move(64,20)
        screen.text_center(self.overlay.text2)
        screen.blend_mode(0)
        -- REMOVE OVERLAY
        if util.time() > self.overlay.time then self.overlay = nil end
        screen.blend_mode(0)
    end
end

return Screen_Overlays