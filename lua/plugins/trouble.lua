return {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        require("trouble").setup {}
        vim.keymap.set("n", "<leader>xx", function() require("trouble").toggle() end, {desc="Toggle Diagnostics"} )
        vim.keymap.set("n", "<leader>xw", function() require("trouble").toggle("workspace_diagnostics") end, {desc="Toggle [W]orkspace Diagnostics"} )
        vim.keymap.set("n", "<leader>xd", function() require("trouble").toggle("document_diagnostics") end, {desc="Toggle [D]ocument Diagnostics"} )
        vim.keymap.set("n", "<leader>xq", function() require("trouble").toggle("quickfix") end, {desc="Toggle [Q]uickfix"} )
        vim.keymap.set("n", "<leader>xl", function() require("trouble").toggle("loclist") end, {desc="Toggle [L]oclist"} )
    end,
}
