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

function Player:move(dt)

    local map = self.map

    -- MOVEMENT (WQSE || ZASE) --

    local vx, vy = 0, 0

    if love.keyboard.isScancodeDown("w") then vy = vy - 1 end
    if love.keyboard.isScancodeDown("s") then vy = vy + 1 end
    if love.keyboard.isScancodeDown("q") then vx = vx - 1 end
    if love.keyboard.isScancodeDown("e") then vx = vx + 1 end

    if vx ~= 0 or vy ~= 0 then

        local len = math.sqrt(vx*vx+vy*vy)

        if len > 0 then

            vx, vy = vx / len, vy / len

            if vx ~= 0 then
                local move_x = self.x + vx * (self.plane_x * self.speed * dt)
                local move_y = self.y + vx * (self.plane_y * self.speed * dt)
                if map[math.floor(self.y)][math.floor(move_x)] <= 0 then self.x = move_x end
                if map[math.floor(move_y)][math.floor(self.x)] <= 0 then self.y = move_y end
            end

            if vy ~= 0 then
                local move_x = self.x - vy * (self.dir_x * self.speed * dt)
                local move_y = self.y - vy * (self.dir_y * self.speed * dt)
                if map[math.floor(self.y)][math.floor(move_x)] <= 0 then self.x = move_x end
                if map[math.floor(move_y)][math.floor(self.x)] <= 0 then self.y = move_y end
            end

        end

    end

    -- ROTATION (AD || QD) --

    if love.keyboard.isScancodeDown("a") then

        local rotSpeed = self.rotSpeed * dt

        local old_vx = self.dir_x
        self.dir_x = self.dir_x * math.cos(-rotSpeed) - self.dir_y * math.sin(-rotSpeed)
        self.dir_y = old_vx * math.sin(-rotSpeed) + self.dir_y * math.cos(-rotSpeed)

        local old_plane_x = self.plane_x
        self.plane_x = self.plane_x * math.cos(-rotSpeed) - self.plane_y * math.sin(-rotSpeed)
        self.plane_y = old_plane_x * math.sin(-rotSpeed) + self.plane_y * math.cos(-rotSpeed)

    end

    if love.keyboard.isScancodeDown("d") then

        local rotSpeed = self.rotSpeed * dt

        local old_vx = self.dir_x
        self.dir_x = self.dir_x * math.cos(rotSpeed) - self.dir_y * math.sin(rotSpeed)
        self.dir_y = old_vx * math.sin(rotSpeed) + self.dir_y * math.cos(rotSpeed)

        local old_plane_x = self.plane_x
        self.plane_x = self.plane_x * math.cos(rotSpeed) - self.plane_y * math.sin(rotSpeed)
        self.plane_y = old_plane_x * math.sin(rotSpeed) + self.plane_y * math.cos(rotSpeed)

    end

end

return Player
