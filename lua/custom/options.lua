vim.wo.number = true

vim.o.completeopt = "menuone,noselect"

-- Sync clipboard between OS and Neovim.
--  Schedule the setting after `UiEnter` because it can increase startup-time.
--  See `:help 'clipboard'`
vim.schedule(function()
	vim.o.clipboard = "unnamedplus"
end)

local options = {
	backup = false, -- creates a backup file
	completeopt = { "menuone", "noselect" }, -- mostly just for cmp
	-- conceallevel = 0, -- so that `` is visible in markdown files
	fileencoding = "utf-8", -- the encoding written to a file
	ignorecase = true, -- ignore case in search patterns
	mouse = "a", -- a = all mouse events nvi = normal, visual, insert
	pumheight = 10, -- pop up menu height
	showmode = false, -- we don't need to see things like -- INSERT -- anymore
	showtabline = 0, -- always show tabs 2 yes 0 no
	smartcase = true, -- smart case
	smartindent = true, -- make indenting smarter again
	splitbelow = true, -- force all horizontal splits to go below current window
	splitright = true, -- force all vertical splits to go to the right of current window
	breakindent = true,
	timeout = true,
	timeoutlen = 300, -- time to wait for a mapped sequence to complete (in milliseconds)
	updatetime = 250, -- faster completion (4000ms default) - used for CursorHold events
	writebackup = false, -- if a file is being edited by another program (or was written to file while editing with another program), it is not allowed to be edited
	expandtab = true, -- convert tabs to spaces
	cursorline = false, -- highlight the current line
	number = true, -- set numbered lines
	numberwidth = 2, -- set number column width to 2 {default 4}
	signcolumn = "yes", -- always show the sign column, otherwise it would shift the text each time
	wrap = false, -- display lines as one long line
	sidescrolloff = 8,
	nu = true,
	-- guicursor = "",
	relativenumber = true,
	tabstop = 4,
	softtabstop = 4,
	shiftwidth = 4,
	swapfile = false,
	undodir = os.getenv("HOME") .. "/.vim/undodir",
	undofile = true,
	hlsearch = false,
	incsearch = true,
	termguicolors = true,
	scrolloff = 8,
	cmdheight = 1,
	winbar = "%= %m%f",
	background = "dark",
	-- Preview substitutions live, as you type!
	inccommand = "nosplit",
	-- Display certain whitespace characters in the editor
	list = true,
	-- If performing an operation that would fail due to unsaved changes,
	-- raise a dialog asking if you wish to save the current file(s)
	confirm = true,
	-- colorcolumn = "80",
}

-- Sets how neovim will display certain whitespace characters in the editor.
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

vim.opt.isfname:append("@-@")
for k, val in pairs(options) do
	vim.opt[k] = val
end
vim.filetype.add({ extension = { templ = "templ" } })

if vim.env.NVIM_NEOGIT == "1" then
	vim.api.nvim_create_autocmd("VimEnter", {
		callback = function()
			require("neogit").open()
		end,
	})
	vim.api.nvim_create_autocmd("FileType", {
		pattern = "NeogitStatus",
		callback = function()
			vim.defer_fn(function()
				vim.keymap.set("n", "q", "<cmd>qa<cr>", { buffer = true, desc = "quit neovim" })
			end, 100) -- Delay to ensure Neogit sets its mapping first.
		end,
	})
end
