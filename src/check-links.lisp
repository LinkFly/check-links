(in-package :check-links)
(deftestsuite check-links-tests () ())
(define-default-logs 
    :logs-pathname (get-logs-path) 
  :extra-log-types (:bad-links :detailed))
(create-memory-storage-interface)
    
;(sb-ext:with-timeout 1.0 (sleep 100))
;(sb-sys:with-deadline (:seconds 1) (read))
(defun check-link (link-or-uri &key
		   base-url
		   (timeout 6)
		   (enable-link-caching-p t))
  (log-info "check-link ~s ~s" link-or-uri base-url)
  (destructuring-bind (link uri) 
      (link-to-link-and-uri link-or-uri)
    (log-info "link: ~S uri: ~S" link uri)
    (if (not (or link uri))
	(return-from check-link nil))

    (if enable-link-caching-p
	(aif (get-link link base-url)
	     (return-from check-link (link-valid-p it))))

    (log-info "link ~s not found in cache." link)
    (let (valid-p 
	  (result-request 
	   (ignore-errors 
	     (tweak-http-request
	      (as-absolute-url uri (or base-url ""))
	      :timeout timeout)
	     )				;ignore-errors
	    ))
      (when (first result-request)
	(setq valid-p (first (member (second result-request) '(200)))))
      (if enable-link-caching-p
	  (progn 
	    (log-info ":url ~S :base-url ~S :valid-p ~S" link base-url valid-p)
	    (add-link link valid-p base-url)))
      valid-p)))
(addtest check-link-test
  (ensure
  ; (and 
    (every #'identity 
	   (mapcar #'check-link
		   '("http://www.mozilla.com/ru/firefox/about/"
		     "http://www.slideshare.net/vseloved/common-lisp"
		     "http://download.oracle.com/docs/cd/B28359_01/appdev.111/b31695/index.htm"
		     "http://blog.ponto-dot.com/2010/08/15/setting-up-common-lisp-on-a-web-server"
		     "http://www.slideshare.net/vseloved/common-lisp"
		     "http://sbcl10.sbcl.org/materials/ndl"
		     "http://www.sbcl.org/manual/index.html#Debugger-Policy-Control"
		     "http://posix.ru/freenotes/linux/51")))))
(defun seriouse-test-check-link ()
  (every #'identity 
	   (mapcar #'check-link
		   (with-open-file (stream (get-test-data-pathname))
		     (read stream)))))
#|
(mapcar #'(lambda (link) (when (check-link link) link))
	(with-open-file (stream (get-test-data-pathname))
	  (read stream)))


(loop repeat 2   
   collect (loop
	      for link in (get-test-data)
	      if (not (check-link link)) collect link))

(defun get-test-data ()
  (with-open-file (stream (get-test-data-pathname))
    (read stream)))
|#
;(seriouse-test-check-link)


(defun tweak-http-request (uri &key (redirect 5) (timeout 6))  
  (flet ((tries-http-request (uri &optional (referer nil))	   
	   (let ((result-request
		  (multiple-value-list 
		   (return-if-very-long 
		    timeout
		    (let ((chunga:*accept-bogus-eols* t)) 
		      (format t "~%get page: ~a" uri) 
		      (apply #'drakma:http-request uri 
			     :redirect nil
			     :want-stream t
			     (if referer `(:additional-headers ((:referer ,referer))))))))))
	     (when (first result-request)     
	       (close (first result-request))
	       result-request))))
    (iter 
      (with uri = uri)
      (with referer)      
      (terpri)
      (log-detailed "Requested uri: ~s)" uri)

      (log-detailed "~%referer: ~s" referer)

      (for was-space-p = (search "%20" (format nil "~A" uri)))
      (log-detailed "~%was-space-p: ~s" was-space-p)

      (for cur-redirect from redirect downto 0)
      (log-detailed "~%cur-redirect: ~s" cur-redirect)

      (for req-result = (tries-http-request uri referer))
      ;(log-detailed "~%req-result: ~s" (subseq (format nil "~s" req-result) 0 40))

      (for status = (second req-result))
      (log-detailed "~%status: ~s" status)

      (cond 
	((not (or req-result was-space-p)) 
	 (leave))
	((and (or (not req-result)
		  (= status 404)) 
	      was-space-p)
	 (setf uri 
	       (parse-uri 
		(cl-ppcre:regex-replace-all "%20" 
					    (princ-to-string uri)
					    "+")))
	 (next-iteration)))



      (for location = (header-value :location 
				    (third req-result)))
      (log-detailed "~%location: ~s" location)      

      (when (not (member status '(300 301 302 303 305)))
	;(log-detailed "~%Now exit. req-resut: ~s" (subseq (format nil "~s" req-result) 0 40))
	(leave req-result))

      (when (plusp cur-redirect)	    
	(log-detailed "Now redirect. New href: ")
	(setf uri (merge-uris (princ (prepare-uri-from-str location))
			      uri)	      
	      referer (fourth req-result))))))
(addtest tweak-http-request-test
  (ensure
    (every #'identity 
	   (mapcar #'tweak-http-request
		   '("https://adwords.google.com/select/snapshot"
		     "http://anime.media.lan/cgi-bin/anime%3Ffind=àëõèìèê"
		     "http://anime.media.lan/cgi-bin/anime?find=àëõèìèê"
		     "http://axiger.livejournal.com/tag/lisp"
		     "http://mail.yandex.ru/?retpath=http%3A%2F%2Fmail.yandex.ru%2Fneo%2Fmessages%3Fd%3Did29344108"
		     "https://addons.mozilla.org/en-US/firefox"
		     "http://www.google.com/reader/view/#stream/feed%2Fhttp%3A%2F%2Fwww.developers.org.ua%2Ffeed%2F"
		     "http://mail.yandex.ru/?retpath=http%3A%2F%2Fmail.yandex.ru%2Fneo%2Fmessages%3Fd%3Did19452249"
		     "http://swizard.livejournal.com/tag/dependent%20type"
		     "http://swizard.livejournal.com/tag/dependent+type"
		     "http://anime.media.lan/cgi-bin/anime?find=%E0%EB%F5%E8%EC%E8%EA"
		     "https://launchpad.net/distros/ubuntu/%20addticket"
		     "http://swizard.livejournal.com/tag/dependent%20type")))))

(defun recheck-links ()
  (dolist (link (list-links))
    (update-link link    
		 (check-link (link-url link) :base-url (link-base-url link)))))

;;; Utitilities
(defun link-to-link-and-uri (link-or-uri &aux link)
  (cond
    ((stringp link-or-uri)
     (list (setq link (url-unescape link-or-uri))
	   (prepare-uri-from-str link)))
    ((typep link-or-uri 'uri)
     (list (format nil "~A" link-or-uri)
	   link-or-uri))))
(addtest link-to-link-and-uri-test
  (ensure-same
   (link-to-link-and-uri 
    "http%3A%2F%2Fanime.media.lan%2F?cgi-bin%2Fanime%3Ffind%3D%E0%EB%F5%E8%EC%E8%EA#blablabla")
   '("http://anime.media.lan/?cgi-bin/anime%3Ffind=àëõèìèê#blablabla"
     #U"http://anime.media.lan/?cgi-bin/anime%3Ffind=àëõèìèê")
   :test #'(lambda (real-result test-result)
	     (destructuring-bind (test-link-str test-link-uri)
		 test-result
	       (and (string= (first real-result) test-link-str)
		    (puri:uri= (second real-result) test-link-uri))))))

(defun prepare-uri-from-str (link-str)
  (funcall (compose #'parse-uri #'link-without-rest #'url-escape)
	   link-str))
(addtest prepare-uri-from-str-test
  (ensure-same
   (prepare-uri-from-str 
    "http://anime.media.lan/?cgi-bin/anime?find=àëõèìèê#blablabla")
    #U"http://anime.media.lan/?cgi-bin/anime%3Ffind=àëõèìèê"
    :test #'puri:uri=))

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
     with was-question-p
     for char across link
     do (setq result 
	 (append 
	  (case char
	    (#\Space  (reverse-esc-code "%20"))
	    (#\?      (if was-question-p 
			  (reverse-esc-code "%3F")
			  (progn
			    (setf was-question-p t)
			    '(#\?)
			    )))
	    (#\"      (reverse-esc-code "%22"))
	    (otherwise (list char)))
	  result))
     finally (return (coerce (reverse result) 'string))))
(addtest url-escape-test
  (ensure-same 
   (url-escape "https://www.google.com/accounts/ServiceLogin?service=adwords&hl=en_US&ltmpl=adwords&passive=true&ifr=false&alwf=true&continue=https://adwords.google.com/um/gaiaauth?apt%3DNone%26ugl%3Dtrue&gsessionid=8rgUoF8BsbesPHbUU6AxQg")
   "https://www.google.com/accounts/ServiceLogin?service=adwords&hl=en_US&ltmpl=adwords&passive=true&ifr=false&alwf=true&continue=https://adwords.google.com/um/gaiaauth%3Fapt%3DNone%26ugl%3Dtrue&gsessionid=8rgUoF8BsbesPHbUU6AxQg"))
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
   (url-unescape "http%3A%2F%2Fanime.media%20.lan%2F?cgi-bin%2Fanime%3Ffind%3D%E0%EB%F5%E8%EC%E8%EA")
   "http://anime.media .lan/?cgi-bin/anime%3Ffind=àëõèìèê"))

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
