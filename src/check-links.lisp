(in-package :restas.check-links)
(deftestsuite check-links-tests () ())

;(sb-ext:with-timeout 1.0 (sleep 100))
;(sb-sys:with-deadline (:seconds 1) (read))
(defun check-link (link &optional base-url &aux uri)  
  (log-info "RESTAS.CHECK-LINKS: (check-link ~s ~s) " link base-url)
  (setq link (string-trim " " link))
  (setq uri (as-uri link))
  (setq link (as-url-string link))
  (if *enable-link-caching*  
      (aif (get-link link)
	   (return-from check-link (link-valid-p it))))
  (log-info "RESTAS.CHECK-LINKS: link ~s not found in cache." link)
  (let (valid-p 
	(result-request 
	 (ignore-errors 
	   (multiple-value-list 
	    (return-if-very-long *check-timeout* 
				(drakma:http-request 
				 (progn
				   (log-info
				    "(drakma:http-request ~S :want-stream t)"
				    (as-absolute-url uri (or base-url "")))
				   (as-absolute-url uri (or base-url "")))
				 :want-stream t)))
	   );ignore-errors
	  ))
 ;   (break "result-request: ~S" result-request)
    (when (first result-request)     
      (close (first result-request))
      (setq valid-p (not (member (second result-request) '(404)))))
    (if *enable-link-caching*
	  (progn 
	    (log-info "(:url ~S :valid-p ~S)" link valid-p)
	    (add-link link valid-p)))
    valid-p))



(defun recheck-links ()
  (dolist (link (storage-list-links *storage*))
    (storage-update-link *storage* 
			 link
			 (check-link (link-url link)))))

;;; Utitilities
(defun as-url-string (link)
  (typecase link
    (string link)
    (uri (format nil "~A" link))))

(defun as-uri (link)
  (typecase link
    (uri link)
    (string (parse-uri (link-without-rest (url-escape link))))))

(defun url-escape (link)
  (loop with result
     for char across link
     if (char= char #\Space) do
       (setq result (append '(#\0 #\2 #\%) result))       
     else do 
       (push char result)
     finally (return (coerce (reverse result) 'string))))

(defun link-without-rest (link)
  (let* ((pos-last-fragment (position #\/ link :from-end t))
	 (pos-sharp (position-if 
		     #'(lambda (x) 
			 (member x '(#\#) :test #'char=))
		     (subseq link (or pos-last-fragment 0)))))
    (if pos-sharp
	(subseq link 0 (+ pos-last-fragment pos-sharp))
	link)))

(defun as-absolute-url (url base)
  (aif (handler-case (merge-uris url base) 
	 (uri-parse-error () nil))
       it
       url))	       





  
    