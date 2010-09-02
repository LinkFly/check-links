(in-package :restas.check-links)

;(restas.check-links:check-link "http://badlink.ru")
(defmacro return-if-very-long (sec-max form &optional value)
  `(handler-case (sb-ext:with-timeout (float ,sec-max) ,form)
     (sb-ext:timeout () ,value)))
