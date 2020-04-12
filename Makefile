SHELL := /bin/bash
include verbose.mk
include functions.mk

DOCKER ?= $(shell which docker)
INSTALL ?= /usr/bin/install
IMG := thedoh/dotfiles-decrypter:latest
__PWD := $(dir $(realpath $(firstword $(MAKEFILE_LIST))))
# Note: This can be overridden with:
# make ARCH=linux <some target>
# eg to add a file that references $(ARCH) where ARCH=s390x:
# make ARCH=s390x some.file.s390x.vault
# Turns some.file.s390x.plain to some.file.s390x.vault
ARCH ?= $(shell uname -s | tr A-Z a-z)

### Dotfiles (even if they're not .files) and Directories to create. Encrypted
# files are treated differently. See below
__DOTFILES := .bash_profile.d/.gitkeep .vimrc .bash_profile .gitconfig .gitignore_global
__DIRS := $(join $(HOME)/,.bash_profile.d) $(join $(HOME)/,.config) \
	$(HOME)/.ssh $(HOME)/.docker $(HOME)/.gnupg

# transform the relative path from the git repo to where it goes in $HOME
DOTFILES := $(foreach dotfile,$(__DOTFILES),$(join $(HOME)/,$(dotfile)))
SECURE_PW_FILE ?= $(join $(__PWD),decrypt_pw)

## Encrypted files section

# All of these ENCRYPTED_FILES_*, by default, will have .vault appended.
# They will be decrypted to .plain so they can be moved into place
# where they will be stripped of the .plain (and .vault) suffix

# These files will have permission 0644
ENCRYPTED_FILES_OPENREAD := .ssh/config .ssh/redhat .ssh/personal .ssh/authorized_keys \
	.ssh/lisa.pub .ssh/lseelye_github.pub .config/asciinema/install-id

# These files will have permission 0600
ENCRYPTED_FILES_PRIVATE := .ssh/lseelye_github .ssh/lseelye .ssh/lisa \
	.docker/config.json.$(ARCH) .bash_profile.d/secure_start.sh \
	.bash_profile.d/secure_end.sh

__ENCRYPTED_FILES_OPENREAD_SRC := $(foreach f,$(ENCRYPTED_FILES_OPENREAD),$(f).vault)
__ENCRYPTED_FILES_PRIVATE_SRC := $(foreach f,$(ENCRYPTED_FILES_PRIVATE),$(f).vault)

__ENCRYPTED_FILES_OPENREAD_PLAIN_SRC := $(foreach f,$(ENCRYPTED_FILES_OPENREAD),$(f).plain)
__ENCRYPTED_FILES_PRIVATE_PLAIN_SRC := $(foreach f,$(ENCRYPTED_FILES_PRIVATE),$(f).plain)

__ENCRYPTED_FILES_OPENREAD_DEST := $(foreach f,$(ENCRYPTED_FILES_OPENREAD),$(HOME)/$(f))
__ENCRYPTED_FILES_PRIVATE_DEST := $(foreach f,$(ENCRYPTED_FILES_PRIVATE),$(HOME)/$(f)) 

# All of the encrypted files no matter what their destination permissions
__ENCRYPTED_FILES_SRC := $(__ENCRYPTED_FILES_OPENREAD_SRC) $(__ENCRYPTED_FILES_PRIVATE_SRC)
# All of the plain-text versions no matter destination permissions
__DECRYPTED_FILES := $(__ENCRYPTED_FILES_OPENREAD_PLAIN_SRC) $(__ENCRYPTED_FILES_PRIVATE_PLAIN_SRC)

## End encrypted files section

all: dirs $(DOTFILES) decrypt-all install-openread install-private

ifeq (,$(wildcard $(SECURE_PW_FILE)))
	$(error Must populate $(SECURE_PW_FILE) with a decryption passphrase)
endif

