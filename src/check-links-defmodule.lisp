(restas:define-module :restas.check-links
    (:use :cl :pathnames :check-links :drakma :anaphora 
	  :split-sequence :lift :local-time
	  :cl-fad :alexandria :puri
	  :iterate :cl-ppcre :logging)
  (:shadowing-import-from :alexandria #:copy-stream #:copy-file)
  (:export   
   #:check-link
   #:check-links-route 
   #:static-files
   #:static-tests-files
   #:static-files
   #:static-tests-files
   #:links-save
   #:links-load
   #:links-history-clear
   #:CHECK-LINKS-JS-PROXY
   #:CHECK-LINKS-JSON
   ))

;;; For xhtml generations
(defpackage :check-links-view (:use :cl :cl-who :lift))

(in-package :restas.check-links)

(defparameter *check-timeout* 6)
(defparameter *obsolete-time* 60)
(defparameter *enable-link-caching* t)

(defparameter *log-stream* nil)

(defparameter *storage* nil)

(define-logging (get-logs-path)
    :log-types (:info :warn :error)
    :prefix-logs (string-downcase (as-string *package*)))
(addtest generated-log-functions-test
  (ensure
   (loop for function in '(log-info log-warn log-error)
	always (fboundp function))))
(addtest created-log-files-test
  (ensure
   (loop for file in (mapcar #'(lambda (type)
				 (make-pathname :name (concatenate 'string 
								   (string-downcase (as-string *package*))
								   "-"
								   (string-downcase (as-string type)))
						:defaults (get-logs-path)))
			     '(:info :warn :error))
      always (probe-file file))))

;;;;;; Utilities ;;;;;;;;;;;;
(defun as-string (obj)
  (typecase obj
    (string obj)
    (package (package-name obj))
    (symbol (symbol-name obj))))
(addtest as-string-test
  (ensure (every #'identity
		 (mapcar #'as-string
			 (list "sdf" *package* 'sym)))))

