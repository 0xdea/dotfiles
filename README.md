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
represents a "group" of configs, and you can "install" (by symlinking) the
configs of a group using:

```bash
stow -v <group>
```

You can use `-n` to just show what it _would_ install (dry run).

> [!WARNING]
> Don't blindly install my dotfiles if you don't know what you're doing.

[GNU Stow]: https://www.gnu.org/software/stow/