## Make directories with mode 0700
dirs: $(__DIRS)
$(__DIRS):
	$(AT)$(INSTALL) -d -m 0700 -o $(shell id -u $(USER)) -g $(shell id -g $(USER)) $@

# Do the actual install of our .dotfiles
$(DOTFILES): dirs $(__DOTFILES)
	$(AT)srcfile=$$(echo $@ | sed -e 's,$(HOME)\/,,') ;\
	$(INSTALL) -d $(shell dirname $@) ;\
	$(INSTALL) -b -m 644 -o $(shell id -u $(USER)) -g $(shell id -g $(USER)) $$srcfile $@

## Encrypted Stuff
## Install decrypted files to their place on disk
install-openread: $(__ENCRYPTED_FILES_OPENREAD_DEST)
$(__ENCRYPTED_FILES_OPENREAD_DEST): dirs decrypt-all
	$(AT)nopath="$$(echo $@ | sed -e 's,$(HOME)\/,,')" ;\
	$(call decrypt,$$nopath.vault,$$nopath.plain) ;\
	echo "Installing $@ to $$nopath" ;\
	$(INSTALL) -b -m 0644 -o $(shell id -u $(USER)) -g $(shell id -g $(USER)) $${nopath}.plain $@ ;\
	\rm -f $$nopath.plain

.PHONY: install-private
install-private: $(__ENCRYPTED_FILES_PRIVATE_DEST)
$(__ENCRYPTED_FILES_PRIVATE_DEST): dirs decrypt-all
	$(AT)nopath="$$(echo $@ | sed -e 's,$(HOME)\/,,')" ;\
	$(call decrypt,$$nopath.vault,$$nopath.plain) ;\
	echo "Installing $@ to $$nopath" ;\
	$(INSTALL) -b -m 0600 -o $(shell id -u $(USER)) -g $(shell id -g $(USER)) $${nopath}.plain $@ ;\
	\rm -f $$nopath.plain

.PHONY: encrypt-all
encrypt-all: $(__ENCRYPTED_FILES_SRC)
.PHONY: $(__ENCRYPTED_FILES_SRC)
$(__ENCRYPTED_FILES_SRC):
	$(AT)plain=$$(echo $@ | sed -e 's,\.vault$$,\.plain,') ;\
	if [[ -f $$plain ]]; then \
		echo "[Encrypt] $@" ;\
		$(call encrypt,$(shell echo $@ | sed -e 's,\.vault$$,\.plain,'),$@) ;\
	fi

.PHONY: decrypt-all
decrypt-all: $(__DECRYPTED_FILES)
.PHONY: $(__DECRYPTED_FILES)
$(__DECRYPTED_FILES):
	$(AT)echo "[Decrypt] $@"
	$(AT)$(call decrypt,$(shell echo $@ | sed -e 's,\.plain$$,\.vault,'),$@)

.PHONY: clean-plain
clean-plain: check-files
	$(AT)find $(__PWD) -type f -name "*.plain" -delete ;\
	\rm -f $(SECURE_PW_FILE)

# Exit code is the number of files not matched
.PHONY: check-files
check-files:
	$(AT)overall=0 ;\
	for fil in $$(find $(__PWD) -type f -name "*.plain"); do \
		f="$$(echo $${fil} | sed 's,$(__PWD)/,,')" ;\
		fmatch=0 ;\
		for pil in $(__ENCRYPTED_FILES_SRC); do \
			p="$$(echo $${pil} | sed -e 's,\.vault$$,\.plain,')" ;\
			if [[ "$${f}" == "$${p}" ]]; then \
				fmatch=1 ;\
				break ;\
			fi ;\
		done ;\
		if [[ $$fmatch == 0 ]]; then \
			overall=$$(( $$overall + 1 )) ;\
			echo "[check-files] Did not match $${f}. Did you remember to encrypt it?" ;\
		fi ;\
	done ;\
	exit $$overall

## End Encrypted Stuff