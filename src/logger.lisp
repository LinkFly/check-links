(in-package :logging)
(deftestsuite logging-tests () 
  ()
  (:function 
   (get-test-data-path ()
		       (cl-fad:pathname-as-directory
			(merge-pathnames "test-logger" *default-pathname-defaults*))))
  (:function 
   (delete-test-directory ()
		       (cl-fad:delete-directory-and-files (get-test-data-path)))))

(defun log-type-message (type log-types-streams log-types-switches fmt-message &rest args)
  (when (enable-log-type-p type log-types-switches)
    (awhen (getf log-types-streams type)
      (format it
	      "~&(:~A (~A) :time \"~A\")~%"
	      (package-name (load-time-value *package*))
	      (apply #'format nil fmt-message args)
	      (local-time:now))
      (finish-output it)
      )))
(addtest log-type-message-test
  (ensure
   (list
    (subseq (with-output-to-string (s)
	      (log-type-message :my-type `(:my-type ,s) '(:my-type t) "log-message. arg: ~a" 'is-arg))
	    0 44)
    "(:LOGGING (log-message. arg: IS-ARG) :time \"")))

(defun open-log-types-streams (&key log-types-streams prefix-logs place (types '(:info :warn :error)))  
;  (break "place: ~S" place)
  (unless place (setf place *standard-output*))
  (when log-types-streams (close-log-types-streams log-types-streams :types types))
  (setq place
	(cl-fad:pathname-as-directory
	 (cond 
	   ((typep place 'stream) 
	    (return-from open-log-types-streams
	      (if (not log-types-streams)
		  (mapcan #'(lambda (type) (list type place)) types)		  
		  (dolist (type types log-types-streams)
		    (setf (getf log-types-streams type) place)))))
	   ((or (typep place 'string)
		(typep place 'pathname))
	    (pathname place)))))
  ;(break "place: ~S" place)	 
  (ensure-directories-exist place)
  (loop 
     with log-types-streams = (or log-types-streams)
     for type in types 
;     unless (aif (getf log-types-streams type)
;		 (open-stream-p it))
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
(addtest open-log-types-streams-test
  (ensure
   (let* ((prefix "test-prefix")
	  (types '(:info :warn :my-type))
	  (types-streams 
	   (open-log-types-streams :place (get-test-data-path)
				   :types types
				   :prefix-logs prefix)))
     (prog1 
	 (for-test-created-logs (get-test-data-path)
				:log-types types
				:prefix-logs prefix)
       (close-log-types-streams types-streams)
       (delete-test-directory)))))

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
     (ensure-directories-exist (get-test-data-path))
     (let ((types-streams
	    (mapcan #'(lambda (type)
			(list type (open-test-file type)))
		    '(:info :warn :error))))       
       (close-log-types-streams types-streams)
       (prog1 
	   (notany #'identity (mapcar #'open-stream-p 
				      (remove-if #'keywordp types-streams)))
	 (mapc (compose #'delete-file #'pathname) 
	       (remove-if #'keywordp types-streams)))))))

(defun switch-log-type (type value-p log-types-switches)
  (setf (getf log-types-switches type) value-p)
  log-types-switches)

(defun enable-log-type-p (type log-types-switches)
  (getf log-types-switches type))

(defun for-test-created-logs (path &key prefix-logs (log-types '(:info :warn :error)))
  (loop for file in (mapcar #'(lambda (type)
				 (make-pathname :name
						(concatenate 'string 
							     prefix-logs
							     (when prefix-logs "-")
							     (string-downcase (as-string type)))
						:defaults path))
			    log-types)
      always (probe-file file)))

(defun for-test-generated-functions (types &optional prefix-functions)
  (loop for function in (mapcar #'(lambda (type) 
				    	  (symcat 
					   prefix-functions
					   (when prefix-functions "-")
					   "LOG-"
					   type))
				types)
     always (fboundp function)))

(defmacro define-logging (place &key 
			  prefix-functions
			  prefix-logs
			  (log-types '(:info :warn :error))
			  disable-log-types)
  (labels ((get-prefix ()
	     (concatenate 'string  prefix-functions (when prefix-functions "-")))
	   (fn-gen-fn-name (&optional (prefix-before-log ""))
	     #'(lambda (log-type)
		 (symcat (get-prefix) 
			 prefix-before-log
			 (unless (zerop (length prefix-before-log)) "-")
			 "LOG-"
			 log-type)))
	   (gen-fn-name-enable-p (log-type)
	     (symcat (get-prefix) "LOG-" log-type "-ENABLE-P")))
;    (break "log-tp: ~s" log-types)
;    (setq log-types (replace-many :std-log-types '(:info :warn :error) log-types))					
    `(progn 
       (defparameter *log-types-streams* nil)
       (defparameter *log-types-switches* 
	 ,@(mapcan #'(lambda (type) (list type t))
		   log-types))
       (dolist (type ,disable-log-types)
	 (setf (getf *log-types-switches* type) nil))

       (defun open-log-streams (&key (place ,place) (types ',log-types))
	 (setf *log-types-streams* 
	       (open-log-types-streams 
		:place place
		:types types
		:prefix-logs ,prefix-logs)))

       (defun close-log-streams (&key (types ',log-types))
	 (close-log-types-streams *log-types-streams* :types types))
	    
       (defun log-message (type fmt-message &rest args)
	 (apply #'log-type-message type *log-types-streams* *log-types-switches* fmt-message args))


       ,@(loop for type in log-types 
	    collect `(defun ,(funcall (fn-gen-fn-name) type) (fmt-message &rest args)
		       (log-message ,type fmt-message args)))

#|
       ,@(loop for (fn-type value-p) in '(("ENABLE" t) ("DISABLE" nil))
	      (loop for type in log-types
		 collect `(defun ,(funcall (fn-gen-fn-name "ENABLE") type) ()
			 (switch-log-type ,type t *log-types-switches*))))
|#

       ,@(loop for type in log-types
	    collect `(defun ,(funcall (fn-gen-fn-name "ENABLE") type) ()
			 (switch-log-type ,type t *log-types-switches*)))

       ,@(loop for type in log-types
	    collect `(defun ,(funcall (fn-gen-fn-name "DISABLE") type) ()
			 (switch-log-type ,type nil *log-types-switches*)))
       
       ,@(loop for type in log-types
	    collect `(defun ,(gen-fn-name-enable-p type) ()
			 (enable-log-type-p ,type *log-types-switches*)))
       
       (open-log-streams))))
(addtest define-logging-test
  (ensure-same
   (macroexpand-1 '(define-logging
		    (merge-pathnames "test-logs-dir" *default-pathname-defaults*)
		    :log-types (:info :warn :error :bad-links :details)
		    :prefix-logs "check-links"))
   '(PROGN
    (DEFPARAMETER *LOG-TYPES-STREAMS* NIL)
    (DEFPARAMETER *LOG-TYPES-SWITCHES*
      :INFO
      T
      :WARN
      T
      :ERROR
      T
      :BAD-LINKS
      T
      :DETAILS
      T)
    (DOLIST (TYPE NIL) (SETF (GETF *LOG-TYPES-SWITCHES* TYPE) NIL))
    (DEFUN OPEN-LOG-STREAMS
           (&KEY
            (PLACE
             (MERGE-PATHNAMES "test-logs-dir" *DEFAULT-PATHNAME-DEFAULTS*))
            (TYPES (QUOTE (:INFO :WARN :ERROR :BAD-LINKS :DETAILS))))
      (SETF *LOG-TYPES-STREAMS*
              (OPEN-LOG-TYPES-STREAMS :PLACE PLACE :TYPES TYPES :PREFIX-LOGS
                                      "check-links")))
    (DEFUN CLOSE-LOG-STREAMS
           (&KEY (TYPES (QUOTE (:INFO :WARN :ERROR :BAD-LINKS :DETAILS))))
      (CLOSE-LOG-TYPES-STREAMS *LOG-TYPES-STREAMS* :TYPES TYPES))
    (DEFUN LOG-MESSAGE (TYPE FMT-MESSAGE &REST ARGS)
      (APPLY #'LOG-TYPE-MESSAGE TYPE *LOG-TYPES-STREAMS* *LOG-TYPES-SWITCHES* FMT-MESSAGE ARGS))
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
    (DEFUN ENABLE-LOG-INFO () (SWITCH-LOG-TYPE :INFO T *LOG-TYPES-SWITCHES*))
    (DEFUN ENABLE-LOG-WARN () (SWITCH-LOG-TYPE :WARN T *LOG-TYPES-SWITCHES*))
    (DEFUN ENABLE-LOG-ERROR () (SWITCH-LOG-TYPE :ERROR T *LOG-TYPES-SWITCHES*))
    (DEFUN ENABLE-LOG-BAD-LINKS ()
      (SWITCH-LOG-TYPE :BAD-LINKS T *LOG-TYPES-SWITCHES*))
    (DEFUN ENABLE-LOG-DETAILS ()
      (SWITCH-LOG-TYPE :DETAILS T *LOG-TYPES-SWITCHES*))
    (DEFUN DISABLE-LOG-INFO ()
      (SWITCH-LOG-TYPE :INFO NIL *LOG-TYPES-SWITCHES*))
    (DEFUN DISABLE-LOG-WARN ()
      (SWITCH-LOG-TYPE :WARN NIL *LOG-TYPES-SWITCHES*))
    (DEFUN DISABLE-LOG-ERROR ()
      (SWITCH-LOG-TYPE :ERROR NIL *LOG-TYPES-SWITCHES*))
    (DEFUN DISABLE-LOG-BAD-LINKS ()
      (SWITCH-LOG-TYPE :BAD-LINKS NIL *LOG-TYPES-SWITCHES*))
    (DEFUN DISABLE-LOG-DETAILS ()
      (SWITCH-LOG-TYPE :DETAILS NIL *LOG-TYPES-SWITCHES*))
    (DEFUN LOG-INFO-ENABLE-P () (ENABLE-LOG-TYPE-P :INFO *LOG-TYPES-SWITCHES*))
    (DEFUN LOG-WARN-ENABLE-P () (ENABLE-LOG-TYPE-P :WARN *LOG-TYPES-SWITCHES*))
    (DEFUN LOG-ERROR-ENABLE-P ()
      (ENABLE-LOG-TYPE-P :ERROR *LOG-TYPES-SWITCHES*))
    (DEFUN LOG-BAD-LINKS-ENABLE-P ()
      (ENABLE-LOG-TYPE-P :BAD-LINKS *LOG-TYPES-SWITCHES*))
    (DEFUN LOG-DETAILS-ENABLE-P ()
      (ENABLE-LOG-TYPE-P :DETAILS *LOG-TYPES-SWITCHES*))
    (OPEN-LOG-STREAMS))))





