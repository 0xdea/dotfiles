# dotfiles

[![](https://img.shields.io/github/stars/0xdea/dotfiles.svg?style=flat&color=yellow)](https://github.com/0xdea/dotfiles)
[![](https://img.shields.io/github/forks/0xdea/dotfiles.svg?style=flat&color=green)](https://github.com/0xdea/dotfiles)
[![](https://img.shields.io/github/watchers/0xdea/dotfiles.svg?style=flat&color=red)](https://github.com/0xdea/dotfiles)
[![](https://img.shields.io/badge/stow-2.3.1-violet)](https://www.gnu.org/software/stow/)
[![](https://img.shields.io/badge/twitter-%400xdea-blue.svg)](https://twitter.com/0xdea)
[![](https://img.shields.io/badge/mastodon-%40raptor-purple.svg)](https://infosec.exchange/@raptor)

> "When I am working on a problem I never think about beauty, but when I have
> finished, if the solution is not beautiful, I know it is wrong." 
>
> -- R. Buckminster Fuller

My dotfiles are currently managed with [GNU Stow]. Each top-level directory
represents a group of configurations: 

* [**bash**](bash). Configuration files for the Bash shell.
* [**git**](git). Configuration files for the Git version control system.
* [**nvim**](nvim). Configuration files for the [Neovim] editor.
* [**x11**](x11). Configuration files for the X Window system.

> [!WARNING]
> You shouldn't blindly install my dotfiles unless you know what you're doing.

## Usage

You can install (by symlinking) the configurations of a group using:

```sh
git clone https://github.com/0xdea/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
stow -v bash nvim x11
```

Use `-n` to just show what it _would_ install (dry run).

You can update the source using git:

```sh
cd ~/.dotfiles
git add .
git status
git commit -a -m "feat: nvim: update"
git push
```

## See also

* <https://github.com/jonhoo/configs>
* <https://youtu.be/ycMiMDHopNc>

[GNU Stow]: https://www.gnu.org/software/stow/
[Neovim]: https://neovim.io/
