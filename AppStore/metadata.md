# App Store Connect metadata draft (Guidelines 2.3.2 / 3.1.2(c))

This file is a draft. Editing it does NOT change App Store Connect; paste it in manually.

## Description (English)

Lumen is a personal video library and player. Import videos from your Photos library or the Files app, keep them in a poster-style library, search it, and watch them offline. Lumen does not stream, host or provide any movies or TV episodes; you play only the videos you import.

Some features require Lumen Plus, a separate purchase: a Monthly or Annual auto-renewable subscription, or a one-time Lifetime purchase. Available plans, billing periods and prices are shown in the app, in your local currency, before you purchase.

Lumen Plus subscriptions:
- Monthly: renews every month until canceled
- Annual: renews every year until canceled
- Lifetime: one-time purchase, does not renew

Payment is charged to your Apple ID at confirmation. Subscriptions renew automatically unless canceled at least 24 hours before the end of the current period. Manage or cancel in Settings > Apple ID > Subscriptions.

Terms of Use (EULA): https://sites.google.com/view/movie-box-app-lumen/terms
Privacy Policy: https://sites.google.com/view/movie-box-app-lumen/privacy

> Hard paywall confirmed in code: after onboarding, every user without an active Lumen Plus entitlement sees only the paywall (RootView). Library, search, discover and settings are all unreachable before purchase, so this description calls no feature free. If a free tier is added later, rewrite it.
>
> Verify before pasting: the list of free vs. Lumen Plus features must match the shipped build. In the current build, `RootView` shows the paywall to every user who is not entitled (see `RootView` in Views/RootTabView.swift), so the whole app is gated. If that stays, do not describe any feature as free.

## Manual App Store Connect actions

1. App Information > Privacy Policy URL: `https://sites.google.com/view/movie-box-app-lumen/privacy`.
2. Add the Terms of Use link to the Description (above), or set a custom EULA under App Information > License Agreement.
3. Review every published localization and remove any claim that paid features are free.
4. Confirm the subscription display names, durations and localizations in each subscription's App Store Connect page.
5. Re-open the saved metadata and confirm the URLs load.

## Hosted legal pages

The existing Google Sites pages describe a poster-import app and hardcode prices. Replace them with the drafts in this folder (see LEGAL_PAGE_PUBLISHING.md). Nothing hosted has been changed.
