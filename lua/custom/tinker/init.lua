---@diagnostic disable: undefined-global
local M = {}

local config = {
	auto_scroll = true,
	split_direction = "vertical",
	split_ratio = 0.5,
	tinker_dir = vim.fn.expand("~/.config/mytinker"),
	docker_command = nil, -- Custom docker command, or nil for auto-detect
}

-- State management
local state = {
	tinker_job_id = nil,
	code_buffer = nil,
	output_buffer = nil,
	code_window = nil,
	output_window = nil,
	is_open = false,
	accumulated_output = {},
	project_file = nil, -- Path to project-specific tinker file
	previous_win = nil, -- Window to return to when hiding
	previous_buf = nil, -- Buffer to return to when hiding
}

-- Get project-specific file path
local function get_project_file()
	local cwd = vim.fn.getcwd()
	local home = vim.fn.expand("~")
	
	-- Remove home prefix and convert to relative path
	local relative_path = cwd:gsub("^" .. home .. "/", "")
	
	-- Create file path: ~/.config/mytinker/repos/assetplan/Backoffice.php
	local file_path = config.tinker_dir .. "/" .. relative_path .. ".php"
	
	return file_path
end

-- Ensure directory exists for file
local function ensure_dir(file_path)
	local dir = vim.fn.fnamemodify(file_path, ":h")
	if vim.fn.isdirectory(dir) == 0 then
		vim.fn.mkdir(dir, "p")
	end
end

-- Load content from project file
local function load_project_file()
	local file_path = get_project_file()
	
	if vim.fn.filereadable(file_path) == 1 then
		local file = io.open(file_path, "r")
		if file then
			local content = file:read("*all")
			file:close()
			return vim.split(content, "\n", { plain = true })
		end
	end
	
	-- Return default content if file doesn't exist
	return {
		"<?php",
		"",
	}
end

-- Save content to project file
local function save_project_file()
	if not state.code_buffer or not vim.api.nvim_buf_is_valid(state.code_buffer) then
		return
	end
	
	local file_path = get_project_file()
	ensure_dir(file_path)
	
	local lines = vim.api.nvim_buf_get_lines(state.code_buffer, 0, -1, false)
	
	local file = io.open(file_path, "w")
	if file then
		file:write(table.concat(lines, "\n"))
		file:close()
	end
end

-- Detect if current directory is a Laravel project
local function is_laravel_project()
	local composer_json = vim.fn.getcwd() .. "/composer.json"
	if vim.fn.filereadable(composer_json) == 0 then
		return false
	end

	local file = io.open(composer_json, "r")
	if not file then
		return false
	end

	local content = file:read("*all")
	file:close()

	-- Check if laravel/framework is in the dependencies
	return content:match('"laravel/framework"') ~= nil
end

-- Parse mode from buffer comments
-- Looks for comments like: // mode:docker, // mode:sail, // mode:docker-compose
local function parse_mode_from_buffer()
	if not state.code_buffer or not vim.api.nvim_buf_is_valid(state.code_buffer) then
		return nil
	end
	
	-- Check first 5 lines for mode comment
	local lines = vim.api.nvim_buf_get_lines(state.code_buffer, 0, 5, false)
	for _, line in ipairs(lines) do
		local mode = line:match("^//+%s*mode:%s*(.+)$")
		if mode then
			return vim.trim(mode)
		end
	end
	
	return nil
end

