(in-package :restas.check-links)

#|(restas:define-route check-links-route-2 ("check-links/for-links"
					:method :options)
  (break "~A" (hunchentoot:post-parameter "urls"))
  "<b>OK</b>")
|#

(restas:define-route check-links-json ("check-links/json.js"
				       :method :get)
; (break "this is check-links-json")
;  (break "urls: ~S" (hunchentoot:get-parameter "urls"))
  (let ((base-url (or (hunchentoot:get-parameter "base-url") (hunchentoot:referer)))
	(var-name (hunchentoot:get-parameter "varName")))
    (if (not (valid-var-name-p var-name)) (return-from check-links-json 400))
    (list :var-name var-name
	  :data (prog1 (create-plist-from-urls (hunchentoot:get-parameter "urls") base-url)
		  (log-info "End handling route check-links/for-links.")))))


(defun valid-var-name-p (var-name)
;  (break "var-name: ~s" var-name)
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

(restas:define-route check-links-js-proxy ("check-links/for-links-js-proxy.js"
					   :method :get
					   :requirement #'(lambda ()
							    (hunchentoot:get-parameter "urls")))
  ;(break "urls: ~s" (hunchentoot:get-parameter "urls"))
  (log-info "Start handling route check-links/for-links-js-proxy.js.")
  (let ((base-url (or (hunchentoot:get-parameter "base-url") (hunchentoot:referer)))) 
    (prog1 (create-plist-from-urls (hunchentoot:get-parameter "urls") base-url)
      (log-info "End handling route check-links/for-links."))))

(restas:define-route check-links-route ("check-links/for-links"
					:method :post
					:requirement #'(lambda ()
							 (hunchentoot:post-parameter "urls")))  
  (log-info "Start handling route check-links/for-links.")
  (let ((base-url (or (hunchentoot:post-parameter "base-url") (hunchentoot:referer))))    
    (prog1 (create-plist-from-urls (hunchentoot:post-parameter "urls") base-url)
      (log-info "End handling route check-links/for-links."))))

(defun create-plist-from-urls (urls base-url)
  (log-info "Start create plist from POST parameter URLS.") 
  (prog1
      (let (res)
;	(break "urls: ~s" urls)
	(dolist (link (split-sequence:split-sequence
		       #\Newline
		       (string-trim " " urls))
		 (reverse res))	  
	  ;(break "link: ~S" link)
	  (push (list :url link
		      :valid-p (check-link link :base-url base-url)) 
		res)))
    (log-info "End create plist from POST parameter URLS.")))

(restas:define-route static-files ("check-links/www/*path-list")  
  (merge-pathnames (list-to-path path-list) (get-www-path)))

(restas:define-route static-tests-files ("check-links/www-tests/*path-list")  
  ;(break "path-list: ~S" path-list)
  (merge-pathnames (list-to-path path-list) (get-www-tests-path)))

