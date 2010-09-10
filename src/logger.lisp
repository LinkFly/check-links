(in-package :logging)
(deftestsuite logging-tests () ())

(defun log-type-message (type log-types-streams fmt-message &rest args)
	 (awhen (getf log-types-streams type)
	   (format it
		   "~&(:~A (~A) :time \"~A\")~%"
		   (package-name (load-time-value *package*))
		   (apply #'format nil fmt-message args)
		   (local-time:now))
	   (finish-output it)
	   ))

(defun open-log-types-streams (log-types-streams &key prefix-logs place (types '(:info :warn :error)))  
;  (break "place: ~S" place)
  (unless place (setf place *standard-output*))
  (close-log-types-streams log-types-streams :types types)
  (setq place
	(cl-fad:pathname-as-directory
	 (cond 
	   ((typep place 'stream) 
	    (setf log-types-streams
		  (mapcan #'(lambda (type) (list type place))
			  types))
	    (return-from open-log-types-streams log-types-streams))
	   ((or (typep place 'string)
		(typep place 'pathname))
	    place))))
  ;(break "place: ~S" place)	 
  (ensure-directories-exist place)
  (loop for type in types 
     unless (aif (getf log-types-streams :error)
		 (open-stream-p it))
     do (setf (getf log-types-streams type)
	      (open (merge-pathnames (concatenate 'string
						  prefix-logs
						  (when prefix-logs "-")
						  (string-downcase (symbol-name type)))
				     place)
		    :direction :output
		    :if-does-not-exist :create
		    :if-exists :append))
     finally (return log-types-streams)))


(defun close-log-types-streams (log-types-streams &key (types '(:info :warn :error)))
	 (loop for type in types 
	    do (aif (getf log-types-streams type)
		    (when (open-stream-p it)
		      (close it)))
	    finally (return t)))
(addtest close-log-types-streams-test
  (ensure
   (flet ((open-test-file (file)
	    (open (make-pathname :defaults (get-test-data-path) 
				 :name (string file))
		  :direction :output :if-does-not-exist :create :if-exists :append)))
     (let ((types-streams
	    (mapcan #'(lambda (type)
			(list type (open-test-file type)))
		    '(:info :warn :error))))
       (print types-streams)
       (close-log-types-streams types-streams)
       (prog1 
	   (notany #'identity (mapcar #'open-stream-p 
				      (remove-if #'keywordp types-streams)))
	 (mapc (compose #'delete-file #'pathname) 
	       (remove-if #'keywordp types-streams)))))))

(defmacro define-logging (place &key 
			  prefix-functions
			  prefix-logs
			  (log-types '(:info :warn :error)))
  (flet ((gen-fn-name (log-type)
	   (symcat prefix-functions (when prefix-functions "-") "LOG-" log-type)))
;    (break "log-tp: ~s" log-types)
;    (setq log-types (replace-many :std-log-types '(:info :warn :error) log-types))					
    `(progn 
       (defparameter *log-types-streams* nil)

       (defun open-log-streams (&key (place ,place) (types ',log-types))
	 (open-log-types-streams *log-types-streams* 
				 :place place
				 :types types
				 :prefix-logs ,prefix-logs))

       (defun close-log-streams (&key (types ',log-types))
	 (close-log-types-streams *log-types-streams* :types types))
	    
       (defun log-message (type fmt-message &rest args)
	 (apply #'log-type-message type *log-types-streams* fmt-message args))

       ,@(loop for type in log-types 
	    collect `(defun ,(gen-fn-name type) (fmt-message &rest args)
		       (log-message ,type fmt-message args)))

       (open-log-streams))))
(addtest define-logging-test
  (ensure-same
   (macroexpand-1 '(define-logging
		    (merge-pathnames "test-logs-dir" *default-pathname-defaults*)
		    :log-types (:info :warn :error :bad-links :details)
		    :prefix-logs "check-links"))
   '(PROGN
    (DEFPARAMETER *LOG-TYPES-STREAMS* NIL)
    (DEFUN OPEN-LOG-STREAMS
           (&KEY
            (PLACE
             (MERGE-PATHNAMES "test-logs-dir" *DEFAULT-PATHNAME-DEFAULTS*))
            (TYPES (QUOTE (:INFO :WARN :ERROR :BAD-LINKS :DETAILS))))
      (OPEN-LOG-TYPES-STREAMS *LOG-TYPES-STREAMS* :PLACE PLACE :TYPES TYPES
                              :PREFIX-LOGS "check-links"))
    (DEFUN CLOSE-LOG-STREAMS
           (&KEY (TYPES (QUOTE (:INFO :WARN :ERROR :BAD-LINKS :DETAILS))))
      (CLOSE-LOG-TYPES-STREAMS *LOG-TYPES-STREAMS* :TYPES TYPES))
    (DEFUN LOG-MESSAGE (TYPE FMT-MESSAGE &REST ARGS)
      (APPLY #'LOG-TYPE-MESSAGE TYPE *LOG-TYPES-STREAMS* FMT-MESSAGE ARGS))
    (DEFUN LOG-INFO (FMT-MESSAGE &REST ARGS)
      (LOG-MESSAGE :INFO FMT-MESSAGE ARGS))
    (DEFUN LOG-WARN (FMT-MESSAGE &REST ARGS)
      (LOG-MESSAGE :WARN FMT-MESSAGE ARGS))
    (DEFUN LOG-ERROR (FMT-MESSAGE &REST ARGS)
      (LOG-MESSAGE :ERROR FMT-MESSAGE ARGS))
    (DEFUN LOG-BAD-LINKS (FMT-MESSAGE &REST ARGS)
      (LOG-MESSAGE :BAD-LINKS FMT-MESSAGE ARGS))
    (DEFUN LOG-DETAILS (FMT-MESSAGE &REST ARGS)
      (LOG-MESSAGE :DETAILS FMT-MESSAGE ARGS))
    (OPEN-LOG-STREAMS))))


;;;; Utilities ;;;;;;;;;;;;;
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
;;;;;;;;;;;;;;;;;;;;;

#|
(defun log-info (msg &rest args) 
  (when *log-stream*
    (terpri *log-stream*)
    (apply #'format
	   *log-stream* 
	   (concatenate 'string 
			(format nil "(:~A " (package-name 
					    (load-time-value *package*)))
			(prepare-msg msg)
			(format nil " :time ~A)" (local-time:now)))
	   args)))
|#