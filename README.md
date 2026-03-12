# dotfiles

[![](https://img.shields.io/github/stars/0xdea/dotfiles.svg?style=flat&color=yellow)](https://github.com/0xdea/dotfiles)
[![](https://img.shields.io/github/forks/0xdea/dotfiles.svg?style=flat&color=green)](https://github.com/0xdea/dotfiles)
[![](https://img.shields.io/github/watchers/0xdea/dotfiles.svg?style=flat&color=red)](https://github.com/0xdea/dotfiles)
[![](https://img.shields.io/badge/stow-2.3.1-violet)](https://www.gnu.org/software/stow/)
[![](https://img.shields.io/badge/twitter-%400xdea-blue.svg)](https://twitter.com/0xdea)
[![](https://img.shields.io/badge/mastodon-%40raptor-purple.svg)](https://infosec.exchange/@raptor)

> "When I am working on a problem I never think about beauty, but when I have finished, if the solution is not
> beautiful, I know it is wrong."
>
> -- R. Buckminster Fuller

My Linux and macOS dotfiles are currently managed with [GNU Stow]. Each top-level directory represents a configuration
package:

- [**base16**](base16). Personalized color schemes based on [Tinted Theming].
- [**bash**](bash). Configuration files for the Bash shell.
- [**fish**](fish). Configuration files for the [fish] shell.
- [**git**](git). Configuration files for the Git version control system.
- [**iterm2**](iterm2). Configuration files for the [iTerm2] macOS terminal emulator.
- [**nvim**](nvim). Configuration files for the [Neovim] editor.
- [**pics**](pics). Some pictures for backgrounds and avatars.
- [**tmux**](tmux). Configuration files for the [tmux] terminal multiplexer.
- [**x11**](x11). Configuration files for X Window and the [i3] window manager.
- [**zed**](zed). Configuration files for the [Zed] editor.

> [!WARNING]
> You shouldn't blindly install my dotfiles unless you know what you're doing.

## Usage

You can install (by symlinking) the configurations of a package using:

```sh
git clone https://github.com/0xdea/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
stow -vn base16 fish git nvim tmux x11 # dry run
stow -v base16 fish git nvim tmux x11 # install packages
```

You can update the package source repository using git:

```sh
cd ~/.dotfiles
git add .
git status
git commit -am "feat: nvim: update"
git push
```

## See also

- <https://github.com/jonhoo/configs>
- <https://youtu.be/ycMiMDHopNc>

[GNU Stow]: https://www.gnu.org/software/stow/
[Tinted Theming]: https://github.com/tinted-theming
[fish]: https://fishshell.com/
[iTerm2]: https://iterm2.com/
[Neovim]: https://neovim.io/
[tmux]: https://tmuxcheatsheet.com/
[i3]: https://i3wm.org/
[Zed]: https://zed.dev/
