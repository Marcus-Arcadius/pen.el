(require 'clojure-mode)
(require 'cider)
(require 'ob-clojure)

(require 'clomacs)

(my/with 'cider
         ;; Fixes super annoying message
         (setq cider-allow-jack-in-without-project t))

(defun my/4clojure-check-and-proceed ()
  "Check the answer and show the next question if it worked."
  (interactive)
  (let ((result (4clojure-check-answers)))
    (unless (string-match "failed." result)
       (4clojure-next-question))))

(define-key clojure-mode-map (kbd "C-c C-c") nil)
(define-key cider-mode-map (kbd "C-c 4") 'my/4clojure-check-and-proceed)
(define-key cider-mode-map (kbd "C-c C-c") nil)

(require 'monroe)
(add-hook 'clojure-mode-hook 'clojure-enable-monroe)

(define-key monroe-interaction-mode-map (kbd "M-.") nil)
(define-key monroe-interaction-mode-map (kbd "C-c C-r") nil)
(define-key cider-mode-map (kbd "M-.") nil)

(defun pen-cider-macroexpand-1 ()
  (interactive)
  (save-excursion
    (special-lispy-different)
    (cider-macroexpand-1)
    (special-lispy-different)))

(defun pen-cider-macroexpand-1-or-copy ()
  (interactive)
  (if (selected)
      (my/copy)
    (call-interactively 'pen-cider-macroexpand-1)))

(define-key clojure-mode-map (kbd "M-w") #'pen-cider-macroexpand-1-or-copy)

(defmacro pen-cider-eval-return-handler (&rest code)
  "Make a handler for the result."
  `(nrepl-make-response-handler (or buffer (current-buffer))
                                (lambda (buffer value)
                                  (with-current-buffer buffer
                                    (insert
                                     (if (derived-mode-p 'cider-clojure-interaction-mode)
                                         (format "\n%s\n" value)
                                       value))))
                                (lambda (_buffer out)
                                  (cider-emit-interactive-eval-output out))
                                (lambda (_buffer err)
                                  (cider-emit-interactive-eval-err-output err))
                                '()))


(defun pen-cider-eval-last-sexp ()
  "Evaluate the expression preceding point.
If invoked with OUTPUT-TO-CURRENT-BUFFER, print the result in the current
buffer."
  (interactive)
  (cider-interactive-eval nil
                          (cider-eval-print-handler)
                          (cider-last-sexp 'bounds)
                          (cider--nrepl-pr-request-map)))


(defun clojure-select-copy-dependency ()
  (interactive)
  (my/copy (fz (pen-snc "cd $NOTES; oci clojure-list-deps"))))

(defun clojure-find-deps (use-google &rest query)
  (interactive (list (or
                      (>= (prefix-numeric-value current-prefix-arg) 4)
                      (yes-or-no-p "Use google?"))
                     (read-string-hist "clojure-find-deps query: ")))

  (if (>= (prefix-numeric-value current-prefix-arg) 4)
      (setq use-google t))

  ;; (tv query)
  (my/copy (fz (pen-snc (apply 'cmd "clojure-find-deps"
                               (if use-google
                                   "-gl")
                               (-flatten (mapcar (lambda (e) (s-split " " e)) query)))))))



(require 'clj-refactor)

(defun pen-clojure-mode-hook ()
  (clj-refactor-mode 1)
  (yas-minor-mode 1)
  ;; for adding require/use/import statements
  (define-key clojure-mode-map (kbd "H-*") nil)
  ;; This choice of keybinding leaves cider-macroexpand-1 unbound
  (cljr-add-keybindings-with-prefix "H-*"))

(add-hook 'clojure-mode-hook #'pen-clojure-mode-hook)

;; This only prevents the buffer from being selected (which was SUPER annoying)
;; What about preventing it from being shown altogether?
;; It's appearing even when I switch terminals and are not working in clojure
(setq cider-auto-select-error-buffer nil)
;; This was supremely annoying until I found the option to turn it off
;; (setq cider-show-error-buffer 'only-in-repl)
(setq cider-show-error-buffer nil)

(defvar pen-do-cider-auto-jack-in t)

(defun cider-auto-jack-in ()
  (interactive)

  ;; Make sure to be more precise. jack in with cljs too if it should
  ;; j:cider-jack-in-clj
  ;; j:cider-jack-in-cljs
  ;; j:cider-jack-in-clj&cljs

  (if (and
       (derived-mode-p 'clojure-mode)
       (not (derived-mode-p 'clojerl-mode)))
      (progn
        ;; (ns "running timer")
        (run-with-idle-timer 3 nil
                             (lm
                              (try
                               (if ;; pen-do-cider-auto-jack-in
                                   (pen-rc-test "cider")
                                   (progn
                                     ;; (message "Jacking in")
                                     (with-current-buffer (current-buffer)
                                       (cond
                                        ((derived-mode-p 'clojure-mode)
                                         (auto-no
                                          ;; (call-interactively
                                          ;;  'cider-jack-in)
                                          (cider-jack-in nil)))
                                        ((derived-mode-p 'clojurescript-mode)
                                         (auto-no
                                          ;; (call-interactively
                                          ;;  'cider-jack-in)
                                          (cider-jack-in-cljs nil)))))
                                     ;; (message "Jacked in?")
                                     )))))

        (enable-helm-cider-mode)))
  ;; (try
  ;;  (if ;; pen-do-cider-auto-jack-in
  ;;      (pen-rc-test "cider")
  ;;      (progn
  ;;        (auto-no
  ;;         (call-interactively
  ;;          'cider-jack-in))
  ;;        (message "Jacked in?"))))

  t)

;; This may be breaking the clojure hook when it's disabled for some reason, so I put it last
;; It's still making it so it fails to open the clojure file on first attempt
;; I have to hook it somewhere else. After the file is fully opened

(require 'helm-cider)
(defun enable-helm-cider-mode ()
  (interactive)
  (helm-cider-mode 1))

(add-hook-last 'clojure-mode-hook 'cider-auto-jack-in)
;; (add-hook-last 'clojure-mode-hook 'enable-helm-cider-mode)
;; (remove-hook 'clojure-mode-hook 'enable-helm-cider-mode)
(add-hook-last 'clojurescript-mode-hook 'cider-auto-jack-in)
;; (remove-hook 'clojure-mode-hook 'cider-auto-jack-in)

(defun cider--check-existing-session (params)
  "Ask for confirmation if a session with similar PARAMS already exists.
If no session exists or user chose to proceed, return PARAMS.  If the user
canceled the action, signal quit."
  (let* ((proj-dir (plist-get params :project-dir))
         (host (plist-get params :host))
         ;; (port (plist-get params :port))
         (session (seq-find (lambda (ses)
                              (let ((ses-params (cider--gather-session-params ses)))
                                (and (equal proj-dir (plist-get ses-params :project-dir))
                                     ;; (or (null port)
                                     ;;     (equal port (plist-get ses-params :port)))
                                     (or (null host)
                                         (equal host (plist-get ses-params :host))))))
                            (sesman-current-sessions 'CIDER '(project)))))
    (when session
      (unless (y-or-n-p
               (concat
                "A CIDER session with the same connection parameters already exists (" (car session) ").  "
                "Are you sure you want to create a new session instead of using `cider-connect-sibling-clj(s)'?  "))
        (let ((debug-on-quit nil))
          (signal 'quit nil)))))
  params)


(defun cider-switch-to-errors ()
  (interactive)
  (if (buffer-exists "*cider-error*")
      (switch-to-buffer "*cider-error*")
    (message "*cider-error* doesn't exist")))

(defun pen-clojure-switch-to-errors ()
  (interactive)
  (if (and
       (>= (prefix-numeric-value current-prefix-arg) 4)
       (buffer-exists "*cider-error*"))
      (call-interactively 'flycheck-list-errors)
    (call-interactively 'cider-switch-to-errors)))

(defun pen-clojure-lein-run ()
  (interactive)
  (pen-sps (concat "cd " (pen-q (my/pwd)) "; " "is-git && cd \"$(vc get-top-level)\"; nvc -E 'lein run; pen-pak'")))

(require 'pen-net)

;; Remember, the nrepl port is also recorded 
;; $MYGIT/gigasquid/libpython-clj-examples/.nrepl-port

(defun cider-jack-in-params (project-type)
  "Determine the commands params for `cider-jack-in' for the PROJECT-TYPE."
  ;; The format of these command-line strings must consider different shells,
  ;; different values of IFS, and the possibility that they'll be run remotely
  ;; (e.g. with TRAMP). Using `", "` causes problems with TRAMP, for example.
  ;; Please be careful when changing them.
  ;; (tv project-type)
  (pcase project-type
    ('lein        (concat cider-lein-parameters " :port " (n-get-free-port "40500" "40800")))
    ('boot        cider-boot-parameters)
    ('clojure-cli nil)
    ('shadow-cljs cider-shadow-cljs-parameters)
    ('gradle      cider-gradle-parameters)
    (_            (user-error "Unsupported project type `%S'" project-type))))

;; This allows me to remote connect
;; I should probably make it select a random port
(setq cider-lein-parameters "repl :headless :host localhost")


;; TODO cd to where the =project.clj= file is
(defun cider-jack-in-around-advice (proc &rest args)
  (never
   (let ((res (apply proc args)))
     res))
  (let ((gdir (sor
               (locate-dominating-file default-directory ".git")
               (projectile-acquire-root)))
        (pdir (locate-dominating-file default-directory "project.clj")))
    (save-window-excursion
      (let ((b (switch-to-buffer "*cd-project-clj*")))
        (ignore-errors
          (with-current-buffer b
            (cond
             ((string-equal gdir pdir)
              (progn
                (message (concat "starting cider in " gdir))
                (insert (concat "starting cider in " gdir))
                (insert "\n")
                (cd gdir)))
             ((sor pdir)
              (progn
                (message (concat "starting cider in " pdir))
                (insert (concat "starting cider in " pdir))
                (insert "\n")
                (cd pdir))))
            (let ((res (apply proc args)))
              (bury-buffer b)
              res)))))))
(advice-add 'cider-restart :around #'cider-jack-in-around-advice)
(advice-add 'cider-jack-in :around #'cider-jack-in-around-advice)
;; (advice-remove 'cider-jack-in #'cider-jack-in-around-advice)
(advice-add 'cider-jack-in-clj :around #'cider-jack-in-around-advice)
(advice-add 'cider-jack-in-cljs :around #'cider-jack-in-around-advice)

(define-key cider-repl-mode-map (kbd "C-c h f") 'my/cider-docfun)

(defun my/cider-docfun (symbol-string)
  (interactive (list (let ((s (symbol-at-point)))
                       (if s
                           (s-replace-regexp "^[a-z]+/" "" (symbol-name s))
                         ""))))
  ;; special-form
  ;; macro
  ;; function

  (let* ((cs (cider-complete ""))
         (prompt
          (cond
           ((>= (prefix-numeric-value current-prefix-arg) (expt 4 4))
            "function: ")
           ((>= (prefix-numeric-value current-prefix-arg) (expt 4 3))
            "special form: ")
           ((>= (prefix-numeric-value current-prefix-arg) (expt 4 2))
            "macro: ")
           (t
            "func/macro/special: ")))

         ;; (type-of (get-text-property 0 'type csa))
         )
    ;; (tv (str cs))
    ;; (tv symtype)
    (if (= (prefix-numeric-value current-prefix-arg) 4)
        (call-interactively 'helpful-function)
      (let ((r (fz
                (-filter
                 (cond
                  ((>= (prefix-numeric-value current-prefix-arg) (expt 4 4))
                   (lambda (e)
                     (string-equal "function" (get-text-property 0 'type e))))
                  ((>= (prefix-numeric-value current-prefix-arg) (expt 4 3))
                   (lambda (e)
                     (string-equal "special-form" (get-text-property 0 'type e))))
                  ((>= (prefix-numeric-value current-prefix-arg) (expt 4 2))
                   (lambda (e)
                     (string-equal "macro" (get-text-property 0 'type e))))
                  (t
                   (lambda (e)
                     (or (string-equal "function" (get-text-property 0 'type e))
                         (string-equal "macro" (get-text-property 0 'type e))
                         (string-equal "special-form" (get-text-property 0 'type e))))))

                 cs)
                symbol-string
                nil
                prompt)))
        ;; (tv (type-of r))
        (if (sor r)
            (try (cider-doc-lookup r)
                 (egr (cmd "clojure" symbol-string))))))))

(setq cider-preferred-build-tool "lein")

(defun cljr--insert-into-leiningen-dependencies (artifact version)
  (try
   (progn
     (re-search-forward ":dependencies")
     (paredit-forward)
     (paredit-backward-down)
     (newline-and-indent)
     (insert "[" artifact " \"" version "\"]"))
   (progn
     (re-search-forward "^ *:")
     (backward-char)
     (newline)
     (backward-char)
     (insert ":dependencies []")
     (paredit-backward-down)
     (insert "[" artifact " \"" version "\"]"))))

(defun pen-clojure-project-file ()
  (interactive)
  (let ((pfp (cljr--project-file)))
    (if (interactive-p)
        (e pfp)
      pfp)))

(define-key cider-mode-map (kbd "C-c C-o") nil)
(define-key cider-mode-map (kbd "C-M-i") nil)

(defun pen-cider-backwards-search ()
  (interactive)
  (if (>= (prefix-numeric-value current-prefix-arg) 4)
      (call-interactively 'cider-repl-previous-matching-input)
    (call-interactively 'isearch-backward)))

;; cider-repl-previous-matching-input
(define-key cider-repl-mode-map (kbd "M-r") nil)
(define-key cider-repl-mode-map (kbd "C-r") 'pen-cider-backwards-search)

(setq clomacs-httpd-default-port 8680)

(defun pen-clomacs-connect ()
  (interactive)
  (message "connect to clomacs"))

(require 'nrepl-client)
(defun nrepl--dispatch-response (response)
  "Dispatch the RESPONSE to associated callback.
First we check the callbacks of pending requests.  If no callback was found,
we check the completed requests, since responses could be received even for
older requests with \"done\" status."
  (nrepl-dbind-response response (id)
    (nrepl-log-message response 'response)
    (let ((callback (or (gethash id nrepl-pending-requests)
                        (gethash id nrepl-completed-requests))))
      (if callback
          (ignore-errors
            (funcall callback response))
        (error "[nREPL] No response handler with id %s found" id)))))

(defset cider-repl-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-d") 'cider-doc-map)
    (define-key map (kbd "C-c ,")   'cider-test-commands-map)
    (define-key map (kbd "C-c C-t") 'cider-test-commands-map)
    (define-key map (kbd "M-.") #'cider-find-var)
    (define-key map (kbd "C-c C-.") #'cider-find-ns)
    (define-key map (kbd "C-c C-:") #'cider-find-keyword)
    (define-key map (kbd "M-,") #'cider-pop-back)
    (define-key map (kbd "C-c M-.") #'cider-find-resource)
    (define-key map (kbd "RET") #'cider-repl-return)
    (define-key map (kbd "TAB") #'cider-repl-tab)
    (define-key map (kbd "C-<return>") #'cider-repl-closing-return)
    (define-key map (kbd "C-j") #'cider-repl-newline-and-indent)
    (define-key map (kbd "C-c C-o") #'cider-repl-clear-output)
    (define-key map (kbd "C-c M-n") #'cider-repl-set-ns)
    (define-key map (kbd "C-c C-u") #'cider-repl-kill-input)
    (define-key map (kbd "C-S-a") #'cider-repl-bol-mark)
    (define-key map [S-home] #'cider-repl-bol-mark)
    (define-key map (kbd "C-<up>") #'cider-repl-backward-input)
    (define-key map (kbd "C-<down>") #'cider-repl-forward-input)
    (define-key map (kbd "M-p") #'cider-repl-previous-input)
    (define-key map (kbd "M-n") #'cider-repl-next-input)
    (define-key map (kbd "M-r") #'cider-repl-previous-matching-input)
    (define-key map (kbd "M-s") #'cider-repl-next-matching-input)
    (define-key map (kbd "C-c C-n") #'cider-repl-next-prompt)
    (define-key map (kbd "C-c C-p") #'cider-repl-previous-prompt)
    (define-key map (kbd "C-c C-b") #'cider-interrupt)
    (define-key map (kbd "C-c C-c") #'cider-interrupt)
    (define-key map (kbd "C-c C-m") #'cider-macroexpand-1)
    (define-key map (kbd "C-c M-m") #'cider-macroexpand-all)
    (define-key map (kbd "C-c C-s") #'sesman-map)
    (define-key map (kbd "C-c C-z") #'cider-switch-to-last-clojure-buffer)
    (define-key map (kbd "C-c M-o") #'cider-repl-switch-to-other)
    (define-key map (kbd "C-c M-s") #'cider-selector)
    (define-key map (kbd "C-c M-d") #'cider-describe-connection)
    (define-key map (kbd "C-c C-q") #'cider-quit)
    (define-key map (kbd "C-c M-r") #'cider-restart)
    (define-key map (kbd "C-c M-i") #'cider-inspect)
    (define-key map (kbd "C-c M-p") #'cider-repl-history)
    (define-key map (kbd "M-r") #'helm-cider-repl-history)
    (define-key map (kbd "C-c M-t v") #'cider-toggle-trace-var)
    (define-key map (kbd "C-c M-t n") #'cider-toggle-trace-ns)
    (define-key map (kbd "C-c C-x") 'cider-start-map)
    (define-key map (kbd "C-x C-e") #'cider-eval-last-sexp)
    (define-key map (kbd "C-c C-r") 'clojure-refactor-map)
    (define-key map (kbd "C-c C-v") 'cider-eval-commands-map)
    (define-key map (kbd "C-c M-j") #'cider-jack-in-clj)
    (define-key map (kbd "C-c M-J") #'cider-jack-in-cljs)
    (define-key map (kbd "C-c M-c") #'cider-connect-clj)
    (define-key map (kbd "C-c M-C") #'cider-connect-cljs)

    (define-key map (string cider-repl-shortcut-dispatch-char) #'cider-repl-handle-shortcut)
    (easy-menu-define cider-repl-mode-menu map
      "Menu for CIDER's REPL mode"
      `("REPL"
        ["Complete symbol" complete-symbol]
        "--"
        ,cider-doc-menu
        "--"
        ("Find"
         ["Find definition" cider-find-var]
         ["Find namespace" cider-find-ns]
         ["Find resource" cider-find-resource]
         ["Find keyword" cider-find-keyword]
         ["Go back" cider-pop-back])
        "--"
        ["Switch to Clojure buffer" cider-switch-to-last-clojure-buffer]
        ["Switch to other REPL" cider-repl-switch-to-other]
        "--"
        ("Macroexpand"
         ["Macroexpand-1" cider-macroexpand-1]
         ["Macroexpand-all" cider-macroexpand-all])
        "--"
        ,cider-test-menu
        "--"
        ["Run project (-main function)" cider-run]
        ["Inspect" cider-inspect]
        ["Toggle var tracing" cider-toggle-trace-var]
        ["Toggle pen-ns tracing" cider-toggle-trace-ns]
        ["Refresh loaded code" cider-ns-refresh]
        "--"
        ["Set REPL ns" cider-repl-set-ns]
        ["Toggle pretty printing" cider-repl-toggle-pretty-printing]
        ["Toggle Clojure font-lock" cider-repl-toggle-clojure-font-lock]
        ["Toggle rich content types" cider-repl-toggle-content-types]
        ["Require REPL utils" cider-repl-require-repl-utils]
        "--"
        ["Browse classpath" cider-classpath]
        ["Browse classpath entry" cider-open-classpath-entry]
        ["Browse namespace" cider-browse-ns]
        ["Browse all namespaces" cider-browse-ns-all]
        ["Browse spec" cider-browse-spec]
        ["Browse all specs" cider-browse-spec-all]
        "--"
        ["Next prompt" cider-repl-next-prompt]
        ["Previous prompt" cider-repl-previous-prompt]
        ["Clear output" cider-repl-clear-output]
        ["Clear buffer" cider-repl-clear-buffer]
        ["Trim buffer" cider-repl-trim-buffer]
        ["Clear banners" cider-repl-clear-banners]
        ["Clear help banner" cider-repl-clear-help-banner]
        ["Kill input" cider-repl-kill-input]
        "--"
        ["Interrupt evaluation" cider-interrupt]
        "--"
        ["Connection info" cider-describe-connection]
        "--"
        ["Close ancillary buffers" cider-close-ancillary-buffers]
        ["Quit" cider-quit]
        ["Restart" cider-restart]
        "--"
        ["Clojure Cheatsheet" cider-cheatsheet]
        "--"
        ["A sip of CIDER" cider-drink-a-sip]
        ["View manual online" cider-view-manual]
        ["View refcard online" cider-view-refcard]
        ["Report a bug" cider-report-bug]
        ["Version info" cider-version]))
    map))

(defun cider-switch-to-repl-buffer-any (&optional set-namespace)
  "Switch to current REPL buffer, when possible in an existing window.
The type of the REPL is inferred from the mode of current buffer.  With a
prefix arg SET-NAMESPACE sets the namespace in the REPL buffer to that of
the namespace in the Clojure source buffer"
  (interactive "P")
  (cider--switch-to-repl-buffer
   (cider-current-repl 'any 'ensure)
   set-namespace))

;; (define-key cider-repl-mode-map (kbd "M-r") 'helm-cider-repl-history)
(define-key cider-repl-mode-map (kbd "M-r") nil)

(defun pen-cider-interrupt-and-new-prompt ()
  (interactive)
  (cider-interrupt))

(define-key cider-repl-mode-map (kbd "C-c C-c") 'pen-cider-interrupt-and-new-prompt)

(defun pen-cider-select-prompt-or-result ()
  (interactive)

  (if (< cider-repl-input-start-mark (point))
      (progn
        (call-interactively 'end-of-buffer)
        (set-mark (point))
        (goto-char cider-repl-input-start-mark)
        (call-interactively 'exchange-point-and-mark))
    (progn
      (if (looking-back "^[^ ]+> .*")
          (beginning-of-line))
      (if (looking-back "^[^ ]+> ")
          (progn
            (set-mark (point))
            (end-of-line))
        (progn
          (cider-repl-previous-prompt)
          (forward-line)
          (beginning-of-line)
          (set-mark (point))
          (cider-repl-next-prompt)
          (previous-line)
          (end-of-line)))))

(define-key cider-repl-mode-map (kbd "M-h") 'pen-cider-select-prompt-or-result)

(define-key clj-refactor-map (kbd "/") nil)

(provide 'pen-clojure)