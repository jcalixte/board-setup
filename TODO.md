# TODO

## Create own Google Drive OAuth client (before the shared one is retired)

**Why:** rclone's shared Google Drive `client_id` is being retired and stops working
sometime during 2026 (rclone prints a NOTICE on every export). Until then exports still
work, but they'll break without warning once it's pulled. Fix it before the next activation.

**Current state:** the `gdrive` remote is type `drive`, scope `drive.readonly`, and has
**no `client_id`** set — so it's using the shared client that's going away.

Reference: https://rclone.org/drive/#making-your-own-client-id

### Steps (1–5 in the browser; 6–8 in a terminal)

1. **Create/pick a GCP project** — https://console.cloud.google.com
   Use a **Theodo** project if you have access (lets the consent screen be *Internal*).
   Otherwise a personal project is fine.

2. **Enable the Google Drive API**
   APIs & Services → Library → "Google Drive API" → Enable.

3. **Configure the OAuth consent screen**
   APIs & Services → OAuth consent screen.
   - User type: *Internal* (Theodo project) or *External* (personal).
   - Fill app name + email. No scopes needed here.
   - If *External*: add `julien.calixte@theodo.com` under **Test users** (test mode is
     enough — no Google verification needed).

4. **Create the OAuth client ID**
   APIs & Services → Credentials → Create credentials → OAuth client ID.
   - **Application type: `Desktop app`** (rclone needs the desktop/loopback flow).

5. **Copy the Client ID and Client secret.**

6. **Attach them to the `gdrive` remote:**
   ```sh
   rclone config update gdrive client_id "<CLIENT_ID>" client_secret "<CLIENT_SECRET>"
   ```

7. **Re-authorize** (opens a browser with the new client):
   ```sh
   rclone config reconnect gdrive:
   ```
   Log in as `julien.calixte@theodo.com` and Allow. If *External*, you'll hit an
   "unverified app" screen → Advanced → "Go to … (unsafe)" — expected for your own app.

8. **Verify:**
   ```sh
   printboard doctor
   ```
   The retirement NOTICE should be gone and "deck exports from Drive" should pass.

### Notes

- The client secret lands in `~/.config/rclone/rclone.conf` in plaintext (unless rclone
  config encryption is on). It's a `drive.readonly` desktop-client secret — low blast
  radius, but be aware.
- After this works, expand the one-line README mention (README.md:121) into these steps.
