local config = require("commentary.config")
Config = {}
local M = {}

-- A primary call out function to decide which comment out function to run
M.go = function(...)
	local arg = { ... }

	local language = Config.languages[vim.bo.filetype]
	-- this set opertorfunc, which is the function that will be called after a motion e.g. "gcj5"
	-- The process will be as follow: typing gc will set the operatorfunc and return g@,
	-- if you now do a motion like 5j, then the operatorfunc gets called.
	if arg[1] == "motion" then
		vim.api.nvim_set_option("operatorfunc", "v:lua.commentary.go")
		return "g@"
	end

	local mode = vim.api.nvim_get_mode().mode
	if mode == "n" then
		-- normal mode
		M.comment_in_line(vim.api.nvim_win_get_cursor(0)[1], language)
	elseif mode == "no" then
		-- motion mode
		-- When using g@, the marks [ and ] will contain the position of the
		-- start and the end of the motion, respectively. vim.fn.getpos() returns
		-- a tuple with the line and column of the position.
		if language[3] then
			M.multiline_comment_in_multi_line(vim.fn.getpos("'[")[2], vim.fn.getpos("']")[2], language)
		else
			M.comment_in_multi_single_line(vim.fn.getpos("'[")[2], vim.fn.getpos("']")[2], language)
		end
	elseif mode == "v" then
		-- visual mode
		M.comment_in_line(vim.fn.getpos("v")[2], language)
		-- switch from visual mode to normal mode
		vim.api.nvim_input("<esc>")
	elseif mode == "V" then
		-- Visual mode
		-- the index 3 is the prefer_multiline boolean
		if language[3] then
			M.multiline_comment_in_multi_line(vim.fn.getpos("v")[2], vim.fn.getcurpos()[2], language)
		else
			M.comment_in_multi_single_line(vim.fn.getpos("v")[2], vim.fn.getcurpos()[2], language)
		end
		-- switch from visual mode to normal mode
		vim.api.nvim_input("<esc>")
	end
end

-- Function to setup the required commands
-- @param languages table
-- @param use_default_mappings bool (optional, defaut:true)
M.setup = function(opts)
	opts = opts or {}

	vim.validate({
		languages = { opts.languages, "t", true },
	})

	Config = config.set_opts(opts.languages)

	vim.api.nvim_set_keymap("x", "<Plug>commentary", [[<Cmd>lua require"commentary".go()<CR>]], { noremap = true })
	vim.api.nvim_set_keymap(
		"n",
		"<Plug>commentary",
		[[<Cmd>lua require"commentary".go()<CR>]],
		{ noremap = true, silent = true }
	)
	-- You can use the <expr> attribute to a map command to invoke a Vim function and use the returned value as the key sequence to execute.
	-- This way will help use capture the motion
	vim.api.nvim_set_keymap(
		"n",
		"<Plug>commentary_motion",
		"v:lua.commentary.go('motion')",
		{ noremap = true, expr = true }
	)

	local use_default_mappings = opts.use_default_mappings and opts.use_default_mappings or true

	if use_default_mappings then
		vim.api.nvim_set_keymap("x", "gc", "<Plug>commentary", { silent = true })
		vim.api.nvim_set_keymap("n", "gcc", "<Plug>commentary", { silent = true })
		vim.api.nvim_set_keymap("n", "gc", "<Plug>commentary_motion", { silent = true })
	end
end

M.use_default_mappings = function()
	-- Https://www.reddit.com/r/neovim/comments/ord878/how_to_map_command_with_nargs_range_to_a_lua/
	-- Vim.api.nvim_command(
	-- 	[[command! -range -bar Commentary call luaeval("require'commentary'.go(_A)",[<line1>,<line2>])]]
	-- )
	vim.api.nvim_set_keymap("x", "gc", "<Plug>commentary", { silent = true })
	vim.api.nvim_set_keymap("n", "gcc", "<Plug>commentary", { silent = true })
	vim.api.nvim_set_keymap("n", "gc", "<Plug>commentary_motion", { silent = true })
end

