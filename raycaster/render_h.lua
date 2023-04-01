local lg = love.graphics

return function (self)

    local rd = self.render_data
    local frameBuffer = self.frameBuffer
    local renderShader = self.renderShader
    local raysBufferTex = self.raysBufferTex
    local raysBuffer = self.raysBuffer

    -- Gen and send rays data buffer --

    local x = 0
    for i = 1, #rd-8, 9 do
        raysBuffer:setPixel(x, 0, rd[i], rd[i+1], rd[i+2], rd[i+3])     -- hit_x, hit_y, ray_dir_x, ray_dir_y
        raysBuffer:setPixel(x, 1, rd[i+6], rd[i+4], rd[i+8], rd[i+7]-1) -- wall_h, dist_to_wall, side, wall_tex_num
        x = x + 1
    end

    raysBufferTex:replacePixels(raysBuffer)
    renderShader:send("raysBuffer", raysBufferTex)

    -- Send player values --

    renderShader:send("pos", rd.pos)
    renderShader:send("dir", rd.dir)
    renderShader:send("plane", rd.plane)

    -- Render raycasting --

    lg.setShader(renderShader)
    lg.draw(frameBuffer)
    lg.setShader()

end