-- ~/.config/nvim/lua/tagcomplete.lua
-- Simple tag completer: converts .tag -> <tag></tag>
-- Works in both Normal and Insert mode via a key (default <leader>.)
-- Places the cursor neatly between the opening and closing tags.

local M = {}

---Return .tag under or just before the cursor, and its start & end indices (0-based).
---@return string|nil word, number start_col, number end_col
local function current_word_and_range()
	local line = vim.api.nvim_get_current_line()
	local col = vim.api.nvim_win_get_cursor(0)[2] + 1 -- Lua strings are 1-based

	-- Look backward from cursor for a .tag pattern
	local s, e = line:sub(1, col):find("%.[%w%-_]+$")
	if not s then
		return nil
	end

	local word = line:sub(s, e)
	return word, s - 1, e - 1 -- convert to 0-based columns
end

---Expand .tag into <tag></tag> and put cursor between > <
function M.expand_tag()
	local word, s, e = current_word_and_range()
	if not word or not word:match("^%.[%w%-_]+$") then
		vim.notify("No .tag under cursor", vim.log.levels.INFO)
		return
	end

	local tag = word:sub(2) -- drop leading dot
	local replacement = string.format("<%s></%s>", tag, tag)

	-- update current line
	local line = vim.api.nvim_get_current_line()
	local before = line:sub(1, s)
	local after = line:sub(e + 2)
	vim.api.nvim_set_current_line(before .. replacement .. after)

	-- move cursor just inside the opening tag
	local row = vim.api.nvim_win_get_cursor(0)[1]
	local new_col = s + #tag + 2
	vim.api.nvim_win_set_cursor(0, { row, new_col })

	if vim.fn.mode() == "i" then
		vim.cmd("startinsert")
	end
end

---Set up keymaps; call from init.lua with require('tagcomplete').setup{}
---@param opts table|nil { key = '<leader>.' }
function M.setup(opts)
	opts = opts or {}
	local key = opts.key or "<leader>."
	vim.keymap.set({ "n", "i" }, key, function()
		if vim.fn.mode() == "i" then
			vim.schedule(function()
				vim.cmd("stopinsert")
				M.expand_tag()
			end)
		else
			M.expand_tag()
		end
	end, { desc = "Expand .tag to <tag></tag>" })
end

return M
