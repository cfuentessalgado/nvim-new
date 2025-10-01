return {
  "zbirenbaum/copilot.lua",
  requires = {
    "copilotlsp-nvim/copilot-lsp", -- (optional) for NES functionality
  },
  cmd = "Copilot",
  event = "InsertEnter",
  config = function()
    require("copilot").setup({
      suggestion = {
        auto_trigger = false -- TODO: check if needs to be true
      },
      nes = {
        enabled = true,
      }
    })
  end,
}
