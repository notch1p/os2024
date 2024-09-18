(format t "Enter process requests matrix shape (ROW COL): ~%")
(defparameter requests (read))

; (defparameter requests '(5 3))

(defparameter number-of-processes (first requests))
(defparameter number-of-resource-type (second requests))

(format t "Number of processes: ~A~%" number-of-processes)
(format t "Number of resource types: ~A~%" number-of-resource-type)

(declaim
  (inline random-between)
  (ftype (function (fixnum fixnum) fixnum) random-between))
(defun random-between (start finish)
  "Return a random number between START and FINISH. (inclusive)"
  (+ start (random (1+ (- finish start)))))

(defparameter available-resources
              (loop for i from 1 to number-of-resource-type
                    collect (random-between 1 10)))
; (defparameter available-resources '(3 3 2))
(format t "Initial Available resources: ~A~%" available-resources)

(defparameter allocation
              ; number-of-processes * number-of-resource-type
              (loop for i from 1 to number-of-processes collect
                      (loop for j from 1 to number-of-resource-type
                            collect (random-between 0 4))))

; (defparameter allocation
;               '((0 1 0)
;                 (2 0 0)
;                 (3 0 2)
;                 (2 1 1)
;                 (0 0 2)))

(format t "Initial Allocation: ~A~%" allocation)

(defparameter maximum-needs
              ; number-of-processes * number-of-resource-type
              (loop for i from 1 to number-of-processes collect
                      (loop for j from 1 to number-of-resource-type
                            collect (random-between 1 6))))

; (defparameter maximum-needs
;               '((7 5 3)
;                 (3 2 2)
;                 (9 0 2)
;                 (2 2 2)
;                 (4 3 3)))

(declaim (type list need))
(defparameter
  need
  (mapcar (lambda (xs ys)
            (mapcar (lambda (x y)
                      (let ((delta (- x y)))
                        (if (>= delta 0) delta 0))) xs ys))
      maximum-needs
    allocation))

(format t "Initial Need: ~A~%" need)

(defun list> (xs ys)
  (if (or (null xs) (null ys)) (null ys)
      (let ((x (car xs))
            (y (car ys)))
        (and (> x y)
             (list> (cdr xs) (cdr ys))))))

(defun list>= (xs ys)
  (if (or (null xs) (null ys)) (null ys)
      (let ((x (car xs))
            (y (car ys)))
        (and (>= x y)
             (list>= (cdr xs) (cdr ys))))))

(defun list< (xs ys)
  (if (or (null xs) (null ys)) (null xs)
      (let ((x (car xs))
            (y (car ys)))
        (and (< x y)
             (list< (cdr xs) (cdr ys))))))

(defun list<= (xs ys)
  (if (or (null xs) (null ys)) (null xs)
      (let ((x (car xs))
            (y (car ys)))
        (and (<= x y)
             (list<= (cdr xs) (cdr ys))))))

(defmacro list-decf (place value)
  `(setf ,place (mapcar #'- ,place ,value)))

(defmacro list-incf (place value)
  `(setf ,place (mapcar #'+ ,place ,value)))

(declaim (inline allocate))
(defun allocate (p request-id)
  (list-decf available-resources p)
  (list-incf (nth request-id allocation) p)
  (list-decf (nth request-id need) p))

(defparameter safe-sequence '())

(defun iota (n)
  (loop for i from 0 below n collect i))

; () -> Boolean
(declaim (ftype (function () boolean) check))
(defun check ()
  (let ((work (copy-tree available-resources))
        (finish (make-list number-of-processes :initial-element nil))
        (iota (iota number-of-processes))
        (exists-1-passed nil))
    (loop named loop-1 initially (setq safe-sequence nil)
        do
          (loop initially (setq exists-1-passed nil)
              for i in iota
              do (if (and (null (nth i finish))
                          (list>= work (nth i need)))
                     (progn (setf exists-1-passed t)
                            (list-incf work (nth i allocation))
                            (setf safe-sequence (cons i safe-sequence))
                            (setf iota (remove i iota))
                            (setf (nth i finish) t))))
          when (not exists-1-passed) do (return-from loop-1))
    (format t "Work+Allocation: ~A~%" work)
    (every #'identity finish)))

(format t
    "The system is ~A initially. Possible safe sequence being ~A ~%"
  (if (check) "Safe" "Unsafe")
  (reverse safe-sequence))

; [Fixnum] -> Fixnum -> Boolean
(declaim (ftype (function (list fixnum) boolean) bankers))
(defun bankers (request request-id)
  (format t "requesting allocation for process ~A: ~A~%" request-id request)
  (if (list> request (nth request-id need))
      (error "Process ~A is requesting more than it needs." request-id)
      (if (list> request available-resources)
          (error "Process ~A is requesting more than available resources." request-id)
          (progn
           (allocate request request-id)
           (check)))))


(loop
 (format t "Enter (PROCESS-ID REQUEST)~%")
 (destructuring-bind (i request)
     `(,(read) ,(read))
   (declare (type fixnum i) (type list request))
   (format t "Requesting: PROC~A,~A~%" i request)
   (if (/= (list-length request) number-of-resource-type)
       (error "Request must be of length ~A." number-of-resource-type)
       (progn
        (if (bankers request i)
            (progn
             (format t "Allocation for PROC~A:~A is safe~%" i request)
             (format t "Available resources: ~A~%" available-resources)
             (format t "Allocation: ~A~%" allocation)
             (format t "Need: ~A~%" need)
             (format t "Safe sequence: ~A~%" (reverse safe-sequence)))
            (progn
             (format t "Allocation for PROC~A:~A is unsafe~%" i request)
             (format t "Restoring...")
             (list-incf available-resources (nth i allocation))
             (list-decf (nth i allocation) request)
             (list-incf (nth i need) request)))))))