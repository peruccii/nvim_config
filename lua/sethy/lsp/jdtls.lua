local M = {}

function M.setup()
  -- Find root directory (from current directory upwards until it finds any of these files/folders)
  local root_markers = {
    ".git",
    "mvnw",
    "gradlew",
    "pom.xml",
    "build.gradle",
  }
  
  local root_dir = require("jdtls.setup").find_root(root_markers)
  if not root_dir then
    root_dir = vim.fn.getcwd()
  end

  -- Calculate workspace directory
  -- Each project has a dedicated workspace
  local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
  local workspace_dir = vim.fn.expand("~/.cache/jdtls/workspace/") .. project_name

  -- Get jdtls installation path (default location for Mason installs)
  local jdtls_path = vim.fn.expand("~/.local/share/nvim/mason/packages/jdtls")
  local jdtls_bin = jdtls_path .. "/bin/jdtls"
  
  -- For Windows, adjust paths accordingly
  if vim.fn.has("win32") == 1 then
    jdtls_path = vim.fn.expand("~/AppData/Local/nvim-data/mason/packages/jdtls")
    jdtls_bin = jdtls_path .. "/bin/jdtls.bat"
    workspace_dir = vim.fn.expand("~/AppData/Local/nvim-data/jdtls-workspace/") .. project_name
  end

  -- Setup JDTLS config
  local config = {
    cmd = {
      jdtls_bin,
      "-data", workspace_dir,
    },
    root_dir = root_dir,
    settings = {
      java = {
        configuration = {
          runtimes = {
            {
              name = "JavaSE-21",
              path = vim.fn.expand("C:/Program Files/Java/jdk-21"),
            },
          },
        },
        eclipse = {
          downloadSources = true,
        },
        maven = {
          downloadSources = true,
        },
        implementationsCodeLens = {
          enabled = true,
        },
        referencesCodeLens = {
          enabled = true,
        },
        references = {
          includeDecompiledSources = true,
        },
        inlayHints = {
          parameterNames = {
            enabled = "all",
          },
        },
        format = {
          enabled = true,
          settings = {
            url = jdtls_path .. "/formatters/eclipse-java-google-style.xml",
            profile = "GoogleStyle",
          },
        },
      },
      signatureHelp = {
        enabled = true,
      },
      completion = {
        favoriteStaticMembers = {
          "org.hamcrest.MatcherAssert.assertThat",
          "org.hamcrest.Matchers.*",
          "org.hamcrest.CoreMatchers.*",
          "org.junit.jupiter.api.Assertions.*",
          "java.util.Objects.requireNonNull",
          "java.util.Objects.requireNonNullElse",
          "org.mockito.Mockito.*",
        },
        filteredTypes = {
          "com.sun.*",
          "io.micrometer.shaded.*",
          "java.awt.*",
          "jdk.*",
          "sun.*",
        },
      },
      contentProvider = {
        preferred = "fernflower",
      },
      extendedClientCapabilities = {
        progressReportProvider = true,
        classFileContentsSupport = true,
      },
      sources = {
        organizeImports = {
          starThreshold = 9999,
          staticStarThreshold = 9999,
        },
      },
      codeGeneration = {
        toString = {
          template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
        },
        useBlocks = true,
      },
    },
    flags = {
      allow_incremental_sync = true,
    },
    capabilities = vim.lsp.protocol.make_client_capabilities(),
  }

  -- Try to enhance capabilities with cmp_nvim_lsp if available
  local status_cmp_ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
  if status_cmp_ok then
    config.capabilities = cmp_nvim_lsp.default_capabilities(config.capabilities)
  end

  -- Add jdtls-specific commands
  local bundles = {}
  
  -- Add Java Debug and Test bundles
  -- Only add if we have the java-debug and vscode-java-test installed
  local java_debug_path = vim.fn.expand("~/AppData/Local/nvim-data/mason/packages/java-debug-adapter")
  local java_test_path = vim.fn.expand("~/AppData/Local/nvim-data/mason/packages/java-test")
  
  if vim.fn.isdirectory(java_debug_path) == 1 then
    vim.list_extend(bundles, vim.split(vim.fn.glob(java_debug_path .. "/extension/server/com.microsoft.java.debug.plugin-*.jar"), "\n"))
  end
  
  if vim.fn.isdirectory(java_test_path) == 1 then
    vim.list_extend(bundles, vim.split(vim.fn.glob(java_test_path .. "/extension/server/*.jar"), "\n"))
  end
  
  -- Enable DAP
  if #bundles > 0 then
    config.init_options = {
      bundles = bundles,
    }
  end

  -- Setup keymaps
  local function setup_keymaps()
    local jdtls = require("jdtls")
    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = vim.api.nvim_get_current_buf(), desc = desc })
    end
    
    -- Regular LSP mappings
    map("n", "gd", vim.lsp.buf.definition, "Go to definition")
    map("n", "gr", vim.lsp.buf.references, "Go to references")
    map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
    map("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
    map("n", "K", vim.lsp.buf.hover, "Hover documentation")
    map("n", "<C-k>", vim.lsp.buf.signature_help, "Signature help")
    map("n", "<leader>ca", vim.lsp.buf.code_action, "Code actions")
    map("n", "<leader>rn", vim.lsp.buf.rename, "Rename")
    map("n", "<leader>f", vim.lsp.buf.format, "Format file")
    
    -- Java-specific mappings
    map("n", "<leader>jo", function() jdtls.organize_imports() end, "Organize imports")
    map("n", "<leader>jv", function() jdtls.extract_variable() end, "Extract variable")
    map("n", "<leader>jc", function() jdtls.extract_constant() end, "Extract constant")
    map("n", "<leader>jm", function() jdtls.extract_method() end, "Extract method")
    
    -- Visual mode mappings
    map("v", "<leader>jv", function() jdtls.extract_variable(true) end, "Extract variable")
    map("v", "<leader>jc", function() jdtls.extract_constant(true) end, "Extract constant")
    map("v", "<leader>jm", function() jdtls.extract_method(true) end, "Extract method")
    
    -- Test mappings
    map("n", "<leader>jt", function() jdtls.test_nearest_method() end, "Test method")
    map("n", "<leader>jT", function() jdtls.test_class() end, "Test class")
    
    -- DAP mappings
    map("n", "<leader>jb", function() require("dap").toggle_breakpoint() end, "Toggle breakpoint")
    map("n", "<leader>jB", function() require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: ")) end, "Conditional breakpoint")
    map("n", "<leader>jc", function() require("dap").continue() end, "Continue")
    map("n", "<leader>ji", function() require("dap").step_into() end, "Step into")
    map("n", "<leader>jo", function() require("dap").step_over() end, "Step over")
    map("n", "<leader>jO", function() require("dap").step_out() end, "Step out")
    map("n", "<leader>jr", function() require("dap").repl.open() end, "Open REPL")
  end

  -- Setup autocommand to attach jdtls
  config.on_attach = function(client, bufnr)
    -- Enable completion triggered by <c-x><c-o>
    vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")
    
    setup_keymaps()

    -- Register command for DAP
    require("jdtls").setup_dap({ hotcodereplace = "auto" })
    require("jdtls.dap").setup_dap_main_class_configs()
    
    -- Enable codelens
    vim.cmd [[
      augroup jdtls_codelens_refresh
        autocmd!
        autocmd BufEnter,CursorHold,InsertLeave <buffer> lua vim.lsp.codelens.refresh()
      augroup END
    ]]
  end
  
  -- Start JDTLS
  require("jdtls").start_or_attach(config)
end

return M

