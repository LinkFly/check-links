(in-package :restas.check-links)

(defclass drawer () ())

(defmethod restas:render-object ((drawer drawer) object)
 ;(break "(my)Render: ~S" object)
  (log-info "Start render-object.")
  (prog1
      (restas:render-object (find-package :check-links-view) object)
    (log-info "End render-object .")))

(setf *default-render-method* (make-instance 'drawer))

