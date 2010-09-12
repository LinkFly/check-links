(in-package :utilities)

(defun as-string (obj)
  (typecase obj
    (string obj)
    (package (package-name obj))
    (symbol (symbol-name obj))))
(addtest as-string-test
  (ensure (every #'identity
		 (mapcar #'as-string
			 (list "sdf" *package* 'sym)))))

(defun replace-many (old-elem new-list list)
  (loop 
     for type in list
     if (eq type old-elem)
     append new-list
     else 
     collect type))
(addtest replace-many-test
  (ensure-same
   (replace-many :std-log-types '(:info :warn :error) '(a b :std-log-types c d))
   '(a b :info :warn :error c d)))

(defun symcat (&rest syms)     
;  (break "syms: ~S" syms)
  (read-from-string (string-upcase
		     (apply #'concatenate 'string
			    (mapcar #'string 
				    (remove nil syms))))))
;(apply #'symcat '(NIL NIL "LOG-" :INFO))
(addtest symcat-test
  (ensure-same 
   (symcat "PREFIX" "-log-" :mykey)
   'PREFIX-LOG-MYKEY))	  

(defun add-package-prefix (package sym)
  (read-from-string 
   (concatenate 'string (string-upcase (typecase package
					 (package (package-name package))
					 (string package))) "::" (symbol-name sym))))
(addtest add-package-prefix-test
  (ensure-same 
   (add-package-prefix "logging" 'defun)
   'logging::defun))

#|
(defmacro with-gensyms ((&rest syms) &body body)
  `(let ,(loop for sym in syms
	     collect `(,sym (gensym ,(concatenate 'string (symbol-name sym) "-"))))
    ,@body))
(addtest with-gensyms-test
  (ensure-same 
   (macroexpand-1 '(with-gensyms (arg1 arg2)
		    (operation1 arg1 arg2)
		    (operation2 arg1 arg2)))
   '(LET ((ARG1 (GENSYM "ARG1-")) (ARG2 (GENSYM "ARG2-")))
     (OPERATION1 ARG1 ARG2)
     (OPERATION2 ARG1 ARG2))))
|#
;;;;;;;;;;;;;;;;;;;;;
