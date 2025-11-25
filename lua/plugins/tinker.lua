---@diagnostic disable: undefined-global
return {
	{
		"nvim-lua/plenary.nvim",
		lazy = true,
	},
	{
		-- Custom Tinkerwell alternative for Laravel
		dir = vim.fn.stdpath("config") .. "/lua/custom/tinker",
		name = "tinker.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			require("custom.tinker").setup({
				-- Default configuration
				auto_scroll = true, -- Auto scroll output buffer
				save_history = true, -- Save tinker history
				split_direction = "vertical", -- 'vertical' or 'horizontal'
				split_ratio = 0.5, -- Ratio of code buffer to output buffer
			})
		end,
		keys = {
			{ "<leader>tt", "<cmd>Tinker<cr>", desc = "Toggle Tinker" },
		},
	},
}
