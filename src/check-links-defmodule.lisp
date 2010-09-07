(restas:define-module :restas.check-links
    (:use :cl :drakma :anaphora 
	  :split-sequence :lift :local-time
	  :cl-fad :alexandria :puri
	  :iterate :cl-ppcre)
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

(defvar *system-name* :check-links)

(defparameter *check-timeout* 6)
(defparameter *obsolete-time* 60)
(defparameter *enable-link-caching* t)

(defparameter *log-stream* nil)

(defparameter *storage* nil)
(defparameter *storage-dir* "saved-storage")

(defparameter *www-dir* "www")
(defparameter *src-dir* "src")
(defparameter *www-tests-dir* "www-tests")
(defparameter *test-data-dir* "src/test")
(defparameter *test-data-file* "test-data.sexpr")

;;; Getting pathnames
(defun get-system-path ()
  (make-pathname :defaults
		 (asdf:component-pathname 
		  (asdf:find-system *system-name*))
		 :name nil :type nil))

(defun get-www-path ()
  (merge-pathnames (cl-fad:pathname-as-directory *www-dir*) (get-system-path)))

(defun get-src-path ()
  (merge-pathnames (cl-fad:pathname-as-directory *src-dir*) (get-system-path)))

(defun get-test-data-path ()
  (merge-pathnames (cl-fad:pathname-as-directory *test-data-dir*) (get-system-path)))

(defun get-test-data-pathname ()  
  (merge-pathnames (cl-fad:pathname-as-file *test-data-file*) (get-test-data-path)))

(defun get-www-tests-path ()
  (merge-pathnames (cl-fad:pathname-as-directory *www-tests-dir*) (get-system-path)))


(defun get-storage-path ()
  (cl-fad:pathname-as-directory
   (merge-pathnames *storage-dir* (get-system-path))))

  