local M = {}

local mode, modes

local function update_ui()
	ui.statusbar_text = mode..' mode'
end

local function command_mode()
	mode = 'command'
	buffer.caret_style = buffer.CARETSTYLE_BLOCK
	update_ui()
end

local function insert_mode()
	mode = 'insert'
	buffer.caret_style = buffer.CARETSTYLE_LINE
	update_ui()
end

--start in command mode by default
command_mode()

local function move_up(distance) --moves at least one unless at top
					distance = distance > 0 and distance or 1
					
					local first = buffer.first_visible_line
					first = first - distance
					first = first < 0 and 0 or first
					
					buffer.first_visible_line = first
					buffer:move_caret_inside_view()
end

--debug reminder thingie
function unimplemented() print('unimplemented') end

--[[the mode stuff built into the ta api allows unbound letters through
	but filters out things like ctrl-w and ctrl-s which is basically exactly
	opposite of what i want. so we are rolling our own.]]

local modes =
{
	command =
	{
		['cb']	=	function()
					move_up(buffer.lines_on_screen - 2)
				end,
		['cd']	=	function()
					move_up(math.floor(buffer.lines_on_screen/2))
				end,
		['h']	=	buffer.char_left,
		['j']	=	buffer.line_down,
		['k']	=	buffer.line_up,
		['l']	=	buffer.char_right,
		['i']	=	insert_mode,
	},
	insert =
	{
		['c@']	=	unimplemented,
		['cd']	=	function()
					buffer:back_tab()
				end,
		['esc']	=	command_mode
	}
}

--[[for some reason the following hacks let
	control keys through. i don't know why, but i'm
	not sweating it.]]
local tavi_meta = {}
setmetatable(keys,tavi_meta)

function tavi_meta.__index(table, key)
	--just ignore the builtin mode mechanism
	if 'MODE' == key then
		return nil
	elseif 'insert' == mode then
		return modes[mode][key] --don't filter out extra stuff in insert mode
	else
		return modes[mode][key] or update_ui
	end
end

--forward the control sequences we want to deal with
local function forward_factory(key) return function() modes[mode][key]() end end

keys['c@']	=	forward_factory('c@')
keys['cb']	=	forward_factory('cb')
keys['cd']	=	forward_factory('cd')

events.connect(events.UPDATE_UI, update_ui)

return M
