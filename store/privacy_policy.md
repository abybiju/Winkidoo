# Privacy Policy for Winkidoo

**Last updated: April 4, 2026**

Winkidoo ("we", "us", or "our") operates the Winkidoo mobile application (the "App"). This Privacy Policy explains how we collect, use, disclose, and protect your information when you use our App.

By creating an account or using Winkidoo, you agree to the collection and use of information in accordance with this policy.

---

## 1. Information We Collect

### 1.1 Information You Provide
- **Account information**: email address and password (if using email login), or OAuth tokens via Google, Apple, or Facebook sign-in.
- **Profile information**: display name and profile photo (optional).
- **App content**: surprise messages, encrypted content you create and share with your partner, voice notes, photos uploaded to surprises, and chat messages within battles.
- **Custom judge content**: names, descriptions, and images you upload when creating custom AI judge personas.

### 1.2 Information Collected Automatically
- **Usage data**: features you interact with, screens visited, timestamps of activity, and battle/quest completion data.
- **Push notification tokens**: device push tokens used to deliver in-app notifications.
- **Device and connection data**: app version, operating system type and version, and crash/error logs.

### 1.3 Information from Third Parties
- **OAuth providers** (Google, Apple, Facebook): when you sign in using a third-party account, we receive your name, email, and profile picture from that provider, as permitted by your settings with them.
- **RevenueCat**: subscription status, entitlement data, and purchase receipts to manage your Wink+ subscription. RevenueCat's privacy policy applies: https://www.revenuecat.com/privacy
- **Google Firebase**: device push tokens for notifications. Firebase's privacy policy applies: https://firebase.google.com/support/privacy

---

## 2. How We Use Your Information

We use the information we collect to:
- Provide, operate, and maintain the Winkidoo experience.
- Enable the couple-linking feature so you and your partner can share surprises and play together.
- Process and manage in-app purchases and subscriptions through RevenueCat.
- Send push notifications about surprise unlocks, partner activity, and streak reminders.
- Power AI judge responses using the Google Gemini API (your chat messages within a battle are sent to Gemini to generate judge commentary; they are not stored by us beyond what is documented in your battle history).
- Analyse aggregate, anonymised usage patterns to improve the App.
- Maintain security, detect fraud, and enforce our Terms of Service.

---

## 3. Data Storage and Security

- Your content (surprise text, voice notes, photos) is stored in **Supabase** (PostgreSQL + Storage), hosted in the US.
- Surprise text content is **end-to-end encrypted** using a couple-specific key; we cannot read the contents of your surprises.
- Voice notes and photos are stored encrypted at rest in Supabase Storage and are accessible only via signed, time-limited URLs.
- We implement industry-standard security measures including TLS in transit and RLS (Row-Level Security) policies at the database level.
- No security system is impenetrable. We cannot guarantee the absolute security of your data.

---

## 4. Data Sharing and Disclosure

We do not sell your personal information. We share data only:

| Recipient | Purpose |
|---|---|
| **Your partner** | Shared surprise content, battle progress, and couple XP/stats |
| **Supabase** | Database and file storage hosting |
| **Google Gemini API** | Generating AI judge responses (battle chat messages only) |
| **RevenueCat** | Subscription management and purchase verification |
| **Firebase (Google)** | Push notification delivery |
| **Apple / Google / Facebook** | OAuth sign-in (only when you choose those methods) |
| **Law enforcement** | If required by law, court order, or to protect rights/safety |

---

## 5. Data Retention

- Your account data is retained as long as your account is active.
- Surprises are deleted according to your configured auto-delete setting (immediately upon viewing, 24 hours, or 48 hours).
- Battle chat messages are retained as part of your couple's surprise vault history.
- You may request deletion of your account and associated data by emailing **privacy@winkidoo.app**.

---

## 6. Your Rights

Depending on your location, you may have the right to:
- **Access** the personal data we hold about you.
- **Correct** inaccurate data.
- **Delete** your account and data.
- **Restrict or object** to certain processing.
- **Data portability** — receive a copy of your data.

To exercise any of these rights, contact us at **privacy@winkidoo.app**.

---

## 7. Children's Privacy

Winkidoo is intended for users aged **17 and older** (romantic-relationship focused content). We do not knowingly collect personal information from anyone under 13. If we become aware that a child under 13 has provided us with personal data, we will delete it immediately.

---

## 8. International Data Transfers

Winkidoo is operated from Canada. Your data may be processed in the United States (Supabase, Google, Firebase, RevenueCat infrastructure). By using the App, you consent to this transfer. We ensure appropriate safeguards are in place.

---

## 9. Third-Party Links and Services

The App may contain links to third-party websites or integrate with third-party services. We are not responsible for the privacy practices of those services. We encourage you to review their privacy policies.

---

## 10. Changes to This Privacy Policy

We may update this Privacy Policy from time to time. We will notify you of significant changes by updating the "Last updated" date above and, where appropriate, via in-app notification. Continued use of the App after changes constitutes your acceptance of the updated policy.

---

## 11. Contact Us

If you have any questions or concerns about this Privacy Policy, please contact us:

**Winkidoo**
Email: **privacy@winkidoo.app**

---

*This privacy policy was last updated on April 4, 2026.*
