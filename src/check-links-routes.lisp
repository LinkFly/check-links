(in-package :restas.check-links)

(restas:define-route check-links.js ("check-links/js/check-links.js"
				       :method :get)
  (log-info "Start handling route check-links/json.js")
  (let ((base-url (or (hunchentoot:get-parameter "base-url") (hunchentoot:referer)))
	(var-name (hunchentoot:get-parameter "varName")))
    (if (not (valid-var-name-p var-name)) (return-from check-links.js 400))
    (list :var-name var-name
	  :data (prog1 (create-plist-from-urls (hunchentoot:get-parameter "urls") base-url)
		  (log-info "End handling route check-links/json.js")))))

(defun valid-var-name-p (var-name)
  (if (or (not var-name)
	  (digit-char-p (elt var-name 0)))
      (return-from valid-var-name-p nil))
  (iter (for char in-vector var-name)
	(if (not 
	     (or (char= char #\.)
		 (char= char #\_)
		 (alpha-char-p char)
		 (digit-char-p char)))
	    (return nil))
	(finally (return t))))

(restas:define-route check-links-route ("check-links/for-links"
					:method :post
					:requirement #'(lambda ()
							 (hunchentoot:post-parameter "urls")))  
  (log-info "Start handling route check-links/for-links")
  (let ((base-url (or (hunchentoot:post-parameter "base-url") (hunchentoot:referer))))    
    (prog1 (create-plist-from-urls (hunchentoot:post-parameter "urls") base-url)
      (log-info "End handling route check-links/for-links"))))

(defun create-plist-from-urls (urls base-url)
  (log-info "Start create plist from POST parameter URLS") 
  (prog1
      (let (res)
	(dolist (link (split-sequence:split-sequence
		       #\Newline
		       (string-trim " " urls))
		 (reverse res))	  
	  (push (list :url link
		      :valid-p (check-link link
					   :base-url base-url
					   :timeout *check-timeout*
					   :enable-link-caching-p *enable-link-caching*)) 
		res)))
    (log-info "End create plist from POST parameter URLS.")))

(restas:define-route static-files ("check-links/www/*path-list")  
  (merge-pathnames (list-to-path path-list) (get-www-path)))

(restas:define-route static-tests-files ("check-links/www-tests/*path-list")
  (merge-pathnames (list-to-path path-list) (get-www-tests-path)))

