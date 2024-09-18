## Lab3

输出示例 (数据来自课本 P102):

```plaintext
Number of processes: 5
Number of resource types: 3
Initial Available resources: (3 3 2)
Initial Allocation: ((0 1 0) (2 0 0) (3 0 2) (2 1 1) (0 0 2))
Initial Need: ((7 4 3) (1 2 2) (6 0 0) (0 1 1) (4 3 1))
Work+Allocation: (10 5 7)
The system is Safe initially. Possible safe sequence being (1 3 4 0 2) 

Enter (PROCESS-ID REQUEST)
1 (1 0 2)

Requesting: PROC1,(1 0 2)
requesting allocation for process 1: (1 0 2)
Work+Allocation: (10 5 7)
Allocation for PROC1:(1 0 2) is safe
Available resources: (2 3 0)
Allocation: ((0 1 0) (3 0 2) (3 0 2) (2 1 1) (0 0 2))
Need: ((7 4 3) (0 2 0) (6 0 0) (0 1 1) (4 3 1))
Safe sequence: (1 3 4 0 2)

Enter (PROCESS-ID REQUEST)
4 (3 3 0)

Requesting: PROC4,(3 3 0)
requesting allocation for process 4: (3 3 0)
ERROR: Process 4 is requesting more than available resources.
Allocation for PROC4:(3 3 0) is unsafe
Restoring...

Enter (PROCESS-ID REQUEST)
0 (0 2 0)

Requesting: PROC0,(0 2 0)
requesting allocation for process 0: (0 2 0)
Work+Allocation: (10 5 7)
Allocation for PROC0:(0 2 0) is unsafe
Restoring...
```

### 思考题

安全性算法的本质是测试 allocation 之后所有的进程仍能够执行完毕 (即 allocation 不影响进程的执行成功率, 总是应该 100% 成功, 否则这个实现有问题). 因而需要复制 Available 一份到 work, 用于模拟 allocation 之后各线程的执行情况. 如果全部执行完毕 (i.e. `finish` 都为真), 这才能说明 allocation 正确.

这一试探性的操作是尝试当前 allocation 是否正确的, 不应该把测试中所产生的临时量直接更新到 Available 中 (即测试中产生的 side effects 不应该外泄), 否则每次 `check` 都会把所有进程执行直至全部执行完毕 (或有失败), 这显然是错误的.

### 完整代码

(注释掉的代码就是课本 P102 的数据)

```lisp
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

(defun any-list> (xs ys)
  (some (lambda (x) (>= x 1)) (mapcar #'- xs ys)))

(defun any-list>= (xs ys)
  (some (lambda (x) (>= x 0)) (mapcar #'- xs ys)))

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
                          (list<= (nth i need) work))
                     (progn
                      (list-incf work (nth i allocation))
                      (setf
                        exists-1-passed t
                        safe-sequence (cons i safe-sequence)
                        iota (remove i iota)
                        (nth i finish) t))))
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
  (if (any-list> request (nth request-id need))
      (progn
       (format t
           "ERROR: Process ~A is requesting more than it needs.~%"
         request-id)
       (return-from bankers nil))
      (if (any-list> request available-resources)
          (progn
           (format t
               "ERROR: Process ~A is requesting more than available resources.~%"
             request-id)
           (return-from bankers nil))
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
```
