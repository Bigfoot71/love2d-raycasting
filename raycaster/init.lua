local PATH = (...):gsub("%.","/")
local lg = love.graphics

local Raycaster = {}

function Raycaster:init(map, hardware_accel, screen_width, screen_height, num_rays)

    screen_width = screen_width or lg.getWidth()
    screen_height = screen_height or lg.getHeight()

    local h_screen_width = screen_width * .5
    local h_screen_height = screen_height * .5

    num_rays = num_rays or screen_width -- For a 3D scene we need the same number of rays as pixels of width

    -- Create or reset render_data table --

    if not self.render_data then

        self.render_data = {
            pos = {};
            dir = {};
            plane = {};
        }

        self.texArrays = {}

        self.textures = {
            ground  = {};   -- -inf -> 0
            walls   = {};   -- 1 -> inf
        }

    else

        local rd = self.render_data
        rd.pos[1], rd.pos[2] = nil, nil
        rd.dir[1], rd.dir[2] = nil, nil
        rd.plane[1], rd.plane[2] = nil, nil
        for i = 1, #rd do rd[i] = nil end

        if self.frameBuffer then
            self.frameBuffer:release()
            self.renderShader:release()
            self.dataBuffer:release()
            self.dataBufferTexture:release()
        elseif self.renderBuffer then
            self.renderBuffer:release()
            self.renderTexture:release()
        end

    end

    -- Init new values --

    self:setMap(map)
    self.num_rays = num_rays
    self.screen_width = screen_width
    self.screen_height = screen_height
    self.h_screen_width = h_screen_width
    self.h_screen_height = h_screen_height
    self.hardware_accel = hardware_accel

    -- Define render function --

    if hardware_accel then

        self.frameBuffer = love.graphics.newCanvas(screen_width, screen_height)
        self.renderShader = love.graphics.newShader(PATH.."/renderer.glsl")

        self.dataBuffer = love.image.newImageData(screen_width, 2, "rgba16f")
        self.dataBufferTexture = love.graphics.newImage(self.dataBuffer)

        self.renderView = love.filesystem.load(PATH.."/render_h.lua")()

    else

        self.renderBuffer = love.image.newImageData(screen_width, screen_height)
        self.renderTexture = lg.newImage(self.renderBuffer)

        self.renderView = love.filesystem.load(PATH.."/render_s.lua")()

    end

end

function Raycaster:setMap(map)
    self.map_width = #map[1]
    self.map_height = #map
    self.map = map
end

function Raycaster:posToMap(x,y)
    return math.floor(x), math.floor(y)
end

function Raycaster:setTextures(type, ...)

    if not self.textures[type] then -- If type is not defined then walls is default
        self:setTextures("walls", type, ...)
        return
    end

    -- Load textures --

    local textures = self.textures[type]
    local n = select("#", ...)

    for i = 1, n do

        local v = select(i, ...)

        if _G.type(v) == "string" then
            v = love.image.newImageData(v)
        end

        textures[i] = v

    end

    if self.texArrays[type] then
        self.texArrays[type]:release()
    end

    self.texArrays[type] = lg.newArrayImage(textures)

end

function Raycaster:getPlaneFromDir(dir_x, dir_y) -- Takes as input a direction to return its vector on the orthogonal plane from -0.66 to 0.66 (getPerpendicularVector)
    local length = math.sqrt(dir_x*dir_x + dir_y*dir_y)
    return (dir_y/length)*.66, (dir_x/length)*.66
end

