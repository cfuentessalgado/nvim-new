return {
	"saghen/blink.cmp",
    event = 'VimEnter',
	version = "1.*",
	dependencies = {
		"giuxtaposition/blink-cmp-copilot",
		-- Snippet engine for blink.cmp
		{
			"L3MON4D3/LuaSnip",
			version = "2.*",
			build = (function()
				-- Build step is needed for regex support in snippets.
				-- This step is not supported in many windows environments.
				if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
					return
				end
				return "make install_jsregexp"
			end)(),
			dependencies = {
				-- `friendly-snippets` contains a variety of premade snippets.
				--    See the README about individual language/framework/plugin snippets:
				--    https://github.com/rafamadriz/friendly-snippets
				{
				  'rafamadriz/friendly-snippets',
				  config = function()
				    require('luasnip.loaders.from_vscode').lazy_load()
				  end,
				},
			},
			opts = {},
		},
      'folke/lazydev.nvim',
	},
	---@module 'blink.cmp'
	---@type blink.cmp.Config
	opts = {
		keymap = { preset = "default" },
		appearance = {
			nerd_font_variant = "mono",
		},
		completion = {
			documentation = {
				auto_show = true,
				auto_show_delay_ms = 500,
				treesitter_highlighting = true,
				window = {
					min_width = 10,
					max_width = 60,
					max_height = 20,
					border = "rounded",
					winblend = 0,
					winhighlight = "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,CursorLine:BlinkCmpDocCursorLine,Search:None",
					scrollbar = true,
				},
			},
		},
		sources = {
			default = { "lazydev", "lsp", "path", "snippets", "buffer", "copilot" },
			providers = {
				copilot = {
					name = "copilot",
					module = "blink-cmp-copilot",
				},
				lazydev = {
					name = "LazyDev",
					module = "lazydev.integrations.blink",
					-- make lazydev completions top priority (see `:h blink.cmp`)
					score_offset = 100,
				},
			},
		},
		snippets = { preset = "luasnip" },
		fuzzy = { implementation = "lua" },
		-- Shows a signature help window while you type arguments for a function
		signature = { enabled = true },
	},
	opts_extend = { "sources.default" },
}
