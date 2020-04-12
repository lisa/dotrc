# dotrc

Just some dot files for myself. Nothing to see.

# Installing updates

```shell
# update local working copy
echo "decryption password" > decrypt_pw
make
make clean-plain
```

Afterwards, validate contents on disk and, if desired, remove the `.old` backup copies.

# Adding or Updating

## Plain text

Add a file prefixed with `.` in the root directory. If it needs a directory hierarchy, add it (See [Directory Hierarchy](#directory-hierarchy)).

Once added, in [Makefile](./Makefile), add it to the `__DOTFILES` list. If a new directory is to be added, add it to the `__DIRS` list in the same [Makefile](./Makefile).

## Encrypted Addition

To create content that is to be encrypted, create the file as normal, in the relative directory structure required, and ensure it has a `.plain` file suffix. The `make encrypt-all` target will encrypt it. See [Directory Hierarchy](#directory-hierarchy).

Similar to [Plain Text](#plain-text) directories, secure one can be added to the same `__DIRS` list in the [Makefile](./Makefile).

```shell
echo "decryption password" > decrypt_pw
# Create file(s) with a .plain suffix
make encrypt-all
make check-files
make clean-plain
# done
```

Edit or create the appropriate `.plain` files. If there are additions, add them in [Makefile](./Makefile) in either the `ENCRYPTED_FILES_OPENREAD` or `ENCRYPTED_FILES_PRIVATE` variables with their relative path.

## Encrypted Change

Similar to [Encrypted Addition](#encrypted-addition), except only a single file will be decrypted. In this example, a change will be made to `.ssh/config`

```shell
echo "decryption password" > decrypt_pw
make .ssh/config.plain
# Edit .ssh/config.plain
make .ssh/config.vault
make check-files
make clean-plain
# done
```

# Directory Hierarchy

Files and directories are created on the target system with the relative path based on this repository. For example, a file intending to be installed to `$HOME` will be in [.](/.), or the root of the repository. Some file going to `$HOME/.vim/plugin` would be in the `.vim/plugin` directory of this repository.

Encrypted files follow a similar pattern. That is, if a file should be created as `$HOME/.config/asciinema/instance-id`, add the file in the [.config/asciinema](./.config/asciinema/) directory hierarchy in this repository as [instance-id](./.config/asciinema/install-id.plain) and the `make encrypt-all` target will encrypt it.

# Rekeying

```shell
echo "decryption password" > decrypt_pw
make decrypt-all
echo "new decryption password" > decrypt_pw
make encrypt-all
make check-files
make clean-plain
# done
```

# Limitations

* This contraption does handle not removing the file when removed from this git repository on the next `make` deployment.
* Files outside of `$HOME` are not supported.

# TODO

* Randomize filenames of encrypted files
* Reintroduce find as a way to find candidate dotfiles to save having to manually maintain `__DOTFILES` in the [Makefile](./Makefile)
