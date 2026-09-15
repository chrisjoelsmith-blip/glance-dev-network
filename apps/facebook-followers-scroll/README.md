# Facebook Page Followers

A live follower counter for one public Facebook Page: the exact count, the
page's name with its verified badge, and the page ID. No API key or login.

## Settings

| setting | what it is |
|---|---|
| **Facebook Page ID** | The Page's numeric ID, shown on the Page's About tab under Page transparency. `54971236771` is NASA. The name from the page's URL (`nasa` for `https://www.facebook.com/nasa`) works too, and pasting the whole URL also works; the app strips the site part. |

## Notes

- The count comes from Facebook's own Page Plugin, the embeddable box any
  website can show, which is why nothing has to be signed up for. It works
  for public **Pages** only. Personal profiles and unpublished pages show
  `NOT FOUND`.
- **Check the name on the panel.** If Facebook does not know the name you
  typed, it may serve the closest page it can find instead of an error.
  The panel always shows the page's real name next to the count so a wrong
  page is obvious at a glance.
- Refresh is every 10 minutes.
