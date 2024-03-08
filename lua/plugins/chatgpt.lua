return {
    "jackMort/ChatGPT.nvim",
    event = "VeryLazy",
    config = function()
        require("chatgpt").setup({
            api_key_cmd = "pass show personal/openai/nvim-api",
        })
        vim.keymap.set({ 'n' }, '<C-g>', '<cmd>ChatGPT<cr>', { desc = "Open Chat[G]PT" })
    end,
    dependencies = {
        "MunifTanjim/nui.nvim",
        "nvim-lua/plenary.nvim",
        "folke/trouble.nvim",
        "nvim-telescope/telescope.nvim"
    }
}
