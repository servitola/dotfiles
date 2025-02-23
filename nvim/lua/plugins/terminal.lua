return {
  {
    "folke/snacks.nvim",
    opts = {
      terminal = {
        shell = "/opt/homebrew/bin/zsh",
        -- Ensure shell is properly quoted and configured
        shell_opts = {},
        -- Add any additional terminal settings here
        on_open = function()
          -- Disable line numbers in terminal
          vim.opt_local.number = false
          vim.opt_local.relativenumber = false
        end,
      },
    },
  },
}
