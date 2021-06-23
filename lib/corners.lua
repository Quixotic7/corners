local Corners = {}
Corners.__index = Corners

local WALL_LEDS = {
    {15, 15, 14, 8, 7, 6, 5, 4},
    {8, 8, 7, 6, 5, 4, 3, 2, 1},
    {8, 8, 7, 6, 5, 4, 3, 2, 1},
    {4, 4, 3, 2, 1},
    {4, 4, 3, 2, 1},
    {4, 4, 3, 2, 1},
    {3, 3, 2, 1},
    {3, 3, 2, 1},
}

function Corners.new()
    local c = setmetatable({}, Corners)
    
    c.dx = 0 -- x velocity
    c.dy = 0 -- y velocity
    c.x = 4 -- x position
    c.y = 4 -- y position
    
    c.prev_gx = 0
    c.prev_gy = 0
    -- c.i1 = nil
    -- c.i2 = nil
    c.g = 100 -- gravity
    c.bx =  8 -- boundary x
    c.by = 8 -- boundary y
    c.f = 0.995 -- friction
    c.keys = 0 -- number of keys pressed
    c.r = {1, 1, 1, 1}
    
    c.bLeft = nil
    c.bRight = nil
    c.bUp = nil
    c.bDown = nil
    
    c.bLedEvents = {}
    
    c.draw_walls = false
    
    c.grid_dirty = true
    c.grid_width = 8
    c.grid_height = 8
    
    -- keeps track of grid presses
    c.p = {}
    for x = 1, 16 do
        c.p[x] = {}
        for y = 1, 16 do
            c.p[x][y] = 0
        end
    end
    
    return c
end


-- function Corners:describe_it(num)
--     if num==0 then self:assist("x")
--     elseif num==1 then self:assist("y")
--     elseif num==2 then self:assist("dx")
--     elseif num==3 then self:assist("dy")
--     elseif num==4 then self:assist("edge: 0=right 1=up 2=left 3=down")
--     elseif num==5 then self:assist("keys held down") end
-- end

-- change reflection state 1 - 4
function Corners:ref(i, state) 
    self.r[i] = state
end

function Corners:toggle_ref(i, x, y) 
    self.r[i] = self.r[i] == 1 and 0 or 1

    if i == 1 then -- right
        self:add_b_led_event(x, y, true)
    elseif i == 2 then -- up
        self:add_b_led_event(x, y, false)
    elseif i == 3 then -- left
        self:add_b_led_event(x, y, true)
    elseif i == 4 then -- down
        self:add_b_led_event(x, y, false)
    end
end

-- change gravity
function Corners:grr(val)
    val = util.clamp(val, 0.0, 1.0)
    val = 1 - val
    
    self.g = val * 1000 + 4
end

-- change friction
function Corners:fric(val)
    val = util.clamp(val, 0.0, 1.0)
    val = 1 - val
    
    self.f = ((val * 200) + 800) / 1000
end

function Corners:grid_key(x, y, z)
    if z == 1 then
        self.p[x][y] = 1
    else
        self.p[x][y] = 0
    end
end

-- change bounds
function Corners:bounds(xb, yb)
    self.bx = xb - 0.5
    self.by = yb - 0.5
    self.grid_width = xb
    self.grid_height = yb
end

function Corners:outlet(i, val)
    -- print("Outlet "..i..val)
    
    
    if i == 4 then
        if val == 0 then
            if self.bRight then self.bRight() end
        elseif val == 1 then
            if self.bUp then self.bUp() end
        elseif val == 2 then
            if self.bLeft then self.bLeft() end
        elseif val == 3 then
            if self.bDown then self.bDown() end
        end
    end
end

function Corners:bang()
    -- dx = dy = 0
    self.keys = 0
    
    for i1 = 1, 16 do
        for i2 = 1, 16 do
            if self.p[i1][i2] == 1 then
                -- apply gravity to points
                self.dx = self.dx + (i1 - self.x + 0.5) / self.g
                self.dy = self.dy + (i2 - self.y + 0.5) / self.g
                self.keys = self.keys + 1
            end
        end
    end
    
    -- apply friction
    self.dx = self.dx * self.f
    self.dy = self.dy * self.f
    
    -- move x direction
    self.x = self.x + self.dx
    
    -- greater than x boundary
    if self.x > self.bx then
        if self.r[1] == 1 then -- wall, reflect
            self:add_b_led_event(self.bx, self.y, true)
            self.dx = -self.dx
            self.x = self.bx
        else  
            self.x = math.max(self.x - self.bx, 0.5) -- wrap
        end
        self:outlet(4,0)
    end
    
    -- less than x boundary
    if self.x < 0.5 then
        if self.r[3] == 1 then 
            self:add_b_led_event(1, self.y, true)
            self.dx = -self.dx
            self.x = 0.5
        else  
            self.x = math.min(self.x + self.bx, self.bx)
        end
        
        self:outlet(4,2)
    end
    
    -- move y direction
    self.y = self.y + self.dy
    
    -- greater than y boundary
    if self.y > self.by then
        if self.r[4] == 1 then
            self:add_b_led_event(self.x, self.by, false)
            self.dy = -self.dy
            self.y = self.by
        else 
            self.y = math.max(self.y - self.by, 0.5)
        end

        self:outlet(4,3)
    end
    
    if self.y < 0.5 then
        if self.r[2] == 1 then
            self:add_b_led_event(self.x, 1, false)
            self.dy = -self.dy
            self.y = 0.5
        else
            self.y = math.min(self.y + self.by, self.by)
        end
        
        self:outlet(4,1)
    end
    
    local gx, gy = self:get_grid_pos()
    
    if gx ~= self.prev_gx or gy ~= self.prev_gy then self.grid_dirty = true end
    if #self.bLedEvents > 0 then self.grid_dirty = true end
    
    -- self:outlet(0,self.x)
    -- self:outlet(1,self.y)
    -- self:outlet(2,self.dx)
    -- self:outlet(3,self.dy)
    -- self:outlet(5,self.keys)
