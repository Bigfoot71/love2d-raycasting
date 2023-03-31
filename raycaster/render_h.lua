local lg = love.graphics

return function (self)

    local rd = self.render_data
    local frameBuffer = self.frameBuffer
    local renderShader = self.renderShader
    local dataBufferTexture = self.dataBufferTexture
    local dataBuffer = self.dataBuffer

    local x = 0
    for i = 1, #rd-8, 9 do
        dataBuffer:setPixel(x, 0, rd[i], rd[i+1], rd[i+2], rd[i+3])     -- hit_x, hit_y, ray_dir_x, ray_dir_y
        dataBuffer:setPixel(x, 1, rd[i+6], rd[i+4], rd[i+8], rd[i+7])   -- wall_h, dist_to_wall, side, wall_tex_num
        x = x + 1
    end

    dataBufferTexture:replacePixels(dataBuffer)
    renderShader:send("dataBuffer", dataBufferTexture)

    renderShader:send("groundTexCount", #self.textures.ground)
    renderShader:send("groundTexNum", -rd.ground_tex_num+1)         -- the ground numbers are negative so we make them positive + 1 (because start at 0)

    if self.texArrays.ground then
        renderShader:send("groundTexs", self.texArrays.ground)
    end

    renderShader:send("wallTexCount", #self.textures.walls)

    if self.texArrays.walls then
        renderShader:send("wallTexs", self.texArrays.walls)
    end

    renderShader:send("pos", rd.pos)
    renderShader:send("dir", rd.dir)
    renderShader:send("plane", rd.plane)

    lg.setShader(renderShader)
    lg.draw(frameBuffer)
    lg.setShader()

end