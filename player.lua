local clamp = function (v,min,max)
    return (v<min) and min or (v>max) and max or v
end

Player = {}
Player.__index = Player

function Player.new(map, x, y, dir_x, dir_y)

    if not dir_y then
        dir_x = dir_x or 0
        dir_y = math.sin(dir_x)
        dir_x = math.cos(dir_y)
    end

    local length = math.sqrt(dir_x*dir_x+dir_y*dir_y)
    local plane_x = (dir_y/length)*.66
    local plane_y = (dir_x/length)*.66

    return setmetatable({

        map = map;

        x = x, y = y;
        z = 0, pitch = 0;

        dir_x = dir_x;
        dir_y = dir_y;

        plane_x = plane_x;
        plane_y = plane_y;

        rotSpeed = 2.5;
        speed = 5;

    }, Player)

end

function Player:setMap(map)
    self.map = map
end

function Player:movement(dt)

    local lk = love.keyboard
    local map = self.map

    local speed = self.speed * dt

    -- MOVEMENT (WASD || ZQSD) --

    local vx, vy = 0, 0

    if lk.isScancodeDown("w") then vy = vy - 1 end
    if lk.isScancodeDown("s") then vy = vy + 1 end
    if lk.isScancodeDown("a") then vx = vx - 1 end
    if lk.isScancodeDown("d") then vx = vx + 1 end

    if vx ~= 0 or vy ~= 0 then

        local len = math.sqrt(vx*vx+vy*vy)

        if len > 0 then

            vx, vy = vx / len, vy / len

            if vx ~= 0 then
                local move_x = self.x + vx * (self.plane_x * speed)
                local move_y = self.y + vx * (self.plane_y * speed)
                if map[math.floor(self.y)][math.floor(move_x)] <= 0 then self.x = move_x end
                if map[math.floor(move_y)][math.floor(self.x)] <= 0 then self.y = move_y end
            end

            if vy ~= 0 then
                local move_x = self.x - vy * (self.dir_x * speed)
                local move_y = self.y - vy * (self.dir_y * speed)
                if map[math.floor(self.y)][math.floor(move_x)] <= 0 then self.x = move_x end
                if map[math.floor(move_y)][math.floor(self.x)] <= 0 then self.y = move_y end
            end

        end

    end

    -- JUMP AND CROUCH -- TODO: rewrite (is not adjusted to screen size)


    if not self.jump then
        if lk.isDown("c") then
            self.vy = -800
        elseif lk.isDown("space") then
            self.vy, self.jump = 1600, true
        end
    end

    if self.vy then

        if self.jump then

            self.z = self.z + self.vy * dt
            self.vy = self.vy - 6400 * dt

            if self.z < 0 then
                self.z, self.vy, self.jump = 0, nil, false
            end

        else
            self.z = clamp(self.z + self.vy * dt, -200, 0)
            self.vy = self.z ~= 0 and self.vy + 3200 * dt or nil
        end

    end

end

function Player:mousemoved(dx,dy)

    -- VIEW LEFT AND RIGHT --

    local rotSpeed = .0025 * dx * self.rotSpeed

    local old_vx = self.dir_x
    self.dir_x = self.dir_x * math.cos(rotSpeed) - self.dir_y * math.sin(rotSpeed)
    self.dir_y = old_vx * math.sin(rotSpeed) + self.dir_y * math.cos(rotSpeed)

    local old_plane_x = self.plane_x
    self.plane_x = self.plane_x * math.cos(rotSpeed) - self.plane_y * math.sin(rotSpeed)
    self.plane_y = old_plane_x * math.sin(rotSpeed) + self.plane_y * math.cos(rotSpeed)

    -- VIEW UP AND DOWN -- TODO: rewrite (is not adjusted to screen size)

    self.pitch = clamp(self.pitch - dy * self.rotSpeed, -100, 100)

end

return Player
