return {

  {
    "sainnhe/sonokai",

    config = function()
      vim.g.sonokai_style = "atlantis"
      vim.g.sonokai_better_performance = 1
      vim.g.sonokai_colors_override = { bg0 = { "#222222", "232" } }
      vim.g.sonokai_disable_italic_comment = 1
      vim.cmd.colorscheme("sonokai")
    end
  }

}
