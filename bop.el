;;; bop.el --- Quickly use Emacs bookmarks in Eshell -*- lexical-binding: t; -*-

;;; Commentary:
;; List bookmarks with `bop', or jump with `bop NUMBER' or `bop NAME'.
;; BOP_BOOKMARK_PATH defaults to `bookmark-default-file'.
;; BOP_USE_FZF defaults to 1; set it to 0 for literal substring searches.

;;; Code:

(require 'bookmark)
(require 'dash)
(require 'em-dirs)

(defun bop--entries (bookmarks)
  "Return name/path pairs for file BOOKMARKS, preserving their order."
  (-keep (lambda (bookmark)
           (let ((filename (cdr (assq 'filename (cdr bookmark)))))
             (when (and (stringp filename) (not (equal filename "")))
               (cons (car bookmark) filename))))
         bookmarks))

(defun bop--style (text face styled)
  "Return TEXT with FACE when STYLED is non-nil."
  (if styled (propertize text 'face face) text))

(defun bop--format-entries (entries &optional styled)
  "Return ENTRIES as an aligned listing, with faces when STYLED is non-nil."
  (let ((name-width (-reduce-from #'max 0 (-map (lambda (entry)
                                                (string-width (car entry)))
                                              entries)))
        (number-format (format "%%%dd" (max 2 (length (number-to-string
                                                     (length entries)))))))
    (mapconcat
     #'identity
     (-map-indexed
      (lambda (index entry)
        (concat
         (bop--style (format number-format (1+ index))
                     '(bold font-lock-constant-face) styled)
         "  "
         (bop--style (car entry) 'font-lock-function-name-face styled)
         (make-string (- name-width (string-width (car entry))) ?\s)
         "  "
         (bop--style (concat "→  " (cdr entry)) 'shadow styled)
         "\n"))
      entries)
     "")))

(defun bop--find-entry (query entries)
  "Find QUERY in ENTRIES by one-based number or literal name substring."
  (if (integerp query)
      (when (and (>= query 1) (<= query (length entries)))
        (nth (1- query) entries))
    (let ((case-fold-search t)
          (pattern (regexp-quote query)))
      (-first (lambda (entry) (string-match-p pattern (car entry))) entries))))

(defun bop--read-bookmarks (file)
  "Read FILE without changing Emacs's bookmark state."
  (unless (file-readable-p file)
    (user-error "bop: cannot read bookmarks: %s" file))
  (with-temp-buffer
    (insert-file-contents file)
    (bookmark-alist-from-buffer)))

(defun bop--fzf (query entries)
  "Return the first fzf match for QUERY in ENTRIES."
  (unless (executable-find "fzf")
    (user-error "bop: fzf not found; install it or set BOP_USE_FZF to 0"))
  (with-temp-buffer
    (dolist (entry entries)
      (insert (car entry) "\t" (cdr entry) "\n"))
    (let ((status (call-process-region
                   (point-min) (point-max) "fzf" t t nil
                   (concat "--filter=" query) "--delimiter=\t" "--nth=1")))
      (cond
       ((equal status 1) nil)
       ((not (equal status 0)) (user-error "bop: fzf failed: %s" status))
       (t (assoc (car (split-string (buffer-string) "\t")) entries))))))

(defun eshell/bop (&rest args)
  "List Emacs bookmarks, or navigate by number or name in ARGS.
Read BOP_BOOKMARK_PATH, falling back to `bookmark-default-file'.
Use fzf unless the environment variable BOP_USE_FZF is set to 0."
  (let* ((file (expand-file-name
                (or (getenv "BOP_BOOKMARK_PATH") bookmark-default-file)))
         (use-fzf (or (getenv "BOP_USE_FZF") "1"))
         (query (car args)))
    (unless (member use-fzf '("0" "1"))
      (user-error "bop: BOP_USE_FZF must be 0 or 1"))
    (let ((entries (bop--entries (bop--read-bookmarks file))))
      (if (or (null query) (member query '("-h" "--help")))
          (bop--format-entries entries (not (getenv "NO_COLOR")))
        (let ((entry
                (cond
                 ((string-match-p "\\`[0-9]+\\'" query)
                  (bop--find-entry (string-to-number query) entries))
                 ((equal use-fzf "1") (bop--fzf query entries))
                 (t (bop--find-entry query entries)))))
          (unless entry
            (user-error "bop: bookmark not found: %s" query))
          (let ((target (expand-file-name (cdr entry))))
            (eshell/cd (if (file-regular-p target)
                           (file-name-directory target)
                         target))))))))

(put 'eshell/bop 'eshell-no-numeric-conversions t)

(provide 'bop)
;;; bop.el ends here
