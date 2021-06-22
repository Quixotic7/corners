local Corners = {}
Corners.__index = Corners

function Corners.new()
    local c = setmetatable({}, Corners)
    
    c.dx = 0 -- x velocity
    c.dy = 0 -- y velocity
    c.x = 4 -- x position
    c.y = 4 -- y position
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

    c.draw_walls = false

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

function Corners:toggle_ref(i) 
    self.r[i] = self.r[i] == 1 and 0 or 1
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
            self.dx = -self.dx
            self.x = self.bx
        else  
            self.x = self.x - self.bx -- wrap
        end
        self:outlet(4,0)
    end
    
    -- less than x boundary
    if self.x < 0.5 then
        if self.r[3] == 1 then 
            self.dx = -self.dx
            self.x = 0.5
        else  
            self.x = self.x + self.bx
        end
        
        self:outlet(4,2)
    end
    
    -- move y direction
    self.y = self.y + self.dy
    
    -- greater than y boundary
    if self.y > self.by then
        if self.r[4] == 1 then
            self.dy = -self.dy
            self.y = self.by
        else 
            self.y = self.y - self.by
        end
        self:outlet(4,3)
    end
    
    if self.y < 0.5 then
        if self.r[2] == 1 then
            self.dy = -self.dy
            self.y = 0.5
        else
            self.y = self.y + self.by
        end
        
        self:outlet(4,1)
    end
    
    -- self:outlet(0,self.x)
    -- self:outlet(1,self.y)
    -- self:outlet(2,self.dx)
    -- self:outlet(3,self.dy)
    -- self:outlet(5,self.keys)
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

    local gx = util.round(self.x)
    local gy = util.round(self.y)
    g:led(gx, gy, 15)
end

return Corners