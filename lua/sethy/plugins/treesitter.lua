return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    -- Load earlier in the startup process instead of lazy loading
    lazy = false,
    priority = 1000, -- High priority to ensure it loads early
    config = function()
      local ok, ts_configs = pcall(require, "nvim-treesitter.configs")
      if not ok then
        vim.notify("nvim-treesitter não pôde ser carregado", vim.log.levels.ERROR)
        return
      end

      -- Function to safely check if a parser is installed
      local function is_parser_installed(lang)
        local parser_file = vim.api.nvim_get_runtime_file("parser/" .. lang .. ".so", true)
        return #parser_file > 0
      end

      -- Ensure required parsers are installed before proceeding
      if not is_parser_installed("go") then
        vim.notify("Go parser not installed. Installing now...", vim.log.levels.INFO)
        vim.cmd("TSInstall! go")
      end

      -- Ensure parsers are properly initialized
      local parsers_ok, parser_config = pcall(require, "nvim-treesitter.parsers")
      if not parsers_ok then
        vim.notify("nvim-treesitter.parsers não pôde ser carregado", vim.log.levels.ERROR)
        return
      end
      
      -- Get parser configs safely
      local parser_configs = parser_config.get_parser_configs()
      local installed_parsers = {
        "bash",
        "c",
        "css",
        "dockerfile",
        "gitignore",
        "go",
        "graphql",
        "html",
        "http",
        "java",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "prisma",
        "python",
        "query",
        "rust",
        "svelte",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "yaml",
      }

      ts_configs.setup({
        ensure_installed = installed_parsers,
        sync_install = true, -- Install synchronously to avoid race conditions
        auto_install = true,
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
          -- Add custom error handling for highlighting
          custom_captures = {},
          disable = function(lang, bufnr)
            -- Disable if file is too large
            local max_filesize = 100 * 1024 -- 100 KB
            local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(bufnr))
            if ok and stats and stats.size > max_filesize then
              return true
            end
            
            -- Add special handling for Go files
            if lang == "go" and not is_parser_installed("go") then
              vim.notify("Go parser not available for this buffer. Attempting to install...", vim.log.levels.WARN)
              vim.cmd("TSInstall! go")
              return true
            end
            
            return false
          end,
        },
        indent = {
          enable = true,
        },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "<C-space>",
            node_incremental = "<C-space>",
            scope_incremental = "<CR>",
            node_decremental = "<BS>",
          },
        },
        -- Additional modules if needed
        autopairs = {
          enable = true,
        },
        autotag = {
          enable = true,
        },
      })
      
      -- Add post-setup verification
      vim.defer_fn(function()
        -- Double-check parser installation after setup
        if not is_parser_installed("go") then
          vim.notify("Go parser still not available after setup. Please run :TSInstall go manually.", vim.log.levels.WARN)
        end
        
        -- Try to add the go parser to any open Go files
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_valid(buf) then
            local ft = vim.api.nvim_buf_get_option(buf, "filetype")
            if ft == "go" then
              pcall(function()
                -- Try to force attach the parser
                require("nvim-treesitter.configs").reattach_module("highlight", buf)
              end)
            end
          end
        end
      end, 1000) -- Check after 1 second
    end,
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
  },
}
