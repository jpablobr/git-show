git-show
========

## git-show(1) + Emacs

**FAST** and descriptive file search throughout your git(1) repo's
  history.

This mode exists to allow [Emacs](http://www.gnu.org/software/emacs/)
execute git-show(1) processes dumping the results into a buffer
attempting to use its same mode. For example; if it's a shell script, it
will open the new buffer using sh-mode.

## Functions:

    M-x git-show

Indexes current git(1) repo via git-ls-tree(1) making it super FAST.

    M-x git-show-file

Aearch a file from a previews commit via its SHA and will display it
using its defined modes (via `auto-mode-alist` var).

    M-x git-show-rm-tmp

Removes the temp directory `/tmp/git-show/`

## Screencast:

<iframe src="http://player.vimeo.com/video/33925715?title=0&amp;byline=0&amp;portrait=0" width="400" height="300" frameborder="0" webkitAllowFullScreen mozallowfullscreen allowFullScreen></iframe><p><a href="http://vimeo.com/33925715">Emacs git-show</a> from <a href="http://vimeo.com/user695842">jpablobr</a> on <a href="http://vimeo.com">Vimeo</a>.</p>

## Installation:

In your emacs config:

    (add-to-list 'load-path "~/.emacs.d/load/path/git-show.el")
    (require 'git-show)

## TODO / Thoughts

![Wonka](https://github.com/jpablobr/git-show/raw/master/wonka.gif)
