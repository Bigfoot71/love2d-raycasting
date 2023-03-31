local ffi = require("ffi")
local lg = love.graphics
local floor = math.floor
local max = math.max

ffi.cdef[[
    typedef struct {
        uint8_t r, g, b, a;
    } Pixel;
]]

local function getPixel(image, x, y) -- Faster than ImageData:getPixel()
    local ffi_pixel = ffi.cast("Pixel*", image:getFFIPointer())
    local pixel = ffi_pixel[floor(x)+floor(y)*image:getWidth()]
    return pixel.r/255, pixel.g/255, pixel.b/255, pixel.a/255
end

local function getShade(dist)
    return max(1 - (dist / 20), .15)
end

return function (self)

    local min = math.min

    local rd = self.render_data
    local textures = self.textures
    local screen_width = self.screen_width
    local screen_height = self.screen_height
    local h_screen_height = self.h_screen_height

    local renderBuffer = self.renderBuffer
    local renderTexture = self.renderTexture

    local draw_wall_lines = not self.texArrays.walls

    -- Draw sky (not textured) --

    lg.setColor(0,.1,.5)
    lg.rectangle("fill", 0,0,screen_width,h_screen_height)

    -- Draw ground (not textured) --

    for y = screen_height, h_screen_height, -1 do
        local shade = getShade((1-y/screen_height)*30)
        lg.setColor(0,.5*shade,.1*shade)
        lg.line(0,y,screen_width,y)
    end

    lg.setColor(1,1,1)

    -- Draw walls (textured) --

    if self.texArrays.walls then

        renderBuffer:mapPixel(function (x, y)

            local i = (x * 9) + 1
            local wall_tex = textures.walls[rd[i+7]]

            if wall_tex then

                local wall_h = rd[i+6]
                local wall_height_half = wall_h * 0.5
                local y_top = h_screen_height - wall_height_half
                local y_bottom = h_screen_height + wall_height_half

                if y >= y_top and y <= y_bottom then

                    -- Get values --

                    local tex_width, tex_height = wall_tex:getDimensions()
                    tex_width, tex_height = tex_width-1, tex_height-1

                    local hit_x, hit_y = rd[i], rd[i+1]
                    local wall_dist = rd[i+4]
                    local side = rd[i+8]

                    -- Calculate coords of pixel texture to shown --

                    local tex_coord_x = (side == 0) and hit_y%1 or hit_x%1
                    local tex_coord_y = (y - y_top) / wall_h

                    local r,g,b,a = getPixel(wall_tex,tex_coord_x * tex_width, tex_coord_y * tex_height)
                    local shade = getShade(wall_dist)

                    return r * shade, g * shade, b * shade, a

                end

            else
                draw_wall_lines = true
            end

            return 0, 0, 0, 0

        end)

        renderTexture:replacePixels(renderBuffer)
        lg.draw(renderTexture)

    end

    -- Line walls (not textured) --

    if draw_wall_lines then

        lg.setLineStyle("rough")

        for i = 1, #rd-8, 9 do

            local wall_tex = textures.walls[rd[i+7]]

            if not wall_tex then

                local x = rd[i+5]
                local h = rd[i+6]

                local wall_height_half = h * .5
                local y1 = -wall_height_half + h_screen_height
                local y2 = wall_height_half + h_screen_height

                local shade = min(h,screen_height)/screen_height

                lg.setColor(shade,shade,shade)
                lg.line(x, max(y1,0), x, min(y2,screen_height))

            end

        end

        lg.setLineStyle("smooth")

    end

end
