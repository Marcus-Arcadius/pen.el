(defun pen-filter-shellscript (script)
  "This will pipe the selection into fzf filters,\nreplacing the original region. If no region is\nselected, then the entire buffer is passed\nread only."
  (interactive (list (fz (cat "$HOME/filters/filters.sh") nil nil "pen-filter-shellscript: ")))
  (if (region-active-p)
      (region-pipe
       (chomp
        (replace-regexp-in-string
         " #.*" ""
         script)))))

(provide 'pen-filters)