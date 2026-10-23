<!--
DRAFT. Do not publish until every [CONFIRM] item is resolved and this notes block is deleted.
Based on a code audit after all third-party catalog code was removed. Only practices found in the code are stated.
Things that cannot be proven from the repository are marked [CONFIRM].
-->

# Privacy Policy

**Lumen / Movie Box** (bundle ID `com.lumen.discovery`)

Last updated: [CONFIRM: publication date]

This policy describes how the Lumen iOS app (shown on the device as "Movie Box") handles information. The app is provided by [CONFIRM: legal entity or individual name]. Contact: [CONFIRM: contact email or support URL].

## Summary

- The app has no account system and does not ask for your name, email, phone number or contacts.
- Videos you import and your lists are stored only on your device. The app does not upload them.
- The app makes no network requests of its own for content. Its only network use is Apple's In-App Purchase service. [CONFIRM: re-check after the final build.]
- We found no analytics, advertising, tracking or crash-reporting code in the app. [CONFIRM: no such service is configured outside the code.]

## Information stored on your device

Stored on your device by the app, not on a server we operate:
- Videos you import, copied into the app's own storage, plus a preview image made from each video
- Watchlist, favorites, watched titles and episode progress
- Recent searches and recently viewed titles
- Preferences: appearance, content language, genre preferences chosen at introduction, whether you completed the introduction, and a notifications preference

Deleting the app removes this data from your device. Imported video copies are excluded from device backups. Other app data may be included in backups under your device settings. [CONFIRM: backup behavior.]

## Information sent to third parties

**Apple.** Purchases are processed by Apple In-App Purchase. The app learns only whether a Lumen Plus purchase is active. We do not receive your payment details. [CONFIRM: you do not use any server-side purchase validation or receipts.]

## Photos and files

You choose which videos to import using the system Photos picker or Files picker. The app receives only the items you select. Files picked from the Files app are opened with temporary access granted by iOS, copied into the app, and not changed.

## Notifications

The app can ask for permission to show notifications. The audit found no code that schedules or sends notifications; the permission and your choice are stored on the device. [CONFIRM: whether notifications are planned for this version. If none, consider removing the permission request.]

## Advertising and tracking

The app does not include an advertising or tracking SDK. Lumen Plus messages inside the app are our own and are shown only to people without an active Lumen Plus purchase. [CONFIRM: what this means in the shipped build, since the app currently gates all use behind the purchase screen.]

## Children

The app is not directed to children under 13. [CONFIRM: age rating and statement; legal review.]

## Your choices

- Delete the app to remove locally stored data.
- Turn notifications off in iOS Settings.
- Manage subscriptions in Settings > Apple ID > Subscriptions.
- [CONFIRM: any data-subject rights language required in your markets (for example GDPR or CCPA). It is intentionally not drafted here.]

## Changes

We may update this policy. The date above shows the latest version.
