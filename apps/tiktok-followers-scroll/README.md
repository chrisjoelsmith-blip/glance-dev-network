# TikTok Followers

A live follower counter for one TikTok account: every digit of the count,
the display handle with its verified check, and an optional goal bar. A
second page shows total likes and how many videos earned them. No API key.

## Settings

| setting | what it is |
|---|---|
| **TikTok username** | The handle from the profile URL, with or without the `@`. For `https://www.tiktok.com/@khaby.lame` enter `khaby.lame`. |
| **Follower goal** *(optional)* | A target like `10K`, `250K` or `1.5M`. On the scroll panel it adds a bar filling toward the goal under the count; on the 64 panel it shows the percentage. It says GOAL HIT once you pass it. Leave blank for none. |

## What the pages show

- **Followers** - the count with commas in the largest font that fits, so
  `95,738,011` is shown as itself on the scroll panel. The 64 panel shows
  the exact count when it fits and a compact `95.7M` when it does not.
- **Likes** - total likes for the account, with the video count as a footnote.

## Notes

- TikTok has no public API. The app reads the numbers TikTok embeds in the
  public profile page, which is why there is nothing to sign up for. If
  TikTok throttles the render host you will see `TIKTOK BLOCKED US` for a
  refresh or two; it clears on its own.
- Refresh is every 10 minutes. Counts on the profile page are TikTok's own
  live figures, not estimates.
- Private accounts still show their follower count; accounts that do not
  exist show `NOT FOUND` with the handle so a typo is obvious.
