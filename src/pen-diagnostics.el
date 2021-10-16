(defun pen-diagnostics-show-context ()
  (interactive)
  (let* ((plist (list
                 :semantic-path (get-path-semantic)
                 :last-final-command (pen-snc "cat ~/.pen/last-final-command.txt")
                 :last-final-prompt (pen-snc "cat ~/.pen/last-final-prompt.txt")
                 :last-pen-command-exprs (pen-snc "cat ~/.pen/last-pen-command-exprs.txt")
                 :last-pen-command (pen-snc "cat ~/.pen/last-pen-prompt.txt")
                 :pen-force-engine pen-force-engine
                 :lm-complete-stderr (pen-snc (pen-cmd "cat" "/tmp/lm-complete-stderr.txt"))
                 :lm-complete-stdout (pen-snc (pen-cmd "cat" "/tmp/lm-complete-stdout.txt"))
                 :lm-complete-results (pen-snc (concat "find " (pen-q (pen-snc (pen-cmd "cat" "/tmp/lm-complete-stdout.txt"))) " | while read line; do cat \$line; echo; done"))
                 :openai-last-output (pen-snc (pen-cmd "cat" "/tmp/openai-temp.txt"))
                 :hf-last-output (pen-snc (pen-cmd "cat" "/tmp/hf-temp.txt"))
                 :aix-last-output (pen-snc (pen-cmd "cat" "/tmp/aix-temp.txt"))

                 ;; This is usually so long it causes problems
                 ;; :ai21-last-output (pen-snc (pen-cmd "cat" "/tmp/ai21-temp.txt"))
                 )))
    (find-file (pen-tf "pen context" (plist2yaml plist) "yaml"))))

(defun pen-diagnostics-test-key ()
  (interactive)
  (let* ((aix-key (pen-snc "cat ~/.pen/aix_api_key"))
         (aix-cmd
          (concat
           (sh-construct-envs `(("AIX_API_KEY" ,aix-key)
                                ("PEN_PROMPT" "Once upon a time")
                                ("PEN_MAX_TOKENS" "60")
                                ("PEN_MODEL" "GPT-J-6B")
                                ("PEN_TOP_P" "1.0")
                                ("PEN_STOP_SEQUENCE" "###")))
           " "
           "pen-aix"))
         (output (concat
                  "openai keytest: "
                  (pen-onelineify
                   (pen-snc
                    "OPENAI_API_KEY=\"$(cat ~/.pen/openai_api_key)\" pen-openai api completions.create -e davinci -t 0.8 -M 10 -n 1 --stop '###' -p \"Hello\""))
                  "\n"
                  "aix keytest: "
                  (pen-onelineify (pen-snc aix-cmd)))))
    (if (interactive-p)
        (pen-etv output)
      output)))

;; Use =cl= when dealing with plists in emacs
;; (cl-remf

(defun pen-diagnostics-test ()
  (interactive)
  (let* ((plist `(:testkey ,(pen-diagnostics-test-key))))

    ;; (plist-put plist :testkey (pen-diagnostics-test-key))

    ;; (pen-etv (plist2yaml plist))
    (nbfs (plist2yaml plist) "pen diagnostics" 'yaml-mode)))

(provide 'pen-diagnostics)