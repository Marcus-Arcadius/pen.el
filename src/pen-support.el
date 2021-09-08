;; To work around an issue with
;; Debugger entered--Lisp error: (void-function make-closure)
;; in f-join.
;; It's happening for all f functions on pen-debian.
;; Try recompiling emacs
;; (defun f-join (&rest strings)
;;   (s-join "/" strings))

(defun f-basename (path)
  ;; (pen-snc (pen-cmd "basename" path))
  (s-replace-regexp ".*/" "" path))

(defun f-mant (path)
  ;; (pen-snc (pen-cmd "mant" path))
  (s-replace-regexp "\\..*" "" (f-basename path)))

(defun pen-tf (template &optional input ext)
  "Create a temporary file."
  (setq ext (or ext "txt"))
  (let ((fp (pen-snc (concat "mktemp -p /tmp " (pen-q (concat "XXXX" (slugify template) "." ext))))))
    (if (and (sor fp)
             (sor input))
        (shut-up (write-to-file input fp)))
    fp))

(defalias 're-match-p 'string-match)

(defun pen-is-glossary-file (&optional fp)
  ;; This path works also with info
  (setq fp (or fp
               (get-path nil t)
               ""))

  (or
   (re-match-p "glossary\\.txt$" fp)
   (re-match-p "words\\.txt$" fp)
   (re-match-p "glossaries/.*\\.txt$" fp)))

(defun pen-yas-expand-string (ys)
  (interactive)
  (save-window-excursion
    (save-excursion
      (let ((m major-mode)
            (b (new-buffer-from-string
                ys)))
        (str
         (with-current-buffer b
           (let ((s))
             (funcall m)
             (yas-minor-mode 1)
             (yas-expand-snippet (buffer-string) (point-min) (point-max))
             (setq s (buffer-string))
             (kill-buffer b)
             s)))))))

(defun pen-get-glossary-topic (&optional fp)
  (if (pen-is-glossary-file)
      (cond
       ((or
         (re-match-p "glossary\\.txt$" fp)
         (re-match-p "words\\.txt$" fp))
        (f-mant (f-basename (f-dirname (buffer-file-name)))))
       (t
        (f-mant (f-basename (buffer-file-name)))))))

(defun url-found-p (url)
  "Return non-nil if URL is found, i.e. HTTP 200."
  (with-current-buffer (url-retrieve-synchronously url nil t 5)
    (prog1 (eq url-http-response-status 200)
      (kill-buffer))))

(defun ecurl (url)
  (with-current-buffer (url-retrieve-synchronously url t t 5)
    (goto-char (point-min))
    (re-search-forward "^$")
    (delete-region (point) (point-min))
    (kill-line)
    (let ((result (buffer2string (current-buffer))))
      (kill-buffer)
      result)))

(defun pen-messages-buffer ()
  "Return the \"*Messages*\" buffer.
If it does not exist, create it and switch it to `messages-buffer-mode'."
  (or (get-buffer "*Messages*")
      (with-current-buffer (get-buffer-create "*Messages*")
        (messages-buffer-mode)
        (current-buffer))))

(defun pen-message-no-echo (format-string &rest args)
  (let ((inhibit-read-only t))
    (with-current-buffer (pen-messages-buffer)
      (goto-char (point-max))
      (when (not (bolp))
        (insert "\n"))
      (insert (apply 'format format-string args))
      (when (not (bolp))
        (insert "\n"))))
  ;; (let ((minibuffer-message-timeout 0))
  ;;   (message format-string args))
  )

(defun pen-log (s)
  (pen-message-no-echo "%s\\n" s)
  s)

(defun pen-alist-setcdr (alist-symbol key value)
  "Set KEY to VALUE in alist ALIST-SYMBOL."
  (set alist-symbol
       (cons (cons key value)
             (assq-delete-all key (eval alist-symbol)))))

(defun pen-write-to-file (stdin file_path)
  (ignore-errors (with-temp-buffer
                   (insert stdin)
                   (delete-file file_path)
                   (write-file file_path))))

(defun pen-cartesian-product (&rest ls)
  (let* ((len (length ls))
         (result (cond
                  ((not ls) nil)
                  ((equal 1 len) ls)
                  (t
                   (-reduce 'cartesian-product-2 ls)))))
    (if (< 2 len)
        (mapcar (lambda (l) (unsnd l (- len 2)))
                result)
      result)))

(defun pp-oneline (l)
  (chomp (replace-regexp-in-string "\n +" " " (pp l))))
(defalias 'pp-ol 'pp-oneline)

(defun eval-string (string)
  "Evaluate elisp code stored in a string."
  (eval (car (read-from-string (format "(progn %s)" string)))))

(defun pcre-replace-string (pat rep s &rest body)
  "Replace pat with rep in s and return the result.
The string replace part is still a regular emacs replacement pattern, not PCRE"
  (eval `(replace-regexp-in-string (pcre-to-elisp pat ,@body) rep s)))

(defun qne (string)
  "Like q but without the end quotes"
  (pcre-replace-string "\"(.*)\"" "\\1" (e/q string)))

(defun e/cat (path)
  "Return the contents of FILENAME."
  (with-temp-buffer
    (insert-file-contents path)
    (buffer-string)))

