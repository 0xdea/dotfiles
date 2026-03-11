# general settings
set -g fish_greeting ""

function fish_title
  echo (whoami)@(hostname): (prompt_pwd)
end

fish_add_path /usr/local/bin
fish_add_path $HOME/.cargo/bin
fish_add_path $HOME/.local/bin

alias vi "nvim"
alias up "sudo -i"
alias script "set -x SCRIPT yes; command script -af"

# Linux
if test (uname) = "Linux"

  fish_add_path /opt/oracle

  alias fd "fdfind"
  alias smbclient "smbclient -mSMB3"
  alias nat "smb-nat"

  if type -q dircolors
    eval (dircolors -c)
  end

# macOS
else if test (uname) = "Darwin"

  fish_add_path /opt/homebrew/bin
  fish_add_path /opt/homebrew/sbin

end

# script
if test "$SCRIPT" = "yes"

  function fish_prompt
    echo "$(date +%Y-%m-%d\ %T) $(prompt_pwd)> "
  end

  alias ls "ls -F"

  set -g fish_color_normal normal
  set -g fish_color_command normal
  set -g fish_color_keyword normal
  set -g fish_color_quote normal
  set -g fish_color_redirection normal
  set -g fish_color_end normal
  set -g fish_color_error normal
  set -g fish_color_param normal
  set -g fish_color_comment normal
  set -g fish_color_match normal
  set -g fish_color_search_match normal
  set -g fish_color_operator normal
  set -g fish_color_escape normal
  set -g fish_color_autosuggestion normal

end
