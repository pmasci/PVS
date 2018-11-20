;;
;; eval.lisp
;; Release: PVSio-6.0.10 (xx/xx/xx)
;;
;; Contact: Cesar Munoz (cesar.a.munoz@nasa.gov)
;; NASA Langley Research Center
;; http://shemesh.larc.nasa.gov/people/cam/PVSio
;;
;; Copyright (c) 2011-2012 United States Government as represented by
;; the National Aeronautics and Space Administration.  No copyright
;; is claimed in the United States under Title 17, U.S.Code. All Other
;; Rights Reserved.
;;
;; List of strategies in PVSio: eval, eval-expr, and eval-formula
;;

(in-package :pvs)

(defparameter *pvsio-strategies* nil)

(pushnew "eval-formula" *pvsio-strategies* :test #'string=)
(pushnew "eval-expr"    *pvsio-strategies* :test #'string=)
(pushnew "eval"         *pvsio-strategies* :test #'string=)

(define-condition eval-error (simple-condition) ())

(define-condition pvsio-inprover (simple-condition) ())

(defun evalexpr (expr &optional safe)
  (when expr
    (handler-case
	(let* ((pr-input (extra-get-expr expr))
	       (*tccforms* nil)
	       (*generate-tccs* 'all)
	       (tc-input (pc-typecheck pr-input)))
	  (when (and *tccforms* safe)
	    (format t "~%Typechecking ~s produced TCCs:~%" expr)
	    (evaluator-print-tccs *tccforms*)
	    (error 'eval-error "Use option :safe? nil if TCCs are provable"))
	  (let* ((cl-input (handler-case (pvs2cl tc-input)
			     (pvseval-error (condition) nil)))
		 (cl-eval (eval cl-input))
		 (pvs-val (cl2pvs cl-eval (type tc-input))))
	    (assert (expr? pvs-val))
	    pvs-val))
      ;; At the moment, all errors simply print the condition, and evalexpr returns nil
      (groundeval-error (condition) (format t "~%~a" condition))
      (pvsio-inprover (condition) (format t "~%~a" condition)))))

(defrule eval-expr (expr &optional safe? (auto? t) quiet?)
  (let ((e (extra-get-expr expr)))
    (when e
	(let ((result (evalexpr e safe?)))
	  (if (stringp result)
	      (unless quiet? (printf "Error: ~a~%" result))
	    (when result 
	      (let ((casexpr (format nil "~a = ~a" e result)))
		(with-fresh-labels
		 ((!evx))
		 (trust *PVSGroundEvaluator*
			(discriminate (case casexpr) !evx)
			((skip) !
			 (when auto? (eval-formula !evx)))))))))))
  "[PVSio] Adds the hypothesis expr=eval(EXPR) to the current goal, 
where eval(EXPR) is the ground evaluation of EXPR. If SAFE? is t and EXPR
generates TCCs, the expression is not evaluated. Otherwise, TCCs
are added as subgoals and the expression is evaluated. If AUTO? is t,
TCCs are ground evaluated. The strategy is sound in the sense that
user-defined semantic attachments are not evaluated. However, if SAFE? is nil,
the strategy may not terminate properly in the presence of unproven TCCs. When
QUIET? is t, the strategy fails silently."
  "Evaluating expression ~a in the current sequent")

(defrule eval-formula (&optional (fnum 1) safe? quiet?)
  (let ((fexpr (extra-get-seqf fnum)))
    (when fexpr
      (let ((expr   (formula fexpr))
	    (result (evalexpr expr safe?)))
	(if (stringp result)
	    (unless quiet? (printf "Error: ~a~%" result))
	  (when result 
	    (trust *PVSGroundEvaluator*
		   (case result)
		   (! (skip))))))))
  "[PVSio] Evaluates the formula FNUM in Common Lisp and adds the result to 
the antecedent of the current goal. If SAFE? is t and FNUM generates TCCs, 
the expression is not evaluated. The strategy is safe in the sense that 
user-defined semantic attachments are not evaluated. However, 
if SAFE? is nil, the strategy may not terminate properly in
the presence of unproven TCCs.  When QUIET? is t, the strategy fails silently"
  "Evaluating formula ~a in the current sequent")

(defrule eval (expr &optional safe? quiet?)
  (let ((e (extra-get-expr expr)))
    (when e
      (let ((*in-evaluator* t)
	    (result (evalexpr e safe?)))
	(if (stringp result)
	    (unless quiet? (printf "Error: ~a~%" result))
	  (when result
	    (printf "~a = ~a~%" e result))))))
  "[PVSio] Prints the evaluation of expression EXPR. If SAFE? is t and EXPR 
generates TCCs, the expression is not evaluated. This strategy evaluates
semantic attachments. Therefore, it may not terminate properly. When QUIET? 
is t, the strategy fails silently."
  "Printing the evaluation of ~a")

(defstrat pvsio-about ()
  (let ((version *pvsio-version*)
	(strategies *pvsio-strategies*))
    (printf "%--
% ~a 
% http://shemesh.larc.nasa.gov/people/cam/PVSio
% Strategies in PVSio: ~{~a~^, ~}
%--~%" version strategies))
  "[PVSio] Prints PVSio's about information.")

