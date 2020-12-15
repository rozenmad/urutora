local modules = (...):gsub('%.[^%.]+$', '') .. '.'
local class = require(modules .. 'class')
local utils = require(modules .. 'utils')

local lovg = love.graphics

local base_node = class('base_node')

function base_node:constructor()
	self.callback = function () end
	self.textAlign = self.textAlign or utils.textAlignments.CENTER

	self.style = utils.style

	self.bounds_calculated = false

	self.enabled = true
	self.visible = true
	self.padding = self.padding or utils.default_font:getHeight() / 2

	self.x = self.x or 1
	self.y = self.y or 1
	self.w = self.w or 16
	self.h = self.h or 16
	self.px = self.x
	self.py = self.y
	self.npw = self.w
	self.nph = self.h
end

function base_node:centerX()
	return self.x + self.w / 2
end
function base_node:centerY()
	return self.y + self.h / 2
end

function base_node:setBounds(x, y, w, h)
	local f = utils.default_font

	local pxa, pya
	if type(self.padding) == 'table' then
		pxa = self.padding[1]
		pya = self.padding[2]
	else
		pxa = self.padding
		pya = pxa
	end

	self.x = x
	self.y = y
	self.w = w or f:getWidth(self.text) + pxa * 2
	self.h = h or f:getHeight() + pya * 2
	self.px  = self.x + pxa
	self.py  = self.y + pya
	self.npw = self.w - pxa * 2
	self.nph = self.h - pya * 2

	local text = tostring(self.text)
	if self.text and #text > 0 then
		self:setText(text)
	else
		self._tx = 0
		self._ty = 0
		self.line_limit = self.npw
	end

	self.bounds_calculated = true
end

function base_node:setStyle(style, lock)
	if self.style.lock and not lock then return self end

	local t = { lock = lock }
	for k, v in pairs(self.style) do
		t[k] = v
	end
	for k, v in pairs(style) do
		t[k] = v
	end
	self.style = t
	return self
end

function base_node:setEnabled(value)
	self.enabled = value
	return self
end

function base_node:setVisible(value)
	self.visible = value
	return self
end

function base_node:activate()
	self:setEnabled(true)
	self:setVisible(true)
	return self
end

function base_node:deactivate()
	self:setEnabled(false)
	self:setVisible(false)
	return self
end

function base_node:disable()
	self:setEnabled(false)
	return self
end
function base_node:enable()
	self:setEnabled(true)
	return self
end

function base_node:hide()
	self:setVisible(false)
	return self
end
function base_node:show()
	self:setVisible(true)
	return self
end

function base_node:action(f)
	if type(f) == 'function' then
		self.callback = f
	end
	return self
end

function base_node:left()
	self.textAlign = utils.textAlignments.LEFT
	return self
end

function base_node:center()
	self.textAlign = utils.textAlignments.CENTER
	return self
end

function base_node:right()
	self.textAlign = utils.textAlignments.RIGHT
	return self
end

function base_node:pointInsideNode(x, y)
	local parent = self.parent
	local ox, oy = 0, 0
	if parent then
		ox, oy = parent:_get_scissor_offset()
	end

	return utils.pointInsideRect(x, y, self.x - ox, self.y - oy, self.w, self.h)
end

function base_node:getLayerColors()
	local bgColor, fgColor
	if not self.enabled then
		bgColor = self.style.disablebgColor
		fgColor = self.style.disablefgColor
	else
		if self.pressed then
			bgColor = self.style.pressedbgColor or utils.darker(self.style.bgColor)
			fgColor = self.style.pressedfgColor or self.style.fgColor
		elseif self.pointed then
			bgColor = self.style.hoverbgColor or utils.brighter(self.style.bgColor)
			fgColor = self.style.hoverfgColor or self.style.fgColor
		else
			bgColor = self.style.bgColor
			fgColor = self.style.fgColor
		end
	end
	return bgColor, fgColor
end