function Raycaster:update(px, py, dir_x, dir_y, plane_x, plane_y)

    -- Define local self values --

    local abs = math.abs

    local num_rays = self.num_rays
    local screen_height = self.screen_height

    local map = self.map
    local o_map_x, o_map_y = self:posToMap(px,py)

    local rd = self.render_data
    rd.ground_tex_num = map[o_map_y][o_map_x]
    rd.plane[1], rd.plane[2] = plane_x, plane_y
    rd.dir[1], rd.dir[2] = dir_x, dir_y
    rd.pos[1], rd.pos[2] = px, py

    -- Perform raycasting --

    local j = 1 -- i: 9 by 9

    for i = 1, num_rays do

        local map_x, map_y = o_map_x, o_map_y       -- Initial position of the ray in the map table

        local cam_x = 2 * i / num_rays - 1          -- x coordinate in camera space
        local ray_dir_x = dir_x + plane_x * cam_x
        local ray_dir_y = dir_y + plane_y * cam_x

        -- We get the distance to the edge of the next cell --

        local dx = (ray_dir_x == 0) and 1e30 or 1/abs(ray_dir_x)
        local dy = (ray_dir_y == 0) and 1e30 or 1/abs(ray_dir_y)

        -- We calculate the initial step and the length to the side --

        local step_x, side_dist_x;
        local step_y, side_dist_y;

        if ray_dir_x < 0 then step_x, side_dist_x = -1, (px-map_x)*dx
        else step_x, side_dist_x = 1, (map_x+1-px)*dx end

        if ray_dir_y < 0 then step_y, side_dist_y = -1, (py-map_y)*dy
        else step_y, side_dist_y = 1, (map_y+1-py)*dy end

        -- We launch the ray --

        local side; repeat  -- DDA

            if side_dist_x < side_dist_y then
                side_dist_x = side_dist_x + dx
                map_x = map_x + step_x
                side = 0
            else
                side_dist_y = side_dist_y + dy
                map_y = map_y + step_y
                side = 1
            end

        until not map[map_y] or map[map_y][map_x] ~= 0;

        -- Add radius data to render_data table --

        local distance_to_wall = (side == 0)
            and side_dist_x - dx or side_dist_y - dy

        local wall_height = screen_height/distance_to_wall

        rd[j]    = px + ray_dir_x * distance_to_wall             -- HIT X
        rd[j+1]  = py + ray_dir_y * distance_to_wall             -- HIT Y
        rd[j+2]  = ray_dir_x                                     -- RAY DIR X
        rd[j+3]  = ray_dir_y                                     -- RAY DIR Y
        rd[j+4]  = distance_to_wall                              -- DIST TO WALL
        rd[j+5]  = i                                             -- WALL X
        rd[j+6]  = wall_height                                   -- WALL H
        rd[j+7]  = map[map_y][map_x]                             -- WALL TEX NUM
        rd[j+8]  = side                                          -- side

        j = j + 9

    end

end

function Raycaster:renderMap(x,y,w,h,tile_size)

    tile_size = tile_size or 32

    -- Define local self values --

    local map = self.map
    local map_width = self.map_width
    local map_height = self.map_height

    map_width = map_width * tile_size
    map_height = map_height * tile_size

    -- Define local render_data values --

    local rd = self.render_data
    local px, py = rd.pos[1]-1, rd.pos[2]-1

    lg.push()
    lg.translate(x,y)
    lg.scale(w/map_width, h/map_height)

        lg.setColor(.5,.5,.5)
        lg.rectangle("fill", 0, 0, map_width, map_height)

        -- Draw map --

        lg.setColor(.125,.125,.125)

        for ty, xs in ipairs(map) do
            for tx, value in ipairs(xs) do
                if value ~= 0 then
                    lg.rectangle("fill", (tx-1)*tile_size, (ty-1)*tile_size, tile_size, tile_size)
                end
            end
        end

        -- Draw rays --

        lg.setColor(1,0,0)

        for i = 1, #rd-8, 9 do
            lg.line(px*tile_size, py*tile_size, (rd[i]-1)*tile_size, (rd[i+1]-1)*tile_size)
        end

        -- Draw player position --

        lg.setColor(1,1,0)
        lg.circle("fill", px*tile_size, py*tile_size, tile_size*.25)

    lg.pop()

end

function Raycaster:resize(w,h,adjust_num_rays)

    if adjust_num_rays then

        local old_num_rays = self.num_rays
        self.num_rays = w * (self.num_rays/self.screen_width)

        if old_num_rays > self.num_rays then

            local rd = self.render_data

            for i = self.num_rays, old_num_rays do

                local j = i*9

                for k = 0, 10 do
                    rd[j+k] = nil
                end

            end

        end

    end

    self.screen_width, self.screen_height = w, h
    self.h_screen_width, self.h_screen_height = w*.5, h*.5

    if self.hardware_accel then

        self.frameBuffer:release()
        self.dataBuffer:release()
        self.dataBufferTexture:release()

        self.frameBuffer = love.graphics.newCanvas(self.screen_width, self.screen_height)
        self.dataBuffer = love.image.newImageData(self.screen_width, 2, "rgba16f")
        self.dataBufferTexture = love.graphics.newImage(self.dataBuffer)

    else

        self.renderBuffer:release()
        self.renderTexture:release()

        self.renderBuffer = love.image.newImageData(self.screen_width, self.screen_height)
        self.renderTexture = lg.newImage(self.renderBuffer)

    end

end


return Raycaster