(in-package :check-links-view)
(deftestsuite check-links-view-tests () ())

;;; Utilities
(defmacro with-html (&body body)
  `(who:with-html-output-to-string (s)
     ,@body))

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
(defun check-links-route (data)
  (let ((res (prog1 
		 (with-html 
		   (:div :class "check-links_result-data"
			 (dolist (link data)
			   (str (gen-link-data link)))))
	       (restas.check-links::log-info
		"End generate xhtml for route check-links/for-links."))))
    res))
(addtest check-links-route-test 
  (ensure-same 
   (check-links-route '((:url "http://google.ru" :valid-p t)
			(:url "http://bad~link.ru" :valid-p t)))
   "<div class='check-links_result-data'><div class='check-links_link'><span class='link_url'>http://google.ru</span><span class='link_gap'>&nbsp;</span><span class='link_valid-p'>true</span></div><div class='check-links_link'><span class='link_url'>http://bad~link.ru</span><span class='link_gap'>&nbsp;</span><span class='link_valid-p'>true</span></div></div>"))

(defun check-links.js (data)
  (let ((res (format nil "~A = \"~A\";" 
		     (getf data :var-name)
		     (check-links-route (getf data :data)))))
    res))
