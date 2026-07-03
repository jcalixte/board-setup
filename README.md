# board-setup — `printboard`

Print the **Enabler board**'s papers — the right ones, at the right size, the right
number of copies, and the right version — in one command.

The papers live as slides in one Google Slides deck (the source of truth that
colleagues edit). `printboard` exports that deck to a PDF on demand, finds each
paper's slide **by its title**, and sends it to the printer at the size and count
declared in [`manifest.json`](./manifest.json).

See [`CONTEXT.md`](./CONTEXT.md) for the vocabulary and the decisions behind this.

## Usage

```sh
printboard                            # ACTIVATION: every variant of every paper, at its count
printboard generic                    # only the generic (blank) variants — ×5 each
printboard generic tech-working-conditions   # one paper, one variant — 1 copy (quick reprint)
printboard with-examples              # only the worked-example references — ×1 each
printboard generic takt --count 5     # a named paper, but this many copies
printboard --printer _4e_etage
printboard generic --to-pdf ~/Downloads/board.pdf   # export a PDF instead of printing

printboard --list-titles              # debug: show page → title for the live deck
printboard --dry-run                  # show the lp commands without printing
printboard printer                    # pick the default printer from a menu (A3/A4 shown)
printboard setup                      # one-time: authorise rclone (read-only Drive)
printboard doctor                     # check deps, auth, and that the deck exports
```

- **No version → activation**: prints every variant of every paper at its version count
  (`with-examples` ×1, `template` ×1, `generic` ×5). Add a version to filter
  (`printboard generic`) and/or a paper id to target one (`printboard generic questionnaire`).
  Order doesn't matter — each token is recognised as a version or a paper.
- **Naming a paper prints 1 copy.** `version_counts` are board-activation quantities, so a
  single-paper request (e.g. `printboard dantotsu`) is treated as a quick reprint and defaults
  to 1 — not the activation count. Use `--count N` when you do want more.
- Versions are **`with-examples`**, **`template`**, **`generic`** — read from the slide title.
- The **printer** (must support A3 + A4) is resolved in this order: `--printer <name>`
  (per run) → `"printer"` in `~/.config/printboard/config.json` (persistent, printboard
  only) → `print.printer` in the manifest → the system default `lp` uses (set it with
  `lpoptions -d <printer>`). `printboard doctor` shows the one in effect.
- **`printboard printer`** is the easy way to set the persistent one: it lists every
  printer with its friendly name and whether it does **A3+A4**, and saves your pick to
  the config above. `printboard printer <name>` sets one directly; `--list` just shows
  them; `--unset` reverts to the system default.
- **`--to-pdf <path>`** writes the selected papers to one PDF instead of sending them to a
  printer — **one page per variant**, each sized to its A3/A4. No printer needed, and
  `--count` doesn't apply (a PDF is a master; set copies when you print it). Point it at a
  directory to auto-name the file.

## The deck ↔ tool contract

When you rework the deck, follow this so the tool can find each paper:

1. Each printable paper is **one slide** whose **title is its canonical name**
   (e.g. `Tech Working Conditions`), as **real text** (not inside an image).
2. That title must be **unique** in the deck and appear as its own line — the tool
   matches a standalone title line, so spec/list slides are ignored.
3. A paper with several versions gets **one slide per version**, titled
   `<Paper> — <version>` — e.g. `Tech Working Conditions — with examples` and
   `Tech Working Conditions — generic`. The manifest maps each to its version. A
   single-variant paper can keep a bare title (e.g. `Questionnaire`).
4. Anything that isn't a paper (specs, materials, the "Printed paper needed" table)
   needs no change — it simply won't match.

`printboard` **refuses to print** when a title is missing, ambiguous (on several
slides), or only a fuzzy substring match — and tells you what to fix. Use
`printboard generic --list-titles --from-pdf <export>` to check the deck, or
`--force` to override (uses the first matching page).

## manifest.json

The source of truth for what Slides can't store — size, count, version-variant
titles, and pillar per paper:

```jsonc
{
  "deck":  { "rclone_remote": "gdrive" },        // the private deck id lives in local config, not here
  "print": { "printer": null, "orientation": "landscape", "safe_margin_mm": 0,
             "version_counts": { "with-examples": 1, "template": 1, "generic": 5 },
             "lp_options": ["sides=one-sided"] },
  "papers": [
    { "id": "tech-working-conditions", "pillar": "Tech-enabled Network of Teams", "size": "A3",
      "variants": { "with-examples": "Tech Working Conditions — with examples",
                    "generic":       "Tech Working Conditions" } }
  ]
}
```

Counts come from `version_counts`; override one variant with an object:
`"generic": { "title": "…", "count": 3 }`. A variant whose title is the bare paper
name matches the unlabelled (blank) slide — the tool gives each contested page to the
most specific title, so `… - template` wins its slide and the bare one falls to generic.

Each page is **scaled to its exact A3/A4 size** (vector, via ghostscript) before
printing, so it fills the sheet on any printer regardless of the driver's fit-to-page
behaviour. `safe_margin_mm` insets the content (0 = full bleed; keep content off the
edges in the slide design, or set e.g. 6 to avoid the printer's unprintable border).

The **deck id is not stored here** — it's private, kept per-machine in
`~/.config/printboard/config.json` (written by `printboard setup`), so it never ships
in the formula. Manifest lookup order: `--manifest` → `$PRINTBOARD_MANIFEST` →
`~/.config/printboard/manifest.json` → the copy bundled next to the script.

## Setup

Requires `poppler` (pdftotext), `rclone`, and `python3`.

```sh
brew install poppler rclone
printboard setup --deck "<Google Slides URL or file id>"   # rclone OAuth + save the deck id locally
printboard doctor                                          # verify deps, auth, and that the deck exports
```

`setup` authorises rclone (browser, read-only — one time per user) and saves the deck
id to `~/.config/printboard/config.json`. The deck is **org-restricted**, so each user
authorises as themselves; you do **not** need to choose a Shared Drive (the deck is
fetched by id, so the remote's root is irrelevant). If your Workspace blocks third-party
OAuth apps, create your own OAuth client in Google Cloud Console and supply its
client_id/secret (re-run `rclone config`).

Then a no-print check of the live deck:

```sh
printboard generic --dry-run
```

## Install (for non-developers)

One line, pasted into **Terminal** (⌘-Space → "Terminal"). It installs Homebrew
if you don't have it, then printboard and everything it needs:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/jcalixte/board-setup/main/install.sh)"
```

Then the two one-time steps it prints — a browser sign-in to the deck:

```sh
printboard setup --deck "<paste the Google Slides deck URL>"
printboard doctor        # checks deps, auth, and that the deck exports
```

## Install (Homebrew)

```sh
brew install jcalixte/tap/printboard
```

The formula lives in [`printboard.rb`](./printboard.rb); copy it to
`jcalixte/homebrew-tap` → `Formula/printboard.rb` once this repo is published and
tagged.
