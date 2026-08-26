return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        solargraph = {
          mason = false,
          workspace_required = true,
          on_init = function(client)
            client.server_capabilities.documentHighlightProvider = false
          end,
          cmd = function(dispatchers, config)
            return vim.lsp.rpc.start(
              {
                "mise",
                "x",
                "--",
                "ruby",
                "-r",
                vim.fn.stdpath("config") .. "/solargraph_mapping_patch.rb",
                "-S",
                "solargraph",
                "stdio",
              },
              dispatchers,
              { cwd = config.root_dir }
            )
          end,
        },
      },
    },
  },
}
