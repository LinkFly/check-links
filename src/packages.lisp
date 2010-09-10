(defpackage :utilities 
  (:use :cl :lift)
  (:export #:as-string
	   #:replace-many
	   #:symcat))

(defpackage :pathnames 
  (:use :cl :cl-fad)
  (:export 
   #:*LOGS-DIR* #:*TEST-DATA-DIR* #:*SYSTEM-NAME* #:*SRC-DIR*
   #:*WWW-TESTS-DIR* #:*WWW-DIR* #:*TEST-DATA-FILE* #:*STORAGE-DIR*
   #:GET-WWW-PATH #:GET-LOGS-PATH #:GET-WWW-TESTS-PATH
   #:GET-SYSTEM-PATH #:GET-SRC-PATH #:RES
   #:GET-TEST-DATA-PATH #:GET-STORAGE-PATH 
   #:GET-TEST-DATA-PATHNAME))

(defpackage :logging 
  (:use :cl :lift :utilities :cl-fad :local-time :iterate :anaphora :alexandria)
  (:shadowing-import-from :cl-fad #:copy-stream #:copy-file)
  (:export #:define-logging
	   #:log-type-message
	   #:open-log-types-streams
	   #:close-log-types-streams
	   #:switch-log-type
	   #:enable-log-type
	   #:for-test-created-logs
	   #:for-test-generated-functions))


(defpackage :check-links
  (:use :cl :pathnames :chunga :logging :lift)
  (:export #:check-link))

