# Meta (Facebook) app – URLs for Basic settings

Use these URLs in **Meta for Developers → App settings → Basic** once the `docs/` folder is hosted on the web.

## Custom domain (winkidoo.com)

When the custom domain **winkidoo.com** is configured for GitHub Pages (repo Settings → Pages → Custom domain, and DNS A records pointing to GitHub):

- **Privacy policy URL:** `https://winkidoo.com/privacy-policy.html`
- **User data deletion:** `https://winkidoo.com/data-deletion.html`
- **App domains:** Add `winkidoo.com` in Basic settings if required.

## Option A: GitHub Pages (no custom domain)

1. Push this repo to GitHub (e.g. `https://github.com/YourUsername/Winkidoo`).
2. In the repo: **Settings → Pages**.
3. Under **Source**, choose **Deploy from a branch**.
4. Branch: **main**, folder: **/ (root)** or **docs** (if you set it to “root” you may need to put `index.html` in root; for “docs” as root, use the paths below).
5. Save. After a few minutes the site will be at `https://YourUsername.github.io/Winkidoo/` (if “docs” is the root, then):
   - **Privacy policy URL:** `https://YourUsername.github.io/Winkidoo/privacy-policy.html`
   - **User data deletion:** choose “Data deletion instructions URL” and set: `https://YourUsername.github.io/Winkidoo/data-deletion.html`

Replace `YourUsername` and `Winkidoo` with your actual GitHub username and repo name.

## Option B: Any other host

Upload the contents of the `docs/` folder to your website or any static host. Then use the full URLs to:
- `privacy-policy.html` → **Privacy policy URL**
- `data-deletion.html` → **User data deletion** (Data deletion instructions URL)

## App icon (1024×1024)

In the repo, use: **assets/images/app_icon_1024.png**  
Upload this file in Meta → App settings → Basic → **App icon (1024 x 1024)**.

## Category

In Basic settings, set **Category** to something that fits your app. For Winkidoo we use **Social networks & dating**. Also set **Contact email** (do not commit real addresses in public docs).