end

function Corners:get_grid_pos()
    local gx = util.clamp(util.round(self.x), 1, self.grid_width)
    local gy = util.clamp(util.round(self.y), 1, self.grid_height)
    return gx, gy
end

function Corners:add_b_led_event(x, y, vert)
    local gx, gy = util.round(x)
    local gy = util.round(y)
    local pointLevelX = util.linlin( 0, 2, 0.4, 1, math.abs(self.dx))
    local pointLevelY = util.linlin( 0, 2, 0.4, 1, math.abs(self.dy))
    local levelScale = math.max(pointLevelX, pointLevelY)
    local ledEvent = {x = gx, y = gy, scale = levelScale, vert = vert, phase = 1}
    table.insert(self.bLedEvents, ledEvent)
end

function Corners:grid_redraw(g)
    if self.draw_walls then
        local wallLed = 1
        
        if self.r[1] == 1 then -- right wall
            local wx = g.cols
            for wy = 1, g.rows do
                g:led(wx, wy, wallLed)
            end
        end
        
        if self.r[3] == 1 then -- left wall
            local wx = 1
            for wy = 1, g.rows do
                g:led(wx, wy, wallLed)
            end
        end
        
        if self.r[2] == 1 then -- top wall
            local wy = 1
            for wx = 1, g.cols do
                g:led(wx, wy, wallLed)
            end
        end
        
        if self.r[4] == 1 then -- bottom wall
            local wy = g.rows
            for wx = 1, g.cols do
                g:led(wx, wy, wallLed)
            end
        end
    end
    
    -- local removeCount = 0
    
    for bIndex, e in pairs(self.bLedEvents) do
        if e.phase <= #WALL_LEDS then
            if e.vert == true then
                for i = 1, #WALL_LEDS[e.phase] do
                    local bY = e.y + (i-1)
                    local bY2 = e.y - (i-1)
                    local bLevel = util.round(WALL_LEDS[e.phase][i] * e.scale)
                    if bY > 0 and bY <= g.rows then
                        g:led(e.x, bY, bLevel)
                    end
                    if bY2 > 0 and bY2 <= g.rows then
                        g:led(e.x, bY2, bLevel)
                    end
                end
            else
                for i = 1, #WALL_LEDS[e.phase] do
                    local bX = e.x + (i-1)
                    local bX2 = e.x - (i-1)
                    local bLevel = util.round(WALL_LEDS[e.phase][i] * e.scale)
                    if bX > 0 and bX <= g.cols then
                        g:led(bX, e.y, bLevel)
                    end
                    if bX2 > 0 and bX2 <= g.cols then
                        g:led(bX2, e.y, bLevel)
                    end
                end
            end
        end
        
        e.phase = e.phase + 1
        -- if e.phase > #WALL_LEDS then removeCount = removeCount + 1 end
        
    end
    -- print("ledEvents "..#self.bLedEvents)
    
    -- clean up dead events
    for i = 1, #self.bLedEvents do
        if i <=#self.bLedEvents then
            if self.bLedEvents[i].phase > #WALL_LEDS then
                table.remove(self.bLedEvents, i)
            end
        end
    end
    
    -- for i = 0, removeCount do
    --     table.remove(self.bLedEvents, 1)
    -- end
    
    
    
    
    local pointLevelX = util.linlin( 0, 2, 1, 15, math.abs(self.dx))
    local pointLevelY = util.linlin( 0, 2, 1, 15, math.abs(self.dy))
    local level = util.round(math.max(pointLevelX, pointLevelY))
    
    local gx, gy = self:get_grid_pos()
    g:led(gx, gy, level)
    
    self.grid_dirty = false
    self.prev_gx = gx
    self.prev_gy = gy
end

return Corners