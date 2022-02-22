(define-derived-mode person-description-mode yaml-mode "Person"
  "Person description mode")

(add-to-list 'auto-mode-alist '("\\.person\\'" . person-description-mode))

(defvar pen-personalities (make-hash-table :test 'equal)
  "Personalities are supported personality prompts")

(defvar pen-personalities-failed '())

;; (pen-personality-file-load "/home/shane/source/git/semiosis/personalities/personalities/libertyprime.person")
(defun pen-personality-file-load (fp)
  (let* ((yaml-ht (yamlmod-read-file fp))
         (incl-name (sor (ht-get yaml-ht "include")))
         (incl-fp (if (sor incl-name)
                      (f-join
                       pen-personalities-directory
                       "personalities"
                       (concat (slugify incl-name) ".person"))))
         (incl-yaml (if (and (sor incl-name)
                             (f-file-p incl-fp))
                        (pen-personality-file-load incl-fp))))
    (if incl-yaml
        (setq yaml-ht
              (ht-merge incl-yaml
                        ;; The last is overriding
                        yaml-ht)))
    yaml-ht))

(defun pen-test-personality ()
  (interactive)
  (pen-etv (pps (ht-get pen-personalities "freckled-girl"))))

(defun pen-test-pen-expand-template-keyvals-eval-string ()
  (interactive)

  (pen-expand-template-keyvals val personality-keyvals nil nil 'eval-string))

(defun pen-test-pen-expand-template-keyvals-eval-string ()
  (interactive)

  (pen-etv
   (let ((kv '(("task" . "Write a bio about a girl who was trafficked"))))
     (eval
      `(pen-let-keyvals
        ',kv
        (eval-string "task"))))))

(defun pen-test-expand-keyvals-personalities ()
  (interactive)
  (pen-etv
   (pen-expand-template-keyvals "Biography:\n<(pf-instruct-an-ai-to-write-something/1 task)>"
                                '(("(pf-instruct-an-ai-to-write-something/1 task)" . "She was just a young girl when she was trafficked. She didn't know what was happening to her, and she certainly didn't know how to get out. She was taken from her home country and forced into a life of prostitution. She was beaten and abused, and she didn't see any way out. But she was eventually rescued, and she is now working to help other victims of trafficking. She is a powerful advocate for change, and she is determined to make a difference in the world.")))))

;; mapcar((lambda (s) (eval `(pen-let-keyvals ',def-replacement-keyvals (eval-string (s-replace-regexp "<\\([^>]*\\)>" "\\1" s))))) ("biography>)" "biography"))

;; Yes this may prompt to define all the personalities initially.
;; But I can always update them on a one-off basis.
;; This is the way it indeed should work.
(defun pen-load-personalities (&optional paths)
  (interactive)

  (setq pen-personalities (make-hash-table :test 'equal))
  (setq pen-personalities-failed '())
  (noupd
   (eval
    `(let ((paths
            (or ,paths
                (-non-nil
                 (mapcar 'sor (glob (concat pen-personalities-directory "/personalities" "/*.person")))))))
       (cl-loop for path in paths do
                (message (concat "pen-mode: Loading .personality file " path))

                ;; pen-try
                (let* ((yaml-ht (pen-personality-file-load path))
                       (full-name (ht-get yaml-ht "full-name"))
                       (description (ht-get yaml-ht "description"))

                       ;; load person-defs
                       (defs-htlist (pen--htlist-to-alist (ht-get yaml-ht "defs")))
                       (def-values)

                       ;; an alist
                       ;; I can't call this defs, or it will break prompts
                       (person-defs
                        ;; It's a key-value
                        ;; generate vals from the values
                        ;; and replace person-defs
                        (let* ((vars-al defs-htlist)
                               (keys (cl-loop
                                      for atp in vars-al
                                      collect
                                      (car atp)))
                               (values (cl-loop
                                        for atp in vars-al
                                        collect
                                        (cdr atp))))

                          (setq def-values values)
                          keys))

                       (def-slugs (mapcar 'slugify person-defs))
                       ;; (def-syms (mapcar 'intern def-slugs))

                       ;; use the slugs of the keys, so i can use them in further replacements
                       (def-keyvals (-zip def-slugs def-values))

                       ;; def-keyvals:
                       ;; (("task" . "Write a bio about a girl who was trafficked")
                       ;;  ("biography" . "Biography:\n<(pf-instruct-an-ai-to-write-something/1 task)>")
                       ;;  ("full-name" . "<(pf-christen-something-with-a-name/1 biography)>")
                       ;;  ("description" . "<biography>"))

                       (def-replacement-keyvals)

                       (def-keyvals
                         (let ((personality-keyvals))
                           (cl-loop
                            for atp in def-keyvals
                            collect
                            (let ((defkey (car atp))
                                  (val (str (cdr atp))))
                              (cons
                               defkey
                               ;; First, update the templateeval keyvals
                               ;; Second, update the actual vals
                               (let* (
                                      ;; for each .personality key, create a set of template keys by scaping the string
                                      (eval-template-keys
                                       (mapcar
                                        ;; Remove the angle brackets
                                        ;; These keys will be used in the template expansion
                                        (lambda (s)
                                          ;; This is ugly but $ didnt seem to work
                                          (s-replace-regexp "<" "" (s-replace-regexp ">" "" (chomp s))))
                                        (append
                                         (-filter-not-empty-string
                                          (mapcar
                                           (lambda (e) (scrape "<\\(.*\\)>" e))
                                           (mapcar
                                            (lambda (s) (concat s ")>"))
                                            (s-split ")>" val))))
                                         (-filter-not-empty-string
                                          (mapcar
                                           (lambda (e) (scrape "<[a-z-]+>" e))
                                           (mapcar
                                            (lambda (s) (concat s ">"))
                                            (s-split ">" val)))))))

                                      ;; (display
                                      ;;  (tv (pps (-filter-not-empty-string
                                      ;;     (mapcar
                                      ;;      (lambda (e) (scrape "<[a-z-]+>" e))
                                      ;;      (mapcar
                                      ;;       (lambda (s) (concat s ">"))
                                      ;;       (s-split ">" val)))))))

                                      ;; (display
                                      ;;  (if eval-template-keys
                                      ;;      (pen-tv (concat
                                      ;;               "\nv:\n"
                                      ;;               "eval-template-keys"
                                      ;;               "\npath:\n"
                                      ;;               path
                                      ;;               "\nkey:\n"
                                      ;;               defkey
                                      ;;               "\nvalue:\n"
                                      ;;               val
                                      ;;               "\neval-template-keys:\n" (pps eval-template-keys)))))

                                      ;; (display
                                      ;;  (pen-tv (concat path "\n" defkey ":" val " def-replacement-keyvals: " (pps def-replacement-keyvals))))

                                      ;; (display
                                      ;;  (if def-replacement-keyvals
                                      ;;      (tv (pps def-replacement-keyvals))))

                                      ;; (display
                                      ;;  (if eval-template-keys
                                      ;;      (tv (pps eval-template-keys))))

                                      ;; test this
                                      (eval-template-vals
                                       (mapcar
                                        (lambda (s)
                                          (eval
                                           `(pen-let-keyvals
                                             ',def-replacement-keyvals
                                             (eval-string (s-replace-regexp "<\\([^>]*\\)>" "\\1" s)))))
                                        eval-template-keys))

                                      ;; (display
                                      ;;  (pen-tv (pps eval-template-vals)))

                                      (eval-template-keyvals (-zip eval-template-keys eval-template-vals))

                                      ;; (display
                                      ;;  (tv (pps eval-template-keyvals)))

                                      (updated-val
                                       (pen-expand-template-keyvals val eval-template-keyvals))
                                      (update
                                       (setq def-replacement-keyvals
                                             (asoc-merge
                                              `((,defkey . ,updated-val))
                                              def-replacement-keyvals)))
                                      ;; (display
                                      ;;  (pen-tv (concat path "\n" defkey " personality-keyvals: " (pps personality-keyvals))))
                                      )
                                 ;; for each discovered eval template, i must create a key and value
                                 ;; the key is <(...)> inclusive, and the val is (eval-string "(...)")
                                 ;; update the vals here
                                 updated-val))))))
                       ;; now i must run
                       (full-name (pen-expand-template-keyvals full-name def-replacement-keyvals))
                       (description (pen-expand-template-keyvals description def-replacement-keyvals)))
                  (setq def-keyvals
                        (asoc-merge
                         `(("personality full name" ,full-name))
                         def-keyvals))
                  (loop for kv in def-keyvals do
                        (ht-set yaml-ht (concat "def-" (car kv)) (cdr kv)))
                  (ht-set yaml-ht "full-name" full-name)
                  (ht-set yaml-ht "description" description)
                  (ht-set yaml-ht "personality-path" path)
                  (message (concat "pen-mode: Loaded personality " full-name))
                  (ht-set pen-personalities full-name yaml-ht))
                ;; (add-to-list 'pen-personalities-failed path)
                ))
    (if pen-personalities-failed
        (progn
          (message "failed:")
          (message (pen-list2str pen-personalities-failed))
          (message (concat (str (length pen-personalities-failed)) " failed")))))))

(defun pen-list-personalities ()
  (ht-keys pen-personalities))

(provide 'pen-personalities)