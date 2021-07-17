(let ((pendir (concat (getenv "EMACSD") "/pen.el"))
      (contribdir (concat (getenv "EMACSD") "/pen-contrib.el")))
  (add-to-list 'load-path (concat pendir "/src"))
  (add-to-list 'load-path (concat contribdir "/src"))
  (add-to-list 'load-path (concat pendir "/src/in-development")))

;; Add Hyper and Super
(defun add-event-modifier (string e)
  (let ((symbol (if (symbolp e) e (car e))))
    (setq symbol (intern (concat string
                                 (symbol-name symbol))))
    (if (symbolp e)
        symbol
      (cons symbol (cdr e)))))

(defun superify (prompt)
  (let ((e (read-event)))
    (vector (if (numberp e)
                (logior (lsh 1 23) e)
              (if (memq 'super (event-modifiers e))
                  e
                (add-event-modifier "s-" e))))))

(defun hyperify (prompt)
  (let ((e (read-event)))
    (vector (if (numberp e)
                (logior (lsh 1 24) e)
              (if (memq 'hyper (event-modifiers e))
                  e
                (add-event-modifier "H-" e))))))

;; These bindings will allow you to use Space Cadet keyboard modifiers
;; https://mullikine.github.io/posts/add-super-and-hyper-to-terminal-emacs/
;; C-M-6 = Super (s-)
;; C-M-\ = Hyper (H-)
;; Pen.el will make use of H-
(define-key global-map (kbd "C-M-6") nil)             ;For GUI
(define-key function-key-map (kbd "C-M-6") 'superify) ;For GUI
(define-key function-key-map (kbd "C-M-^") 'superify)
(define-key function-key-map (kbd "C-^") 'superify)
(define-key global-map (kbd "C-M-\\") nil) ;Ensure that this bindings isnt taken
(define-key function-key-map (kbd "C-M-\\") 'hyperify)

;; Ensure that you have yamlmod

;; https://github.com/perfectayush/emacs-yamlmod
(if module-file-suffix
    (progn
      (module-load (concat (getenv "YAMLMOD_PATH") "/target/release/libyamlmod.so"))
      (add-to-list 'load-path (getenv "YAMLMOD_PATH"))
      (require 'yamlmod)
      (require 'yamlmod-wrapper)))


(require 'pen)
(pen 1)

;; Camille-complete (because I press SPC to replace)
(defalias 'camille-complete 'pen-run-prompt-function)

(require 'selected)
(define-key selected-keymap (kbd "SPC") 'pen-run-prompt-function)
(define-key selected-keymap (kbd "M-SPC") 'pen-run-prompt-function)

(define-key pen-map (kbd "H-TAB r") 'pen-run-prompt-function)
(define-key pen-map (kbd "M-1") #'pen-company-filetype)
(define-key pen-map (kbd "H-P") 'pen-complete-long)
(define-key pen-map (kbd "H-TAB g") 'pen-generate-prompt-functions)
(define-key pen-map (kbd "H-s") 'fz-pen-counsel)
(define-key pen-map (kbd "H-TAB s") 'pen-filter-with-prompt-function)

(require 'pen-contrib)
;; from contrib
(require 'pen-org-brain)
(define-key org-brain-visualize-mode-map (kbd "C-c a") 'org-brain-asktutor)
(define-key org-brain-visualize-mode-map (kbd "C-c t") 'org-brain-show-topic)
(define-key org-brain-visualize-mode-map (kbd "C-c d") 'org-brain-describe-topic)

(require 'pen-org-roam)

;; Prompts discovery
;; This is where discovered prompts repositories are placed
(setq pen-prompts-library-directory (f-join user-emacs-directory "prompts-library"))
;; This is how many repositories deep pen will look for new prompts repositories that are linked to eachother
(setq pen-prompt-discovery-recursion-depth 5)
;; Personal prompts repository
(setq pen-prompts-directory (f-join user-emacs-directory "prompts"))

;; nlsh
(setq pen-nlsh-histdir (f-join user-emacs-directory "comint-history"))

;; Initial load of prompt functions
(pen-generate-prompt-functions)

;; For docker
(if (not (variable-p 'user-home-directory))
    (defvar user-home-directory nil))
(setq user-home-directory (or user-home-directory "/root"))

;; Company
(setq company-auto-complete nil)
(setq company-auto-complete-chars '())
(setq company-minimum-prefix-length 0)
(setq company-idle-delay 0)
(setq company-minimum-prefix-length 1)
(setq company-tooltip-limit 20) ; bigger popup window
(setq company-idle-delay 0.3)  ; decrease delay before autocompletion popup shows
(setq company-echo-delay 0)    ; remove annoying blinking
(setq company-begin-commands '(self-insert-command)) ; start autocompletion only after typing
(add-hook 'after-init-hook 'global-company-mode)

(require 'xt-mouse)
(xterm-mouse-mode)
(require 'mouse)
(xterm-mouse-mode t)
;; (defun track-mouse (e))

;; Automatically check if OpenAI key exists and ask for it otherwise
(call-interactively 'pen-add-key-openai)
;; (call-interactively 'pen-add-key-booste)

;; Simplify the experience -- Super newb mode
(ignore-errors (switch-to-buffer "*scratch*"))

(defun pen-super-newb-dired-prompts ()
  (interactive)
  (dired pen-prompts-directory))

(defun pen-super-newb-scratch ()
  (interactive)
  (dired pen-prompts-directory))

(defvar pen-super-noob-mode t)

(if pen-super-noob-mode
    (progn
      (define-key pen-map (kbd "M-p") 'pen-super-newb-dired-prompts)
      (define-key pen-map (kbd "M-s") 'pen-super-newb-scratch)
      (define-key pen-map (kbd "M-r") 'pen-run-prompt-function)
      (define-key pen-map (kbd "M-TAB") 'pen-company-filetype)
      (define-key pen-map (kbd "M-l") 'pen-complete-long)
      (define-key pen-map (kbd "M-g") 'pen-generate-prompt-functions)
      (define-key pen-map (kbd "M-c") 'fz-pen-counsel)
      (define-key pen-map (kbd "M-m") 'right-click-context-menu)
      (define-key selected-keymap (kbd "TAB") 'pen-filter-with-prompt-function)))

(package-install 'ivy)
(require 'ivy)
(ivy-mode 1)