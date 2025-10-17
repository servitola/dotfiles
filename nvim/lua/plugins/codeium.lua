return {
  {
    "Exafunction/codeium.vim",
    event = "BufEnter",
    config = function()
      -- Disable default bindings
      vim.g.codeium_disable_bindings = 1
      -- Enable Codeium by default
      vim.g.codeium_enabled = true
      -- Show Codeium status in statusline
      vim.g.codeium_status_indicator = 1
      
      -- Set up custom keybindings
      vim.keymap.set('i', '<C-g>', function() return vim.fn['codeium#Accept']() end, { expr = true, silent = true })
      vim.keymap.set('i', '<c-;>', function() return vim.fn['codeium#CycleCompletions'](1) end, { expr = true, silent = true })
      vim.keymap.set('i', '<c-,>', function() return vim.fn['codeium#CycleCompletions'](-1) end, { expr = true, silent = true })
      vim.keymap.set('i', '<c-x>', function() return vim.fn['codeium#Clear']() end, { expr = true, silent = true })
      -- Additional useful bindings
      vim.keymap.set('i', '<C-h>', function() return vim.fn['codeium#AcceptNextWord']() end, { expr = true, silent = true })
      vim.keymap.set('i', '<C-l>', function() return vim.fn['codeium#AcceptNextLine']() end, { expr = true, silent = true })
    end,
  }
}