-- Verify if the line has been commented or not
-- @param content string
-- @param language table
-- @return boolean
function M.is_comment_single(content, language)
	-- get the single comment string from the table
	local comment_string = language[1]
	content = vim.trim(content)
	-- check if the content contains the comment string
	return content:sub(1, #comment_string) == comment_string
end

-- Comment/Uncomment a single line
-- @line_number int
-- @language table
function M.comment_in_line(line_number, language)
	-- get the content from this line_number
	local content = vim.api.nvim_buf_get_lines(0, line_number - 1, line_number, false)[1]

	-- if content is nil or empty, then ignore the request
	if content == nil or content == "" then
		return vim.trim(content)
	end

	-- look for the whitespaces
	local start_index = string.find(content, "%S")
	local comment_string = language[1]

	start_index = start_index == nil and 1 or start_index

	-- comment/uncomment the line
	-- commenting will append whitespaces + comment string + original content
	-- uncommenting will append whitespaces + content
	local lines = M.is_comment_single(content, language)
			and {
				string.sub(content, 0, start_index - 1) .. string.sub(content, start_index + #comment_string, #content),
			}
		or {
			string.sub(content, 0, start_index - 1) .. comment_string .. (string.sub(content, start_index, #content)),
		}

	vim.api.nvim_buf_set_lines(0, line_number - 1, line_number, false, lines)
end

-- Veirfy if the specified is a rage of single-line comments
-- @param line_number_start int
-- @param line_number_end int
-- @param language table
-- @return boolean
function M.is_comment_multi_single(line_number_start, line_number_end, language)
	local content = vim.api.nvim_buf_get_lines(0, line_number_start - 1, line_number_end, false)
	for _, line in pairs(content) do
		if not M.is_comment_single(line, language) then
			if string.match(line, "%S") ~= nil then
				return false
			end
		end
	end

	return true
end

-- Comment out multiple single lines
-- @param line_number_start int
-- @param line_number_end int
-- @param language table
function M.comment_in_multi_single_line(line_number_start, line_number_end, language)
	local content = vim.api.nvim_buf_get_lines(0, line_number_start - 1, line_number_end, false)

	--low_index is to get the index position of a whitespace that has shortest indent
	--and we use this index to prepend the comment string
	local low_index
	local is_comment = M.is_comment_multi_single(line_number_start, line_number_end, language)
	--loop throught the content to get the lowest index
	for _, line in pairs(content) do
		local current_index = string.find(line, "%S")
		current_index = current_index == nil and 1 or current_index
		if low_index == nil or current_index < low_index then
			low_index = current_index
		end
	end

	local new_content = {}
	local comment_string = language[1]
	--loop through the conent to modify the string
	for _, line in ipairs(content) do
		local new_line = is_comment
				and string.sub(line, 0, low_index - 1) .. string.sub(
					line,
					low_index + #comment_string,
					#line
				)
			or string.sub(line, 0, low_index - 1) .. comment_string .. " " .. (string.sub(line, low_index, #line))

		table.insert(new_content, new_line)
	end
	vim.api.nvim_buf_set_lines(0, line_number_start - 1, line_number_end, false, new_content)
end

-- Check if the textobject is commented out by multiline comment strings
-- @param content table
-- @param language table
-- @return boolean
function M.is_multiline_comment(content, language)
	local comment_string_open = language[2][1]
	local comment_string_close = language[2][2]

	if vim.trim(content[1]) == comment_string_open and vim.trim(content[#content]) == comment_string_close then
		return true
	end

	return false
end

-- Use multiline comment strings to comment out a block of code
-- @param line_number_start int
-- @param line_number_end int
-- @param language table
function M.multiline_comment_in_multi_line(line_number_start, line_number_end, language)
	local content = vim.api.nvim_buf_get_lines(0, line_number_start - 1, line_number_end, false)

	local new_content = {}
	local comment_string_open = language[2][1]
	local comment_string_close = language[2][2]
	local is_multiline_comment = M.is_multiline_comment(content, language)

	if is_multiline_comment then
		table.remove(content, 1)
		table.remove(content, #content)
		new_content = content
	else
		-- low_index is to get the line that has shortest indent space prefix
		-- then prepend the same indent space with the comment string
		local low_index
		-- loop through each line to get the shortest indent space
		for _, line in pairs(content) do
			local current_index = string.find(line, "%S")
			current_index = current_index == nil and 1 or current_index
			if low_index == nil or current_index < low_index then
				low_index = current_index
			end
		end

		for index, line in ipairs(content) do
			if index == 1 then
				local new_line = string.sub(line, 0, low_index - 1) .. comment_string_open
				table.insert(new_content, new_line)
			end

			table.insert(new_content, line)

			if index == #content then
				local new_line = string.sub(line, 0, low_index - 1) .. comment_string_close
				table.insert(new_content, new_line)
			end
		end
	end
	vim.api.nvim_buf_set_lines(0, line_number_start - 1, line_number_end, false, new_content)
end

return M
