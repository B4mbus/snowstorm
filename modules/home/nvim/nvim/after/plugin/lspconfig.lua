local neodev_ok, neodev = b4.pequire("neodev")
neodev.setup({
  experimental = {
    pathStrict = true,
  },
  library = {
    runtime = '~/Executable/storage/nvim-linux64/share/nvim/runtime',
  },
})

if not neodev_ok then
  vim.notify('Could not load the "neodev" plugin')
  return
end

local lsp_ok, lsp = b4.pequire('lspconfig')

if not lsp_ok then
  vim.notify('Could not load the "lsp" plugin')
  return
end

require('lspconfig.configs').fennel_language_server = ({
  default_config = {
    -- replace it with true path
    cmd = { '/home/b4mbus/.cargo/bin/fennel-language-server' },
    filetypes = { 'fennel' },
    single_file_support = true,
    -- source code resides in directory `fnl/`
    root_dir = lsp.util.root_pattern("fnl"),
    settings = {
      fennel = {
        workspace = {
          -- If you are using hotpot.nvim or aniseed,
          -- make the server aware of neovim runtime files.
          library = vim.api.nvim_list_runtime_paths(),
        },
        diagnostics = {
          globals = { 'vim' },
        },
      },
    },
  },
})

local custom_on_attach =  function(client, bufnr)
  local wk_ok, wk = b4.pequire('which-key')
  if wk_ok then
    local lsp_mappings = {
      name = 'LSP',
      ['<space>'] = {
        name = 'Meta',
        i = { '<cmd>LspInfo<cr>', 'Info' },
        l = { '<cmd>LspLog<cr>', 'Log' },
        r = { '<cmd>LspRestart<cr>', 'Restart' },
        s = { '<cmd>LspStart<cr>', 'Start' },
        S = { '<cmd>LspStop<cr>', 'Stop' }
      },
      c = {
        name = 'Calls',
        i = { '<cmd>Telescope lsp_incoming_calls<cr>', 'Incoming'},
        o = { '<cmd>Telescope lsp_outgoing_calls<cr>', 'Outgoing'},
      },
      f = { '<cmd>lua vim.lsp.buf.format()<cr>', 'Format' },
      R = { '<cmd>Telescope lsp_references<cr>', 'References' },
      d = { '<cmd>Telescope lsp_definitions<cr>', 'Definitions' },
      D = { '<cmd>lua vim.diagnostic.open_float()<cr>', 'Diagnostics float' },
      i = { '<cmd>Telescope lsp_implementations<cr>', 'Implementations' },
      s = { '<cmd>Telescope lsp_document_symbols<cr>', 'Local symbols' },
      S = { '<cmd>Telescope lsp_dynamic_workspace_symbols<cr>', 'Symbols' },
      l = { '<cmd>lua require "lsp_lines".toggle()<cr>', 'Toggle lsp_lines' },
      r = { function() vim.lsp.buf.rename() end, 'Toggle lsp_lines' },
      v = {
        function()
          local opts = {
            prefix = '◉ '
          }

          local virtual_text_enabled = vim.diagnostic.config().virtual_text

          vim.diagnostic.config({
            virtual_text = (not virtual_text_enabled) and opts or false
          })
        end,
        'Toggle virtual_text',
      }
    }

    wk.register(
      {
        l = lsp_mappings,
      },
      { prefix = '<leader>' }
    )

    wk.register(
      {
        [']d'] =  { vim.diagnostic.goto_prev, 'Goto next diag' },
        ['[d'] =  { vim.diagnostic.goto_next, 'Goto prev diag' },
        g = {
          d = { vim.lsp.buf.definition, 'Definition' },
          i = { vim.lsp.buf.implementation, 'Implementation' }
        }
      },
      { prefix = '' }
    )

    vim.keymap.set({ 'n', 'x' }, '<leader>la', vim.lsp.buf.code_action, { desc = "Code actions" })
    vim.keymap.set('n', 'gD', '<CMD>Glance definitions<CR>')
    vim.keymap.set('n', 'gR', '<CMD>Glance references<CR>')
    vim.keymap.set('n', 'gY', '<CMD>Glance type_definitions<CR>')
    vim.keymap.set('n', 'gM', '<CMD>Glance implementations<CR>')

    vim.api.nvim_create_autocmd(
      'BufWritePre',
      {
        callback = function ()
          if vim.b.format_on_save then
            vim.lsp.buf.format()
          end
        end
      }
    )
  end
end

local server_caps = vim.lsp.protocol.make_client_capabilities()
local caps = require('cmp_nvim_lsp').default_capabilities(server_caps)
caps.textDocument.foldingRange = {
  dynamicRegistration = false,
  lineFoldingOnly = true
}

local default_config = {
  single_file_support = true,
  capabilities = caps,
  on_attach = custom_on_attach
}

local clangd_config = {
  single_file_support = true,
  capabilities = caps,
  on_attach = function(c, b)
    custom_on_attach(c, b)

    require("clangd_extensions.inlay_hints").setup_autocmd()
    require("clangd_extensions.inlay_hints").set_inlay_hints()
  end,
  on_init = function(c, b)
    require("clangd_extensions.config").setup({
      extensions = {
        inlay_hints = {
          show_parameter_hints = false,
          other_hints_prefix = ': ',
        }
      }
    })
  end
}

lsp.clangd.setup(
  vim.tbl_extend('keep', clangd_config, {
    cmd = {
      os.getenv('CLANGD_PATH') or 'clangd',
      '--background-index',
      '--clang-tidy',
      '--completion-style=detailed',
      '--header-insertion=never',
      '--header-insertion-decorators',
      '--all-scopes-completion',

      -- '--compile-commands-dir=${workspaceFolder}/build',

      '--enable-config',
      '--pch-storage=disk',

      '--log=info',
    }
  })
)

local sumneko_lua_settings = {
  settings = {
    Lua = {
      runtime = {
        version = "LuaJIT",
      },
      diagnostics = {
        globals = { "vim" },
      },
      workspace = {
        library = {
          vim.fn.stdpath('data') .. "/site/pack/packer/opt/emmylua-nvim",
          vim.fn.stdpath('config'),
        },
        maxPreload = 2000,
        preloadFileSize = 50000,
      },
    },
  }
}

lsp.lua_ls.setup(
  vim.tbl_deep_extend('keep', sumneko_lua_settings, default_config)
)

lsp.hls.setup(default_config)
lsp.tsserver.setup(default_config)
lsp.fennel_language_server.setup(default_config)
lsp.rust_analyzer.setup(default_config)
lsp.solargraph.setup(default_config)

-- lsp.sorbet.setup(default_config)
-- lsp.ruby_ls.setup(default_config)

vim.diagnostic.config {
  update_in_insert = false,
  virtual_text = false,
  underline = true
}
