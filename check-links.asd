;;;; check-links.asd
;;;;
;;;; This file is part of the common lisp library - check-links, released under Lisp-LGPL.
;;;; 
;;;;
;;;; Author: Katrevich Sergey

(defsystem :check-links
  :depends-on (:restas :drakma :anaphora :cl-who :split-sequence
	       :lift :local-time :cl-fad :alexandria :puri
	       :iterate :cl-ppcre :chunga :hunchentoot)
  :serial t
  :components ((:module "src"
			:components ((:file "packages")
				     (:file "pathnames")
				     (:file "check-links-defmodule")
				     (:file "logger" :depends-on ("check-links-defmodule"))
				     (:file "check-links-storage" :depends-on ("check-links-defmodule"))
				     (:file "port" :depends-on ("check-links-defmodule"))
				     (:file "check-links" :depends-on ("packages"))
				     (:file "check-links-utilities" :depends-on ("check-links-defmodule"))
				     (:file "check-links-routes" :depends-on ("check-links-defmodule"))
				     (:file "check-links-view" :depends-on ("check-links-defmodule"))
				     (:file "check-links-drawer" :depends-on ("check-links-defmodule"))))))

