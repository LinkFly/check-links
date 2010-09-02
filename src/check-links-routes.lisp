(in-package :restas.check-links)

#|(restas:define-route check-links-route-2 ("check-links/for-links"
					:method :options)
  (break "~A" (hunchentoot:post-parameter "urls"))
  "<b>OK</b>")
|#

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
		      :valid-p (check-link link base-url))
		res)))
    (log-info "End create plist from POST parameter URLS.")))

(restas:define-route static-files ("check-links/www/*path-list")  
  (merge-pathnames (list-to-path path-list) (get-www-path)))

(restas:define-route static-tests-files ("check-links/www-tests/*path-list")  
  (merge-pathnames (list-to-path path-list) (get-www-tests-path)))