-- Get tinker command based on mode
local function get_tinker_command()
	local mode = parse_mode_from_buffer()
	
	-- If user provided custom docker command in config, use it
	if config.docker_command then
		return vim.split(config.docker_command, " ")
	end
	
	-- If no mode, run locally
	if not mode then
		return { "php", "artisan", "tinker" }
	end
	
	-- Mode-based commands
	if mode == "docker" then
		-- Generic docker-compose with 'app' container
		return { "docker-compose", "exec", "app", "php", "artisan", "tinker" }
	elseif mode == "sail" then
		-- Laravel Sail
		return { "./vendor/bin/sail", "tinker" }
	elseif mode:match("^docker%-compose:(.+)$") then
		-- Custom docker-compose container: // mode:docker-compose:web
		local container = mode:match("^docker%-compose:(.+)$")
		return { "docker-compose", "exec", container, "php", "artisan", "tinker" }
	elseif mode:match("^docker:(.+):(.+)$") then
		-- Direct docker exec with path: // mode:docker:dev-kit-php81-1:/var/www/backoffice
		local container, workdir = mode:match("^docker:(.+):(.+)$")
		return { "docker", "exec", "-it", "-w", workdir, container, "php", "artisan", "tinker" }
	elseif mode:match("^docker:(.+)$") then
		-- Direct docker exec: // mode:docker:myapp_web_1
		local container = mode:match("^docker:(.+)$")
		return { "docker", "exec", "-it", container, "php", "artisan", "tinker" }
	end
	
	-- Default: run locally
	return { "php", "artisan", "tinker" }
end

-- Create output buffer with proper settings
local function create_output_buffer()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(buf, "bufhidden", "hide")
	vim.api.nvim_buf_set_option(buf, "swapfile", false)
	vim.api.nvim_buf_set_option(buf, "filetype", "php")
	vim.api.nvim_buf_set_option(buf, "modifiable", true)
	-- Use pcall to avoid error if buffer with this name already exists
	pcall(vim.api.nvim_buf_set_name, buf, "Tinker Output")
	return buf
end

-- Create code buffer with proper settings
local function create_code_buffer()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf, "buftype", "")
	vim.api.nvim_buf_set_option(buf, "bufhidden", "hide")
	vim.api.nvim_buf_set_option(buf, "swapfile", false)
	vim.api.nvim_buf_set_option(buf, "filetype", "php")
	
	-- Use the actual project file path as buffer name so LSP attaches
	local file_path = get_project_file()
	pcall(vim.api.nvim_buf_set_name, buf, file_path)

	-- Load content from project file
	local content = load_project_file()
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
	
	-- Trigger LSP attach
	vim.schedule(function()
		if vim.api.nvim_buf_is_valid(buf) then
			vim.api.nvim_buf_call(buf, function()
				vim.cmd("doautocmd BufReadPost")
			end)
		end
	end)
	
	return buf
end

