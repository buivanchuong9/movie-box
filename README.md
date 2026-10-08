<div align="center">

# 🎬 Movie Box

### Your personal cinematic library.

<p>
  <img src="https://img.shields.io/badge/iOS-17%2B-000000?style=for-the-badge&logo=apple&logoColor=white">
  <img src="https://img.shields.io/badge/Swift-6-F05138?style=for-the-badge&logo=swift&logoColor=white">
  <img src="https://img.shields.io/badge/SwiftUI-000000?style=for-the-badge&logo=swift&logoColor=white">
  <img src="https://img.shields.io/badge/StoreKit%202-007AFF?style=for-the-badge&logo=apple&logoColor=white">
</p>

<p>
  A beautifully designed personal movie library for iPhone.
  <br>
  Import. Organize. Discover. Keep track of what you love.
</p>

</div>

---

## ✦ Overview

**Movie Box** is a private cinematic shelf designed for iPhone.

Instead of streaming or downloading movies, Movie Box focuses on
organizing the titles you care about — with a clean poster-first
interface and a simple local-first experience.

> **Your library. Your device. Your collection.**

---

## ✦ Features

<table>
<tr>
<td width="50%">

### 🎞 Personal Library

Import poster artwork from your Photo Library
or Files and build your own collection.

</td>

<td width="50%">

### 🔎 Local Search

Quickly find titles in your personal library
without maintaining an account.

</td>
</tr>

<tr>
<td>

### ❤️ Watchlist & Favorites

Keep track of movies you want to watch
and the titles you never want to forget.

</td>

<td>

### ✓ Watched Tracking

Mark titles as watched and keep your
collection organized.

</td>
</tr>

<tr>
<td>

### 📊 Statistics

Understand your viewing habits with
Lumen Plus statistics.

</td>

<td>

### ✨ Advanced Filters

Filter your collection by additional
metadata with Lumen Plus.

</td>
</tr>
</table>

---

## 💎 Lumen Plus

Unlock the full Movie Box experience.

| Feature | Free | Lumen Plus |
|:---|:---:|:---:|
| Personal library | ✓ | ✓ |
| Import images | ✓ | ✓ |
| Search | ✓ | ✓ |
| Watchlist | ✓ | ✓ |
| Favorites | ✓ | ✓ |
| Watched tracking | ✓ | ✓ |
| Advanced filters | — | ✓ |
| Recommendations | — | ✓ |
| Statistics | — | ✓ |

### Plans

**Monthly** · `$3.99 / month`

**Annual** · `$24.99 / year`

**Lifetime** · `$34.99 one-time`

Native purchases are handled through **StoreKit 2**.

---

## 🛠 Technology

<p>
  <img src="https://img.shields.io/badge/Swift-6-F05138?style=flat-square&logo=swift&logoColor=white">
  <img src="https://img.shields.io/badge/SwiftUI-000000?style=flat-square&logo=swift&logoColor=white">
  <img src="https://img.shields.io/badge/StoreKit%202-007AFF?style=flat-square&logo=apple&logoColor=white">
  <img src="https://img.shields.io/badge/AVFoundation-000000?style=flat-square&logo=apple&logoColor=white">
</p>

- **Swift** — application language
- **SwiftUI** — interface and UI architecture
- **StoreKit 2** — subscriptions and lifetime purchase
- **AVFoundation** — media-related functionality
- **PhotosUI** — photo importing
- **Swift Concurrency** — asynchronous workflows

---

## 🔐 Privacy

Movie Box is designed around a simple principle:

> **Your personal library belongs to you.**

- No Movie Box account
- No sign-in
- No advertising SDK
- No advertising profile
- Imported images remain on the device
- Local library and search
- Purchases handled by Apple

**Privacy:**  
https://sites.google.com/view/movie-box-app-lumen/privacy

**Terms:**  
https://sites.google.com/view/movie-box-app-lumen/terms

**Support:**  
https://sites.google.com/view/movie-box-app-lumen/support

---

## 🧩 Architecture

```text
Movie Box
│
├── Presentation
│   ├── Home
│   ├── Discover
│   ├── Search
│   ├── Detail
│   ├── Watchlist
│   └── Settings
│
├── Features
│   ├── Library
│   ├── Favorites
│   ├── Watched
│   ├── Statistics
│   └── Lumen Plus
│
├── Services
│   ├── StoreKit
│   ├── Media
│   └── Search
│
└── Persistence
    ├── Library
    ├── Preferences
    └── User State
