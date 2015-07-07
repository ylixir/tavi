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

--catchall
keys['esc'] = command_mode

--debug reminder thingie
function unimplemented() print('unimplemented') end

--start in command mode by default
command_mode()


--[[the mode stuff built into the ta api allows unbound letters through
	but filters out things like ctrl-w and ctrl-s which is basically exactly
	opposite of what i want. for some reason the following hacks let
	control keys through. i don't know why, but it's what i want, so i'm
	not sweating it.]]

local modes =
{
	command =
	{
		['cb']	=	function()
					buffer:page_up()
					if 3 >= buffer.lines_on_screen then
						buffer:line_scroll_down()
						buffer:line_scroll_donw()
					end
				end,
		--todo move caret into view
		['cd']	=	function()
					local half = math.floor(buffer.lines_on_screen/2)
					half = half or 1
					buffer.first_visible_line =
						buffer.first_visible_line + half
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
				end
	}
}

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

--control sequences, just forward as required
keys['c@']	=	function() modes[mode]['c@']() end
keys['cb']	=	function() modes[mode]['cb']() end
keys['cd']	=	function() modes[mode]['cd']() end

events.connect(events.UPDATE_UI, update_ui)

return M
