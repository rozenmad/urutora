local utf8 = require('utf8')

local utils = {
	default_font = love.graphics.newFont(14),
	nodeTypes = {
		LABEL 	= 1,
		BUTTON 	= 2,
		SLIDER 	= 3,
		TOGGLE 	= 4,
		TEXT 	= 5,
		MULTI 	= 6,
		PANEL 	= 7,
		JOY 	= 8,
		IMAGE   = 9
	},
	textAlignments = {
		LEFT	= 'left',
		CENTER 	= 'center',
		RIGHT 	= 'right'
	},
	sx = 1,
	sy = 1,
	scroll_speed = 0.05,
}

function utils.isLabel(node) return node.node_type == utils.nodeTypes.LABEL end
function utils.isPanel(node) return node.node_type == utils.nodeTypes.PANEL end
function utils.isMulti(node) return node.node_type == utils.nodeTypes.MULTI_OPTION end
function utils.isImage(node) return node.node_type == utils.nodeTypes.IMAGE end
function utils.isToggle(node) return node.node_type == utils.nodeTypes.TOGGLE end
function utils.isSlider(node) return node.node_type == utils.nodeTypes.SLIDER end
function utils.isButton(node) return node.node_type == utils.nodeTypes.BUTTON end
function utils.isTextField(node) return node.node_type == utils.nodeTypes.TEXT end
function utils.isJoy(node) return node.node_type == utils.nodeTypes.JOY end

function utils.textWidth(node)
	if not node.text then return 0 end
	local font = node.style.font or utils.default_font
	return font:getWidth(tostring(node.text))
end
function utils.textHeight(node)
	if not node.text then return 0 end
	local font = node.style.font or utils.default_font
	return font:getHeight()
end

function utils.utf8sub(s, i, j)
	local length = utf8.len(s) + 1
	if not length then return nil end
	i = i or  1
	j = j or -1
	if j < 0 then j = length + j end
	if i < 0 then i = length + i end
	if i > j then return '' end

	i = utf8.offset(s, i)
	j = utf8.offset(s, j + 1)

	if i and j then
		return s:sub(i, j-1)
	elseif i then
		return s:sub(i)
	else
		return ""
	end
end

function utils.toRGB(hex)
	local hex = hex:gsub("#", "")
	local color = {
		tonumber("0x" .. hex:sub(1, 2)) / 255,
		tonumber("0x" .. hex:sub(3, 4)) / 255,
		tonumber("0x" .. hex:sub(5, 6)) / 255
	}
	return color
end

function utils.darker(color, amount)
	amount = 1 - (amount or 0.2)
	local r, g, b = color[1], color[2], color[3]
	r = r * amount
	g = g * amount
	b = b * amount

	return { r, g, b, color[4] }
end

function utils.brighter(color, amount)
	amount = amount or 0.2
	local r, g, b = color[1], color[2], color[3]
	r = r + ((1 - r) * amount)
	g = g + ((1 - g) * amount)
	b = b + ((1 - b) * amount)

	return { r, g, b, color[4] }
end

utils.colors = {
	BLACK = utils.toRGB('#000000'),
	WHITE = utils.toRGB('#ffffff'),
	GRAY = utils.toRGB('#666666'),
	DARK_GRAY = utils.toRGB('#333333'),
	LOVE_BLUE = utils.toRGB('#599ddc'),
	LOVE_BLUE_LIGHT = utils.toRGB('#63aff5'),
	RED = utils.toRGB('#ac3232'),
}

utils.style = {
	bgColor = utils.colors.LOVE_BLUE,
	fgColor = utils.colors.WHITE,
	disablebgColor = utils.colors.GRAY,
	disablefgColor = utils.colors.DARK_GRAY,
	outlineColor = utils.colors.LOVE_BLUE_LIGHT,
}

function utils.withOpacity(color, alpha)
	local newColor = { unpack(color) }
	table.insert(newColor, alpha)

	return newColor
end

function utils.needsBase(node)
	return not (
		utils.isPanel(node) or
		utils.isLabel(node) or
		utils.isTextField(node) or
		utils.isJoy(node) or
		utils.isImage(node)
	)
end

function utils.print(text, x, y)
	love.graphics.print(text, math.floor(x), math.floor(y))
end

function utils.rect(mode, a, b, c, d)
	love.graphics.rectangle(mode, math.floor(a), math.floor(b), math.floor(c), math.floor(d))
end

function utils.line(a, b, c, d)
	love.graphics.line(math.floor(a), math.floor(b), math.floor(c), math.floor(d))
end

function utils.circ(mode, a, b, c)
	love.graphics.circle(mode, math.floor(a), math.floor(b), math.floor(c))
end

function utils.getMouse()
	return love.mouse.getX() / utils.sx, love.mouse.getY() / utils.sy
end

function utils.pointInsideRect(px, py, x, y, w, h)
	return not (
		px < (x) or
		px > (x + w) or
		py < (y) or
		py > (y + h)
	)
end

return utils