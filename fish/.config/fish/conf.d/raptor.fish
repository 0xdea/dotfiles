# general settings
set -g fish_greeting ""

function fish_title
  echo (whoami)@(hostname): (prompt_pwd)
end

fish_add_path /usr/local/bin
fish_add_path $HOME/.cargo/bin
fish_add_path $HOME/.local/bin

alias vi "nvim"
#alias up "sudo -i"
alias up "sudo su -"

# Linux
if test (uname) = "Linux"

  fish_add_path /opt/oracle

  alias fd "fdfind"
  alias smbclient "smbclient -mSMB3"
  alias nat "smb-nat"
  alias script "set -x SCRIPT yes; command script -af"

  if type -q dircolors
    eval (dircolors -c)
  end

# macOS
else if test (uname) = "Darwin"

  fish_add_path /opt/homebrew/bin
  fish_add_path /opt/homebrew/sbin

  alias script "command script -aF"

end

# script
if set -q SCRIPT

  function fish_prompt
    echo "$(date +%Y-%m-%d\ %T) $(prompt_pwd)> "
  end

end
