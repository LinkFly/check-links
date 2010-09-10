
(in-package :restas.check-links)

(defclass storage () ())
(defclass memory-storage (storage)
  ((links :initarg :links 
	  :initform (make-hash-table :test 'equal)
	  :accessor memory-storage-links)))

(setf *storage* (make-instance 'memory-storage))

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

(defgeneric link-obsolete-p (link)
  (:method ((link link))
    (> (- (get-universal-time) (link-time link))
       *obsolete-time*)))


(defmethod print-object ((link link) stream)
  (print-unreadable-object (link stream :type t :identity nil)
    (format stream "~S" (link-to-plist link))))

(defgeneric storage-count-links (storage))

(defgeneric storage-list-links (storage))
(defgeneric (setf storage-list-links) (links storage))

(defgeneric storage-add-link (storage link))

(defgeneric storage-remove-link (storage link base-url))

(defgeneric storage-remove-obsolete-links (storage))

(defgeneric storage-get-link (storage url base-url))

(defgeneric storage-update-link (storage link valid-p))

(defgeneric storage-save (storage))

(defgeneric storage-load (storage))

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

(defmethod storage-remove-link ((storage memory-storage) link base-url)
  (flet ((remove-link (url)
	   (remhash (list url base-url) (memory-storage-links storage))))
    (remove-link (typecase link
		   (string link)
		   (link (link-url link))))))

(defmethod storage-remove-obsolete-links ((storage storage))
  (let ((hash-table (memory-storage-links storage)))
    (dolist (url/base-url (alexandria:hash-table-keys hash-table))
      (if (link-obsolete-p (gethash url/base-url hash-table))
	  (remhash url/base-url hash-table)))))

(defmethod storage-get-link ((storage memory-storage) url base-url)
  (aif (gethash url (memory-storage-links storage))
       (if (not (link-obsolete-p it))
	   it
	   (progn 
	     (storage-remove-link storage it base-url)
	     nil))))

(defmethod storage-update-link ((storage memory-storage) (link link) valid-p)
  (awhen (storage-get-link storage (link-url link) (link-base-url link))
    (setf (link-valid-p link) valid-p)
    (setf (link-time link) (get-universal-time))))

(defmethod storage-save ((storage memory-storage))
  (with-open-file (stream (get-pathname-for-save-storage) 
			  :direction :output)    
    (print (mapcar #'link-to-plist
		 (storage-list-links storage))
	   stream)))

(defmethod storage-load ((storage memory-storage))
  (setf (storage-list-links storage)
	(mapcar #'plist-to-link
		(with-open-file (stream (get-pathname-last-for-load-storage))
		  (read stream)))))

(defun get-link (url base-url)
  (storage-get-link *storage* url base-url))

(defun add-link (url valid-p base-url)
  (aif (storage-get-link *storage* url base-url)
       (storage-update-link *storage* it valid-p)
       (storage-add-link *storage* 
			 (make-instance 'link
					:url url
					:valid-p valid-p
					:base-url base-url))))

(defun remove-link (url base-url)
  (storage-remove-link *storage* url base-url))

(defun links-save ()
  (storage-save *storage*))

(defun links-load ()
  (storage-load *storage*))

(defun links-history-clear ()
  (dolist (pathname (remove 
		     (get-pathname-last-for-load-storage)
		     (cl-fad:list-directory (get-storage-path))
		     :test #'equal))
    (delete-file pathname)))

(defun get-pathname-for-save-storage ()
  (merge-pathnames (escape-filename
		    (local-time:format-timestring nil (local-time:now)))
		   (get-storage-path)))

(defun get-pathname-last-for-load-storage ()
  (let* ((storage-path (get-storage-path))
	 (storage-files (cl-fad:list-directory storage-path)))
    (unless storage-files 
      (error "Not files for storage load in ~S" storage-path))    
    (let ((universal-times
	   (mapcar (alexandria:compose #'local-time:timestamp-to-universal
				       #'local-time:parse-timestring
				       #'unescape-filename
				       #'file-namestring)
		   (cl-fad:list-directory (get-storage-path)))))
      (nth (position (apply #'max universal-times) universal-times)
	   storage-files))))

(defun escape-filename (filename)
  filename)

(defun unescape-filename (filename)
  filename)


    