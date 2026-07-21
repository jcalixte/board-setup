#!/usr/bin/env bash
# release.sh — cut a printboard release and point both Homebrew formulas at it.
#
#   ./release.sh <version>                e.g. ./release.sh 1.4.2
#   ./release.sh <version> --gh-release   also create a GitHub Release for the tag
#
# Assumes the feature commit is already on main and pushed (this is the last real
# code change — release.sh never writes the script, only the formulas). It then
# reproduces exactly what past releases did:
#   1. preflight: on main, clean tree, HEAD == origin/main, tag not taken
#   2. tag that feature commit v<version> and push the tag
#   3. download the GitHub tag tarball and compute its sha256
#   4. bump url+sha256 in the mirror (printboard.rb) -> commit
#      "chore(printboard): sync formula mirror to v<version>" -> push main
#   5. bump url+sha256 in the tap (Formula/printboard.rb) -> commit
#      "printboard <version>" -> push
#
# Prereqs (all present in this env): git over SSH to both repos, curl, and
# shasum/sha256sum. The tap is expected at $PRINTBOARD_TAP (default
# ~/projects/homebrew-tap). gh is only needed for --gh-release; override its path
# with GH=/abs/path/to/gh if it isn't on PATH.
set -euo pipefail

VERSION="${1:?usage: ./release.sh <version> [--gh-release]  (e.g. 1.4.2)}"
VERSION="${VERSION#v}"                 # tolerate a leading v
TAG="v${VERSION}"
GH_RELEASE=false
[[ "${2:-}" == "--gh-release" ]] && GH_RELEASE=true

BS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"     # board-setup (this repo)
TAP="${PRINTBOARD_TAP:-$HOME/projects/homebrew-tap}"
MIRROR="$BS/printboard.rb"
TAP_FORMULA="$TAP/Formula/printboard.rb"
REPO="jcalixte/board-setup"
TARBALL_URL="https://github.com/${REPO}/archive/refs/tags/${TAG}.tar.gz"
GH="${GH:-gh}"

die(){ echo "release: $*" >&2; exit 1; }

# 1. preflight ---------------------------------------------------------------
[[ -f "$MIRROR" ]]      || die "mirror formula not found at $MIRROR"
[[ -f "$TAP_FORMULA" ]] || die "tap formula not found at $TAP_FORMULA (set PRINTBOARD_TAP)"
[[ "$(git -C "$BS" symbolic-ref --short HEAD)" == "main" ]] || die "board-setup not on main"
[[ -z "$(git -C "$BS" status --porcelain)" ]] || die "board-setup working tree not clean"
git -C "$BS" fetch --tags --quiet origin
git -C "$BS" rev-parse --verify --quiet "refs/tags/$TAG" >/dev/null \
  && die "$TAG already exists — bump the version"
[[ "$(git -C "$BS" rev-parse HEAD)" == "$(git -C "$BS" rev-parse origin/main)" ]] \
  || die "HEAD != origin/main — commit and push the feature change first"

echo "→ releasing printboard $TAG from: $(git -C "$BS" log --oneline -1 HEAD)"

# 2. tag the feature commit & push -------------------------------------------
git -C "$BS" tag -a "$TAG" -m "printboard $VERSION"
git -C "$BS" push origin "$TAG"

# 3. sha256 of the tag tarball (tag must exist first) ------------------------
sha256(){ if command -v sha256sum >/dev/null; then sha256sum; else shasum -a 256; fi; }
echo "→ hashing $TARBALL_URL"
SHA="$(curl -fsSL "$TARBALL_URL" | sha256 | cut -d' ' -f1)"
[[ "${#SHA}" -eq 64 ]] || die "unexpected sha256 '$SHA'"
echo "  sha256 = $SHA"

# bump the url + sha256 lines of a formula in place --------------------------
bump(){
  sed -i.bak -E \
    -e "s#(url \"https://github.com/${REPO}/archive/refs/tags/)v[0-9]+\.[0-9]+\.[0-9]+(\.tar\.gz\")#\1${TAG}\2#" \
    -e "s#(sha256 \")[0-9a-f]{64}(\")#\1${SHA}\2#" \
    "$1"
  rm -f "$1.bak"
  grep -q "$TAG" "$1" && grep -q "$SHA" "$1" || die "failed to bump $1"
}

# 4. mirror (board-setup) ----------------------------------------------------
bump "$MIRROR"
git -C "$BS" add printboard.rb
git -C "$BS" commit -m "chore(printboard): sync formula mirror to $TAG"
git -C "$BS" push origin main

# 5. tap (homebrew-tap) ------------------------------------------------------
git -C "$TAP" pull --ff-only --quiet
bump "$TAP_FORMULA"
git -C "$TAP" add Formula/printboard.rb
git -C "$TAP" commit -m "printboard $VERSION"
git -C "$TAP" push origin main

# 6. optional GitHub Release -------------------------------------------------
if $GH_RELEASE; then
  "$GH" release create "$TAG" --repo "$REPO" \
    --title "printboard $VERSION" --generate-notes \
    || echo "release: gh release create failed (non-fatal — tag + formulas are done)"
fi

echo "✓ printboard $TAG released — both formulas point at $SHA"
