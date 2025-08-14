return {
    {
        "williamboman/mason.nvim",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, {
                "jdtls",
                "java-debug-adapter",
                "java-test",
                "gradle-language-server",
                "checkstyle",
            })
        end,
    },
    {
        "neovim/nvim-lspconfig",
        optional = true,
        opts = {
            setup = {
                jdtls = function()
                    return true -- avoid duplicate servers
                end,
            },
        },
    },
}
