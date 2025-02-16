					; DEBUGGING HTML;; You will most likely need to adjust this font size for your system!
(defvar runemacs/default-font-size 180)

;; Setting default path for custom code to go to from emacs.
;; Any Customize-based settings should live in custom.el, not here.
(setq custom-file "~/.emacs.d/custom.el") ;; Without this emacs will dump generated custom settings in this file. No bueno.
(load custom-file 'noerror)

(setq inhibit-startup-message t)

(scroll-bar-mode -1)        ; Disable visible scrollbar
(tool-bar-mode -1)          ; Disable the toolbar
(tooltip-mode -1)           ; Disable tooltips
(set-fringe-mode 10)        ; Give some breathing room

(menu-bar-mode -1)            ; Disable the menu bar

;; Make ESC quit prompts
(global-set-key (kbd "<escape>") 'keyboard-escape-quit)

;; Initialize package sources
(require 'package)

(setq package-archives '(("melpa" . "https://melpa.org/packages/")
			 ("org" . "https://orgmode.org/elpa/")
			 ("elpa" . "https://elpa.gnu.org/packages/")))

(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))

;; Initialize use-package on non-Linux platforms
(unless (package-installed-p 'use-package)
  (package-install 'use-package))

(require 'use-package)
(setq use-package-always-ensure t)

(column-number-mode)
(global-display-line-numbers-mode t)

;; Disable line numbers for some modes
(dolist (mode '(org-mode-hook
		term-mode-hook
		shell-mode-hook
		eshell-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))

(use-package command-log-mode)

(use-package ivy
  :diminish
  :bind (("C-s" . swiper)
	 :map ivy-minibuffer-map
	 ("TAB" . ivy-alt-done)
	 ("C-l" . ivy-alt-done)
	 ("C-j" . ivy-next-line)
	 ("C-k" . ivy-previous-line)
	 :map ivy-switch-buffer-map
	 ("C-k" . ivy-previous-line)
	 ("C-l" . ivy-done)
	 ("C-d" . ivy-switch-buffer-kill)
	 :map ivy-reverse-i-search-map
	 ("C-k" . ivy-previous-line)
	 ("C-d" . ivy-reverse-i-search-kill))
  :config
  (ivy-mode 1))

;; NOTE: The first time you load your configuration on a new machine, you'll
;; need to run the following command interactively so that mode line icons
;; display correctly:
;;
;; M-x all-the-icons-install-fonts

(use-package all-the-icons)

(use-package doom-modeline
  :init (doom-modeline-mode 1)
  :custom ((doom-modeline-height 15)))

(use-package doom-themes
  :init (load-theme 'doom-zenburn t))

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package ivy-rich)
(ivy-rich-mode 1)

(require 'which-key)
(which-key-mode)
(which-key-setup-side-window-right)

(use-package counsel
  :bind (("M-x" . counsel-M-x)
	 ("C-x b" . counsel-ibuffer)
	 ("C-x C-f" . counsel-find-file)
	 :map minibuffer-local-map
	 ("C-r" . 'counsel-minibuffer-history)))

(use-package helpful
  :custom
  (counsel-describe-function-function #'helpful-callable)
  (counsel-describe-variable-function #'helpful-variable)
  :bind
  ([remap describe-function] . counsel-describe-function)
  ([remap describe-command] . helpful-command)
  ([remap describe-variable] . counsel-describe-variable)
  ([remap describe-key] . helpful-key))

(use-package general
  :config
  (general-create-definer rune/leader-keys
			  :keymaps '(normal insert visual emacs)
			  :prefix "SPC"
			  :global-prefix "C-SPC")

  (rune/leader-keys
   "t"  '(:ignore t :which-key "toggles")
   "tt" '(counsel-load-theme :which-key "choose theme")))

(use-package hydra)

(defhydra hydra-text-scale (:timeout 4)
	  "scale text"
	  ("j" text-scale-increase "in")
	  ("k" text-scale-decrease "out")
	  ("f" nil "finished" :exit t))

(rune/leader-keys
 "ts" '(hydra-text-scale/body :which-key "scale text"))

(use-package projectile
  :diminish projectile-mode
  :config (projectile-mode)
  :custom ((projectile-completion-system 'ivy))
  :bind-keymap
  ("C-c p" . projectile-command-map)
  :init
  ;; NOTE: Set this to the folder where you keep your Git repos!
  (when (file-directory-p "~/projects/")
    (setq projectile-project-search-path '("~/projects/")))
  (setq projectile-switch-project-action #'projectile-dired))

(use-package counsel-projectile
  :config (counsel-projectile-mode))

(use-package magit
  :custom
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1))

;; NOTE: Make sure to configure a GitHub token before using this package!
;; - https://magit.vc/manual/forge/Token-Creation.html#Token-Creation
;; - https://magit.vc/manual/ghub/Getting-Started.html#Getting-Started
;;(use-package forge)

;; LSP Mode Support for Programming Languages

;; ----------------------
;; LSP MODE FOR CLOJURE
;; ----------------------
(use-package clojure-mode
  :ensure t
  :mode ("\\.clj\\'" "\\.cljs\\'" "\\.cljc\\'")
  :hook (clojure-mode . lsp-deferred))

(use-package cider
  :ensure t
  :hook (clojure-mode . cider-mode)
  :custom
  (cider-repl-history-file "~/.emacs.d/cider-history")
  (cider-repl-wrap-history t)
  (cider-auto-select-error-buffer t)
  (cider-show-error-buffer t)
  (cider-repl-pop-to-buffer-on-connect t)
  :bind (("C-c C-j" . cider-jack-in)
         ("C-c C-k" . cider-load-buffer)
         ("C-c C-n" . cider-repl-set-ns)))

(use-package paredit
  :hook ((clojure-mode . paredit-mode)
         (cider-repl-mode . paredit-mode))
  :config
  (define-key paredit-mode-map (kbd "RET") 'paredit-newline))

(defhydra hydra-cider (:color blue :hint nil)
	  "
CIDER Commands
--------------------------------------
[_j_] Jack-in    [_q_] Quit REPL
[_k_] Load File  [_n_] Set Namespace
[_b_] Eval Buffer
"
	  ("j" cider-jack-in)
	  ("q" cider-quit)
	  ("k" cider-load-buffer)
	  ("n" cider-repl-set-ns)
	  ("b" cider-eval-buffer))

(global-set-key (kbd "C-c h") 'hydra-cider/body)

;; Make sure clojure-lsp is installed and on your PATH:
;;   brew install clojure-lsp/brew/clojure-lsp
;; or download from https://github.com/clojure-lsp/clojure-lsp/releases

;; ----------------------
;; LSP MODE FOR PYTHON
;; ----------------------
(use-package lsp-pyright
  :ensure t
  :hook (python-mode . (lambda ()
			 (require 'lsp-pyright)
			 (lsp-deferred))))

;; using ipython in python-mode
(setq python-shell-interpreter "ipython"
      python-shell-interpreter-args "-i --simple-prompt")

;; If you prefer Microsoft Python Language Server instead:
;; (use-package lsp-python-ms
;;   :ensure t
;;   :hook (python-mode . (lambda ()
;;                          (require 'lsp-python-ms)
;;                          (lsp-deferred))))

;; ----------------------
;; SHARED LSP SETTINGS
;; ----------------------
(use-package lsp-mode
  :commands (lsp lsp-deferred)
  :init
  ;; set prefix for lsp-command-keymap
  (setq lsp-keymap-prefix "C-c l")
  :hook
  ;; add any other major modes you want to start LSP for
  ((lsp-mode . lsp-enable-which-key-integration))
  :config
  ;; Optional: tweak lsp-mode diagnostics, session folder, etc.
  (setq lsp-prefer-flymake nil)  ; Use lsp-ui and/or flycheck instead of flymake
  )

;; lsp-ui, lsp-ivy, lsp-treemacs, etc. can remain as is in your config:
(use-package lsp-ui :commands lsp-ui-mode)
(use-package lsp-ivy :commands lsp-ivy-workspace-symbol)
(use-package lsp-treemacs :commands lsp-treemacs-errors-list)

;; Considering using Evil Mode
