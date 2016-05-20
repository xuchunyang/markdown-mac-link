;;; markdown-mac-link.el --- Insert Markdown links to items selected in various Mac apps  -*- lexical-binding: t; -*-

;; Copyright (c) 2010-2016 Free Software Foundation, Inc.
;; Copyright (C) 2016  Chunyang Xu

;; The code is heavily inspired by org-mac-link.el

;; Authors of org-mac-link.el:
;;      Anthony Lander <anthony.lander@gmail.com>
;;      John Wiegley <johnw@gnu.org>
;;      Christopher Suckling <suckling at gmail dot com>
;;      Daniil Frumin <difrumin@gmail.com>
;;      Alan Schmitt <alan.schmitt@polytechnique.org>
;;      Mike McLean <mike.mclean@pobox.com>

;; Author: Chunyang Xu <xuchunyang.me@gmail.com>
;; URL: https://github.com/xuchunyang/markdown-mac-link
;; Version: 0.1
;; Package-Requires: ((emacs "24"))
;; Keywords: Markdown, mac, hyperlink
;; Created: <2016-05-20 Fri>

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; `markdown-mac-link.el' is inspired by `org-mac-link.el'
;;
;; The following applications are supportted:
;;
;; Google Chrome.app - Grab the url of the frontmost tab in the frontmost window
;; Safari.app - Grab the url of the frontmost tab in the frontmost window
;; Finder.app - Grab links to the latest selected file in the frontmost window
;;
;; To use, type M-x markdown-mac-link-grab, it will prompt for an
;; application to grab a link from.
;;
;; Besides, you can also use these commands directly:
;; - `markdown-mac-link-chrome-insert-frontmost-url'
;; - `markdown-mac-link-safari-insert-frontmost-url'
;; - `markdown-mac-link-finder-insert-selected'

;;; Code:

(defun markdown-mac-link-split-applescript-link (as-link)
  (let* ((split-link (split-string as-link "::split::"))
         (URL (car split-link))
         (description (cadr split-link)))
    (cons URL description)))

(defun markdown-mac-link-make-link-string (URL description)
  (format "[%s](%s)" description URL))

(defun markdown-mac-link-get-link-string (as-link)
  (let* ((url-and-description (markdown-mac-link-split-applescript-link as-link))
         (URL (car url-and-description))
         (description (cdr url-and-description)))
    (markdown-mac-link-make-link-string URL description)))

(defun markdown-mac-link-paste-applescript-link (as-link)
  (let ((markdown-link (markdown-mac-link-get-link-string as-link)))
    (kill-new markdown-link)
    markdown-link))


;; Google Chrome

(defun markdown-mac-link-as-get-frontmost-url-chrome ()
  (let ((result
         (do-applescript
          (concat
           "set frontmostApplication to path to frontmost application\n"
           "tell application \"Google Chrome\"\n"
           "	set theUrl to get URL of active tab of first window\n"
           "	set theResult to (get theUrl) & \"::split::\" & (get name of window 1)\n"
           "end tell\n"
           "activate application (frontmostApplication as text)\n"
           "set links to {}\n"
           "copy theResult to the end of links\n"
           "return links as string\n"))))
    (replace-regexp-in-string
     "^\"\\|\"$" "" (car (split-string result "[\r\n]+" t)))))

(defun markdown-mac-link-chrome-get-frontmost-url ()
  (interactive)
  (message "Applescript: Getting Chrome url...")
  (markdown-mac-link-paste-applescript-link
   (markdown-mac-link-as-get-frontmost-url-chrome)))

;;;###autoload
(defun markdown-mac-link-chrome-insert-frontmost-url ()
  (interactive)
  (message "Applescript: Getting Chrome url...")
  (insert (markdown-mac-link-chrome-get-frontmost-url)))


;; Safari

(defun markdown-mac-link-as-get-frontmost-url-safari ()
  (do-applescript
   (concat
    "tell application \"Safari\"\n"
    "	set theUrl to URL of document 1\n"
    "	set theName to the name of the document 1\n"
    "	return theUrl & \"::split::\" & theName\n"
    "end tell\n")))

(defun markdown-mac-link-safari-get-frontmost-url ()
  (interactive)
  (message "Applescript: Getting Safari url...")
  (markdown-mac-link-paste-applescript-link
   (markdown-mac-link-as-get-frontmost-url-safari)))

;;;###autoload
(defun markdown-mac-link-safari-insert-frontmost-url ()
  (interactive)
  (insert (markdown-mac-link-safari-get-frontmost-url)))


;; Finder

(defun markdown-mac-link-as-get-frontmost-url-finder ()
  (do-applescript
   (concat
    "tell application \"Finder\"\n"
    " set theSelection to the selection\n"
    " set links to {}\n"
    " repeat with theItem in theSelection\n"
    " set theLink to \"file://\" & (POSIX path of (theItem as string)) & \"::split::\" & (get the name of theItem)\n"
    " copy theLink to the end of links\n"
    " end repeat\n"
    " return links as string\n"
    "end tell\n")))

(defun markdown-mac-link-finder-item-get-selected ()
  (interactive)
  (message "Applescript: Getting Finder items...")
  (markdown-mac-link-paste-applescript-link
   (markdown-mac-link-as-get-frontmost-url-finder)))

;;;###autoload
(defun markdown-mac-link-finder-insert-selected ()
  (interactive)
  (insert (markdown-mac-link-finder-item-get-selected)))


;; Entry point

;;;###autoload
(defun markdown-mac-link-grab ()
  "Prompt for an application to grab a link from.
When done, go grab the link, and insert it at point."
  (interactive)
  (let ((descriptors
         '((?c . markdown-mac-link-chrome-insert-frontmost-url)
           (?s . markdown-mac-link-safari-insert-frontmost-url)
           (?f . markdown-mac-link-finder-insert-selected)))
        (menu-string "[c]hrome [s]afari [f]inder:" )
        input)

    (message menu-string)
    (setq input (read-char-exclusive))

    (let ((grab-function (cdr (assq input descriptors))))
      (when grab-function
        (call-interactively grab-function)))))

(provide 'markdown-mac-link)
;;; markdown-mac-link.el ends here
