;; $MYGIT/semiosis/pen.el/scripts/filters

(defmacro pen-flash-region (&rest body)
  `(let ((fg "#00aa00")
         (bg "#006600")
         (fg_blue "#5555ff")
         (bg_blue "#2222bb")
         (fg_purple "#ff55ff")
         (bg_purple "#bb22bb")
         (fg_limegreen "#55ff55")
         (bg_limegreen "#22bb22")
         (fg_yellow "#ffff55")
         (bg_yellow "#bbbb22")
         (fg_orange "#ffA500")
         (bg_orange "#996200"))

     (set-face-foreground 'region fg_limegreen)
     (set-face-background 'region bg_limegreen)

     (sit-for 0.05)

     (let ((r ,@body))
       (set-face-foreground 'region fg)
       (set-face-background 'region bg)
       r)))

(defun pen-region-filter (func)
  "Apply the function to the selected region. The function must accept a string and return a string."
  (let ((rstart (if (region-active-p) (region-beginning) (point-min)))
        (rend (if (region-active-p) (region-end) (point-max))))

    (let ((res
           (pen-flash-region
            (ptw func (buffer-substring rstart rend)))))
      (replace-region res))))

(defun pen-region-pipe (cmd)
  (interactive (list (read-string "shell filter:")))
  "pipe region through shell command"
  (if (not cmd)
      (setq cmd "tm filter"))
  (pen-region-filter (lambda (input) (pen-sn (concat cmd) input))))

(defun pen-filter-shellscript (script)
  "This will pipe the selection into fzf filters,\nreplacing the original region. If no region is\nselected, then the entire buffer is passed\nread only."
  (interactive (list (fz (cat "$HOME/filters/filters.sh") nil nil "pen-filter-shellscript: ")))
  (if (region-active-p)
      (pen-region-pipe
       (chomp
        (replace-regexp-in-string
         " #.*" ""
         script)))))

(defun pen-pretty-paragraph ()
  (interactive)
  (pen-filter-shellscript "pen-pretty-paragraph"))

(provide 'pen-filters)