local M = {}

local mode

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

local command = {
	['h'] = buffer.char_left,
	['j'] = buffer.line_down,
	['k'] = buffer.line_up,
	['l'] = buffer.char_right,
	['i'] = insert_mode,
}

keys['esc'] = command_mode

local key_meta = getmetatable(keys)
local tavi_meta = {}
setmetatable(keys,tavi_meta)

function tavi_meta.__index(table, key)
	if 'MODE' == key then
		return nil
	elseif mode == 'command' then
		return command[key] or update_ui
	else
		return key_meta and key_meta.__index and key_meta.__index(table,key)
	end
end

events.connect(events.UPDATE_UI, update_ui)

command_mode()

return M
