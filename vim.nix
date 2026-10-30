{ config, lib, pkgs, ... }:

{
  # halfway sophisticated neovim + lsp + syntax highlighting setup
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withRuby = false;
    withPython3 = false;
    configure = {
      packages.nix.start = with pkgs.vimPlugins; [
        nvim-lspconfig
        nvim-lint
        gruvbox
        (nvim-treesitter.withPlugins (grammars: [
          grammars.nix
          grammars.bash
        ]))
      ];
      customLuaRC = ''
        vim.g.mapleader = ' '
        vim.opt.number = true
        vim.opt.signcolumn = 'yes'
        vim.opt.expandtab = true
        vim.opt.shiftwidth = 2
        vim.opt.completeopt = { 'menuone', 'noselect', 'popup' }
        vim.diagnostic.config({ virtual_text = true })
        vim.cmd.colorscheme('gruvbox')

        -- Tree-sitter highlighting is more precise than the regex syntax file
        vim.api.nvim_create_autocmd('FileType', {
          pattern = 'nix',
          callback = function(args) vim.treesitter.start(args.buf) end,
        })

        -- Without further settings nixd takes packages and NixOS options
        -- from <nixpkgs>, which is the installer's channel.
        vim.lsp.config('nixd', {
          settings = { nixd = { formatting = { command = { 'nixfmt' } } } },
        })
        vim.lsp.enable('nixd')

        -- Builtin LSP defaults: K hover, grn rename, gra code action,
        -- grr references, [d / ]d diagnostics. Add gd for definitions and
        -- <space>f to format (nixfmt via nixd), which also happens on save.
        vim.api.nvim_create_autocmd('LspAttach', {
          callback = function(args)
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
            vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = args.buf })
            vim.keymap.set('n', '<leader>f', vim.lsp.buf.format, { buffer = args.buf })
            vim.api.nvim_create_autocmd('BufWritePre', {
              group = vim.api.nvim_create_augroup('lsp-format-' .. args.buf, {}),
              buffer = args.buf,
              callback = function()
                vim.lsp.buf.format({ bufnr = args.buf, id = client.id })
              end,
            })
          end,
        })

        require('lint').linters_by_ft = { nix = { 'statix', 'deadnix' } }
        vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
          callback = function() require('lint').try_lint() end,
        })
      '';
    };
  };

  environment.systemPackages = [
    (lib.hiPrio config.programs.neovim.finalPackage) # override original `vim` alias
    pkgs.deadnix
    pkgs.nixd
    pkgs.nixfmt
    pkgs.statix
  ];
}
