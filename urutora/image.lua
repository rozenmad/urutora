local modules = (...):gsub('%.[^%.]+$', '') .. '.'
local base_node = require(modules .. 'base_node')

local lovg = love.graphics

local image = base_node:extend('image')

function image:constructor()
	image.super.constructor(self)
	if self.keep_aspect_ratio == nil then self.keep_aspect_ratio = true end
	if self.scaling == nil then self.scaling = true end
end

function image:calculatePosition()
	local image_w, image_h = self.image:getDimensions()
	local ox, oy = self.x, self.y
	local sx, sy
	if not self.scaling then
		sx = 1
		sy = 1
	else
		sx = (self.w - 1) / image_w
		sy = (self.h - 1) / image_h
	end

	if self.keep_aspect_ratio then
		sx = math.min(sx, sy)
		sy = sx
		ox = ox + (self.w - (image_w * sx)) / 2
		oy = oy + (self.h - (image_h * sy)) / 2
	end

	self.sx = sx
	self.sy = sy
	self.ox = ox
	self.oy = oy
end

function image:draw()
	if self.image then
		local _, fgc = self:getLayerColors()
		lovg.setColor(1, 1, 1, 1)
		self:calculatePosition()

		lovg.draw(self.image, self.ox, self.oy, 0, self.sx, self.sy)
	end
end

return image