(in-package :check-links)

(defclass storage () ())
(defclass memory-storage (storage)
  ((links :initarg :links 
	  :initform (make-hash-table :test 'equal)
	  :accessor memory-storage-links)
   (backup-path :initarg :backup-path
		:initform (cl-fad:pathname-as-directory 
			   (merge-pathnames "check-links-backup-memory-storage"))
		:accessor memory-storage-backup-path)
   (obsolete-time :initarg :obsolete-time 
		  :initform 60
		  :writer (setf memory-storage-obsolete-time)
		  :reader memory-storage-obsolete-time)))

(defmethod memory-storage-obsolete-time ((storage memory-storage))
  (let ((obsolete-time (slot-value storage 'obsolete-time)))
    (if (symbolp obsolete-time)
	(symbol-value obsolete-time)
	obsolete-time)))

(defclass link ()
  ((url :initarg :url :initform nil :accessor link-url)
   (time :initarg :time :initform (get-universal-time) :accessor link-time)
   (valid-p :initarg :valid-p :initform nil :accessor link-valid-p)
   (base-url :initarg :base-url :initform nil :accessor link-base-url)))

(defgeneric link-to-plist (link)
  (:method ((link link)) 
    (list :url (link-url link)
	  :base-url (link-base-url link)
	  :time (link-time link)
	  :valid-p (link-valid-p link))))

(defgeneric plist-to-link (link-plist)
  (:method ((link-plist list)) 
    (make-instance 'link 
		   :url (getf link-plist :url)
		   :base-url (getf link-plist :base-url)
		   :time (getf link-plist :time)
		   :valid-p (getf link-plist :valid-p))))

(defmethod print-object ((link link) stream)
  (print-unreadable-object (link stream :type t :identity nil)
    (format stream "~S" (link-to-plist link))))

(defgeneric storage-count-links (storage))

(defgeneric storage-list-links (storage))
(defgeneric (setf storage-list-links) (links storage))

(defgeneric storage-add-link (storage link))

(defgeneric storage-add-or-update-link (storage url valid-p &optional base-url))

(defgeneric storage-remove-link (storage link base-url))

(defgeneric storage-link-obsolete-p (storage link))

(defgeneric storage-remove-obsolete-links (storage))

(defgeneric storage-get-link (storage url base-url))

(defgeneric storage-update-link (storage link valid-p))

(defgeneric storage-save (storage))

(defgeneric storage-load (storage))

(defgeneric storage-links-history-clear (storage))

;;; Methods 
(defmethod storage-count-links ((storage memory-storage))
  (hash-table-count (memory-storage-links storage)))

(defmethod storage-list-links ((storage memory-storage))
  (alexandria:hash-table-values (memory-storage-links storage)))

(defmethod (setf storage-list-links) ((links list) (storage memory-storage))
  (setf (memory-storage-links storage)
	(alexandria:alist-hash-table
	 (mapcar #'(lambda (link)
		     (cons (list (link-url link)
				 (link-base-url link))
			   link))
		 links))))

(defmethod storage-add-link ((storage memory-storage) (link link))
  (setf (gethash (list (link-url link)
		       (link-base-url link))
		 (memory-storage-links storage))
	link))

(defmethod storage-add-or-update-link ((storage memory-storage) url valid-p &optional base-url)
  (aif (storage-get-link storage url base-url)
       (storage-update-link storage it valid-p)
       (storage-add-link storage
			 (make-instance 'link
					:url url
					:valid-p valid-p
					:base-url base-url))))

(defmethod storage-remove-link ((storage memory-storage) link base-url)
  (flet ((remove-link (url)
	   (remhash (list url base-url) (memory-storage-links storage))))
    (remove-link (typecase link
		   (string link)
		   (link (link-url link))))))

(defmethod storage-link-obsolete-p ((storage memory-storage) link)
    (> (- (get-universal-time) (link-time link))
       (funcall (memory-storage-obsolete-time storage))))

(defmethod storage-remove-obsolete-links ((storage storage))
  (let ((hash-table (memory-storage-links storage)))
    (dolist (url/base-url (alexandria:hash-table-keys hash-table))
      (if (storage-link-obsolete-p storage (gethash url/base-url hash-table))
	  (remhash url/base-url hash-table)))))

(defmethod storage-get-link ((storage memory-storage) url base-url)
  (aif (gethash url (memory-storage-links storage))
       (if (not (storage-link-obsolete-p storage it))
	   it
	   (progn 
	     (storage-remove-link storage it base-url)
	     nil))))

(defmethod storage-update-link ((storage memory-storage) (link link) valid-p)
  (awhen (storage-get-link storage (link-url link) (link-base-url link))
    (setf (link-valid-p link) valid-p)
    (setf (link-time link) (get-universal-time))))

(defmethod storage-save ((storage memory-storage) &aux dir)
  (setf dir (memory-storage-backup-path storage))
  (with-open-file (stream (get-pathname-for-save-storage dir) 
			  :direction :output)    
    (print (mapcar #'link-to-plist
		 (storage-list-links storage))
	   stream)))

(defmethod storage-load ((storage memory-storage))
  (setf (storage-list-links storage)
	(mapcar #'plist-to-link
		(with-open-file (stream (get-pathname-last-for-load-storage))
		  (read stream)))))

(defmethod storage-links-history-clear ((storage memory-storage) &aux dir)
  (setf dir (memory-storage-backup-path storage))
  (dolist (pathname (remove 
		     (get-pathname-last-for-load-storage dir)
		     (cl-fad:list-directory dir)
		     :test #'equal))
    (delete-file pathname)))  
;;;;;;;;;;;;;;;;;;;;;;;;; Create interface ;;;;;;;;;;;;;;;;;;;;;;;;

(defmacro create-storage-interface (&optional storage-create-form)
  `(progn
     (defparameter ,(add-package-prefix *package* '*storage*) ,storage-create-form)
     ,@(mapcar #'(lambda (sexpr)		 
		 (destructuring-bind (defun function-name args
				       (method-name storage-dyn-var &rest rest))
		     sexpr
		   (declare (ignore defun))
		   (flet ((function-name () 
			    (add-package-prefix *package* function-name))
			  (storage-dyn-var ()
			    (add-package-prefix *package* storage-dyn-var)))
		     `(defun ,(function-name) ,args
			(,method-name ,(storage-dyn-var) ,@rest)))))
	     '((defun list-links ()
		 (storage-list-links *storage*))

	       (defun get-link (url &optional base-url)
		 (storage-get-link *storage* url base-url))

	       (defun link-obsolete-p (link)
		 (storage-link-obsolete-p *storage* link))

	       (defun update-link (link value-p)
		 (storage-update-link *storage* link value-p))

	       (defun add-link (url valid-p &optional base-url)
		 (storage-add-or-update-link *storage* url valid-p base-url))

	       (defun remove-link (url &optional base-url)
		 (storage-remove-link *storage* url base-url))

	       (defun links-save ()
		 (storage-save *storage*))

	       (defun links-load ()
		 (storage-load *storage*))

	       (defun links-history-clear ()
		 (storage-links-history-clear *storage*))))))
