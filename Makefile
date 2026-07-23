# The install logic lives in ./install.sh — readable zsh, split into
# install/*.sh steps (each step is its own file; install.sh is the table of
# contents). `make` just runs it, so CI and muscle memory keep working.
.PHONY: install
install:
	@./install.sh
