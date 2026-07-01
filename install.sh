#!/bin/bash
# install.sh — one-line setup of printboard for non-developers.
#
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/jcalixte/board-setup/main/install.sh)"
#
# Installs Homebrew if it's missing, then `jcalixte/tap/printboard` (which pulls
# python, ghostscript, poppler and rclone). Stops short of `printboard setup`,
# which needs a deck URL and a browser sign-in — it prints those two commands
# for you to run afterwards.
set -euo pipefail

echo "→ printboard installer"

# 1. Homebrew (its own installer pulls Xcode Command Line Tools if needed).
if ! command -v brew >/dev/null 2>&1; then
  echo "→ Homebrew not found — installing it (you'll be asked for your Mac password)…"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# 2. Put brew on PATH for this run (Apple Silicon vs Intel).
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# 3. printboard + all its dependencies.
echo "→ Installing printboard…"
brew install jcalixte/tap/printboard

# 4. Hand off the two steps that need a human (a deck URL and a browser sign-in).
cat <<'EOS'

✓ printboard is installed.

Two one-time steps left (these need you — a browser sign-in):

  printboard setup --deck "<paste the Google Slides deck URL>"
  printboard doctor        # checks deps, auth, and that the deck exports

Then try a no-print check:

  printboard generic --dry-run
EOS
