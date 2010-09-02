
(in-package :restas.check-links)

(defun log-info (msg &rest args) 
  (when *log-stream*
      (terpri *log-stream*)
      (apply #'format
	     *log-stream* 
	     (concatenate 'string 
			  msg
			  (format nil " Time: ~A" (local-time:now)))
	     args)))
