;;; git-show.el --- FAST search of committed files in a git repo.

;; This file is not part of Emacs

;; Copyright (C) 2011 Jose Pablo Barrantes
;; Created: 18/Dec/11
;; Version: 0.1.0

;;; Installation:

;; Put this file where you defined your `load-path` directory or just
;; add the following line to your emacs config file:

;; (load-file "/path/to/git-show.el")

;; Finally require it:

;; (require 'git-show)

;; Requirements:

;; http://www.emacswiki.org/emacs/Anything

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(require 'anything)

;;; --------------------------------------------------------------------
;;; - Customization
;;;
(defcustom git-show/git-exec
  "git --no-pager "
  "Git executable."
  :group 'git-show
  :type 'string)

(defcustom git-show/sha-command
  "log --pretty=format:'%h %an %ar %s'"
  "Git show SHA command."
  :group 'git-show
  :type 'string)

(defcustom git-show/tmp-dir
  "/tmp/git-show/"
  "Git show temp directory."
  :group 'git-show
  :type 'string)

;;; --------------------------------------------------------------------
;;; - Vars
;;;
(defvar git-show/ls-tree
  "cd %s && git ls-tree --name-only -r %s "
  "Git show ls-tree command.")

;;; --------------------------------------------------------------------
;;; - Helpers
;;;
(defun git-show/tmp-file (sha candidate)
  "Creates the temp file name for the git-show function."
  (concat sha ":" (replace-regexp-in-string  ".*/" "" candidate)))

(defun git-show/tmp-file-full-path (tmp-file)
  "Adds the `git-show/tmp-dir' directory to the tmp-file name. "
  (concat git-show/tmp-dir tmp-file))

(defun git-show/show-cmd (sha candidate tmp-file-path)
  "Creates the string for the git-show command."
  (concat git-show/git-exec
          "show " sha ":" candidate " >" tmp-file-path))

(defun git-show/find-git-repo (dir)
  "Recursively search for a .git/ directory."
  (if (string= "/" dir)
      (message "not in a git repo.")
    (if (file-exists-p (expand-file-name ".git/" dir))
        dir
      (git-show/find-git-repo (expand-file-name "../" dir)))))

(defun git-show/make-tmp-dir ()
  "Test if the temp directory exists, if not it creates it."
  (interactive)
  (if (not (file-exists-p git-show/tmp-dir))
      (make-directory git-show/tmp-dir)))

(defun git-show/mode-line (commit-msg)
  "Display the context on which the file is being searched."
  (concat "[Context: " commit-msg "]"))

(defun git-show/sha ()
  "Used internally to get the SHA for rendering the files properly via
  the git-ls-tree utility."
  (anything-other-buffer
   '((name . "Get SHA")
     ;; TODO: Refresh search if executed in a new repo context,
     ;; results seem to be getting cached or something... I don't know
     ;; how to refresh it. ATM if this is executed in a different
     ;; repo, it will render the git-log(1) of the first one!.
     (candidates . git-show/sha-init)
     (candidate-number-limit . 9999)
     (candidates-in-buffer)
     (action . (lambda (candidate) candidate)))
   "*Git Show*"))

(defun git-show/sha-init ()
  "Initialize git-show/sha via `git-show/git-exec' and
  `git-show/sha-command' process for identifing the SHA to use for the
  file search."
  (setq mode-line-format
        '(" " mode-line-buffer-identification " "
          (line-number-mode "%l") " "
          (:eval (propertize "(Git Show Process Running) "
                             'face '((:foreground "red"))))))
  (setq cmd
        (concat git-show/git-exec git-show/sha-command))
  (prog1
      (start-process-shell-command "git-show-process" nil cmd)

    (set-process-sentinel (get-process "git-show-process")
                          #'(lambda (process event)
                              (when (string= event "finished\n")
                                (kill-local-variable 'mode-line-format)
                                (with-anything-window
                                  (anything-update-move-first-line)))))))

;;; --------------------------------------------------------------------
;;; - Interctive Functions
;;;
;;;###autoload
(defun git-show ()
  "Use the initially used SHA for listing the files and search for a
  specific one to display its content."
  (interactive)
  (setq sha-msg (git-show/sha))
  (setq sha (replace-regexp-in-string " .*" "" sha-msg))
  (setq git-show-mode-line (git-show/mode-line sha-msg))
  (anything-other-buffer
   '((name . "Get file")
     (init
      . (lambda ()
          (setq cmd
                (format git-show/ls-tree
                        (git-show/find-git-repo default-directory)
                        sha))
          (call-process-shell-command
           cmd nil (anything-candidate-buffer 'global))))
     (type . string)
     (mode-line . git-show-mode-line)
     (candidate-number-limit . 9999)
     (candidates-in-buffer)
     (action . (lambda (candidate)
                 (kill-local-variable 'mode-line-format)
                 (setq tmp-file (git-show/tmp-file sha candidate))
                 (setq tmp-file-path (git-show/tmp-file-full-path tmp-file))
                 (setq show-cmd (git-show/show-cmd
                                 sha
                                 candidate
                                 tmp-file-path))
                 (git-show/make-tmp-dir)
                 (call-process-shell-command show-cmd)
                 (find-file tmp-file-path)
                 (setq mode-line-format
                       '(" " mode-line-buffer-identification " "
                         (:eval (propertize
                                 (replace-regexp-in-string
                                  "\\([0-9a-fA-F]\\{7\\}\\)" "" sha-msg)
                                 'face '((:foreground "yellow"))))))
                 (when (fboundp 'redraw-modeline) (redraw-modeline)))))
   "*Git Show*")); TODO: Clean this up...

;;;###autoload
(defun git-show-rm-tmp ()
  "Removes `git-show/tmp-dir' directory"
  (interactive)
  (if (file-exists-p git-show/tmp-dir)
      (delete-directory git-show/tmp-dir t)))

(provide 'git-show)
;; git-show.el ends here
