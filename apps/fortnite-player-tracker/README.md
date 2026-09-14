# Fortnite Player Tracker

Lifetime Fortnite Battle Royale stats for you and up to 9 friends. Each of the
5 pages tracks two players and cycles through their WINS, K/D, WIN RATE,
KILLS, and TOP 10S once a minute.

## Getting an API key

Stats come from [fortnite-api.com](https://fortnite-api.com), and its stats
endpoint requires a free key.

1. Go to **[dash.fortnite-api.com/account](https://dash.fortnite-api.com/account)**
   and click **Login with Discord**. This is the only sign-in method — there's
   no email/password option.
2. Once signed in, go to **Apps** and click **Create App**. Give it any name.
3. Copy the key it generates and paste it into this app's **Fortnite-API.com
   key** setting in Glance.

Leave the key blank and the app runs fine on clearly-labeled **DEMO** data
until you add one.

### If Discord's login or phone verification gives you trouble

- The Discord login button doing nothing usually means a popup blocker or an
  ad-blocking extension (uBlock Origin, Brave Shields, etc.) is killing the
  OAuth redirect — allowlist `dash.fortnite-api.com` and `discord.com`, or try
  an incognito window with extensions off.
- If Discord asks you to verify a phone number and rejects it as **"invalid
  phone number,"** check that the country-code dropdown next to the field
  actually matches your number, and use a real mobile number — Discord does
  not accept VOIP numbers (Google Voice, TextNow, Skype) or landlines for
  verification.

## Inputs

| Input | What it is |
|---|---|
| Fortnite-API.com key | Your key from the dashboard above. Optional — blank runs demo data. |
| Player 1 (you) — Epic name | Your exact Epic display name, case-sensitive. |
| Player 2–10 — Epic name | Friends' Epic display names. Leave any blank to leave that slot empty. |

Platform is fixed to Epic (PC/mobile) account lookups.
