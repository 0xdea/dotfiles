return {

  {
    "itchyny/lightline.vim",

    lazy = false,

    config = function()
      vim.opt.showmode = false
      vim.g.lightline = {
        colorscheme = "sonokai"
      }
    end
  }

}
