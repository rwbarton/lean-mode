(require 'dash)
(require 'dash-functional)

(defun lean-set-parse-string (str)
  "Parse the output of eval command."
  (let ((str-list (split-string str "\n")))
    ;; Drop the first line "-- BEGINSET" and
    ;; the last line "-- ENDSET"
    (setq str-list
          (-take (- (length str-list) 2)
                 (-drop 1 str-list)))
    (string-join str-list "\n")))

(defun lean-set-option ()
  "Set Lean option."
  (interactive)
  (lean-get-options)
  (let* ((key-list (-map 'car lean-global-option-record-alist))
         (option-name
          (completing-read "Option name: "
                           key-list
                           nil t "" nil (car key-list)))
         (option (cdr (assoc option-name lean-global-option-record-alist)))
         (option-value (lean-option-read option)))
    (lean-server-send-cmd (lean-cmd-set option-name option-value) 'message)))

(defun lean-option-read-bool (prompt)
  (interactive)
  (completing-read prompt'(("true" 1) ("false" 2)) nil t "" nil "true"))

(defun lean-option-read-int (prompt)
  (interactive)
  (let* ((str (read-string prompt))
         (val (string-to-int str))
         tmp-str)
    (setq tmp-str (int-to-string val))
    (if (and (integerp val)
             (stringp tmp-str)
             (string= tmp-str str))
        val
        (error "%s is not an int value" str))))

(defun lean-option-read-uint (prompt)
  (interactive)
  (let* ((str (read-string prompt))
         (val (string-to-int str))
         tmp-str)
    (setq tmp-str (int-to-string val))
    (if (and (integerp val)
             (>= val 0)
             (stringp tmp-str)
             (string= tmp-str str))
        val
      (error "%s is not an unsigned int value" str))))

(defun lean-option-read-double (prompt)
  (interactive)
  (let* ((str (read-string prompt))
         (val (string-to-number str))
         tmp-str)
    (setq tmp-str (number-to-string val))
    (if (and (numberp val)
             (>= val 0)
             (stringp tmp-str)
             (string= tmp-str str))
        (string-to-number str)
      (error "%s is not a double value" str))))

(defun lean-option-read-string (prompt)
  (interactive)
  (read-string prompt))

(defun lean-option-read-sexp (prompt)
  (interactive)
  (let* ((str (read-string prompt))
         (sexp (ignore-errors (read str))))
    (if (ignore-errors
          (string= (prin1-to-string sexp) str))
        sexp
      (error "%s is not a well-formed S-Expression"))))

(defun lean-option-type (option)
  (let ((type-str (lean-option-record-type option)))
    (cond ((string= "Bool" type-str)          'Bool)
          ((string= "Int" type-str)           'Int)
          ((string= "Unsigned Int" type-str)  'UInt)
          ((string= "Double" type-str)        'Double)
          ((string= "String" type-str)        'String)
          ((string= "S-Expressions" type-str) 'SEXP)
          (t (error "lean-option-string-to-type: %s is not supported lean-option type."
                    type-str)))))

(defun lean-option-read (option)
  (let* ((option-type-str (lean-option-record-type option))
         (option-name (lean-option-record-name option))
         (option-desc (lean-option-record-desc option))
         (prompt (format "%s [%s] : %s = "
                         option-name
                         option-desc
                         option-type-str)))
    (pcase (lean-option-type option)
      (`Bool   (lean-option-read-bool prompt))
      (`Int    (lean-option-read-int prompt))
      (`UInt   (lean-option-read-uint prompt))
      (`Double (lean-option-read-double prompt))
      (`String (lean-option-read-string prompt))
      (`SEXP   (lean-option-read-sexp prompt)))))

(cl-defstruct lean-option-record name type default-value desc)
(defun lean-option-parse-string (line)
  "Parse a line to lean-option-record"
  (let* ((str-list             (split-string line "|"))
         (option-name          (substring-no-properties (cl-first str-list) 3))
         (option-type          (cl-second str-list))
         (option-default-value (cl-third str-list))
         (option-desc          (cl-fourth str-list)))
    (make-lean-option-record :name option-name
                             :type option-type
                             :default-value option-default-value
                             :desc option-desc)))

(defun lean-options-parse-string (str)
  "Parse lines of option string into an entry of alist of lean-option-records

(NAME . OPTION-RECORD)."
  (let ((str-list (split-string str "\n"))
        str-str-list
        option-list)
    ;; Drop the first line "-- BEGINOPTIONS" and
    ;;      the last line  "-- ENDOPTIONS"
    (setq str-list
          (-take (- (length str-list) 2)
                 (-drop 1 str-list)))
    (-map (lambda (line)
            (let ((option-record (lean-option-parse-string line)))
              `(,(lean-option-record-name option-record) . ,option-record)))
          str-list)))

(defun lean-get-options ()
  "Get Lean option."
  (interactive)
  (unless lean-global-option-record-alist
    (lean-server-send-cmd (lean-cmd-options)
                          '(lambda (option-record-alist)
                             (setq lean-global-option-record-alist
                                   option-record-alist)))))

(provide 'lean-option)
