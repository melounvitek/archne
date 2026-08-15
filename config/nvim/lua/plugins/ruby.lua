return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        solargraph = {
          mason = false,
          workspace_required = true,
          cmd = function(dispatchers, config)
            return vim.lsp.rpc.start(
              { "mise", "x", "--", "solargraph", "stdio" },
              dispatchers,
              { cwd = config.root_dir }
            )
          end,
        },
      },
    },
  },
}
