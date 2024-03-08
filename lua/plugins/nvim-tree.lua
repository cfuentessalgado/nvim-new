return {
    'nvim-tree/nvim-tree.lua',
    dependencies = {
      'nvim-tree/nvim-web-devicons'
    },
    config = function() 
      -- TODO: This might be wrong, RTFM
      require 'nvim-tree'.setup()
      vim.keymap.set({ 'n' }, '<leader>e', '<cmd>NvimTreeToggle<cr>')
    end,
    opts = {}
  }
