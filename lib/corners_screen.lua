-- handles drawing corners to the screen
local Corners_Screen = {}
Corners_Screen.__index = Corners_Screen

function Corners_Screen.new(corners, x, y, w, h, gw, gh)
    local c = setmetatable({}, Corners_Screen)
    
    c.corners = corners
    c.x = x
    c.y = y
    c.w = w
    c.h = h
    c.gw = gw
    c.gh = gh
    c.trail = {}
    
    return c
end

function Corners_Screen:draw()
    screen.blend_mode('add')
    
    screen.level(10)
    screen.line_width(2)
    
    if self.corners.r[1] == 1 then -- right wall
        screen.move(self.x + self.w, self.y)
        screen.line_rel(0, self.h)
        screen.stroke()
    end
    
    if self.corners.r[3] == 1 then -- left wall
        screen.move(self.x, self.y)
        screen.line_rel(0, self.h)
        screen.stroke()
    end
    
    if self.corners.r[2] == 1 then -- top wall
        screen.move(self.x, self.y)
        screen.line_rel(self.w, 0)
        screen.stroke()
    end
    
    if self.corners.r[4] == 1 then -- bottom wall
        screen.move(self.x, self.y + self.h)
        screen.line_rel(self.w, 0)
        screen.stroke()
    end
    
    
    
    local pointLevelX = util.linlin( 0, 2, 1, 15, math.abs(self.corners.dx))
    local pointLevelY = util.linlin( 0, 2, 1, 15, math.abs(self.corners.dy))
    local level = util.round(math.max(pointLevelX, pointLevelY))
    
    -- print("LevelX "..level)
    
    screen.level(level)
    
    screen.line_width(1)

    local prevForward = nil
    local breakTrailIndex = 0
    
    -- draws a trailing line
    for i = 1, #self.trail do
        local t1 = self.trail[i]
        local t2 = nil
        if i == #self.trail then
            t2 = {x = self.corners.x, y = self.corners.y}
        else
            t2 = self.trail[i+1]
        end
        
        local p1 = self:remap_point(t1.x, t1.y)
        local p2 = self:remap_point(t2.x, t2.y)

        local forward = (p2 - p1):norm()
        if i == 1 then prevForward = forward end

        local dot = prevForward:dot(forward)

        -- print("Dot "..dot)
        
        if dot > 0.25 then
            
            local tl = util.round(((i / #self.trail) * 0.6) * level)
            screen.level(tl)
            
            screen.move(p1.x, p1.y)
            screen.line(p2.x, p2.y)
            screen.stroke()
        else
            breakTrailIndex = i -- break the trail here, probably teleported
        end

        prevForward = forward
    end

    if breakTrailIndex > 0 then
        for i = 1, breakTrailIndex do
            table.remove(self.trail, 1)
        end
    end
    
    local ball = self:remap_point(self.corners.x, self.corners.y)
    
    screen.circle(ball.x, ball.y, 1.5)
    screen.fill()
    
    screen.blend_mode(0)
    
    table.insert(self.trail, {x = self.corners.x, y = self.corners.y})
    if #self.trail > 3 then table.remove(self.trail, 1) end
end

function Corners_Screen:remap_point(x,y)
    local px = util.linlin( 0, self.gw, self.x, self.x + self.w, x)
    local py = util.linlin( 0, self.gh, self.y, self.y + self.h, y)
    
    return Vector2d(px, py)
    -- return {x = px, y = py}
end

return Corners_Screen