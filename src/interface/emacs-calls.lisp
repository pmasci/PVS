;
; emacs-calls.lisp: dave_sc, 12/19/98
;
; A dummy file that gives information to Allegro's xref so that
; you can use "who-calls" to get information on which emacs files
; call functions in the PVS lisp image.
;

#-runtime
(defun pvs-browser-el ()
  (show-declaration nil nil nil)
  (goto-declaration nil nil nil)
  (find-declaration nil)
  (whereis-declaration-used nil nil nil)
  (whereis-identifer-used nil)
  (list-declarations nil)
  (usedby-proofs nil nil nil))

#-runtime
(defun pvs-cmds-el ()
  (parse-file nil nil)
  (typecheck-file nil nil nil nil)
  (prettyprint-region nil nil nil)
  (prettyprint-theory nil nil)
  (prettyprint-pvs-file nil)
  (prettyprint-expanded nil)
  (show-tccs nil)
  (show-theory-warnings nil)
  (show-pvs-file-warnings nil)
  (show-theory-messages nil)
  (show-pvs-file-messages nil)
  (delete-pvs-file nil nil)
  (delete-theory nil)
  (get-patch-version)
  (change-context nil)
  (change-context nil)
  (save-context)
  (load-prelude-library nil)
  (remove-prelude-library nil)
  (prelude-libraries)
  (exit-pvs)
  (let ((foo *pvs-version*)) nil)
  (get-patch-version)
  (when (fboundp 'get-patch-test-version)
    (get-patch-test-version))
  (when (fboundp 'get-patch-exp-version)
    (get-patch-exp-version))
  (lisp-implementation-type)
  (lisp-implementation-version)
  (let ((foo *pvs-version*)) nil)
  (status-theory nil)
  (status-pvs-file nil)
  (status-importchain nil)
  (status-importbychain nil)
  (proof-status-at nil nil nil)
  (status-proof-theory nil nil)
  (status-proof-pvs-file nil nil)
  (proofchain-status-at nil nil nil)
  (status-proofchain-theory nil)
  (status-proofchain-pvs-file nil)
  (status-proofchain-importchain nil)
  (load-pvs-patches)
  (change-declaration-name nil nil nil)
  (x-module-hierarchy nil)
  (let ((foo *dont-write-object-files*)) nil)
  (typecheck-formula-decl nil nil)
  (prove-formula-decl nil nil nil)  ;; ilisp-send
  (get-prove-formula-proof))

#-runtime
(defun pvs-ilisp-el ()
  (let ((foo *default-char-width*)) nil))

#-runtime
(defun pvs-file-list-el ()
  (context-files-and-theories nil)
  (library-files)
  (current-libraries))

#-runtime
(defun pvs-load-el ()
  (in-package "PVS")
  (let ((foo *pvs-path*)) nil)
  (pvs-init)
  (let ((foo *noninteractive*)
	(bar *pvs-varbose*)) nil))
		 
#-runtime
(defun pvs-print-el ()
  (context-usingchain nil)
  (context-usingchain nil)
  (when *last-proof*
    (label *last-proof*))
  (alltt-proof nil nil)
  (latex-theory nil nil)
  (latex-pvs-file nil)
  (latex-usingchain nil nil)
  (latex-theory-view nil nil nil)
  (when *last-proof*
    (label *last-proof*))
  (latex-proof-view nil nil nil)
  (when *last-proof*
    (label *last-proof*))
  (latex-proof nil nil)
  (let ((foo *latex-linelength*)) nil))

#-runtime
(defun pvs-prover-el ()
  (typecheck-file nil nil nil nil nil)
  (typechecked? nil)
  (typecheck-file nil nil nil nil nil)
  (typechecked? nil)
  (rerun-proof-at? nil nil nil nil)
  (prove-file-at nil nil nil nil nil nil nil nil) ;; ilisp-send
  (prove-theory nil nil nil)
  (prove-pvs-file nil nil)
  (prove-usingchain nil nil)
  (prove-proofchain nil nil nil nil)
  (typecheck-file nil nil nil nil nil)
  (typechecked? nil)
  (let ((foo *in-checker*)) nil)
  (edit-proof-at nil nil nil nil nil nil)
  (prove-file-at nil nil nil nil nil nil nil nil) ;; ilisp-send
  (let ((foo *in-checker*)) nil)
  (remove-proof-at nil nil nil)
  (revert-proof-at nil nil nil)
  (install-pvs-proof-file nil)
  (show-proof-file nil nil)
  (show-orphaned-proofs)
  (show-proofs-importchain nil)
  (show-proofs-pvs-file nil)
  (show-proofs-theory nil)
  (pvs-select-proof nil)
  (pvs-view-proof nil)
  (pvs-delete-proof nil)
  (add-declaration-at nil nil)
  (typecheck-add-declaration nil nil)
  (reset-parsed-at nil)
  (modify-declaration-at nil nil)
  (typecheck-mod-declaration nil nil)
  (reset-parsed-date nil)
  (help-prover)
  (show-last-proof nil)
  (read-strategies-files)
  (let ((foo *rewrite-print-depth*)
	(bar *rewrite-print-length*)
	(taz *prover-print-depth*)
	(baz *prover-print-length*)) nil)
  (typecheck-file nil nil nil nil nil)
  (typechecked? nil)
  (prove-next-unproved-formula nil nil nil nil nil nil)  ;; ilisp-send
  (edit-proof-at nil nil nil nil nil nil)  
  (call-ancestry)
  (call-siblings)
  (call-show-proof)
  (call-x-show-proof)
  (call-x-show-proof-at nil nil nil)
  (call-show-hidden)
  (show-auto-rewrites)
  (show-expanded-sequent nil)
  (show-skolem-constants)
  (call-explain-tcc)
  (help-prover nil)
  (show-strategy nil)
  (collect-strategy-names)
  (x-prover-commands)
  (toggle-proof-prettyprinting)
  (prove-usingchain nil nil nil)
  (prove-pvs-theories nil nil)
  (typecheck-file nil nil nil nil nil)
  (typechecked? nil)
  (let ((foo *dump-sequents-to-file*)) nil)
  (display-proofs-formula-at nil nil nil) 
  (display-proofs-theory nil)
  (display-proofs-pvs-file nil)
  (set-proofs-default nil)
  (proofs-rename nil nil)
  (proofs-show-proof nil)
  (proofs-change-description nil nil)
  (proofs-rerun-proof nil) ;; ilisp-send
  (proofs-delete-proof nil)
  (proofs-edit-proof nil)
  (prove-with-checkpoint nil) ;; ilisp-send
  (install-proof nil nil nil nil nil nil)  
  (let ((foo *number-of-proof-backups* nil)) nil)
  (prove-proof-at nil nil nil)  ;; ilisp-send
  (prove-file-at nil nil nil nil nil nil nil nil) ;; ilisp-send
  (let ((foo *number-of-proof-backups* nil)) nil))

#-runtime
(defun pvs-utils-el ()
  (file-and-place (get-theory nil))
  (parsed? (get-theory nil))
  (all-theories-parsed? (get-theory nil))  
  (typechecked? (get-theory nil))
  (library-file? nil)
  (library-files)
  (library-theories)
  (pvs-current-directory)
  (pvs-current-directory)
  (collect-theories)
  (collect-file-usings nil)
  (get-pvs-file-dependedcies nil)
  (get-using-chain nil)
  (let ((foo *pvs-verbose*)) nil)
  (pvs-emacs-eval "(setq pvs-waiting nil)")
  (list-lisp-entities-of-file nil nil)
  (print-duplicate-lisp-entities nil nil nil))