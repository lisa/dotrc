# Decrypt something with $(IMG)
# $1 is the source
# $2 is the destination
# All relative to inside the container, and should be prefixed with /dotfiles
define decrypt
	$(DOCKER) run --rm -i -v $(__PWD):/dotfiles $(IMG) decrypt --vault-password-file /dotfiles/decrypt_pw --output /dotfiles/$(2) /dotfiles/$(1)
endef

define encrypt
	$(DOCKER) run --rm -i -v $(__PWD):/dotfiles $(IMG) encrypt --vault-password-file /dotfiles/decrypt_pw --output /dotfiles/$(2) /dotfiles/$(1)
endef