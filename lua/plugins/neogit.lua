return {
  "NeogitOrg/neogit",
  branch = 'master',
  event = 'VeryLazy',
  dependencies = {
    "nvim-lua/plenary.nvim",         -- required
    "sindrets/diffview.nvim",        -- optional - Diff integration
  },
  config = function ()
    require('neogit').setup {}
    vim.keymap.set({'n'}, '<leader>gs', '<cmd>Neogit<cr>', {desc = "Open Neogit"})
  end
}
