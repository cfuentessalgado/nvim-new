return { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    config = function()
        -- [[ Configure Treesitter ]] See `:help nvim-treesitter`

        ---@diagnostic disable-next-line: missing-fields
        require('nvim-treesitter.configs').setup {
            ensure_installed = { 'bash', 'blade', 'c', 'html', 'lua', 'markdown', 'vim', 'vimdoc', 'php', 'go', 'javascript' },
            -- Autoinstall languages that are not installed
            auto_install = true,
            highlight = { enable = true },
            indent = { enable = true },
        }
        local parser_config = require("nvim-treesitter.parsers").get_parser_configs()

        -- parser_config.blade = {
        --     install_info = {
        --         -- url = "https://github.com/cfuentessalgado/tree-sitter-blade",
        --         url = "~/repos/github.com/cfuentessalgado/tree-sitter-blade/",
        --         files = { "src/parser.c" },
        --         branch = "main",
        --     },
        --     filetype = "*.blade.php"
        -- }

        -- There are additional nvim-treesitter modules that you can use to interact
        -- with nvim-treesitter. You should go explore a few and see what interests you:
        --
        --    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
        --    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
        --    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
    end,
}
