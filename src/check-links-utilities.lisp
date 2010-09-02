(in-package :restas.check-links)

(defun print-to-string (obj)
  (format nil "~S" obj))

#|
(defun add-path (path)
  "Added ending to *www-path*"
  (merge-pathnames (list-to-path path) *www-path*))
|#

(defun list-to-path (ls)
  (format nil "~{~A~^/~}" ls))
