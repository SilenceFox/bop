Quickly use Emacs bookmarks in terminal sessions, simple, stupid, useful, just bop it up.

## Install

### Fish

Requires Fish, wget, and fzf (unless `BOP_USE_FZF` is set to `0`). Run in Fish:

```fish
mkdir -p "$__fish_config_dir/functions"
wget -O "$__fish_config_dir/functions/bop.fish" https://raw.githubusercontent.com/SilenceFox/bop/main/bop.fish
and source "$__fish_config_dir/functions/bop.fish"
```

Run `bop` to list bookmarks, `bop 1` to jump by number, or `bop project` to search by name.

Optional settings in `~/.config/fish/config.fish`:

```fish
set -gx BOP_BOOKMARK_PATH ~/.emacs.d/bookmarks # Default bookmark file
set -gx BOP_USE_FZF 1 # Set to 0 to search without fzf
```

### Eshell

Install [Dash](https://github.com/magnars/dash.el) with `M-x package-install RET dash RET`.

Download `bop.el` into your Emacs configuration directory:

```sh
mkdir -p ~/.emacs.d
wget -O ~/.emacs.d/bop.el https://raw.githubusercontent.com/SilenceFox/bop/main/bop.el
```

Adjust the destination if your Emacs configuration lives elsewhere. Add to your init file:

```elisp
(load (expand-file-name "bop.el" user-emacs-directory) nil t)
```

Use the same `bop`, `bop 1`, and `bop project` commands in Eshell.
Requires fzf unless `BOP_USE_FZF` is `0`. By default, bookmarks are read
from Emacs's `bookmark-default-file`. Optional settings, before loading bop:

```elisp
(setenv "BOP_BOOKMARK_PATH" (expand-file-name "bookmarks" user-emacs-directory))
(setenv "BOP_USE_FZF" "1") ; Set to "0" to search without fzf
```

## Keeping it simple

There are a few things I don't plan to do:

- Port bop beyond Fish and Eshell.
- Add bookmark or project management.
- Add bookmark reordering.
- Rewrite it in Rust.

Favorites and project managers tend to get more complicated than I need.
I just want to get to a bookmark and get on with my day. Emacs already
keeps the bookmarks; bop helps me get there from Fish or Eshell.

This is tailored to my own use cases. If you'd like something extra,
you're welcome to fork it and make it yours. Just bop it up.
