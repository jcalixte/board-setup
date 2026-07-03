# Homebrew formula for printboard — a mirror of the published formula in the tap
# (jcalixte/homebrew-tap → Formula/printboard.rb), which is the source of truth
# behind `brew install jcalixte/tap/printboard`. When cutting a release: tag the
# repo, bump `url`/`sha256` to the new tag here AND in the tap, then push both.
class Printboard < Formula
  desc "Print the Enabler project board's papers at the right size, count, and version"
  homepage "https://github.com/jcalixte/board-setup"
  url "https://github.com/jcalixte/board-setup/archive/refs/tags/v1.3.0.tar.gz"
  sha256 "f9fb9e3b31784aeceaa7339edbb954b732ce788cd0a2869e3fa310e20594ac12"
  license "MIT"

  depends_on "ghostscript"    # gs — scale each page to its exact A3/A4 size before printing
  depends_on "poppler"        # pdftotext — read slide titles from the export
  depends_on "python@3.12"
  depends_on "rclone"         # export the org-restricted Slides deck to PDF

  def install
    # Ship the script and the (doc_id-free) default manifest together; the script
    # finds the manifest next to itself, or ~/.config/printboard/manifest.json.
    libexec.install "printboard", "manifest.json"
    (bin/"printboard").write_env_script libexec/"printboard",
                                         PATH: "#{formula_opt_bin("python@3.12")}:$PATH"
  end

  def caveats
    <<~EOS
      One-time per user (the deck is org-restricted):
        printboard setup --deck "<Google Slides URL or id>"
        printboard doctor

      setup authorises rclone (read-only) and saves the deck id to
      ~/.config/printboard/config.json (it is never shipped in the formula). If your
      Workspace blocks third-party OAuth apps, create your own OAuth client in Google
      Cloud Console and re-run `rclone config`.
    EOS
  end

  test do
    assert_match "usage", shell_output("#{bin}/printboard --help")
  end
end
