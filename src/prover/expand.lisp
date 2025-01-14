;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; -*- Mode: Lisp -*- ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; expand.lisp -- 
;; Author          : N. Shankar and Sam Owre
;; Created On      : Sat Oct 31 02:31:26 1998
;; Last Modified By: Sam Owre
;; Last Modified On: Thu May 20 21:20:29 2004
;; Update Count    : 2
;; Status          : Stable
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; --------------------------------------------------------------------
;; PVS
;; Copyright (C) 2006, SRI International.  All Rights Reserved.

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 2
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
;; --------------------------------------------------------------------

(in-package :pvs)

(defvar *count-occurrences* 0)
(defvar *if-simplifies*)
(defvar *expand-in-actuals?* nil)
(defvar *names-from-symbols*)
;(defvar *dependent-decls*)


(defun expand (name &optional sformnum occurrence if-simplifies
		    assert? actuals?)
  #'(lambda (ps)
      (expand-step name ps sformnum occurrence if-simplifies
		   assert? actuals?)))

(defun expand-step (name ps sformnum occurrence if-simplifies assert? actuals?)
  (let* ((goalsequent (current-goal ps))
	 (*assert-flag* (if (eq assert? 'none) 'none
			    (if assert? 'assert 'simplify)))
	 (*hash-rewrites?* t)
	 (*rewrite-hash* ;;if *hash-rewrites?*
	  (copy (rewrite-hash ps)))
	 (*sequent-typealist* nil)
	 ;(*quant-simp?* nil)
	 (sformnums (if (memq sformnum '(* + -))
			sformnum
		       (list sformnum)))
	 (sforms (s-forms goalsequent))
	 (lnames (if (listp name) name (list name)))
	 (*names-from-symbols* nil)
	 (nnames (mapcar #'(lambda (n)
			     (let ((nn (pc-parse n 'bname)))
			       (when (number-expr? nn)
				 (change-class nn 'name-expr 'id (number nn)))
			       (when (symbolp n)
				 ;; Symbols are accepted for names, but SBCL
				 ;; will read/store them in uppercase.
				 ;; See same-expand-name*
				 (push nn *names-from-symbols*))
			       nn))
		   lnames))
	 (occurrence (if (numberp occurrence)
			 (list occurrence)
			 occurrence))
	 (*max-occurrence* (if (consp occurrence)
			       (apply #'max occurrence)
			       0))
	 (*dependent-decls* nil)
	 (*if-simplifies* if-simplifies)
	 (*expand-in-actuals?* actuals?))
    (dolist (pname nnames)
      (when (and (name? pname)
		 (or (mod-id pname)
		     (actuals pname)
		     (mappings pname)
		     (target pname)))
	(pc-typecheck pname)))
    (cond ((not (or (null occurrence)
		    (and (listp occurrence)
			 (every #'(lambda (x)
				    (and (numberp x)
					 (plusp x)))
				occurrence))))
	   (error-format-if "Occurrence ~a must be nil, a positive number or a 
list of positive numbers" occurrence)
	   (values 'X nil nil))
	  ((and occurrence
		(cdr nnames))
	   (error-format-if "Occurrence should not be given with multiple names"))
	  (t 
	   (let ((new-sforms
		  (expand-sforms nnames sforms sformnums occurrence)))
	     (cond ((every #'eq sforms new-sforms)
		    (values 'X nil nil))
		   (t (mapcar #'(lambda (x)
				  (pushnew x (dependent-decls ps)))
			      *dependent-decls*)
		      (values '? (list
				  (list (lcopy goalsequent
					  's-forms new-sforms)
					'dependent-decls
					*dependent-decls*))))))))))

(defun expand-sforms (name sforms sformnums occurrence)
  (expand-sforms* name sforms (cleanup-fnums sformnums) occurrence +1 -1 nil))

(defun expand-sforms* (name sforms sformnums occurrence pos neg accum)
  (if (null sforms)
      (nreverse accum)
      (let* ((*count-occurrences* 0)
	     (fmla (formula (car sforms)))
	     (new-fmla
	      (if (in-sformnums? (car sforms) pos neg sformnums)
		  (expand-defn name fmla occurrence)
		  fmla))
	     )
	#+pvsdebug (assert (fully-instantiated? new-fmla))
	#+pvsdebug (assert (fully-typed? new-fmla))
	(if (eq fmla new-fmla)
	    (expand-sforms* name (cdr sforms)
			    sformnums occurrence
			    (if (not (negation? fmla))
				(1+ pos)
				pos)
			    (if (negation? fmla)
				(1- neg)
				neg)
			    (cons (car sforms) accum))
	    (multiple-value-bind (sig result)
		(if (eq *assert-flag* 'none)
		    (values 'X new-fmla) ;;NSH(1/16/97): Myla Archer
		    ;;wanted no-simplification option.
		    (let ((*use-rationals* t))
		      (assert-if-inside new-fmla)))
	      (let ((new-sform (lcopy (car sforms)
				 'formula (if (eq sig 'X)
					      new-fmla
					      result))))
		(if occurrence
		    (append (nreverse accum)
			    (cons new-sform (cdr sforms)))
		    ;;since only one formula is
		    ;;processed when occurrence is
		    ;;given.  
		    (expand-sforms* name (cdr sforms)
				    sformnums occurrence
				    (if (not (negation? fmla))
					(1+ pos)
					pos)
				    (if (negation? fmla)
					(1- neg)
					neg)
				    (cons new-sform accum)))))))))

(defun match-defns (expr def-axioms)
  (cond ((null def-axioms) 'fail)
	(t (let* ((*modsubst* t)
		  (ax (car def-axioms))
		  (def-expr (if (forall-expr? ax)
				(expression ax)
				ax))
		  (lhs (args1 def-expr))
		  (rhs (args2 def-expr))
		  (sub 
		   (call-match lhs expr nil nil)))
	     (if (not (eq sub 'fail))
		 (values sub rhs)
		 'fail)))))




(defmethod expand-defn (name (expr projection-expr) occurrence)
  (declare (ignore name occurrence))
  expr)

(defmethod expand-defn (name (expr injection-expr) occurrence)
  (declare (ignore name occurrence))
  expr)

(defmethod expand-defn (name (expr injection?-expr) occurrence)
  (declare (ignore name occurrence))
  expr)

(defmethod expand-defn (name (expr extraction-expr) occurrence)
  (declare (ignore name occurrence))
  expr)

(defmethod expand-defn (name (expr projection-application) occurrence)
  (if (and (plusp *max-occurrence*)
	   (< *max-occurrence* *count-occurrences*))
      expr
      (let* ((arg (argument expr))
	     (newarg (expand-defn name arg occurrence)))
	(lcopy expr 'argument newarg))))

(defmethod expand-defn (name (expr injection-application) occurrence)
  (if (and (plusp *max-occurrence*)
	   (< *max-occurrence* *count-occurrences*))
      expr
      (let* ((arg (argument expr))
	     (newarg (expand-defn name arg occurrence)))
	(lcopy expr 'argument newarg))))

(defmethod expand-defn (name (expr injection?-application) occurrence)
  (if (and (plusp *max-occurrence*)
	   (< *max-occurrence* *count-occurrences*))
      expr
      (let* ((arg (argument expr))
	     (newarg (expand-defn name arg occurrence)))
	(lcopy expr 'argument newarg))))

(defmethod expand-defn (name (expr extraction-application) occurrence)
  (if (and (plusp *max-occurrence*)
	   (< *max-occurrence* *count-occurrences*))
      expr
      (let* ((arg (argument expr))
	     (newarg (expand-defn name arg occurrence)))
	(lcopy expr 'argument newarg))))

(defmethod expand-defn (name (expr field-application) occurrence)
  (if (and (plusp *max-occurrence*)
	   (< *max-occurrence* *count-occurrences*))
      expr
      (let* ((arg (argument expr))
	     (newarg (expand-defn name arg occurrence)))
	(lcopy expr 'argument newarg))))

(defmethod expand-defn (name (expr application) occurrence)
  (if (and (plusp *max-occurrence*)
	   (< *max-occurrence* *count-occurrences*))
      expr
      (let* ((op* (operator* expr)))
	(if (and (name? op*)
		 (same-expand-name op* name)
		 (null occurrence)
		 *if-simplifies*)
	    (let* ((def-axioms (create-formulas (resolution op*))))
	      (multiple-value-bind (subst rhs)
		  (match-defns expr def-axioms)
		(if (not (eq subst 'fail))
		    (let* ((xsubst
			    (loop for (x . y) in subst
				  collect
				  (cons x (expand-defn name y occurrence))))
			   (subexpr (substit rhs xsubst)))
		      (multiple-value-bind (sig value)
			  (lazy-assert-if subexpr)
			(cond ((and (or (typep subexpr 'cases-expr)
					(branch? subexpr))
				    (eq sig 'X))
			       (expand-defn-application name expr
							occurrence))
			      (t (pushnew (declaration (resolution op*))
					  *dependent-decls*)
				 value))))
		    (expand-defn-application name expr occurrence))))
	    (expand-defn-application name expr occurrence)))))

; (defmethod expand-defn (name (expr infix-application) occurrence)
;   (let ((nexpr (call-next-method)))
; ;    (unless (eq nexpr expr)
; ;      (setf (parens nexpr) 1))
;     nexpr))
				       
(defmethod expand-defn-application (name (expr application) occurrence)
  (let* ((oper (operator expr))
	 (arg (argument expr))
	 (op* (operator* expr))
	 (newoper (expand-defn name oper occurrence))
	 (newargs (expand-defn name arg occurrence)))
    (if (and (not (eq oper newoper))
	     (typep  op* 'name-expr)
	     (same-expand-name op* name)
	     (typep newoper 'lambda-expr))
	(substit (expression newoper)
	  (cond ((singleton? (bindings newoper))
		 (acons (car (bindings newoper)) newargs nil))
		(t
		 (pairlis-args (bindings newoper)
			       (argument-list newargs)))))
	(if (and (eq oper newoper)
		 (eq arg newargs))
	    expr
	    (let* ((stype (find-supertype (type newoper)))
		   (nex (simplify-or-copy-app
			 expr newoper newargs
			 (if (typep (domain stype) 'dep-binding)
			     (substit (range stype)
			       (acons (domain stype) newargs nil))
			     (range stype)))))
	      #+pvsdebug
	      (assert (subsetp (freevars nex) (union (freevars expr) *bound-variables*)
			       :key #'declaration))
	      (unless (eq newoper (operator expr))
		(change-application-class-if-necessary expr nex))
	      nex)))))

(defmethod expand-defn-application (name (expr infix-application) occurrence)
  (if (and occurrence
	   ;; Check that it prints as an infix
	   (valid-infix-application? expr))
      (let* ((oper (operator expr))
	     (lhs (args1 expr))
	     (rhs (args2 expr))
	     (newlhs (expand-defn name lhs occurrence))
	     (newoper (expand-defn name oper occurrence))
	     (newrhs (expand-defn name rhs occurrence)))
	(if (and (eq oper newoper)
		 (eq lhs newlhs)
		 (eq rhs newrhs))
	    expr
	    (if (typep newoper 'lambda-expr)
		(substit (expression newoper)
		  (pairlis-args (bindings newoper)
				(list newlhs newrhs)))
		(let* ((stype (find-supertype (type newoper)))
		       (newargs (make!-arg-tuple-expr newlhs newrhs))
		       (nex (simplify-or-copy-app
			     expr newoper newargs
			     (if (typep (domain stype) 'dep-binding)
				 (substit (range stype)
				   (acons (domain stype) newargs nil))
				 (range stype)))))
		  (unless (eq newoper (operator expr))
		    (change-application-class-if-necessary expr nex))
		  nex))))
      (call-next-method)))


(defmethod expand-defn (name (expr name-expr) occurrence)
  (if (and (plusp *max-occurrence*)
	   (< *max-occurrence* *count-occurrences*))
      expr
      (cond ((same-expand-name expr name)
	     (setf *count-occurrences* (1+ *count-occurrences*))
	     (if (or (null occurrence)
		     (member *count-occurrences* occurrence
			     :test #'eql))
		 (cond ((def-axiom (declaration expr))
			(let ((rhs (args2
				    (let ((*smp-include-actuals* t))
				      (subst-mod-params
					  (car (last (def-axiom
							 (declaration expr))))
					  (module-instance (resolution expr))
					(module (declaration expr))
					(declaration expr))))))
			  (cond ((not *if-simplifies*)
				 (pushnew (declaration expr)
					  *dependent-decls*)
				 rhs)
				((typep rhs 'lambda-expr)
				 expr)
				((or (typep rhs 'cases-expr)
				     (branch? rhs))
				 (multiple-value-bind
				     (sig result)
				     (lazy-assert-if rhs)
				   (cond ((eq sig 'X)
					  expr)
					 (t (pushnew (declaration expr)
						     *dependent-decls*)
					    result))))
				(t (pushnew (declaration expr)
					    *dependent-decls*)
				   rhs))))
		       ((formula-decl? (declaration expr))
			;; Substitute the closed-definition for the formula name
			(let ((rhs (subst-mod-params
				       (closed-definition (declaration expr))
				       (module-instance (resolution expr))
				     (module (declaration expr))
				     (declaration expr))))
			  (pushnew (declaration expr) *dependent-decls*)
			  rhs))
		       ((mappings (module-instance expr))
			(subst-mod-params expr (module-instance expr)))
		       (t expr))
		 expr))
	    ((and *expand-in-actuals?*
		  (or (actuals expr)
		      (mappings expr)))
	     (let ((eacts (expand-defn name (actuals expr) occurrence))
		   (emaps (expand-defn name (mappings expr) occurrence)))
	       (if (and (eq eacts (actuals expr))
			(eq emaps (mappings expr)))
		   expr
		   (let* ((thinst (copy (module-instance expr)
				    'actuals eacts 'mappings emaps))
			  (res (make-resolution (declaration expr) thinst)))
		     (copy expr
		       'actuals eacts
		       'mappings emaps
		       'resolutions (list res))))))
	    (t expr))))

(defmethod expand-defn (name (expr actual) occurrence)
  (if (type-value expr)
      expr
      (lcopy expr
	'expr (expand-defn name (expr expr) occurrence))))

(defmethod expand-defn (name (expr mapping) occurrence)
  (lcopy expr
    'rhs (expand-defn name (rhs expr) occurrence)))

(defmethod expand-defn (name (expr binding-expr) occurrence)
  (if (and (plusp *max-occurrence*)
	   (< *max-occurrence* *count-occurrences*))
      expr
      (lcopy expr
	'expression (expand-defn name (expression expr) occurrence))))

(defmethod expand-defn (name (expr lambda-expr) occurrence)
  (if (and (plusp *max-occurrence*)
	   (< *max-occurrence* *count-occurrences*))
      expr
      (let ((exp-expr (expand-defn name (expression expr) occurrence)))
	(if (eq exp-expr (expression expr))
	    expr
	    (let ((ltype (if (tc-eq (range (type expr)) (type exp-expr))
			     (type expr)
			     (get-lambda-expr-funtype-for-range
			      expr (type exp-expr)))))
	      (copy expr
		:expression exp-expr
		:type ltype))))))

(defmethod expand-defn (name (expr tuple-expr) occurrence)
  (if (and (plusp *max-occurrence*)
	   (< *max-occurrence* *count-occurrences*))
      expr
      (let ((nexprs (expand-defn name (exprs expr) occurrence)))
	(if (eq nexprs (exprs expr))
	    expr
	    (copy expr
	      'exprs nexprs
	      'type (mk-tupletype (mapcar #'type nexprs)))))))

(defmethod expand-defn (name (expr record-expr) occurrence)
  (if (and (plusp *max-occurrence*)
	   (< *max-occurrence* *count-occurrences*))
      expr
  (lcopy expr
    'assignments
    (expand-defn name (assignments expr) occurrence))))

(defmethod expand-defn (name (expr assignment) occurrence)
  (lcopy expr
    'arguments (expand-defn name (arguments expr) occurrence)
    'expression (expand-defn name (expression expr) occurrence)))

(defmethod expand-defn (name (expr field-assignment-arg) occurrence)
  (declare (ignore name occurrence))
  expr)

(defmethod expand-defn (name (expr list) occurrence)
  (let ((newlist (mapcar #'(lambda (x) (expand-defn name x
						    occurrence))
			 expr)))
    (if (every #'eq expr newlist)
	expr
	newlist)))

(defmethod expand-defn (name (expr update-expr) occurrence)
  (if (and (plusp *max-occurrence*)
	   (< *max-occurrence* *count-occurrences*))
      expr
  (lcopy expr
    'expression (expand-defn name (expression expr) occurrence)
    'assignments (expand-defn name (assignments expr) occurrence))))

(defmethod expand-defn (name (expr cases-expr) occurrence)
  (if (and (plusp *max-occurrence*)
	   (< *max-occurrence* *count-occurrences*))
      expr
  (lcopy expr
    'expression (expand-defn name (expression expr) occurrence)
    'selections (expand-defn name (selections expr) occurrence)
    'else-part (expand-defn name (else-part expr) occurrence))))

(defmethod expand-defn (name (expr selection) occurrence)
  (lcopy expr
    'expression (expand-defn name (expression expr) occurrence)))

(defmethod expand-defn (name (expr expr) occurrence)
  (declare (ignore name occurrence))
  expr)

;;; Compares the tgt-name from the sequent to the pat-name given by the user
;;; Whatever is not nil in the pat-name must match.
(defun same-expand-name (tgt-name pat-names)
  (and pat-names
       (or (same-expand-name* tgt-name (car pat-names))
	   (same-expand-name tgt-name (cdr pat-names)))))

(defun same-expand-name* (tgt-name pat-name)
  (and (or (id-suffix pat-name tgt-name)
	   (when (and (null (resolution pat-name))
		      (memq pat-name *names-from-symbols*)
		      (simple-name? pat-name))
	     ;; Otherwise, could be from a symbol, ignore case
	     (string-equal (id tgt-name) (id pat-name)))
	   (and (memq (id tgt-name) '(/= ≠))
		(memq (id pat-name) '(/= ≠))))
       (or (null (library pat-name))
	   (eq (library tgt-name) (library pat-name))
	   (and (resolution pat-name)
		(eq (library tgt-name) (library (module-instance pat-name)))))
       (or (null (mod-id pat-name))
	   (eq (id (module-instance tgt-name)) (mod-id pat-name))
	   (and (resolution pat-name)
		(eq (id (module-instance tgt-name))
		    (id (module-instance pat-name)))))
       (or (null (actuals pat-name))
	   (tc-eq (actuals (module-instance tgt-name)) (actuals pat-name))
	   (and (resolution pat-name)
		(tc-eq (actuals (module-instance tgt-name))
		       (actuals (module-instance pat-name)))))
       (or (null (mappings pat-name))
	   (tc-eq (mappings tgt-name) (mappings pat-name))
	   (and (resolution pat-name)
		(tc-eq (mappings tgt-name)
		       (mappings (module-instance pat-name)))))
       (or (null (target pat-name))
	   (tc-eq (target tgt-name) (target pat-name))
	   (and (resolution pat-name)
		(tc-eq (target tgt-name)
		       (target (module-instance pat-name)))))))
