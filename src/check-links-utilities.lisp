(in-package :check-links-utilities)

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
  (read-from-string (string-upcase
		     (apply #'concatenate 'string
			    (mapcar #'string 
				    (remove nil syms))))))
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