-- Append text to output buffer with highlights
local function append_to_output(text, highlights)
	if not state.output_buffer or not vim.api.nvim_buf_is_valid(state.output_buffer) then
		return
	end

	-- Check if text contains newlines and split if needed
	if text:find("\n") then
		local lines = vim.split(text, "\n", { plain = true })
		for _, line in ipairs(lines) do
			-- Recursively call for each line (without highlights, they won't map correctly)
			append_to_output(line, nil)
		end
		return
	end

	local current_line_count = vim.api.nvim_buf_line_count(state.output_buffer)
	local line_num = current_line_count == 1 and 0 or current_line_count -- 0-indexed, handle empty buffer
	
	-- Append the text (single line)
	vim.api.nvim_buf_set_lines(state.output_buffer, -1, -1, false, { text })

	-- Apply highlights if provided
	if highlights and #highlights > 0 then
		local namespace = vim.api.nvim_create_namespace("tinker_highlights")
		
		for _, hl in ipairs(highlights) do
			local start_col, end_col, hl_group = hl[1], hl[2], hl[3]
			pcall(vim.api.nvim_buf_add_highlight, state.output_buffer, namespace, hl_group, line_num, start_col, end_col)
		end
	end

	-- Auto scroll to bottom if enabled
	if config.auto_scroll and state.output_window and vim.api.nvim_win_is_valid(state.output_window) then
		local line_count = vim.api.nvim_buf_line_count(state.output_buffer)
		vim.api.nvim_win_set_cursor(state.output_window, { line_count, 0 })
	end
end

-- Clear output buffer
local function clear_output()
	if state.output_buffer and vim.api.nvim_buf_is_valid(state.output_buffer) then
		vim.api.nvim_buf_set_lines(state.output_buffer, 0, -1, false, { "=== Output cleared ===" })
	end
	state.accumulated_output = {}
end

-- ANSI color code to Neovim highlight group mapping
local ansi_colors = {
	-- Standard colors
	["30"] = "TinkerBlack",
	["31"] = "TinkerRed",
	["32"] = "TinkerGreen",
	["33"] = "TinkerYellow",
	["34"] = "TinkerBlue",
	["35"] = "TinkerMagenta",
	["36"] = "TinkerCyan",
	["37"] = "TinkerWhite",
	["90"] = "TinkerBrightBlack",
	["91"] = "TinkerBrightRed",
	["92"] = "TinkerBrightGreen",
	["93"] = "TinkerBrightYellow",
	["94"] = "TinkerBrightBlue",
	["95"] = "TinkerBrightMagenta",
	["96"] = "TinkerBrightCyan",
	["97"] = "TinkerBrightWhite",
}

-- 256 color support - convert to RGB
local xterm_colors = {
	[0] = "#000000", [1] = "#800000", [2] = "#008000", [3] = "#808000",
	[4] = "#000080", [5] = "#800080", [6] = "#008080", [7] = "#c0c0c0",
	[8] = "#808080", [9] = "#ff0000", [10] = "#00ff00", [11] = "#ffff00",
	[12] = "#0000ff", [13] = "#ff00ff", [14] = "#00ffff", [15] = "#ffffff",
	-- Add some common 256 colors used by Tinker
	[35] = "#00af5f", [38] = "#00afd7", [90] = "#870087", 
	[208] = "#ff8700", [244] = "#808080",
}

local function get_256_color_hl(color_num)
	local hl_name = "Tinker256_" .. color_num
	if vim.fn.hlexists(hl_name) == 0 then
		local color = xterm_colors[tonumber(color_num)]
		if color then
			vim.api.nvim_set_hl(0, hl_name, { fg = color })
		else
			-- Fallback: use cterm color
			vim.api.nvim_set_hl(0, hl_name, { ctermfg = tonumber(color_num) })
		end
	end
	return hl_name
end

-- Parse ANSI codes and return clean text with highlight positions
local function parse_ansi(text)
	local clean_text = ""
	local highlights = {}
	local pos = 0
	local current_hl = nil
	
	-- Remove carriage returns
	text = text:gsub("\r", "")
	
	local i = 1
	while i <= #text do
		-- Check for ANSI escape sequence
		local esc_start, esc_end = text:find("\27%[[^m]*m", i)
		
		if esc_start then
			-- Add text before escape sequence
			if esc_start > i then
				local chunk = text:sub(i, esc_start - 1)
				if current_hl then
					table.insert(highlights, { pos, pos + #chunk, current_hl })
				end
				clean_text = clean_text .. chunk
				pos = pos + #chunk
			end
			
			-- Extract and parse the color codes
			local codes = text:sub(esc_start, esc_end):match("\27%[([^m]*)m")
			if codes == "" or codes == "0" or codes == "39" or codes == "49" then
				-- Reset
				current_hl = nil
			else
				-- Handle 256 color format (38;5;N)
				local color_256 = codes:match("38;5;(%d+)")
				if color_256 then
					current_hl = get_256_color_hl(color_256)
				else
					-- Extract color code (handle multiple codes separated by ;)
					for code in codes:gmatch("[^;]+") do
						if code ~= "1" and ansi_colors[code] then
							current_hl = ansi_colors[code]
						end
					end
				end
			end
			
			i = esc_end + 1
		else
			-- No more color sequences, but check for other escape sequences to strip
			local next_esc = text:find("\27", i)
			local chunk
			if next_esc then
				chunk = text:sub(i, next_esc - 1)
				-- Skip the escape sequence
				local skip_end = text:find("[A-Za-z]", next_esc + 1)
				if skip_end then
					i = skip_end + 1
				else
					i = next_esc + 2
				end
			else
				chunk = text:sub(i)
				i = #text + 1
			end
			
			if current_hl and #chunk > 0 then
				table.insert(highlights, { pos, pos + #chunk, current_hl })
			end
			clean_text = clean_text .. chunk
			pos = pos + #chunk
			
			if not next_esc then
				break
			end
		end
	end
	
	return clean_text, highlights
end

-- Process tinker output
local function process_output(_, data)
	if data then
		for _, line in ipairs(data) do
			if line ~= "" then
				-- Parse ANSI codes and get highlights
				local clean_line, highlights = parse_ansi(line)
				
				-- Skip empty lines and prompt markers
				if clean_line ~= "" and clean_line ~= ">" and not clean_line:match("^%s*>%s*$") then
					table.insert(state.accumulated_output, clean_line)
					-- Display immediately with highlights
					vim.schedule(function()
						if highlights and #highlights > 0 then
							append_to_output(clean_line, highlights)
						else
							append_to_output(clean_line, nil)
						end
					end)
				end
			end
		end
	end
end

-- Start tinker process
local function start_tinker()
	if state.tinker_job_id then
		vim.fn.jobstop(state.tinker_job_id)
	end

	state.accumulated_output = {}

	-- Get current working directory
	local cwd = vim.fn.getcwd()

	-- Get appropriate command based on mode
	local command = get_tinker_command()
	
	state.tinker_job_id = vim.fn.jobstart(command, {
		on_stdout = process_output,
		on_stderr = process_output,
		on_exit = function(_, exit_code)
			vim.schedule(function()
				append_to_output("\n=== Tinker exited with code " .. exit_code .. " ===")
				state.tinker_job_id = nil
			end)
		end,
		stdout_buffered = false,
		stderr_buffered = false,
		pty = true, -- Enable PTY for interactive mode
		cwd = cwd,
	})

	if state.tinker_job_id <= 0 then
		vim.notify("Failed to start tinker process. Make sure you're in a Laravel project.", vim.log.levels.ERROR)
		return false
	end

	vim.schedule(function()
		append_to_output("=== Laravel Tinker Started ===\n")
	end)

	return true
end

-- Send code to tinker
local function send_to_tinker(code)
	if not state.tinker_job_id then
		vim.notify("Tinker is not running", vim.log.levels.ERROR)
		return
	end

	-- Clean up the code
	code = code:gsub("^%s*<%?php%s*", "") -- Remove <?php tag
	code = code:gsub("^%s*//.*", "") -- Remove comment-only lines
	code = code:gsub("^%s*", "") -- Remove leading whitespace
	code = code:gsub("%s*$", "") -- Remove trailing whitespace

	if code == "" or code:match("^//") then
		return
	end

	-- Show what we're executing with a separator for clarity
	vim.schedule(function()
		append_to_output("\n─────────────────────────────────────")
	end)

	-- Send to tinker with newline
	local result = vim.fn.chansend(state.tinker_job_id, code .. "\n")
	
	if result == 0 then
		vim.notify("Failed to send to tinker - channel closed", vim.log.levels.ERROR)
	end
end

-- Execute current line or visual selection
local function execute_code()
	if not state.tinker_job_id then
		vim.notify("Tinker job not running. Please restart with :Tinker", vim.log.levels.ERROR)
		return
	end

	local current_buf = vim.api.nvim_get_current_buf()
	if current_buf ~= state.code_buffer then
		vim.notify("Execute code only works from the code buffer", vim.log.levels.WARN)
		return
	end

	local mode = vim.api.nvim_get_mode().mode

	if mode == "v" or mode == "V" then
		-- Visual mode: get selected lines
		local start_line = vim.fn.line("v")
		local end_line = vim.fn.line(".")

		if start_line > end_line then
			start_line, end_line = end_line, start_line
		end

		local lines = vim.api.nvim_buf_get_lines(state.code_buffer, start_line - 1, end_line, false)
		local code = table.concat(lines, "\n")
		send_to_tinker(code)

		-- Exit visual mode
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
	else
		-- Normal mode: get current line
		local line = vim.api.nvim_get_current_line()
		send_to_tinker(line)
	end
end

-- Set up keymaps for tinker buffers
local function setup_keymaps()
	local opts = { buffer = state.code_buffer, silent = true, noremap = true }

	-- Execute code - just press Enter
	vim.keymap.set("n", "<CR>", execute_code, vim.tbl_extend("force", opts, { desc = "Execute line" }))
	vim.keymap.set("v", "<CR>", execute_code, vim.tbl_extend("force", opts, { desc = "Execute selection" }))

	-- Clear output
	vim.keymap.set("n", "<leader>tc", clear_output, vim.tbl_extend("force", opts, { desc = "Clear output" }))

	-- Also allow q to quit from output buffer
	vim.keymap.set("n", "q", function()
		M.toggle()
	end, { buffer = state.output_buffer, silent = true, noremap = true })

	-- Set up autocmd for :w to save to project file
	vim.api.nvim_create_autocmd("BufWritePost", {
		buffer = state.code_buffer,
		callback = function()
			vim.notify("Tinker session saved", vim.log.levels.INFO)
		end,
	})
end

-- Open tinker interface
function M.open()
	if not is_laravel_project() then
		vim.notify("Not a Laravel project. composer.json must contain laravel/framework", vim.log.levels.WARN)
		return
	end

	if state.is_open then
		vim.notify("Tinker is already open", vim.log.levels.INFO)
		return
	end

	-- Save current window and buffer to return to later
	state.previous_win = vim.api.nvim_get_current_win()
	state.previous_buf = vim.api.nvim_get_current_buf()

	-- Create or reuse buffers
	if not state.code_buffer or not vim.api.nvim_buf_is_valid(state.code_buffer) then
		state.code_buffer = create_code_buffer()
	end
	if not state.output_buffer or not vim.api.nvim_buf_is_valid(state.output_buffer) then
		state.output_buffer = create_output_buffer()
	end

	-- Create windows
	if config.split_direction == "vertical" then
		-- First create the split with output buffer
		vim.cmd("vsplit")
		state.output_window = vim.api.nvim_get_current_win()
		vim.api.nvim_win_set_buf(state.output_window, state.output_buffer)

		-- Move to left window and set code buffer
		vim.cmd("wincmd h")
		state.code_window = vim.api.nvim_get_current_win()
		vim.api.nvim_win_set_buf(state.code_window, state.code_buffer)

		-- Set window width based on ratio
		local total_width = vim.o.columns
		local code_width = math.floor(total_width * config.split_ratio)
		vim.api.nvim_win_set_width(state.code_window, code_width)
	else
		vim.cmd("split")
		state.code_window = vim.api.nvim_get_current_win()
		vim.api.nvim_win_set_buf(state.code_window, state.code_buffer)

		vim.cmd("wincmd j")
		state.output_window = vim.api.nvim_get_current_win()
		vim.api.nvim_win_set_buf(state.output_window, state.output_buffer)

		-- Go back to code window
		vim.api.nvim_set_current_win(state.code_window)
	end

	-- Start tinker
	if not start_tinker() then
		M.close()
		return
	end

	-- Setup keymaps
	setup_keymaps()

	state.is_open = true
end

-- Close tinker interface
function M.close()
	-- Save before closing
	save_project_file()
	
	-- Stop tinker job
	if state.tinker_job_id then
		vim.fn.jobstop(state.tinker_job_id)
		state.tinker_job_id = nil
	end

	-- Mark buffers as not modified
	if state.code_buffer and vim.api.nvim_buf_is_valid(state.code_buffer) then
		vim.api.nvim_buf_set_option(state.code_buffer, "modified", false)
	end
	if state.output_buffer and vim.api.nvim_buf_is_valid(state.output_buffer) then
		vim.api.nvim_buf_set_option(state.output_buffer, "modified", false)
	end

	-- Count total windows (excluding floating windows)
	local total_windows = 0
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local win_config = vim.api.nvim_win_get_config(win)
		if win_config.relative == "" then
			total_windows = total_windows + 1
		end
	end

	local tinker_windows = 0
	if state.code_window and vim.api.nvim_win_is_valid(state.code_window) then
		tinker_windows = tinker_windows + 1
	end
	if state.output_window and vim.api.nvim_win_is_valid(state.output_window) then
		tinker_windows = tinker_windows + 1
	end

	-- If closing tinker would close all windows, restore previous buffer in current window
	if total_windows <= tinker_windows then
		-- Switch to code window
		vim.api.nvim_set_current_win(state.code_window)
		
		-- Restore the previous buffer (or create a new one if it's no longer valid)
		if state.previous_buf and vim.api.nvim_buf_is_valid(state.previous_buf) then
			vim.api.nvim_set_current_buf(state.previous_buf)
		else
			local new_buf = vim.api.nvim_create_buf(true, false)
			vim.api.nvim_set_current_buf(new_buf)
		end
		
		-- Now close the output window only
		if state.output_window and vim.api.nvim_win_is_valid(state.output_window) then
			vim.api.nvim_win_close(state.output_window, false)
		end
		
		-- The code window is now showing the previous buffer
		state.code_window = nil
		state.output_window = nil
		state.is_open = false
		return
	end

	-- Normal case: close both windows and return to previous window
	if state.code_window and vim.api.nvim_win_is_valid(state.code_window) then
		vim.api.nvim_win_close(state.code_window, false)
	end
	if state.output_window and vim.api.nvim_win_is_valid(state.output_window) then
		vim.api.nvim_win_close(state.output_window, false)
	end

	-- Try to restore the previous window and buffer
	if state.previous_win and vim.api.nvim_win_is_valid(state.previous_win) then
		vim.api.nvim_set_current_win(state.previous_win)
		if state.previous_buf and vim.api.nvim_buf_is_valid(state.previous_buf) then
			vim.api.nvim_set_current_buf(state.previous_buf)
		end
	end

	-- Mark as closed
	state.code_window = nil
	state.output_window = nil
	state.is_open = false
end

-- Toggle tinker interface
function M.toggle()
	if state.is_open then
		M.close()
	else
		M.open()
	end
end

-- Setup highlight groups
local function setup_highlights()
	-- Standard ANSI colors
	vim.api.nvim_set_hl(0, "TinkerBlack", { fg = "#2e3436" })
	vim.api.nvim_set_hl(0, "TinkerRed", { fg = "#cc0000" })
	vim.api.nvim_set_hl(0, "TinkerGreen", { fg = "#4e9a06" })
	vim.api.nvim_set_hl(0, "TinkerYellow", { fg = "#c4a000" })
	vim.api.nvim_set_hl(0, "TinkerBlue", { fg = "#3465a4" })
	vim.api.nvim_set_hl(0, "TinkerMagenta", { fg = "#75507b" })
	vim.api.nvim_set_hl(0, "TinkerCyan", { fg = "#06989a" })
	vim.api.nvim_set_hl(0, "TinkerWhite", { fg = "#d3d7cf" })
	
	-- Bright colors
	vim.api.nvim_set_hl(0, "TinkerBrightBlack", { fg = "#555753" })
	vim.api.nvim_set_hl(0, "TinkerBrightRed", { fg = "#ef2929" })
	vim.api.nvim_set_hl(0, "TinkerBrightGreen", { fg = "#8ae234" })
	vim.api.nvim_set_hl(0, "TinkerBrightYellow", { fg = "#fce94f" })
	vim.api.nvim_set_hl(0, "TinkerBrightBlue", { fg = "#729fcf" })
	vim.api.nvim_set_hl(0, "TinkerBrightMagenta", { fg = "#ad7fa8" })
	vim.api.nvim_set_hl(0, "TinkerBrightCyan", { fg = "#34e2e2" })
	vim.api.nvim_set_hl(0, "TinkerBrightWhite", { fg = "#eeeeec" })
end

-- Setup function
function M.setup(opts)
	config = vim.tbl_deep_extend("force", config, opts or {})

	-- Setup highlights
	setup_highlights()

	-- Create user command - just toggle
	vim.api.nvim_create_user_command("Tinker", function()
		M.toggle()
	end, { desc = "Toggle Laravel Tinker" })
end

return M
