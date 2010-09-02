(in-package :check-links-view)
(deftestsuite check-links-view-tests () ())

;;; Utilities
(defmacro with-html (&body body)
  `(who:with-html-output-to-string (s)
     ,@body))

(defun print-to-string (obj)
  (format nil "~S" obj))
;;;;;;;;;;;;;

#|
(defun escape-character (str character)
  (let ((new-str (make-string 
		    (+ (count #\~ str) 
		       (length str)))))    
    (loop for char across str
	 for i from 0
	 do (setf (elt new-str i) 
		  char)
	 if (char= char character)
	   do (setf (elt new-str (incf i))
		    char)
	 finally (return new-str))))
(addtest escape-character-test
  (ensure-same 
   (escape-character "Hello ~ this ~ sdf ~ asdf ~" #\~)
   "Hello ~~ this ~~ sdf ~~ asdf ~~"))
|#

;;; Utilities for xhtml generations
(defun gen-link-data (data)
  (let ((url (getf data :url))
	(valid-p (if (getf data :valid-p)
		     "true"
		     "false")))
    (with-html
      (:div :class "check-links_link" 
	    (:span :class "link_url" (str url))
	    (:span :class "link_gap" "&nbsp;")
	    (:span :class "link_valid-p" (str valid-p))))))
(addtest gen-link-data-test 
  (ensure-same 
   (gen-link-data '(:url "http://google.ru" :valid-p t))		   
   "<div class='check-links_link'><span class='link_url'>http://google.ru</span><span class='link_gap'>&nbsp;</span><span class='link_valid-p'>true</span></div>"))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;


#|(defun check-link-route (data)
  (gen-link-data data))|#

(defun check-links-route (data)
; (break "Views: ~A" data)
  (let ((res (prog1 
		(with-html 
		  (:div :class "check-links_result-data"
			(dolist (link data)
			  (str (gen-link-data link)))))
	      (restas.check-links::log-info
	       "End generate xhtml for route check-links/for-links."))))
;    (setf (hunchentoot:content-length*) 
;	  (length
;	   (flexi-streams:string-to-octets res)))
    res))

(addtest check-links-route-test 
  (ensure-same 
   (check-links-route '((:url "http://google.ru" :valid-p t)
			(:url "http://bad~link.ru" :valid-p t)))
   "<div class='check-links_result-data'><div class='check-links_link'><span class='link_url'>http://google.ru</span><span class='link_gap'>&nbsp;</span><span class='link_valid-p'>true</span></div><div class='check-links_link'><span class='link_url'>http://bad~link.ru</span><span class='link_gap'>&nbsp;</span><span class='link_valid-p'>true</span></div></div>"))

(defun check-links-js-proxy (data)
  (format nil "\"~a\";" (check-links-route data)))
#|(defun test-check-links (data)
  (print-to-string data))
|#

#|(defun static-files (data)
  (break "data: ~S" data)
  (print-to-string data))
|#

#|(defun check-links-route-2 (data)
  (print-to-string data)) |#
