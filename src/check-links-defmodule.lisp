(restas:define-module :restas.check-links
    (:use :cl :utilities :pathnames :check-links :drakma :anaphora 
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
(deftestsuite restas.check-links-tests () ())

(defparameter *check-timeout* 6)
(defparameter *obsolete-time* 60)
(defparameter *enable-link-caching* t)
(defparameter *log-stream* nil)
(defparameter *storage* nil)

#|(setf *load-pathname*
      (pathname
       "/media/WORK_PARTITION/web-projects/dynserv/lisp-libs/user-libs/check-links/src/check-links-defmodule.lisp"))
|#
(define-default-logs :logs-pathname (get-logs-path))
(addtest generated-log-functions-test
  (ensure
   (for-test-generated-functions '(:info :warn :error))))
(addtest created-log-files-test
  (ensure 
   (for-test-created-logs (get-logs-path)
			  :log-types '(:info :warn :error)
			  :prefix-logs (string-downcase (as-string *package*)))))
#|
(define-logging (get-logs-path)
    :log-types (:info :warn :error)
    :prefix-logs (string-downcase (as-string *package*)))
|#
