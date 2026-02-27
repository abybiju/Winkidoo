# Supabase Storage for Winkidoo

The app uploads **photo** and **voice** surprise media to Supabase Storage. You must create the bucket and policies once.

## 1. Create the bucket

1. Open **Supabase Dashboard** → your project → **Storage**.
2. Click **New bucket**.
3. **Name:** `surprises` (must match exactly; see `AppConstants.surpriseStorageBucket`).
4. Choose **Private** (recommended) or Public depending on your security needs.
5. Create the bucket.

## 2. Policies (if bucket is Private)

For private buckets, add policies so authenticated users can upload and read objects.

- **Upload (insert):** Allow authenticated users to upload objects under their couple path. Example policy name: `Allow authenticated uploads`.
  - Allowed operation: **INSERT**
  - Target roles: `authenticated`
  - Policy definition (e.g. using `bucket_id = 'surprises'` and a check that the path starts with the user’s couple id if you store it in RLS context, or a simple `true` for authenticated to allow all uploads to this bucket).

- **Read (select):** Allow authenticated users to read objects. Example:
  - Allowed operation: **SELECT**
  - Target roles: `authenticated`
  - Policy definition: `true` (or restrict by path if you have row-level context).

In the Storage UI: open the `surprises` bucket → **Policies** → **New policy**. Use “For full customization” and add:

- **INSERT** for `authenticated`: expression `true`.
- **SELECT** for `authenticated`: expression `true`.

(You can tighten later with path checks if needed.)

## 3. Verify

After creating the bucket (and policies), try creating a **photo** or **voice** surprise in the app. The “Bucket not found” error should go away.
