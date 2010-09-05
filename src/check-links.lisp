(in-package :restas.check-links)
(deftestsuite check-links-tests () ())

;(sb-ext:with-timeout 1.0 (sleep 100))
;(sb-sys:with-deadline (:seconds 1) (read))
(defun check-link (link-or-uri &optional base-url)  
  (log-info "(check-link ~s ~s) " link-or-uri base-url)
  (destructuring-bind (link uri) 
      (link-to-link-and-uri link-or-uri)

    (if (not (or link uri))
	(return-from check-link nil))

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
	     )				;ignore-errors
	    ))
					;   (break "result-request: ~S" result-request)
      (when (first result-request)     
	(close (first result-request))
	(setq valid-p (not (member (second result-request) '(404)))))
      (if *enable-link-caching*
	  (progn 
	    (log-info "(:url ~S :valid-p ~S)" link valid-p)
	    (add-link link valid-p)))
      valid-p)))

(defun recheck-links ()
  (dolist (link (storage-list-links *storage*))
    (storage-update-link *storage* 
			 link
			 (check-link (link-url link)))))

;;; Utitilities
(defun link-to-link-and-uri (link-or-uri &aux link)
  (cond
    ((stringp link-or-uri)
     (print (list (setq link (url-unescape link-or-uri))
		  (parse-uri (print (link-without-rest 
				     (url-escape link)
					;link
				     ))))))
    ((typep link-or-uri 'uri)
     (list (format nil "~A" link-or-uri)
	   link-or-uri))))

#|
(defun as-url-string (link)
  (typecase link
    (string link)
    (uri (format nil "~A" link))))

(defun as-uri (link)
  (typecase link
    (uri link)
    (string 
     (#-debug ignore-errors  
      #+debug identity	      
      (parse-uri (link-without-rest (url-escape link)))))))
|#

(defmacro reverse-esc-code (esc-code)
  `(quote ,(reverse (coerce esc-code 'list))))
(addtest rev-esc-code-test
  (ensure-same 
   (macroexpand-1 '(reverse-esc-code "%3F"))
   '(quote (#\F #\3 #\%))))
   
(defun url-escape (link)
;  (break "url-escape. link: ~S" link)
  (loop 
     with result
     for char across link
     do (setq result 
	 (append 
	  (case char
	    (#\Space  '(#\+))
	    (#\?      '(#\?));(reverse-esc-code "%3F"))
	    (#\"      (reverse-esc-code "%22"))
	    (otherwise (list char)))
	  result))
     finally (return (coerce (reverse result) 'string))))
;(addtest url-escape-test
;  (ensure-same 
;   (url-escape "http://anime.media.lan/cgi-bin/anime?find=àëõèìèê")

;(drakma:http-request "http://anime.media.lan/cgi-bin/anime%3Ffind=àëõèìèê")
;(drakma:http-request "http://anime.media.lan/cgi-bin/anime?find=àëõèìèê")

(defun url-unescape (link)
  (let ((result (make-array (length link) 
			    :element-type 'character
			    ;:fill-pointer (length link)
			    :fill-pointer (- (length link) (* 2 (count #\% link)))
			    )))
    (loop
       with was-question-p 
       for index-in-result from 0
       for index-in-link from 0 below (length link)       
       for cur-char = (elt link index-in-link)
       if (char= #\% cur-char)
	 do (setq cur-char 
		  (code-char 
		   (parse-integer link :start (incf index-in-link) 
				  :end (1+ (incf index-in-link))
				  :radix 16)))
       if (char/= cur-char #\?)
	 do (setf (elt result index-in-result) cur-char)
       else if (not was-question-p)
	      do (setq was-question-p t)
	         (setf (elt result index-in-result) cur-char)
            else do (incf (fill-pointer result) 2)
	            (setf (subseq result 
				  index-in-result
				  (1+ (incf index-in-result 2)))
			  "%3F"))
    result))
(addtest url-unescape-test 
  (ensure-same
   (url-unescape "http%3A%2F%2Fanime.media.lan%2F?cgi-bin%2Fanime%3Ffind%3D%E0%EB%F5%E8%EC%E8%EA")
   "http://anime.media.lan/?cgi-bin/anime%3Ffind=àëõèìèê"))

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





  
    