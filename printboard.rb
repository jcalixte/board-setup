# Homebrew formula for printboard.
# Place a copy in your tap: jcalixte/homebrew-tap → Formula/printboard.rb
# Install with:  brew install jcalixte/tap/printboard
#
# Before publishing: push board-setup to GitHub, tag a release, then set `url`
# to the release tarball and fill `sha256` (brew fetch <url> prints it, or
# `shasum -a 256 <tarball>`).
class Printboard < Formula
  desc "Print the Enabler project board's papers at the right size, count, and version"
  homepage "https://github.com/jcalixte/board-setup"
  url "https://github.com/jcalixte/board-setup/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "REPLACE_WITH_TARBALL_SHA256"
  license "MIT"

  depends_on "poppler"        # provides pdftotext (read slide titles from the export)
  depends_on "rclone"         # exports the org-restricted Slides deck to PDF (one-time `rclone config`)
  depends_on "python@3.12"

  def install
    # Ship the script and the default manifest together; the script finds the
    # manifest next to itself (or ~/.config/printboard/manifest.json to override).
    libexec.install "printboard", "manifest.json"
    (bin/"printboard").write_env_script libexec/"printboard",
                                         PATH: "#{Formula["python@3.12"].opt_bin}:$PATH"
  end

  def caveats
    <<~EOS
      printboard exports an org-restricted Google Slides deck, so each user must
      authenticate rclone once:

        rclone config           # create a Google Drive remote named "gdrive"

      If your Workspace blocks third-party OAuth apps, create your own OAuth
      client in Google Cloud and pass its client_id/secret during `rclone config`.

      To customise papers/sizes/counts without reinstalling, copy the manifest:
        mkdir -p ~/.config/printboard
        cp #{libexec}/manifest.json ~/.config/printboard/manifest.json
    EOS
  end

  test do
    assert_match "usage", shell_output("#{bin}/printboard --help")
  end
end
