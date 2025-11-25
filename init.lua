vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

require 'custom/options'
require 'custom/keymaps'


require('lazy').setup({
  'tpope/vim-sleuth', -- Detect tabstop and shiftwidth automatically
  { 'numToStr/Comment.nvim', opts = {} },
  require 'plugins.todo',
  require 'plugins.toggleterm',
  require 'plugins.neogit',
  require 'plugins.gitsigns',
  -- require 'plugins.nvim-tree',
  require 'plugins.oil',
  require 'plugins.treesitter',
  require 'plugins.chatgpt',
  require 'plugins.mini',
  require 'plugins.whichkey',
  require 'plugins.telescope',
  require 'plugins.lsp',
  -- require 'plugins.autocomplete',
  require 'plugins.copilot',
  require 'plugins.noice',
  require 'plugins.blink',
  require 'plugins.trouble',
  require 'plugins.undotree',
  require 'plugins.colorscheme',
  require 'plugins.dadbod',
  require 'plugins.oil',
  require 'plugins.php',
  require 'plugins.tinker',
  -- require 'plugins.sidekick',  -- Disabled for now
  {
    'sindrets/diffview.nvim',
  },
  {
    'windwp/nvim-autopairs',
    event = "InsertEnter",
    config = true
    -- use opts = {} for passing setup options
    -- this is equivalent to setup({}) function
  },
}, {
  ui = {
    -- If you have a Nerd Font, set icons to an empty table which will use the
    -- default lazy.nvim defined Nerd Font icons otherwise define a unicode icons table
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚡',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})
