return {
  {
    "mfussenegger/nvim-jdtls",
    ft = "java",
    lazy = true,
    config = function()
      -- Will load jdtls configuration when a Java file is opened
      local jdtls_augroup = vim.api.nvim_create_augroup("jdtls_config", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "java",
        callback = function()
          require("sethy.lsp.jdtls").setup()
        end,
        group = jdtls_augroup,
      })
    end,
  },
}

