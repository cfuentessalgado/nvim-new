return { -- Autoformat
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>df",
      function()
        require("conform").format({ async = true, lsp_fallback = true })
      end,
      mode = { "n", "v" },
      desc = "[D]o [F]ormat",
    },
  },
  opts = {
    notify_on_error = false,
    -- Disable format on save - use <leader>df to format manually
    -- If you want to enable format on save, uncomment the function below:
    -- format_on_save = function(bufnr)
    -- 	local disable_filetypes = { c = true, cpp = true }
    -- 	if disable_filetypes[vim.bo[bufnr].filetype] then
    -- 		return nil
    -- 	else
    -- 		return {
    -- 			timeout_ms = 500,
    -- 			lsp_format = "fallback",
    -- 		}
    -- 	end
    -- end,
    formatters_by_ft = {
      lua = { "stylua" },
      -- PHP: Try pint first, then php-cs-fixer, then fallback to LSP (intelephense)
      -- stop_after_first will use the first available formatter
      php = { "pint", "php-cs-fixer", stop_after_first = true },
      blade = { "blade-formatter" },
      -- TODO: Add formatters for your other languages
      -- Conform can also run multiple formatters sequentially
      -- python = { "isort", "black" },
      javascript = { "prettierd", "prettier", stop_after_first = true },
      typescript = { "prettierd", "prettier", stop_after_first = true },
      go = { "gofmt", "goimports" },
      rust = { "rustfmt" },
    },
    -- Custom formatter configurations
    formatters = {
      pint = {
        command = function()
          -- Try ./vendor/bin/pint first, fallback to global pint
          local pint_local = vim.fn.findfile("vendor/bin/pint", ".;")
          if pint_local ~= "" then
            return vim.fn.fnamemodify(pint_local, ":p")
          end
          return "pint"
        end,
      },
      ["php-cs-fixer"] = {
        command = function()
          -- Try ./vendor/bin/php-cs-fixer first, fallback to global
          local fixer_local = vim.fn.findfile("vendor/bin/php-cs-fixer", ".;")
          if fixer_local ~= "" then
            return vim.fn.fnamemodify(fixer_local, ":p")
          end
          return "php-cs-fixer"
        end,
      },
    },
  },
}
