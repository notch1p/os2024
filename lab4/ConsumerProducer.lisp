;; C/P w/ Semaphore
(import (list 'sb-thread:make-semaphore
              'sb-thread:signal-semaphore
              'sb-thread:wait-on-semaphore
              'sb-thread:make-thread
              'sb-thread:join-thread))

(require :cl-interpol)
(named-readtables:in-readtable :interpol-syntax)

(defstruct (buf (:constructor mkbuf (size start end)))
  (size 3)
  (start 0)
  (end 0)
  (num 0))

(defparameter empty (make-semaphore :count 3))
(defparameter full (make-semaphore :count 0))
(defparameter mutex (make-semaphore :count 1))

(defparameter buffer (mkbuf 3 0 0))

(defmacro fformat (str)
  `(progn
    (format t "~A~%" ,str)
    (force-output)))

(defun producer (thread-name)
  (loop
   (wait-on-semaphore empty)
   (wait-on-semaphore mutex)
   (let ((size (buf-size buffer))
         (start (buf-size buffer)))
     (setf (buf-start buffer) (mod (1+ start) size))
     (incf (buf-num buffer)))
   (fformat #?"Producer ${thread-name} produced, buf now is ${buffer}")
   (sleep 1)
   (signal-semaphore mutex)
   (signal-semaphore full)))

(defun consumer (thread-name)
  (loop
   (wait-on-semaphore full)
   (wait-on-semaphore mutex)
   (let ((size (buf-size buffer))
         (end (buf-end buffer)))
     (setf (buf-end buffer) (mod (1+ end) size))
     (decf (buf-num buffer)))
   (fformat #?"Consumer ${thread-name} consumed, buf now is ${buffer}")
   (sleep 1)
   (signal-semaphore mutex)
   (signal-semaphore empty)))

(defun main ()
  (mapcar (lambda (p)
            (join-thread (car p))
            (join-thread (cdr p)))
      (loop for i from 0 to 2 collect
              (cons
                (make-thread #'producer :name #?"P${i}" :arguments (list #?"P${i}"))
                (make-thread #'consumer :name #?"C${i}" :arguments (list #?"C${i}"))))))
