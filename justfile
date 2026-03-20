#!/usr/bin/env just -f

import? "justfile.mise"

set export

SSHPASS := "nixosusb"

# This help
[group('misc')]
@help:
    [ -f justfile.mise ] || just justise
    just -l -u

# Convert mise tasks to just recipes
[group('misc')]
@justise:
    mise run justise


###############################################################################
# Documentation
###############################################################################
# Update documentation
[group('documentation')]
@doc-update:
    termshot -f docs/commands.png -- just

###############################################################################
# Debug
###############################################################################

# Repl the project
[group('debug')]
@debug-repl:
    nix repl --extra-experimental-features repl-flake .#

# debug Markdown project
[group('debug')]
@serve-markdown:
   godown 

