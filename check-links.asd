;;;; check-links.asd
;;;;
;;;; This file is part of the common lisp library - check-links, released under Lisp-LGPL.
;;;; See file COPYING for details.
;;;;
;;;; Author: Katrevich Sergey <linkfly1@newmail.ru>

(defsystem :check-links
  :version "0.0.1"
  :depends-on (:restas :drakma :anaphora :cl-who :split-sequence
	       :lift :local-time :cl-fad :alexandria :puri
	       :iterate :cl-ppcre :chunga :hunchentoot :cl-logging)
  :serial t
  :components ((:module "src"
			:components ((:file "packages")
				     (:file "utilities")
				     (:file "pathnames")
				     (:file "check-links-defmodule" :depends-on ("packages" "pathnames" "check-links"))
				     (:file "check-links-storage" :depends-on ())
				     (:file "port" :depends-on ("check-links-defmodule"))
				     (:file "check-links" :depends-on ("packages" "check-links-storage" "utilities"))
				     (:file "check-links-utilities" :depends-on ("check-links-defmodule"))
				     (:file "check-links-routes" :depends-on ("check-links-defmodule"))
				     (:file "check-links-view" :depends-on ("check-links-defmodule"))
				     (:file "check-links-drawer" :depends-on ("check-links-defmodule"))))))

