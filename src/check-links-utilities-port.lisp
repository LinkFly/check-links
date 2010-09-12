(in-package :check-links-utilities-port)

;;;;;;;;;;;;;;;;;;;;;;; Not portability ;;;;;;;;;;;
;;; Using sb-ext:with-timeout and sb-ext:timeout
(defmacro return-if-very-long (sec-max form &optional value)
  `(handler-case (sb-ext:with-timeout (float ,sec-max) ,form)
     (sb-ext:timeout () ,value)))
(addtest return-if-very-long-test
  (ensure
   (let ((time-before (get-universal-time)))
      (and (return-if-very-long 2 (sleep 5) t)
	   (= 2 (- (get-universal-time) time-before))))))

;;;!!! Not portability - not work on windows
(defun absolute-pathname-p (pathname)
  (eq :absolute (first (pathname-directory pathname))))
(addtest absolute-pathname-p-test
  (ensure 
   (and (not (absolute-pathname-p "media/WORK_PARTITION/sdf"))
        (absolute-pathname-p "/media/WORK_PARTITION/sdf"))))

