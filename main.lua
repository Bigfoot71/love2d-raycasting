local lg = love.graphics

local f = lg.newFont(24)
lg.setFont(f)

local Player = require("player")
local raycaster = require("raycaster")

local map1 = {
    {8,8,8,8,8,8,8,8,8,8,8,4,4,6,4,4,6,4,6,4,4,4,6,4},
    {8,0,0,0,0,0,0,0,0,0,8,4,-1.1,-1.1,-1.1,-1.1,-1.1,-1.1,-1.1,-1.1,-1.1,-1.1,-1.1,4},
    {8,0,3,3,0,0,-2,0,0,8,8,4,-1.1,-1.1,-1.1,-1.1,-1.1,-1.1,-1.1,-1.1,-1.1,-1.1,-1.1,6},
    {8,0,0,3,0,-2,-2,-2,0,-1.1,-1.1,-1.1,-1.1,-1.1,-1.1,-1.1,-1.1,-1.1,-1.1,-1.1,-1.1,-1.1,-1.1,6},
    {8,0,3,3,0,0,-2,0,0,8,8,4,-1.1,-1.1,-1.1,-1.1,-1.1,-1.1,-1.1,-1.1,-1.1,-1.1,-1.1,4},
    {8,0,0,0,0,0,0,0,0,0,8,4,-1.1,-1.1,-1.1,-1.1,-1.1,6,6,6,-1.1,6,4,6},
    {8,8,8,8,0,8,8,8,8,8,8,4,4,4,4,4,4,6,0,0,0,0,0,6},
    {7,7,7,7,0,7,7,7,7,0,8,0,8,0,8,0,8,4,0,4,0,6,0,6},
    {7,7,-1,-1,-1,-1,-1,-1,7,8,0,8,0,8,0,8,8,6,0,0,0,0,0,6},
    {7,-1,-1,-1,-1,-1,-1,-1,-1,0,0,0,0,0,0,0,8,6,0,0,0,0,0,4},
    {7,-1,-1,-1,-1,-1,-1,-1,-1,0,0,0,0,0,0,0,8,6,0,6,0,6,0,6},
    {7,7,-1,-1,-1,-1,-1,-1,7,8,0,8,0,8,0,8,8,6,4,6,0,6,6,6},
    {7,7,7,7,0,7,7,7,7,8,8,4,0,6,8,4,8,3,3,3,0,3,3,3},
    {2,2,2,2,0,2,2,2,2,4,6,4,0,0,6,0,6,3,0,0,0,0,0,3},
    {2,2,0,0,0,0,0,2,2,4,0,0,0,0,0,0,4,3,0,0,0,0,0,3},
    {2,0,0,0,0,0,0,0,2,4,0,0,0,0,0,0,4,3,0,0,0,0,0,3},
    {1,0,0,0,0,0,0,0,1,4,4,4,4,4,6,0,6,3,3,0,0,0,3,3},
    {2,0,0,0,0,0,0,0,2,2,2,1,2,2,2,6,6,0,0,5,0,5,0,5},
    {2,2,0,0,0,0,0,2,2,2,0,0,0,2,2,0,5,0,5,0,0,0,5,5},
    {2,0,0,0,0,0,0,0,2,0,0,0,0,0,2,5,0,5,0,5,0,5,0,5},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,5},
    {2,0,0,0,0,0,0,0,2,0,0,0,0,0,2,5,0,5,0,5,0,5,0,5},
    {2,2,0,0,0,0,0,2,2,2,0,0,0,2,2,0,5,0,5,0,0,0,5,5},
    {2,2,2,2,1,2,2,2,2,2,2,1,2,2,2,5,5,5,5,5,5,5,5,5}
}