(defmacro comment (&rest body) nil)

(defun variable-p (s)
  (and (not (eq s nil))
       (boundp s)))

;; For docker
(if (not (variable-p 'user-home-directory))
    (defvar user-home-directory nil))
(setq user-home-directory (or user-home-directory "/root"))

(defmacro upd (&rest body)
  (let ((l (eval
            `(let ((pen-sh-update t))
               ,@body))))
    `',l))

(comment
 (pen-ci (pen-one (pf-list-of/2 10 "operating systems with a command line")))
 (upd (pen-ci (pen-one (pf-list-of/2 10 "operating systems with a command line")))))

(defun test-upd2 ()
  (interactive)
  (etv (pps (upd (pen-ci (pen-one (pf-list-of/2 10 "operating systems with a command line")))))))

(defun test-upd ()
  (interactive)
  (etv (pps (eval `(upd (pen-ci (pen-one (pf-list-of/2 10 "operating systems with a command line"))))))))

(defmacro noupd (&rest body)
  `(let ((pen-sh-update nil)) ,@body))

(defmacro tryelse (thing &optional otherwise)
  "Try to run a thing. Run something else if it fails."
  `(condition-case
       nil ,thing
     (error ,otherwise)))

(defmacro try (&rest list-of-alternatives)
  "Try to run a thing. Run something else if it fails."
  `(try-cascade '(,@list-of-alternatives)))

(defmacro pen-try (&rest list-of-alternatives)
  "Try to run a thing. Run something else if it fails."
  (if pen-debug
      (car list-of-alternatives)
    `(try-cascade '(,@list-of-alternatives))))

(defun try-cascade (list-of-alternatives)
  "Try to run a thing. Run something else if it fails."
  ;; (pen-list2str list-of-alternatives)

  (let* ((failed t)
         (result
          (catch 'bbb
            (dolist (p list-of-alternatives)
              ;; (message "%s" (pen-list2str p))
              (let ((result nil))
                (tryelse
                 (progn
                   (setq result (eval p))
                   (setq failed nil)
                   (throw 'bbb result))
                 result))))))
    (if failed
        (error "Nothing in try succeeded")
      result)))

(defmacro defset (symbol value &optional documentation)
  "Instead of doing a defvar and a setq, do this. [[http://ergoemacs.org/emacs/elisp_defvar_problem.html][ergoemacs.org/emacs/elisp_defvar_problem.html]]"

  `(progn (defvar ,symbol ,documentation)
          (setq ,symbol ,value)))

(defun string-empty-or-nil-p (s)
  (or (not s)
      (string-empty-p s)))

(defun string-not-empty-nor-nil-p (s)
  (not (string-empty-or-nil-p s)))

(defun -filter-not-empty-string (l)
  (-filter 'string-not-empty-nor-nil-p l))

(defun string-first-nonnil-nonempty-string (&rest ss)
  "Get the first non-nil string."
  (let ((result))
    (catch 'bbb
      (dolist (p ss)
        (if (string-not-empty-nor-nil-p p)
            (progn
              (setq result p)
              (throw 'bbb result)))))
    result))
(defalias 'sor 'string-first-nonnil-nonempty-string)

(defmacro generic-or (p &rest items)
  "Return the first element of ITEMS that does not fail p.
ITEMS will be evaluated in normal `or' order."
  `(generic-or-1 ,p (list ,@items)))

(defun generic-or-1 (p items)
  (let (item)
    (while items
      (setq item (pop items))
      (if (call-function p item)
          (setq item nil)
        (setq items nil)))
    item))

;; The macro implementation also has the problem of evaluating all strings first
(defmacro str-or (&rest strings)
  "Return the first element of STRINGS that is a non-blank string.
STRINGS will be evaluated in normal `or' order."
  `(generic-or-1 'string-empty-or-nil-p (list ,@strings)))
(defalias 'msor 'str-or)

(defun cwd ()
  "Gets the current working directory"
  (interactive)
  (f-expand (substring (shut-up-c (pwd)) 10)))

(defun get-dir ()
  "Gets the directory of the current buffer's file. But this could be different from emacs' working directory.
Takes into account the current file name."
  (shut-up-c
   (let ((filedir (if buffer-file-name
                      (file-name-directory buffer-file-name)
                    (file-name-directory (cwd)))))
     (if (s-blank? filedir)
         (cwd)
       filedir))))

(defmacro shut-up-c (&rest body)
  "This works for c functions where shut-up does not."
  `(progn (let* ((inhibit-message t))
            ,@body)))

(defun pen-q (&rest strings)
  (let ((print-escape-newlines t))
    (s-join " " (mapcar 'prin1-to-string strings))))

(defun pen-str2list (s)
  "Convert a newline delimited string to list."
  (split-string s "\n"))

(defun pen-list2str (&rest l)
  "join the string representation of elements of a given list into a single string with newline delimiters"
  (if (cl-equalp 1 (length l))
      (setq l (car l)))
  (mapconcat 'identity (mapcar 'str l) "\n"))

(defun scrape (re s &optional delim)
  "Return a list of matches of re within s.
delim is used to guarantee the function returns multiple matches per line
(pen-etv (scrape \"\\b\\w+\\b\" (buffer-string) \" +\"))"
  (if delim
      (setq s (pen-list2str (s-split delim s))))
  (pen-list2str
   (-flatten
    (cl-loop
     for
     line
     in
     (s-split "\n" (str s))
     collect
     (if (string-match-p re line)
         (s-replace-regexp (concat "^.*\\(" re "\\).*") "\\1" line))))))

(defun chomp (str)
  "Chomp (remove tailing newline from) STR."
  (replace-regexp-in-string "\n\\'" "" str))

(defun rx/chomp (str)
  "Chomp leading and tailing whitespace from STR."
  (replace-regexp-in-string
   (rx (or (: bos (* (any " \t\n")))
           (: (* (any " \t\n")) eos)))
   ""
   str))

(defun slurp-file (filePath)
  "Return filePath's file content."
  (with-temp-buffer
    (insert-file-contents filePath)
    (buffer-string)))

(defun pen-find-thing (thing)
  (interactive)
  (if (stringp thing)
      (setq thing (intern thing)))
  (try (find-function thing)
       (find-variable thing)
       (find-face-definition thing)
       t))
(defalias 'pen-j 'pen-find-thing)
(defalias 'pen-ft 'pen-find-thing)

(defmacro pen-lm (&rest body)
  "Interactive lambda with no arguments."
  `(lambda () (interactive) ,@body))

(defun str (thing)
  "Converts object or string to an unformatted string."

  (if thing
      (if (stringp thing)
          (substring-no-properties thing)
        (progn
          (setq thing (format "%s" thing))
          (set-text-properties 0 (length thing) nil thing)
          thing))
    ""))

(defun sh-construct-exports (varval-tuples)
  (concat
   "export "
   (sh-construct-envs varval-tuples)))

(defun sh-construct-envs (varval-tuples)
  (s-join
   " "
   (-filter
    'identity
    (cl-loop for tp in varval-tuples
             collect
             (let ((lhs (car tp))
                   (rhs (cadr tp)))
               (if tp
                   (concat
                    lhs
                    "="
                    (if rhs
                        (if (booleanp rhs)
                            "y"
                          (pen-q rhs))
                      ""))))))))

(defun pen-sn (cmd &optional stdin dir exit_code_var detach b_no_unminimise output_buffer b_unbuffer chomp b_output-return-code)
  "Runs command in shell and return the result.
This appears to strip ansi codes.
\(sh) does not.
This also exports PEN_PROMPTS_DIR, so lm-complete knows where to find the .prompt files"
  (interactive)

  (if (not cmd)
      (setq cmd "false"))

  (if (not dir)
      (setq dir (get-dir)))

  (let ((default-directory dir))
    (if b_unbuffer
        (setq cmd (concat "unbuffer -p " cmd)))

    (if (or (or
             (pen-var-value-maybe 'pen-sh-update)
             (>= (prefix-numeric-value current-global-prefix-arg) 16))
            (or
             (and (variable-p 'sh-update)
                  (eval 'sh-update))
             (>= (prefix-numeric-value current-prefix-arg) 16)))
        (setq cmd (concat "export UPDATE=y; " cmd)))

    (setq tf (make-temp-file "elisp_bash"))
    (setq tf_exit_code (make-temp-file "elisp_bash_exit_code"))

    (let ((exps
           (sh-construct-exports
            (-filter 'identity
                     (list (list "PATH" (getenv "PATH"))
                           (list "PEN_PROMPTS_DIR" (concat pen-prompts-directory "/prompts"))
                           (if (or (pen-var-value-maybe 'pen-sh-update)
                                   (pen-var-value-maybe 'sh-update))
                               (list "UPDATE" "y")))))))
      (setq final_cmd (concat exps "; ( cd " (pen-q dir) "; " cmd "; echo -n $? > " tf_exit_code " ) > " tf)))

    (if detach
        (setq final_cmd (concat "trap '' HUP; unbuffer bash -c " (pen-q final_cmd) " &")))

    (shut-up-c
     (if (not stdin)
         (progn
           (shell-command final_cmd output_buffer))
       (with-temp-buffer
         (insert stdin)
         (shell-command-on-region (point-min) (point-max) final_cmd output_buffer))))
    (setq output (slurp-file tf))
    (if chomp
        (setq output (chomp output)))
    (progn
      (defset b_exit_code (slurp-file tf_exit_code)))

    (if b_output-return-code
        (setq output (str b_exit_code)))
    output))

(cl-defun pen-cl-sn (cmd &key stdin &key dir &key detach &key b_no_unminimise &key output_buffer &key b_unbuffer &key chomp &key b_output-return-code)
  (interactive)
  (pen-sn cmd stdin dir nil detach b_no_unminimise output_buffer b_unbuffer chomp b_output-return-code))

(defun pen-snc (cmd &optional stdin)
  "sn chomp"
  (chomp (pen-sn cmd stdin)))

(defun pen-eval-string (string)
  "Evaluate elisp code stored in a string."
  (eval (car (read-from-string (format "(progn %s)" string)))))

;; (wrlp "hi\nshane" (tv))
;; (pen-etv (wrlp "hi\nshane" (chomp)))
;; (type (wrlp "hi\n\nshane" (pen-etv)))
;; (type (wrlp "hi\n\nshane" (pen-etv) t))
;; (wrlp "hi\n\nshane" (identity))
(defmacro mwrlp (s form &optional nojoin)
  ;; The (eval s) undoes the macroishness of the s arg
  (let* ((sval (eval s))
         (ret
          (cl-loop for l in (s-split "\n" sval) collect
                (if (sor l)
                    ;; This is needed to access form.
                    ;; Unfortunately this occludes dynamic scope.
                    (eval
                     `(-> ,l
                        ,form))
                  l))))
    (if nojoin
        `',ret
      (s-join "\n" ret))))
(defalias 'wrlp 'mwrlp)

(defun fwrlp (s form &optional nojoin)
  "Function version of wrlp"
  (let* ((ret
          (cl-loop for l in (s-split "\n" s) collect
                (if (sor l)
                    (eval
                     `(-> ,l
                        ,form))
                  l))))
    (if nojoin
        ret
      (s-join "\n" ret))))

(defun pen-sne (cmd &optional stdin &rest args)
  "Returns the exit code."
  (defset b_exit_code nil)

  (progn
    (apply 'pen-sn (append (list cmd stdin) args))
    (string-to-number b_exit_code)))

;; (pen-snq "grep hi" "hi")
;; (pen-snq "grep hi" "yo")
(defun pen-snq (cmd &optional stdin &rest args)
  (let ((code (apply 'pen-sne (append (list cmd stdin) args))))
    (equal code 0)))

(defun slugify (input &optional joinlines length)
  "Slugify input"
  (interactive)
  (let ((slug
         (if joinlines
             (pen-sn "tr '\n' - | slugify" input)
           (pen-sn "slugify" input))))
    (if length
        (substring slug 0 (- length 1))
      slug)))

(defun fz-completion-second-of-tuple-annotation-function (s)
  (let ((item (assoc s minibuffer-completion-table)))
    (when item
      ;; (concat " # " (second item))
      (cond
       ((listp item) (concat " # " (second item)))
       ((stringp item) "")
       (t "")))))

(cl-defun cl-fz (list &key prompt &key full-frame &key initial-input &key must-match &key select-only-match &key hist-var &key add-props &key no-hist)
  (setq select-only-match
        (or select-only-match
            (pen-var-value-maybe 'pen-select-only-match)))

  (if no-hist
      (setq hist-var nil)
    (if (and (not hist-var)
             (sor prompt))
        (setq hist-var (intern (concat "histvar-fz-" (slugify prompt))))))

  (setq prompt (sor prompt ":"))

  (if (not (string-match " $" prompt))
      (setq prompt (concat prompt " ")))

  (if (eq (type-of list) 'symbol)
      (cond
       ((variable-p 'clojure-mode-funcs) (setq list (eval list)))
       ((fboundp 'clojure-mode-funcs) (setq list (funcall list)))))

  (if (stringp list)
      (setq list (split-string list "\n")))

  (if (and select-only-match (eq (length list) 1))
      (car list)
    (progn
      (setq prompt (or prompt ":"))
      (let ((helm-full-frame full-frame)
            (completion-extra-properties nil))

        (if add-props
            (setq completion-extra-properties
                  (append
                   completion-extra-properties
                   add-props)))

        (if (and (listp (car list)))
            (setq completion-extra-properties
                  (append
                   '(:annotation-function fz-completion-second-of-tuple-annotation-function)
                   completion-extra-properties)))

        (completing-read prompt list nil must-match initial-input hist-var)))))

(defun fz (list &optional input b_full-frame prompt must-match select-only-match add-props hist-var no-hist)
  (cl-fz
   list
   :initial-input input
   :full-frame b_full-frame
   :prompt prompt
   :must-match must-match
   :select-only-match select-only-match
   :add-props add-props
   :hist-var hist-var
   :no-hist no-hist))

(defun pen-selected ()
  (or
   (use-region-p)
   (evil-visual-state-p)))
(defalias 'pen-selected-p 'pen-selected)

(defun glob (pattern &optional dir)
  (split-string (pen-cl-sn (concat "pen-glob " (pen-q pattern) " 2>/dev/null") :stdin nil :dir dir :chomp t) "\n"))

(defun flatten-once (list-of-lists)
  (apply #'append list-of-lists))

(defun new-buffer-from-string (&optional contents bufname mode nodisplay)
  "Create a new untitled buffer from a string."
  (interactive)
  (if (not bufname)
      (setq bufname "*untitled*"))
  (let ((buffer (generate-new-buffer bufname)))
    (set-buffer-major-mode buffer)
    (if (not nodisplay)
        (display-buffer buffer '(display-buffer-same-window . nil)))
    (with-current-buffer buffer
      (if contents
          (if (stringp contents)
              (insert contents)
            (insert (str contents))))
      (beginning-of-buffer)
      (if mode (funcall mode)))
    buffer))
(defalias 'nbfs 'new-buffer-from-string)
(defun new-buffer-from-o (o)
  (new-buffer-from-string
   (if (stringp o)
       o
     (pp-to-string o))))
(defun pen-etv (o)
  "Returns the object. This is a way to see the contents of a variable while not interrupting the flow of code.
 Example:
 (message (pen-etv \"shane\"))"
  (new-buffer-from-o o)
  o)

(defun regex-match-string-1 (pat s)
  "Get first match from substring"
  (save-match-data
    (and (string-match pat s)
         (match-string-no-properties 0 s))))
(defalias 'regex-match-string 'regex-match-string-1)

(defun s-trailing-whitespace (s)
  (regex-match-string "[ \t\n]*\\'" s))

(defun s-remove-trailing-newline (s)
  (replace-regexp-in-string "\n\\'" "" s))

(defun s-remove-trailing-whitespace (s)
  (replace-regexp-in-string "[ \t\n]*\\'" "" s))

(defun s-remove-starting-specified-whitespace (s ws)
  (replace-regexp-in-string (concat "\\`" ws) "" s))

(defun s-preserve-trailing-whitespace (s-new s-old)
  "Return s-new but with the same amount of trailing whitespace as s-old."
  (let* ((trailing_ws_pat "[ \t\n]*\\'")
         (original_whitespace (regex-match-string trailing_ws_pat s-old))
         (new_result (concat (replace-regexp-in-string trailing_ws_pat "" s-new) original_whitespace)))
    new_result))

(defun preserve-trailing-whitespace (fun s)
  "Run a string filter command, but preserve the amount of trailing whitespace. (ptw 'awk1 \"hi\")"
  (s-preserve-trailing-whitespace (apply fun (list s)) s))
(defalias 'ptw 'preserve-trailing-whitespace)

(defun filter-selected-region-through-function (fun)
  (let* ((start (if (pen-selected) (region-beginning) (point-min)))
         (end (if (pen-selected) (region-end) (point-max)))
         (doreverse (and (pen-selected) (< (point) (mark))))
         (removed (delete-and-extract-region start end))
         (replacement (str (ptw fun (str removed))))
         (replacement-len (length (str replacement))))
    (if buffer-read-only (new-buffer-from-string replacement)
      (progn
        (insert replacement)
        (let ((end-point (point))
              (start-point (- (point) replacement-len)))
          (push-mark start-point)
          (goto-char end-point)
          (setq deactivate-mark nil)
          (activate-mark)
          (if doreverse
              (cua-exchange-point-and-mark nil)))))))
(defalias 'filter-selection 'filter-selected-region-through-function)

(defmacro ntimes (n &rest body)
  (cons 'progn (flatten-once
                (cl-loop for i from 1 to n collect body))))

(defun pen-selected-text (&optional ignore-no-selection keep-properties)
  "Just give me the selected text as a string. If it's empty, then nothing was selected.
region-active-p does not work for evil selection."
  (interactive)
  (let ((sel
         (cond
          ((or (region-active-p)
               (eq evil-state 'visual))
           (buffer-substring (region-beginning) (region-end)))
          (iedit-mode
           (iedit-current-occurrence-string))
          (ignore-no-selection nil)
          (t (read-string "pen-selected-text: ")))))
    (if keep-properties
        sel
      (str sel))))

(defun pen-selected-text-ignore-no-selection (&optional keep-properties)
  "Just give me the selected text as a string. If it's empty, then nothing was selected. region-active-p does not work for evil selection."
  (interactive)
  (pen-selected-text t t))

(defalias 'pen-selection 'pen-selected-text-ignore-no-selection)

(defalias 'pps 'pp-to-string)

(defun xc (&optional s silent)
  "emacs kill-ring, xclip copy
when s is nil, return current contents of clipboard
when s is a string, set the clipboard to s"
  (interactive)
  (if (and
       s
       (not (stringp s)))
      (setq s (pps s)))
  (if (not (s-blank? s))
      (kill-new s)
    (if (pen-selected-p)
        (progn
          (setq s (pen-selected-text))
          (call-interactively 'kill-ring-save))))
  (if s
      (if (not silent) (message "%s" (concat "Copied: " s)))
    (progn
      (shell-command-to-string "xsel --clipboard --output"))))

(defun pen-ivy-completing-read (prompt collection
                                       &optional predicate require-match initial-input
                                       history def inherit-input-method)
  "This is like ivy-completing-read but it does not escape +"
  (let ((handler
         (and (< ivy-completing-read-ignore-handlers-depth (minibuffer-depth))
              (assq this-command ivy-completing-read-handlers-alist))))
    (if handler
        (let ((completion-in-region-function #'completion--in-region)
              (ivy-completing-read-ignore-handlers-depth (1+ (minibuffer-depth))))
          (funcall (cdr handler)
                   prompt collection
                   predicate require-match
                   initial-input history
                   def inherit-input-method))
      ;; See the doc of `completing-read'.
      (when (consp history)
        (when (numberp (cdr history))
          (setq initial-input (nth (1- (cdr history))
                                   (symbol-value (car history)))))
        (setq history (car history)))
      (when (consp def)
        (setq def (car def)))
      (let ((str (ivy-read
                  prompt collection
                  :predicate predicate
                  :require-match (when (and collection require-match)
                                   require-match)
                  :initial-input (cond ((consp initial-input)
                                        (car initial-input))
                                       (t
                                        initial-input))
                  :preselect def
                  :def def
                  :history history
                  :keymap nil
                  :dynamic-collection ivy-completing-read-dynamic-collection
                  :extra-props '(:caller ivy-completing-read)
                  :caller (if (and collection (symbolp collection))
                              collection
                            this-command))))
        (if (string= str "")
            (or def "")
          str)))))

(defmacro initvar (symbol &optional value)
  "defvar while ignoring errors"
  (let ((sym (eval symbol)))
    `(progn (ignore-errors (defvar ,sym nil))
            ;; (ignore-errors (defvar ,symbol nil))
            (if ,value (setq ,symbol ,value)))))

;; To get around an annoying error message
(defvar histvar nil)

(defun completing-read-hist (prompt &optional initial-input histvar default-value)
  "read-string but with history."
  (if (not histvar)
      (setq histvar (intern (concat "completing-read-hist-" (slugify prompt)))))

  (setq prompt (sor prompt ":"))

  (if (not (string-match " $" prompt))
      (setq prompt (concat prompt " ")))

  (if (not (variable-p histvar))
            (eval `(defvar ,histvar nil)))
  (if (and (not initial-input)
           (listp histvar))
      (setq initial-input (first histvar)))
  (eval `(progn
           (let ((inhibit-quit t))
             (or (with-local-quit
                   (let ((completion-styles
                          '(basic))
                         (s (str (pen-ivy-completing-read ,prompt ,histvar nil nil initial-input ',histvar nil))))

                     (setq ,histvar (seq-uniq ,histvar 'string-equal))
                     s))
                 "")))))
(defalias 'read-string-hist 'completing-read-hist)

(defun vector2list (v)
  (append v nil))

(defun region-or-buffer-string ()
  (interactive)
  (if (or (region-active-p) (eq evil-state 'visual))
      (str (buffer-substring (region-beginning) (region-end)))
    (str (buffer-substring (point-min) (point-max)))))

(defun current-major-mode-string ()
  "Get the current major mode as a string."
  (str major-mode))

(defun pen-string-to-buffer (string)
  "temporary buffer from string"
  (with-temp-buffer
    (insert string)))

(defun pen-detect-language (&optional detect buffer-not-selection world programming)
  "Returns the language of the buffer or selection."
  (interactive)

  (let* ((text (if buffer-not-selection
                   (buffer-string)
                 (region-or-buffer-string)))
         (buf (nbfs text))
         (mode-lang (and (not detect)
                         (s-replace-regexp "-mode$" "" (current-major-mode-string))))
         (mode-lang
          (cond
           ((string-equal "fundamental" mode-lang) nil)
           ((string-equal "lisp-interaction" mode-lang) nil)
           (t mode-lang)))
         (programming-lang (and (not world)
                                (sor (language-detection-string text))))
         (world-lang (and (not programming-lang)
                          (sor (with-current-buffer buf
                                 (insert text)
                                 (guess-language-buffer)))))
         (lang (sor mode-lang programming-lang world-lang)))

    (if (string-equal "rustic" lang) (setq lang "rust"))
    (if (string-equal "clojurec" lang) (setq lang "clojure"))

    (kill-buffer buf)
    (str lang)))

(defun mode-to-lang (&optional modesym)
  (if (not modesym)
      (setq modesym major-mode))

  (s-replace-regexp "-mode$" "" (symbol-name (slugify modesym))))

(defun lang-to-mode (&optional langstr)
  (if (not langstr)
      (setq langstr (pen-detect-language)))

  (setq langstr (slugify langstr))

  (cond
   ((string-equal "elisp" langstr)
    (setq langstr "emacs-lisp")))

  (intern (concat langstr "-mode")))

(defun get-ext-for-lang (langstr)
  (get-ext-for-mode (lang-to-mode langstr)))

(defun get-ext-for-mode (&optional m)
  (interactive)
  (if (not m) (setq m major-mode))

  (cond ((eq major-mode 'json-mode) "json")
        ((eq major-mode 'python-mode) "py")
        ((eq major-mode 'fundamental-mode) "txt")
        (t (try (let ((result (chomp (s-replace-regexp "^\." "" (scrape "\\.[a-z0-9A-Z]+" (car (rassq m auto-mode-alist)))))))
                  (setq result (cond ((string-equal result "pythonrc") "py")
                                     (t result)))

                  (if (called-interactively-p)
                      (message result)
                    result))
                "txt"))))
(defalias 'get-path-ext-from-mode-alist 'get-ext-for-mode)

(defalias 'second 'cadr)

;; I would like to disable the yaml lsp server for .prompt files.
;; At least, until a schema for it is made in schemastore.
;; http://www.schemastore.org/json/
(defun maybe-lsp ()
  "Maybe run lsp."
  (interactive)
  (cond
   ((derived-mode-p 'prompt-description-mode)
    (message "Disabled lsp for prompts"))
   ((derived-mode-p 'completer-description-mode)
    (message "Disabled lsp for completers"))
   (t
    (call-interactively 'lsp))))

(defun pen-awk1 (s)
  (pen-sn "awk 1" s))

(defun pen-onelineify (s)
  (pen-snc "pen-str onelineify" s))

(defun pen-unonelineify (s)
  (pen-sn "pen-str unonelineify" s))

(defun pen-onelineify-safe (s)
  (pen-snc "pen-str onelineify-safe" s))

(defun pen-unonelineify-safe (s)
  (pen-sn "pen-str unonelineify-safe" s))

(defun replace-region (s)
  "Apply the function to the selected region. The function must accept a string and return a string."
  (let ((rstart (if (region-active-p) (region-beginning) (point-min)))
        (rend (if (region-active-p) (region-end) (point-max)))
        (was_selected (pen-selected-p))
        (deactivate-mark nil))

    (if buffer-read-only
        (progn
          (message "buffer is readonly. placing in temp buffer")
          (nbfs s))
      (progn
        (let ((doreverse (< (point) (mark))))
          (delete-region
           rstart
           rend)
          (insert s)

          (if doreverse
              (call-interactively 'cua-exchange-point-and-mark)))

        (if (not was_selected)
            (deactivate-mark))))))

(defun write-to-file (stdin file_path)
  ;; The ignore-errors is needed for babel for some reason
  (ignore-errors (with-temp-buffer
                   (insert stdin)
                   (delete-file file_path)
                   (write-file file_path))))

(defmacro pen-eval-for-host (&rest body)
  `(let ((result (progn ,@body)))
     (if result
         (write-to-file (str result) "/tmp/eval-output.txt")
       (write-to-file "" "/tmp/eval-output.txt"))
     nil))

(defun pen-var-value-maybe (sym)
  (if (variable-p sym)
      (eval sym)))

(defun -uniq-u (l &optional testfun)
  "Return a copy of LIST with all non-unique elements removed."

  (if (not testfun)
      (setq testfun 'equal))

  ;; Here, contents-hash is some kind of symbol which is set

  (setq testfun (define-hash-table-test 'contents-hash testfun 'sxhash-equal))

  (let ((table (make-hash-table :test 'contents-hash)))
    (cl-loop for string in l do
             (puthash string (1+ (gethash string table 0))
                      table))
    (cl-loop for key being the hash-keys of table
             unless (> (gethash key table) 1)
             collect key)))

(defun lm-define (term &optional prepend-lm-warning topic)
  (interactive)
  (let* ((final-topic
          (if (sor topic)
              (concat " in the context of " topic)
            ""))
         (def
          (pf-define-word-for-glossary/1 (concat term final-topic))))

    (if (sor def)
        (progn
          (if prepend-lm-warning
              (setq def (concat "NLG: " (ink-propertise def))))
          (if (interactive-p)
              (pen-etv def)
            def)))))

;; Example
(defun gpt-test-haskell ()
  (let ((lang
         (pen-detect-language (pen-selected-text))))
    (message (concat "Language:" lang))
    (istr-match-p "Haskell" (message lang))))

(defun pen-word-clickable ()
  (or (not (pen-selected-p))
      (= 1 (length (s-split " " (pen-selection))))))

(defun identity-command (&optional body)
  (interactive)
  (identity body))

;; j:add-to-glossary-file-for-buffer
(defun pen-define (term)
  (interactive (list (pen-thing-at-point-ask "word" t)))
  (message (lm-define term t (pen-topic t t :no-select-result t))))

(defun pen-define-general-knowledge (term)
  (interactive (list (pen-thing-at-point-ask "word" t)))
  (pen-add-to-glossary term nil nil "general knowledge")
  ;; (message (lm-define term t "general knowledge"))
  )

(defun pen-extract-keywords ()
  (interactive)

  (pen-etv (pps (pen-single-generation (pf-keyword-extraction/1 (pen-selected-text) :no-select-result t))))
  ;; (nbfs
  ;;  (pps
  ;;   (str2lines
  ;;    (pen-snc
  ;;     (concat
  ;;      "printf -- '%s\n' "
  ;;      ;; It doesn't always generate keywords, so it's not very reliable
  ;;      (pen-single-generation (pf-keyword-extraction/1 (pen-selected-text) :no-select-result t))
  ;;      ;; (pf-keyword-extraction/1 (pen-selected-text) :no-select-result t)
  ;;      )))))
  ;; nil 'emacs-lisp-mode
  )

(defun s-replace-regexp-thread (regex rep string)
  (s-replace-regexp regex rep string t))

(defmacro do-substitutions (str &rest tups)
  ""
  (let* ((newtups (mapcar (lambda (tup) (cons 's-replace-regexp-thread tup)) tups)))
    `(progn (->>
                ,str
              ,@newtups))))
(defalias 'seds 'do-substitutions)

(defun pen-mnm (input)
  "Minimise string."
  ;; (sh-notty "mnm" input)
  (if input
      (seds (pen-umn input)
            ((f-join pen-prompts-directory "prompts") "$PROMPTS")
            (user-emacs-directory "$EMACSD")
            (penconfdir "$PEN")
            ((f-join user-emacs-directory "pen.el") "$PENEL")
            (user-home-directory "$HOME"))))

(defun pen-umn (input)
  "Unminimise string."
  (if input
      (seds input
            ("~/" user-home-directory)
            ("$PROMPTS" (f-join pen-prompts-directory "prompts"))
            ("$EMACSD" user-emacs-directory)
            ("$PEN" penconfdir)
            ("$PENEL" (f-join user-emacs-directory "pen.el"))
            ("$HOME" user-home-directory))))

(defun pen-topic-ask (&optional prompt)
  (setq prompt (sor prompt "pen-topic-ask"))
  (read-string-hist
   (concat prompt ": ")
   (pen-batch (pen-topic t))))

(defun pen-show-last-prompt ()
  (interactive)
  (pen-etv (f-read (f-join penconfdir "last-final-prompt.txt"))))

(defun pen-set-major-mode (name)
  (setq name (str name))

  (funcall (cond ((string= name "shell-mode") 'sh-mode)
                 ((string= name "emacslisp-mode") 'common-lisp-mode)
                 (t (intern name)))))

(defun pen-guess-major-mode-set (&optional lang)
  "Guesses which major mode this file should have and set it."
  (interactive)
  (if (not lang)
      (setq lang (language-detection-string (buffer-string))))
  (pen-set-major-mode (lang-to-mode lang)))

(defmacro df (name &rest body)
  "Named interactive lambda with no arguments"
  `(defun ,name ()
     (interactive)
     ,@body))

(defun pen-sed (command stdin)
  "wrapper around sed"
  (interactive)
  (setq stdin (str stdin))

  (setq command (concat "sed '" (str command) "'"))
  (pen-sn command stdin))

;; (alist2pairs '(("hi" . "yo") ("my day" . "is good")))
(defun alist2pairs (al)
  (mapcar (lambda (e)
            (list (intern (slugify (str (car e)))) (cdr e)))
          al))

(defmacro pen-let-keyvals (keyvals &rest body)
  `(let ,(alist2pairs (eval keyvals))
     ,@body))

;; (pen-let-keyvals '(("hi" . "yo") ("my day" . "is good")) my-day)
(defun pen-test-let-keyvals ()
  (interactive)
  (pen-let-keyvals '(("hi" . "yo") ("my day" . "is good")) hi))

(defun pen-subprompts-to-alist (ht)
  (ht->alist (-reduce 'ht-merge (vector2list ht))))

(defun pen-test-kickstarter ()
  (eval
   `(pen-let-keyvals
     '(("kickstarter" . "Python 3.8.5 (default, Jan 27 2021, 15:41:15)\nType 'copyright', 'credits' or 'license' for more information\nIPython 7.21.0 -- An enhanced Interactive Python. Type '?' for help.\n\nIn [1]: <expression>\nOut\n"))
     (if "kickstarter"
         (eval-string "kickstarter")
       (read-string-hist "history: " "In [1]:")))))

(defun pen-test-kickstarter-2 ()
  (let
      ((kickstarter "Python 3.8.5 (default, Jan 27 2021, 15:41:15)
Type 'copyright', 'credits' or 'license' for more information
IPython 7.21.0 -- An enhanced Interactive Python. Type '?' for help.

In [1]: <expression>
Out
"))
    (if "kickstarter"
        (eval-string "kickstarter")
      (read-string-hist "history: " "In [1]:"))))

(comment
 (defun pen-test-kickstarter-3 ()
   `(eval
     `(pen-let-keyvals
       ',',(pen-subprompts-to-alist subprompts)
       (if ,,default
           (eval-string ,,(str default))
         (read-string-hist ,,(concat varname ": ") ,,example))))))

(defun pen-insert (s)
  (interactive)
  (cond
   ((derived-mode-p 'term-mode)
    (term-send-raw-string s))
   ((derived-mode-p 'vterm-mode)
    (vterm-insert s))
   (t
    (insert s))))

(defun pp-oneline (l)
  (chomp (replace-regexp-in-string "\n +" " " (pp l))))
(defalias 'pp-ol 'pp-oneline)

(defun pp-map-line (l)
  (string-join (mapcar 'pp-oneline l) "\n"))

(defun pen-sed (command stdin)
  "wrapper around sed"
  (interactive)
  (setq stdin (str stdin))

  (setq command (concat "sed '" (str command) "'"))
  (pen-sn command stdin))

(defmacro pen-macro-sed (expr &rest body)
  "This transforms the code with a sed expression"
  (let* ((codestring (pp-map-line body))
         (ucodestring (pen-sed expr codestring))
         (newcode (pen-eval-string (concat "'(progn " ucodestring ")"))))
    newcode))
(defalias 'pen-ms 'pen-macro-sed)

(defmacro pen-define-key (map kbd-expr func-sym)
  (macroexpand
   `(pen-ms "/H-[A-Z]\\+/{p;s/H-\\([A-Z]\\+\\)/<H-\\L\\1>/;}"
            (define-key ,map ,kbd-expr ,func-sym))))

(defalias 'λ 'lambda)

(defun pen-round-to-dec (n &optional decimal-count)
  (setq decimal-count (or decimal-count 1))
  (let ((mult (expt 10 decimal-count)))
    (number-to-string
     (/
      (fround
       (*
        mult
        n))
      mult))))

(provide 'pen-support)