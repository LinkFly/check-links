(in-package :pathnames)

(defvar *system-name* :check-links)

(defparameter *storage-dir* "saved-storage")
(defparameter *www-dir* "www")
(defparameter *src-dir* "src")
(defparameter *logs-dir* "logs")
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

(defun get-logs-path ()
  (merge-pathnames (cl-fad:pathname-as-directory *logs-dir*) (get-system-path)))

(defun get-test-data-path ()
  (merge-pathnames (cl-fad:pathname-as-directory *test-data-dir*) (get-system-path)))

(defun get-test-data-pathname ()  
  (merge-pathnames (cl-fad:pathname-as-file *test-data-file*) (get-test-data-path)))

(defun get-www-tests-path ()
  (merge-pathnames (cl-fad:pathname-as-directory *www-tests-dir*) (get-system-path)))

(defun get-storage-path ()
  (cl-fad:pathname-as-directory
   (merge-pathnames *storage-dir* (get-system-path))))