# printboard dev tasks — run `just` to list them.

# Local homebrew-tap checkout (the real `brew install` source). Defaults to the
# sibling ../homebrew-tap; override with the PRINTBOARD_TAP env var.
tap := env_var_or_default("PRINTBOARD_TAP", justfile_directory() / ".." / "homebrew-tap")

_default:
    @just --list

# Commit AND push the code change first — release.sh only writes the formulas,
# never the script. Add `--gh-release` to also create a GitHub Release for the tag.

# Release e.g. `just publish 1.5.0`: tag the pushed commit, hash the tarball, bump both formulas.
publish version *flags:
    PRINTBOARD_TAP="{{tap}}" ./release.sh {{version}} {{flags}}
