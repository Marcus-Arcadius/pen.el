;; Basic imaginary programming functions
;; Add these to the thesis

;; idefun
;; ieval
;; ilambda
;; ifilter
;; itransform
;; imacro

;; idefun vs imacro

;; imacro should take

;; i macro-expand?

;; Well, I could inject a macro with a value which is actually sent to the LM?

;; Make a legit imaginary programming library for emacs

;; TODO Make an elisp code evaluator based on prompting

;; TODO Make an elisp code generator based on prompting
;; This should create a function, which may not necessarily work
;; But can be imaginarily evaluated

;; if any of these arguments are not available, infer them via prompt
;; The macro can be expanded to create an instance of the function.
;; idefun does not necessarily need imacro.
(defmacro imacro/3 (name args docstr)
  "Does not evaluate. It merely generates code."
  (let* ((argstr (apply 'cmd (mapcar 'slugify (mapcar 'str args))))
         (bodystr
          (car
           (pen-single-generation
            (pf-imagine-an-emacs-function/3
             name
             argstr
             docstr
             :include-prompt t
             :no-select-result t))))
         (body (eval-string (concat "'" bodystr))))
    `(progn ,body)))

(defmacro imacro/2 (name args)
  "Does not evaluate. It merely generates code."
  (let* ((argstr (apply 'cmd (mapcar 'slugify (mapcar 'str args))))
         (bodystr
          (car
           (pen-single-generation
            (pf-imagine-an-emacs-function/2
             name
             argstr
             :include-prompt t
             :no-select-result t))))
         (body (eval-string (concat "'" bodystr))))
    `(progn ,body)))

(defmacro imacro/1 (name)
  "Does not evaluate. It merely generates code."
  (let* ((bodystr
          (car
           (pen-single-generation
            (pf-imagine-an-emacs-function/1
             name
             :include-prompt t
             :no-select-result t))))
         (body (eval-string (concat "'" bodystr))))
    `(progn ,body)))

(idefun double (a)
        "this function doubles its input")

(defun ilist (n type-of-thing)
  (interactive (list (read-string-hist "ilist n: ")
                     (read-string-hist "ilist type-of-thing: ")))
  (pen-single-generation (pf-list-of/2 (str n) (str type-of-thing) :no-select-result t)))

(defun test-ilist ()
  (interactive)
  (etv (pps (ilist 10 "tennis players"))))

(defmacro ieval (expression &optional code)
  (let* ((code-str (pps code))
         (result (car
                  (pen-single-generation
                   (pf-imagine-evaluating-emacs-lisp/2
                    code-str expression
                    :no-select-result t :select-only-match t)))))
    (ignore-errors
      (eval-string result))))

(defun test-ieval ()
  (ieval
   (double-number 5)
   (defun double-number (x)
     (x * x))))

(provide 'ilambda)