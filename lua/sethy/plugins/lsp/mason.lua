return {
    "williamboman/mason.nvim",
    lazy = false,
    dependencies = {
        "williamboman/mason-lspconfig.nvim",
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        "hrsh7th/cmp-nvim-lsp",
        "neovim/nvim-lspconfig",
        -- "saghen/blink.cmp",
    },
    config = function()
        -- import mason and mason_lspconfig
        local mason = require("mason")
        local mason_lspconfig = require("mason-lspconfig")
        local mason_tool_installer = require("mason-tool-installer")

        -- NOTE: Moved these local imports below back to lspconfig.lua due to mason depracated handlers

        -- local lspconfig = require("lspconfig")
        -- local cmp_nvim_lsp = require("cmp_nvim_lsp")             -- import cmp-nvim-lsp plugin
        -- local capabilities = cmp_nvim_lsp.default_capabilities() -- used to enable autocompletion (assign to every lsp server config)

        -- enable mason and configure icons
        mason.setup({
            ui = {
                icons = {
                    package_installed = "✓",
                    package_pending = "➜",
                    package_uninstalled = "✗",
                },
            },
            log_level = vim.log.levels.DEBUG, -- Aumentar o nível de log para debug
        })

        mason_lspconfig.setup({
            automatic_installation = true, -- Habilitar instalação automática
            -- servers for mason to install
            ensure_installed = {
                "lua_ls",
                -- "ts_ls", currently using a ts plugin
                "html",
                "cssls",
                "tailwindcss",
                "gopls",
                "emmet_ls",
                "emmet_language_server",
                -- "eslint",
                "marksman",
                "jdtls",
            },

        })

        mason_tool_installer.setup({
            ensure_installed = {
                "prettier", -- prettier formatter
                "stylua",   -- lua formatter
                "isort",    -- python formatter
                "pylint",
                "clangd",
                "denols",
                -- { 'eslint_d', version = '13.1.2' },
                "java-debug-adapter", -- Java debugging support
                "java-test", -- Java testing support
            },
            auto_update = true,
            run_on_start = true,

            -- NOTE: mason BREAKING Change! Removed setup_handlers
            -- moved lsp configuration settings back into lspconfig.lua file
        })
    end,
}
