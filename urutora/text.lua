local modules = (...):gsub('%.[^%.]+$', '') .. '.'
local utils = require(modules .. 'utils')
local base_node = require(modules .. 'base_node')
local utf8 = require('utf8')

local lovg = love.graphics

local text = base_node:extend('text')

function text:constructor()
	self.padding = {0, 0}
	text.super.constructor(self)
	self.textAlign = utils.textAlignments.LEFT
	self.text = self.text or ''
	self.type = self.type or 'default'
	self.min = self.min or -math.huge
	self.max = self.max or  math.huge
end

function text:focusLost()
	if self.type == 'number' then
		local n = tonumber(self.text) or self.min
		if type(n) == 'number' then
			if n < self.min then n = tostring(self.min) end
			if n > self.max then n = tostring(self.max) end
			self.text = tostring(n)
		end
	end
end

function text:draw()
	--local _, fgc = self:getLayerColors()
	local y = self.y + self.h - 2
	local textY = self:centerY() - utils.textHeight(self) / 2
	lovg.setColor(self.style.outlineColor)
	utils.line(self.x, y, self.x + self.w, y)

	if self.focused then
		utils.print('_', self.px + utils.textWidth(self), textY)
	end
end

function text:textInput(text, scancode)
	if scancode == 'backspace' then
		local byteoffset = utf8.offset(self.text, -1)
		if byteoffset then
			self.text = string.sub(self.text, 1, byteoffset - 1)
		end
	else
		local new_text = self.text .. (text or '')
		local font = self.style.font or utils.default_font
		if font:getWidth(new_text .. '_') <= self.npw then
			if self.type == 'default' then
				self.text = new_text
			elseif self.type == 'number' then
				local n = tonumber(new_text)
				if type(n) == 'number' then
					self.text = new_text
				end
			end
		end
	end

	if scancode == 'return' then
		self.focused = false
		self:focusLost()
	end
end

return text