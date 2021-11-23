(require 'term)

(setq explicit-shell-file-name "/bin/bash")

;; I can't abolish C-c from all the minor modes
;; But at least I can control it.
(define-prefix-command 'pen-term-c-c)
(define-prefix-command 'pen-term-c-x)
(define-prefix-command 'pen-term-c-c-esc)

(defun term-raw-or-kill ()
  (interactive)
  (if (not (term-check-proc (current-buffer)))
      (kill-buffer)
    (progn
      (shut-up-c (message "sending C-d"))
      (term-send-raw))))


(defun term-send-function-key ()
  (interactive)
  (let* ((char last-input-event)
         (output (cdr (assoc (str char) term-function-key-alist))))
    (term-send-raw-string output)))

(defconst term-function-key-alist `(("f1" . ,(read-kbd-macro "<ESC> OP"))
                                    ("80" . ,(read-kbd-macro "<ESC> OP"))
                                    ("f2" . ,(read-kbd-macro "<ESC> OQ"))
                                    ("81" . ,(read-kbd-macro "<ESC> OQ"))
                                    ("f3" . ,(read-kbd-macro "<ESC> OR"))
                                    ("82" . ,(read-kbd-macro "<ESC> OR"))
                                    ("f4" . ,(read-kbd-macro "<ESC> OS"))
                                    ("83" . ,(read-kbd-macro "<ESC> OS"))
                                    ;;("f2" . "\eOQ")
                                    ;;("f3" . "\eOR")
                                    ;;("f4" . "\eOS")
                                    ))

(defun pen-term-paste ()
  (interactive)
  (if (>= (prefix-numeric-value current-prefix-arg) 4)
      (term--xterm-paste)
    (term-paste)))

(defun pen-term-clean-user-prompt (&optional input)
  (interactive (list (pen-preceding-text-line)))

  (let ((ret
         (pen-snc "pen-clean-user-prompt" input)))
    (if (interactive-p)
        (xc ret)
      ret)))

(defun pen-term-get-line-at-point ()
  (interactive)
  (let* ((row (+ (term-current-row) 1))
         (col (term-current-column))
         (buf (new-buffer-from-string (buffer-contents)))
         (height term-height)
         (linecontents (with-current-buffer buf
                         (let ((nbackhistory (- (count-lines (point-min) (point-max)) height)))
                           ;; term-height
                           (goto-line (+ row nbackhistory))
                           (move-to-column col t)
                           (thing-at-point 'line)))))
    (kill-buffer buf)
    (xc (chomp linecontents) t)
    linecontents))

(defun pen-term-set-raw-map ()
  (interactive)
  (let* ((map (make-keymap))
         (esc-map (make-keymap))
         (i 0))

    (define-key map (kbd "C-c") #'pen-term-c-c)
    ;; (define-key map (kbd "<xterm-paste>") #'pen-term-paste)
    (define-key map (kbd "C-x") #'pen-term-c-x)
    (define-key map (kbd "C-c ESC") #'pen-term-c-c-esc)

    ;; Send the function key to terminal
    (dolist (spec term-function-key-alist)
      (define-key map
        (read-kbd-macro (message (format "C-c <%s>" (car spec))))
        'term-send-function-key))

    (while (< i 128)
      ;; if not C-c
      (if (not (or (cl-equalp i 3)
                   (cl-equalp i 24)))
          (define-key map (make-string 1 i) #'term-send-raw))

      (define-key map (concat "\C-c" (make-string 1 i)) 'term-send-raw)
      ;; Avoid O and [. They are used in escape sequences for various keys.
      (unless (or (eq i ?O) (eq i 27) (eq i 91))
        (define-key esc-map (make-string 1 i) 'term-send-raw-meta))
      (setq i (1+ i)))
    (define-key map [remap self-insert-command] 'term-send-raw)
    (define-key map "\e" esc-map)
    (define-key esc-map (make-string 1 27) #'term-send-raw) ;;Send ESC, not M-ESC

    ;; Added nearly all the 'gray keys' -mm

    (if (featurep 'xemacs)
        (define-key map [button2] 'term-mouse-paste)
      (define-key map [mouse-2] 'term-mouse-paste))
    (define-key map (kbd "C-p") 'term-send-raw)
    (define-key map [up] 'term-send-up)
    (define-key map [down] 'term-send-down)
    (define-key map [right] 'term-send-right)
    (define-key map [left] 'term-send-left)
    (define-key map [C-up] 'term-send-ctrl-up)
    (define-key map [C-down] 'term-send-ctrl-down)
    (define-key map [C-right] 'term-send-ctrl-right)
    (define-key map [C-left] 'term-send-ctrl-left)
    (define-key map [delete] 'term-send-del)
    (define-key map [deletechar] 'term-send-del)
    (define-key map [backspace] 'term-send-backspace)
    (define-key map [home] 'term-send-home)
    (define-key map [end] 'term-send-end)
    (define-key map [insert] 'term-send-insert)
    (define-key map [S-prior] 'scroll-down)
    (define-key map [S-next] 'scroll-up)
    (define-key map [S-insert] 'term-paste)
    (define-key map [prior] 'term-send-prior)
    (define-key map [next] 'term-send-next)
    ;; (define-key map [xterm-paste] #'term--xterm-paste)
    (define-key map [xterm-paste] #'pen-term-paste)
    (define-key map (kbd "C-d") 'term-raw-or-kill)
    (setq term-raw-map map)
    (setq term-raw-escape-map esc-map))
  (define-key term-raw-map (kbd "M-l") nil)
  (define-key term-raw-map (kbd "M-=") 'my-handle-repls)
  ;; I want M-x to transmit through
  ;; (define-key term-raw-map (kbd "M-x") nil)
  (define-key term-raw-map (kbd "C-c ESC") #'pen-term-c-c-esc)
  (define-key term-raw-map (kbd "C-c M-l") #'term-send-raw-meta)
  (define-key term-raw-map (kbd "C-c C-c") #'term-send-raw)
  (define-key term-raw-map (kbd "C-c M-Y") #'pen-term-clean-user-prompt)
  (define-key term-raw-map (kbd "C-c C-M-i") #'pen-company-complete)
  (define-key term-raw-map (kbd "C-c M-;") #'term-send-raw-meta)
  (define-key term-raw-map (kbd "C-c M-m") #'term-send-raw-meta)

  ;; Super
  (define-key term-raw-map (kbd "C-M-^") nil)
  ;; Hyper
  (define-key term-raw-map (kbd "C-M-\\") nil)

  ;; (define-key term-raw-map (kbd "C-c o") #'tm-edit-v-in-nw)
  ;; (define-key term-raw-map (kbd "C-c O") #'tm-edit-vs-in-nw)
  (define-key term-raw-map (kbd "C-c M-:") #'pp-eval-expression)
  (define-key term-raw-map (kbd "C-c M-x") #'helm-M-x)
  (define-key term-raw-map (kbd "C-x C-x") #'term-send-raw)
  (define-key term-raw-map (kbd "<backtab>") (lambda () (interactive) (term-send-raw-string "[Z")))
  ;; (define-key term-raw-map (kbd "C-s") #'term-line-mode)
  (define-key term-raw-map (kbd "C-c C-j") #'term-line-mode)
  (define-key term-raw-map (kbd "C-c C-h") #'describe-mode)
  ;; (define-key term-raw-map (kbd "C-c h") #'evil-scroll-left)
  ;; (define-key term-raw-map (kbd "C-c H") #'evil-scroll-left)
  ;; (define-key term-raw-map (kbd "C-c l") #'evil-scroll-right)
  ;; (define-key term-raw-map (kbd "C-c L") #'evil-scroll-right)
  (define-key term-raw-map (kbd "C-c Y") #'pen-term-get-line-at-point)
  ;; (define-key term-raw-map (kbd "C-c z L") #'evil-scroll-right)
  (define-key term-raw-map (kbd "C-d") 'term-raw-or-kill)
  ;; (define-key term-raw-map (kbd "C-c M-q v") #'open-in-vim)
  ;; (define-key term-raw-map (kbd "C-c M-q V") #'e/open-in-vim)
  ;; (define-key term-raw-map (kbd "C-c M-q M-V") #'e/open-in-vim)
  ;; (define-key term-raw-map (kbd "C-c M-q M-v") #'open-in-vim)
                                        ;This is like vim's M-q M-m for opening in emacs in the current pane
  )

(define-key term-mode-map (kbd "C-c o") #'tm-edit-v-in-nw)
(define-key term-mode-map (kbd "C-c O") #'tm-edit-vs-in-nw)

(defun pen-term-around-advice (proc &rest args)
  (pen-term-set-raw-map)
  (let ((res (apply proc args)))
    res))
(advice-add 'term :around #'pen-term-around-advice)

;; Not sure why this is not sufficient
(pen-term-set-raw-map)


(term-set-escape-char ?✓)


(defvar termframe nil)

(defun set-termframe (frame)
  "Frame is obtained from the method which calls this function"
  (message (concat "setting " (str frame)))
  (with-current-buffer "*scratch*"
    (setq termframe frame)))

;; this makes it look like this is a regular hook list, which it isn't
;; The thing which calls the functions in =after-make-frame-functions= also supplies
;; the frame as a parameter
(add-hook 'after-make-frame-functions 'set-termframe)

(defun pen-term (program &optional closeframe modename buffer-name reuse)
  (interactive (list (read-string "program:")))
  (if (and buffer-name reuse (get-buffer buffer-name))
      (switch-to-buffer buffer-name)
    (with-current-buffer (term program)
      (if closeframe
          (defset-local termframe-local termframe))
      (let ((modefun (intern (concat (slugify (or modename (s-left 20 program))) "-term-mode"))))
        (if (fboundp modefun)
            (funcall modefun)))

      (if buffer-name
          (rename-buffer buffer-name t)))))

(defun pen-kill-buffer-and-window ()
  "Kill the current buffer and delete the selected window."
  (interactive)
  (let ((window-to-delete (selected-window))
    (buffer-to-kill (current-buffer))
    (delete-window-hook (lambda () (ignore-errors (delete-window)))))
    (unwind-protect
    (progn
      (add-hook 'kill-buffer-hook delete-window-hook t t)
      (if (kill-buffer (current-buffer))
          (when (eq (selected-window) window-to-delete)
              (delete-window))))
      (ignore-errors
       (with-current-buffer buffer-to-kill
           (remove-hook 'kill-buffer-hook delete-window-hook t))))))

(defun pen-term-kill-buffer-and-window ()
  (interactive)
  (if (major-mode-p 'ranger-mode)
      (ranger-close)
    (if (equal 1 (count-windows))
        (ignore-errors (kill-buffer))
      (ignore-errors (pen-kill-buffer-and-window)))))

(defun oleh-term-exec-hook ()
  (let* ((buff (current-buffer))
         (proc (get-buffer-process buff)))
    (set-process-sentinel
     proc
     `(lambda (process event)
        (if (string-match "\\(finished\\|exited\\)" event)
            (progn
              (shut-up-c (message "finished"))
              (if (and (variable-p 'termframe-local)
                       termframe-local)
                  (progn
                    (delete-frame termframe-local t)
                    (with-current-buffer ,buff (ignore-errors (pen-kill-buffer-and-window))))
                (with-current-buffer ,buff (ignore-errors
                                             (pen-term-kill-buffer-and-window))))))))))

(add-hook 'term-exec-hook 'oleh-term-exec-hook)

(defun pen-term-use-utf8 ()
  (set-buffer-process-coding-system 'utf-8-unix 'utf-8-unix))

(add-hook 'term-exec-hook 'pen-term-use-utf8)

(defun pen-term-set-scroll-margin ()
  (make-local-variable 'hscroll-margin)
  (setq hscroll-margin 0)
  (make-local-variable 'scroll-margin)
  (setq scroll-margin 0)
  (make-local-variable 'scroll-conservatively)
  (setq scroll-conservatively 10000))

(add-hook 'term-mode-hook #'pen-term-set-scroll-margin)

(define-key term-mode-map (kbd "M-r") nil)

(defun term-send-binding ()
  "Send the last binding typed through the terminal-emulator
without any interpretation."
  (interactive)
  (term-send-raw-string (this-command-keys)))

(defun term-exec-1 (name buffer command switches)
  ;; We need to do an extra (fork-less) exec to run stty.
  ;; (This would not be needed if we had suitable Emacs primitives.)
  ;; The 'if ...; then shift; fi' hack is because Bourne shell
  ;; loses one arg when called with -c, and newer shells (bash,  ksh) don't.
  ;; Thus we add an extra dummy argument "..", and then remove it.
  (let ((process-environment
           (nconc
            (list
             (format "TERM=%s" term-term-name)
             (format "TERMINFO=%s" data-directory)
             (format term-termcap-format "TERMCAP="
                       term-term-name term-height term-width)

             (format "INSIDE_EMACS=%s,term:%s" emacs-version term-protocol-version)
             (format "LINES=%d" term-height)
             (format "COLUMNS=%d" term-width))
            process-environment))
          (process-connection-type t)
          (inhibit-eol-conversion t)
          (coding-system-for-read 'binary))
    (when (term--bash-needs-EMACSp)
      (push (format "EMACS=%s (term:%s)" emacs-version term-protocol-version)
            process-environment))
    (apply #'start-process name buffer
             "/bin/sh" "-c"
             (format "stty stop undef; stty start undef; unset TTY; stty -nl echo rows %d columns %d sane 2>/dev/null; if [ $1 = .. ]; then shift; fi; exec \"$@\"" term-height term-width)
             ".."
             command switches)))

(defun disable-modes-for-term ()
  (interactive)
  (progn
    (global-display-line-numbers-mode -1)
    (comment
     (global-hide-mode-line-mode 1))
    (visual-line-mode -1)
    (fringe-mode -1))

  (ignore-errors
    (my-mode -1)))

(defun pen-term-around-advice (proc &rest args)
  (let ((res (apply proc args)))
    (disable-modes-for-term)
    res))
(advice-add 'term :around #'pen-term-around-advice)

(use-package eterm-256color
  :ensure t)
(add-hook 'term-mode-hook #'eterm-256color-mode)

;; Not sure why this is required for spacemacs
(defun pen-disable-ivy-mode ()
  (interactive)
  (setq-local ivy-mode nil))

(add-hook 'term-mode-hook 'pen-disable-ivy-mode)

(comment
 (if (cl-search "SPACEMACS" pen-daemon-name)
     (progn
       (remove-hook 'term-mode-hook 'ansi-term-handle-close))))

(defun realign-term-window ()
  (interactive)

  (set-window-margins (selected-window) 0 0)
  (set-window-hscroll (selected-window) 0)
  (set-window-vscroll (selected-window) 0))

;; This fixes the scrolling for rat
;; But I bet it doesn't fix it for DF
(defun term-move-columns (delta)
  (setq term-current-column (max 0 (+ (term-current-column) delta)))
  (let ((point-at-eol (line-end-position)))
    (move-to-column term-current-column t)
    (when (> (point) point-at-eol)
      (put-text-property point-at-eol (point) 'font-lock-face 'default)))

  ;; This is almost a fix
  (realign-term-window)
  ;; it's not a total fix. The margin still appears from time to time
  )


(defun pen-term-get-line-at-point ()
  (interactive)
  (let* ((row (+ (term-current-row) 1))
         (col (term-current-column))
         (buf (new-buffer-from-string (buffer-contents)))
         (height term-height)
         (linecontents (with-current-buffer buf
                         (let ((nbackhistory (- (count-lines (point-min) (point-max)) height)))
                           ;; term-height
                           (goto-line (+ row nbackhistory))
                           (move-to-column col t)
                           (thing-at-point 'line)))))
    (kill-buffer buf)
    (xc (chomp linecontents) t)
    linecontents))

(defun eterm-256color-compile ()
  "If eterm-256color isn't a term type, tic eterm-256color.ti.

If eterm-color doesn't exist, prompt to fetch and compile it.")

(provide 'pen-term)