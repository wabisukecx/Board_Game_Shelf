# Board Game Shelf

[English](README.md) | [日本語](README.ja.md)

Board Game Shelf is a Flutter app for managing a board game collection. It registers BoardGameGeek (BGG) data, supports local-only games, recognizes boxes and shelves from photos, runs a local analytics dashboard, and exports analyzer-compatible YAML.

The app is designed to be useful **without any API keys**, with optional online features unlocked when you provide your own BGG token and/or Gemini API key. See [Feature availability without API keys](#feature-availability-without-api-keys) for exactly what works in each configuration.

## Distribution policy

This is a personal, non-commercial project. It is not published on Google Play, and APKs are not distributed. Run it from source in your own environment.

## Setup

1. Install Flutter and run `flutter pub get`.
2. Run tests with `flutter test`.
3. Start the app with `flutter run`.

## Platform Support

This app targets **Android only**.

- **Android** — Supported. All features work, including camera-based barcode, box-cover, and shelf recognition.
- **iOS** — Not supported and not planned. The `ios/` directory contains only the default Flutter template and is left in place for tooling compatibility; the app is not built, tested, or maintained for iOS.
- **Desktop / Web** — Not a target. Camera and scanning features fall back to manual input on these platforms.

## Localization

UI strings are loaded from JSON bundles under `assets/i18n/` (`ja.json`, `en.json`) through a small key-based lookup (`I18n`).

- The default language setting is **Follow system**. If the device language matches a bundled locale, that bundle is used.
- If the system language is not bundled, the app falls back to English. If English is unavailable, it falls back to the first available locale bundle.
- You can manually select a language from Settings. The choice is applied immediately and is kept after restarting the app.
- Game titles follow the active UI language: Japanese UI prefers Japanese names, English UI prefers English names. Games without a Japanese name fall back to the BGG primary/English name.
- Search still checks all stored names regardless of the display language, so titles can be found by Japanese, English, or alternate names.
- The language preference is stored in `shared_preferences`; API keys and tokens remain isolated in secure storage.

### Adding another language

1. Copy an existing bundle to `assets/i18n/<locale>.json` and translate the values. Keep the same nested keys; missing keys fall back to showing the raw key string.
2. Add top-level metadata such as `"_meta": {"locale": "fr", "name": "Français"}`. If `_meta` is omitted, the filename is used as both locale code and display name.
3. No `pubspec.yaml` change is needed for additional locale JSON files because the whole `assets/i18n/` folder is bundled.
4. Restart the app; the new file appears automatically in the Settings language selector.



## API Keys and Feature Availability

This app never bundles API keys in the repository or the built binary. Any key you provide is stored only in the device's secure storage and is never written to the SQLite database, exported, or printed.

### Feature availability without API keys

| Feature | No keys | BGG token only | Gemini key only | Both keys |
| --- | --- | --- | --- | --- |
| Local-only game registration (manual add) | ✅ | ✅ | ✅ | ✅ |
| Browse / search / filter local collection | ✅ | ✅ | ✅ | ✅ |
| Analytics dashboard & learning analysis | ✅ | ✅ | ✅ | ✅ |
| YAML export, backup / restore | ✅ | ✅ | ✅ | ✅ |
| Barcode scan → known JAN (offline map hit) | ✅ | ✅ | ✅ | ✅ |
| Barcode scan → unknown JAN (GameUPC public test API) | ✅¹ | ✅¹ | ✅¹ | ✅¹ |
| BGG title search & registration | ❌ | ✅ | ❌ | ✅ |
| BGG collection batch import | ❌ | ✅ | ❌ | ✅ |
| Expansion candidate discovery (from BGG links) | ❌ | ✅ | ❌ | ✅ |
| Photo box-cover recognition | ❌ | ❌² | ✅ | ✅ |
| Shelf batch recognition | ❌ | ❌² | ✅ | ✅ |

¹ GameUPC lookup uses a public test endpoint that currently needs no key, but a successful **registration** of the matched game still requires a BGG token. Without a BGG token, an unknown JAN can be looked up but not registered into the collection through the BGG flow.

² Photo and shelf recognition only produce **title candidates**. Tapping a candidate hands off to the BGG search/registration flow, which needs a BGG token to actually register the game.

#### Without a BGG token

BGG search, registration, collection import, and expansion discovery are unavailable. You can still build and use a collection entirely through **manual (local-only) registration**, and every offline feature — filtering, analytics, learning analysis, export, and backup — works fully.

#### Without a Gemini API key

Photo box-cover recognition and shelf batch recognition are unavailable. The app falls back to manual search and manual add.

### How to obtain keys

**BoardGameGeek token.** BGG search and registration use a Bearer token. Apply for an API token from the BoardGameGeek API page (<https://boardgamegeek.com/applications>). Approval can take more than a week. After approval, save the issued token in the app's Settings screen.

**Gemini API key.** Save your own Gemini API key in Settings to enable photo box-cover recognition and shelf batch recognition.

## Collection List

- Games are shown in either a list view (default) or a grid view.
- **Expansions are nested under their parent base game and are collapsed by default.** A base game that owns expansions shows an expansion count and a chevron; tapping the row expands or collapses its expansions. Expand/collapse state is held in view only and is not persisted. Base games with no expansions show no chevron or badge.
- Grid view keeps the existing layout and marks expansions with a badge.

## Filters

Open the filter controls from the collection screen. Filters combine with AND logic:

- Title query
- Player count
- Maximum playing time
- Local-only
- Mechanics / designers
- Has expansions only
- Unplayed only
- **Play audience (Beginner / Advanced).** This is auto-classified from the BGG weight (complexity):
  - Beginner: weight below 2.0
  - Advanced: weight 2.0 and above
  - Games with no weight value are treated as Unknown and do not match either audience filter.

  The threshold is defined as a single constant so it can be tuned, and a finer three-band split (with a future Advanced cutoff at 3.0) is reserved in constants for later use.

## Local-only games

"Local-only" means a game that exists **only in your local database and is not tied to a BGG object** — typically a self-published / doujin game or any title you add by hand through manual registration. Local-only games are first-class collection records: they can be filtered, analyzed, exported, and backed up exactly like BGG-registered games. They simply have no BGG ID and therefore are never fetched from or written back to BGG.

## Analytics Dashboard

A read-only analytics dashboard for the local collection.

- Open Analytics from the collection AppBar.
- The dashboard uses existing local database records only. It does not call external APIs, use the camera, or write results back to the database.
- The default scope is owned records only; a toggle can include all collection records.
- **Analysis is always base-game only. Expansions are excluded from every aggregate** (title counts, weight and playing-time averages, rating, mechanic/category/designer/publisher tallies, distributions, and learning analysis). This prevents expansion records — which share mechanics and metadata with their base game and often lack their own BGG values — from skewing the data. All analytics flow through a single shared base-game filter so this rule is applied consistently.
- Missing or unparsable values are excluded from averages and reported as excluded counts.
- Built-in horizontal bars show weight, time, player coverage, decade, rating, top mechanics/categories/designers/publishers, storage locations, and acquisitions by month without adding chart dependencies.

### Learning analysis

Local multidimensional learning analysis based on the bundled `boardgame_analyzer` YAML tables.

- Game details show initial barrier, strategic depth, replayability, decision points, interaction complexity, rules complexity, mechanic complexity, solo suitability, player scalability, and luck dependence.
- Analytics summarizes average initial barrier, strategic depth, replayability, learning-curve types, player types, mastery time, and strategic-depth distribution.
- Analysis is local only. It does not call external APIs, store secrets, write YAML back to disk, or mutate analyzer table assets.
- Unknown mechanics/categories/rank types use documented fallback values instead of creating pending YAML entries.

## Barcode Scan

JAN/EAN-13 barcode registration on Android.

- The camera reads EAN-13 and UPC-A. UPC-A is normalized to EAN-13 with a leading `0`.
- If the JAN is already in the local barcode map, the app opens the game details offline.
- Unknown JAN values are resolved through the learned local map, bundled GameUPC offline data, the GameUPC API, then manual search.
- The bundled GameUPC data needs no API key and can be refreshed manually in Settings. A failed refresh keeps the existing data intact.
- If GameUPC returns a verified BGG game, the app registers it through the BGG registration flow (requires a BGG token) and saves the JAN-to-game mapping.
- If GameUPC returns multiple candidates, the app asks you to choose one, prefers a Japanese version for the GameUPC vote when available (otherwise English), posts the selection back to GameUPC with a stable device user id, then registers and links the JAN.
- If GameUPC is unset or finds no match, unknown JAN values go through BGG search or manual registration. On success, the mapping is saved for next time.
- iOS, desktop, web, permission-denied, or camera-unavailable environments fall back to the manual JAN input form.
- Android requires the `CAMERA` permission.

The app does not send JAN values directly to BGG as a barcode lookup. BGG search remains title-based; GameUPC is the optional UPC-to-BGG bridge.

Offline data provided by [GameUPC](https://gameupc.com).

## Photo Recognition

Single box-cover recognition on Android (requires a Gemini API key).

- Take a box-cover photo or pick one from the gallery, then explicitly press the recognition button. The image is sent to Gemini only after that action.
- Recognition returns estimated title candidates only. It never decides a BGG ID and never auto-registers a game.
- Tapping a candidate opens the BGG title search flow, where you confirm and register.
- If the key is missing, the network is unavailable, or confidence is low, the app falls back to manual search.

## Shelf Batch Recognition

Batch candidate extraction from one shelf photo on Android (requires a Gemini API key).

- Take a shelf photo or pick one from the gallery, then explicitly press the recognition button. The whole image is sent to Gemini only after that action. The app does not crop, detect objects locally, or run on-device ML.
- Recognition returns a review list of possible titles. Low-confidence candidates remain visible but are off by default.
- Existing collection title matches are marked as possibly owned so you can avoid duplicates.
- Selected candidates are sent one by one into the BGG search and registration flow. The app never auto-registers games and never treats Vision output as a confirmed BGG ID.
- Shelf photos can miss games, include false detections, and cost more tokens than a single box photo. Use manual search or manual add for omissions.

## BGG Collection Import

Manual batch import of an owned BoardGameGeek collection (requires a BGG token).

- Save your BGG username in Settings and keep the BGG bearer token set; item details are registered through the BGG registration flow.
- Open Add, then Import from BGG collection.
- Fetch the collection first. The app requests owned board games only with `own=1` and `subtype=boardgame`.
- Review total / new / already-registered counts, then start the import explicitly.
- Only new BGG object IDs are submitted to the existing registration path. Already-registered games are skipped, so rerunning the import is idempotent.
- Progress, cancel, partial results, and a consecutive-failure stop are shown in the import screen.
- Ratings, comments, play counts, BGG write-back, and automatic sync are out of scope.

## Expansion Management

- BGG `boardgameexpansion` links are parsed during the registration flow.
- Registration completes without automatically opening expansion candidates. Use **Check expansion candidates** from game details to add related games when needed.
- Expansions are saved as normal collection records with `gameKind=expansion` and an optional `parentGameKey`.
- Parent games do not have to be registered first; an expansion detail screen can register the parent later.
- When BGG reports multiple possible parent editions, choose one during registration or later from the expansion detail screen.
- List view nests registered expansions under their parent game (collapsed by default); grid view adds an expansion badge.
- Learning analysis remains base-game only; expansion detail pages show a notice instead of learning metrics.
- Analyzer-compatible YAML export is unchanged and adds no expansion-specific keys.

## Backup

The settings screen can manually copy the SQLite database.

- Location: `bg_shelf_backups/` within the app documents directory
- Filename: `backup_YYYYMMDD_HHMMSS.sqlite`

An automatic-backup naming helper (`YYMMDD.sqlite`) exists, but automatic execution is not implemented. There is no in-app restore feature.

## License

The intended license is MIT. A `LICENSE` file is not currently included in the repository.
