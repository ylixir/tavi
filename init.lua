--[[
keycodes intentionally not implemented:
	ctrl-g:	just not useful, all this info is already there
	ctrl-i: not easier to push than tab
	ctrl-m: enter (\n) has the same behavior
	ctrl-n: we already have ctrl-j
	ctrl-p: we have ctrl-k
	ctrl-r: we (probably) aren't using a 300 baud modem
	ctrl-t: i am unclear what the difference between this and tab is
	ctrl-v: we already have ctrl-q
	#			: although i may make it the vim 'q' since 'q' is super annoying in vim
keycodes intentionally changed:
	ctrl-h:	don't erase, backspace is easier to reach than right arrow
	ctrl-l: this is a relic, instead make it a movement like it should be
	ctrl-q: allows you to enter the unicode character in hex, this may change
	ctrl-z: the logical counterpart seems like the textadept command line
keycodes added:
	ctrl-k: if i'm doing hj and l then i should do k also
keycodes that need to be (re)implemented:
	ctrl-@
	ctrl-]
	ctrl-^
	!
	&
]]

local M = {}

--current and available modes
--local mode, modes

--all the action functions take one parameter, the key
local action

--the different modes
local command, insert

local count=0
local function count_add_digit(digit)
	count = count*10 + digit
end

local marks = {}

local function update_ui()
	--ui.statusbar_text = mode..' mode'
end
--[[
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
]]
local function move_up(distance) --moves at least one unless at top
	distance = distance > 0 and distance or 1

	local first = buffer.first_visible_line
	first = first - distance
	first = first < 0 and 0 or first

	buffer.first_visible_line = first
	buffer.move_caret_inside_view()
end
local function move_down(distance) --moves at least one unless at bottom
	distance = distance > 0 and distance or 1

	local first = buffer.first_visible_line
	first = first + distance

	buffer.first_visible_line = first
	buffer.move_caret_inside_view()
end

--debug reminder thingie
local function unimplemented() print('unimplemented') end

--clear any started key chain
local function clear_chain()
	count = 0
	action = command.action
end

--make a keys[mode] for entering unicode characters
keys.utf8_input = {['\n'] = {ui.command_entry.finish_mode, function(code)
	_G.buffer:add_text(utf8.char(tonumber(code, 16)))
end}}

--[[the mode stuff built into the ta api allows unbound letters through
	but filters out things like ctrl-w and ctrl-s which is basically exactly
	opposite of what i want. so we are rolling our own.]]
command =
{
	action = function(key)
	end,
	['cb']	=	function()
				move_up(buffer.lines_on_screen - 2)
			end,
	['cd']	=	function()
				move_down(math.floor(buffer.lines_on_screen/2))
			end,
	['ce']	=	buffer.line_scroll_down,
	['cf']	=	function()
				move_down(buffer.lines_on_screen - 2)
			end,
	['ch']	=	buffer.char_left,
	['cj']	=	buffer.line_down,
	['ck']	=	buffer.line_up,
	['cl']	=	buffer.char_right,
	['\n']	= function()
				buffer.line_down()
				buffer.home()
				buffer.vc_home()
			end,
	['cu']	=	function()
				move_up(math.floor(buffer.lines_on_screen/2))
			end,
	['cy']	=	buffer.line_scroll_up,
	['cz']	=	function()
				ui.command_entry.enter_mode('lua_command')
			end,
	['esc']	=	clear_chain,
	['c[']	=	clear_chain,
	[' ']	=	buffer.char_right,
	['$']	= buffer.line_end,
	['%']	= textadept.editing.match_brace,
	['h']	=	buffer.char_left,
	['i']	=	insert_mode,
	['j']	=	buffer.line_down,
	['k']	=	buffer.line_up,
	['l']	=	buffer.char_right,
	['m']	=	function()
			end,
	['0']	= function()
				if 0 < count then
					count_add_digit(0)
				else
					buffer.vc_home()
				end
			end,
	['1']	= function() count_add_digit(1) end,
	['2']	= function() count_add_digit(2) end,
	['3']	= function() count_add_digit(3) end,
	['4']	= function() count_add_digit(4) end,
	['5']	= function() count_add_digit(5) end,
	['6']	= function() count_add_digit(6) end,
	['7']	= function() count_add_digit(7) end,
	['8']	= function() count_add_digit(8) end,
	['9']	= function() count_add_digit(9) end,
}
insert =
{
	action = function(key)
	end,
	['c@']	=	unimplemented,
	['cd']	=	buffer.back_tab,
	['cq']	=	function()
				ui.statusbar_text = 'Enter 4 digit unicode character code'
				ui.command_entry.enter_mode('utf8_input')
			end,
	['cw']	=	buffer.del_word_left,
	['esc']	=	command_mode,
	['c[']	= command_mode,
}


--shared keycodes
for _,v in ipairs({'cb','ce','cf','ch','cj','ck','cl','cu','cy','cz'}) do
	modes.insert[v]=modes.command[v]
end

--for some reason the metatable hacks let control keys through.
--i don't know why, but i can just 'forward' the ones i care about
for _,v in ipairs({
		'c@',	'cb',	'cd',	'ce',	'cf',	'ch',	'cj',	'ck',	'cl',	'cq',	'cu',	'cw',
		'cy',	'cz',	'c['
		}) do
	keys[v] = function()
							f = modes[mode][v]
							return f and f()
						end
end

local function command_action(key)
end

local function insert_action()
end

--start in command mode by default
--command_mode()
action = command_action

local tavi_meta = {}
setmetatable(keys,tavi_meta)

function tavi_meta.__index(table, key)
	--just ignore the builtin mode mechanism
	if 'MODE' == key then
		return nil
	else
		return action
	end
end

events.connect(events.UPDATE_UI, update_ui)

return M
