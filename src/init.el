;;disable splash screen and startup message
(setq inhibit-startup-message t)
(setq initial-scratch-message nil)

(require 'package)

(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
;; Enable ssl
(setq gnutls-algorithm-priority "NORMAL:-VERS-TLS1.3")
(package-initialize)

;; (package-refresh-contents)

(defvar org-roam-v2-ack t)

;; Require dependencies
(require 'shut-up)
;; For org-roam
(require 'emacsql)
(require 'guess-language)
(require 'language-detection)
(require 'org-roam)
(require 'org-brain)
(require 'dash)
(require 'eterm-256color)
;; (require 'flyspell)
(require 'evil)
(require 'popup)
(require 'right-click-context)
(require 'projectile)
(require 'transient)
(require 'iedit)
(require 'ht)
(require 'helm)
(require 'memoize)
(require 'ivy)
(require 'counsel)
(require 'yaml-mode)
(require 'pp)
(require 'yaml)
(require 's)
(require 'f)
;; builtin
;; (require 'cl-macs)
(require 'company)
(require 'selected)
(require 'yasnippet)
(require 'pcsv)
(require 'sx)
(require 'pcre2el)
(require 'cua-base)
(require 'helpful)

(let ((openaidir (f-join user-emacs-directory "openai-api.el"))
      (openaihostdir (f-join user-emacs-directory "host/openai-api.el"))
      (pendir (f-join user-emacs-directory "pen.el"))
      (penhostdir (f-join user-emacs-directory "host/pen.el"))
      (contribdir (f-join user-emacs-directory "pen-contrib.el"))
      (contribhostdir (f-join user-emacs-directory "host/pen-contrib.el")))

  (if (f-directory-p (f-join openaihostdir "src"))
      (setq openaidir openaihostdir))
  (add-to-list 'load-path openaidir)
  (require 'openai-api)

  (if (f-directory-p (f-join penhostdir "src"))
      (setq pendir penhostdir))
  (add-to-list 'load-path (f-join pendir "src"))
  (require 'pen)

  (add-to-list 'load-path (f-join pendir "src/in-development"))
  (add-to-list 'load-path (f-join contribdir "src"))

  (load (f-join contribdir "src/init-setup.el"))
  (load (f-join contribdir "src/pen-contrib.el"))

  (load (f-join pendir "src/pen-example-config.el")))
