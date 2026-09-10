# ADM — Next-Gen Advanced Download Manager ⚡

[![Build ADM Apps (Android & iOS)](https://github.com/broroy38-max/ADM/actions/workflows/build.yml/badge.svg)](https://github.com/broroy38-max/ADM/actions/workflows/build.yml)

> **Core Philosophy:** Faster downloads + Reliable resume + Intelligent queue + Powerful browser integration + Privacy-first + Modern Material 3 UX.

Built with **Flutter & Dart**, targeting both **Android** and **iOS** platforms, compiled automatically via **GitHub Actions**.

---

## 🌟 Key Features

### 1. 🏠 Home Dashboard
- **Live Status Header:** Real-time count of Active, Queued, Completed, and Failed tasks.
- **Dynamic Speed Card:** Instant throughput display (`↓ MB/s`), today's cumulative bandwidth, and active performance mode badge (`Turbo`, `Balanced`, `Saver`).
- **Real-Time Throughput Graph:** Ultra-smooth 60fps bezier curve visualizing network bandwidth across a rolling 30-second window.
- **Quick Action Grid:** 1-tap shortcuts for Add URL, Paste Link, Built-in Browser, and Power Tools.

### 2. ⚡ High-Speed Multi-Connection Engine
- **Configurable Multi-Threading:** 1, 2, 4, 8, 16, or 32 parallel chunk connections.
- **Dynamic Chunk Segmentation:** Automatically calculates byte ranges `[startByte, endByte]` for parallel downloads.
- **Automatic Fallback:** Seamlessly detects whether target servers support `Accept-Ranges` bytes; falls back to single-connection streaming if ranges are unavailable.
- **Preallocated Sparse Storage:** Uses `RandomAccessFile` to write chunks directly into preallocated file positions without memory bloat.

### 3. 🔄 Bulletproof Resume Engine
- **Range & ETag Validation:** Prevents corruption by validating `ETag` and `Last-Modified` headers before resumption.
- **Chunk-Level State Persistence:** Persists segment byte offsets to SQLite so interrupted transfers resume exactly where they left off.
- **Checksum Verification:** Automatic MD5 and SHA-256 hash calculation upon download completion.

### 4. 🧠 Smart Download Algorithm & Network Intelligence
- **Performance Modes:**
  - **Turbo Mode:** Aggressive retry, maximum connections (16–32), adaptive chunking.
  - **Balanced Mode:** Optimum balance between speed and battery efficiency (8 connections).
  - **Battery Saver Mode:** Minimal connections (2 connections), reduced CPU wakeups.
- **Wi-Fi Protection:** Automatically pauses downloads when switching from Wi-Fi to cellular data (if Wi-Fi Only is toggled).
- **Auto-Resume on Wi-Fi:** Instantly resumes queued downloads as soon as Wi-Fi reconnects.
- **Battery Guard:** Automatically halts intensive downloads when battery falls below threshold (e.g. 15%).

### 5. 📥 Intelligent Queue & Priority Management
- **Smart Concurrency Controller:** Configurable limit (1 to 10 concurrent active tasks).
- **Priority Hierarchy:** `Critical` > `High` > `Normal` > `Low`. Higher priority downloads automatically claim bandwidth first.
- **Auto-Retry Engine:** Exponential backoff mechanism (retries after 3s, 6s, 9s) on network disconnects or transient server errors.

### 6. 🌐 Built-in Browser & Media Sniffer
- **Integrated Web Browser:** Omnibox URL bar, search suggestions, bookmarks, and back/forward navigation.
- **Incognito Browsing:** Privacy-first browsing mode without caching or history retention.
- **Automated Media Sniffer:** Detects streamable and downloadable media (.mp4, .mkv, .mp3, .zip, .apk, .pdf, .iso) in real time and presents a 1-tap "Download with ADM" modal.

### 7. 📁 Smart Storage & File Management
- **Auto-Categorization Folders:**
  - `Movies/` — Video formats (`.mp4`, `.mkv`, `.avi`, `.webm`)
  - `Music/` — Audio formats (`.mp3`, `.flac`, `.wav`, `.m4a`)
  - `Documents/` — Documents (`.pdf`, `.docx`, `.xlsx`, `.txt`)
  - `Archives/` — Compressed archives (`.zip`, `.rar`, `.7z`, `.tar.gz`, `.iso`)
  - `Apps/` — Installable packages (`.apk`, `.ipa`, `.deb`, `.dmg`)
  - `Images/` — Media photos (`.png`, `.jpg`, `.webp`)
- **Collision Strategies:** Auto Rename (`file (1).ext`), Overwrite, or Resume existing files.

### 8. 🤖 Smart AI Download Assistant
- Natural language task configuration parser supporting both Bengali and English:
  > *"https://example.com/file.zip রাত ২টায় Wi-Fi দিয়ে download করো urgent"*
  - Parses URL, scheduled time (02:00 AM), Wi-Fi constraint (`true`), and Priority (`High`).
  - Generates ready-to-run download configurations for confirmation.

### 9. 🧪 Intelligent Diagnostics Lab
- Comprehensive root cause analysis for failed transfers:
  - Validates **Internet Connection**, **DNS Resolution**, **Host Reachability**, and **HTTP Authorization**.
  - Detailed diagnostic breakdown for HTTP 401, 403, 404, 416, 429, and 5xx errors.
  - Actionable 1-tap recommendations (e.g. "Open in browser to refresh session", "Retry with fewer connections").

### 10. 🎨 Modern Material 3 Theme
- Seamless theme switching:
  - **Dark Mode:** Deep slate theme with neon cyan accents.
  - **AMOLED Black:** Pure `#000000` background for OLED battery conservation.
  - **Light Mode:** Crisp, clean Material 3 palette.

---

## 🛠️ GitHub Actions CI/CD Build System

This repository is configured with automated GitHub Actions CI/CD to build both **Android APK** and **iOS IPA / App** packages on every push to `main`:

- **Android Job (`ubuntu-latest`):**
  - Sets up OpenJDK 17 and Flutter stable.
  - Runs unit and regression test suite.
  - Compiles release APK: `flutter build apk --release --no-tree-shake-icons`.
  - Uploads artifact: `ADM-Android-Release-APK`.

- **iOS Job (`macos-14`):**
  - Sets up Flutter stable on Apple Silicon runner.
  - Compiles release iOS app: `flutter build ios --release --no-codesign`.
  - Packages unsigned `.ipa` archive with `Payload/Runner.app`.
  - Uploads artifact: `ADM-iOS-Unsigned-IPA`.

---

## 📱 How to Download Built Apps

1. Go to the [ADM GitHub Actions Runs](https://github.com/broroy38-max/ADM/actions).
2. Click on the latest run under **Build ADM Apps (Android & iOS)**.
3. Scroll down to the **Artifacts** section:
   - Download **`ADM-Android-Release-APK`** for Android.
   - Download **`ADM-iOS-Unsigned-IPA`** for iOS.

---

## 💻 Local Development

```bash
# Clone the repository
git clone https://github.com/broroy38-max/ADM.git
cd ADM

# Install dependencies
flutter pub get

# Run tests
flutter test

# Analyze code quality
flutter analyze

# Run on connected device or emulator
flutter run
```
