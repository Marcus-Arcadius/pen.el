(defcustom pen-cost-efficient t
  "Avoid spending money"
  :type 'boolean
  :group 'pen
  :initialize (lambda(_sym _exp)
                (custom-initialize-default _sym nil)))

(defcustom pen-debug nil
  "When debug is on, try is disabled, and all errors throw an exception"
  :type 'boolean
  :group 'pen
  :initialize (lambda(_sym _exp)
                (custom-initialize-default _sym nil)))

(defcustom pen-sh-update nil
  "Export UPDATE=y when executing sn and such"
  :type 'boolean
  :group 'pen
  :initialize (lambda(_sym _exp)
                (custom-initialize-default _sym nil)))

(defun pen-get-hostname ()
  "Reliable way to get current hostname."
  (with-temp-buffer
    (shell-command "hostname" t)
    (goto-char (point-max))
    (delete-char -1)
    (buffer-string)))

(defcustom pen-memo-prefix (pen-get-hostname)
  "memoize file prefix"
  :type 'string
  :group 'pen
  :initialize #'custom-initialize-default)

;; Changing the memo prefix should also rememoize
;; It's like changing the database
;; (memoize-restore 'pen-prompt-snc)
;; (memoize 'pen-prompt-snc)

(defcustom pen-libre-only nil
  "Only use libre engines"
  :type 'boolean
  :group 'pen
  :initialize (lambda(_sym _exp)
                (custom-initialize-default _sym nil)))

(defcustom pen-default-lm-command "openai-complete.sh"
  "Default LM completer script"
  :type 'string
  :group 'pen
  :initialize #'custom-initialize-default)

(defcustom pen-override-lm-command nil
  "Override LM completer script"
  :type 'string
  :group 'pen
  :initialize #'custom-initialize-default)

(defcustom pen-prompt-function-prefix "pf-"
  "Prefix string to prepend to prompt function names"
  :type 'string
  :group 'pen
  :initialize #'custom-initialize-default)

(defcustom pen-penel-directory (f-join user-emacs-directory "pen.el")
  "Personal pen.el respository"
  :type 'string
  :group 'pen
  :initialize #'custom-initialize-default)

(defcustom pen-prompts-directory (f-join user-emacs-directory "prompts")
  "Personal prompt respository"
  :type 'string
  :group 'pen
  :initialize #'custom-initialize-default)

(defcustom pen-snippets-directory (f-join user-emacs-directory "snippets")
  "Personal snippets respository"
  :type 'string
  :group 'pen
  :initialize #'custom-initialize-default)

(defcustom pen-engines-directory (f-join user-emacs-directory "engines")
  "Personal engine respository"
  :type 'string
  :group 'pen
  :initialize #'custom-initialize-default)

(defcustom pen-glossaries-directory (f-join user-emacs-directory "glossaries")
  "Personal glossary respository"
  :type 'string
  :group 'pen
  :initialize #'custom-initialize-default)

(defcustom pen-prompts-library-directory (f-join user-emacs-directory "prompts-library")
  "The directory where prompts repositories are stored"
  :type 'string
  :group 'pen
  :initialize #'custom-initialize-default)

(defcustom pen-completers-directory (f-join user-emacs-directory "completers")
  "Directory where personal .completer files are located"
  :type 'string
  :group 'pen
  :initialize #'custom-initialize-default)

(defcustom pen-prompt-discovery-recursion-depth 5
  "The number of git repositories deep that pen.el will go looking"
  :type 'integer
  :group 'pen
  :initialize #'custom-initialize-default)

(defcustom pen-force-temperature nil
  "The temperature to force"
  :type 'float
  :group 'pen
  :initialize #'custom-initialize-default)

(defcustom pen-ink-disabled nil
  "Disable ink. Useful if it's breaking"
  :type 'boolean
  :group 'pen
  :initialize #'custom-initialize-default)

(defcustom pen-force-single-collation nil
  "Forcing only one collation will speed up Pen.el"
  :type 'boolean
  :group 'pen
  :initialize #'custom-initialize-default)

(defcustom pen-force-few-completions nil
  "Forcing only few completions will speed up Pen.el, but not by much usually"
  :type 'boolean
  :group 'pen
  :initialize #'custom-initialize-default)


(defun pen-customize ()
  (interactive)
  (customize-group "pen"))

(defcustom pen-user-agent "emacs/pen"
  "User Agent for self identification"
  :type 'string
  :group 'pen
  :initialize #'custom-initialize-default)


;; Extensions to custom

(defun custom-variable-action (widget &optional event)
  "Show the menu for `custom-variable' WIDGET.
Optional EVENT is the location for the menu."

  ;; if there are options then run that menu by default
  ;; custom-variable-select-option
  (if (and (not (>= (prefix-numeric-value current-prefix-arg) 4))
           (ignore-errors (widget-get (car (widget-get widget :children)) :options)))
      (custom-variable-select-option widget)
    (if (eq (widget-get widget :custom-state) 'hidden)
        (custom-toggle-hide widget)
      (unless (eq (widget-get widget :custom-state) 'modified)
        (custom-variable-state-set widget))
      (custom-redraw-magic widget)
      (let* ((completion-ignore-case t)
	           (answer (widget-choose (concat "Operation on "
					                                  (custom-unlispify-tag-name
					                                   (widget-get widget :value)))
				                            (custom-menu-filter custom-variable-menu
						                                            widget)
				                            event)))
        (if answer
	          (funcall answer widget))))))


(defun custom-variable-select-option (widget)
  "Restore the backup value for the variable being edited by WIDGET.
The value that was current before this operation
becomes the backup value, so you can use this operation repeatedly
to switch between two values."
  ;; (fz (widget-get (car (widget-get widget :children)) :options))
  (let* ((symbol (widget-value widget))
         ;; set function
	       (set (or (get symbol 'custom-set) 'set-default))
	       ;; (value (get symbol 'backup-value))
         (value (list (fz (widget-get (car (widget-get widget :children)) :options))))
	       (comment-widget (widget-get widget :comment-widget))
	       (comment (widget-value comment-widget)))
    (if value
	      (progn
	        (custom-variable-backup-value widget)
	        (custom-push-theme 'theme-value symbol 'user 'set value)
	        (condition-case nil
	            (funcall set symbol (car value))
	          (error nil)))
      (user-error "No backup value for %s" symbol))
    (put symbol 'customized-value (list (custom-quote (car value))))
    (put symbol 'variable-comment comment)
    (put symbol 'customized-variable-comment comment)
    (custom-variable-state-set widget)
    ;; This call will possibly make the comment invisible
    (custom-redraw widget)))


(defset custom-variable-menu
  `(("Set for Current Session" custom-variable-set
     (lambda (widget)
       (eq (widget-get widget :custom-state) 'modified)))
    ;; Note that in all the backquoted code in this file, we test
    ;; init-file-user rather than user-init-file.  This is in case
    ;; cus-edit is loaded by something in site-start.el, because
    ;; user-init-file is not set at that stage.
    ;; https://lists.gnu.org/r/emacs-devel/2007-10/msg00310.html
    ,@(when (or custom-file init-file-user)
	      '(("Save for Future Sessions" custom-variable-save
	         (lambda (widget)
	           (memq (widget-get widget :custom-state)
		               '(modified set changed rogue))))))
    ("Undo Edits" custom-redraw
     (lambda (widget)
       (and (default-boundp (widget-value widget))
	          (memq (widget-get widget :custom-state) '(modified changed)))))
    ("Revert This Session's Customization" custom-variable-reset-saved
     (lambda (widget)
       (memq (widget-get widget :custom-state)
	           '(modified set changed rogue))))
    ,@(when (or custom-file init-file-user)
	      '(("Erase Customization" custom-variable-reset-standard
	         (lambda (widget)
	           (and (get (widget-value widget) 'standard-value)
		              (memq (widget-get widget :custom-state)
			                  '(modified set changed saved rogue)))))))
    ("Set to Backup Value" custom-variable-reset-backup
     (lambda (widget)
       (get (widget-value widget) 'backup-value)))
    ;; ("Select from Options"
    ;;  ;; this runs when you select the option
    ;;  custom-variable-select-option
    ;;  (lambda (widget)
    ;;    ;; this runs when you click the button
    ;;    ;; (btv widget)
    ;;    (get (widget-value widget) 'backup-value)))
    ;; ("Select from Options" custom-variable-edit
    ;;  (lambda (widget)
    ;;    (eq (widget-get widget :custom-form) 'lisp)))
    ("---" ignore ignore)
    ("Add Comment" custom-comment-show custom-comment-invisible-p)
    ("---" ignore ignore)
    ("Show Current Value" custom-variable-edit
     (lambda (widget)
       (eq (widget-get widget :custom-form) 'lisp)))
    ("Show Saved Lisp Expression" custom-variable-edit-lisp
     (lambda (widget)
       (eq (widget-get widget :custom-form) 'edit))))
  "Alist of actions for the `custom-variable' widget.
Each entry has the form (NAME ACTION FILTER) where NAME is the name of
the menu entry, ACTION is the function to call on the widget when the
menu is selected, and FILTER is a predicate which takes a `custom-variable'
widget as an argument, and returns non-nil if ACTION is valid on that
widget.  If FILTER is nil, ACTION is always valid.")

(require 'pen-yaml)

;; pen-debug

(defun pen-load-config ()
  (interactive)
  (let* ((path (f-join penconfdir "pen.yaml"))
         (yaml-ht (yamlmod-read-file path)))
    (setq pen-debug (pen-yaml-test yaml-ht "debug"))
    (setq pen-ink-disabled (pen-yaml-test yaml-ht "disable-ink"))
    (setq pen-force-engine (ht-get yaml-ht "force-engine"))
    (setq pen-libre-only (pen-yaml-test yaml-ht "libre-only"))
    (setq pen-sh-update (pen-yaml-test yaml-ht "sh-update"))
    (setq pen-force-few-completions (pen-yaml-test yaml-ht "force-few-completions"))
    (setq pen-force-single-collation (pen-yaml-test yaml-ht "force-single-collation"))
    (setq pen-force-temperature (ht-get yaml-ht "force-temperature"))))

(provide 'pen-custom)