function base_node:drawBaseRectangle(color, ...)
	local bgc, _ = self:getLayerColors()
	lovg.setColor(color or bgc)
	local x, y, w, h = self.x, self.y, self.w, self.h

	if ... then x, y, w, h = ... end
	utils.rect('fill', x, y, w, h)
end

function base_node:setText(text)
	text = text or ''
	local font = self.style.font or utils.default_font

	local lines = math.ceil(self.nph / font:getHeight())
	local _, wrappedtext = font:getWrap(text, self.npw)
	lines = (#wrappedtext < lines) and #wrappedtext or lines
	text = table.concat(wrappedtext, '\n', 1, lines)

	local sy = lines * font:getHeight()

	self._tx = 0
	self._ty = (self.nph - sy) / 2

	self.text = text
	self.line_limit = self.npw
end

function base_node:drawText(color)
	local text = self.text

	if (not text) or (#tostring(text) == 0) then
		return
	end

	local align = 'center'
	if self.textAlign == utils.textAlignments.LEFT then
		align = 'left'
	elseif self.textAlign == utils.textAlignments.RIGHT then
		align = 'right'
	end

	local x = math.floor(self.px)
	local y = math.floor(self.py)
	local _, fgc = self:getLayerColors()
	lovg.setFont(self.style.font or utils.default_font)
	lovg.setColor(color or fgc)
	love.graphics.printf(self.text, x + self._tx, y + self._ty, self.line_limit, align)
end

function base_node:drawOutline()
	if self.outline then
		lovg.setColor(self.style.outlineColor)
		utils.rect('line', self.x, self.y, self.w, self.h)
	end
end

function base_node:performPressedAction(data)
	if not self.enabled then return end

	local urutora = data.urutora
	if self.pointed then
		self.pressed = true
		urutora.focused_node = self

		-- special cases
		if utils.isSlider(self) then
			self:update()
			self.callback({ target = self, value = self.value })
		end
	end
end

function base_node:performKeyboardAction(data)
	if self.node_type == utils.nodeTypes.TEXT then
		if self.focused then
			local previousText = self.text
			self:textInput(data.text, data.scancode)
			self.callback({ target = self, value = {
				previousText = previousText,
				newText = self.text,
				scancode = data.scancode,
				textAdded = data.text
			}})
		end
	end
end

function base_node:performMovedAction(data)
	if not self.enabled then return end

	if self.node_type == utils.nodeTypes.SLIDER then
		if self.focused then
			self.callback({ target = self, value = self.value })
		end
	elseif self.node_type == utils.nodeTypes.JOY then
		if self.pressed then
			self.joyX = self.joyX + data.dx / utils.sx
			self.joyY = self.joyY + data.dy / utils.sy
			self:limitMovement()
		end
	end
end

function base_node:performReleaseAction(data)
	if not self.enabled then return end

	if self.pressed then
		if self.pointed then
			if self.node_type == utils.nodeTypes.BUTTON then
				self.callback({ target = self })
			elseif self.node_type == utils.nodeTypes.TOGGLE then
				self:change()
				self.callback({ target = self, value = self.value })
			elseif self.node_type == utils.nodeTypes.MULTI then
				self:change()
				self.callback({ target = self, value = self.text })
			end
		end

		if self.node_type == utils.nodeTypes.JOY then
			self.callback({ target = self, value = {
				lastX = self.joyX,
				lastY = self.joyY
			}})
			self.joyX, self.joyY = 0, 0
		end
	end

	self.pressed = false
end

function base_node:performMouseWheelAction(data)
	if not self.enabled then return end

	if self.pointed then
		if self.node_type == utils.nodeTypes.PANEL then
			local v = self:getScrollY()
			self:setScrollY(v + (-data.y) * utils.scroll_speed)
		elseif self.node_type == utils.nodeTypes.SLIDER then
			self:setValue(self.value + (-data.y) * utils.scroll_speed)
			self.callback({ target = self, value = self.value })
		end
	end
end

return base_node