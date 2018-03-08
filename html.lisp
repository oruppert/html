;; * Overview

;; This program is an HTML generator for Common Lisp.

;; Why another one?

;; The libraries known to me (cl-who) transform symbolic expressions
;; into a series of print statements that generate HTML as a side
;; effect.

;; These side effects complicate the use of functional abstractions:

;; - HTML can not be stored in variables.

;; - HTML can not be used as a function argument or return value.

;; - HTML can not be changed programmatically.

;; - HTML is not a real data type.

;; * Code

(defpackage html
  (:use :common-lisp)
  (:export :render :print-html :print-html-to-string :html))

(in-package :html)

(defgeneric print-html (object stream)
  (:method (object stream)
    (print-html (render object) stream))
  (:method ((char character) stream)
    (case char
      (#\< (write-string "&lt;" stream))
      (#\> (write-string "&gt;" stream))
      (#\& (write-string "&amp;" stream))
      (#\" (write-string "&quot;" stream))
      (t (write-char char stream))))
  (:method ((string string) stream)
    (map nil (lambda (char) (print-html char stream)) string))
  (:method ((list list) stream)
    (dolist (object list)
      (print-html object stream))))

(defgeneric render (object)
  (:method (object)
    (princ-to-string object)))

(defun print-html-to-string (object)
  (with-output-to-string (stream)
    (print-html object stream)))

(defstruct tag name attrs children)

(defmethod print-html ((self tag) stream)
  (print-html (tag-children self) stream))

(defmethod print-html :before ((self tag) stream)
  (format stream "~&<~(~a~)~{ ~(~a~)=~s~}>" (tag-name self)
	  (loop for (k v) on (tag-attrs self) by #'cddr when v
	     collect (print-html-to-string k) and
	     collect (print-html-to-string (if (eq v t) k v)))))

(defmethod print-html :after ((self tag) stream)
  (unless (member (tag-name self) (list :input))
    (format stream "</~(~a~)>~&" (tag-name self))))

(defmacro html (&body body)
  (labels ((listify (x) (if (listp x) x (list x)))
	   (codegen (x)
	     (cond ((atom x) x)
		   ((not (keywordp (car (listify (car x))))) x)
		   (t (destructuring-bind (head &rest body) x
			(destructuring-bind (name &rest attrs) (listify head)
			  `(make-tag :name ,name :attrs (list ,@attrs)
				     :children (html ,@body))))))))
    `(list ,@(mapcar #'codegen body))))

