# Publishing the legal pages

**Local Markdown files do not update the hosted Google Sites pages.** Nothing in this repository has edited Google Sites, and no tool in this session had access to do so. The pages below are still the old content until you edit them.

## URLs the app uses (from `Config/Legal.xcconfig`)

| Page | URL |
|---|---|
| Terms of Use | https://sites.google.com/view/movie-box-app-lumen/terms |
| Privacy Policy | https://sites.google.com/view/movie-box-app-lumen/privacy |

The Release build fails if either is missing or not https (`Scripts/verify-legal-urls.sh`). If you change the Google Sites URLs, change them in `Config/Legal.xcconfig`, the App Store Connect Privacy Policy field, and the description.

## Steps

1. Resolve every `[CONFIRM]` item in the two drafts (list below). Delete the HTML comment block at the top of each.
2. Google Sites > page **Terms**: delete all existing body text (it describes a poster-import app and lists fixed prices), then paste `AppStore/TermsOfUse.md`.
3. Google Sites > page **Privacy**: delete all existing body text (it says the app downloads no catalog, which is false), then paste `AppStore/PrivacyPolicy.md`.
4. Old content to remove: the "Movie Box is a personal library for poster images" description, the "Introduction screens" section, all `$3.99 / $24.99 / $29.99` prices, poster-image wording (the app now imports videos) and anything that no longer matches the drafts.
5. Click **Publish** in Google Sites. Unpublished edits are not visible at the URLs.
6. Verify (logged out or in a private window):
   ```
   curl -sL -o /dev/null -w "%{http_code}\n" https://sites.google.com/view/movie-box-app-lumen/terms
   curl -sL https://sites.google.com/view/movie-box-app-lumen/privacy | grep -ci "import"
   curl -sL https://sites.google.com/view/movie-box-app-lumen/terms | grep -c '\$[0-9]'
   ```
   Expected: `200`; a count of 1 or more for the video-import wording; `0` for dollar prices. Also open both pages on an iPhone and read them fully.
7. Re-check that the pages do not still contain `[CONFIRM`.

## Facts only the developer can confirm

1. Legal entity or individual name, and a contact email or support URL (none is in the repo).
2. Publication date for both pages.
3. Whether the paywall-before-any-use behavior is intended to ship (`RootView`). If a free tier is added, the Terms section 3 and the App Store description change.
4. What "Lifetime" promises.
5. Which features Lumen Plus includes in the shipped build.
6. Refund wording beyond Apple's, warranty disclaimer, liability limit, governing law, children's statement, regional privacy-rights language. These need legal review.
7. Whether you rely on Apple's standard EULA or a custom EULA.
8. No analytics, crash reporting, ads or server-side receipt validation exist outside this repo.
9. Whether notifications are planned. The app requests the permission but no scheduled notification was found.
10. Your App Privacy answers in App Store Connect; with no data leaving the device, "Data Not Collected" is expected, but confirm. `PrivacyInfo.xcprivacy` currently declares no collected data.
11. (Removed: the app no longer uses TMDB.)
12. Whether iOS or iCloud device backups include the app data in your setup.

## App Store Connect (manual, not done)

- App Information > Privacy Policy URL = the privacy URL above.
- Description: paste from `AppStore/metadata.md`, including both URLs, or set a custom EULA.
- Check every localization you publish.
