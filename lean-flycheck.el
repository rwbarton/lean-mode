;; Copyright (c) 2014 Microsoft Corporation. All rights reserved.
;; Released under Apache 2.0 license as described in the file LICENSE.
;;
;; Author: Soonho Kong
;;

(require 'lean-settings)

(defun lean-flycheck-command ()
  "Concat lean-flychecker-checker-name with options"
  (cl-concatenate 'list
                  `(,(lean-get-executable lean-flycheck-checker-name))
                  lean-flycheck-checker-options
                  '("--cache")
                  '(source-original)
                  '("--")
                  '(source-inplace)))

(defun lean-flycheck-init ()
  "Initialize lean-flychek checker"
  (eval
   `(flycheck-define-checker lean-checker
      "A Lean syntax checker."
      :command ,(lean-flycheck-command)
      :error-patterns
      ((error line-start "FLYCHECK_BEGIN ERROR\n"
              (file-name) ":" line ":" column  ": error: "
              (minimal-match
               (message (one-or-more (one-or-more not-newline) "\n") ))
              "FLYCHECK_END" line-end)
       (warning line-start "FLYCHECK_BEGIN WARNING\n"
                (file-name) ":" line ":" column  ": warning "
                (minimal-match
                 (message (one-or-more (one-or-more not-newline) "\n") ))
                "FLYCHECK_END" line-end))
      :modes (lean-mode)))
  (add-to-list 'flycheck-checkers 'lean-checker))

(defun lean-flycheck-turn-on ()
  (interactive)
  (unless lean-flycheck-use
    (when (interactive-p)
      (message "use flycheck in lean-mode"))
    (setq lean-flycheck-use t))
  (flycheck-mode t))

(defun lean-flycheck-turn-off ()
  (interactive)
  (when lean-flycheck-use
    (when (interactive-p)
      (message "no flycheck in lean-mode")))
  (flycheck-mode 0)
  (setq lean-flycheck-use nil))

(defun lean-flycheck-toggle-use ()
  (interactive)
  (if lean-flycheck-use
      (lean-flycheck-turn-off)
    (lean-flycheck-turn-on)))

(eval-after-load "flycheck"
  '(defadvice flycheck-try-parse-error-with-pattern
     (after lean-flycheck-try-parse-error-with-pattern activate)
     "Add 1 to error-column."
     (let* ((err ad-return-value)
            (col (flycheck-error-column err)))
       (when (and (string= major-mode "lean-mode") col)
         (setf (flycheck-error-column ad-return-value) (1+ col))))))

(defun lean-flycheck-delete-temporaries ()
  "Delete temporaries files generated by flycheck."
  (when (eq major-mode 'lean-mode)
    (let* ((filename (buffer-file-name))
           (tempname (format "%s_%s"
                             flycheck-temp-prefix
                             (file-name-nondirectory filename)))
           (tempbase (file-name-base tempname))
           (tempfile (expand-file-name tempbase
                                       (file-name-directory filename)))
           (exts     '(".ilean" ".d" ".olean"))
           (tempfiles (--map (concat tempfile it) exts)))
      (mapc #'flycheck-safe-delete tempfiles))))

(provide 'lean-flycheck)
