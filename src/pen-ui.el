(require 'hide-mode-line)

(defun kill-buffer-if-not-current (name)
  (ignore-errors
    (if (not (string-equal name (buffer-name)))
        (if (buffer-exists name)
            (progn
              (ignore-errors (kill-buffer name))
              (message (concat "killed buffer " name " because it's slow")))))))

(defun toggle-chrome ()
  (interactive)
  (kill-buffer-if-not-current "*aws-instances*")
  (kill-buffer-if-not-current "*docker-containers*")
  (kill-buffer-if-not-current "*docker-images*")
  (kill-buffer-if-not-current "*docker-machines*")
  (if (bound-and-true-p global-display-line-numbers-mode)
      (progn
        (if lsp-mode
            (lsp-headerline-breadcrumb-mode -1))
        (global-display-line-numbers-mode -1)
        (if (sor header-line-format)
            (setq header-line-format
                  (s-replace-regexp "^    " "" header-line-format)))
        (global-hide-mode-line-mode 1)
        (visual-line-mode -1))
    (progn
      (if lsp-mode
          (lsp-headerline-breadcrumb-mode 1))
      (global-display-line-numbers-mode 1)
      (if (sor header-line-format)
          (setq header-line-format (concat "    " header-line-format)))
      (global-hide-mode-line-mode -1)
      (visual-line-mode 1))))

(toggle-chrome)
(toggle-chrome)

(global-set-key (kbd "<S-f4>") 'toggle-chrome)

(provide 'pen-ui)