(addtest create-storage-interface-test
  (ensure-same
   (macroexpand-1 '(create-storage-interface (make-instance 'memory-storage)))
   '(PROGN
    (DEFPARAMETER *STORAGE* (MAKE-INSTANCE 'MEMORY-STORAGE))
    (DEFUN LIST-LINKS () (STORAGE-LIST-LINKS *STORAGE*))
    (DEFUN GET-LINK (URL &OPTIONAL BASE-URL)
      (STORAGE-GET-LINK *STORAGE* URL BASE-URL))
     (defun link-obsolete-p (link)
		 (storage-link-obsolete-p *storage* link))
    (DEFUN UPDATE-LINK (LINK VALUE-P)
      (STORAGE-UPDATE-LINK *STORAGE* LINK VALUE-P))
    (DEFUN ADD-LINK (URL VALID-P &OPTIONAL BASE-URL)
      (STORAGE-ADD-OR-UPDATE-LINK *STORAGE* URL VALID-P BASE-URL))
    (DEFUN REMOVE-LINK (URL &OPTIONAL BASE-URL)
      (STORAGE-REMOVE-LINK *STORAGE* URL BASE-URL))
    (DEFUN LINKS-SAVE () (STORAGE-SAVE *STORAGE*))
    (DEFUN LINKS-LOAD () (STORAGE-LOAD *STORAGE*))
    (DEFUN LINKS-HISTORY-CLEAR () (STORAGE-LINKS-HISTORY-CLEAR *STORAGE*)))))

(defmacro create-memory-storage-interface ()
  `(create-storage-interface (make-instance 'memory-storage)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun get-pathname-for-save-storage (dir)
  (merge-pathnames (escape-filename
		    (local-time:format-timestring nil (local-time:now)))
		   dir))

(defun get-pathname-last-for-load-storage (dir)
  (let* ((storage-path (cl-fad:pathname-as-directory dir))
	 (storage-files (cl-fad:list-directory storage-path)))
    (unless storage-files 
      (error "Not files for storage load in ~S" storage-path))    
    (let ((universal-times
	   (mapcar (alexandria:compose #'local-time:timestamp-to-universal
				       #'local-time:parse-timestring
				       #'unescape-filename
				       #'file-namestring)
		   storage-files)))
      (nth (position (apply #'max universal-times) universal-times)
	   storage-files))))

(defun escape-filename (filename)
  filename)

(defun unescape-filename (filename)
  filename)


    