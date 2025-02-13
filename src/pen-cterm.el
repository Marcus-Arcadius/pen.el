(defun cterm (command)
  (interactive (list (read-string-hist "Shell command: ")))
  (pen-sps (pen-cmd "cterm" "-E" command)))

(defun pet (command)
  (interactive (list (read-string-hist "Shell command: ")))
  (pen-sps (pen-cmd "pet" "-E" command)))

(defun cterm-start ()
  (interactive)

  (pen-sps "cterm"))

(defun pet-start ()
  (interactive)

  (pen-sps "pet"))

(provide 'pen-cterm)