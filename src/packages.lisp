(defpackage :utilities 
  (:use :cl :lift)
  (:export #:as-string
	   #:replace-many
	   #:symcat
	   #:add-pkg-prefix
	   ;#:with-gensyms
	   #:absolute-pathname-p
	   ))

(defpackage :pathnames 
  (:use :cl :cl-fad)
  (:export 
   #:*LOGS-DIR* #:*TEST-DATA-DIR* #:*SYSTEM-NAME* #:*SRC-DIR*
   #:*WWW-TESTS-DIR* #:*WWW-DIR* #:*TEST-DATA-FILE* #:*STORAGE-DIR*
   #:GET-WWW-PATH #:GET-LOGS-PATH #:GET-WWW-TESTS-PATH
   #:GET-SYSTEM-PATH #:GET-SRC-PATH #:RES
   #:GET-TEST-DATA-PATH #:GET-STORAGE-PATH 
   #:GET-TEST-DATA-PATHNAME))

(defpackage :check-links
  (:use :cl :logging :pathnames :chunga :logging :lift)
  (:export #:check-link))

