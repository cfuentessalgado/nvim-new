---@diagnostic disable: undefined-global
local M = {}

local config = {
	auto_scroll = true,
	save_history = true,
	split_direction = "vertical",
	split_ratio = 0.5,
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
}

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

-- Create output buffer with proper settings
local function create_output_buffer()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(buf, "swapfile", false)
	vim.api.nvim_buf_set_option(buf, "filetype", "php")
	vim.api.nvim_buf_set_option(buf, "modifiable", true)
	vim.api.nvim_buf_set_name(buf, "Tinker Output")
	return buf
end

-- Create code buffer with proper settings
local function create_code_buffer()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf, "buftype", "acwrite")
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(buf, "swapfile", false)
	vim.api.nvim_buf_set_option(buf, "filetype", "php")
	vim.api.nvim_buf_set_name(buf, "Tinker Code")

	-- Add some helpful initial content
	local initial_content = {
		"<?php",
		"",
		"// Laravel Tinker - Press <leader>te to execute line/selection",
		"// Press <leader>tc to clear output",
		"// Press <leader>tq to quit",
		"",
		"// Example:",
		"// User::count()",
		"",
	}
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, initial_content)
	return buf
end

-- Append text to output buffer
local function append_to_output(text)
	if not state.output_buffer or not vim.api.nvim_buf_is_valid(state.output_buffer) then
		return
	end

	local lines = vim.split(text, "\n", { plain = true })
	local current_lines = vim.api.nvim_buf_get_lines(state.output_buffer, 0, -1, false)

	for _, line in ipairs(lines) do
		table.insert(current_lines, line)
	end

	vim.api.nvim_buf_set_lines(state.output_buffer, 0, -1, false, current_lines)

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

-- Strip ANSI escape codes from text
local function strip_ansi(text)
	-- Remove ANSI color codes and other escape sequences
	text = text:gsub("\27%[[%d;]*m", "") -- Color codes
	text = text:gsub("\27%[%d*[ABCDEFGJKST]", "") -- Cursor movement
	text = text:gsub("\27%]%d*;[^\7]*\7", "") -- OSC sequences
	text = text:gsub("\13", "") -- Carriage return (^M)
	return text
end

-- Process tinker output
local function process_output(_, data)
	if data then
		for _, line in ipairs(data) do
			if line ~= "" then
				-- Strip ANSI codes before storing and displaying
				local clean_line = strip_ansi(line)
				
				-- Skip empty lines and prompt markers
				if clean_line ~= "" and clean_line ~= ">" and not clean_line:match("^%s*>%s*$") then
					table.insert(state.accumulated_output, clean_line)
					-- Display immediately
					vim.schedule(function()
						append_to_output(clean_line)
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

	state.tinker_job_id = vim.fn.jobstart({ "php", "artisan", "tinker" }, {
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
		append_to_output("=== Laravel Tinker Started (Job ID: " .. state.tinker_job_id .. ") ===\n")
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

	-- Execute code
	vim.keymap.set("n", "<leader>te", execute_code, vim.tbl_extend("force", opts, { desc = "Execute line" }))
	vim.keymap.set("v", "<leader>te", execute_code, vim.tbl_extend("force", opts, { desc = "Execute selection" }))

	-- Alternative: just press Enter to execute
	vim.keymap.set("n", "<CR>", execute_code, vim.tbl_extend("force", opts, { desc = "Execute line" }))
	vim.keymap.set("v", "<CR>", execute_code, vim.tbl_extend("force", opts, { desc = "Execute selection" }))

	-- Clear output
	vim.keymap.set("n", "<leader>tc", clear_output, vim.tbl_extend("force", opts, { desc = "Clear output" }))

	-- Quit tinker
	vim.keymap.set("n", "<leader>tq", function()
		M.close()
	end, vim.tbl_extend("force", opts, { desc = "Quit tinker" }))

	-- Also allow q to quit from output buffer
	vim.keymap.set("n", "q", function()
		M.close()
	end, { buffer = state.output_buffer, silent = true, noremap = true })
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

	-- Create buffers
	state.code_buffer = create_code_buffer()
	state.output_buffer = create_output_buffer()

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

	vim.notify("Laravel Tinker started! Press <CR> or <leader>te to execute code", vim.log.levels.INFO)
end

-- Close tinker interface
function M.close()
	-- Stop tinker job
	if state.tinker_job_id then
		vim.fn.jobstop(state.tinker_job_id)
		state.tinker_job_id = nil
	end

	-- Close windows
	if state.code_window and vim.api.nvim_win_is_valid(state.code_window) then
		vim.api.nvim_win_close(state.code_window, true)
	end
	if state.output_window and vim.api.nvim_win_is_valid(state.output_window) then
		vim.api.nvim_win_close(state.output_window, true)
	end

	-- Delete buffers
	if state.code_buffer and vim.api.nvim_buf_is_valid(state.code_buffer) then
		vim.api.nvim_buf_delete(state.code_buffer, { force = true })
	end
	if state.output_buffer and vim.api.nvim_buf_is_valid(state.output_buffer) then
		vim.api.nvim_buf_delete(state.output_buffer, { force = true })
	end

	-- Reset state
	state.code_buffer = nil
	state.output_buffer = nil
	state.code_window = nil
	state.output_window = nil
	state.is_open = false
	state.accumulated_output = {}
end

-- Toggle tinker interface
function M.toggle()
	if state.is_open then
		M.close()
	else
		M.open()
	end
end

-- Setup function
function M.setup(opts)
	config = vim.tbl_deep_extend("force", config, opts or {})

	-- Create user commands
	vim.api.nvim_create_user_command("Tinker", function()
		M.open()
	end, { desc = "Open Laravel Tinker" })

	vim.api.nvim_create_user_command("TinkerClose", function()
		M.close()
	end, { desc = "Close Laravel Tinker" })

	vim.api.nvim_create_user_command("TinkerToggle", function()
		M.toggle()
	end, { desc = "Toggle Laravel Tinker" })

	vim.api.nvim_create_user_command("TinkerClear", function()
		clear_output()
	end, { desc = "Clear Tinker output" })

	vim.api.nvim_create_user_command("TinkerStatus", function()
		if state.is_open then
			local job_status = state.tinker_job_id and "running (ID: " .. state.tinker_job_id .. ")" or "stopped"
			vim.notify(
				string.format(
					"Tinker is open\nJob: %s\nCode buffer: %s\nOutput buffer: %s",
					job_status,
					state.code_buffer or "nil",
					state.output_buffer or "nil"
				),
				vim.log.levels.INFO
			)
		else
			vim.notify("Tinker is not open", vim.log.levels.INFO)
		end
	end, { desc = "Show Tinker status" })
end

return M
