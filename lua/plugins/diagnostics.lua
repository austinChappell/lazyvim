return {
  -- Renders the current line's diagnostic inline instead of as one unbroken
  -- virtual_text line that runs off the right edge of the window.
  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "VeryLazy",
    priority = 1000, -- load before other plugins that touch diagnostic virtual_text
    opts = {
      preset = "modern",
      options = {
        show_source = true,
        multilines = { enabled = true, always_show = false },
        -- break_line uses a fixed character width and takes priority over
        -- overflow.mode when enabled, which truncated messages in windows
        -- narrower than that width (e.g. vsplits). Keep it off so "wrap"
        -- measures the real window width instead.
        overflow = { mode = "wrap" },
        break_line = { enabled = false },
      },
    },
  },

  -- LazyVim enables virtual_text by default, which is what was running off
  -- the page; tiny-inline-diagnostic replaces it. Also bound the floating
  -- diagnostic window (gh / <leader>cd) so long messages wrap instead of
  -- stretching past the screen edge.
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        virtual_text = false,
        float = {
          border = "rounded",
          source = true,
          max_width = 100,
        },
      },
    },
  },

  -- Rewrites cryptic TSxxxx compiler errors (from ts_ls/vtsls) into
  -- plain-English explanations in the diagnostic float.
  {
    "dmmulroy/ts-error-translator.nvim",
    ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
    opts = {},
  },
}