local map2 = {
    {4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,7,7,7,7,7,7,7,7},
    {4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,7,0,0,0,0,0,0,7},
    {4,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,7},
    {4,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,7},
    {4,0,3,0,0,0,0,0,0,0,0,0,0,0,0,0,7,0,0,0,0,0,0,7},
    {4,0,4,0,0,0,0,5,5,5,5,5,5,5,5,5,7,7,0,7,7,7,7,7},
    {4,0,5,0,0,0,0,5,0,5,0,5,0,5,0,5,7,0,0,0,7,7,7,1},
    {4,0,6,0,0,0,0,5,0,0,0,0,0,0,0,5,7,0,0,0,0,0,0,8},
    {4,0,7,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,7,7,7,1},
    {4,0,8,0,0,0,0,5,0,0,0,0,0,0,0,5,7,0,0,0,0,0,0,8},
    {4,0,0,0,0,0,0,5,0,0,0,0,0,0,0,5,7,0,0,0,7,7,7,1},
    {4,0,0,0,0,0,0,5,5,5,5,0,5,5,5,5,7,7,7,7,7,7,7,1},
    {6,6,6,6,6,6,6,6,6,6,6,0,6,6,6,6,6,6,6,6,6,6,6,6},
    {8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4},
    {6,6,6,6,6,6,0,6,6,6,6,0,6,6,6,6,6,6,6,6,6,6,6,6},
    {4,4,4,4,4,4,0,4,4,4,6,0,6,2,2,2,2,2,2,2,3,3,3,3},
    {4,0,0,0,0,0,0,0,0,4,6,0,6,2,0,0,0,0,0,2,0,0,0,2},
    {4,0,0,0,0,0,0,0,0,0,0,0,6,2,0,0,5,0,0,2,0,0,0,2},
    {4,0,0,0,0,0,0,0,0,4,6,0,6,2,0,0,0,0,0,2,2,0,2,2},
    {4,0,6,0,6,0,0,0,0,4,6,0,0,0,0,0,5,0,0,0,0,0,0,2},
    {4,0,0,5,0,0,0,0,0,4,6,0,6,2,0,0,0,0,0,2,2,0,2,2},
    {4,0,6,0,6,0,0,0,0,4,6,0,6,2,0,0,5,0,0,2,0,0,0,2},
    {4,0,0,0,0,0,0,0,0,4,6,0,6,2,0,0,0,0,0,2,0,0,0,2},
    {4,4,4,4,4,4,4,4,4,4,1,1,1,2,2,2,2,2,2,3,3,3,3,3}
  };

local player = Player.new(map1, 2.5, 2.5)

function love.load()

    -- Init raycaster --

    raycaster:init(map1, true)   -- true/false = hardware acceleration

    raycaster:setTextures(
        "images/walls/1.png",
        "images/walls/2.png",
        "images/walls/3.png",
        "images/walls/4.png",
        "images/walls/5.png",
        "images/walls/6.png",
        "images/walls/7.png",
        "images/walls/8.png"
    )

    raycaster:setTextures(  -- NOT IMPLEMENTED IN SOFTWARE ACCELERATION
        "ground",
        "images/ground/1.png",
        "images/ground/2.png",
        "images/ground/3.png"
    )

    raycaster:setTextures(  -- NOT IMPLEMENTED IN SOFTWARE ACCELERATION
        "ceiling",
        "images/ceiling/1.png",
        "images/ceiling/2.png",
        "images/ceiling/3.png"
    )

    -- Love2d settings --

    love.mouse.setRelativeMode(true)

end

-- MAIN PROGRAM --

function love.update(dt)

    player:movement(dt)

    raycaster:update(
        player.x, player.y,
        player.z, player.pitch,
        player.dir_x, player.dir_y,
        player.plane_x, player.plane_y
    )

end

function love.mousemoved(x,y,dx,dy)
    if love.mouse.getRelativeMode() then
        player:mousemoved(dx,dy)
    end
end

function love.mousepressed()
    if not love.mouse.getRelativeMode() then
        love.mouse.setRelativeMode(true)
    end
end

function love.keypressed(k)

    if k=="m" then  -- Switch map
        raycaster:setMap(raycaster.map == map1 and map2 or map1)
        player:setMap(raycaster.map)

    elseif k=="escape" then
        love.mouse.setRelativeMode(false)
    end

end

function love.draw()

    raycaster:renderView()

    local size_map = lg.getWidth()*.2
    raycaster:renderMap(lg.getWidth()-size_map, 0, size_map, size_map)

    lg.setColor(1,1,0)
    lg.print(tostring(love.timer.getFPS()).." FPS")

    local str = ("%dx%d"):format(lg.getWidth(), lg.getHeight())
    lg.print(str, 0, lg.getHeight()-f:getHeight())
    lg.setColor(1,1,1)

end

function love.resize(w,h)
    raycaster:resize(w,h,true)
end
