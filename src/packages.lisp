(defpackage :check-links-utilities 
  (:use :cl :lift)
  (:export #:as-string
	   #:replace-many
	   #:symcat
	   #:add-package-prefix
	   #:list-to-path))

(defpackage :check-links-utilities-port
  (:use :cl :lift)
  (:export #:absolute-pathname-p
	   #:return-if-very-long))

(defpackage :pathnames 
  (:use :cl :cl-fad)
  (:export #:GET-WWW-PATH #:GET-LOGS-PATH #:GET-WWW-TESTS-PATH
   	   #:GET-SYSTEM-PATH #:GET-SRC-PATH
	   #:GET-TEST-DATA-PATH #:GET-STORAGE-PATH 
	   #:GET-TEST-DATA-PATHNAME))

(defpackage :check-links
  (:use :cl :puri :pathnames :chunga 
	:logging :lift :alexandria :anaphora
	:check-links-utilities :check-links-utilities-port
	:iterate)
  (:export #:check-link #:*storage* #:memory-storage-obsolete-time))

