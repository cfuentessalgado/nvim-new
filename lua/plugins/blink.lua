return {
  'saghen/blink.cmp',
  dependencies = {
    'rafamadriz/friendly-snippets',
    'giuxtaposition/blink-cmp-copilot'
  },

  version = '1.*',
  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    keymap = { preset = 'default' },
    appearance = {
      nerd_font_variant = 'mono'
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
          border = 'rounded',
          winblend = 0,
          winhighlight = 'Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,CursorLine:BlinkCmpDocCursorLine,Search:None',
          scrollbar = true,
        }
      }
    },
    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer', 'copilot' },
      providers = {
        copilot = {
          name = "copilot",
          module = "blink-cmp-copilot",
        },
      },
    },
    fuzzy = { implementation = "prefer_rust_with_warning" }
  },
  opts_extend = { "sources.default" }
}
