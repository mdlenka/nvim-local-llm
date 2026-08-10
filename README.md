# nvim-local-llm

Fast, local, phone-like **word completion** for natural-language writing in Neovim,
powered by a local LLM and [blink.cmp](https://github.com/Saghen/blink.cmp).

> The central invariant: **PREFIX + COMPLETION = ONE COMPLETE WORD.**

If you type `scat`, the only acceptable completions are full words like
`scattering`, `scattered`, `scatter`. Suffixes like `tering` are never offered.

## Installation (lazy.nvim)

\`\`\`lua
return {
  "Saghen/blink.cmp",
  version = "*",
  dependencies = {
    {
      "yourname/nvim-local-llm",
      config = function()
        require("local_llm").setup({
          endpoint         = "http://127.0.0.1:11434/v1/chat/completions",
          model            = "qwen2.5-coder:1.5b",
          debounce_ms      = 150,
          max_context_chars= 1200,
          max_tokens       = 32,
          temperature      = 0.1,
        })
      end,
    },
  },
  opts = {
    sources = {
      default = { "lsp", "path", "snippets", "buffer", "local_llm" },
      providers = {
        local_llm = {
          name        = "LocalLLM",
          module      = "local_llm",
          score_offset= 5,
        },
      },
    },
  },
}
\`\`\`
