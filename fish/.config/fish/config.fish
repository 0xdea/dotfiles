#if status is-interactive
#end

# settings
set -g fish_greeting ""

# path
fish_add_path /opt/homebrew/bin
fish_add_path /opt/homebrew/sbin
fish_add_path /usr/local/bin
fish_add_path $HOME/.cargo/bin
fish_add_path $HOME/.local/bin

# aliases
alias vi "nvim"
alias up "sudo -i"
alias ls "eza"
