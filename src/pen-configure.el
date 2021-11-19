(require 'f)

(defvar penconfdir (f-join user-home-directory ".pen"))

(defun pen-read-service-key (service-name)
  (interactive (list (read-string "service: ")))
  (let* ((key-path (f-join user-home-directory ".pen" (format "%s_api_key" service-name)))
         (maybe-key (if (f-file-p key-path)
                        (chomp (str (f-read key-path))))))
    (if maybe-key
        (read-string (format "update %s key: " service-name) maybe-key)
      (read-string (format "%s key: " service-name)))))

(defun pen-add-key (service-name key)
  (interactive (let* ((service-name (read-string "service: "))
                      (key (pen-read-service-key service-name)))
                 (list service-name key)))
  (let ((key-path (f-join user-home-directory ".pen" (format "%s_api_key" service-name))))
    (if (not (f-dir-p penconfdir))
        (f-mkdir penconfdir))

    (f-touch key-path)
    (f-write-text key 'utf-8 key-path)))

(defun pen-add-key-booste (key)
  (interactive (list (pen-read-service-key "booste")))
  (pen-add-key "booste" key))

(defun pen-add-key-openai (key)
  (interactive (list (pen-read-service-key "openai")))
  (pen-add-key "openai" key))

(defun pen-add-key-cohere (key)
  (interactive (list (pen-read-service-key "cohere")))
  (pen-add-key "cohere" key))

(defun pen-add-key-ai21 (key)
  (interactive (list (pen-read-service-key "ai21")))
  (pen-add-key "ai21" key))

(defun pen-add-key-aix (key)
  (interactive (list (pen-read-service-key "aix")))
  (pen-add-key "aix" key))

(defun pen-add-key-hf (key)
  (interactive (list (pen-read-service-key "hf")))
  (pen-add-key "hf" key))

(provide 'pen-configure)