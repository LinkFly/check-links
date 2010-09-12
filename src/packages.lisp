(defpackage :utilities 
  (:use :cl :lift)
  (:export #:as-string
	   #:replace-many
	   #:symcat
	   #:add-package-prefix))

(defpackage :utilities-port
  (:use :cl :lift)
  (:export #:absolute-pathname-p
	   #:return-if-very-long))

(defpackage :pathnames 
  (:use :cl :cl-fad)
  (:export 
   #:*LOGS-DIR* #:*TEST-DATA-DIR* #:*SYSTEM-NAME* #:*SRC-DIR*
   #:*WWW-TESTS-DIR* #:*WWW-DIR* #:*TEST-DATA-FILE* #:*STORAGE-DIR*
   #:GET-WWW-PATH #:GET-LOGS-PATH #:GET-WWW-TESTS-PATH
   #:GET-SYSTEM-PATH #:GET-SRC-PATH
   #:GET-TEST-DATA-PATH #:GET-STORAGE-PATH 
   #:GET-TEST-DATA-PATHNAME))

(defpackage :check-links
  (:use :cl :puri :logging :pathnames :chunga 
	:logging :lift :alexandria :anaphora
	:utilities :utilities-port)
  (:export #:check-link #:*storage* #:memory-storage-obsolete-time))

