SHELL := /bin/bash
include verbose.mk
include functions.mk

DOCKER ?= $(shell which docker)
INSTALL ?= /usr/bin/install
IMG := thedoh/dotfiles-decrypter:latest
__PWD := $(dir $(realpath $(firstword $(MAKEFILE_LIST))))

### Dotfiles (even if they're not .files) and Directories to create
__DOTFILES := .bash_profile.d/.gitkeep .vimrc .bash_profile
__DIRS := $(HOME)/.bash_profile.d $(HOME)/.config

# Plain text version of secure.mk.vault
SECURE_MK := $(join $(__PWD),secure.mk.plain)
# Encrypted version
SECURE_MK_VAULT := $(join $(__PWD),$(shell basename $(SECURE_MK) |sed -e 's,\.plain$$,\.vault,'))

# transform the relative path from the git repo to where it goes in $HOME
DOTFILES := $(foreach dotfile,$(__DOTFILES),$(join $(HOME),$(dotfile)))
SECURE_PW_FILE ?= $(join $(__PWD),decrypt_pw)

all: dirs $(DOTFILES) $(SECURE_MK) run_secure

ifeq (,$(wildcard $(SECURE_PW_FILE)))
	$(error Must populate $(SECURE_PW_FILE) with a decryption passphrase)
endif

## Make directories with mode 0700
dirs: $(__DIRS)
$(__DIRS):
	$(AT)$(INSTALL) -m 0700 -o $(shell id -u $(USER)) -g $(shell id -g $(USER)) $@

# Do the actual install of our .dotfiles
$(DOTFILES): dirs $(__DOTFILES)
	$(AT)srcfile=$$(echo $@ | sed -e 's,$(HOME)\/,,') ;\
	$(INSTALL) -d $(shell dirname $@) ;\
	$(INSTALL) -b -m 644 -o $(shell id -u $(USER)) -g $(shell id -g $(USER)) $$srcfile $@

# Decrypt secure.mk.plain from secure.mk.vault
$(SECURE_MK):
	$(AT)$(call decrypt,$(shell basename $@ | sed -e 's,\.plain$$,\.vault,'),$(shell basename $@))

# Run the secure.mk content
.PHONY: run_secure
run_secure: $(SECURE_MK)
	$(AT)$(MAKE) -C $(__PWD) -f $(SECURE_MK) all

# Helper targets to save having to use /full/path/to/target
secure.mk.plain: $(SECURE_MK)
secure.mk.vault: $(SECURE_MK)
	$(AT)$(call encrypt,$(shell basename $@ | sed -e 's,\.vault$$,\.plain,'),$(shell basename $@))

# Helper to encrypt everything (except secure.mk) via secure.mk
.PHONY: encrypt-all
encrypt-all: $(SECURE_MK)
	$(AT)$(MAKE) -C $(__PWD) -f $(SECURE_MK) encrypt-all

.PHONY: decrypt-all
decrypt-all: $(SECURE_MK)
	$(AT)$(MAKE) -C $(__PWD) -f $(SECURE_MK) decrypt-all

# The `clean-plain` target in $(SECURE_MK) does not delete $(SECURE_MK), so we
# ought to do it here in this handy wrapper, but only if $(SECURE_MK_VAULT) exists and is newer than $(SECURE_MK)
.PHONY: clean-plain
clean-plain: $(SECURE_MK)
	$(AT)$(MAKE) -C $(__PWD) -f $(SECURE_MK) clean-plain
	$(AT)if [[ -f $(SECURE_MK_VAULT) && $(SECURE_MK_VAULT) -nt $(SECURE_MK) ]]; then \
		\rm -f $(SECURE_MK) $(SECURE_PW_FILE);\
	else \
		if [[ ! -f $(SECURE_MK_VAULT) ]]; then \
			echo "[clean-plain] Not cleaning $(shell basename $(SECURE_PW_FILE)) or $(shell basename $(SECURE_MK)) because $(shell basename $(SECURE_MK_VAULT)) doesn't exist. Run make secure.mk.vault first" ;\
		fi ;\
		if [[ -f $(SECURE_MK_VAULT) && $(SECURE_MK_VAULT) -ot $(SECURE_MK) ]]; then \
			echo "[clean-plain] Not cleaning $(shell basename $(SECURE_PW_FILE)) or $(shell basename $(SECURE_MK)) because it is newer than $(shell basename $(SECURE_MK_VAULT)). Run make secure.mk.vault first" ;\
		fi ;\
	fi
