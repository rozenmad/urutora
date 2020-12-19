local modules = (...):gsub('%.[^%.]+$', '') .. '.'
local utils = require(modules .. 'utils')
local base_node = require(modules .. 'base_node')
local utf8 = require('utf8')

local lovg = love.graphics

local function remove_char(pos, str)
	local first_endpos = pos - 1
	if first_endpos < 0 then
		return utils.utf8sub(str, pos + 1)
	else
		return utils.utf8sub(str, 1, first_endpos) .. utils.utf8sub(str, pos + 1)
	end
end

local function insert_char(pos, str, r)
	r = r or ''
    return utils.utf8sub(str, 1, pos) .. r .. utils.utf8sub(str, pos+1)
end

local text = base_node:extend('text')

function text:constructor()
	self.padding = {0, 0}
	text.super.constructor(self)
	self.textAlign = utils.textAlignments.LEFT
	self.text = self.text or ''
	self.type = self.type or 'default'
	self.min = self.min or -math.huge
	self.max = self.max or  math.huge

	self.cursor_position = 0
	self.cursor_x = 0
end

function text:setText(s)
	text.super.setText(self, s)
	self.cursor_position = 0
	self:moveCursorPosition(self:getTextLength())
	return self
end

function text:focusLost()
	if self.type == 'number' then
		local n = tonumber(self.text) or self.min
		if type(n) == 'number' then
			if n < self.min then
				n = self.min
			elseif n > self.max then
				n = self.max
			end
			self.text = tostring(n)
		end
	end
	self.cursor_position = 0
	self:moveCursorPosition(self:getTextLength())
end

function text:draw()
	local _, fgc = self:getLayerColors()
	local y = self.y + self.h - 2
	local textY = self:centerY() - utils.textHeight(self) / 2
	lovg.setColor(utils.brighter(fgc))
	utils.line(self.x, y, self.x + self.w, y)

	if self.focused then
		utils.print('_', self.px + self.cursor_x, textY)
	end
end

function text:moveCursorPosition(offset)
	local new_position = self.cursor_position + offset
	if new_position >= 0 and new_position <= self:getTextLength() then
		self.cursor_position = new_position
	end

	local font = self.style.font or utils.default_font
	local t = utils.utf8sub(self.text, 1, self.cursor_position)
	self.cursor_x = font:getWidth(t)
end

function text:textInput(text, scancode)
	if scancode then
		if scancode == 'backspace' then
			self.text = remove_char(self.cursor_position, self.text)
			self:moveCursorPosition(-1)
		end
		if scancode == 'return' then
			self.focused = false
			self:focusLost()
		end
		if scancode == 'left' then
			self:moveCursorPosition(-1)
		end
		if scancode == 'right' then
			self:moveCursorPosition( 1)
		end
	elseif text then
		local new_text = insert_char(self.cursor_position, self.text, text)
		local font = self.style.font or utils.default_font
		if font:getWidth(new_text .. '_') <= self.npw then
			if self.type == 'number' then
				if type(tonumber(new_text)) ~= self.type then
					return
				end
			end

			self.text = new_text
			self:moveCursorPosition(1)
		end
	end
end

return text