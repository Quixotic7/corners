Corners_Lib = include('lib/corners')

corners = Corners_Lib.new()

local g = grid.connect()

function init()
    corners:bounds(g.cols, g.rows)
    -- corners:init()

    clock.run(grid_redraw_clock) 
end

function key(n, v)
    corners:key(n, v)
end

function enc(n, v)
    corners:enc(n, v)
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
    corners:bang()

    g:all(0)

    corners:grid_redraw(g)

    g:refresh()
end
